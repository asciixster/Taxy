# Taxy — connector-first reinvention

## Decision

Taxy only continues as an automated fiscal-data product. OCR, photographs and
manual document ingestion are not the core proposition and cannot be used to
claim that Taxy imports a taxpayer's fiscal situation.

The product promise is:

> With the taxpayer's explicit authorization, Taxy reads the fiscal data that
> already exists in official systems, normalizes it, explains what it means and
> asks only for information that is genuinely unavailable.

## Accepted source classes

1. Documented official read-only API authorized for Taxy.
2. Official read-only API with an explicit third-party entitlement.
3. Legitimate taxpayer-authenticated Portal session, mediated by api.taxy.pt,
   using read-only web/JSON flows and without bypassing access controls.
4. Public official datasets for non-personal reference data.

Official-app private identities, extracted private certificates, AT writes and
authorization bypasses are not product paths.

## Required automated dataset

The first useful connector must retrieve a meaningful subset of:

- taxpayer and fiscal-year context;
- household composition;
- Category A income;
- IRS withholding;
- mandatory Social Security contributions;
- Category B income and payments on account when present;
- e-Fatura expenses and pending invoices;
- submitted declaration status;
- assessment, refund or amount payable when available.

An endpoint being reachable is not success. Success requires populated data for
the authenticated taxpayer, stable field semantics and repeatable runtime
results.

## Product flow

1. The user authorizes a read-only connection.
2. The backend opens a short-lived official session or calls an entitled API.
3. The connector fetches only the minimum required fields.
4. Taxy normalizes every field with official provenance and tax-year isolation.
5. Conflicts are shown; official data never silently overwrites a user decision.
6. The interview asks only for fields not supplied by the official source.
7. The estimate is shown only when the supported scenario is complete.

## Architecture

```text
Flutter
  -> api.taxy.pt short-lived session
  -> isolated AT connector
  -> official API or authenticated Portal read flow
  -> normalized fiscal model
  -> confirmation/reconciliation
  -> supported IRS engine
```

AT-specific parsing and credentials must not be spread through the Flutter app.
Credentials must not return to Flutter after authentication, and raw upstream
payloads must not be retained.

## Existing evidence

- Portal/e-Fatura read flows have previously returned received invoices,
  pending items and deduction categories, but the current release path needs a
  repeatable end-to-end confirmation.
- FactIntWS accepted the Taxy transport and operations but returned populations
  inconsistent with the official client, so it is not a usable source.
- DM3IRS accepted the legitimate Taxy identity for historical delivery,
  receipt and declaration retrieval, but did not provide the required current
  structured prefill.
- No runtime-confirmed Taxy route currently provides current income,
  withholding, Social Security and household data together.

## Proof-of-viability gate

Before further consumer-product work, one legitimate connector must prove all
of the following in a controlled read-only run:

- authenticates as the taxpayer without an official-app private identity;
- returns populated current or relevant fiscal-year data;
- provides at least income plus withholding, or an equivalently valuable
  official dataset;
- exposes deterministic fields that can be normalized and tested;
- performs zero write operations;
- can be used by Taxy under a defensible authorization/terms path;
- succeeds repeatedly without endpoint or parameter guessing.

## Continue/stop rule

If the proof-of-viability gate passes, Taxy continues as a connector-first
product and the guided experience is rebuilt around official prefill.

If no authorized API or legitimate Portal read flow can pass the gate, the
consumer Taxy project is stopped. OCR, photographs and additional manual forms
must not be used as a substitute for the promised automation.

## Immediate scope

Until the gate passes:

- no new OCR or camera work;
- no new tax-category implementation;
- no UI expansion;
- no claim of comprehensive AT integration;
- no release presented as the intended automated Taxy product;
- concentrate exclusively on one authorized read connector and its normalized
  field coverage.
