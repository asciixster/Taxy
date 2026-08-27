# IRS Jovem — implementação Taxy 0.4

## Separação de responsabilidades

`IrsJovemEligibilityEngine` decide o estado `ELIGIBLE`, `NOT_ELIGIBLE`,
`NEEDS_MORE_INFORMATION` ou `NOT_REQUESTED`. `IrsJovemTaxAdjustment` trata a
isenção e `IrsJovemTaxEngine` produz duas liquidações comparáveis. O motor base
não decide elegibilidade.

## Histórico e elegibilidade

Cada `IrsJovemIncomeYear` declara ano, rendimento A, rendimento B, condição de
dependente, residência em Portugal e utilização de regime incompatível. O
histórico tem de conter todos os anos desde o primeiro registo até ao ano
simulado, mesmo quando não houve rendimento. Duplicados, lacunas ou ausência do
ano atual devolvem `NEEDS_MORE_INFORMATION`.

Contam os anos com rendimentos A/B como sujeito passivo não dependente. Anos sem
A/B e anos como dependente não consomem o período. O titular tem de ter até 35
anos em 31 de dezembro, não ser dependente no ano, ter situação tributária
regularizada e não ter beneficiado de RNH, IFICI ou Regressar.

O modelo antigo `qualifyingIncomeYears` é lido apenas para migração. Não é
recolhido pela UX 0.4.

## Taxas e limite

- 1.º ano: 100%;
- 2.º ao 4.º: 75%;
- 5.º ao 7.º: 50%;
- 8.º ao 10.º: 25%;
- máximo anual: 55 IAS (28.737,50 € em 2025; 29.542,15 € em 2026).

Os parâmetros residem nos rulesets anuais, não em widgets.

## Liquidação

1. A liquidação normal apura dedução específica, mínimo de existência e
   rendimento coletável.
2. A isenção é o menor valor entre percentagem do rendimento A e 55 IAS.
3. A parcela isenta reduz o rendimento coletável, sem o tornar negativo.
4. Nos termos do artigo 22.º, n.º 4, a parcela isenta é adicionada sem deduções
   para determinar a taxa progressiva.
5. A coleta correspondente ao rendimento isento é imputada
   proporcionalmente e retirada.
6. Deduções à coleta, solidariedade, retenções e saldo são apurados sobre a
   liquidação ajustada.

Em conjunta, o rendimento para taxa usa quociente 2, a coleta é multiplicada
por dois e só depois se faz a imputação proporcional. Em separada, cada titular
é liquidado autonomamente. A Taxy compara separada/conjunta com e sem benefício.

## Fail-safe e limitações

- informação insuficiente nunca aplica isenção; o IRS normal continua;
- Categoria B pode contar no histórico de elegibilidade, mas não é liquidada;
- anos anteriores com rendimento A/B durante não residência permanecem
  `NEEDS_MORE_INFORMATION` por segurança;
- residência parcial, guarda partilhada e restantes situações fora do
  `SUPPORTED_SCOPE.md` continuam recusadas;
- zero liquidações oficiais reais estão incluídas. A release tem referências
  manuais auditadas, mas recomenda-se validação humana contra demonstrações AT
  anonimizadas antes de produção.

## Fontes oficiais

- [CIRS artigo 12.º-B](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs12b.aspx)
- [CIRS artigo 22.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs22.aspx)
- [AT — Folheto IRS Jovem 2025](https://info.portaldasfinancas.gov.pt/pt/apoio_contribuinte/Folhetos_informativos/Documents/Folheto_IRS_jovem_2025.pdf)
- [AT — Newsletter janeiro 2026](https://info.portaldasfinancas.gov.pt/pt/at/Divulgacao/publicacoes_internas/Newsletter_AT/Documents/Newsletter-39-janeiro-2026.pdf)
