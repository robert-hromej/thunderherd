import { test, expect } from '@playwright/test'

// Inactive panes are display:none, so the named tabpanel is always the open one.
const pane = (page, name) => page.getByRole('tabpanel', { name })

test('directory shows the three reference tabs and the operator of the demo run', async ({ page }) => {
  await page.goto('/')

  await page.getByRole('link', { name: 'Directory', exact: true }).click()
  await expect(page).toHaveURL(/\/directory$/)

  await expect(page.getByRole('tab', { name: 'Operators' })).toBeVisible()
  await expect(page.getByRole('tab', { name: 'Machines' })).toBeVisible()
  await expect(page.getByRole('tab', { name: 'Deploys' })).toBeVisible()

  // Every run records who executed it, so the demo run leaves one operator behind.
  await expect(pane(page, 'Operators').getByRole('columnheader', { name: 'Name' })).toBeVisible()
  await expect(pane(page, 'Operators').locator('.ant-table-tbody .ant-table-row').first()).toBeVisible()
})

test('machines tab lists the machine the demo run was executed on', async ({ page }) => {
  await page.goto('/directory')

  await page.getByRole('tab', { name: 'Machines' }).click()

  await expect(pane(page, 'Machines').getByRole('columnheader', { name: 'Hostname' })).toBeVisible()
  await expect(pane(page, 'Machines').locator('.ant-table-tbody .ant-table-row').first()).toBeVisible()
})
