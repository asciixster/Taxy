import dgram from 'node:dgram';

const NTP_PACKET_BYTES = 48;
const NTP_UNIX_EPOCH_SECONDS = 2_208_988_800;
const UINT32_SCALE = 0x1_0000_0000;

export class NtpError extends Error {
  constructor(code, message, options = {}) {
    super(message, options);
    this.name = 'NtpError';
    this.code = code;
  }
}

function readTimestamp(packet, offset) {
  return Object.freeze({
    seconds: packet.readUInt32BE(offset),
    fraction: packet.readUInt32BE(offset + 4),
  });
}

function timestampIsZero(timestamp) {
  return timestamp.seconds === 0 && timestamp.fraction === 0;
}

export function ntpTimestampToDate(seconds, fraction) {
  if (!Number.isInteger(seconds) || seconds < NTP_UNIX_EPOCH_SECONDS || seconds > 0xffff_ffff) {
    throw new NtpError('NTP_TIMESTAMP_INVALID', 'NTP timestamp is outside the supported 1970-2036 era');
  }
  if (!Number.isInteger(fraction) || fraction < 0 || fraction > 0xffff_ffff) {
    throw new NtpError('NTP_TIMESTAMP_INVALID', 'NTP timestamp fraction is invalid');
  }
  const unixMilliseconds = ((seconds - NTP_UNIX_EPOCH_SECONDS) * 1000) +
    Math.floor((fraction * 1000) / UINT32_SCALE);
  const value = new Date(unixMilliseconds);
  if (Number.isNaN(value.getTime())) throw new NtpError('NTP_TIMESTAMP_INVALID', 'NTP timestamp is not representable');
  return value;
}

export function createNtpRequest({ now = () => new Date() } = {}) {
  const request = Buffer.alloc(NTP_PACKET_BYTES);
  request[0] = (4 << 3) | 3; // leap=0, version=4, client mode=3
  const value = now();
  if (!(value instanceof Date) || Number.isNaN(value.getTime())) {
    throw new NtpError('NTP_REQUEST_TIME_INVALID', 'NTP request clock returned an invalid Date');
  }
  const unixMilliseconds = value.getTime();
  const unixSeconds = Math.floor(unixMilliseconds / 1000);
  const millisecondRemainder = unixMilliseconds - (unixSeconds * 1000);
  request.writeUInt32BE(unixSeconds + NTP_UNIX_EPOCH_SECONDS, 40);
  request.writeUInt32BE(Math.floor((millisecondRemainder * UINT32_SCALE) / 1000), 44);
  return request;
}

export function parseNtpResponse(packet, request) {
  if (!Buffer.isBuffer(packet) || packet.length < NTP_PACKET_BYTES || packet.length % 4 !== 0) {
    throw new NtpError('NTP_RESPONSE_MALFORMED', 'NTP response must contain at least 48 bytes and be word-aligned');
  }
  if (!Buffer.isBuffer(request) || request.length !== NTP_PACKET_BYTES) {
    throw new NtpError('NTP_REQUEST_INVALID', 'NTP request must contain exactly 48 bytes');
  }
  const leap = packet[0] >>> 6;
  const version = (packet[0] >>> 3) & 0x07;
  const mode = packet[0] & 0x07;
  const stratum = packet[1];
  if (leap === 3) throw new NtpError('NTP_SERVER_UNSYNCHRONIZED', 'NTP server reports an unsynchronized clock');
  if (version !== 3 && version !== 4) throw new NtpError('NTP_RESPONSE_MALFORMED', 'Unsupported NTP response version');
  if (mode !== 4) throw new NtpError('NTP_RESPONSE_MALFORMED', 'NTP response is not in server mode');
  if (stratum === 0) throw new NtpError('NTP_SERVER_KISS_OF_DEATH', 'NTP server refused the request');
  if (stratum > 15) throw new NtpError('NTP_RESPONSE_MALFORMED', 'NTP response stratum is invalid');
  if (!packet.subarray(24, 32).equals(request.subarray(40, 48))) {
    throw new NtpError('NTP_RESPONSE_MISMATCH', 'NTP response does not match the request');
  }
  const receive = readTimestamp(packet, 32);
  const transmit = readTimestamp(packet, 40);
  if (timestampIsZero(receive) || timestampIsZero(transmit)) {
    throw new NtpError('NTP_RESPONSE_MALFORMED', 'NTP response is missing server timestamps');
  }
  return ntpTimestampToDate(transmit.seconds, transmit.fraction);
}

export function exchangeNtpUdp({ host, port, timeoutMs, request }) {
  return new Promise((resolve, reject) => {
    const socket = dgram.createSocket('udp4');
    let settled = false;
    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      socket.close();
      callback(value);
    };
    const timer = setTimeout(() => finish(reject,
      new NtpError('NTP_TIMEOUT', `NTP request timed out after ${timeoutMs} ms`)), timeoutMs);
    socket.once('error', (cause) => finish(reject,
      new NtpError('NTP_NETWORK_ERROR', 'NTP UDP exchange failed', { cause })));
    socket.once('message', (message) => finish(resolve, message));
    socket.connect(port, host, () => socket.send(request, (error) => {
      if (error) finish(reject, new NtpError('NTP_NETWORK_ERROR', 'NTP UDP send failed', { cause: error }));
    }));
  });
}

export async function queryNtpTime({ host, port = 123, timeoutMs = 3000,
  exchange = exchangeNtpUdp, now } = {}) {
  if (typeof host !== 'string' || host.trim() === '' || /[,;\s]/.test(host)) {
    throw new NtpError('NTP_CONFIGURATION_INVALID', 'Exactly one NTP server hostname must be configured');
  }
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new NtpError('NTP_CONFIGURATION_INVALID', 'NTP port is invalid');
  }
  if (!Number.isInteger(timeoutMs) || timeoutMs < 100 || timeoutMs > 5000) {
    throw new NtpError('NTP_CONFIGURATION_INVALID', 'NTP timeout must be between 100 and 5000 ms');
  }
  const request = createNtpRequest({ now });
  const response = await exchange({ host, port, timeoutMs, request });
  return parseNtpResponse(response, request);
}

export function ntpProviderFromEnvironment(env = process.env, options = {}) {
  const host = env.FACTINTWS_NTP_SERVER;
  const port = env.FACTINTWS_NTP_PORT == null ? 123 : Number(env.FACTINTWS_NTP_PORT);
  const timeoutMs = env.FACTINTWS_NTP_TIMEOUT_MS == null ? 3000 : Number(env.FACTINTWS_NTP_TIMEOUT_MS);
  // Captures one server configuration and performs exactly one UDP exchange per invocation.
  return async () => {
    if (!host) throw new NtpError('NTP_CONFIGURATION_INVALID', 'FACTINTWS_NTP_SERVER is required');
    return queryNtpTime({ host, port, timeoutMs, ...options });
  };
}
