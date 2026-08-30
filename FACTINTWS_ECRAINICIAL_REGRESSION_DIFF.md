# FactIntWS EcraInicial regression diff

Offline audit only. `networkRequests=0`. All identities and credentials are
represented symbolically; no authenticated payload or response was read or
persisted.

## Compared paths

### Runtime-confirmed path

- reference commit: `a5d861d` (`test(connector): confirm FactIntWS endpoint 8443`);
- entrypoint: `tools/at_connector/bin/factintws-live-once.mjs`;
- HTTP client: Node `https.request`;
- request builder/serializer: `buildFactIntWsEnvelope` and
  `serializeFactIntWsOperation` in `src/factintws.mjs`;
- TLS: PFX/passphrase, native CA validation, `minVersion=TLSv1.2`, no maximum,
  no custom ciphers, no explicit agent;
- headers: `factIntWsHttpContract` plus byte-calculated `Content-Length`;
- write: one `request.end(xml)`;
- response: chunks to Buffer, manual gzip decompression when declared, UTF-8
  string, functional parser.

The current `factintws-live-once.mjs` blob hash is identical to the file at
`a5d861d`. The reference entrypoint itself has not regressed.

### Current failing paths

- bootstrap entrypoint added at `74dd2c8`:
  `tools/at_connector/bin/factintws-bootstrap-live.mjs`;
- framing-only entrypoint added at `7e3764c`:
  `tools/at_connector/bin/factintws-framing-live.mjs`;
- HTTP client: Node `https.request` in both;
- builder, serializer, TLS options, HTTP contract, Content-Length calculation
  and one-shot `request.end(xml)`: shared with the reference path;
- bootstrap response: chunks to Buffer, gzip decode, parser through
  `FactIntWsClient`;
- framing response: chunks preserved as raw Buffer, headers captured, exactly
  one in-memory decode according to `Content-Encoding`, shape inspection before
  any functional parser.

The diagnostic layer acts only after the response event and cannot change the
already-sent request.

## Commit window

Window: `a5d861d..7e3764c`.

| Change | Relevance |
|---|---|
| `4976cb7` adds typed client/repository and invoice live tooling | New wrapper path, but it reuses the same builder/contract and does not modify the confirmed entrypoint |
| `6342adb` adds app integration | No change to Node transport or Ecra serializer |
| `a0c24a3` makes required overview fields fail closed | Response-only; cannot cause HTTP 500 |
| `74dd2c8` adds the bootstrap sequence entrypoint | New orchestration path; first request still uses the same wire functions |
| `7e3764c` adds framing diagnostics and namespace validation | Response-only; the separate one-call diagnostic reproduced HTTP 500 |

No commit in the window changes the runtime-confirmed entrypoint, the Ecra
request case, the HTTP contract, TLS options, crypto construction, NTP or the
request write call.

## Sanitized SOAP and byte diff

Placeholders: `USER`, `NIF`, `PASSWORD`, `DIGEST`, `NONCE`, `CREATED`.
The committed synthetic reference is
`ecra_inicial_runtime_confirmed_envelope.xml`.

| Element | Result |
|---|---|
| XML declaration and UTF-8 encoding | MATCH |
| Envelope/namespace declarations | MATCH |
| Security, actor and auth version | MATCH |
| UsernameToken child order | MATCH |
| Password/Digest, Nonce and Created positions | MATCH |
| EcraInicial root and namespace | MATCH |
| Nif, Ano, CanalOrigem order | MATCH |
| Escaping, whitespace and self-closing behavior | MATCH |
| LF/CRLF, BOM, leading/trailing bytes | MATCH |

Canonical XML diff count: **0**. Byte-shape diff count: **0**. A regression
test proves exact UTF-8 equality to the frozen synthetic reference.

`Content-Length` is manually set to `Buffer.byteLength(xml)`, after final
serialization and before `request.end(xml)`. A non-ASCII test proves declared
length equals the actual UTF-8 Buffer length rather than JavaScript character
count. With Content-Length present, request Transfer-Encoding is not set. The
request is plain XML and has no Content-Encoding.

## Header comparison

