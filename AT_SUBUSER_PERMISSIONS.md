# AT Username and Permission Model

## Local username validation

Authentication supports a taxpayer's primary NIF credentials and, where applicable, supported AT subuser credentials.

- Primary username: exactly nine digits. `CustomerTaxID` is that NIF.
- Historical subuser username: `NIF/UserId`, with one to four digits after `/`. `CustomerTaxID` is the NIF-base.

Subusers are optional. Local syntax validation is separate from remote authentication and authorization.

## Evidence and remote authorization

AT FAQ 4996 documents the `WFA — Comunicação de dados de faturas` subuser profile for e-Fatura operations. It does not establish that a subuser is mandatory for `InvoicesRequest`, nor does it explicitly establish authorization of a primary user for this operation.

Therefore, an AT rejection is classified from the actual response as authentication or authorization failure. It is not converted into a global username-format rule, and the harness does not retry with another username type.

Source: [AT e-Fatura FAQ — question 4996](https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx), checked 28 August 2026.
