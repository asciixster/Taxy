# AT Protocol Evidence — Taxy 0.7.2

Evidence is classified without promoting historical code to official documentation.

- `OFFICIAL_DOCUMENTATION`: stated in an AT publication.
- `HISTORICAL_CODE_EVIDENCE`: reproduced from supplied historical code; not official.
- `RUNTIME_BEHAVIOR_CONFIRMED`: observed in a controlled AT sandbox response.
- `UNKNOWN`: not established.

| Protocol element | Value used | Evidence |
|---|---|---|
| Test endpoint | port 725 `fatshareFaturas` | OFFICIAL_DOCUMENTATION |
| Production endpoint | port 425; execution blocked | OFFICIAL_DOCUMENTATION |
| TLS / client certificate | HTTPS with AT PFX | OFFICIAL_DOCUMENTATION |
| `TesteWebservices.pfx` client identity | Accepted by the port 725 test endpoint | RUNTIME_BEHAVIOR_CONFIRMED; identity-specific only |
| Separate AT Issuing CA2 identity | Local chain valid; endpoint acceptance not confirmed | UNKNOWN |
| SOAP | 1.1 | OFFICIAL_DOCUMENTATION |
| Subuser username | `NIF/UserId` | OFFICIAL_DOCUMENTATION |
| Primary username | 9-digit taxpayer NIF | HISTORICAL_CODE_EVIDENCE; remote authorization UNKNOWN |
| AES | random 128-bit key per request, ECB, PKCS padding | OFFICIAL_DOCUMENTATION |
| Request/response | `InvoicesRequest` / `InvoicesResponse` | OFFICIAL_DOCUMENTATION |
| InvoicesRequest namespace | `http://factemi.at.min_financas.pt/fatshareInvoices` | RUNTIME_BEHAVIOR_CONFIRMED |
| SOAPAction | header absent | HISTORICAL_CODE_EVIDENCE |
| RSA padding | RSAES-PKCS1-v1_5 | HISTORICAL_CODE_EVIDENCE |
| Password input encoding | UTF-8 | HISTORICAL_CODE_EVIDENCE |
| Created precision | `YYYY-MM-DDTHH:mm:ss.000Z` | HISTORICAL_CODE_EVIDENCE |
| Nonce | Base64(RSA-PKCS1-v1_5(AES key)) | HISTORICAL_CODE_EVIDENCE |
| Pagination | page 1, 500 documents | HISTORICAL_CODE_EVIDENCE |
| Consultation WSDL | not published/found | UNKNOWN |
| WFA permission for this exact operation | not explicitly stated | UNKNOWN |
| Primary-user authorization for this operation | not runtime-tested | UNKNOWN |

The historical path has its own explicit evidence gate. It does not alter the stricter official-only gate retained from 0.7.1. A successful sandbox response may add `RUNTIME_BEHAVIOR_CONFIRMED`, but never changes historical evidence into official documentation.

## First live observation

One controlled request on 28 August 2026 completed mTLS but returned HTTP 500 / SOAP fault 33. The server rejected the historical namespace and reported `http://factemi.at.min_financas.pt/fatshareInvoices` as the namespace expected for `InvoicesRequest`. This is documented runtime behavior, not an automatic protocol change and not confirmation of authentication or authorization. No retry or alternative was attempted.

A subsequent single-variable experiment used exactly that namespace. One response reached the client, but local TLS metadata collection failed after Node released the response socket. The run is `PARSING_ERROR`: HTTP, SOAP body and namespace acceptance are not available, so the namespace was **not** promoted. No second request was made. The metadata timing bug now has an offline regression fix.

The authorized repeat after that fix made one request with the protocol unchanged: mTLS authorized, HTTP 200, no SOAP fault, and a parsed `EstadoOperacao` 486 indicating an empty invoice list. This confirms dispatch of `InvoicesRequest` with the namespace above. Only the namespace is promoted; the response does not independently promote SOAPAction, RSA/AES parameters, Created precision, username authorization or WFA permissions.

## Client identity isolation

A later single-variable 0.7.3 experiment restored the exact `TesteWebservices.pfx` identity used in the successful 0.7.2 execution while preserving the current code, endpoint, SOAP request, date interval and TLS options. The request completed with mTLS authorized, HTTP 200, no SOAP fault and `EstadoOperacao` 486. The specific `TesteWebservices.pfx` identity is therefore `RUNTIME_BEHAVIOR_CONFIRMED` for this endpoint.

This evidence is identity-specific. It does not prove that AT Issuing CA1 is universally required. The separate AT Issuing CA2 identity has different certificate and public-key fingerprints and remains unconfirmed for this endpoint after its TLS-handshake failure; it was not retested in this experiment.

## Request-semantics review required

Three successful authenticated requests returned `EstadoOperacao` 486 and an empty invoice list for one-day, seven-day and 28-day August 2026 intervals. The last experiment changed only the date range and made exactly one page-1 request. This is classified `EMPTY_RESULT_REQUIRES_REQUEST_SEMANTICS_REVIEW`.

Before another live request, an offline review must establish the exact date semantics, `CustomerTaxID` role, invoice direction/type selected by `InvoicesRequest`, implicit filters, pagination meaning and differences from the historical source implementation. No broader interval, different month or request parameter is inferred from the empty results.

Official sources remain the AT manuals for [generic aspects](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao_aspetos_gerais.pdf), [specific aspects](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao.pdf), and [FAQ 4996](https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx).
