# DM3IRS catalog sync plan

The official client requests four catalog types independently.

| Catalog | Data shape | Product use | Category B use | Proposed refresh | Cache/versioning | Privacy |
|---|---|---|---|---|---|---|
| `ENTIDADES_BANCARIAS` | JSON CDATA: code/name entries | IBAN institution display only | none | per app/rules release or explicit version change | versioned short cache; bundled fallback | reference data |
| `ENTIDADES_CONSIGNACAO` | JSON CDATA: identifier/name entries | consignation chooser | none | annual + explicit invalidation | tax-year/version keyed cache | reference data |
| `TIPOS_INSTITUICAO` | JSON CDATA: value/code/text entries | institution classification | none | annual | schema + payload hash; bundled fallback | reference data |
| `GRAFICO_DESPESAS` | JSON CDATA: description/percentage/order/color | expense presentation | never use percentages as fiscal rules | annual/app release | locale/year/version keyed cache | reference data |

## Controls

- Validate JSON shape and allow-listed catalog type before replacing cache.
- Never execute code or trust server-provided colors/text as fiscal logic.
- Preserve the last known valid version and fail closed on malformed payload.
- Catalog payload has no confirmed activity-code/Category B catalog in this APK version. Therefore it cannot replace the curated 90-code research fixture.
- If AT later adds an activity catalog, reconcile additions/removals and the `1519` exception explicitly before use.
