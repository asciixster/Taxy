import fs from 'node:fs';
import process from 'node:process';
import { chromium } from 'playwright';
import {
  extractDm3IrsHtmlVersion,
  parseForwardForm,
  parseLoginBootstrap,
  PORTAL_IRS_START,
} from '../src/portal_prefill.mjs';
import {
  normalizePortalPrefillModel,
  summarizeNormalizedPrefill,
} from '../src/portal_prefill_normalizer.mjs';

const envPath = process.argv[2];
const taxYear = Number(process.argv[3] || 2025);
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
if (![2024, 2025].includes(taxYear)) {
  process.stdout.write('{"error":"SUPPORTED_TAX_YEAR_REQUIRED"}\n');
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
const stages = [];
const record = (stage, extra = {}) => stages.push({ stage, ...extra });

try {
  const landing = await context.request.get(PORTAL_IRS_START, {
    timeout: 60000,
    maxRedirects: 10,
  });
  record('login-page', { host: new URL(landing.url()).hostname });
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
  record('authenticated', {
    host: new URL(page.url()).hostname,
    path: new URL(page.url()).pathname,
  });

  const prefillChoice = page.getByText(
    /Obtenção de uma declaração pré-preenchida/i,
  ).first();
  await prefillChoice.waitFor({ state: 'visible', timeout: 60000 });
  await prefillChoice.click();

  const yearSelects = page.locator('select:visible');
  const yearCount = await yearSelects.count();
  let selectedYear = false;
  for (let index = 0; index < yearCount; index += 1) {
    const select = yearSelects.nth(index);
    const options = await select.locator('option').allTextContents();
    if (options.some((text) => new RegExp(`^\\s*${taxYear}\\s*$`).test(text))) {
      await select.selectOption({ label: String(taxYear) });
      selectedYear = true;
      break;
    }
  }
  if (!selectedYear) throw new Error('PREFILL_YEAR_CONTROL_NOT_FOUND');

  const visibleTextInputs = page.locator('input:visible[type=text],input:visible:not([type])');
  const textInputCount = await visibleTextInputs.count();
  let nifFilled = false;
  for (let index = 0; index < textInputCount; index += 1) {
    const input = visibleTextInputs.nth(index);
    const maxLength = await input.getAttribute('maxlength');
    const name = String(await input.getAttribute('name') || '');
    const id = String(await input.getAttribute('id') || '');
    if (maxLength === '9' || /nif/i.test(`${name} ${id}`)) {
      await input.fill(nif);
      nifFilled = true;
      break;
    }
  }
  if (!nifFilled) throw new Error('PREFILL_NIF_CONTROL_NOT_FOUND');

  record('prefill-form-ready', { taxYear });
  const continueButton = page.getByRole('button', { name: /Continuar/i }).last();
  const prefillResponse = page.waitForResponse((response) => {
    try {
      return new URL(response.url()).pathname.endsWith('/app/prePreencher') &&
        response.request().method() === 'POST';
    } catch {
      return false;
    }
  }, { timeout: 60000 });
  const declarationNavigation = page.waitForNavigation({
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  }).catch(() => null);
  await continueButton.click();
  const officialResponse = await prefillResponse;
  if (officialResponse.status() >= 400) {
    throw new Error('PREFILL_UPSTREAM_REJECTED');
  }
  await declarationNavigation;
  if (new URL(page.url()).hostname.endsWith('acesso.gov.pt')) {
    throw new Error('PREFILL_SESSION_NOT_PROPAGATED');
  }

  const shape = await page.evaluate(() => {
    const angularApi = globalThis.angular;
    if (!angularApi) return { modelAvailable: false, reason: 'ANGULAR_NOT_FOUND' };
    const roots = [document.body, document.querySelector('[ng-app]')].filter(Boolean);
    let injector;
    for (const root of roots) {
      try {
        injector = angularApi.element(root).injector();
        if (injector) break;
      } catch {}
    }
    if (!injector) return { modelAvailable: false, reason: 'INJECTOR_NOT_FOUND' };
    let model;
    try { model = injector.get('lfAppService').getModel(); } catch {
      return { modelAvailable: false, reason: 'MODEL_NOT_FOUND' };
    }
    const annexes = [];
    const rootKeys = Object.keys(model || {});
    for (const [key, annex] of [
      ['anexoA', 'A'], ['anexoB', 'B'], ['anexoC', 'C'], ['anexoD', 'D'],
      ['anexoE', 'E'], ['anexoF', 'F'], ['anexoG', 'G'], ['anexoG1', 'G1'],
      ['anexoH', 'H'], ['anexoI', 'I'], ['anexoJ', 'J'], ['anexoL', 'L'],
      ['anexoSs', 'SS'],
    ]) {
      const value = model?.[key];
      if (Array.isArray(value) ? value.length > 0 : value && typeof value === 'object') {
        annexes.push(annex);
      }
    }
    let scalarFields = 0;
    let populatedScalarFields = 0;
    let tableRows = 0;
    const groups = {};
    const fieldPaths = [];
    const tableShapes = {};
    const seen = new Set();
    const walk = (value, path = '', depth = 0) => {
      if (depth > 20 || value == null || typeof value !== 'object' || seen.has(value)) return;
      seen.add(value);
      if (Array.isArray(value)) {
        tableRows += value.length;
        if (value.length > 0) {
          const keys = new Set();
          for (const row of value.slice(0, 20)) {
            if (row && typeof row === 'object') {
              for (const key of Object.keys(row)) keys.add(key);
            }
          }
          tableShapes[path] = [...keys].sort();
        }
      }
      for (const [key, child] of Object.entries(value)) {
        const next = path ? `${path}.${key}` : key;
        if (child && typeof child === 'object') {
          walk(child, next, depth + 1);
        } else {
          scalarFields += 1;
          fieldPaths.push(next);
          if (child !== null && child !== undefined && child !== '') populatedScalarFields += 1;
          const group = next.split('.')[0];
          groups[group] = (groups[group] || 0) + 1;
        }
      }
    };
    walk(model);
    return {
      modelAvailable: true,
      rootKeyCount: rootKeys.length,
      annexes,
      scalarFields,
      populatedScalarFields,
      tableRows,
      groups,
      fieldPaths: fieldPaths.sort(),
      tableShapes,
      hasCategoryA: annexes.includes('A'),
      hasCategoryB: annexes.includes('B') || annexes.includes('C'),
      hasHousehold: Boolean(model?.rosto?.quadro06),
    };
  });
  const rawModel = await page.evaluate(() => {
    const angularApi = globalThis.angular;
    const roots = [document.body, document.querySelector('[ng-app]')].filter(Boolean);
    let injector;
    for (const root of roots) {
      try {
        injector = angularApi?.element(root).injector();
        if (injector) break;
      } catch {}
    }
    if (!injector) throw new Error('INJECTOR_NOT_FOUND');
    const model = injector.get('lfAppService').getModel();
    return JSON.parse(angularApi.toJson(model));
  });
  const normalized = normalizePortalPrefillModel(rawModel, { taxYear });
  const normalizedSummary = summarizeNormalizedPrefill(normalized);
  record('prefill-loaded', {
    host: new URL(page.url()).hostname,
    path: new URL(page.url()).pathname,
  });
  process.stdout.write(`${JSON.stringify({
    ok: true,
    stages,
    shape,
    normalizedSummary,
  }, null, 2)}\n`);
} catch (error) {
  process.stdout.write(`${JSON.stringify({
    ok: false,
    stages,
    error: String(error?.message || 'UNKNOWN'),
    currentHost: (() => { try { return new URL(page.url()).hostname; } catch { return null; } })(),
    currentPath: (() => { try { return new URL(page.url()).pathname; } catch { return null; } })(),
  }, null, 2)}\n`);
  process.exitCode = 1;
} finally {
  await context.close();
  await browser.close();
}
