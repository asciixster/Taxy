# FactIntWS population mismatch audit

## Confirmed constraints

- `BASE_NIF` matches the intended taxpayer (`RUNTIME_CONFIGURATION_CONFIRMED`,
  value intentionally omitted).
- Year 2026 matches the official-app observation.
- FactIntWS transport, WS-Security authentication, operation dispatch and
  successful business responses are operational.
- The official app for the intended taxpayer/year visibly reports five pending
  invoices, a non-zero provisional benefit and non-zero sectors.
- Taxy's controlled responses report zero overview aggregates and an empty
  pending list.
- `GENUINE_OPERATION_EMPTY`, `BASE_NIF_MISMATCH` and a simple year mismatch do
  not explain the intended comparison.

The password was neither read for output nor compared during this audit.
Evidence is limited to `CREDENTIAL_AUTH_PATH_OPERATIONALLY_WORKING`.

## Login form

Official and Taxy code implement the same transformation:

```text
SOAP_USERNAME = complete LOGIN_IDENTITY
request body  = BASE_NIF(LOGIN_IDENTITY)
```

Both support the historical primary/subuser syntax in their reference flows.
The supplied evidence establishes base-NIF equality but does not expose or
provide a safe equality proof for the complete official-app login. Therefore:

```text
LOGIN_FORM_MATCH = UNKNOWN
```

No credential value is needed or stored in this document.

## Updated hypotheses

| Hypothesis | Confidence/status | Evidence |
|---|---|---|
| `UNKNOWN_SERVER_POPULATION_RULE` / client application identity context | **HIGH-MEDIUM** | Official mobile and Taxy client-certificate identities differ; endpoint acceptance does not prove equal population policy |
| `BOOTSTRAP_CALL_MISSING` | **MEDIUM** | Official displayed homepage follows `EcraInicial -> DadosContribuinte -> EcraInicial`; Taxy tested a direct operation. No token/cookie proves a remote dependency |
| `LOGIN_FORM_MISMATCH` | **MEDIUM-UNKNOWN** | Base NIF is equal, but complete official login equality was not safely established |
| `SESSION_CONTEXT_MISMATCH` | **LOW-MEDIUM** | Call sequence differs, but no explicit session token is carried |
| `COOKIE_STATE_MISMATCH` | **LOW** | Official code replaces its CookieManager before each operation; no Set-Cookie evidence exists |
| `SELECTED_TAXPAYER_SERVER_CONTEXT_MISSING` | **LOW** | Selection is local credential state and is serialized on every request; no activation operation found |
| `HTTP_HEADER_CONTEXT_MISMATCH` | **LOW** | Material headers match; only timeout/platform defaults differ |
| `ECRAINICIAL_PARSER_DATA_LOSS` | **FIXED; LOW for prior Node live** | Six unsafe bridge defaults existed, but earlier runtime evidence records all three fields present |
| `CANALORIGEM_CONTEXT_MISMATCH` | **LOW** | Same constant/formula is used throughout official calls and current value was accepted |
| `YEAR_MISMATCH` | **LOW** | Same explicit year in both observations |
| `BASE_NIF_MISMATCH` | **REJECTED** | Safe local equality confirmation |
| `PASSWORD_MISMATCH` | **LOW** | Authentication path is operational; no plaintext comparison performed |

## Independent sector issue

The official homepage's explicit empty `CodSetor` remains an evidence-backed
difference for the aggregate `FaturasPorSetor` call. It cannot explain the
zero `EcraInicial`, which has no sector field, and must remain a separate future
experiment.

## Recommended next experiment

The next authorized experiment should reproduce the official login/home call
sequence exactly, with zero parameter variation:

```text
EcraInicial(authentication year)
  -> DadosContribuinte
  -> EcraInicial(2026)
```

Inspect only the final overview aggregates. Use the same configured identity,
endpoint, TLS client identity, crypto, channel and body derivation. This tests
`BOOTSTRAP_CALL_MISSING` without mixing it with header, year, taxpayer or sector
changes. If the final overview remains zero, the sequence hypothesis is
falsified and investigation should move to the client-application identity /
server-population policy boundary; the official private identity must not be
used.

## Controlled bootstrap execution — 2026-08-30

The approved sequence was prepared with the authentication `EcraInicial` year
derived from verified NTP time (current civil year), followed by
`DadosContribuinte` and a final `EcraInicial(2026)`. All protocol, credential,
TLS, channel and HTTP parameters remained frozen.

The first FactIntWS request received a response but failed closed before an
operation result could be established: the response was not recognized as a
SOAP Envelope (`PARSING_ERROR`, field `Envelope`). Per the experiment rules,
the sequence stopped immediately. `DadosContribuinte` and the final overview
were not requested; there was no retry.

Consequently, this execution is `BOOTSTRAP_SEQUENCE_INCOMPLETE`. It neither
confirms nor rejects `BOOTSTRAP_CALL_MISSING`, and it provides no population
comparison. No raw response or personal data was persisted.

### Framing-only follow-up — 2026-08-30

One separately authorized `EcraInicial` request reproduced the same request
configuration and captured transport metadata before parsing. The server
returned HTTP 500 with `Content-Type: text/xml`, `Content-Encoding: gzip`,
chunked transfer and a 23-byte compressed entity. The entity had the gzip
signature and required exactly one in-memory decompression by the Node HTTPS
client path; the decoded shape was neither XML, HTML nor JSON and contained no
detectable SOAP 1.1 Envelope.

This explains the earlier `Envelope` parsing failure without implicating SOAP
prefix handling. The response is classified `COMPRESSED_BYTES`; no raw entity
was logged or persisted. The bootstrap sequence was not retried.

## Controlled direct population probes — 2026-08-30

After transport recovery, a bounded diagnostic made two read-only requests,
with no retry and with endpoint, TLS identity, authentication, crypto, NTP and
channel configuration frozen:

1. `FaturasPorSetor` with the official homepage shape `CodSetor=""`,
   `Indice=0`, `Ano=2026` returned HTTP 200, valid SOAP,
   `EstadoOperacao=204`, and zero invoice items.
2. `FaturasPorClassificar` was called through an explicit diagnostic override
   despite the zero overview count. It also returned HTTP 200, valid SOAP,
   `EstadoOperacao=204`, and zero invoice items.

No real response body or identifying invoice field was retained. These results
reject an overview-only summary defect and the formerly unsupported empty
sector encoding as explanations. The divergence affects all three read paths.

The Taxy runtime credential has primary-login shape rather than subuser shape.
The complete credential active in the official-app visual observation is not
available in local evidence, so complete-login equality remains `UNKNOWN` even
though the base taxpayer identifier is already confirmed equal.

The strongest remaining explanation is
`CLIENT_APPLICATION_IDENTITY_CONTEXT_MISMATCH` /
`UNKNOWN_SERVER_POPULATION_RULE`: the legitimate Taxy client identity is
accepted for mTLS and SOAP operations but may not receive the same population
as the officially provisioned mobile application. This is not proven server
semantics. Testing it would require authoritative AT evidence or the official
application's private identity, whose use is prohibited.

The other unresolved input is the exact complete credential selected in the
official app. Reproducing another identity requires that credential to be
legitimately supplied; it cannot be derived from the base NIF or APK code. This
is an external evidence/authorization boundary rather than a remaining
serializer or transport experiment.
