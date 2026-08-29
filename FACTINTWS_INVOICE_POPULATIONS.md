# FactIntWS invoice populations

This is an offline audit of the official e-Fatura Android app v4.7.1 (build
29), correlated with Taxy's current serializers and the controlled runtime
results already recorded in this repository. No request was made while
performing this audit.

Evidence labels used below:

- `CONFIRMED_FROM_OFFICIAL_APP`: directly observed in a request builder, DTO,
  constant or UI call site from the official app.
- `RUNTIME_BEHAVIOR_CONFIRMED`: demonstrated by an earlier controlled Taxy
  request.
- `INFERENCE`: supported by the flow, but not explicitly specified.
- `UNKNOWN`: no reliable local evidence was found.

## Operation populations

| Operation | Population | Filters and defaults | Consumer / issuer role | Year / period | Sector | Pagination | Evidence | Unknowns |
|---|---|---|---|---|---|---|---|---|
| `EcraInicial` | Consumer overview: provisional benefit, invoices requiring validation/revenue association, and sector aggregates | `Nif`, `Ano`, `CanalOrigem` | The selected taxpayer is the acquirer/consumer; the app passes the selected taxpayer NIF | Civil/fiscal year selected in the app | Returns a sector list; no sector request filter | None | Builder, response DTO and homepage UI are `CONFIRMED_FROM_OFFICIAL_APP`; operation is `RUNTIME_BEHAVIOR_CONFIRMED` | Exact business calendar behind prior-year availability |
| `FaturasPorClassificar` | Only invoices requiring classification, not all invoices belonging to the account | `Nif`, `Ano`, `CanalOrigem`; no hidden role, professional or pagination field was found | Selected taxpayer as consumer/acquirer | Same selected year as the overview | No sector filter | None in request or response DTO | The homepage exposes the validation action only when `NumTotalFaturasPorValidar > 0`; that action passes the same year to this operation (`CONFIRMED_FROM_OFFICIAL_APP`) | Whether every kind of pending document is included |
| `FaturasPorSetor` | Consumer/acquirer invoices for one sector, or all sectors when `CodSetor` is empty | `NifAdquirente`, `CodSetor`, `Ano`, `Indice`, `CanalOrigem` | Explicit acquirer NIF; no issuer mode exists in the request | Same selected year as the overview | Concrete `Cxx` code on sector navigation; empty string in the homepage aggregate request | `Indice` is a zero-based offset. The app uses 0, 20, 40, 60 and 80 and increments by 20. Page size is therefore implicitly 20; there is no page-size field or `TotalPaginas` in the APK response DTO | Manager, homepage and expense-list flow are `CONFIRMED_FROM_OFFICIAL_APP`; `C05`/0 was previously accepted at runtime | Server behavior of empty `CodSetor`; maximum result window beyond the observed offsets |
| `DadosContribuinte` | Identity/profile lookup (`Nif`, `Nome`), not an invoice population | `Nif`, `CanalOrigem` | Selected taxpayer identity | None | None | None | Builder and response DTO are `CONFIRMED_FROM_OFFICIAL_APP` | Authorization rules for a selected household member |

## Call-site flow

### Sector expenses

```text
HomepageActivity sector card
  -> card tag (for example C05)
  -> DespesasAtividadeActivity(COD_SETOR, ANO)
  -> obtemFaturasPorSetor(selectedNif, codSetor, selectedYear, indice)
  -> FaturasPorSetorRequest
       NifAdquirente
       CodSetor
       Ano
       Indice
       CanalOrigem(Sistema, Versao)
```

The expense list starts with `indice = 0`. Infinite scrolling adds 20 before
each subsequent call. A separate official-app helper requests the first 100
items as five requests with offsets 0, 20, 40, 60 and 80. This establishes
offset semantics and an implicit batch size of 20; `Indice=0` is correct for
the first result window.

The homepage has a second, materially different call path:

```text
HomepageActivity refresh
  -> obtemEcraInicial(selectedNif, selectedYear)
  -> parallel FaturasPorSetorRequest
       NifAdquirente = selected taxpayer
       CodSetor = ""
       Ano = selected year
       Indice = 0
       CanalOrigem
```

The empty sector is therefore a deliberate official-app value, not an omitted
or malformed parameter. Taxy's current serializer requires a shaped `Cxx`
code and cannot reproduce this all-sector request.

### Pending classification

```text
HomepageActivity
  -> show validation action only when NumTotalFaturasPorValidar > 0
  -> ValidarFaturasActivity(ANO)
  -> obtemFaturasPorClassificar(selectedNif, selectedYear)
  -> FaturasPorClassificarRequest
       Nif
       Ano
       CanalOrigem(Sistema, Versao)
```

Consequently, a taxpayer may have many e-Fatura documents and legitimately
receive zero items from `FaturasPorClassificar` when none require validation.
An empty result from this operation is not evidence that the account has no
invoices.

## Year semantics

