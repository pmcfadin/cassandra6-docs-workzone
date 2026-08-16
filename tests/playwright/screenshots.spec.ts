import { test, expect } from '@playwright/test';

/**
 * Review-evidence screenshots. Not assertions about pixels — each capture
 * still asserts the page rendered (article visible) so a blank page fails.
 *
 * Output: build/screenshots/*.png — uploaded as a CI artifact so reviewers
 * see how the site looks without checking anything out. At the
 * cassandra-website port, the sticky PR comment embeds these via the fork's
 * GitHub Pages URL (images in PR comments render from any https host).
 *
 * Pixel-diff gating (toHaveScreenshot) is deliberately NOT enabled — runner
 * font rendering makes it flaky (docs/website-qa-automation.md, deferred).
 */

const SHOTS: Array<{ name: string; nav: string | null }> = [
  { name: 'home', nav: null },
  { name: 'operators', nav: 'Operators' },
  { name: 'developers', nav: 'Developers' },
  { name: 'contributors', nav: 'Contributors' },
  { name: 'reference', nav: 'Reference' },
];

for (const { name, nav } of SHOTS) {
  test(`screenshot: ${name}`, async ({ page }) => {
    await page.goto('/');
    if (nav) await page.getByRole('link', { name: nav }).first().click();
    await expect(page.locator('article.doc').first()).toBeVisible();
    await page.screenshot({
      path: `build/screenshots/${name}.png`,
      fullPage: false, // above-the-fold is what reviewers glance at
    });
  });
}
