# DM3IRS → Taxy product field map

Status: design-only. Every mapping assumes explicit AT entitlement, runtime confirmation and tax-year isolation. `OFFICIAL_AT` never silently overrides user- or document-confirmed data.

Actions: `KEEP` keeps the current question; `PREFILL_CONFIRM` proposes a value; `AUTO_IMPORT_READONLY` imports observational evidence; `HIDE_IF_OFFICIAL` suppresses a redundant presence question only when the official response is current and unambiguous.

## FiscalProfile summary

| Classification | Count | Fields |
|---|---:|---|
| `CONFIRMED_DIRECT` | 3 | `activeTaxYear`, `region`, `civilStatus` |
| `DERIVED` | 3 | `dependentCount`, `hasEmployment`, `hasSelfEmployment` |
| `NOT_SAFE_TO_PREFILL` | 0 of the current six | values still require confirmation where they affect the calculation |

All 6 current `FiscalProfile` fields are technically prefillable. Direct does not mean automatically accepted.

## infoUtilizador / person fields

| DM3IRS field(s) | Taxy model | Current question | Action | Provenance | Confirm | Privacy |
|---|---|---|---|---|---:|---|
| `ano-fiscal` | `FiscalProfile.activeTaxYear` | year selector | PREFILL_CONFIRM | OFFICIAL_AT | YES | fiscal-context |
| `residenciaFiscal` | `residentPortugal`, `FiscalProfile.region` after mapping | `residentPortugal`, `region` | PREFILL_CONFIRM | OFFICIAL_AT | YES | sensitive-profile |
| `estadoCivil` | `FiscalProfile.civilStatus` | `civilStatus` | PREFILL_CONFIRM | OFFICIAL_AT | YES | sensitive-family |
| `conjuge`, `integraAgregado`, `pertenceSoConjuge` | family facts | `jointTaxation` | PREFILL_CONFIRM | OFFICIAL_AT | YES | sensitive-family |
| `dependentes` | derived `dependentCount` plus household evidence | `dependentCount` | PREFILL_CONFIRM | OFFICIAL_AT | YES | highly-sensitive-family |
| `codAtividadeIRS` | activity-classification candidate | `selfEmploymentIncome` and future activity question | PREFILL_CONFIRM; never infer current revenue from registration alone | OFFICIAL_AT | YES | sensitive-income |
| `rendimentos` / `detalheRendimentos` | income evidence | income-presence questions | HIDE_IF_OFFICIAL when current-year groups are complete | OFFICIAL_AT | YES for amounts | highly-sensitive-financial |
| `podeEntregarDeclAuto` | readiness/eligibility hint | none | AUTO_IMPORT_READONLY | OFFICIAL_AT | NO | sensitive-fiscal |
| `hasIrsJovem` | IRS Jovem context | future/current eligibility flow | PREFILL_CONFIRM | OFFICIAL_AT | YES | sensitive-fiscal |
| `nome`, `genero`, `fObito` | no current calculation model | none | KEEP outside FiscalProfile; do not persist unless product need is approved | OFFICIAL_AT | n/a | personal/highly-sensitive |
| `nif`, `nifSPDG`, `nifEntidadeConsignacao` | authentication/reference only | none | KEEP out of product state | OFFICIAL_AT | n/a | direct-identifier |
| `servicoFinancas`, `cPosDecl`, `cProgen`, `ddfId`, `xGinv`, `percentagemPartDespesas`, `residenciaAlternada` | no safe current equivalent or specialist context | none | KEEP internal/session-only | OFFICIAL_AT | YES before fiscal use | sensitive-fiscal |

## infoAgregado income and expense fields

