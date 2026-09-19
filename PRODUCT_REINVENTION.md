# Taxy — product reinvention

## Decision

Taxy continues, but it no longer presents direct AT connectivity as its core
product promise. The product must remain useful when every AT connector is
unavailable.

The new promise is:

> Give Taxy your fiscal documents once. Taxy structures and reconciles the
> evidence, asks only for what is missing, and explains what can and cannot be
> calculated safely.

## Primary journey

1. Import an official IRS declaration, annual income statement, withholding
   proof, Social Security proof, or supported image/PDF.
2. Extract candidates locally where supported.
3. Show every candidate for explicit confirmation or correction.
4. Reconcile confirmed evidence with current answers without silent overwrite.
5. Ask only the unresolved questions required by the supported calculation.
6. Present included, excluded, conflicted, and missing information together.
7. Produce an estimate only for a supported and sufficiently complete scenario.

## Product hierarchy

### Core — must work without AT connectivity

- guided interview and resume;
- local document capture and reviewed extraction;
- local import of a supported official IRS PDF;
- provenance, conflict resolution, and year isolation;
- Category A and other validated calculations;
- explicit unsupported handling;
- guided review and next action.

### Accelerators — optional and degradable

- e-Fatura read-only consultation;
- authorized official-data imports;
- historical IRS online retrieval.

An accelerator failure must never block the core journey or show a fake zero.

### Research — never exposed as a product promise

- official-app-private DM3IRS contracts without third-party entitlement;
- FactIntWS populations that differ by client identity;
- Category B calculation before the official validation gate;
- any AT write operation.

## Automation contract

Taxy reports automation coverage using required fiscal facts, not an arbitrary
percentage. Every relevant fact is one of:

- confirmed;
- needs confirmation;
- missing;
- conflicted;
- unsupported;
- not relevant.

Historical data can suggest a current answer but never becomes a current-year
TaxFact without confirmation. Extracted values never become TaxFacts directly.

## Immediate product changes

1. Make **Import documents** the primary shortcut after onboarding.
2. Present **Connect e-Fatura** as an optional time-saver, not the main route.
3. Promote local official-IRS-PDF import; keep unstable online retrieval hidden.
4. Add a single coverage view: what Taxy knows, what needs confirmation, what is
   missing, what is excluded, and the next useful action.
5. Remove language implying that Taxy imports all AT-held information.
6. Keep Category B identification and explanation, but fail closed on its final
   estimate until the validation gate passes.

## Success criteria

For a supported employee scenario, a user can reach a reviewed estimate by
importing an annual statement or entering only the missing values. The user can
always answer these questions:

- What did Taxy find?
- Where did it come from?
- What did I confirm?
- What is still missing or unsupported?
- What entered the estimate?
- What should I do next?

The journey remains usable with all AT connectors disabled.

## Kill gate

If this document-first journey cannot demonstrate a meaningful reduction in
manual entry for supported users, the consumer product should be stopped rather
than returning to unsupported private-endpoint experimentation.

Direct comprehensive AT prefill remains a separate entitlement-dependent track.
It may re-enter the product only after an authorized route and reliable runtime
data are both confirmed.
