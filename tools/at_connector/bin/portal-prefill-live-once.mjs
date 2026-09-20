import fs from 'node:fs';
import process from 'node:process';
import { request } from 'playwright';
import { runPortalPrefillOnce } from '../src/portal_prefill.mjs';

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
try {
  const result = await runPortalPrefillOnce({ request, nif, password });
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} catch (error) {
  process.stdout.write(`${JSON.stringify({
    error: String(error?.message || 'UNKNOWN'),
    credentialsPresent: Boolean(nif && password),
  }, null, 2)}\n`);
  process.exitCode = 1;
}
