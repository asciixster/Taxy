# Tax Engine — matriz de testes 0.3

A suite executa mais de 200 testes e compara cêntimos inteiros.

## Escalões

Para 2025 Continente e 2026 Continente/Madeira/Açores, cada limite finito tem testes a −0,01 €, no limite e a +0,01 €. As tabelas regionais são comparadas com o Continente.

## Agregados

- casado e união de facto;
- rendimento só A, só B, ambos, iguais e muito diferentes;
- conjunta vs. duas liquidações separadas;
- despesas próprias, despesas dos dependentes 50/50 e PPR por titular;
- zero a quatro dependentes e invariância de ordem;
- guarda partilhada e segundo titular em falta falham fechados.

## IRS Jovem

- anos 1 a 10 e fronteira dos 35 anos;
- período fora do regime, dependente, irregularidade e regimes incompatíveis;
- respostas em falta e limite 55 IAS.

Os testes cobrem elegibilidade, não liquidação do benefício.

## Regressão e UI

Continuam cobertos mínimo de existência, dedução específica, solidariedade, limites, deduções isoladas, IVA, serialização e fail-safe. UI/question engine cobrem scope check, regiões 2025, opções conjugais, segundo titular, tipos de rendimento, ausência de “outras deduções” e educação standard.

## Fixtures oficiais

O runner descobre fixtures automaticamente e exige zero cêntimos de diferença por defeito em rendimento coletável, coleta, deduções, imposto, retenções e saldo. Uma exceção de arredondamento é local ao campo e exige nota; não existe tolerância global.
