import https from 'node:https';
import { readFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { AtConnectorError, AtErrorCode } from './errors.mjs';

export function sanitizedTlsFailure(cause) {
  const message = String(cause?.message || '');
  const code = /^[A-Z0-9_]{2,64}$/.test(String(cause?.code || '')) ? String(cause.code) : 'NOT_AVAILABLE';
  let reason = 'UNKNOWN_TLS_FAILURE';
  if (/certificate required/i.test(message)) reason = 'CERTIFICATE_REQUIRED';
  else if (/certificate unknown/i.test(message)) reason = 'CERTIFICATE_UNKNOWN';
  else if (/unknown ca/i.test(message)) reason = 'UNKNOWN_CA';
  else if (/bad certificate/i.test(message)) reason = 'BAD_CERTIFICATE';
  else if (/handshake failure/i.test(message)) reason = 'HANDSHAKE_FAILURE';
  else if (/socket hang up|reset by peer|ECONNRESET/i.test(message)) reason = 'CONNECTION_RESET_DURING_TLS';
  else {
    const alert = message.match(/alert(?: number)?\s*(\d{1,3})/i);
    if (alert) reason = `TLS_ALERT_${alert[1]}`;
  }
  const stage = /ENOTFOUND|ECONNREFUSED|ETIMEDOUT/i.test(`${code} ${message}`) ? 'NETWORK_CONNECT' : 'TLS_HANDSHAKE';
  return Object.freeze({ tlsErrorCode: code, tlsErrorReasonSanitized: reason, tlsStage: stage });
}

export class AtTransportError extends AtConnectorError {
  constructor(message, cause) {
    const clientRejected = /certificate required|alert bad certificate|certificate unknown/i.test(cause?.message || '');
    super(clientRejected ? AtErrorCode.CLIENT_CERT_REJECTED : AtErrorCode.TLS_ERROR, message, { cause, details: sanitizedTlsFailure(cause) });
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

export function tlsMetadataFromSocket(socket) {
  return Object.freeze({
    authorized: socket?.authorized === true,
    authorizationError: socket?.authorizationError || null,
    protocol: socket?.getProtocol?.() || null,
    cipher: socket?.getCipher?.()?.standardName || socket?.getCipher?.()?.name || null,
  });
}

export function sendMtlsSoap({ endpoint, pfxPath, pfxPassword, xml, soapAction, timeoutMs, connectTimeoutMs = timeoutMs ?? 20_000, totalTimeoutMs = timeoutMs ?? 20_000, onRequestStart = null }) {
  const started = performance.now();
  return new Promise((resolve, reject) => {
    let pfx;
    try { pfx = readFileSync(pfxPath); } catch (error) { reject(new AtTransportError('Unable to read client certificate', error)); return; }
    let request;
    try {
      request = https.request(endpoint, {
        method: 'POST',
        pfx,
        passphrase: pfxPassword,
        rejectUnauthorized: true,
        minVersion: 'TLSv1.2',
        headers: buildSoapHeaders(xml, soapAction),
        timeout: connectTimeoutMs,
      }, (response) => {
        const chunks = [];
        // Capture while Node still associates the response with its TLS socket.
        const tls = tlsMetadataFromSocket(response.socket);
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          clearTimeout(totalTimer);
          resolve({
            statusCode: response.statusCode,
            headers: response.headers,
            body: Buffer.concat(chunks).toString('utf8'),
            tls,
            durationMs: Math.round(performance.now() - started),
          });
        });
      });
    } catch (error) {
      pfx.fill(0);
      reject(new AtTransportError('AT TLS/HTTP request failed', error));
      return;
    }
    onRequestStart?.();
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
