import { test, expect } from '@playwright/test'

test('the star button on a run toggles its baseline flag', async ({ page }) => {
  await page.goto('/runs')

  const row = page.locator('.ant-table-row', { hasText: 'demo-baseline' })
  const star = row.getByRole('button', { name: /baseline/i })
  await expect(star).toBeVisible()

  // The suite shares one seeded DB, so the run may already be flagged — assert the
  // state flips rather than a fixed outcome.
  const wasBaseline = (await star.getAttribute('aria-label')) === 'Unmark baseline'
  const flipped = wasBaseline ? 'Mark as baseline' : 'Unmark baseline'

  await star.click()

  await expect(page.getByText(wasBaseline ? /is no longer a baseline/ : /marked as baseline/)).toBeVisible()
  await expect(row.getByRole('button', { name: flipped, exact: true })).toBeVisible()
})
