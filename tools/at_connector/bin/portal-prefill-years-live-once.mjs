import fs from 'node:fs';
import process from 'node:process';
import { chromium } from 'playwright';
import {
  extractDm3IrsHtmlVersion,
  parseForwardForm,
  parseLoginBootstrap,
  PORTAL_IRS_START,
} from '../src/portal_prefill.mjs';

const envPath = process.argv[2];
if (envPath) {
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!match || process.env[match[1]]) continue;
    let value = match[2];
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1);
    process.env[match[1]] = value;
  }
}

const nif = String(process.env.AT_USERNAME || '').replace(/\s/g, '');
const password = String(process.env.AT_PASSWORD || '');
if (!/^\d{9}$/.test(nif) || !password) {
  process.stdout.write('{"error":"CREDENTIALS_REQUIRED"}\n');
  process.exit(1);
}

const browser = await chromium.launch({
  channel: 'chrome',
  headless: true,
  args: ['--disable-dev-shm-usage'],
});
const context = await browser.newContext({
  locale: 'pt-PT',
  timezoneId: 'Europe/Lisbon',
});
const page = await context.newPage();

try {
  const landing = await context.request.get(PORTAL_IRS_START, {
    timeout: 60000,
    maxRedirects: 10,
  });
  const bootstrap = parseLoginBootstrap(await landing.text());
  const login = await context.request.post(
    new URL(bootstrap.action, landing.url()).toString(),
    {
      form: {
        ...bootstrap.attributes,
        username: nif,
        password,
        selectedAuthMethod: 'N',
        _csrf: bootstrap.csrf,
        authVersion: bootstrap.authVersion,
      },
      timeout: 60000,
      maxRedirects: 10,
    },
  );
  const loginHtml = await login.text();
  if (/(?:show2FaModal|is2FA)\s*:\s*parseBoolean\(["']true["']\)/.test(loginHtml)) {
    throw new Error('AT_ADDITIONAL_VERIFICATION_REQUIRED');
  }
  const forward = parseForwardForm(loginHtml);
  const app = await context.request.post(
    new URL(forward.action, login.url()).toString(),
    { form: forward.fields, timeout: 60000, maxRedirects: 10 },
  );
  if (new URL(app.url()).hostname !== 'irs.portaldasfinancas.gov.pt') {
    throw new Error('IRS_SESSION_TRANSFER_FAILED');
  }
  if (!extractDm3IrsHtmlVersion(await app.text())) {
    throw new Error('DM3IRS_HTML_VERSION_NOT_FOUND');
  }

  await page.goto(PORTAL_IRS_START, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  const prefillChoice = page.getByText(
    /Obtenção de uma declaração pré-preenchida/i,
  ).first();
  await prefillChoice.waitFor({ state: 'visible', timeout: 60000 });
  await prefillChoice.click();

  const controls = [];
  const selects = page.locator('select:visible');
  for (let index = 0; index < await selects.count(); index += 1) {
    const select = selects.nth(index);
    const options = (await select.locator('option').allTextContents())
      .map((value) => value.trim())
      .filter(Boolean);
    controls.push({
      name: await select.getAttribute('name'),
      id: await select.getAttribute('id'),
      options,
    });
  }
  const years = [...new Set(controls.flatMap((control) => control.options)
    .filter((value) => /^20\d{2}$/.test(value)))]
    .map(Number)
    .sort((a, b) => b - a);
  process.stdout.write(`${JSON.stringify({
    ok: true,
    host: new URL(page.url()).hostname,
    path: new URL(page.url()).pathname,
    years,
    yearControlCount: controls.filter((control) =>
      control.options.some((value) => /^20\d{2}$/.test(value))).length,
    requestSubmitted: false,
  })}\n`);
} catch (error) {
  process.stdout.write(`${JSON.stringify({
    ok: false,
    error: error?.message || String(error),
  })}\n`);
  process.exitCode = 1;
} finally {
  await context.close().catch(() => {});
  await browser.close().catch(() => {});
}
