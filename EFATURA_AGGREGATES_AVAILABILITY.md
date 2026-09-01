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
benefit inputs. An internal experiment aggregated the integer-cent document
benefits and applied documented caps. This is useful diagnostic evidence, but
is not semantically equivalent to the official consolidated overview. External
beta policy therefore keeps provisional benefit and sectors **unavailable**;
document sums must never be presented as an official e-Fatura aggregate.

## Official-app 6.0.10 cross-check

Static analysis of the supplied official e-Fatura APK 6.0.10/build 20260519
confirms that the mobile overview consumes the server's typed
`EcraInicialResponse.ValorTotalBeneficioProvisorio`. The parsed response is held
as `dadosEcraInicial` in the homepage state and passed to the benefit-rendering
path, which formats it as currency. The AOT snapshot contains no evidence of a
homepage calculation that sums invoice rows or reapplies sector/statutory caps.

`valorTotalBeneficioProv` remains a per-document value, while
`ValorTotalBeneficioProvisorio` is the consolidated FactIntWS value produced by
AT. The Taxy aggregation therefore stays deliberately narrow: it uses the
Portal-provided benefits, integer cents and documented caps; it does not
recalculate deductible VAT or infer unknown tax rules.

The same APK contains and programmatically loads an official-app client
certificate/private-key pair into Dart's `SecurityContext`. Its private material
was neither read nor extracted. Together with Taxy's observed HTTP 200/zero
overview under a different legitimate client identity, this raises
`CLIENT_APPLICATION_IDENTITY_CONTEXT_MISMATCH` as the strongest remaining
population hypothesis. It remains an inference: transport authorization alone
does not demonstrate that AT grants the same logical consumer population to
every accepted client identity.

Public-material comparison strengthens and narrows that conclusion. The APK's
AT request-encryption key has the same SPKI SHA-256 as Taxy's configured public
AT cipher key, so request-key drift is rejected. Conversely, neither Taxy's
local nor backend TLS client certificate fingerprint matches the official
application's production or quality client certificate. The official public
app's production-labelled certificate is valid during the observed 2026
operation, while its bundled quality certificate had already expired. Static
analysis cannot prove the exact server policy, but application-client identity
is the only demonstrated cryptographic context difference that still aligns
with HTTP 200/SOAP success and a divergent logical population.

## Backend contract

Every aggregate carries explicit availability. Until an official equivalent
source exists, production benefit and sector values must remain unavailable:

```json
{
  "provisionalBenefitCents": { "status": "unavailable" },
  "pendingValidation": { "status": "available", "value": 5 },
  "pendingRevenueAssociation": { "status": "unavailable" },
  "sectors": { "status": "unavailable" }
}
```

An available sector list uses `items`. Each sector carries the same explicit
wrapper for its benefit, total expenses, total VAT expenses and invoice count,
plus an `active`, `inactive` or `unknown` activity state. A malformed
`available` value fails closed; an absent optional value becomes unavailable
and never zero.

## Application semantics

`AtValue<T>` distinguishes `available`, `unavailable`, `loading` and `error`.
An overview is `partialSuccess` whenever one or more aggregates are not
available. Existing invoice data remains usable during partial success or a
later refresh error. The UI renders a real `available(0)` as localized zero and
renders an unavailable value as **Indisponível** / **Unavailable**.

The experimental feature remains disabled by default. No write operation, raw
Portal response, credential, taxpayer identifier or document identifier is
part of this contract.

The UI no longer exposes an action for pending validation. Pending counts are
read-only information and direct the user to the official application when an
invoice needs intervention. The new `EfaturaIrsEvidence` projection keeps the
official provisional benefit separate from summed document expense/VAT totals;
it does not treat either value as a final IRS refund estimate.

## Controlled runtime validation (2026-09-01)

A controlled read-only run with the intended credential returned a complete
non-zero overview across six mapped categories. Five category benefits matched
the previously captured official-app overview exactly; the remaining category
and total were 40 cents higher. The same live source also reported two more
pending documents than that earlier app screenshot. These two changes support
snapshot/update drift rather than a missing Taxy cap or category rule.

The observation demonstrates access to current Portal document data, not
semantic equivalence with the official aggregate. It must not cross the
external-beta product boundary. No real response, credential, document
identifier, taxpayer identifier or issuer identity is persisted.