| Header | Runtime-confirmed | Current | Result / impact |
|---|---|---|---|
| Content-Type | `text/xml;charset=utf-8` | same | MATCH |
| SOAPAction | exact unquoted Ecra URI | same | MATCH |
| User-Agent | `ksoap2-android/2.6.0+` | same | MATCH |
| Accept-Encoding | `gzip` | same | MATCH; gzip HTTP 500 does not establish causality |
| Content-Length | final UTF-8 byte count | same | MATCH |
| Request Transfer-Encoding | absent/fixed length | same | MATCH |
| Content-Encoding | absent | absent | MATCH; request is not compressed |
| Accept, Connection, Host | Node/platform defaults | same client/runtime defaults | MATCH |
| Expect, Cookie, Cache-Control, Pragma | absent | absent | MATCH |

## TLS and crypto comparison

Endpoint/port, SNI derived from URL, native CA validation,
`rejectUnauthorized`, TLS version bounds, ciphers, ALPN defaults, agent usage
and request-scoped TLS behavior match. Both paths use the validated
`TesteWebservices` client identity; `CLIENT_IDENTITY_MATCH=YES`.

AES size/mode/padding, SHA-1 input order, encrypted password, RSA PKCS#1 v1.5
Nonce, Base64, NTP-only Created shape and CanalOrigem are built by the same
unchanged functions and match.

## Configuration-source difference

The historical successful execution used a coherent runtime environment. In
the current desktop process the variables were absent initially, `.env.local`
provided authentication and AT cipher-certificate configuration, and the
validated PFX pair then required explicit runtime overrides because the local
file's PFX pairing did not pass preflight.

The client PFX identity is proven equal, but no historical fingerprint was
persisted for the separate **public AT cipher certificate** used to RSA-encrypt
the request AES key. Therefore its equality is `UNKNOWN`. This material is not
the TLS client identity: a different/wrong public cipher key can pass local RSA
inspection and mTLS while making the server unable to decrypt the UsernameToken
security material.

## Response handling

The response paths differ intentionally. The confirmed path decodes gzip and
parses. The diagnostic path preserves raw metadata, then decodes once and
inspects shape. Tests cover plain XML, gzip XML, gzip non-XML and invalid gzip.
There is no double-decompression path and diagnostics do not mutate request
bytes. The observed result remains `HTTP_500_NON_SOAP_ERROR`; the 23-byte entity
is not a protocol contract.

## Ranked suspects

1. **RUNTIME_CONFIGURATION_SOURCE_DRIFT / AT cipher public-key mismatch** —
   high-medium confidence. It is the only concrete pre-request difference not
   disproved by byte/transport comparisons. A wrong encryption public key can
   plausibly produce a pre-functional HTTP 500. A single-variable test is
   possible after offline fingerprint equality is established against the
   previously successful public certificate.
2. **HTTP_CLIENT_PATH_CHANGED** — low confidence. Entrypoints changed, but both
   use the same `https.request` options, body, headers and write call; the
   original successful entrypoint remains byte-identical.
3. **SERVER_EDGE_NON_SOAP_500** — low/unknown confidence. It fits the observed
   response but supplies no actionable client-side difference and must not be
   treated as business semantics.
4. **RESPONSE_DIAGNOSTIC_SIDE_EFFECT** — rejected for request generation; the
   diagnostic runs after the response begins and reproduced the same failure.
5. **CONTENT_LENGTH/BODY_SERIALIZATION regression** — rejected offline by exact
   reference and UTF-8 byte-count tests.

## Recommended single-variable plan

Do not call FactIntWS yet. First obtain a safe equality result between the
current public AT cipher certificate and the public certificate fingerprint
recorded or recoverable from the successful local runtime configuration,
without exposing either certificate. If they differ, the next authorized test
is one `EcraInicial` using the previously successful public AT cipher
certificate and changing nothing else. If equality cannot be established, the
live gate remains blocked rather than guessing another certificate.

## Public cipher-certificate identity audit — 2026-08-30

The current public cipher certificate was resolved from `AT_CIPHER_CERT_PATH`
in the unchanged local configuration file. It exists, is public-only, uses a
4096-bit RSA key with exponent 65537 and is currently inside its certificate
validity window. Its certificate, SPKI and modulus SHA-256 fingerprints were
calculated locally but are not copied into this document.

