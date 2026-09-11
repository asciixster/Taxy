# Oportunidades de prefill AT

Total de oportunidades distintas: **14**. Só a primeira população está pronta para uso atual; as restantes mantêm gates.

| # | AT field/capability | Taxy target | Confidence | Confirm user? | Status |
|---:|---|---|---|---:|---|
| 1 | received invoice date/amount/sector | Expenses/e-Fatura evidence | OFFICIAL source, field semantics known | conflicts only | RUNTIME_READ_CONFIRMED |
| 2 | pending invoice count | `REVIEW_EFATURA` next action | CONFIRMED | NO | RUNTIME_READ_CONFIRMED |
| 3 | activity active state | `selfEmploymentPresent` | candidate OFFICIAL | YES | AUTH_UNKNOWN |
| 4 | activity start date | activity-start context | candidate OFFICIAL | YES if tax effect | AUTH_UNKNOWN |
| 5 | activity cessation date | activity status | candidate OFFICIAL | YES | AUTH_UNKNOWN |
| 6 | CIRS code | self-employment activity classification | LIKELY | YES | AUTH_UNKNOWN |
| 7 | CAE code | activity classification | LIKELY | YES | AUTH_UNKNOWN |
| 8 | IRS regime | simplified/organized regime | LIKELY | YES mandatory | AUTH_UNKNOWN |
| 9 | IVA regime | VAT context | LIKELY | YES | AUTH_UNKNOWN |
| 10 | issued invoice gross/net/VAT | self-employment revenue lines | INCOMPLETE until auth/semantics | YES | SCHEMA_CONFIRMED |
| 11 | Category A communicated income | employment income | INCOMPLETE | YES | NOT_AVAILABLE |
| 12 | Category A/B withholding | withholding components | INCOMPLETE | YES | NOT_AVAILABLE |
| 13 | Modelo 3 sections/status | review completeness/history | INCOMPLETE | YES | NOT_AVAILABLE |
| 14 | assessment lines/final balance | official result/history and engine validation | CONFIRMED if sourced | NO for display; never overwrite estimate silently | NOT_AVAILABLE |

Precedence is conceptual: `OFFICIAL_AT`, `USER_CONFIRMED`, `DOCUMENT_CONFIRMED`, `CALCULATED`. It decides display/trust metadata, never silent overwrite. Conflicts route to Guided Review.
