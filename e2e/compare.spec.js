import { test, expect } from '@playwright/test'

// antd renders each Select's dropdown into the body and keeps closed ones around
// with the -hidden class; pick options only from the one that is actually open.
async function pickRun(page, placeholder, runLabel) {
  await expect(page.locator('.ant-select-dropdown:not(.ant-select-dropdown-hidden)')).toHaveCount(0)
  await page.locator('.ant-select').filter({ hasText: placeholder }).click()

  const dropdown = page.locator('.ant-select-dropdown:not(.ant-select-dropdown-hidden)')
  await dropdown.getByText(runLabel).click()
}

test('compare page offers both run selects and an empty state until two runs are picked', async ({ page }) => {
  await page.goto('/')

  await page.getByRole('link', { name: 'Compare', exact: true }).click()
  await expect(page).toHaveURL(/\/compare$/)

  await expect(page.getByText('Before (baseline)')).toBeVisible()
  await expect(page.getByText('After', { exact: true })).toBeVisible()
  await expect(page.getByText('Pick the baseline run')).toBeVisible()
  await expect(page.getByText('Pick the run to compare')).toBeVisible()

  await expect(page.getByText('Pick two completed runs to see per-page deltas')).toBeVisible()
})

test('picking a before and an after run renders the per-page delta table', async ({ page }) => {
  await page.goto('/compare')

  await pickRun(page, 'Pick the baseline run', 'demo-baseline')
  await pickRun(page, 'Pick the run to compare', 'demo-candidate')

  await expect(page.getByText('Per-page deltas (negative = faster)')).toBeVisible()

  const deltas = page.locator('.ant-card').filter({ hasText: 'Per-page deltas' })
  await expect(deltas.getByRole('columnheader', { name: /Δ p95/ })).toBeVisible()
  await expect(deltas.locator('.ant-table-tbody .ant-table-row').first()).toBeVisible()
})
