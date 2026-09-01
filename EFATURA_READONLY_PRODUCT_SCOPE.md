# e-Fatura read-only product scope

## Product intent

Taxy reproduces the useful read-only journey of the official e-Fatura
application without copying its source code, visual assets, private keys or
application identity:

1. connect to the taxpayer's account;
2. show the official overview values that are actually available;
3. show expense sectors;
4. open a sector and list its invoices;
5. expose normalized, non-technical evidence for a future IRS estimate.

The Taxy experience deliberately does not classify, register, delete or modify
an invoice and does not associate professional revenue. Those actions remain in
the official e-Fatura application. A pending count is informational only and no
validation control is rendered by Taxy.

## IRS evidence boundary

The read-only domain exposes `EfaturaIrsEvidence` with three independent values:

- the official provisional benefit returned by AT;
- the sum of sector expense totals returned by AT;
- the sum of sector VAT totals returned by AT.

Every value retains explicit availability. Sector totals are only summed when
the complete sector list and every contributing value are available. Missing
data stays unavailable and is never converted to zero.

The official provisional benefit is not an IRS refund estimate. It is evidence
produced by e-Fatura and may be subject to sector limits and other AT rules. The
document and VAT totals are inputs for future estimation; they are not injected
into the production IRS engine in this release because that would require an
explicit, evidence-backed mapping to household members, deduction categories,
limits and already-assessed benefits.

## User experience

The experimental screen now presents, in order:

- the official provisional benefit;
- pending-information and revenue-association counts as read-only facts;
- a dedicated IRS-prediction evidence card;
- expense sectors and their available expense/benefit totals;
- sector invoice lists opened on demand.

Technical identifiers, taxpayer identifiers, document identifiers, SOAP data,
credentials and certificate material are not displayed. The feature flag stays
disabled by default.

## Deliberate exclusions

- no invoice-validation action;
- no write operation against AT;
- no automatic background refresh;
- no copied official-application implementation or artwork;
- no official-application private identity;
- no guessed official aggregate;
- no change to the production IRS calculation engine.

