import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import PagesBarChart from './PagesBarChart'

const rows = [
  { path: '/', p95_ms: 120, rps: 18, avg_ms: 40 },
  { path: '/products/really/long/nested/path/that/exceeds/the/short/limit', p95_ms: 900, rps: 4, avg_ms: 500 },
]

describe('PagesBarChart', () => {
  it('renders with a rows array without throwing', () => {
    expect(() => render(<PagesBarChart rows={rows} />)).not.toThrow()
  })

  it('renders with empty rows without throwing', () => {
    expect(() => render(<PagesBarChart rows={[]} />)).not.toThrow()
  })

  it('renders when rows is undefined', () => {
    expect(() => render(<PagesBarChart />)).not.toThrow()
  })
})
