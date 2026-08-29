# FactIntWS operations

All schemas below are reconstructed from official app call sites and DTOs. Only the first four are available in Taxy's offline serializer. Mutating operations remain deliberately unimplemented.

| Operation | Classification | Request fields in order | Response |
|---|---|---|---|
| `EcraInicial` | read-only | `Nif`, `Ano`, `CanalOrigem(Sistema,Versao)` | aggregate counters, sector list, `WSResult` |
| `DadosContribuinte` | read-only, sensitive | `Nif`, `CanalOrigem` | `Nif`, `Nome`, `WSResult` |
| `FaturasPorClassificar` | read-only | `Nif`, `Ano`, `CanalOrigem` | invoice list, `WSResult` |
| `FaturasPorSetor` | read-only | `NifAdquirente`, `CodSetor`, `Ano`, `Indice`, `CanalOrigem` | invoice list, total expenses/benefit, `WSResult` |
| `ClassificarFatura` | write | `OrigemRegisto`, `NifAdquirente`, list of `IdDocumento`/optional professional flag/sector, `CanalRegisto` | per-document classification result + `WSResult` |
| `RegistarFaturaQRCode` | write | QR request fields `A`–`I8`, `J1`–`J8`, `K1`–`K8` as present, then channel | invoice + `WSResult` |
| `EliminarFaturaQRCode` | write | `OrigemRegisto`, document list, channel | per-document result + `WSResult` |
| `AssociarReceita` | write | revenue association list with amount when present and document ID, channel | association result + `WSResult` |

`FaturasPorSetor` pagination uses `Indice` offsets observed as 0, 20, 40, 60 and 80. No automatic pagination is part of 0.7.5; the live validation used index 0 only.

## Taxy 0.7.5 runtime validation

- `FaturasPorClassificar`: HTTP 200, no SOAP fault, `EstadoOperacao=204`, controlled empty result. The request and functional operation are `RUNTIME_CONFIRMED`.
- `FaturasPorSetor`: HTTP 200, no SOAP fault, `EstadoOperacao=204`, controlled empty result for official-app sector `C05` and index 0. The request and functional operation are `RUNTIME_CONFIRMED`.
- No real invoice item was returned. Real-item field presence and parsing remain unconfirmed; synthetic fixtures are not promoted to runtime evidence.
