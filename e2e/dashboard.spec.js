import { test, expect } from '@playwright/test'

// Statistic titles collide with sidebar links ("Runs", "Environments"),
// so scope the stat-card assertions to the antd Statistic title element.
const statTitle = (page, name) => page.locator('.ant-statistic-title', { hasText: name })

test('dashboard shows the brand, stat cards, latest runs and the demo run', async ({ page }) => {
  await page.goto('/')

  await expect(page.getByText('⚡ thunderherd')).toBeVisible()

  await expect(statTitle(page, 'Sites')).toBeVisible()
  await expect(statTitle(page, 'Environments')).toBeVisible()
  await expect(statTitle(page, 'Runs')).toBeVisible()
  await expect(statTitle(page, 'Completed')).toBeVisible()

  await expect(page.getByText('Latest runs')).toBeVisible()

  await expect(page.getByText('demo-baseline')).toBeVisible()
})
