# Regras fiscais — 2026.2.0

Validado em **27/08/2026** para o âmbito de `SUPPORTED_SCOPE.md`. Os valores
executáveis residem exclusivamente em `assets/tax_rules/2026.json`.

Cada valor monetário é guardado em cêntimos e cada taxa em partes por milhão
(`ppm`). O motor não usa `double`.

## Rendimentos e taxas gerais

- IAS: 537,13 €.
- dedução específica de Categoria A: 4.587,09 €, ou contribuições obrigatórias
  superiores, sem exceder o rendimento.
- mínimo de existência: parâmetros do artigo 70.º, todos no JSON.
- nove escalões gerais: artigo 68.º, redação da Lei n.º 73-A/2025.
- adicional de solidariedade: 2,5% acima de 80.000 € e 5% acima de 250.000 €.

Fontes oficiais:

- https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs25.aspx
- https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs68.aspx
- https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs70.aspx

## Dependentes

- base: 600 € por dependente;
- dependente único/mais velho até 3 anos: majoração de 126 €;
- segundo dependente e seguintes até 6 anos: majoração de 300 €;
- as majorações não são cumulativas.

O motor ordena uma cópia das idades do mais velho para o mais novo antes de
aplicar a regra. A ordem de introdução nunca altera o resultado, incluindo listas
com três ou mais dependentes. Idades iguais produzem o mesmo total qualquer que
seja a ordem.

Fonte: CIRS artigo 78.º-A:
https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78a.aspx

## Deduções implementadas

| Categoria | Taxa | Limite individual/específico |
|---|---:|---:|
| Despesas gerais standard | 35% | 250 € |
| Despesas gerais monoparental | 45% | 335 € |
| Saúde standard | 15% | 1.000 € |
| Educação standard | 30% | 800 € |
| Lares | 25% | 403,75 € |
| PPR, idade < 35 | 20% | 400 € |
| PPR, 35–50 | 20% | 350 € |
| PPR, > 50 | 20% | 300 € |
| Rendas | 15% | limite transitório configurado, piso 2026 de 900 € |

As situações especiais de educação (estudante deslocado e majorações
territoriais) não são calculadas.

## IVA por exigência de fatura

O input é o **IVA suportado**, não o total da fatura.

| Campo | Taxa | Âmbito suportado |
|---|---:|---|
| `invoiceVat15` | 15% | setores enumerados no artigo 78.º-F, n.º 1 |
| `invoiceVat30` | 30% | ensino desportivo/recreativo, clubes e ginásios elegíveis |
| `invoiceVat35` | 35% | medicamentos de uso veterinário elegíveis |
| `invoiceVat100` | 100% | transportes públicos e assinaturas elegíveis de periódicos |

As quatro categorias concorrem para um único limite global de **250 €**. O JSON
contém taxa, unidade, fonte, comentário e versão para cada parâmetro.

Fonte: CIRS artigo 78.º-F:
https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78f.aspx

## Limite global de deduções

- sem limite deste artigo até ao limite do primeiro escalão;
- transição configurada entre 2.500 € e 1.000 €;
- 1.000 € a partir de 80.000 €;
- em agregados com três ou mais dependentes, majoração de 5% por dependente.

O detalhe de cada crédito, o ajuste do limite do IVA, o ajuste do limite global e
o limite pela coleta ficam disponíveis no `TaxResult.creditBreakdown` e no Tax
Validation Lab.

## Regras removidas ou bloqueadas

`otherEligibleTaxCredit` foi removido do modelo, serialização, UI, cenários e
testes. Nenhum crédito genérico pode ser somado. Consulte `SUPPORTED_SCOPE.md`
para todos os módulos `NEEDS_VERIFICATION`.

## Versionamento e rollback

- `schemaVersion`: compatibilidade estrutural; o parser rejeita versões antigas.
- `rulesVersion`: versão semântica do conjunto fiscal.
- `verifiedAt`: data apresentada na UI.
- `ruleMetadata`: auditoria dos parâmetros novos.

Rollback significa repor o JSON e o código compatível através de Git; uma regra
incompleta ou com status diferente de `VERIFIED_FOR_MVP_SCOPE` não carrega.
