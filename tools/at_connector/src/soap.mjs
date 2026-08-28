const SOAP_NS = 'http://schemas.xmlsoap.org/soap/envelope/';
const WSSE_NS = 'http://schemas.xmlsoap.org/ws/2002/12/secext';

export function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;').replaceAll("'", '&apos;');
}

export function securityHeader(username, credentials) {
  return `<S:Header><wss:Security xmlns:wss="${WSSE_NS}"><wss:UsernameToken>` +
    `<wss:Username>${escapeXml(username)}</wss:Username>` +
    `<wss:Password>${escapeXml(credentials.password)}</wss:Password>` +
    `<wss:Nonce>${escapeXml(credentials.nonce)}</wss:Nonce>` +
    `<wss:Created>${escapeXml(credentials.created)}</wss:Created>` +
    `</wss:UsernameToken></wss:Security></S:Header>`;
}

export function soapEnvelope({ header = '<S:Header/>', body = '' } = {}) {
  return `<?xml version="1.0" encoding="UTF-8"?>` +
    `<S:Envelope xmlns:S="${SOAP_NS}">${header}<S:Body>${body}</S:Body></S:Envelope>`;
}

export function connectivityProbeEnvelope() {
  return soapEnvelope();
}
