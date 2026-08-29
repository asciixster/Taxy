import { AtConnectorError, AtErrorCode } from './errors.mjs';

export const FactIntWsCreatedSource = Object.freeze({
  NTP: 'NTP',
  SYSTEM_CLOCK_FALLBACK: 'SYSTEM_CLOCK_FALLBACK',
});

const exactCreatedPattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;

export function validateFactIntWsCreated(created) {
  if (!exactCreatedPattern.test(created) || Number.isNaN(Date.parse(created))) {
    throw new TypeError("FactIntWS Created must use yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  }
  return created;
}

export async function resolveFactIntWsCreated({ ntpTimeProvider, allowSystemClockFallback = false,
  systemClock = () => new Date() } = {}) {
  if (typeof ntpTimeProvider === 'function') {
    try {
      const value = await ntpTimeProvider();
      const created = value instanceof Date ? value.toISOString() : String(value);
      return Object.freeze({ created: validateFactIntWsCreated(created), source: FactIntWsCreatedSource.NTP });
    } catch (cause) {
      if (!allowSystemClockFallback) {
        throw new AtConnectorError(AtErrorCode.NTP_TIME_UNAVAILABLE, 'NTP time is unavailable', { cause });
      }
    }
  } else if (!allowSystemClockFallback) {
    throw new AtConnectorError(AtErrorCode.NTP_TIME_UNAVAILABLE, 'No verified NTP provider is configured');
  }

  const created = systemClock().toISOString();
  return Object.freeze({ created: validateFactIntWsCreated(created), source: FactIntWsCreatedSource.SYSTEM_CLOCK_FALLBACK });
}
