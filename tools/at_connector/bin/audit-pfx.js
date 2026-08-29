#!/usr/bin/env node
import { loadEnvLocalFallback } from '../src/config.mjs';
import { auditPkcs12 } from '../src/pfx-audit.mjs';

try {
  const { env } = loadEnvLocalFallback(process.env);
  const result = auditPkcs12({
    pfxPath: env.AT_CLIENT_PFX_PATH ?? env.AT_PFX_PATH,
    pfxPassword: env.AT_CLIENT_PFX_PASSWORD ?? env.AT_PFX_PASSWORD,
  });
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} catch (error) {
  process.stdout.write(`${JSON.stringify({ classification: error.code || 'PFX_AUDIT_ERROR' })}\n`);
  process.exitCode = 2;
}
