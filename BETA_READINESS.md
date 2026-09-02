# Beta readiness — 0.7.15

Evidence combines automated tests with a real-device smoke on a Motorola Edge
50 Pro (Android 15 / API 35). `PASS` is limited to the current beta scope.

| Feature | Status | Offline | PT | EN | Dark | Responsive | Accessibility | Real-device | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Home | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Cold/warm launch and quick actions checked. |
| Fiscal profile/checklist | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Six objective checklist items; fiscal logic unchanged. |
| IRS estimate | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Wizard, result and locale-aware amounts checked on device. |
| Scenario comparison | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Real-device flow opened with normalized local values. |
| Saved estimates | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Create, list and scenario duplication checked; local only. |
| Income | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Provenance and locale-aware totals retained. |
| Expenses | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Local supporting evidence only. |
| e-Fatura explorer | BETA | BLOCKED | PASS | PASS | PASS | PASS | PASS | PASS | Network-only, read-only and `api.taxy.pt` only. |
| Settings/privacy/diagnostics | BETA | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Runtime locale/theme changes and sanitized diagnostics. |
| Documents | PLANNED | — | — | — | — | — | — | — | Outside RC scope. |
| Obligations | PLANNED | — | — | — | — | — | — | — | Outside RC scope. |

## Quality evidence

- PT/EN ARB parity and runtime locale switching are automated.
- Critical surfaces render at 320×640 and 200% text without overflow.
- Real-device checks covered light/dark, PT/EN, offline recovery, local IRS,
  e-Fatura failure isolation, scenarios and saved estimates.
- TalkBack exposed no critical unnamed action. Authentication fields now carry
  explicit semantic labels and have a regression test.
- The public e-Fatura app path remains `Flutter → api.taxy.pt`; production
  Android registers no direct FactIntWS bridge.

## External RC decision

`PRODUCT_READY_FOR_EXTERNAL_RC = NO` because Cloudflare credential rotation is
not technically confirmed and production signing material is not available to
the release environment. Neither gate was bypassed or replaced with an ad-hoc
secret.
