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
| SOAP | 1.1 | OFFICIAL_DOCUMENTATION |
| Subuser username | `NIF/UserId` | OFFICIAL_DOCUMENTATION |
| Primary username | 9-digit taxpayer NIF | HISTORICAL_CODE_EVIDENCE; remote authorization UNKNOWN |
| AES | random 128-bit key per request, ECB, PKCS padding | OFFICIAL_DOCUMENTATION |
| Request/response | `InvoicesRequest` / `InvoicesResponse` | OFFICIAL_DOCUMENTATION |
| Namespace | `http://fatshare.at.min_financas.pt/fatshare` | HISTORICAL_CODE_EVIDENCE |
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

Official sources remain the AT manuals for [generic aspects](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao_aspetos_gerais.pdf), [specific aspects](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao.pdf), and [FAQ 4996](https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx).
