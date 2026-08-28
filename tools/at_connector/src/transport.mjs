import https from 'node:https';
import { readFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { AtConnectorError, AtErrorCode } from './errors.mjs';

export class AtTransportError extends AtConnectorError {
  constructor(message, cause) {
    const clientRejected = /certificate required|alert bad certificate|certificate unknown/i.test(cause?.message || '');
    super(clientRejected ? AtErrorCode.CLIENT_CERT_REJECTED : AtErrorCode.TLS_ERROR, message, { cause });
    this.name = 'AtTransportError';
  }
}

export function buildSoapHeaders(xml, soapAction) {
  const headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'Content-Length': Buffer.byteLength(xml),
    'User-Agent': 'Taxy-AT-Connector/0.7.2',
  };
  if (soapAction !== undefined && soapAction !== null) headers.SOAPAction = `"${soapAction}"`;
  return headers;
}

export function sendMtlsSoap({ endpoint, pfxPath, pfxPassword, xml, soapAction, timeoutMs, connectTimeoutMs = timeoutMs ?? 20_000, totalTimeoutMs = timeoutMs ?? 20_000 }) {
  const started = performance.now();
  return new Promise((resolve, reject) => {
    let pfx;
    try { pfx = readFileSync(pfxPath); } catch (error) { reject(new AtTransportError('Unable to read client certificate', error)); return; }
    const request = https.request(endpoint, {
      method: 'POST',
      pfx,
      passphrase: pfxPassword,
      rejectUnauthorized: true,
      minVersion: 'TLSv1.2',
      headers: buildSoapHeaders(xml, soapAction),
      timeout: connectTimeoutMs,
    }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => {
        clearTimeout(totalTimer);
        resolve({
        statusCode: response.statusCode,
        headers: response.headers,
        body: Buffer.concat(chunks).toString('utf8'),
        tls: Object.freeze({
          authorized: response.socket.authorized,
          authorizationError: response.socket.authorizationError || null,
          protocol: response.socket.getProtocol?.() || null,
          cipher: response.socket.getCipher?.()?.standardName || response.socket.getCipher?.()?.name || null,
        }),
        durationMs: Math.round(performance.now() - started),
        });
      });
    });
    const totalTimer = setTimeout(() => request.destroy(new Error('AT request total timeout exceeded')), totalTimeoutMs);
    request.on('timeout', () => request.destroy(new Error('AT connection timeout exceeded')));
    request.on('error', (error) => {
      clearTimeout(totalTimer);
      reject(new AtTransportError('AT TLS/HTTP request failed', error));
    });
    request.end(xml);
    pfx.fill(0);
  });
}
