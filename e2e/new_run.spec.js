import { test, expect } from '@playwright/test'

test('new-run form reveals the production warning and allow-prod checkbox', async ({ page }) => {
  await page.goto('/runs/new')

  const envSelect = page.locator('.ant-select').filter({ hasText: /Choose an environment/ })
  await expect(envSelect).toBeVisible()

  await envSelect.click()
  const dropdown = page.locator('.ant-select-dropdown').filter({ hasText: 'demo/production' })
  await dropdown.getByText('demo/production').click()

  await expect(page.getByText('This is a production environment')).toBeVisible()
  await expect(page.getByText(/I understand/)).toBeVisible()
  await expect(page.getByRole('checkbox')).toBeVisible()
})
