import React from 'react'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, test, expect, describe } from 'vitest'
import Compare, { comparabilityWarnings } from './Compare'

vi.mock('../api', () => ({
  default: {
    runs: vi.fn(() =>
      Promise.resolve([
        { id: 8, site: 'acme', env: 'staging', label: 'before', status: 'completed' },
        { id: 11, site: 'acme', env: 'staging', label: 'after', status: 'completed' },
        { id: 3, site: 'acme', env: 'staging', label: 'failed-one', status: 'failed' },
      ]),
    ),
    compare: vi.fn(() =>
      Promise.resolve({
        before: { id: 8, site: 'acme', env: 'staging', label: 'before', requests_per_url: 20, concurrency: 10, dyno_formation: 'web=2:Standard-2X' },
        after: { id: 11, site: 'acme', env: 'staging', label: 'after', requests_per_url: 20, concurrency: 10, dyno_formation: 'web=4:Standard-2X' },
        diff: [
          { method: 'GET', path: '/', before_p95: 8000, after_p95: 5000, p95_delta: -3000, before_avg: 5000, after_avg: 3000, avg_delta: -2000, before_rps: 1.6, after_rps: 2.5 },
        ],
      }),
    ),
  },
}))

test('empty state prompts to pick two runs; only completed runs are selectable', async () => {
  render(
    <MemoryRouter initialEntries={['/compare']}>
      <Compare />
    </MemoryRouter>,
  )
  expect(await screen.findByText(/Pick two completed runs/i)).toBeInTheDocument()
})

test('with before+after in the URL it loads deltas and warns on differing dyno formations', async () => {
  render(
    <MemoryRouter initialEntries={['/compare?before=8&after=11']}>
      <Compare />
    </MemoryRouter>,
  )
  expect(await screen.findByText(/not directly comparable/i)).toBeInTheDocument()
  expect(await screen.findByText('Dyno formation:')).toBeInTheDocument()
  expect(await screen.findByText('-3000')).toBeInTheDocument() // Δ p95, faster
})

describe('comparabilityWarnings', () => {
  const run = (over = {}) => ({
    site: 'acme', env: 'staging', dyno_formation: 'web=2:Standard-2X',
    requests_per_url: 20, concurrency: 10, machine: 'ci-runner',
    network: { kind: 'ethernet' }, ...over,
  })

  test('says nothing when the two runs are directly comparable', () => {
    expect(comparabilityWarnings(run(), run())).toEqual([])
  })

  test('flags infra, client and load differences that would fake a regression', () => {
    const labels = comparabilityWarnings(
      run(),
      run({ dyno_formation: 'web=4:Standard-2X', machine: 'laptop', network: { kind: 'wifi' }, concurrency: 20 }),
    ).map((d) => d.label)

    expect(labels).toEqual(['Dyno formation', 'Load', 'Machine', 'Network'])
  })

  test('reports a missing value as n/a rather than blank', () => {
    const [diff] = comparabilityWarnings(run({ machine: null }), run())
    expect(diff).toMatchObject({ label: 'Machine', before: 'n/a', after: 'ci-runner' })
  })
})
