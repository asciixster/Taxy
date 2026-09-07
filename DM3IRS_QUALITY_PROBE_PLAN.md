# DM3IRS quality-environment probe plan

This plan is dormant until AT confirms entitlement, supplies/approves the quality identity and confirms the official contract. Production must not be tested first when quality is available.

## Global controls

- one request per step; no automatic retry;
- explicit allow-list of operation, host, certificate fingerprint and test taxpayer role;
- write-operation deny-list at transport and orchestration layers;
- synthetic/AT-provided test data only;
- capture TLS/HTTP/SOAP/business status and field presence, never raw personal values;
- stop on schema drift, ambiguous authorization, unexpected side effect or redirect;
- retain sanitized evidence and exact schema version.

## Ordered steps

| Step | Operation | Purpose | Success signal | Stop condition |
|---:|---|---|---|---|
| 1 | `obterCatalogosMobileRequest` | transport, certificate, SOAPAction and basic entitlement with lowest sensitivity | TLS + recognized SOAP response + valid catalog shape | any TLS/auth/schema error; no retry |
| 2 | `infoUtilizadorAutenticadoMobileRequest` | confirm authorized taxpayer-profile fields | expected response root and allow-listed field presence | unexpected identifiers/fields or role mismatch |
| 3 | `infoAgregadoMobileRequest` | confirm household projection and official calculation provenance | household groups and server outputs with test data | any write-like behavior or unexplained calculation context |
| 4 | `checkEntregaDeclMobileRequest` | validate side-effect-free status read | stable status response | state mutation or undocumented reference behavior |
| 5 | `obterReceiptMobileRequest` | validate on-demand metadata | expected receipt shape | binary/PII excess or unclear retention terms |
| 6 | `obterDeclaracaoMobileRequest` | validate explicit on-demand PDF only if approved | bounded PDF payload | automatic persistence or unsupported content |

After each step, review evidence and obtain any required AT approval before advancing. A successful quality run does not authorize production. Production needs its own certificate/scope and change-control decision.