| DM3IRS field(s) | Taxy destination | Current question | Action | Provenance | Confirm | Privacy |
|---|---|---|---|---|---:|---|
| `rendimentoTDependente` | employment income component | `employmentIncome`, `employmentGrossCents` | HIDE_IF_OFFICIAL + PREFILL_CONFIRM amount | OFFICIAL_AT | YES | highly-sensitive-financial |
| `rendimentoTIndependente` | self-employment component | `selfEmploymentIncome` | HIDE_IF_OFFICIAL + PREFILL_CONFIRM future amount | OFFICIAL_AT | YES | highly-sensitive-financial |
| `rendimentoPensoes` | pension-presence fact/component | `pensionIncome` | HIDE_IF_OFFICIAL | OFFICIAL_AT | YES | highly-sensitive-financial |
| `impostoRetidoTDpendente`, `impostoRetidoTIndpendente`, `impostoRetidoPensoes`, `retFonte`, `impostoRetidoTableList` | category/total withholding evidence | `withholdingCents` | PREFILL_CONFIRM | OFFICIAL_AT | YES | highly-sensitive-financial |
| `contribuicoesObgSegSocial`, `contribuicoesTableList` | contribution evidence | `socialSecurityCents` | PREFILL_CONFIRM | OFFICIAL_AT | YES | highly-sensitive-financial |
| `pagamentosPorConta`, `pagConta` | payment-on-account evidence | future payment question | PREFILL_CONFIRM | OFFICIAL_AT | YES | highly-sensitive-financial |
| `codigoRendimentos`, `rendimentoTableList`, `nifEntidadePagadora` | income classification/detail | no direct current model | AUTO_IMPORT_READONLY except payer identifier; confirmation before calculation | OFFICIAL_AT | YES | identifier/financial |
| `quotizacoesSindicais`, `sobretaxaPensoes`, `sobretaxaTDependente`, `rendAnosAnteriores` | unsupported/specialist inputs | none | KEEP internal until engine support exists | OFFICIAL_AT | YES | highly-sensitive-financial |
| `despesas`, `despesasAtividade`, `sectores`, `seccoes`, `sub-seccao`, `valor`, `total`, `total-deferido`, `informacao-disponivel` | expense evidence/availability | `expensesReviewed` | PREFILL_CONFIRM; availability must not become zero | OFFICIAL_AT | YES | highly-sensitive-financial |

## Server-calculation and delivery fields

| DM3IRS field(s) | Taxy destination | Current question/action | Action | Persistence | Privacy |
|---|---|---|---|---|---|
| `rendimentoGlobal`, `rendColetavel`, `deducoesEspecificas`, `deducoesColeta`, `coletaTotal`, `coletaLiquida` | official comparison snapshot | Review/estimate comparison | AUTO_IMPORT_READONLY | NO_STORE or user-approved comparison snapshot | highly-sensitive-financial |
| `abatimentoMinimoExistencia`, `usaRegraAntigaMinExistencia`, `quocienteFamiliar`, `taxa`, `taxaAdicional`, `taxaEfetiva`, `beneficioMunicipal`, `parcelaAbater`, `importanciaApurada`, `impostoRendAnosAnteriores`, `rendDetTaxas` | official explainability/golden trace | Review detail only | AUTO_IMPORT_READONLY | NO_STORE by default | highly-sensitive-financial |
| `impostoPagar`, `impostoReceber`, `calculoSemImposto` | official result comparison | result hero | AUTO_IMPORT_READONLY, labelled official context | SHORT_CACHE | highly-sensitive-financial |
| `demonstracaoResultados*`, `flagCalculoLiquidacao*`, `valorLiquidacao*`, `tc`, `ts1`, `ts2` | official calculation variants | scenario review | AUTO_IMPORT_READONLY | NO_STORE | highly-sensitive-financial |
| `anexoSS`, `irsJovem`, `incluir`, `nifs`, `optar` | submission-context evidence | relevant review | PREFILL_CONFIRM | USER_CONFIRMED_PERSIST | highly-sensitive-fiscal |
| `declaracao`, `isValid` | delivery/readiness state | next action | AUTO_IMPORT_READONLY | SHORT_CACHE | sensitive-fiscal |
| `iban`, `checkIban`, `indicadorAssociarIban` | declaration payment metadata | none | do not import into Taxy | NO_STORE | restricted-financial-identifier |
| consignation fields | declaration choice | none/current future choice | KEEP / PREFILL_CONFIRM only if implemented | SESSION_ONLY | sensitive-preference |

## Catalog, status, receipt and PDF

| Operation/fields | Taxy destination | Action | Confirmation | Storage | Privacy |
|---|---|---|---:|---|---|
| catalog `tipoCatalogo`, `detalheCatalogoJsonCdata` | versioned reference catalogs | AUTO_IMPORT_READONLY | NO | SHORT_CACHE | public/reference unless payload proves otherwise |
| check `declaracao` + common status | declaration-state monitor | AUTO_IMPORT_READONLY | NO | SHORT_CACHE | sensitive-fiscal/reference |
| receipt `situacao`, dates, `tipo`, `mensagemPosSubmissao`, `montante` | timeline/status | AUTO_IMPORT_READONLY | NO | SHORT_CACHE | highly-sensitive-financial |
| receipt identifiers, taxpayer name/identifier, liquidation reference | transport/display-on-demand only | do not persist by default | n/a | NO_STORE | direct-identifier/restricted |
| declaration `pdf` | ephemeral viewer/download initiated by user | KEEP on-demand | explicit user action | NO_STORE unless user explicitly saves outside Taxy | highly-sensitive-document |

## Minimization rule

The connector should parse a full upstream response into an ephemeral envelope, immediately project only allow-listed fields, discard raw XML/PDF buffers, and persist only confirmed Taxy facts. Availability, provenance, fiscal year and retrieval time travel with every projection.
