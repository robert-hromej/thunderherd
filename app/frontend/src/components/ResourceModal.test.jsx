import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Form, Input } from 'antd'
import { describe, test, expect, vi } from 'vitest'
import ResourceModal from './ResourceModal'

const renderModal = (props = {}) =>
  render(
    <ResourceModal
      open
      title="New thing"
      initialValues={{ name: 'seeded' }}
      onSubmit={vi.fn()}
      onClose={vi.fn()}
      {...props}
    >
      <Form.Item name="name" label="Name" rules={[{ required: true }]}>
        <Input />
      </Form.Item>
    </ResourceModal>,
  )

describe('ResourceModal', () => {
  test('seeds the form from initialValues and submits them', async () => {
    const onSubmit = vi.fn(() => Promise.resolve())
    const onSaved = vi.fn()
    renderModal({ onSubmit, onSaved })

    expect(await screen.findByDisplayValue('seeded')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: /ok/i }))

    await waitFor(() => expect(onSubmit).toHaveBeenCalledWith({ name: 'seeded' }))
    await waitFor(() => expect(onSaved).toHaveBeenCalled())
  })

  test('does not submit when validation fails', async () => {
    const onSubmit = vi.fn(() => Promise.resolve())
    renderModal({ initialValues: { name: '' }, onSubmit })

    await userEvent.click(screen.getByRole('button', { name: /ok/i }))
    await waitFor(() => expect(screen.getByRole('button', { name: /ok/i })).toBeInTheDocument())
    expect(onSubmit).not.toHaveBeenCalled()
  })

  test('a failing transform blocks the request', async () => {
    const onSubmit = vi.fn(() => Promise.resolve())
    renderModal({
      onSubmit,
      transform: () => {
        throw new Error('Body must be valid JSON')
      },
    })

    await userEvent.click(screen.getByRole('button', { name: /ok/i }))
    await waitFor(() => expect(screen.getByText('Body must be valid JSON')).toBeInTheDocument())
    expect(onSubmit).not.toHaveBeenCalled()
  })

  test('surfaces the API error and keeps the dialog open', async () => {
    const onSubmit = vi.fn(() => Promise.reject({ response: { data: { errors: ['Key has already been taken'] } } }))
    const onSaved = vi.fn()
    renderModal({ onSubmit, onSaved })

    await userEvent.click(screen.getByRole('button', { name: /ok/i }))
    await waitFor(() => expect(screen.getByText('Key has already been taken')).toBeInTheDocument())
    expect(onSaved).not.toHaveBeenCalled()
  })
})
