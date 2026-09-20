# Capacidade read-only de declarações IRS

## Resultado

`IRS declaration read available = YES` for listing/history and 2024–2025
structured prefill. Historical detail retrieval remains partial.

O Portal permite ao titular consultar declarações e estados, e a AT publica o pacote de formatos Modelo 3 (2026-03-10). O pacote define ficheiros para entrega; não foi encontrado webservice público para obter a declaração vigente, anexos, divergências ou uma simulação oficial.

| Capability | Evidência | Estado |
|---|---|---|
| lista/estado de Modelo 3 submetida | `app/consulta` + `POST app/consulta/pesquisa` | RUNTIME_READ_CONFIRMED/PORTAL_WEB_FRAGILE |
| anexos submetidos | inferível da declaração, sem API | NOT_AVAILABLE |
| declaração vigente | 2024–2025 prefill plus confirmed 2024 historical PDF flow | RUNTIME_READ_CONFIRMED |
| divergências | funcionalidade Portal, sem contrato | UNKNOWN |
| simulação/resultado oficial | experiência Portal, sem API de consulta | UNKNOWN |

The current Portal year selector exposes 2015–2025. Controlled queries observed
records in 2021, 2022 and 2023, while structured prefill exposed only 2024 and
2025. No submit/simulate operation was invoked.

## DM3IRS Mobile addendum

The supplied offline observation identifies `obterDeclaracaoMobileRequest`, `checkEntregaDeclMobileRequest` and `obterReceiptMobileRequest` under an official IRS mobile service family. This improves discovery priority but does not change `IRS declaration read available = UNKNOWN`: the mobile contract, app call graph and Taxy entitlement are not available, and no live request was executed.

The official 2026 Modelo 3 XSD was inspected. It proves declaration-input groups (`Rosto` plus 13 annexes), not a DM3IRS response or official assessment output. It must not be treated as a golden calculation result.
