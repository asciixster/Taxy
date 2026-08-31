# e-Fatura aggregate availability

## Source audit

The runtime-confirmed backend path authenticates to the Portal das Finanças and
reads the acquired-invoice population from
`consultarDocumentosAdquirente.action`. That response is sufficient to derive
the number of invoices pending validation and to normalize invoice items.

It does **not** provide the provisional tax benefit, pending revenue-association
count or sector aggregates consumed by the overview. The initial backend reader
represented those unknown values as `0`, `0` and `[]`. Those values were
compatibility placeholders, not observations of the taxpayer account.

Classification: **source D — not available in the current backend endpoint**.
The Portal exposes a separate read-only deductible-expenses area at
`homeBeneficio.action`; its response contract still needs controlled runtime
observation before a parser can be implemented without inventing fields.

## Backend contract

Every aggregate now carries explicit availability:

```json
{
  "provisionalBenefitCents": { "status": "unavailable" },
  "pendingValidation": { "status": "available", "value": 5 },
  "pendingRevenueAssociation": { "status": "unavailable" },
  "sectors": { "status": "unavailable" }
}
```

An available sector list uses `items`. Each sector carries the same explicit
wrapper for its benefit and invoice count, plus an `active`, `inactive` or
`unknown` activity state. A malformed `available` value fails closed; an absent
optional value becomes unavailable and never zero.

## Application semantics

`AtValue<T>` distinguishes `available`, `unavailable`, `loading` and `error`.
An overview is `partialSuccess` whenever one or more aggregates are not
available. Existing invoice data remains usable during partial success or a
later refresh error. The UI renders a real `available(0)` as localized zero and
renders an unavailable value as **Indisponível** / **Unavailable**.

The experimental feature remains disabled by default. No write operation, raw
Portal response, credential, taxpayer identifier or document identifier is
part of this contract.
