# AT Connector Security

## Security boundary

The connector is a local developer harness. Flutter, APK assets and the IRS engine contain no AT credential material. A future production connector must run in a controlled backend/service boundary, never on an end-user mobile device.

## Certificate storage

- Keep `.pfx`, `.p12`, `.key` and `.cer` files outside the repository.
- Pass absolute paths through environment variables.
- Never put certificates or credentials in `lib/`, `assets/`, test fixtures, issue text or pull-request descriptions.
- The current Node transport uses the PKCS#12 directly in memory. It does not export or write an unencrypted private key.
- Rotate a certificate by replacing the external file and environment reference. Do not rename/copy it into the repository.

The repository ignores these extensions plus `tools/at_connector/.env`, `local/` and `output/`. Ignore rules are defense in depth; review staged files before every commit.

## Secrets

`AT_PFX_PASSWORD`, `AT_PASSWORD`, encrypted Password, Nonce, PFX content, tokens and private keys are always sensitive. Logs are redacted by key and SOAP element. Portuguese nine-digit identifiers are masked. Do not enable HTTP body dumps.

The supplied test PFX is still credential material even if AT distributes a common test certificate. It is not committed. The public cipher certificate is also kept external because this task explicitly limits it to local use.

## Environment separation

- `test`: enabled; official ports 7xx.
- `production`: endpoint metadata exists, but execution is rejected by configuration.

Never bypass the production guard for local experimentation. Production requires separate threat modelling, secret storage, network controls, audit retention, certificate rotation and operational approval.

## Cryptography

- AES keys are generated with the operating system CSPRNG and must never be reused.
- AES-128-ECB PKCS padding is limited to the AT authentication protocol fields specified by AT; it is not a general encryption recommendation.
- The current official manual does not state RSA padding. Authenticated construction is therefore fail-closed until the missing parameter is confirmed from an official source.
- Plaintext credentials and complete encrypted credential fields must not appear in logs.

## Incident response

If credential material is staged, logged or shared:

1. stop and do not push;
2. remove it from the index/history without copying it elsewhere;
3. rotate affected Portal credentials and client certificate where applicable;
4. document the incident outside the public repository;
5. verify Git history and CI artifacts before resuming.

## Threat model

| Threat | Control in 0.7.2 |
|---|---|
| APK extraction | Connector and secrets remain outside Flutter/assets; no AT code path in the app. |
| Repository leak | Credential extensions and local directories ignored; staged-content secret scan required. |
| CI logs | CI has no certificates/credentials, runs offline tests only, and redaction is tested. |
| Environment exposure | Variables are read only at execution; no `.env` autoload or debug dump. Process administrators remain able to inspect environment variables. |
| Process memory | Plaintext exists only while building credentials; session-key buffers are cleared after use where controlled. Managed/OpenSSL copies may persist until collection/context disposal. |
| MITM | Normal hostname/CA validation, `rejectUnauthorized: true`, TLS 1.2 minimum and AT client certificate. |
| Certificate misuse | Production blocked, external paths only, no private-key export, documented rotation. |
| Credential replay | Fresh CSPRNG AES key per request; no automatic retry. Exact Created precision remains evidence-gated. |
| Excessive permissions | Primary and supported subuser usernames are syntactically accepted. Remote authorization is classified from the AT response; least-privilege credentials remain recommended. |

Live commands are single-shot: at most one request per execution, no loop and zero automatic retries.

The historical command additionally requires `AT_LIVE_TEST=1`, derives the customer NIF from either the primary username or a subuser's NIF-base, rejects mismatches, omits invoice details from output, and never persists a response. Local username validation does not claim or predict remote authorization.
