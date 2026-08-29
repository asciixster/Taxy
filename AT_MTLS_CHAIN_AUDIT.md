# Taxy 0.7.3 — local mTLS chain audit

Date: 29 August 2026  
Network requests during this investigation: `0`

## New Taxy client PFX

| Check | Result |
|---|---|
| PKCS#12 opens | YES |
| Certificates inside | 1 |
| Client certificate | YES |
| Private key | YES |
| Public key match | YES |
| TLS Web Client Authentication EKU | YES |
| Key usage | `digitalSignature`, `keyEncipherment` |
| Client issuer summary | `AT Issuing CA2` |
| Intermediate certificates inside | NO |
| Effective chain length | 1 |
| Chain classification | `CHAIN_INTERMEDIATE_MISSING` |

The only separately supplied public certificate is the AT 2027 cipher certificate. It is not treated as a CA/intermediate. No matching `AT Issuing CA2` certificate was found in the current-user or local-machine Windows CA/root stores.

Conclusion: `INTERMEDIATE_CERTIFICATE_REQUIRED`. No rebuilt PFX was created because the legitimate intermediate certificate is not available locally.

## Comparison with the 0.7.2 successful execution

The historical local path points to a different PFX filename, but its passphrase is not available in the current process or `.env.local`. The certificate and chain therefore cannot be extracted or compared without guessing a passphrase, which is prohibited.

| Comparison | Result |
|---|---|
| Same client certificate | `UNKNOWN` |
| Same certificate chain | `UNKNOWN` |
| Same fatshare endpoint/configuration | YES |

## TLS error detail

The earlier failing request was recorded before sanitized cause details were retained. Its precise native TLS code/reason is therefore `NOT_CAPTURED`; no new request was made to recreate it. Future errors now retain only a stable code, sanitized reason and TLS stage.

No PFX, certificate, private key, passphrase, PEM, complete subject, serial, fingerprint, NIF or socket dump is included in this report.
