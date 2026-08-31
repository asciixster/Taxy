# FactIntWS invoice request difference audit

This comparison is structural and sanitized. Placeholders are synthetic; no
credential, taxpayer identifier or authenticated payload is included.

## FaturasPorClassificar

### Official-app reconstruction

```xml
<app:FaturasPorClassificarRequest>
  <app:Nif>&lt;SELECTED_TAXPAYER_NIF&gt;</app:Nif>
  <app:Ano>&lt;SELECTED_YEAR&gt;</app:Ano>
  <app:CanalOrigem>
    <app:Sistema>A</app:Sistema>
    <app:Versao>&lt;ANDROID_RUNTIME_VERSION&gt;</app:Versao>
  </app:CanalOrigem>
</app:FaturasPorClassificarRequest>
```

### Current Taxy serialization

The child names, order and value roles are identical. No pagination, sector,
consumer/professional mode, issuer field, month or quarter exists in either
request.

| Difference | Category | Likely material | Confidence |
|---|---|---:|---:|
| None found | structural | no | high |

The material semantic point is outside serialization: the official UI invokes
this operation only for the population counted by
`NumTotalFaturasPorValidar`. It is not an all-invoice listing operation.

## FaturasPorSetor — selected sector

### Official-app reconstruction

```xml
<app:FaturasPorSetorRequest>
  <app:NifAdquirente>&lt;SELECTED_TAXPAYER_NIF&gt;</app:NifAdquirente>
  <app:CodSetor>C05</app:CodSetor>
  <app:Ano>&lt;SELECTED_YEAR&gt;</app:Ano>
  <app:Indice>0</app:Indice>
  <app:CanalOrigem>
    <app:Sistema>A</app:Sistema>
    <app:Versao>&lt;ANDROID_RUNTIME_VERSION&gt;</app:Versao>
  </app:CanalOrigem>
</app:FaturasPorSetorRequest>
```

### Current Taxy serialization

For a selected `C05` sector and first result window, the child names, order,
types and values match the official-app builder. `Indice=0` is correct even
though its semantics are offset rather than page number.

| Difference | Category | Likely material | Confidence |
|---|---|---:|---:|
| Taxy calls the input `index` internally; wire name is `Indice` in both | naming only | no | high |
| Taxy documentation/tests have treated pagination as pages in places; official app uses offsets of 20 | semantic | no for offset 0; yes for later windows | high |
| No `TotalPaginas` exists in the official-app response DTO | response expectation | potentially for future pagination only | high |

## FaturasPorSetor — official homepage aggregate

The official homepage uses the following request alongside `EcraInicial`:

```xml
<app:FaturasPorSetorRequest>
  <app:NifAdquirente>&lt;SELECTED_TAXPAYER_NIF&gt;</app:NifAdquirente>
  <app:CodSetor></app:CodSetor>
  <app:Ano>&lt;SELECTED_YEAR&gt;</app:Ano>
  <app:Indice>0</app:Indice>
  <app:CanalOrigem>
    <app:Sistema>A</app:Sistema>
    <app:Versao>&lt;ANDROID_RUNTIME_VERSION&gt;</app:Versao>
  </app:CanalOrigem>
</app:FaturasPorSetorRequest>
```

Taxy cannot currently serialize this exact official-app request because it
rejects a sector not matching `^[A-Z]\\d{2}$`.

| Difference | Category | Likely material | Confidence |
|---|---|---:|---:|
| Explicit empty `CodSetor` accepted/used by official homepage, rejected by Taxy | population selection | **yes** | **high** |

This is the only material request difference found. It does not invalidate the
earlier runtime confirmation that `C05` dispatches successfully; it shows that
the earlier request queried only the health-sector population rather than the
official homepage's all-sector population.

## Fields specifically searched but absent

The official read builders contain no additional field for:

- page size;
- month or quarter;
- issuer/supplier mode;
- consumer/professional mode;
- `FAmbActProfissional`;
- `AdquirentePodeManipularFaturas`;
- aggregate household;
- document status or type filter.

`FAmbActProfissional` and `AdquirentePodeManipularFaturas` occur in responses
or later write flows, not as hidden defaults in these requests.

## Safe conclusion

The pending request has no structural divergence. The concrete-sector request
also matches the official app, including `C05` and initial offset 0. The one
evidence-backed population divergence is that Taxy has not tested — and cannot
currently express — the official homepage's explicit empty-sector request.
