# Fronteiras legais, técnicas e de privacidade

## Autorização

- Um WSDL público documenta um contrato; não concede acesso a qualquer contribuinte/população.
- mTLS aceite prova identidade de transporte; não prova entitlement funcional.
- Credenciais Portal só podem ser usadas para o próprio titular, com consentimento informado e lifecycle mínimo.
- Nunca usar chaves privadas, PFX ou sessão da app oficial; nunca tentar reproduzir controlo privado para obter population entitlement.
- Não inferir autorização de redistribuir dados a terceiros ou contabilistas.

## Minimização/cache

| Data | Minimum | Policy proposta |
|---|---|---|
| received/issued invoices | data, tipo, cents, IVA, sector/status | PERSIST_WITH_USER_CONSENT; omitir NIF/ID por defeito |
| activity profile | state, dates, CAE/CIRS, regimes | SHORT_CACHE ou consented persistence |
| reported income/withholding | category, period, cents, source | PERSIST_WITH_USER_CONSENT |
| declaration status | year, status, relevant annex presence | SHORT_CACHE |
| assessment | tax-relevant lines only | PERSIST_WITH_USER_CONSENT; raw PDF no-store after reviewed extraction |
| obligations | type, period, official status/date | SHORT_CACHE |
| payment/debt | aggregate/status | SESSION_ONLY/NO_STORE |
| VIES | valid/date/country | NO_STORE/SHORT_CACHE |

## Stability and rate

Prefer `OFFICIAL_API_STABLE`, then `OFFICIAL_API_LEGACY`; Portal web requires change detection, fail-closed parsing and manual refresh. FactIntWS is `MOBILE_PRIVATE_CONTEXT`. Sem limites publicados, defaults conservadores: nenhuma repetição automática numa ação, exponential backoff apenas para reads idempotentes, circuit breaker e polling no máximo diário quando o produto o justificar.

## Implementation gate

Source official or legitimate Portal flow + auth confirmed + read-only semantics + schema understood + runtime confirmation + sanitized tests. Falhar um item mantém `unavailable`, nunca zero sintético.
