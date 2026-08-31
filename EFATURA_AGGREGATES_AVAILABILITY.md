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

Classification: **source D — not available in the original backend endpoint**.

Controlled observation rejected `homeBeneficio.action` as a taxpayer source:
that page contains nationwide e-Fatura statistics (hundreds of millions of
documents), not the authenticated account's aggregates. Its values must never
be projected into the Taxy overview.

The authenticated personal source is
`consultarDocumentosIRSAdquirente.action`. Its official page script reads
`json/obterDocumentosIRSAdquirente.action`, whose document rows include
`actividadeEmitente`, `actividadeEmitenteDesc`,
`valorTotalBeneficioProv`, `valorTotalSetorBeneficio` and
`valorTotalDespesasGerais`. This establishes a source for personal sector and
benefit inputs, but not by itself the capped aggregate shown by the official
mobile app.

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

## Controlled runtime validation (2026-08-31)

Three read-only backend requests were used, without automatic retries. The
updated Android build received and rendered the pending count as
`available(5)`. The provisional benefit, revenue-association count and sectors
were received as `unavailable`; the UI rendered **Indisponível**, kept the real
pending count and showed the partial-success explanation. It did not render a
synthetic `0,00 €`.

The later source audit confirmed that `homeBeneficio.action` is a public
national-statistics view and is therefore unsuitable. A controlled personal
IRS-document query returned 357 rows across six mapped sectors and integer-cent
wire values. Summing `valorTotalBeneficioProv` naively produced `334853` cents,
which does not match the approximately `50339` cents shown by the official app.
That number is treated as an uncapped/intermediate diagnostic, not as the
official provisional benefit. The backend was returned to fail-safe
`unavailable` output while state filtering and statutory/AT aggregate limits
are isolated. Pending invoices remain runtime-confirmed and usable during this
partial success.
