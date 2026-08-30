import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { createSecureContext } from 'node:tls';
import { X509Certificate } from 'node:crypto';

export const PfxPreflightClassification = Object.freeze({
  READY: 'READY',
  FILE_NOT_FOUND: 'PFX_FILE_NOT_FOUND',
  PASSWORD_MISSING: 'PFX_PASSWORD_MISSING',
  PASSWORD_INVALID: 'PFX_PASSWORD_INVALID',
  CERTIFICATE_MISSING: 'PFX_CERTIFICATE_MISSING',
  PRIVATE_KEY_MISSING: 'PFX_PRIVATE_KEY_MISSING',
  PARSE_ERROR: 'PFX_PARSE_ERROR',
});

const REDACTED = '[REDACTED]';

export function sanitizeTlsDiagnostic(value) {
  return String(value ?? '')
    .replace(/-----BEGIN[\s\S]*?-----END[^-]*-----/g, REDACTED)
    .replace(/\b\d{9}\b/g, REDACTED)
    .replace(/(?:pass(?:word|phrase)?|pin|token)\s*[=:]\s*\S+/gi, `credential=${REDACTED}`)
    .replace(/[A-Fa-f0-9]{32,}/g, REDACTED)
    .replace(/[\r\n]+/g, ' ')
    .trim()
    .slice(0, 500);
}

export function tlsFailureDiagnostic(error, stage = 'handshake') {
  return Object.freeze({
    tlsErrorCode: sanitizeTlsDiagnostic(error?.code || 'TLS_ERROR'),
    tlsErrorReasonSanitized: sanitizeTlsDiagnostic(error?.reason || error?.message || 'TLS failure'),
    tlsStage: stage,
  });
}

export function resolveOpenSslPath(env = process.env) {
  const candidates = [
    env.OPENSSL_PATH,
    process.platform === 'win32' ? 'C:\\Program Files\\Git\\usr\\bin\\openssl.exe' : null,
    'openssl',
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (candidate === 'openssl' || existsSync(candidate)) return candidate;
  }
  return null;
}

function runOpenSsl(opensslPath, args, { password = null } = {}) {
  const result = spawnSync(opensslPath, args, {
    encoding: 'utf8',
    input: password == null ? undefined : `${password}\n`,
    windowsHide: true,
    timeout: 15_000,
    maxBuffer: 1024 * 1024,
  });
  return {
    ok: result.status === 0,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
    error: result.error || null,
  };
}

function failure(classification, details = {}) {
  return Object.freeze({
    classification,
    pfxOpened: false,
    privateKeyPresent: false,
    certificatePresent: false,
    certificateCount: 0,
    intermediatePresent: false,
    chainClassification: 'CHAIN_UNKNOWN',
    ekuClientAuth: null,
    caValidation: 'NOT_PERFORMED',
    ...details,
  });
}

/**
 * Performs a local-only PKCS#12 readiness audit. Passwords are delivered to
 * OpenSSL over stdin, never as command-line arguments, and extracted public
 * certificates live only in a temporary directory removed before return.
 */
