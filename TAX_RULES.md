# Regras fiscais do MVP

Versão `2026.1.0`, verificada em 26-08-2026. Jurisdição: Continente; residência anual; Categoria A; tributação separada de um sujeito passivo.

## Parâmetros implementados

| Regra | Valor 2026 | Base |
|---|---:|---|
| IAS | 537,13 € | IAS 2026 |
| Dedução específica Categoria A | 4.587,09 € ou contribuições obrigatórias superiores | CIRS art. 25.º |
| Referência do mínimo de existência | 12.880 € | CIRS art. 70.º |
| Escalão 1 | até 8.342 € — 12,5% | CIRS art. 68.º |
| Escalão 2 | até 12.587 € — 15,7% | CIRS art. 68.º |
| Escalão 3 | até 17.838 € — 21,2% | CIRS art. 68.º |
| Escalão 4 | até 23.089 € — 24,1% | CIRS art. 68.º |
| Escalão 5 | até 29.397 € — 31,1% | CIRS art. 68.º |
| Escalão 6 | até 43.090 € — 34,9% | CIRS art. 68.º |
| Escalão 7 | até 46.566 € — 43,1% | CIRS art. 68.º |
| Escalão 8 | até 86.634 € — 44,6% | CIRS art. 68.º |
| Escalão 9 | superior a 86.634 € — 48% | CIRS art. 68.º |
| Adicional de solidariedade | 2,5% acima de 80.000 €; 5% acima de 250.000 € | CIRS art. 68.º-A |
| Dependente | 600 €; majorações por idade/ordem | CIRS art. 78.º-A |
| Despesas gerais | 35%, máximo 250 € por sujeito passivo | CIRS art. 78.º-B |
| Saúde | 15%, máximo 1.000 € | CIRS art. 78.º-C |
| Educação | 30%, máximo 800 € | CIRS art. 78.º-D |
| Lares | 25%, máximo 403,75 € | CIRS art. 84.º |
| IVA por fatura | 15% do IVA elegível, máximo 250 € | CIRS art. 78.º-F |
| PPR | 20%; limites de 400/350/300 € conforme idade | EBF art. 21.º |
| Rendas | 15%; limites transitórios 2026 parametrizados | CIRS art. 78.º-E |

São aplicados os limites globais de deduções do artigo 78.º e a majoração de famílias com pelo menos três dependentes. Todos os montantes são guardados em cêntimos e as taxas em partes por milhão.

## Fontes oficiais

- [Código do IRS — artigo 68.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs68.aspx)
- [Código do IRS — artigo 25.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs25.aspx)
- [Código do IRS — artigo 70.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs70.aspx)
- [Índice oficial do Código do IRS](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/pages/codigo-do-irs-indice.aspx)

## `NEEDS_VERIFICATION`

- Taxas/regras regionais da Madeira e Açores.
- Quociente familiar e cálculo completo de tributação conjunta.
- IRS Jovem.
- Residência parcial e não residentes.
- Outras categorias de rendimentos, deficiência e situações especiais.

O motor devolve resultado indisponível para estes casos. Acrescentar um ano ou módulo exige fonte, comentário técnico, fixtures e testes de fronteira antes de mudar o estado para verificado.
