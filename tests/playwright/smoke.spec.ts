import { test, expect, Page } from '@playwright/test';

/**
 * Rendered-HTML smoke suite for the workzone Antora build (build/site).
 *
 * Port note (apache/cassandra-website): these tests target the default
 * Antora UI + the workzone supplemental header. When ported upstream, the
 * SELECTORS block switches to data-testid attributes on site-ui Handlebars
 * partials per docs/website-qa-automation.md ("Selector policy"), and the
 * website-only tests (version switcher, Lunr search, code-copy, mobile nav)
 * are added from that spec's Test Inventory.
 */

const SELECTORS = {
  article: 'article.doc',
  leftNav: 'nav.nav-menu',
  headerNav: 'header, .navbar, .header', // supplemental header container
};

// The four audience components the workzone header links to.
const AUDIENCES = ['Operators', 'Developers', 'Contributors', 'Reference'];

// Collected per-page browser errors; asserted empty at the end of each test
// that navigates. Benign patterns can be allowlisted here with justification.
const CONSOLE_ERROR_ALLOWLIST: RegExp[] = [
  /favicon\.ico/, // static server has no favicon; not a site defect
];

function watchConsole(page: Page): string[] {
  const errors: string[] = [];
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(`console: ${msg.text()}`);
  });
  page.on('requestfailed', (req) => {
    errors.push(`requestfailed: ${req.url()} (${req.failure()?.errorText})`);
  });
  return errors;
}

function realErrors(errors: string[]): string[] {
  return errors.filter((e) => !CONSOLE_ERROR_ALLOWLIST.some((re) => re.test(e)));
}

test('homepage loads with a title and no browser errors', async ({ page }) => {
  const errors = watchConsole(page);
  const resp = await page.goto('/');
  expect(resp?.status(), 'homepage must return 200').toBeLessThan(400);
  await expect(page).toHaveTitle(/.+/);
  await expect(page.locator(SELECTORS.article).first()).toBeVisible();
  expect(realErrors(errors)).toEqual([]);
});

test('header nav exposes all audience links and each resolves', async ({ page, request }) => {
  await page.goto('/');
  for (const audience of AUDIENCES) {
    const link = page.getByRole('link', { name: audience }).first();
    await expect(link, `header must link to ${audience}`).toBeVisible();
    const href = await link.getAttribute('href');
    expect(href, `${audience} link must have an href`).toBeTruthy();
    const resp = await request.get(new URL(href!, page.url()).toString());
    expect(resp.status(), `${audience} target must not 404`).toBeLessThan(400);
  }
});

test('left nav renders on a docs page and its first links resolve', async ({ page, request }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Operators' }).first().click();
  await expect(page.locator(SELECTORS.article).first()).toBeVisible();
  const nav = page.locator(`${SELECTORS.leftNav} a[href]`);
  const count = await nav.count();
  expect(count, 'operators component must have a populated left nav').toBeGreaterThan(3);
  for (let i = 0; i < Math.min(count, 5); i++) {
    const href = await nav.nth(i).getAttribute('href');
    if (!href || href.startsWith('#')) continue;
    const resp = await request.get(new URL(href, page.url()).toString());
    expect(resp.status(), `nav entry ${href} must not 404`).toBeLessThan(400);
  }
});

// Render-level link audit: every internal link on each audience landing page
// must resolve. This is the browser-side complement of the Antora xref gate —
// it also catches links Antora cannot see (hand-written hrefs, UI links).
for (const audience of AUDIENCES) {
  test(`link audit: ${audience} landing page has no dead internal links`, async ({ page, request }) => {
    await page.goto('/');
    await page.getByRole('link', { name: audience }).first().click();
    const hrefs = await page.$$eval('article.doc a[href], nav.nav-menu a[href]', (as) =>
      as.map((a) => a.getAttribute('href') || ''),
    );
    const internal = [...new Set(hrefs)]
      .filter((h) => h && !h.startsWith('#') && !/^[a-z]+:/i.test(h))
      .slice(0, 40);
    const dead: string[] = [];
    for (const href of internal) {
      const url = new URL(href, page.url()).toString();
      const resp = await request.get(url);
      if (resp.status() >= 400) dead.push(`${href} -> ${resp.status()}`);
    }
    expect(dead, `dead links on ${audience} landing`).toEqual([]);
  });
}

test('404 template renders as a page, not a server error', async ({ page }) => {
  const resp = await page.goto('/404.html');
  expect(resp?.status()).toBe(200);
  await expect(page).toHaveTitle(/not found/i);
});

test('images on the homepage and one docs page actually load', async ({ page }) => {
  for (const path of ['/', undefined]) {
    if (path) await page.goto(path);
    else {
      await page.goto('/');
      await page.getByRole('link', { name: 'Operators' }).first().click();
    }
    const broken = await page.$$eval('article.doc img', (imgs) =>
      imgs
        .filter((img) => !(img as HTMLImageElement).complete || (img as HTMLImageElement).naturalWidth === 0)
        .map((img) => img.getAttribute('src') || '(no src)'),
    );
    expect(broken, `broken images on ${page.url()}`).toEqual([]);
  }
});

test('draft/preview banner is present (workzone must never look official)', async ({ page }) => {
  await page.goto('/');
  await expect(
    page.getByText(/preview|draft/i).first(),
    'the preview disclaimer banner is mandatory per runbooks/github-pages-publishing.md',
  ).toBeVisible();
});
