const SENSITIVE_KEY = /^(?:password|passphrase|private.?key|pfx(?:content|password)?|nonce|token|authorization)$/i;
const PORTUGUESE_NIF = /(?<!\d)\d{9}(?!\d)/g;

export function redactText(value) {
  if (value == null) return value;
  return String(value)
    .replace(PORTUGUESE_NIF, '[REDACTED_NIF]')
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
