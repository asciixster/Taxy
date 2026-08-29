# FactIntWS invoice field matrix

Evidence labels: `RUNTIME_CONFIRMED`, `OBSERVED_RUNTIME_NON_EMPTY`,
`CONFIRMED_FROM_OFFICIAL_APP`, `OFFLINE_SYNTHETIC`, and `NOT_AVAILABLE`.
The 0.7.6 controlled discovery found no sector with evidence of invoice data,
so no invoice field is claimed as `OBSERVED_RUNTIME_NON_EMPTY`.

| Field | faturasPorClassificar | faturasPorSetor | Observed live | Parser support | Domain mapping | Notes |
|---|---|---|---|---|---|---|
| `IdDocumento` | app DTO | app DTO | NOT_AVAILABLE | required, sensitive | excluded | Never logged or exposed to UI domain |
| `NifEmitente` | app DTO | app DTO | NOT_AVAILABLE | optional, sensitive | excluded | Never logged |
| `NomeEmitente` | app DTO | app DTO | NOT_AVAILABLE | optional, sensitive | excluded | Never logged |
| `NumeroFatura` | app DTO | app DTO | NOT_AVAILABLE | optional, sensitive | excluded | Never logged |
| `ATCUD` | app DTO | app DTO | NOT_AVAILABLE | optional, sensitive | excluded | Never logged |
| `DataDocumento` | app DTO | app DTO | NOT_AVAILABLE | strict date-only | `date` | No timezone conversion |
| `ValorTotal` | app DTO | app DTO | NOT_AVAILABLE | integer cents | `totalCents` | Point and comma decimals supported offline |
| `ValorIva` | app DTO | app DTO | NOT_AVAILABLE | integer cents, optional | `vatCents` | No floating point |
| `ValorTributavel` | not seen in app DTO | not seen in app DTO | NOT_AVAILABLE | optional | `taxableCents` | Preserved only if supplied; evidence currently synthetic |
| `CodSetor` | app DTO | app DTO | NOT_AVAILABLE | opaque string | `sectorCode`, `classificationStatus` | Unknown values preserved |
| `CanalRegisto` | app DTO | app DTO | NOT_AVAILABLE | opaque code | `channel` | Unknown values preserved |
| `OrigemRegisto` | app DTO | app DTO | NOT_AVAILABLE | opaque code | optional metadata only | Not interpreted |
| `FAmbActProfissional` | app DTO | app DTO | NOT_AVAILABLE | known S/N or unknown | `professionalActivityFlag` | Fail-safe unknown code |
| `AdquirentePodeManipularFaturas` | response context | response context | NOT_AVAILABLE | known S/N or unknown | `canBeManipulated` | No write operation implemented |
| pending classification | operation semantics | no | operation accepted | explicit boolean | `pendingClassification` | True only for pending operation |

## Runtime result

| Operation | HTTP | EstadoOperacao | Invoice count | Parsed count | Evidence |
|---|---:|---:|---:|---:|---|
| `FaturasPorClassificar` | 200 | 204 | 0 | 0 | `RUNTIME_CONFIRMED` operation, empty result |
| `FaturasPorSetor` (`C05`, index 0) | 200 | 204 | 0 | 0 | `RUNTIME_CONFIRMED` operation, empty result |

### 0.7.6 controlled discovery

| Operation | Year | HTTP | EstadoOperacao | Result |
|---|---:|---:|---:|---|
| `EcraInicial` | 2026 | 200 | 200 | Sectors `C01`–`C15` and `C99`; all observed aggregates zero |
| `EcraInicial` | 2025 | 200 | 419 | Sanitized business response directing consultation of IRS deduction expenses in Portal das Finanças |

No sector or pending count provided evidence for a follow-up invoice request.
The exploration stopped after two requests; no brute-force sector search was
performed.

`REAL_FACTINT_INVOICE_RESPONSE_OBSERVED = NO`

`REAL_FACTINT_INVOICE_PARSING_CONFIRMED = NO`

## FactIntWS versus fatshare

| Concern | FactIntWS | fatshare |
|---|---|---|
| Consumer-facing pending/sector operations | Explicit operations, runtime-confirmed | No equivalent runtime evidence |
| Invoice wire format | FactInt-specific DTO | Independent fatshare DTO |
| Common future domain | Preferred candidate for consumer e-Fatura data | Remains separate historical/WFA connector |
| Automatic fallback | Never | Never |

The connectors remain independent. FactIntWS wire objects map to `AtInvoiceDomain`; fatshare is unchanged and is not used as an automatic fallback.
