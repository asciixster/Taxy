# Tax Engine — matriz de testes 0.4

A suite executa mais de 200 testes e compara cêntimos inteiros.

## Escalões

Para 2025 Continente e 2026 Continente/Madeira/Açores, cada limite finito tem testes a −0,01 €, no limite e a +0,01 €. Além dos testes de fórmula, as tabelas 2025, Madeira e Açores são comparadas com listas fixas transcritas das fontes oficiais.

## Agregados

- casado e união de facto;
- rendimento só A, só B, ambos, iguais e muito diferentes;
- conjunta vs. duas liquidações separadas;
- despesas próprias, despesas dos dependentes 50/50 e PPR por titular;
- regressão que impede partilha do limite PPR não utilizado entre titulares;
- zero a quatro dependentes e invariância de ordem;
- guarda partilhada e segundo titular em falta falham fechados.

## IRS Jovem

- anos 1 a 10 e fronteira dos 35 anos;
- período fora do regime, dependente, irregularidade e regimes incompatíveis;
- respostas em falta, histórico sem o ano atual, anos sem rendimento, anos como dependente e limite 55 IAS.

Cobrem também histórico duplicado/interrompido, confirmação do histórico,
Categoria B apenas para contagem, aplicação integral à liquidação, retenções,
saúde, educação, PPR, limite 55 IAS a ±0,01 €, rendimentos altos e mínimo de
existência. Casais cobrem nenhum/A/B/ambos em separada e conjunta.

## Regressão e UI

Continuam cobertos mínimo de existência, dedução específica, solidariedade, limites, deduções isoladas, IVA, serialização e fail-safe. UI/question engine cobrem scope check, regiões 2025, opções conjugais, segundo titular, tipos de rendimento, ausência de “outras deduções” e educação standard.

## Fixtures oficiais

O runner descobre fixtures automaticamente e exige zero cêntimos de diferença por defeito em rendimento coletável, coleta, deduções, rendimento isento, imposto, retenções e saldo. Uma exceção de arredondamento é local ao campo e exige nota; não existe tolerância global.

O loader só aceita `source: OFFICIAL_AT_ASSESSMENT` e rejeita fixtures incompletas. O exemplo não é executado como liquidação real.

## Referências independentes

Além das nove referências conjugais 2026 existentes,
`test/fixtures/reference_calculations/irs_jovem/cases_2025_continent.json`
contém 12 casos ao cêntimo: anos 1/2/5/8, limite 55 IAS, rendimento elevado e
as combinações conjugais A/B/ambos. São referências de revisão, não
liquidações oficiais, e usam `MANUALLY_AUDITED_REFERENCE`.

O repositório de regras também é testado contra ano/base divergente, descriptor não verificado, schema incompatível, override desconhecido, ficheiro ausente e tentativa de carregar regiões 2025 não existentes. Não existe fallback silencioso.
