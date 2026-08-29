# Taxy 0.7.3 — Real invoice parsing foundation

The AT connector is a developer-only Node.js CLI under `tools/at_connector`. It is deliberately separate from Flutter and from the deterministic IRS engine. It does not place credentials in the mobile application and does not feed AT data into `TaxEngine`.

## Current proof

On 28 August 2026 the local test certificate was loaded directly from PKCS#12 into Node.js memory and used against the official e-Fatura consultation test endpoint. The server accepted the TLS connection and returned a real SOAP 1.1 fault for a deliberately empty body:

```text
TLS peer authorized: true
HTTP: 500
SOAP fault code: env:Client
SOAP fault string: Internal Error
```

This proves TLS, client-certificate presentation, HTTP and SOAP response handling. It does **not** prove Portal credentials, an invoice query, or acceptance of password encryption.

The 0.7.2 path reproduces supplied historical SOAP code without presenting it as official evidence. It uses the historical namespace, absent SOAPAction, RSA PKCS#1 v1.5, exact millisecond precision and fixed first-page pagination. Production remains blocked.

## Architecture

- `config.mjs`: environment validation; production execution is blocked.
- `endpoints.mjs`: centrally defined, documented endpoints.
- `crypto.mjs`: AT public certificate loading and AES-128-ECB/PKCS padding.
- `auth.mjs`: timestamp, session-key and UsernameToken components.
- `evidence.mjs`: executable official-evidence gate.
- `consultation.mjs`: documented request/response DTOs with namespace fail-closed serialization.
- `errors.mjs`: structured error taxonomy.
- `soap.mjs`: XML escaping and SOAP/WS-Security envelope serialization.
- `transport.mjs`: HTTPS transport with the PFX passed directly to Node.js.
- `pfx-preflight.mjs`: local, non-network PKCS#12 validation with stable fail-closed classifications.
- `parser.mjs`: structured SOAP response/fault parsing.
- `redaction.mjs`: recursive log redaction.
- `client.mjs`: orchestration through `AtSoapClient`.
- `dto.mjs`: neutral DTO foundation (`AtInvoice`, `AtParty`, `AtAmount`, `AtTax`).
- `historical.mjs`: isolated historical request builder and single-shot sandbox client.

The 0.7.3 parser adds typed `AtInvoice`, `AtInvoicePage` and `AtInvoiceQueryResult` outputs. Monetary values are exact integer cents, dates remain date-only, absent fields remain explicit, and fiscal identifiers are reduced to presence flags in safe output. See `INVOICE_FIELD_PRESENCE.md` for the runtime/offline evidence boundary.

No temporary private-key file is created. Node.js receives the PFX bytes in memory and clears the application buffer after the request is started. OpenSSL remains responsible for its internal secure context.

## Requirements and local setup

- Node.js 22 or newer (no third-party npm dependency).
- The AT test PKCS#12 file and its password.
- The current AT cipher public certificate for authenticated calls.
- Portal das Finanças primary NIF credentials or, where applicable, supported AT subuser credentials.

Process environment variables remain authoritative. When a required value is absent, the local harness loads the repository-root `.env.local` without overwriting the process environment. That file is Git-ignored and is never modified by the harness.

```powershell
$env:AT_ENV='test'
$env:AT_CLIENT_PFX_PATH='C:\absolute\path\TesteWebservices.pfx'
$env:AT_CLIENT_PFX_PASSWORD='<local password>'
$env:AT_CIPHER_CERT_PATH='C:\absolute\path\Chave Cifra Publica AT.cer'
node tools/at_connector/src/cli.mjs probe
```

The `probe` command sends a valid SOAP envelope with an empty body to the read-only consultation service. It cannot create, alter or delete invoices. Run local integration tests explicitly:

```powershell
$env:AT_LOCAL_INTEGRATION='1'
node --test tools/at_connector/test/integration/*.test.mjs
```

CI runs only offline unit tests. It has no AT certificate or Portal credentials and makes no AT call.

## Historical authenticated dry-run

```powershell
node tools/at_connector/bin/historical-soap-fetch.js --dry-run
```

Set `AT_START_DATE` and `AT_END_DATE` explicitly. The command validates complete local configuration, builds the encrypted request in memory, prints only a sanitized template and performs zero network requests.

The opt-in live command is `AT_LIVE_TEST=1 node tools/at_connector/bin/historical-soap-fetch.js`. It makes at most one test request, has no retry, uses 15/60-second connection/total limits, and prints only TLS/HTTP/status/count metadata plus anonymous parsed field presence. Authentication supports a taxpayer's primary NIF credentials and, where applicable, supported AT subuser credentials. `CustomerTaxID` is the primary NIF or the NIF-base of a subuser.

Before creating a socket, the harness checks the configured PKCS#12 exactly once with `AT_CLIENT_PFX_PATH` and `AT_CLIENT_PFX_PASSWORD` (legacy aliases remain accepted). Missing/invalid passphrases, missing certificate/key material and parse failures receive distinct classifications. The preflight never tries an empty or alternative password and never exposes certificate metadata.

## Official endpoints

| Service | Test | Production (configuration only) | WSDL | SOAPAction / namespace |
|---|---|---|---|---|
| Submit/change/delete invoice | `https://servicos.portaldasfinancas.gov.pt:723/fatcorews/ws` | port `423` | Official `Fatcorews.wsdl` | WSDL declares SOAP 1.1, empty SOAPAction and `http://factemi.at.min_financas.pt/documents` |
| Consult invoices | `https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas` | port `425` | `NEEDS_VERIFICATION`: not published in the generic manual | `NEEDS_VERIFICATION` pending WSDL |

Sources:

- [AT e-Fatura integration manual — generic aspects](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao_aspetos_gerais.pdf)
- [AT e-Fatura integration manual — specific aspects, v3.0](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao.pdf)
- [Official Fatcorews WSDL](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Fatcorews.wsdl)

The WSDL's embedded `soap:address` is not used; the manuals are authoritative for environment endpoints.

## Authentication encryption status

The official generic manual specifies a fresh random 128-bit AES session key for every request, UTF-8 strings, AES ECB with PKCS5Padding for Password and Created, Base64 for Password/Created/Nonce, and RSA encryption of the AES key with the AT public certificate.

The official document does **not** identify RSA padding. The historical path selects PKCS#1 v1.5 only because that choice exists in the supplied historical code. The general library still has no implicit RSA default and the official-only path remains fail-closed.

## Limitations

- Test environment only; production execution is blocked.
- Authenticated runtime behavior is not confirmed unless a controlled sandbox request succeeds.
- No consultation WSDL was published in the cited generic manual.
- The official v3.0 example uses undeclared `soapenv` and `fat` prefixes, so it does not resolve the namespace/binding gap.
- No IRS, Modelo 3 or assessment service is inferred from e-Fatura.
- No automatic persistence of responses. Committed XML fixtures are explicitly sanitized and synthetic; none is represented as a captured AT invoice response.
- No automatic pagination; the live harness requests only page 1.
- No real invoice response was captured in 0.7.3. The latest preflight opened the bundle and confirmed its certificate and private key, but the single authorized request failed during mTLS before HTTP/SOAP. Synthetic fixtures validate parser behavior but are not runtime evidence.
- No integration with Flutter or `TaxEngine`.
