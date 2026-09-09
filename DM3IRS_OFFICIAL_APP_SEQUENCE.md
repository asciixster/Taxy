# DM3IRS official-app sequence

The refined observed static sequence is:

1. Load environment, Portal trust material, bundled TLS client identity and AT public request-encryption key.
2. Authenticate locally held taxpayer credentials into a WS-Security header.
3. Resolve the selected exercise year through `AppDataService.exerciseYearForRequests`; undefined year stops locally with `BadIrsYearException`.
4. `checkEntregaDeclMobileRequest` checks whether a delivered declaration reference exists for base NIF plus exercise year.
5. If a declaration exists, `obterReceiptMobileRequest` retrieves its receipt/status metadata.
6. If no delivered declaration exists, `infoUtilizadorAutenticadoMobileRequest` is called with the same base NIF and selected exercise year and loads the taxpayer/eligibility context.
7. After infoUser succeeds, `obterCatalogosMobileRequest` is issued per catalog type by `loadAllEntities` when the Home initialization path continues.
8. `infoAgregadoMobileRequest` submits the selected household composition for the fiscal year and receives household, income, expense and calculation data.
9. `obterDeclaracaoMobileRequest` retrieves the PDF representation when requested by the user.
10. `submeterDeclaracaoMobileRequest` belongs to a separate explicit confirmation flow and is a write.

This is a branching sequence, not proof that every call occurs on every launch. The earlier high-level inventory placed infoUser before the delivery check; call-site register tracing now establishes the order above. The service is SOAP-only at application level; no bearer token was found. Basic authentication is configurable at HTTP level for environments, while taxpayer authentication remains in WS-Security. No stable cookie dependency was found in the DM3IRS call path, and the preceding delivery check is not evidence of server-side session state.

## Exercise-year source and status 130

`AppDataService.exerciseYearForRequests` prefers the environment value and falls back to application data. In the analysed APK, production and quality both set `exerciseYearRequests` to `2025`, while `config/app.json` sets `exerciseYear` to `2025`. The selected value is a tax declaration/exercise year and is used by both the delivery check and authenticated-user request.

The shared response error chain maps status codes `130` and `131` to `BadIrsYearErrorEffect`. The login handler for the resulting `BadIrsYearException` displays “Período de entrega de IRS não é válido”. This does not reveal whether the rejected condition is the numeric year or the current availability of its delivery campaign, and it provides no deterministic alternative to the configured `2025`.
