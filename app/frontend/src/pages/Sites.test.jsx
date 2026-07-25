import React from 'react'
import { render, screen } from '@testing-library/react'
import { vi, test, expect } from 'vitest'
import Sites from './Sites'

vi.mock('../api', () => ({
  default: {
    sites: vi.fn(() =>
      Promise.resolve([
        { id: 1, key: 'demo', name: 'Demo Project', environments: [{ id: 1, name: 'staging', base_url: 'https://x', is_production: false }] },
        { id: 2, key: 'empty-site', name: 'Empty', environments: [] },
      ]),
    ),
  },
}))

test('lists sites with environment counts and the New site button', async () => {
  render(<Sites />)
  expect(await screen.findByText('demo')).toBeInTheDocument()
  expect(screen.getByText('empty-site')).toBeInTheDocument()
  expect(screen.getByText('New site')).toBeInTheDocument()
})
