import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Routes, Route } from 'react-router-dom'

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
import RunDetail from './RunDetail'

const detail = {
  id: 42,
  site: 'shop',
  env: 'staging',
  base_url: 'https://staging.shop.example',
  status: 'completed',
  dyno_formation: 'web=2:Standard-2X',
  operator: 'jane',
  machine: 'ci-1',
  requests_per_url: 50,
  concurrency: 10,
  timeout_s: 30,
  tool_version: 'th 1.0',
  harness_version: 'h1',
  duration_s: 12,
  is_production: false,
  summary: { pages: 1, total_requests: 20, total_errors: 0, max_p95_ms: 300 },
  results: [
    {
      id: 1,
      method: 'GET',
      path: '/',
      requests: 20,
      error_count: 0,
      rps: 15,
      min_ms: 5,
      avg_ms: 50,
      p50_ms: 45,
      p90_ms: 80,
      p95_ms: 95,
      p99_ms: 120,
      max_ms: 200,
      stddev_ms: 10,
      server_ms: 40,
      status_codes: { 200: 20 },
    },
  ],
}

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/runs/42']}>
      <Routes>
        <Route path="/runs/:id" element={<RunDetail />} />
      </Routes>
    </MemoryRouter>,
  )

describe('RunDetail', () => {
  beforeEach(() => {
    api.run.mockResolvedValue(detail)
  })

  it('renders the run title and dyno formation', async () => {
    renderPage()
    expect(await screen.findByText('web=2:Standard-2X')).toBeInTheDocument()
    expect(screen.getByText('Run #')).toBeInTheDocument()
    expect(screen.getByText('42')).toBeInTheDocument()
  })

  it('renders a results table row for path /', async () => {
    renderPage()
    await screen.findByText('web=2:Standard-2X')
    expect(screen.getAllByText('/').length).toBeGreaterThan(0)
  })

  it('renders the metric Segmented control labels', async () => {
    renderPage()
    await screen.findByText('web=2:Standard-2X')
    for (const label of ['p95', 'p99', 'avg', 'server', 'rps']) {
      expect(screen.getAllByText(label).length).toBeGreaterThan(0)
    }
  })
})
