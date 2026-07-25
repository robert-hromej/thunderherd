import { defineConfig, devices } from '@playwright/test'

const PORT = process.env.E2E_PORT || 3311
const baseURL = `http://localhost:${PORT}`

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  fullyParallel: false,
  workers: 1,
  reporter: 'list',
  use: {
    baseURL,
    headless: true,
    trace: 'retain-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: `bin/e2e-server ${PORT}`,
    url: `${baseURL}/up`,
    timeout: 180000,
    reuseExistingServer: !process.env.CI,
  },
})
