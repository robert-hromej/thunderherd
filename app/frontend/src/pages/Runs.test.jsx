import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

vi.mock('../api', () => ({
  default: {
    dashboard: vi.fn(),
    runs: vi.fn(),
    run: vi.fn(),
    createRun: vi.fn(),
    compare: vi.fn(),
    environments: vi.fn(),
    environment: vi.fn(),
    runConfigs: vi.fn(),
  },
}))

import api from '../api'
import Runs from './Runs'

const runs = [
  {
    id: 3,
    site: 'shop',
    env: 'staging',
    label: 'nightly',
    status: 'completed',
    dynos: 'web=2',
    requests_per_url: 50,
    concurrency: 10,
    pages: 15,
    avg_p95_ms: 210,
    total_errors: 1,
    started_at: '2026-07-20T10:00:00Z',
  },
]

const renderPage = () =>
  render(
    <MemoryRouter>
      <Runs />
    </MemoryRouter>,
  )

describe('Runs', () => {
  beforeEach(() => {
    api.runs.mockResolvedValue(runs)
  })

  it('renders a run row with its id and target', async () => {
    renderPage()
    expect(await screen.findByText('#3')).toBeInTheDocument()
    expect(screen.getByText('shop/staging')).toBeInTheDocument()
  })

  it('renders the New run button', async () => {
    renderPage()
    await screen.findByText('#3')
    expect(screen.getByRole('button', { name: 'New run' })).toBeInTheDocument()
  })
})
