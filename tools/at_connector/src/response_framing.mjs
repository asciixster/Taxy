import { brotliDecompressSync, gunzipSync, inflateSync } from 'node:zlib';

export const SOAP11_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';

function headerValue(headers, name) {
  const value = headers?.[name] ?? headers?.[name.toLowerCase()] ?? null;
  return Array.isArray(value) ? value.join(', ') : value == null ? null : String(value);
}

function hasZlibSignature(bytes) {
  return bytes.length >= 2 && bytes[0] === 0x78 && (((bytes[0] << 8) | bytes[1]) % 31 === 0);
}

function decodeCharset(bytes, charset) {
  if (charset === 'iso-8859-1' || charset === 'latin1' || charset === 'windows-1252') {
    return bytes.toString('latin1');
  }
  return bytes.toString('utf8');
}

export function inspectXmlRoot(xml) {
  const normalized = String(xml ?? '').replace(/^\uFEFF/, '');
  const withoutProlog = normalized.replace(/^\s*(?:<\?xml[\s\S]*?\?>\s*)?(?:(?:<!--(?:[\s\S]*?)-->)\s*)*/i, '');
  const match = /^<([A-Za-z_][\w.-]*:)?([A-Za-z_][\w.-]*)\b([^>]*)>/s.exec(withoutProlog);
  if (!match) return Object.freeze({ detected: false, localName: null, prefix: null, namespaceUri: null });
  const prefix = match[1] ? match[1].slice(0, -1) : null;
  const attributes = match[3];
  const namespacePattern = prefix
    ? new RegExp(`\\bxmlns:${prefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*=\\s*(["'])(.*?)\\1`, 's')
    : /\bxmlns\s*=\s*(["'])(.*?)\1/s;
  const namespaceUri = namespacePattern.exec(attributes)?.[2] ?? null;
  return Object.freeze({ detected: true, localName: match[2], prefix, namespaceUri });
}

export function decodeHttpEntity(bytes, contentEncoding) {
  const encoding = String(contentEncoding ?? '').trim().toLowerCase();
  const gzip = bytes.length >= 2 && bytes[0] === 0x1f && bytes[1] === 0x8b;
  const zlib = hasZlibSignature(bytes);
  if (encoding === 'gzip' && gzip) {
    return Object.freeze({ bytes: gunzipSync(bytes), status: 'NEEDS_DECOMPRESSION' });
  }
  if (encoding === 'deflate' && zlib) {
    return Object.freeze({ bytes: inflateSync(bytes), status: 'NEEDS_DECOMPRESSION' });
  }
  if (encoding === 'br') {
    try { return Object.freeze({ bytes: brotliDecompressSync(bytes), status: 'NEEDS_DECOMPRESSION' }); }
    catch { return Object.freeze({ bytes, status: 'AUTO_DECOMPRESSED' }); }
  }
  if ((encoding === 'gzip' || encoding === 'deflate') && !gzip && !zlib) {
    return Object.freeze({ bytes, status: 'AUTO_DECOMPRESSED' });
  }
  return Object.freeze({ bytes, status: 'UNKNOWN' });
}

export function analyzeHttpResponseFraming({ bytes, headers = {}, httpStatus = null }) {
  if (!Buffer.isBuffer(bytes)) throw new TypeError('Response framing requires raw response bytes');
  const contentType = headerValue(headers, 'content-type');
  const charset = /charset\s*=\s*["']?([^;\s"']+)/i.exec(contentType ?? '')?.[1]?.toLowerCase() ?? null;
  const contentEncoding = headerValue(headers, 'content-encoding');
  const decoded = decodeHttpEntity(bytes, contentEncoding);
  const bomPresent = decoded.bytes.length >= 3 && decoded.bytes[0] === 0xef
    && decoded.bytes[1] === 0xbb && decoded.bytes[2] === 0xbf;
  const text = decodeCharset(decoded.bytes.subarray(bomPresent ? 3 : 0), charset);
  const trimmed = text.trimStart();
  const xmlDetected = trimmed.startsWith('<');
  const root = xmlDetected ? inspectXmlRoot(text) : inspectXmlRoot('');
  const htmlDetected = /^<!doctype\s+html\b/i.test(trimmed)
    || (root.detected && root.localName.toLowerCase() === 'html');
  const jsonDetected = /^[{[]/.test(trimmed);
  const gzipSignature = bytes.length >= 2 && bytes[0] === 0x1f && bytes[1] === 0x8b;
  const zlibSignature = hasZlibSignature(bytes);
  return Object.freeze({
    httpStatus,
    contentType,
    charset,
    contentEncoding,
    contentLength: headerValue(headers, 'content-length'),
    transferEncoding: headerValue(headers, 'transfer-encoding'),
    connection: headerValue(headers, 'connection'),
    responseByteLength: bytes.length,
    firstBytesHex: bytes.subarray(0, 16).toString('hex'),
    bomPresent,
    gzipSignature,
    compressedSignature: gzipSignature || zlibSignature,
    responseStartsWithLt: trimmed.startsWith('<'),
    xmlDeclarationPresent: /^<\?xml\b/i.test(trimmed),
    xmlDetected,
    rootLocalName: root.localName,
    rootNamespaceUri: root.namespaceUri,
    rootPrefix: root.prefix,
    soap11EnvelopeDetected: root.localName === 'Envelope' && root.namespaceUri === SOAP11_NAMESPACE,
    htmlDetected,
    jsonDetected,
    binaryOrCompressed: gzipSignature || zlibSignature || (!xmlDetected && !jsonDetected && /[^\x09\x0a\x0d\x20-\x7e]/.test(text.slice(0, 128))),
    autoDecompressionStatus: decoded.status,
    decodedText: text,
  });
}

export function sanitizedFramingMetadata(analysis) {
  const { decodedText: _discard, ...safe } = analysis;
  return Object.freeze(safe);
}
