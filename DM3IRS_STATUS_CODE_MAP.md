# DM3IRS status-code map

Scope: static, offline analysis of the user-supplied official IRS APK. No network request was made for this analysis. Dart AOT stores small integers as tagged values, so the compiled comparisons `0x104` and `0x106` decode to status codes `130` and `131`.

## Result for status 130

`EstadoOperacao = 130` is an exact match for `BadIrsYearErrorEffect`. The effect raises `BadIrsYearException`; the login flow catches that exception class and displays **“Período de entrega de IRS não é válido”**. The effect is installed in the shared `ApiService` error chain, so this is a global DM3IRS status class rather than an `infoUtilizador`-specific branch.

This establishes the meaning of the status. A later one-shot `checkEntrega` read accepted the same `2025` year with status `0` and found an already delivered declaration. This rules out a global rejection of the numeric year for that operation. Because the official app bypasses `infoUtilizador` when a declaration exists, invalid eligibility for the `infoUtilizador` delivery branch is now the strongest explanation. The causal link remains partial because no server-side status documentation was supplied.

## Explicit mappings

| Code | Operation | Condition | Meaning | User message/effect | Source | Confidence |
|---:|---|---|---|---|---|---|
| 0 | all parsed operations | parsed `statusType/codigo` equals zero | success | response parser continues | APK_CODE: `ApiService.parseSoapResponse` | EXACT |
| 11 | global | code equals 11 | credentials expired | credentials-expired exception/effect | APK_CODE: `CredentialsExpiredEffect.matchesError` | EXACT class; server wording not retained |
| 33 | global | code equals 33 | bad request class | bad-request exception/effect | APK_CODE: `BadRequestErrorEffect.matchesError` | EXACT class; detailed meaning unknown |
| 50–52 | global | code in inclusive range | bad request class | bad-request exception/effect | APK_CODE: `BadRequestErrorEffect.matchesError` | EXACT class; detailed meanings unknown |
| 53 | global | code equals 53 | missing permissions class | missing-permissions exception/effect | APK_CODE: `MissingPermissionsErrorEffect.matchesError` | EXACT class; detailed meaning unknown |
| 54 | global | code equals 54 | missing permissions class | missing-permissions exception/effect | APK_CODE: `MissingPermissionsErrorEffect.matchesError` | EXACT class; detailed meaning unknown |
| 7–20 | global | code in inclusive range | security class, except earlier effect precedence such as code 11 | security exception/effect | APK_CODE: `BadSecurityErrorEffect.matchesError` | EXACT class/range |
| 101–120 | global | code in inclusive range | service-error class except earlier matches (104–108 security; 120 bad request) | service exception/effect | APK_CODE: `ServiceErrorEffect.matchesError` and `_handleApiError` ordering | EXACT class/range |
| 104–108 | global | code in inclusive range | security class due to effect precedence | security exception/effect | APK_CODE: `BadSecurityErrorEffect.matchesError` | EXACT class/range |
| 120 | global | code equals 120 | bad request class due to effect precedence | bad-request exception/effect | APK_CODE: `BadRequestErrorEffect` precedes `ServiceErrorEffect` | EXACT class; detailed meaning unknown |
| 121 | global | code equals 121 | unexpected error class | unexpected-error exception/effect | APK_CODE: `UnexpectedErrorEffect.matchesError` | EXACT class; detailed meaning unknown |
| **130** | **global** | **code equals 130** | **invalid IRS delivery/exercise period** | **`BadIrsYearException`; “Período de entrega de IRS não é válido”** | **APK_CODE: `BadIrsYearErrorEffect`; APK_RESOURCE/CALL_SITE: `LoginViewModel.performLogin`** | **EXACT** |
| 131 | global | code equals 131 | invalid IRS delivery/exercise period class | `BadIrsYearException`; same login message | APK_CODE: `BadIrsYearErrorEffect.matchesError` | EXACT class |
| -1 | global | code equals -1 | bad request class | bad-request exception/effect | APK_CODE: `BadRequestErrorEffect.matchesError` | EXACT class; detailed meaning unknown |
| -999 | global | code equals -999 | bad response sentinel | bad-response exception/effect | APK_CODE: `BadResponseErrorEffect.matchesError` | EXACT class |

The table intentionally avoids assigning detailed server meanings that the APK does not provide. The order installed by `_handleApiError` is credentials, expired credentials, bad request, bad response, security, missing permissions, bad IRS year, service error, unexpected error; the first matching effect controls overlapping ranges.

## Response trace

1. `ApiService.parseSoapResponse` parses the shared `statusType`, including `codigo` and optional `mensagem`.
2. Code `0` returns the operation response to its parser.
3. A nonzero code enters `ApiService._handleApiError`.
4. The shared `BadIrsYearErrorEffect.matchesError` matches `130` or `131`.
5. `triggerEffect` raises `BadIrsYearException`, carrying the server message when present.
6. `LoginViewModel.performLogin` catches that exception class and displays the invalid-delivery-period message.

No operation-specific `130` handler was found in `infoUtilizador`, `infoAgregado`, catalogs, declaration check, receipt, declaration retrieval, or submission handlers.

## Safe conclusion

- Exact meaning: found.
- Exact reason that `infoUtilizador` rejected the `2025` context: not fully documented; the official-flow branch was inapplicable because a delivered declaration existed is the highest-confidence inference.
- Deterministic request correction: none.
- Safe next live action: none until the AT confirms the currently accepted exercise/campaign year or provides an updated sanctioned configuration/status catalogue.
