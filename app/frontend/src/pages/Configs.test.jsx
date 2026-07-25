import React from 'react'
import { render, screen } from '@testing-library/react'
import { vi, test, expect } from 'vitest'
import Configs from './Configs'

vi.mock('../api', () => ({
  default: {
    runConfigs: vi.fn(() =>
      Promise.resolve([
        {
          id: 1, name: 'staging-smoke', environment: 'demo/staging', environment_id: 1,
          requests_per_url: 50, concurrency: 10, timeout_s: 30, description: 'Smoke',
          url_ids: [], target_urls_count: 3,
        },
      ]),
    ),
    environments: vi.fn(() => Promise.resolve([])),
    environment: vi.fn(() => Promise.resolve({ urls: [] })),
  },
}))

test('lists run configs with target URL counts', async () => {
  render(<Configs />)
  expect(await screen.findByText('staging-smoke')).toBeInTheDocument()
  expect(screen.getByText('3 (all)')).toBeInTheDocument()
  expect(screen.getByText('New config')).toBeInTheDocument()
})
