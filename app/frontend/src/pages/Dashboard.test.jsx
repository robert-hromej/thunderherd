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
import Dashboard from './Dashboard'

const dashboard = {
  counts: { sites: 3, environments: 5, runs: 12, completed_runs: 9 },
  latest_runs: [
    {
      id: 7,
      site: 'shop',
      env: 'staging',
      label: 'before-caching',
      status: 'completed',
      pages: 20,
      avg_p95_ms: 320,
      total_errors: 0,
    },
  ],
  slowest_pages: [
    {
      run_id: 7,
      site: 'shop',
      env: 'staging',
      method: 'GET',
      path: '/products',
      p95_ms: 900,
      rps: 12,
      error_count: 0,
    },
  ],
}

const renderPage = () =>
  render(
    <MemoryRouter>
      <Dashboard />
    </MemoryRouter>,
  )

describe('Dashboard', () => {
  beforeEach(() => {
    api.dashboard.mockResolvedValue(dashboard)
  })

  it('renders the four summary statistic titles', async () => {
    renderPage()
    expect(await screen.findByText('Sites')).toBeInTheDocument()
    expect(screen.getByText('Environments')).toBeInTheDocument()
    expect(screen.getByText('Runs')).toBeInTheDocument()
    expect(screen.getByText('Completed')).toBeInTheDocument()
  })

  it('renders a run link and a slowest-page path', async () => {
    renderPage()
    expect((await screen.findAllByText('#7')).length).toBeGreaterThan(0)
    expect(screen.getAllByText('/products').length).toBeGreaterThan(0)
  })
})
