import { test, expect } from '@playwright/test'

test('runs list opens the demo run detail', async ({ page }) => {
  await page.goto('/')

  await page.getByRole('link', { name: 'Runs', exact: true }).click()
  await expect(page).toHaveURL(/\/runs$/)

  await expect(page.getByText('demo-baseline')).toBeVisible()

  await page.getByRole('link', { name: /#\d+/ }).first().click()
  await expect(page).toHaveURL(/\/runs\/\d+$/)

  await expect(page.getByText(/Run #\d+/).first()).toBeVisible()
  await expect(page.getByText('Dyno formation')).toBeVisible()

  const resultsCard = page.locator('.ant-card').filter({ hasText: 'Results' })
  await expect(resultsCard.locator('.ant-table-tbody .ant-table-row').first()).toBeVisible()
})
