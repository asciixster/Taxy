function decodeXml(value = '') {
  return value.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'").replaceAll('&amp;', '&').trim();
}

function element(xml, localName) {
  const escaped = localName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = xml.match(new RegExp(`<(?:[\\w.-]+:)?${escaped}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${escaped}\\s*>`, 'i'));
  return match ? decodeXml(match[1].replace(/<[^>]+>/g, '')) : null;
}

export function parseSoapResponse(xml, httpStatus) {
  const isXml = typeof xml === 'string' && /^\s*(?:<\?xml[^>]*>\s*)?</.test(xml);
  const faultCode = isXml ? (element(xml, 'faultcode') || element(xml, 'Code')) : null;
  const faultString = isXml ? (element(xml, 'faultstring') || element(xml, 'Reason')) : null;
  const requestId = isXml ? (element(xml, 'RequestId') || element(xml, 'CorrelationId')) : null;
  return Object.freeze({
    httpStatus,
    isXml,
    fault: faultCode || faultString ? Object.freeze({ code: faultCode, message: faultString }) : null,
    requestId,
    rawXml: xml,
  });
}
