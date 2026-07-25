import { test, expect } from '@playwright/test'

test('configs page lists the seeded run config with its environment', async ({ page }) => {
  await page.goto('/')

  await page.getByRole('link', { name: 'Configs', exact: true }).click()
  await expect(page).toHaveURL(/\/configs$/)

  const row = page.locator('.ant-table-row', { hasText: 'demo-staging-smoke' })
  await expect(row).toBeVisible()
  await expect(row.getByText('demo/staging')).toBeVisible()
})

test('new-config modal explains that an empty URL selection targets every active URL', async ({ page }) => {
  await page.goto('/configs')

  await page.getByRole('button', { name: 'New config' }).click()

  const dialog = page.getByRole('dialog')
  await expect(dialog.getByText('New run config')).toBeVisible()
  await expect(dialog.getByLabel('Name')).toBeVisible()
  await expect(dialog.getByLabel('Environment')).toBeVisible()
  await expect(dialog.getByLabel('URLs')).toBeVisible()

  await expect(dialog.getByText('Leave empty to hit every active URL of the environment')).toBeVisible()
})
