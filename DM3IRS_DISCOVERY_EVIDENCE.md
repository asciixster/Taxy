# DM3IRS Mobile — evidence ledger

## Evidence levels

| Level | Meaning |
|---|---|
| `APK_OBSERVATION_SUPPLIED` | Name/path reported from the prior offline APK analysis; the APK artefact is not available in this worktree. |
| `PUBLIC_XSD_CONFIRMED` | Directly present in the official 2026 Modelo 3 XSD package. |
| `PUBLIC_PRODUCT_CONFIRMED` | Described by an official public product page. |
| `INFERRED` | Plausible, but not sufficient for a request or production decision. |
| `UNKNOWN` | No evidence available. |

## Sources inspected

1. AT, [Suporte Informático IRS 2026](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Formato_de_ficheiros/Contribuintes_e_contabilistas_certificados/Documents/Suporte_Informatico_IRS_2026.zip), downloaded only to an OS temporary directory. It contains `Modelo3IRSv2026.xsd` and `types.xsd`.
2. AT schema locations reported by the APK investigation: `https://servicos.portaldasfinancas.gov.pt/dm3irs/schemas` and `https://servicos.portaldasfinancas.gov.pt/dm3irsmobile/schemas`.
3. AT service location reported by the APK investigation: `https://servicos.portaldasfinancas.gov.pt:411/dm3irsMobileService/`.
4. Google Play public listing for package `pt.gov.portaldasfinancas.irs`, which describes submission of IRS Automático and consultation of the 2025 declaration.

The schema/service locations could not be retrieved with the local TLS stack: all metadata retrieval attempts ended before an HTTP response with `decryption failed or bad record mac`. They were not SOAP business requests, used no client identity, and were not retried.

## What the public XSD proves

The root `Modelo3IRSv2026` contains `Rosto` and 13 annex groups: A, B, C, D, E, F, G, G1, H, I, J, L and SS. The package defines official declaration-input types, including the Article 151 activity-code catalog and Anexo B income catalog. It also contains Anexo B elements such as `AnexoBq03C07`, `RetencoesFonte`, `DespesasEncargos`, `AnoRendimentos`, `ValorRendimentoPCI`, `ValorRendimentoASP`, `RendimentosPCI` and `RendimentosASP`.

It does **not** prove that `obterDeclaracaoMobileRequest` returns this document, that `obterCatalogosMobileRequest` exposes these catalogs, or that any of the named mobile operations accepts the same fields. It contains declaration input, not an official calculation/liquidation output.

## Missing artefacts

- official IRS APK/base split or a sanitized class/method inventory;
- mobile WSDL/XSD;
- SOAP version, action and namespace;
- request field sequences;
- response roots and parser models;
- WS-Security/auth envelope for this service;
- proof that the Taxy identity is entitled for any DM3IRS operation.

Therefore builder → serializer → parser → repository → screen traces remain `NOT_VERIFIABLE_APK_ABSENT`, and no live operation passes the five-part gate.