export function inspectPfxReadiness({ pfxPath, pfxPassword, opensslPath = resolveOpenSslPath() }) {
  if (!pfxPath || !existsSync(pfxPath)) return failure(PfxPreflightClassification.FILE_NOT_FOUND);
  if (!pfxPassword) return failure(PfxPreflightClassification.PASSWORD_MISSING);

  const pfxBytes = readFileSync(pfxPath);
  try {
    createSecureContext({ pfx: pfxBytes, passphrase: pfxPassword, minVersion: 'TLSv1.2' });
  } catch (error) {
    const text = `${error?.code || ''} ${error?.message || ''}`;
    const classification = /mac verify|mac_verify|invalid password|bad decrypt/i.test(text)
      ? PfxPreflightClassification.PASSWORD_INVALID
      : PfxPreflightClassification.PARSE_ERROR;
    return failure(classification, { error: tlsFailureDiagnostic(error, 'pfx-open') });
  } finally {
    pfxBytes.fill(0);
  }

  if (!opensslPath) {
    return failure(PfxPreflightClassification.PARSE_ERROR, {
      pfxOpened: true,
      error: tlsFailureDiagnostic(new Error('OpenSSL executable unavailable'), 'pfx-inspection'),
    });
  }

  const info = runOpenSsl(opensslPath, ['pkcs12', '-in', pfxPath, '-passin', 'stdin', '-info', '-noout'], { password: pfxPassword });
  if (!info.ok) {
    const text = `${info.stderr} ${info.error?.message || ''}`;
    const classification = /mac verify|invalid password|bad decrypt/i.test(text)
      ? PfxPreflightClassification.PASSWORD_INVALID
      : PfxPreflightClassification.PARSE_ERROR;
    return failure(classification, {
      pfxOpened: true,
      error: tlsFailureDiagnostic(new Error(text), 'pfx-inspection'),
    });
  }

  const certificateCount = (info.stderr.match(/Certificate bag/gi) || []).length;
  const privateKeyPresent = /(?:Shrouded Keybag|Key bag)/i.test(info.stderr);
  if (certificateCount === 0) return failure(PfxPreflightClassification.CERTIFICATE_MISSING, { pfxOpened: true });
  if (!privateKeyPresent) return failure(PfxPreflightClassification.PRIVATE_KEY_MISSING, {
    pfxOpened: true, certificatePresent: true, certificateCount,
  });

  const work = mkdtempSync(join(tmpdir(), 'taxy-pfx-audit-'));
  try {
    const clientPath = join(work, 'client.pem');
    const caPath = join(work, 'ca.pem');
    const client = runOpenSsl(opensslPath, ['pkcs12', '-in', pfxPath, '-passin', 'stdin', '-clcerts', '-nokeys', '-out', clientPath], { password: pfxPassword });
    const cas = runOpenSsl(opensslPath, ['pkcs12', '-in', pfxPath, '-passin', 'stdin', '-cacerts', '-nokeys', '-out', caPath], { password: pfxPassword });
    if (!client.ok) return failure(PfxPreflightClassification.CERTIFICATE_MISSING, { pfxOpened: true, privateKeyPresent, certificateCount });

    let clientCertificateFingerprint = null;
    try {
      const certificate = new X509Certificate(readFileSync(clientPath));
      clientCertificateFingerprint = certificate.fingerprint256.replaceAll(':', '').toLowerCase();
    } catch {
      return failure(PfxPreflightClassification.CERTIFICATE_MISSING, {
        pfxOpened: true, privateKeyPresent, certificateCount,
      });
    }

    const text = runOpenSsl(opensslPath, ['x509', '-in', clientPath, '-noout', '-text']);
    const ekuClientAuth = text.ok
      ? /TLS Web Client Authentication/i.test(text.stdout)
      : null;
    const intermediatePresent = cas.ok && /BEGIN CERTIFICATE/.test(readFileSync(caPath, 'utf8'));
    let chainClassification = intermediatePresent ? 'CHAIN_UNKNOWN' : 'CHAIN_INTERMEDIATE_MISSING';
    let caValidation = 'NOT_PERFORMED';
    if (intermediatePresent) {
      const verify = runOpenSsl(opensslPath, ['verify', '-purpose', 'sslclient', '-CAfile', caPath, clientPath]);
      chainClassification = verify.ok ? 'CHAIN_VALID' : 'CHAIN_INVALID';
      caValidation = verify.ok ? 'VALID' : 'INVALID';
    }

    const ready = ekuClientAuth === true && chainClassification === 'CHAIN_VALID';
    return Object.freeze({
      classification: ready ? PfxPreflightClassification.READY : PfxPreflightClassification.PARSE_ERROR,
      pfxBasename: basename(pfxPath),
      pfxOpened: true,
      privateKeyPresent,
      certificatePresent: true,
      certificateCount,
      intermediatePresent,
      chainClassification,
      ekuClientAuth,
      caValidation,
      clientCertificateFingerprint,
    });
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
}
