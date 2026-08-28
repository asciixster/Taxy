# AT Protocol Evidence — Taxy 0.7.1

Only official AT publications can move an item to `CONFIRMED_OFFICIAL`. A plausible implementation, behavior observed in another AT service, or a successful trial is not a substitute for protocol evidence.

Status values: `CONFIRMED_OFFICIAL`, `INFERRED_NOT_ALLOWED`, `UNRESOLVED`.

| Field | Value | Status | Official source / location | Verified |
|---|---|---|---|---|
| Test endpoint | `https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas` | CONFIRMED_OFFICIAL | Generic manual, 2.1.2 and 3.8 | 2026-08-28 |
| Transport | HTTPS + AT client certificate | CONFIRMED_OFFICIAL | Generic manual, 2.1.2 and 2.3 | 2026-08-28 |
| Client certificate | AT-issued/test SSL client certificate | CONFIRMED_OFFICIAL | Generic manual, 2.1.1–2.1.2 | 2026-08-28 |
| SOAP version | SOAP 1.1 | CONFIRMED_OFFICIAL | Specific manual v3.0, 2.1.10.3: envelope URI | 2026-08-28 |
| Username | `NIF/UserId` | CONFIRMED_OFFICIAL | Generic manual, H.1 | 2026-08-28 |
| UsernameToken | WS-Security UsernameToken with Username, Password, Nonce and Created | CONFIRMED_OFFICIAL | Generic manual, 2.2.1.1 | 2026-08-28 |
| AES algorithm/key | AES, fresh 128-bit key per request | CONFIRMED_OFFICIAL | Generic manual, H.2–H.4 | 2026-08-28 |
| AES mode/padding | ECB / PKCS5Padding | CONFIRMED_OFFICIAL | Generic manual, H.2 and H.4 | 2026-08-28 |
| RSA padding | — | **UNRESOLVED** | Generic manual H.3 says only “RSA” | 2026-08-28 |
| Timestamp | UTC ISO 8601 | CONFIRMED_OFFICIAL | Generic manual, H.4 | 2026-08-28 |
| Timestamp fractional precision | — | UNRESOLVED | Example contains fractional seconds but required precision is not stated | 2026-08-28 |
| Password encoding | AES ciphertext → Base64 confirmed; plaintext charset not expressly stated | **UNRESOLVED** | Generic H.2 | 2026-08-28 |
| Nonce | RSA-encrypted AES key → Base64 | CONFIRMED_OFFICIAL | Generic manual, H.3 | 2026-08-28 |
| WSDL | — | **UNRESOLVED** | Generic manual 3.6 says consultation WSDL will be made available later | 2026-08-28 |
| Namespace | — | **UNRESOLVED** | Specific manual example uses `fat:` without declaring `xmlns:fat` | 2026-08-28 |
| Operation | `InvoicesRequest` / `InvoicesResponse` | CONFIRMED_OFFICIAL | Specific manual v3.0, 2.1.10.1–2.1.10.2 | 2026-08-28 |
| SOAPAction | — | **UNRESOLVED** | No consultation WSDL/binding is published | 2026-08-28 |
| Request root | `InvoicesRequest` | CONFIRMED_OFFICIAL | Specific manual v3.0, 2.1.10.1 and 2.1.10.3 | 2026-08-28 |
| Request fields | exactly one of issuer/customer NIF, StartDate, EndDate, optional Pagination | CONFIRMED_OFFICIAL | Specific manual v3.0, pages 58–59 | 2026-08-28 |
| Subuser profile | `WFA — Comunicação de dados de faturas` | CONFIRMED_OFFICIAL for e-Fatura operations | AT FAQ 4996; consultation-specific wording is absent | 2026-08-28 |

## Official sources

- [e-Fatura — Comunicação por Webservice, Aspetos Genéricos](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao_aspetos_gerais.pdf)
- [e-Fatura — Comunicação por Webservice, Aspetos Específicos, v3.0](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao.pdf)
- [AT e-Fatura FAQ, especially 4994 and 4996](https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx)
- [Published Fatcorews WSDL](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Fatcorews.wsdl) — applies to the submission service, not substituted for `fatshareFaturas`.

## Empirical evidence (not protocol authority)

- The test endpoint accepted the provided client PFX and returned SOAP XML.
- One non-destructive `GET ?wsdl` on 2026-08-28 returned HTTP 500, `text/xml`, a SOAP envelope of 232 bytes, and no WSDL `definitions`.
- No alternate paths, namespaces, SOAPActions or RSA paddings were tried.

The executable registry lives in `tools/at_connector/src/evidence.mjs`. Any authenticated consultation is blocked while a critical item remains unresolved.
