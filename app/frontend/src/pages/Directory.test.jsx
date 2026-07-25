import React from 'react'
import { render, screen } from '@testing-library/react'
import { vi, test, expect } from 'vitest'
import Directory from './Directory'

vi.mock('../api', () => ({
  default: {
    operators: vi.fn(() =>
      Promise.resolve([{ id: 1, name: 'Alice', email: 'a@x.test', runs_count: 4, last_run_at: '2026-07-25T10:00:00Z' }]),
    ),
    machines: vi.fn(() => Promise.resolve([])),
    deploys: vi.fn(() => Promise.resolve([])),
  },
}))

test('shows the three directory tabs with operators loaded by default', async () => {
  render(<Directory />)
  expect(screen.getByText('Operators')).toBeInTheDocument()
  expect(screen.getByText('Machines')).toBeInTheDocument()
  expect(screen.getByText('Deploys')).toBeInTheDocument()
  expect(await screen.findByText('Alice')).toBeInTheDocument()
  expect(screen.getByText('a@x.test')).toBeInTheDocument()
})
