#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { validateAtUsername } from '../src/auth.mjs';
import { readAtPublicKey } from '../src/crypto.mjs';
import {
  buildFactIntWsEnvelope, buildFactIntWsSecurityMaterial,
  FACTINTWS_ENDPOINT_443, FACTINTWS_OPERATION, factIntWsHttpContract,
} from '../src/factintws.mjs';
import { parseFactIntWsResponse } from '../src/factintws_parser.mjs';
import { redact } from '../src/redaction.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH', 'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
let networkRequests = 0;

function output(value) {
  process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
}

function fail(code, message) {
  output({ networkRequests, classification: code, message });
  process.exitCode = 2;
}

function classifyFault(fault) {
  const text = `${fault?.code || ''} ${fault?.reason || ''}`;
  if (/auth|credential|password|username|utilizador/i.test(text)) return 'AUTH_ERROR';
  if (/authoriz|permiss|forbidden|acesso/i.test(text)) return 'AUTHORIZATION_ERROR';
  return 'REMOTE_FAULT';
}

function sendOnce({ xml, pfx, passphrase }) {
  const contract = factIntWsHttpContract(FACTINTWS_OPERATION);
  return new Promise((resolve, reject) => {
    const request = https.request(contract.endpoint, {
      method: contract.method,
      pfx,
      passphrase,
      rejectUnauthorized: true,
      minVersion: 'TLSv1.2',
      headers: { ...contract.headers, 'Content-Length': Buffer.byteLength(xml) },
      timeout: 20_000,
    }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket);
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => {
        try {
          const bytes = Buffer.concat(chunks);
          const body = response.headers['content-encoding'] === 'gzip' ? gunzipSync(bytes).toString('utf8') : bytes.toString('utf8');
          resolve({ httpStatus: response.statusCode ?? null, tls, body });
        } catch (error) { reject(error); }
      });
    });
    request.on('timeout', () => request.destroy(new Error('connection timeout')));
    request.on('error', reject);
    request.end(xml);
  });
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1') return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  if (required.some((key) => !process.env[key])) return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
  const created = new Date().toISOString();
  const aesKey = randomBytes(16);
  try {
    const credentials = buildFactIntWsSecurityMaterial({
      aesKey, created, password: process.env.AT_PASSWORD,
      rsaPublicKey: readAtPublicKey(process.env.AT_CIPHER_CERT_PATH),
    });
    const xml = buildFactIntWsEnvelope({ username, credentials,
      input: { nif: username.split('/')[0], year: String(new Date().getUTCFullYear()),
        channel: { system: 'A', version: 'Taxy 0.7.4' } } });
    networkRequests = 1;
    const response = await sendOnce({ xml, pfx, passphrase: process.env.AT_CLIENT_PFX_PASSWORD });
    let parsed;
    try { parsed = parseFactIntWsResponse(response.body, FACTINTWS_OPERATION); }
    catch (error) {
      output({ networkRequests, mTLS: response.tls.authorized ? 'SUCCESS' : 'FAILED', authorized: response.tls.authorized,
        httpStatus: response.httpStatus, soapResponse: /^\s*(?:<\?xml[^>]*>\s*)?</.test(response.body) ? 'YES' : 'NO',
        classification: 'PARSING_ERROR', parsingError: error.message });
      process.exitCode = 2; return;
    }
    const classification = parsed.fault ? classifyFault(parsed.fault) : 'SUCCESS';
    output({ networkRequests, operation: FACTINTWS_OPERATION,
      mTLS: response.tls.authorized ? 'SUCCESS' : 'FAILED', authorized: response.tls.authorized,
      tlsVersion: response.tls.protocol, httpStatus: response.httpStatus, soapResponse: 'YES',
      soapFault: parsed.fault || null, estadoOperacao: parsed.result?.estadoOperacao ?? null,
      desc: parsed.result?.desc ?? null, operationResponseDetected: !parsed.fault,
      aggregateFieldPresence: parsed.totals ? Object.fromEntries(Object.entries(parsed.totals).map(([key, value]) => [key, value != null])) : {},
      classification });
    if (classification !== 'SUCCESS') process.exitCode = 2;
  } finally {
    aesKey.fill(0);
    pfx.fill(0);
  }
}

main().catch((error) => {
  const identityRejected = /certificate required|bad certificate|certificate unknown/i.test(error.message);
  const tlsError = identityRejected || /ssl|tls|handshake|bad record mac/i.test(error.message);
  output({ networkRequests, classification: identityRejected ? 'TLS_IDENTITY_REJECTED' : (tlsError ? 'TLS_ERROR' : 'UNKNOWN'),
    errorCode: error.code || null, message: error.message });
  process.exitCode = 2;
});
