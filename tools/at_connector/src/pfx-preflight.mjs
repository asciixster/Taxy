import { existsSync, readFileSync } from 'node:fs';
import { createSecureContext } from 'node:tls';

export const PfxPreflightClassification = Object.freeze({
  READY: 'READY',
  FILE_NOT_FOUND: 'PFX_FILE_NOT_FOUND',
  PASSWORD_MISSING: 'PFX_PASSWORD_MISSING',
  PASSWORD_INVALID: 'PFX_PASSWORD_INVALID',
  CERTIFICATE_MISSING: 'PFX_CERTIFICATE_MISSING',
  PRIVATE_KEY_MISSING: 'PFX_PRIVATE_KEY_MISSING',
  PARSE_ERROR: 'PFX_PARSE_ERROR',
});

function result({ pfxFileFound = false, pfxOpened = false, certificatePresent = false, privateKeyPresent = false, classification }) {
  return Object.freeze({ pfxFileFound, pfxOpened, certificatePresent, privateKeyPresent, classification });
}

export function preflightPkcs12({ pfxPath, pfxPassword }, dependencies = {}) {
  const fileExists = dependencies.existsSync || existsSync;
  const readFile = dependencies.readFileSync || readFileSync;
  const openSecureContext = dependencies.createSecureContext || createSecureContext;

  if (!pfxPath || !fileExists(pfxPath)) {
    return result({ classification: PfxPreflightClassification.FILE_NOT_FOUND });
  }
  if (pfxPassword == null || pfxPassword === '') {
    return result({ pfxFileFound: true, classification: PfxPreflightClassification.PASSWORD_MISSING });
  }

  let pfx;
  try {
    pfx = readFile(pfxPath);
    const secureContext = openSecureContext({ pfx, passphrase: pfxPassword });
    const certificatePresent = Boolean(secureContext.context.getCertificate());
    if (!certificatePresent) {
      return result({ pfxFileFound: true, pfxOpened: true, privateKeyPresent: true, classification: PfxPreflightClassification.CERTIFICATE_MISSING });
    }
    // Node's PKCS#12 loader refuses a certificate-only bundle. Reaching this
    // point therefore proves that both the leaf certificate and private key
    // were accepted without exposing either one.
    return result({ pfxFileFound: true, pfxOpened: true, certificatePresent: true, privateKeyPresent: true, classification: PfxPreflightClassification.READY });
  } catch (error) {
    const message = String(error?.message || '');
    if (/mac verify failure|invalid password|bad decrypt|mac verify error/i.test(message)) {
      return result({ pfxFileFound: true, classification: PfxPreflightClassification.PASSWORD_INVALID });
    }
    if (/private key/i.test(message)) {
      return result({ pfxFileFound: true, pfxOpened: true, certificatePresent: true, classification: PfxPreflightClassification.PRIVATE_KEY_MISSING });
    }
    if (/certificate/i.test(message)) {
      return result({ pfxFileFound: true, pfxOpened: true, privateKeyPresent: true, classification: PfxPreflightClassification.CERTIFICATE_MISSING });
    }
    return result({ pfxFileFound: true, classification: PfxPreflightClassification.PARSE_ERROR });
  } finally {
    pfx?.fill?.(0);
  }
}
