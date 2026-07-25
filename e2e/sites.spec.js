import { test, expect } from '@playwright/test'

test('sites page lists the demo site and refuses to delete it while it has environments', async ({ page }) => {
  await page.goto('/')

  await page.getByRole('link', { name: 'Sites', exact: true }).click()
  await expect(page).toHaveURL(/\/sites$/)

  const demoRow = page.locator('.ant-table-row', { hasText: 'Demo Project' })
  await expect(demoRow).toBeVisible()
  await expect(demoRow.getByText('demo', { exact: true })).toBeVisible()

  // The API rejects deleting a site that still has environments, so the UI must
  // not offer it — that guard is the point of this page.
  await expect(demoRow.getByRole('button', { name: 'Delete' })).toBeDisabled()
})

test('new-site modal offers the key and name fields and closes on cancel', async ({ page }) => {
  await page.goto('/sites')

  await page.getByRole('button', { name: 'New site' }).click()

  const dialog = page.getByRole('dialog')
  await expect(dialog.getByText('New site')).toBeVisible()
  await expect(dialog.getByLabel('Key')).toBeVisible()
  await expect(dialog.getByLabel('Name')).toBeVisible()

  await dialog.getByRole('button', { name: 'Cancel' }).click()
  await expect(dialog).toBeHidden()
})
