# DM3IRS household automation

`infoAgregado` exposes 89 distinct payload field names in the sanitized static fixtures. Only part of that payload is household composition; the rest is income, expense, calculation and delivery state. Taxy must not present all 89 as “household data”.

## Complete 89-field partition

| Group | Count | Confirmed field names | Product treatment |
|---|---:|---|---|
| titular/cônjuge/dependentes and fiscal context | 27 | `ano-fiscal`, `utilizadorAutenticado`, `conjuge`, `dependentes`, `incluir`, `nif`, `nifA`, `nifB`, `nifs`, `nome`, `genero`, `estadoCivil`, `residenciaFiscal`, `residenciaAlternada`, `integraAgregado`, `pertenceSoConjuge`, `percentagemPartDespesas`, `fObito`, `cPosDecl`, `cProgen`, `ddfId`, `nifSPDG`, `nifEntidadeConsignacao`, `servicoFinancas`, `codAtividadeIRS`, `podeEntregarDeclAuto`, `xGinv` | project only composition/residence facts; identifiers remain session-only |
| rendimentos/retenções/contribuições | 20 | `rendimentos`, `detalheRendimentos`, `codigoRendimentos`, `rendimentoTDependente`, `rendimentoTIndependente`, `rendimentoPensoes`, `rendimentoTableList`, `impostoRetidoTDpendente`, `impostoRetidoTIndpendente`, `impostoRetidoPensoes`, `impostoRetidoTableList`, `contribuicoesObgSegSocial`, `contribuicoesTableList`, `nifEntidadePagadora`, `quotizacoesSindicais`, `sobretaxaPensoes`, `sobretaxaTDependente`, `rendAnosAnteriores`, `retFonte`, `pagConta` | route to income/evidence models, not household UI |
| despesas | 9 | `despesas`, `despesasAtividade`, `sectores`, `seccoes`, `sub-seccao`, `informacao-disponivel`, `valor`, `total`, `total-deferido` | expense evidence with explicit unavailable semantics |
| cálculo oficial | 26 | `rendimentoGlobal`, `rendColetavel`, `rendDetTaxas`, `deducoesEspecificas`, `deducoesColeta`, `coletaTotal`, `coletaLiquida`, `importanciaApurada`, `parcelaAbater`, `quocienteFamiliar`, `taxa`, `taxaAdicional`, `taxaEfetiva`, `beneficioMunicipal`, `abatimentoMinimoExistencia`, `usaRegraAntigaMinExistencia`, `impostoRendAnosAnteriores`, `impostoPagar`, `impostoReceber`, `calculoSemImposto`, `demonstracaoResultados`, `demonstracaoResultadosComConsignacaoIVA`, `flagCalculoLiquidacao`, `flagCalculoLiquidacaoComConsignacaoIVA`, `valorLiquidacao`, `valorLiquidacaoComConsignacaoIVA` | official comparison/golden trace; no silent replacement of Taxy calculation |
| entrega/variantes | 7 | `anexoSS`, `declaracao`, `iban`, `isValid`, `tc`, `ts1`, `ts2` | next-action/readiness; IBAN never persisted |
| **Total** | **89** |  |  |

## Household projection

- Titular: residence, civil status and safe role/composition flags; identifier used only to bind the authenticated session.
- Spouse: presence and inclusion choice; never persist spouse name or identifier merely because returned.
- Dependants: derive count for current `FiscalProfile`; detailed records require explicit future product need and consent.
- Ascendants: no dedicated confirmed field exists in the current static contract; keep the question/manual path if introduced.
- Joint custody/alternate residence: `residenciaAlternada` is a confirmed field, but remains confirm-only because fiscal meaning is person-specific.
- Tax year: reject cross-year projection before any product mapping.

## UI rule

Show a human summary (“household found for 2025”) and ask for confirmation. Detailed identifiers, internal flags and unused fiscal metadata remain hidden. A mismatch opens conflict resolution rather than overwriting the current profile.