Both the configuration file and referenced public certificate predate the
successful `a5d861d` test. This is useful provenance, but it is not proof of the
effective process environment used by that invocation: the live harness does
not load `.env.local` itself, and the successful result did not persist a
configuration snapshot or public-key fingerprint. Git history and sanitized
result documents contain no such fingerprint.

Therefore:

- current certificate found: **YES**;
- runtime-confirmed certificate found with cryptographic provenance: **NO**;
- `AT_CIPHER_CERT_MATCH`: **UNKNOWN**;
- source comparison: **UNKNOWN**;
- concrete certificate drift: **NO**;
- network requests: **0**.

The key-mismatch hypothesis is not confirmed and cannot authorize a live
single-variable experiment. Tests now expose certificate/SPKI/modulus
fingerprints, RSA type/size/exponent, validity and public-only/client-EKU
separation, and support a fail-closed expected-fingerprint assertion. A future
successful live run must record the selected public certificate fingerprint in
sanitized evidence so this ambiguity cannot recur.

## Current-configuration controlled live result — 2026-08-30

Exactly one `EcraInicial(2026)` request was made. No bootstrap, retry, fallback
or other FactIntWS operation was executed. The reproducibility record was built
before the HTTPS request:

| Element | SHA-256 / value |
|---|---|
| AT cipher certificate | `43b40f7e82bf35fecce2a36778b7dd6eb4ff7bd41e88474108cb1731d3326383` |
| AT cipher SPKI | `b19983ae125123d3b82afb0845018c2fe4fc8f9556686142b1e371a031a54968` |
| AT cipher RSA size / validity | 4096 bits / valid |
| Client identity certificate | `8c274b8bbebdfd5f86bd55e132897a87a44357b6b892e0697c362e0ecab88807` |
| TLS configuration | `9bec9a86ba7b0b8e263098b90907744a5e65182e9a1992c85123e628aa9807f5` |
| Serializer implementation | `cd20f12df4b5e8c1333d45ade78cb61934e1cb6793a9f1ec3a87391da721a2fe` |
| Request contract | `168cc2362f3dd17b38e01662f7f0ab6b33f510b0c9737dc7412990867646016f` |
| Sanitized request | `bb22efdac55ee088496ed921e7d7870b502f28c73ad53e49157649280b7cbec1` |

The TLS handshake reached `secureConnect`, the peer was authorized, and the
negotiated profile was TLS 1.3 with `TLS_AES_128_GCM_SHA256`. The server then
returned HTTP 500, `Content-Type: text/xml`, `Content-Encoding: gzip`, chunked
transfer and 23 response bytes. After exactly one in-memory decompression, the
shape was `NON_XML`; there was no SOAP Envelope, fault or functional result.

Classification: `CURRENT_CONFIG_REPRODUCES_HTTP_500`. The current configuration
is now formally tied to this result. The response body was neither logged nor
persisted, and population semantics were not evaluated.

## Bounded autonomous recovery — 2026-08-30

Five read-only FactIntWS requests tested three concrete hypotheses, with no
automatic retry and with the sanitized reproducibility record created before
every request:

1. the preserved official-app production public encryption key (public-only,
   2048-bit and expired) replaced the current 4096-bit AT encryption key;
   `EcraInicial` still returned the same 23-byte HTTP 500 non-XML response;
2. with the current AT encryption key, `DadosContribuinte` returned HTTP 200,
   a valid SOAP Envelope and business status 415. This proves that the current
   TLS, security material, public-key encryption and HTTP response path can
   reach the FactIntWS application;
3. the official functional order was executed using one keep-alive HTTPS
   agent: `EcraInicial(2026)`, `DadosContribuinte`, `EcraInicial(2026)`. Both
   overview calls returned HTTP 200, valid parseable SOAP and business status
   200. The middle call returned the same functional SOAP/status 415.

The very first request in the sequence already recovered, before the taxpayer
call could create application state. Node 24's default global HTTPS agent also
has keep-alive enabled, so the result does not prove an agent or bootstrap fix.
The earlier identical HTTP 500 is best classified as a transient server/edge
failure; no deterministic client regression was found.

The recovered overviews both contained zero pending invoices, zero provisional
benefit and zero sectors with non-zero aggregates. Transport recovery is
confirmed, but the separately evidenced account-population mismatch remains.
No pending-invoice call was made because the runtime pending count was zero.
No raw response, identifier or credential was logged or persisted.
