const SENSITIVE_KEY = /^(?:username|password|passphrase|private.?key|pfx(?:content|password)?|nonce|token|authorization|nif|(?:issuer|customer|tax).*(?:id|identifier)|invoice.*id|document.*reference|atcud)$/i;
const AT_USERNAME = /(?<!\d)\d{9}\/\d{1,4}(?!\d)/g;
const LONG_NUMERIC_IDENTIFIER = /(?<!\d)\d{9,}(?!\d)/g;
const DOCUMENT_LIKE_IDENTIFIER = /\b[A-Z]{1,5}[-/]\d{4,}\b/gi;

export function redactText(value) {
  if (value == null) return value;
  return String(value)
    .replace(AT_USERNAME, '[REDACTED_USERNAME]')
    .replace(LONG_NUMERIC_IDENTIFIER, '[REDACTED_IDENTIFIER]')
    .replace(DOCUMENT_LIKE_IDENTIFIER, '[REDACTED_DOCUMENT_ID]')
    .replace(/(<(?:\w+:)?(?:Password|Nonce)>)[\s\S]*?(<\/(?:\w+:)?(?:Password|Nonce)>)/gi, '$1[REDACTED]$2');
}

export function redact(value, key = '') {
  if (SENSITIVE_KEY.test(key)) return '[REDACTED]';
  if (typeof value === 'string') return redactText(value);
  if (Array.isArray(value)) return value.map((item) => redact(item));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, redact(v, k)]));
  }
  return value;
}

export function safeLog(logger, event, details = {}) {
  logger(JSON.stringify({ event, ...redact(details) }));
}
