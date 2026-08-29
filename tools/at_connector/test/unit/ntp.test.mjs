import assert from 'node:assert/strict';
import test from 'node:test';
import { FactIntWsCreatedSource, resolveFactIntWsCreated } from '../../src/factintws_time.mjs';
import {
  createNtpRequest, ntpProviderFromEnvironment, ntpTimestampToDate,
  parseNtpResponse, queryNtpTime,
} from '../../src/ntp.mjs';

const fixedNow = () => new Date('2026-08-29T12:34:50.000Z');

function validResponse(request, { seconds = 3_996_995_696, fraction = 0xc9fb_e76d } = {}) {
  const response = Buffer.alloc(48);
  response[0] = (4 << 3) | 4;
  response[1] = 2;
  request.copy(response, 24, 40, 48);
  response.writeUInt32BE(seconds - 1, 32);
  response.writeUInt32BE(fraction, 36);
  response.writeUInt32BE(seconds, 40);
  response.writeUInt32BE(fraction, 44);
  return response;
}

test('valid correlated NTP response returns its UTC transmit timestamp', async () => {
  let exchanges = 0;
  const value = await queryNtpTime({ host: 'ntp.synthetic.test', timeoutMs: 500, now: fixedNow,
    exchange: async ({ request }) => { exchanges += 1; return validResponse(request); } });
  assert.equal(exchanges, 1);
  assert.equal(value.toISOString(), '2026-08-29T12:34:56.789Z');
});

test('timeout is propagated after one exchange and is never retried', async () => {
  let exchanges = 0;
  await assert.rejects(queryNtpTime({ host: 'ntp.synthetic.test', now: fixedNow,
    exchange: async () => { exchanges += 1; throw Object.assign(new Error('synthetic timeout'), { code: 'NTP_TIMEOUT' }); } }),
  (error) => error.code === 'NTP_TIMEOUT');
  assert.equal(exchanges, 1);
});

test('malformed, uncorrelated and unsynchronized responses fail closed', () => {
  const request = createNtpRequest({ now: fixedNow });
  assert.throws(() => parseNtpResponse(Buffer.alloc(47), request), /48 bytes/);
  const mismatched = validResponse(request);
  mismatched[24] ^= 0xff;
  assert.throws(() => parseNtpResponse(mismatched, request), (error) => error.code === 'NTP_RESPONSE_MISMATCH');
  const unsynchronized = validResponse(request);
  unsynchronized[0] |= 0xc0;
  assert.throws(() => parseNtpResponse(unsynchronized, request), (error) => error.code === 'NTP_SERVER_UNSYNCHRONIZED');
});

test('NTP fraction converts deterministically to UTC milliseconds', () => {
  assert.equal(ntpTimestampToDate(3_996_995_696, 0xc9fb_e76d).toISOString(), '2026-08-29T12:34:56.789Z');
  assert.equal(ntpTimestampToDate(2_208_988_800, 0).toISOString(), '1970-01-01T00:00:00.000Z');
});

test('NTP provider feeds exact Created formatting with source NTP', async () => {
  const provider = ntpProviderFromEnvironment({ FACTINTWS_NTP_SERVER: 'ntp.synthetic.test',
    FACTINTWS_NTP_TIMEOUT_MS: '500' }, { now: fixedNow,
    exchange: async ({ request }) => validResponse(request) });
  assert.deepEqual(await resolveFactIntWsCreated({ ntpTimeProvider: provider, allowSystemClockFallback: false }),
    { created: '2026-08-29T12:34:56.789Z', source: FactIntWsCreatedSource.NTP });
});

test('NTP failure cannot fall back to the system clock', async () => {
  let systemClockCalls = 0;
  await assert.rejects(resolveFactIntWsCreated({
    ntpTimeProvider: async () => { throw new Error('offline'); },
    allowSystemClockFallback: false,
    systemClock: () => { systemClockCalls += 1; return new Date(); },
  }), (error) => error.code === 'NTP_TIME_UNAVAILABLE');
  assert.equal(systemClockCalls, 0);
});

test('environment requires exactly one explicit NTP server', async () => {
  await assert.rejects(ntpProviderFromEnvironment({})(), /FACTINTWS_NTP_SERVER/);
  const provider = ntpProviderFromEnvironment({ FACTINTWS_NTP_SERVER: 'one.example,two.example' });
  await assert.rejects(provider(), /Exactly one/);
});
