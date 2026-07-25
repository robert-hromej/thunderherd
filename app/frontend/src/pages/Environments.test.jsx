import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

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
import Environments from './Environments'

const envs = [
  {
    id: 1,
    site: 'shop',
    name: 'staging',
    is_production: false,
    base_url: 'https://staging.shop.example',
    heroku_app: 'acme-staging',
    urls_count: 4,
    runs_count: 2,
  },
  {
    id: 2,
    site: 'shop',
    name: 'production',
    is_production: true,
    base_url: 'https://shop.example',
    heroku_app: 'shop-prod',
    urls_count: 6,
    runs_count: 10,
  },
]

describe('Environments', () => {
  beforeEach(() => {
    api.environments.mockResolvedValue(envs)
  })

  it('renders staging and production environments with their base URLs', async () => {
    render(<Environments />)
    expect(await screen.findByText('https://staging.shop.example')).toBeInTheDocument()
    expect(screen.getByText('https://shop.example')).toBeInTheDocument()
    expect(screen.getAllByText('staging').length).toBeGreaterThan(0)
    expect(screen.getAllByText('production').length).toBeGreaterThan(0)
  })
})
