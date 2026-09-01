# Beta feature matrix — 0.7.13

| Feature | Status | Online/offline | Data source | Persistence | Known limitations |
|---|---|---|---|---|---|
| Fiscal profile/checklist | BETA | Offline | User | Local normalized JSON | Does not claim an accuracy percentage. |
| IRS estimate | BETA | Offline | User + verified rule bundle | Existing local simulations | Supported scope only. |
| Scenario comparison | BETA | Offline | Overlay over a base simulation | Saved only when converted to simulation/snapshot | No new fiscal rules; hypothetical values stay separate. |
| Saved estimates | BETA | Offline | IRS result | Local versioned snapshot | No cloud sync; historical results are not silently recalculated. |
| Income | BETA | Offline | User/import provenance | Local normalized JSON | Possible duplicates require review. |
| Expenses | BETA | Offline | User/import/evidence provenance | Local normalized JSON | Not automatically treated as IRS deductions. |
| e-Fatura explorer | EXPERIMENTAL | Online | `api.taxy.pt` | Session memory only | Read-only; official provisional benefit unavailable. |
| Settings/privacy/diagnostics | BETA | Offline | App configuration | Local preference | Diagnostics intentionally omit fiscal data. |
| Documents | PLANNED | — | — | None | No upload policy yet. |
| Obligations | PLANNED | — | — | None | No validated deadline source yet. |

## Security boundaries

- The production app uses `api.taxy.pt`; it has no direct FactIntWS fallback.
- e-Fatura remains read-only and its payload is not persisted for stale display.
- Snapshots never contain credentials, tokens, cookies, SOAP or raw e-Fatura responses.
