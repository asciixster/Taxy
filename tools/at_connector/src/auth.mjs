import { buildEncryptedCredentials, generateAes128SessionKey } from './crypto.mjs';
import { securityHeader } from './soap.mjs';

export class AtTimestampBuilder {
  static fromIso8601Utc(value) {
    if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/.test(value) || Number.isNaN(Date.parse(value))) {
      throw new Error('Created must be a valid UTC ISO 8601 timestamp');
    }
    return value;
  }

  static now(clock = () => new Date()) {
    return AtTimestampBuilder.fromIso8601Utc(clock().toISOString());
  }

  static historical(clock = () => new Date()) {
    const date = clock();
    if (!(date instanceof Date) || Number.isNaN(date.getTime())) throw new Error('Historical Created clock must return a valid Date');
    return `${date.toISOString().slice(0, 19)}.000Z`;
  }
}

export class AtPasswordCipher {
  static encrypt({ plaintext, sessionKey, publicKey, created, rsaPaddingMode }) {
    return buildEncryptedCredentials({ password: plaintext, sessionKey, publicKey, created, rsaPaddingMode }).password;
  }
}

export class AtNonceCipher {
  static createSessionKey(randomSource) { return generateAes128SessionKey(randomSource); }
}

export class AtUsernameTokenBuilder {
  static build({ username, password, publicKey, rsaPaddingMode, created = AtTimestampBuilder.now(), randomSource }) {
    if (!/^\d{9}\/\d{1,4}$/.test(username)) throw new Error('Username must use the documented NIF/UserId format');
    const sessionKey = generateAes128SessionKey(randomSource);
    try {
      const encrypted = buildEncryptedCredentials({ password, created, publicKey, sessionKey, rsaPaddingMode });
      return securityHeader(username, encrypted);
    } finally {
      sessionKey.fill(0);
    }
  }
}
