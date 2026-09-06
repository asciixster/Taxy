# Arquitetura proposta de connectors AT

```text
Flutter
  -> api.taxy.pt (consent, session, normalized API)
      -> AT connector orchestrator (year + user boundary)
          -> TaxpayerProfileConnector
          -> IssuedDocumentsConnector
          -> IncomeConnector
          -> WithholdingConnector
          -> AssessmentConnector
          -> ObligationsConnector
          -> VatConnector
              -> official API adapter OR legitimate Portal read adapter
      -> normalization/provenance/conflict layer
      -> Taxy models
```

Flutter nunca conhece endpoints, cookies, WS-Security, certificados ou HTML AT. Adapters não partilham autorização implicitamente.

## Interfaces conceptuais

```text
read(input, ReadContext) -> CapabilityResult<T>
CapabilityResult = available(data, source, observedAt)
                 | unavailable(reasonCategory)
                 | notAuthorized
```

Cada connector declara `readOnly=true`, source stability, required authorization, minimal response fields, cache policy e tax year. Não há método genérico `callAT` nem fallback automático entre populações semanticamente diferentes.

## Modelos normalizados descobertos

- `TaxpayerActivityProfile`: activity state/dates, CAE/CIRS, IRS/VAT regime candidates.
- `IssuedDocumentSummary`: date/type/net/VAT/gross cents; identifiers optional server-only.
- `ReportedIncomeSummary`: category, period, gross/withholding cents (future; no source today).
- `AssessmentSummary`: year/status/tax-relevant lines/balance (future).
- `ObligationSummary`: type/period/status/official date (future).
- `VatStatus`: regime/periodicity and VIES validity as separate concepts.

Só `ReceivedInvoiceSummary` tem source runtime atual. Os restantes modelos são limitados aos campos publicamente observados/necessários, sem inventar payload.

## Errors

`AUTH`, `NOT_AUTHORIZED`, `NOT_AVAILABLE`, `UPSTREAM_CHANGED`, `PARSING`, `RATE_LIMIT`, `TEMPORARY`, `UNKNOWN`. Nenhum código, path, response raw, NIF, cookie ou valor fiscal entra em logs.

## Source of truth

`OFFICIAL_AT`, `USER_CONFIRMED`, `DOCUMENT_CONFIRMED`, `CALCULATED`; precedência serve provenance/decision support, não silent override. Divergência cria conflito.
