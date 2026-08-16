import { defineConfig, devices } from '@playwright/test';

// Smoke suite for the built Antora site (build/site). Chromium-only,
// retries: 1, hard fail on second attempt — per docs/website-qa-automation.md.
// The webServer block serves the static build; Playwright owns its lifecycle,
// so `npx playwright test` is the only command CI or a contributor needs.
export default defineConfig({
  testDir: './tests/playwright',
  timeout: 30_000,
  retries: 1,
  workers: 2,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: 'http://127.0.0.1:5151',
    trace: 'retain-on-failure',
    ...devices['Desktop Chrome'],
  },
  webServer: {
    command: 'npx http-server build/site -p 5151 -c-1 --silent',
    url: 'http://127.0.0.1:5151',
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
