# Capacidade read-only de declarações IRS

## Resultado

`IRS declaration read available = UNKNOWN`.

O Portal permite ao titular consultar declarações e estados, e a AT publica o pacote de formatos Modelo 3 (2026-03-10). O pacote define ficheiros para entrega; não foi encontrado webservice público para obter a declaração vigente, anexos, divergências ou uma simulação oficial.

| Capability | Evidência | Estado |
|---|---|---|
| lista/estado de Modelo 3 submetida | funcionalidade Portal conhecida, não endpoint documentado | DOCUMENTED_ONLY/PORTAL_WEB_FRAGILE |
| anexos submetidos | inferível da declaração, sem API | NOT_AVAILABLE |
| declaração vigente | sem API pública | NOT_AVAILABLE |
| divergências | funcionalidade Portal, sem contrato | UNKNOWN |
| simulação/resultado oficial | experiência Portal, sem API de consulta | UNKNOWN |

Não fazer scraping exploratório autenticado. Um futuro probe requer rota observada legitimamente no browser do próprio titular, confirmação GET/read semantics, CSRF/session map e zero execução de submit/simulate que possa criar estado.

## DM3IRS Mobile addendum

The supplied offline observation identifies `obterDeclaracaoMobileRequest`, `checkEntregaDeclMobileRequest` and `obterReceiptMobileRequest` under an official IRS mobile service family. This improves discovery priority but does not change `IRS declaration read available = UNKNOWN`: the mobile contract, app call graph and Taxy entitlement are not available, and no live request was executed.

The official 2026 Modelo 3 XSD was inspected. It proves declaration-input groups (`Rosto` plus 13 annexes), not a DM3IRS response or official assessment output. It must not be treated as a golden calculation result.
