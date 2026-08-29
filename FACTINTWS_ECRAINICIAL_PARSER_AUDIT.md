# FactIntWS EcraInicial parser audit

## Contract cross-check

The official response DTO exposes these overview aggregates:

- `NumTotalFaturasPorValidar`;
- `NumTotalFaturasPorAssociarReceita`;
- `ValorTotalBeneficioProvisorio`;
- `ListaSetores/Setor` and sector aggregates;
- `WSResult`.

The Node/reference and Android parsers locate elements by XML local name, so
SOAP/application namespace prefixes and child order do not change extraction.
The operation response root is required and the correct `Body` descendant is
selected. No wrapper-name or namespace mismatch was found.

## Synthetic non-zero proof

The synthetic overview fixture now deliberately uses:

- `NumTotalFaturasPorValidar = 5`;
- `ValorTotalBeneficioProvisorio = 503.39`;
- a sector with non-zero provisional benefit;
- application namespace prefixes;
- a child order different from the earlier fixture.

Results:

| Layer | Pending | Benefit cents | Non-zero sector | Result |
|---|---:|---:|---:|---|
| Node/reference parser | 5 | 50339 | yes | PASS |
| Android native parser | 5 | 50339 | yes | PASS |
| Flutter normalized bridge | 5 | 50339 | yes | PASS |

Decimal parsing remains integer-cents based; no floating-point representation
is introduced.

## Unsafe defaults found and fixed

Six unsafe zero defaults were found in the overview path:

| Layer | Fields | Previous behavior | New behavior |
|---|---|---|---|
| Android parser | three required aggregates | missing element became zero | `PARSING_ERROR` |
| Flutter bridge mapping | same three normalized aggregates | missing/invalid value became zero | parsing failure |

The Node parser previously returned `null` for missing aggregate fields rather
than zero. It now also treats all three as required and raises a structured
`PARSING_ERROR`, giving the three implementations the same fail-closed policy.

Legitimate literal zero values remain valid. Only absence or malformed content
fails.

## Root-cause impact

This was a real data-loss/diagnostic bug for the Android-to-Flutter path: a
missing required field could appear as a legitimate empty overview. It is not,
by itself, an explanation for the earlier controlled Node request. The recorded
8443 evidence says all three aggregate fields were present in that response,
and the Node parser did not default them to zero.

`EstadoOperacao=200` is therefore never used as proof that aggregate parsing is
complete. Operation success and payload-contract validation remain separate.
