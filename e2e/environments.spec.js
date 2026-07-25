import { test, expect } from '@playwright/test'

test('environments page lists staging and production', async ({ page }) => {
  await page.goto('/environments')

  // "staging"/"production" each appear in the name cell and the type tag.
  await expect(page.getByText('staging').first()).toBeVisible()
  await expect(page.getByText('production').first()).toBeVisible()
})
