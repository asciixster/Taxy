# FactIntWS EcraInicial schema

Evidence: `CONFIRMED_FROM_OFFICIAL_APP`. Wire operation: `EcraInicial`.

## Request, exact child order

```xml
<app:EcraInicialRequest xmlns:app="http://factemi.at.min_financas.pt/factintws">
  <app:Nif>[REDACTED_IDENTIFIER]</app:Nif>
  <app:Ano>[YEAR]</app:Ano>
  <app:CanalOrigem>
    <app:Sistema>A</app:Sistema>
    <app:Versao>Android SDK: &lt;SDK_INT&gt; (&lt;RELEASE&gt;)</app:Versao>
  </app:CanalOrigem>
</app:EcraInicialRequest>
```

The app uses system `A`; the exact version formula is
`Android SDK: <SDK_INT> (<RELEASE>)`. Both are confirmed from the official Android
app. The constructor reads both values directly from `android.os.Build.VERSION`,
so the semantic status is `RUNTIME_DEVICE_METADATA`, not `FIXED_APP_VALUE`.

The first controlled tooling request used the coherent Android pair API 35 /
Android 15: `Sistema=A`, `Versao=Android SDK: 35 (15)`. The request failed after
TLS `secureConnect` and before HTTP, so server acceptance of this channel remains
`UNKNOWN`.

## Response fields

`AdquirentePodeManipularFaturas`, `ListaSetores/Setor`, `NumTotalFaturasPorAssociarReceita`, `NumTotalFaturasPorValidar`, `PodeMostrarAnoAnterior`, `ValorTotalBeneficioProvisorio`, and `WSResult` (`EstadoOperacao`, `Desc`). Each sector may contain `CodSetor`, `ValorBeneficioProvisorioPorSetor`, `ValorTotalDespesas`, and `ValorTotalIvaDespesas`.

The serializer/parser is offline-ready. Actual nullability, business-code meanings and Taxy identity authorization remain runtime unknown.
