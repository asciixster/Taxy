# AT Subuser Permissions

## Confirmed

The official AT e-Fatura FAQ 4996 names the profile:

```text
WFA — Comunicação de dados de faturas
```

The FAQ says a subuser with this profile is used in the webservice security header or for e-Fatura file communication, and that the profile permits only operations in the e-Fatura area.

Source: [AT e-Fatura FAQ — question 4996](https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx), checked 28 August 2026.

## Not confirmed

The official wording found does not separately state that WFA grants the new `InvoicesRequest` consultation operation introduced in the October 2025 manual. Therefore:

- WFA is the documented minimum e-Fatura profile;
- consultation-specific authorization remains `NEEDS_VERIFICATION`;
- a dedicated least-privilege subuser must be used;
- the principal Portal das Finanças credential must not be used;
- an authorization failure must be reported, not bypassed by granting broader profiles.

The 0.7.2 live harness validates `NIF/subuser`. It cannot verify permissions locally. A sandbox authentication or permission failure is classified and reported without retry; it must not trigger use of broader or principal credentials.
