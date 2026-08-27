# Política de arredondamentos fiscais

O motor guarda dinheiro exclusivamente como cêntimos inteiros (`Money`) e taxas
como partes por milhão. Não usa `double` em fórmulas fiscais. Multiplicações e
divisões monetárias usam inteiros arbitrariamente grandes e arredondamento
**half-up ao cêntimo** na fase em que a operação é executada.

## Fases atuais

| Fase | Base | Momento do arredondamento |
|---|---|---|
| Dedução específica | maior entre valor legal e contribuições, limitada ao rendimento | valores já em cêntimos |
| Mínimo de existência | fórmula parametrizada | cada multiplicação/divisão monetária |
| Rendimento coletável | bruto menos deduções/abatimentos | cêntimos, nunca negativo |
| Escalões | parcela por escalão em `ppm` | cada parcela ao cêntimo |
| Quociente conjunto | rendimento coletável / 2 | half-up antes de aplicar escalões |
| Coleta conjunta | coleta do quociente × 2 | depois da coleta individual |
| IRS Jovem | isenção e imputação proporcional da coleta | cada `mulDiv` ao cêntimo |
| Deduções à coleta | taxa por categoria e limites | cada categoria ao cêntimo; depois limites |
| Solidariedade | parcela por limiar; quociente 2 na conjunta | ao cêntimo por parcela |
| Imposto apurado | coleta − deduções + solidariedade | cêntimos; coleta regular nunca negativa |
| Saldo | retenções − imposto apurado | cêntimos; positivo é reembolso |

## Regras de alteração

- Nenhuma tolerância global é permitida em liquidações oficiais.
- Uma diferença de um cêntimo é uma falha até explicação legal/documental.
- Uma correção exige teste de regressão, fonte, atualização deste documento e
  entrada em `VALIDATION_CHANGELOG.md`.
- O motor ou a fixture nunca são alterados automaticamente para “fazer bater”.

## Incertezas abertas

A sequência exata de arredondamentos internos usada pelos sistemas da AT não é
publicada de forma completa para todas as fases e combinações. Em particular,
casos compostos de IRS Jovem, deduções repartidas e tributação conjunta exigem
confirmação por liquidações oficiais anonimizadas. Até existir evidência, a Taxy
mantém o algoritmo determinístico atual e reporta qualquer diferença como
`UNKNOWN`; não amplia tolerâncias nem apresenta precisão oficial.
