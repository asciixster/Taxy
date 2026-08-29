# FactIntWS EcraInicial schema

Evidence: `CONFIRMED_FROM_OFFICIAL_APP`. Wire operation: `EcraInicial`.

## Request, exact child order

```xml
<app:EcraInicialRequest xmlns:app="http://factemi.at.min_financas.pt/factintws">
  <app:Nif>[REDACTED_IDENTIFIER]</app:Nif>
  <app:Ano>[YEAR]</app:Ano>
  <app:CanalOrigem>
    <app:Sistema>[SYSTEM]</app:Sistema>
    <app:Versao>[VERSION]</app:Versao>
  </app:CanalOrigem>
</app:EcraInicialRequest>
```

The app uses system `A`; the version string describes Android SDK/API. The
structure and observed app value are evidence, but they do not prove that the
candidate Taxy pair `A` / `Taxy 0.7.4` is accepted. The combined concrete-value
status is therefore `CHANNEL_VALUES = UNKNOWN`, and live execution is blocked
until that choice is documented with adequate evidence.

## Response fields

`AdquirentePodeManipularFaturas`, `ListaSetores/Setor`, `NumTotalFaturasPorAssociarReceita`, `NumTotalFaturasPorValidar`, `PodeMostrarAnoAnterior`, `ValorTotalBeneficioProvisorio`, and `WSResult` (`EstadoOperacao`, `Desc`). Each sector may contain `CodSetor`, `ValorBeneficioProvisorioPorSetor`, `ValorTotalDespesas`, and `ValorTotalIvaDespesas`.

The serializer/parser is offline-ready. Actual nullability, business-code meanings and Taxy identity authorization remain runtime unknown.
