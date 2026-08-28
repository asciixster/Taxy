import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { AtConnectorError, AtErrorCode } from './errors.mjs';

export const REPOSITORY_ENV_LOCAL = fileURLToPath(new URL('../../../.env.local', import.meta.url));

function parseEnvValue(rawValue) {
  const value = rawValue.trim();
  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    return value.slice(1, -1);
  }
  return value;
}

export function loadEnvLocalFallback(env = process.env, envFilePath = REPOSITORY_ENV_LOCAL) {
  const merged = { ...env };
  if (!existsSync(envFilePath)) return Object.freeze({ env: Object.freeze(merged), found: false });
  const contents = readFileSync(envFilePath, 'utf8');
  for (const line of contents.split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!match) continue;
    const [, key, rawValue] = match;
    if (merged[key] == null || merged[key] === '') merged[key] = parseEnvValue(rawValue);
  }
  return Object.freeze({ env: Object.freeze(merged), found: true });
}

export class AtConfigurationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AtConfigurationError';
  }
}

export function loadConfig(env = process.env, { requireAtCredentials = false } = {}) {
  const atEnvironment = env.AT_ENV || 'test';
  if (!['test', 'production'].includes(atEnvironment)) {
    throw new AtConfigurationError('AT_ENV must be test or production');
  }
  if (atEnvironment === 'production') {
    throw new AtConnectorError(AtErrorCode.PRODUCTION_BLOCKED, 'Production calls are disabled in Taxy 0.7.1');
  }

  const pfxPath = env.AT_CLIENT_PFX_PATH ?? env.AT_PFX_PATH;
  const pfxPassword = env.AT_CLIENT_PFX_PASSWORD ?? env.AT_PFX_PASSWORD;
  const normalized = { ...env, AT_CLIENT_PFX_PATH: pfxPath, AT_CLIENT_PFX_PASSWORD: pfxPassword };
  const required = ['AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
  if (requireAtCredentials) {
    required.push('AT_CIPHER_CERT_PATH', 'AT_USERNAME', 'AT_PASSWORD');
  }
  for (const key of required) {
    if (!normalized[key]) {
      const code = requireAtCredentials ? AtErrorCode.AUTH_CONFIGURATION_MISSING : null;
      if (code) throw new AtConnectorError(code, `Missing required configuration: ${key}`);
      throw new AtConfigurationError(`Missing required configuration: ${key}`);
    }
  }
  for (const key of ['AT_CLIENT_PFX_PATH', ...(requireAtCredentials ? ['AT_CIPHER_CERT_PATH'] : [])]) {
    if (!existsSync(normalized[key])) throw new AtConfigurationError(`Configured file does not exist: ${key}`);
  }

  return Object.freeze({
    environment: atEnvironment,
    pfxPath,
    pfxPassword,
    cipherCertificatePath: env.AT_CIPHER_CERT_PATH || null,
    username: env.AT_USERNAME || null,
    password: env.AT_PASSWORD || null,
  });
}
