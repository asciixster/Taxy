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

The app uses system `A`; the version string describes Android SDK/API. Taxy must use its own honest channel/version value rather than impersonating a device build.

## Response fields

`AdquirentePodeManipularFaturas`, `ListaSetores/Setor`, `NumTotalFaturasPorAssociarReceita`, `NumTotalFaturasPorValidar`, `PodeMostrarAnoAnterior`, `ValorTotalBeneficioProvisorio`, and `WSResult` (`EstadoOperacao`, `Desc`). Each sector may contain `CodSetor`, `ValorBeneficioProvisorioPorSetor`, `ValorTotalDespesas`, and `ValorTotalIvaDespesas`.

The serializer/parser is offline-ready. Actual nullability, business-code meanings and Taxy identity authorization remain runtime unknown.
