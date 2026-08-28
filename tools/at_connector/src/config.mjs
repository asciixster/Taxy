import { existsSync } from 'node:fs';

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
    throw new AtConfigurationError('Production calls are disabled in Taxy 0.7');
  }

  const required = ['AT_PFX_PATH', 'AT_PFX_PASSWORD'];
  if (requireAtCredentials) {
    required.push('AT_CIPHER_CERT_PATH', 'AT_USERNAME', 'AT_PASSWORD');
  }
  for (const key of required) {
    if (!env[key]) throw new AtConfigurationError(`Missing required configuration: ${key}`);
  }
  for (const key of ['AT_PFX_PATH', ...(requireAtCredentials ? ['AT_CIPHER_CERT_PATH'] : [])]) {
    if (!existsSync(env[key])) throw new AtConfigurationError(`Configured file does not exist: ${key}`);
  }

  return Object.freeze({
    environment: atEnvironment,
    pfxPath: env.AT_PFX_PATH,
    pfxPassword: env.AT_PFX_PASSWORD,
    cipherCertificatePath: env.AT_CIPHER_CERT_PATH || null,
    username: env.AT_USERNAME || null,
    password: env.AT_PASSWORD || null,
  });
}
