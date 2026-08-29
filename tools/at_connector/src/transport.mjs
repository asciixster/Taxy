import https from 'node:https';
import { readFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { AtConnectorError, AtErrorCode } from './errors.mjs';
import { tlsFailureDiagnostic } from './tls_preflight.mjs';

export class AtTransportError extends AtConnectorError {
  constructor(message, cause, tlsStage = 'handshake') {
    const clientRejected = /certificate required|alert bad certificate|certificate unknown/i.test(cause?.message || '');
    const tlsDiagnostic = tlsFailureDiagnostic(cause, tlsStage);
    super(clientRejected ? AtErrorCode.CLIENT_CERT_REJECTED : AtErrorCode.TLS_ERROR, message, {
      cause, details: { tlsDiagnostic },
    });
    this.name = 'AtTransportError';
    this.tlsDiagnostic = tlsDiagnostic;
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
  const cipher = socket?.getCipher?.() || null;
  return Object.freeze({
    authorized: socket?.authorized === true,
    authorizationError: socket?.authorizationError || null,
    protocol: socket?.getProtocol?.() || null,
    cipher: cipher?.standardName || cipher?.name || null,
    cipherVersion: cipher?.version || null,
    alpnProtocol: socket?.alpnProtocol || null,
    servername: socket?.servername || null,
  });
}

export function sendMtlsSoap({ endpoint, pfxPath, pfxPassword, xml, soapAction, timeoutMs, connectTimeoutMs = timeoutMs ?? 20_000, totalTimeoutMs = timeoutMs ?? 20_000 }) {
  const started = performance.now();
  return new Promise((resolve, reject) => {
    let pfx;
    try { pfx = readFileSync(pfxPath); } catch (error) { reject(new AtTransportError('Unable to read client certificate', error)); return; }
    let tlsStage = 'socket-creation';
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
    const totalTimer = setTimeout(() => request.destroy(new Error('AT request total timeout exceeded')), totalTimeoutMs);
    request.on('socket', (socket) => {
      tlsStage = 'tls-handshake';
      socket.once('secureConnect', () => { tlsStage = 'http-response'; });
    });
    request.on('timeout', () => request.destroy(new Error('AT connection timeout exceeded')));
    request.on('error', (error) => {
      clearTimeout(totalTimer);
      reject(new AtTransportError('AT TLS/HTTP request failed', error, tlsStage));
    });
    request.end(xml);
    pfx.fill(0);
  });
}
