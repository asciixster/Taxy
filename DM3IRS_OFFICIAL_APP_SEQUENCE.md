# DM3IRS official-app sequence

The observed static sequence is:

1. Load environment, Portal trust material, bundled TLS client identity and AT public request-encryption key.
2. Authenticate locally held taxpayer credentials into a WS-Security header.
3. `infoUtilizadorAutenticadoMobileRequest` loads the authenticated taxpayer and eligibility context.
4. `infoAgregadoMobileRequest` submits the selected household composition for the fiscal year and receives household, income, expense and calculation data.
5. `obterCatalogosMobileRequest` is issued per catalog type when auxiliary lookups are needed.
6. `checkEntregaDeclMobileRequest` checks whether a delivered declaration reference exists.
7. `obterReceiptMobileRequest` retrieves receipt/status metadata for that reference.
8. `obterDeclaracaoMobileRequest` retrieves the PDF representation when requested by the user.
9. `submeterDeclaracaoMobileRequest` belongs to a separate explicit confirmation flow and is a write.

This is a branching sequence, not proof that every call occurs on every launch. The service is SOAP-only at application level; no bearer token was found. Basic authentication is configurable at HTTP level for environments, while taxpayer authentication remains in WS-Security. No stable cookie dependency was found in the DM3IRS call path.
