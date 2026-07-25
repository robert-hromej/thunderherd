import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import { describe, test, expect, vi } from 'vitest'
import { useCollection, mutate } from './hooks'

function Probe({ fetcher }) {
  const { rows, loading, reload } = useCollection(fetcher)
  return (
    <div>
      <span data-testid="loading">{String(loading)}</span>
      <span data-testid="rows">{rows.length}</span>
      <button onClick={reload}>reload</button>
    </div>
  )
}

describe('useCollection', () => {
  test('loads rows and clears the loading flag', async () => {
    const fetcher = vi.fn(() => Promise.resolve([{ id: 1 }, { id: 2 }]))
    render(<Probe fetcher={fetcher} />)

    await waitFor(() => expect(screen.getByTestId('loading')).toHaveTextContent('false'))
    expect(screen.getByTestId('rows')).toHaveTextContent('2')
  })

  test('clears loading even when the request fails, so the table never spins forever', async () => {
    const fetcher = vi.fn(() => Promise.reject(new Error('boom')))
    render(<Probe fetcher={fetcher} />)

    await waitFor(() => expect(screen.getByTestId('loading')).toHaveTextContent('false'))
    expect(screen.getByTestId('rows')).toHaveTextContent('0')
  })
})

describe('mutate', () => {
  test('resolves true and runs onDone on success', async () => {
    const onDone = vi.fn()
    await expect(mutate(Promise.resolve(), { success: 'Saved', onDone })).resolves.toBe(true)
    expect(onDone).toHaveBeenCalled()
  })

  test('swallows the rejection and resolves false so Popconfirm does not re-throw', async () => {
    const onDone = vi.fn()
    await expect(mutate(Promise.reject(new Error('nope')), { error: 'Delete failed', onDone })).resolves.toBe(
      false,
    )
    expect(onDone).not.toHaveBeenCalled()
  })
})
