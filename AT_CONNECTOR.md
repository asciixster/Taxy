# Taxy 0.7.1 — Authenticated e-Fatura Consultation

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

The 0.7.1 protocol investigation reached the documented-blocker outcome: the official manual confirms the operation name and request fields, but not RSA padding, the consultation namespace, binding/WSDL or SOAPAction. No authenticated request was sent and no cryptographic/contract combination was guessed. See `AT_PROTOCOL_EVIDENCE.md`.

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
- `parser.mjs`: structured SOAP response/fault parsing.
- `redaction.mjs`: recursive log redaction.
- `client.mjs`: orchestration through `AtSoapClient`.
- `dto.mjs`: neutral DTO foundation (`AtInvoice`, `AtParty`, `AtAmount`, `AtTax`).

No temporary private-key file is created. Node.js receives the PFX bytes in memory and clears the application buffer after the request is started. OpenSSL remains responsible for its internal secure context.

## Requirements and local setup

- Node.js 22 or newer (no third-party npm dependency).
- The AT test PKCS#12 file and its password.
- The current AT cipher public certificate for authenticated calls.
- A Portal das Finanças subuser with WFA authorization for a future real consultation.

Set the variables from `.env.example` in the local shell. The tool intentionally does not load `.env` automatically, avoiding another dependency and accidental secret discovery.

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

## Authenticated dry-run

```powershell
node tools/at_connector/bin/test-authenticated-consultation.mjs --dry-run
```

The command validates local configuration and the evidence registry. At present it returns `RSA_PADDING_UNCONFIRMED`, prints only redacted metadata and performs zero network requests. There is no live authenticated mode until the critical evidence is officially confirmed and reviewed.

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

The document does **not** identify the RSA padding/hash. The public source example referenced by the manual requires an authenticated portal session and was unavailable to this implementation. Therefore authenticated requests fail closed. The library exposes explicit `pkcs1v15`, `oaepSha1` and `oaepSha256` modes for isolated testing, but none is a default and none is selected for AT. The final mode must only be enabled after written AT confirmation or inspection of the official source example.

## Limitations

- Test environment only; production execution is blocked.
- No authenticated invoice consultation yet.
- No consultation WSDL was published in the cited generic manual.
- The official v3.0 example uses undeclared `soapenv` and `fat` prefixes, so it does not resolve the namespace/binding gap.
- No IRS, Modelo 3 or assessment service is inferred from e-Fatura.
- No automatic persistence of responses. Only a generic, sanitized SOAP fault fixture is committed.
- No integration with Flutter or `TaxEngine`.
