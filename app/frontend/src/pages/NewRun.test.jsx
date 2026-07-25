import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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
import NewRun from './NewRun'

const envs = [
  { id: 1, site: 'shop', name: 'staging', is_production: false, base_url: 'https://staging.shop.example' },
  { id: 2, site: 'shop', name: 'production', is_production: true, base_url: 'https://shop.example' },
]

const renderPage = () =>
  render(
    <MemoryRouter>
      <NewRun />
    </MemoryRouter>,
  )

describe('NewRun', () => {
  beforeEach(() => {
    api.environments.mockResolvedValue(envs)
    api.runConfigs.mockResolvedValue([])
  })

  it('renders the form with the environment field and Start run button', async () => {
    renderPage()
    expect(await screen.findByText('Environment')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start run' })).toBeInTheDocument()
    expect(screen.queryByText('This is a production environment')).not.toBeInTheDocument()
  })

  it('shows the production warning and allow-prod checkbox after choosing a production environment', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Environment')
    const combos = screen.getAllByRole('combobox')
    // combos[0] = run config select, combos[1] = environment select
    await user.click(combos[1])

    // antd renders the visible option with the label as its `title` attribute.
    const prodOption = await screen.findByTitle(/shop\/production/)
    await user.click(prodOption)

    expect(await screen.findByText('This is a production environment')).toBeInTheDocument()
    expect(
      screen.getByText('I understand — allow running against production'),
    ).toBeInTheDocument()
  })
})
