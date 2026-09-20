const LOGIN_HOST_SUFFIX = 'acesso.gov.pt';

export const PORTAL_IRS_START =
  'https://irs.portaldasfinancas.gov.pt/app/entrega/v2026';
export const PORTAL_IRS_PREFILL =
  'https://irs.portaldasfinancas.gov.pt/app/prePreencher';

const decodeHtml = (value) => String(value || '')
  .replace(/&quot;/gi, '"')
  .replace(/&#0*39;|&apos;/gi, "'")
  .replace(/&lt;/gi, '<')
  .replace(/&gt;/gi, '>')
  .replace(/&amp;/gi, '&');

const modelValue = (html, name) => {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = String(html).match(new RegExp(
    `${escaped}\\s*:\\s*(?:stringOrNull\\s*\\(\\s*)?(?:\\x60([^\\x60]*)\\x60|'([^']*)'|"([^"]*)")`,
    's',
  ));
  return match ? String(match[1] ?? match[2] ?? match[3] ?? '') : '';
};

export function parseLoginBootstrap(html) {
  const script = String(html).match(
    /<script[^>]+id=["']data-attributes["'][^>]*>([\s\S]*?)<\/script>/i,
  )?.[1];
  let attributes = {};
  if (script) {
    try { attributes = JSON.parse(decodeHtml(script.trim())); } catch { attributes = {}; }
  }
  const csrf = modelValue(html, 'token');
  if (!csrf) throw new Error('AT_LOGIN_CONTRACT_CHANGED');
  return {
    attributes,
    csrf,
    action: modelValue(html, 'urlLogin') || 'submissaoFormularioLogin',
    authVersion: modelValue(html, 'authVersion') || '1',
  };
}

const tagAttributes = (tag) => {
  const result = {};
  for (const match of String(tag).matchAll(/([:\w-]+)\s*=\s*(["'])(.*?)\2/gs)) {
    result[match[1].toLowerCase()] = decodeHtml(match[3]);
  }
  return result;
};

export function parseForwardForm(html) {
  const form = String(html).match(
    /<form\b[^>]*id=["']forwardParticipantForm["'][^>]*>[\s\S]*?<\/form>/i,
  )?.[0];
  if (!form) throw new Error('AUTHENTICATION_FAILED');
  const action = tagAttributes(form.match(/^<form\b[^>]*>/i)?.[0]).action;
  if (!action) throw new Error('AT_LOGIN_CONTRACT_CHANGED');
  const fields = {};
  for (const input of form.matchAll(/<input\b[^>]*>/gi)) {
    const attributes = tagAttributes(input[0]);
    if (attributes.name) fields[attributes.name] = attributes.value || '';
  }
  return { action, fields };
}

export function extractDm3IrsHtmlVersion(html) {
  const source = String(html);
  return modelValue(source, 'dm3irshtmlVersion') ||
    source.match(/dm3irshtmlVersion["']?\s*[:=]\s*["']([^"']+)["']/i)?.[1] ||
    null;
}

const unique = (values) => [...new Set(values)];

export function summarizePrefillPayload(payload) {
  const source = String(payload || '');
  const fieldNames = unique([
    ...source.matchAll(/\b((?:Rosto|Anexo(?:A|B|C|D|E|F|G1?|H|I|J|L|SS))q\d{2}[A-Za-z0-9_]*)\b/g),
  ].map((match) => match[1]));
  const groups = {};
  for (const field of fieldNames) {
    const group = field.startsWith('Rosto')
      ? 'Rosto'
      : field.match(/^Anexo(?:SS|G1|[A-JL])/)?.[0] || 'Other';
    groups[group] = (groups[group] || 0) + 1;
  }
  const populated = unique([
    ...source.matchAll(/["']((?:Rosto|Anexo(?:A|B|C|D|E|F|G1?|H|I|J|L|SS))q\d{2}[A-Za-z0-9_]*)["']\s*:\s*(?!null\b|["']{2}|\[\s*\]|\{\s*\})([^,}\n]+)/g),
  ].map((match) => match[1]));
  return {
    fieldCount: fieldNames.length,
    populatedFieldCount: populated.length,
    groups,
    hasCategoryA: (groups.AnexoA || 0) > 0,
    hasCategoryB: (groups.AnexoB || 0) > 0 || (groups.AnexoC || 0) > 0,
    hasHousehold: fieldNames.some((field) => /^Rostoq06/.test(field)),
    hasWithholdingFields: fieldNames.some((field) => /(?:Reten|C05|C06)/i.test(field)),
  };
}

const safeLocation = (value, base) => {
  if (!value) return null;
  const url = new URL(value, base);
  return { host: url.hostname, path: url.pathname };
};

export async function runPortalPrefillOnce({
  request,
  nif,
  password,
  taxYear = 2025,
}) {
  if (!/^\d{9}$/.test(nif) || !password) throw new Error('CREDENTIALS_REQUIRED');
  const client = await request.newContext({
    extraHTTPHeaders: {
      'user-agent': 'Mozilla/5.0 (compatible; TaxyReadOnly/1.0)',
      'accept-language': 'pt-PT,pt;q=0.9',
    },
  });
  try {
    const landing = await client.get(PORTAL_IRS_START, {
      timeout: 60000,
      maxRedirects: 10,
    });
    const landingUrl = new URL(landing.url());
    if (!landingUrl.hostname.endsWith(LOGIN_HOST_SUFFIX)) {
      throw new Error('LOGIN_REDIRECT_NOT_OBSERVED');
    }
    const bootstrap = parseLoginBootstrap(await landing.text());
    const login = await client.post(new URL(bootstrap.action, landing.url()).toString(), {
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
    });
    const loginHtml = await login.text();
    if (/(?:show2FaModal|is2FA)\s*:\s*parseBoolean\(["']true["']\)/.test(loginHtml)) {
      throw new Error('AT_ADDITIONAL_VERIFICATION_REQUIRED');
    }
    const forward = parseForwardForm(loginHtml);
    const app = await client.post(new URL(forward.action, login.url()).toString(), {
      form: forward.fields,
      timeout: 60000,
      maxRedirects: 10,
    });
    const appUrl = new URL(app.url());
    const appHtml = await app.text();
    if (appUrl.hostname !== 'irs.portaldasfinancas.gov.pt') {
      throw new Error('IRS_SESSION_TRANSFER_FAILED');
    }
    const htmlVersion = extractDm3IrsHtmlVersion(appHtml);
    if (!htmlVersion) throw new Error('DM3IRS_HTML_VERSION_NOT_FOUND');
    const state = await client.storageState();
    const cookieScope = state.cookies.map((cookie) => ({
      name: cookie.name,
      domain: cookie.domain,
      path: cookie.path,
      secure: cookie.secure,
      sameSite: cookie.sameSite,
    }));

    const url = new URL(PORTAL_IRS_PREFILL);
    for (const [key, value] of Object.entries({
      nifA: nif,
      ano: String(taxYear),
      tributacaoConjunta: 'false',
      dm3irshtmlVersion: htmlVersion,
      origemUrl: '/app/entrega/v2026',
    })) url.searchParams.set(key, value);

    const prefill = await client.get(url.toString(), {
      timeout: 60000,
      maxRedirects: 0,
    });
    const firstStatus = prefill.status();
    const location = prefill.headers().location || null;
    let result = prefill;
    if (location) {
      result = await client.get(new URL(location, prefill.url()).toString(), {
        timeout: 60000,
        maxRedirects: 10,
      });
    }
    const body = await result.body();
    const text = body.toString('utf8');
    return {
      login: {
        authenticated: true,
        appStatus: app.status(),
        appHost: appUrl.hostname,
        appPath: appUrl.pathname,
        cookieScope,
      },
      request: {
        operation: 'prePreencher',
        method: 'GET',
        taxYear,
        firstStatus,
        location: safeLocation(location, prefill.url()),
      },
      response: {
        status: result.status(),
        host: new URL(result.url()).hostname,
        path: new URL(result.url()).pathname,
        contentType: result.headers()['content-type'] || null,
        byteLength: body.length,
        ...summarizePrefillPayload(text),
      },
    };
  } finally {
    await client.dispose();
  }
}