`Ano` is the year selected in the official app, and the same value is passed
to `EcraInicial`, `FaturasPorClassificar` and `FaturasPorSetor`. The app:

- initializes to the device's current civil year;
- before 16 March, initializes a launcher session to the previous year;
- otherwise exposes current/previous navigation according to
  `PodeMostrarAnoAnterior` and app state;
- passes the four-digit year as text with no month, quarter or date range.

This is `CONFIRMED_FROM_OFFICIAL_APP`. In the current August 2026 test context,
2026 matches the official app's default. The earlier 2025 response with code
419 is evidence that the server applied a different business outcome to that
year, but it does not redefine `Ano`.

## Sector encoding

The official app uses string codes with the `C` prefix and two digits. The
v4.7.1 code and UI map `C01` through `C12` and `C99`; later runtime overview
evidence also exposed `C13` through `C15`. The sector card passes the code
unchanged to `CodSetor`. Therefore `C05`, not `05` or `5`, is the correct wire
encoding for health.

There is also an all-sector mode encoded as an explicit empty `CodSetor`
element. No separate `ALL`, numeric sentinel or omitted-element form was found.

## Taxpayer and professional context

The request receives the taxpayer selected by the UI. The manager removes a
subuser suffix only when the supplied login identifier is longer than nine
characters; a nine-digit selected taxpayer remains unchanged. `FaturasPorSetor`
names this value `NifAdquirente`; it is not an issuer query.

No request-side consumer/professional flag was found in either read operation.
`FAmbActProfissional` is an invoice response field and a later classification
choice. `AdquirentePodeManipularFaturas` is overview/response capability
metadata. Neither is serialized as a read filter.

The app can change the selected taxpayer, so a household member's documents
may require that member's NIF. There is no aggregate-household flag: population
selection is by the explicit NIF passed to the operation.

## Business codes

- `204`: `CONFIRMED_FROM_OFFICIAL_APP` as
  `CODIGO_ESTADO_SUCESSO_VAZIO`. The app accepts it alongside 200 for the two
  invoice-list operations. It means successful empty operation result, not a
  proof that the taxpayer has no invoices in other years, sectors, taxpayers
  or operation populations.
- `419`: `UNKNOWN`. No mapping for 419 was found in the official-app constants,
  call sites, DTOs or local historical code. Runtime evidence is limited to an
  `EcraInicial` 2025 business response directing the user to IRS deduction
  expenses in Portal das Financas. Any stronger label remains inference.

## Updated runtime constraint

User-confirmed visual evidence from the official app for the intended account
and year 2026 shows five invoices requiring validation, a non-zero provisional
benefit and non-zero sector activity. Taxy's `EcraInicial` returned zero for
the corresponding aggregates. Therefore `GENUINE_OPERATION_EMPTY` is rejected
for `EcraInicial` and `FaturasPorClassificar` once the selected identity is
confirmed equal. The divergence occurs before sector filtering; the identity
comparison in `FACTINTWS_TAXPAYER_IDENTITY_DIFF.md` now takes priority.

## Ranked hypotheses

| Hypothesis | Confidence | Evidence for | Evidence against / limit |
|---|---|---|---|
| `TAXPAYER_SELECTION_MISMATCH` | **HIGH** | The official app tracks and can switch a complete selected credential; Taxy derives the population only from its configured login | Equality of the two selected base NIFs has not yet been checked without disclosure |
| `UNKNOWN_SERVER_POPULATION_RULE` | **MEDIUM** | Transport/auth success does not prove body-population equivalence | No specific undocumented rule was found locally |
| `REQUEST_SCHEMA_MISMATCH` (all-sector default unsupported) | **MEDIUM** | The official homepage deliberately sends `CodSetor=""`; Taxy currently forbids it and only tested `C05` | Cannot explain the zero `EcraInicial`, which has no sector filter |
| `GENUINE_OPERATION_EMPTY` | **REJECTED** for the intended 2026 identity | None after the direct official-app observation | Official app shows five pending invoices and non-zero overview values |
| `YEAR_SEMANTICS_MISMATCH` | **LOW** | Documents can exist in a different year, and 2025 returned 419 | In August the official app defaults to current year; Taxy's 2026 value matches that behavior |
| `INDEX_PAGINATION_MISMATCH` | **LOW** | Offset is semantically different from a page number | Both models use 0 for the first window, so the tested request is unaffected |
| `SECTOR_CODE_ENCODING_MISMATCH` | **LOW** | None | `C05` is the exact official-app string form |
| `OTHER` (undocumented server-side population rule) | **LOW** | Server rules are not fully documented | No request field or UI flow supports a more specific theory |

## Next single experiment

Perform the sanitized identity equality gate described in
`FACTINTWS_TAXPAYER_IDENTITY_DIFF.md`. If the official selected credential and
Taxy configured login differ, run one `EcraInicial` with the official selected
login identity while preserving every other parameter. The empty-sector test
remains relevant only after overview identity is aligned.
