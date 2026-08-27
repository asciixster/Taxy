# Tax rules — Taxy 0.5

Todos os valores executáveis são carregados de ficheiros versionados. Cêntimos e `ppm` são as únicas unidades do motor.

| Ano | Jurisdição | Versão | Estado |
|---|---|---|---|
| 2025 | Continente | `2025.4.0` | SUPPORTED |
| 2026 | Continente | `2026.4.0` | SUPPORTED |
| 2026 | Madeira | `2026.4.0-M` | SUPPORTED |
| 2026 | Açores | `2026.4.0-A` | SUPPORTED |

`TaxRuleRepository` resolve exclusivamente `year + jurisdiction`, normaliza a jurisdição e recusa schema/status, ano, jurisdição, base ou override incompatível. Não existe fallback regional. A base 2025 é fisicamente independente de 2026, impedindo herança acidental de parâmetros futuros.

## 2025 Continente

- escalões nacionais publicados pela AT para rendimentos de 2025;
- IAS 522,50 € e dedução específica 8,54 IAS = 4.462,15 €;
- mínimo de existência de referência 12.180 €;
- renda standard 15%, limite base 700 € e transição até 1.000 €.

Fontes: [AT — Deduções, benefícios e taxas 2025](https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Cidadaos/Rendimentos/Declaracao/Deducoes_beneficios_taxas/Paginas/default.aspx), [CIRS artigo 68.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs68.aspx) e [artigo 70.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs70.aspx).

## 2026 regiões

Continente usa o artigo 68.º vigente para 2026. Madeira usa a tabela expressa do artigo 18.º do [DLR n.º 8/2025/M](https://diariodarepublica.pt/dr/detalhe/decreto-legislativo-regional/8-2025-993031451), sem derivação aproximada. Açores aplica a redução de 30% às taxas nacionais prevista no artigo 4.º do [DLR n.º 2/99/A consolidado](https://diariodarepublica.pt/dr/legislacao-consolidada/decreto-legislativo-regional/1999-164477580-164477062). As listas fixas de taxas são verificadas nos testes.

## Casados e unidos de facto

Parâmetros JSON:

- `jointDivisor = 2` — CIRS artigo 69.º;
- `separateDependentExpenseSharePpm = 500000` — artigo 78.º, n.º 14;
- `familyLimitDivisor = 2` — limites familiares reduzidos na separada.

Na separada, os rendimentos próprios são liquidados individualmente e 50% dos rendimentos dos dependentes são imputados a cada titular ([artigo 59.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/ra/Pages/irs59.aspx)). As deduções usam despesas próprias mais 50% das despesas dos dependentes e os limites referidos ao agregado são reduzidos para metade ([artigo 78.º, n.º 14](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78.aspx)).

Na conjunta, o quociente é 2 e a coleta é multiplicada por dois ([artigo 69.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs69.aspx)). O adicional de solidariedade também usa metade do rendimento e multiplica o resultado por dois ([artigo 68.º-A, n.º 3](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs68a.aspx)). O mínimo de existência é apurado por titular, aplicando-se o corte conjunto previsto no artigo 70.º.

## Deduções

Mantêm-se base 600 € por dependente, majoração 126 € até 3 anos ou 300 € para segundo e seguintes até 6 anos, sem cumulação.

| Dedução | Taxa | Limite |
|---|---:|---:|
| Gerais | 35% | 250 € por titular |
| Monoparental | 45% | 335 € |
| Saúde | 15% | 1.000 € |
| Educação standard | 30% | 800 € |
| Lares | 25% | 403,75 € |
| PPR | 20% | 400/350/300 € por titular |
| IVA | 15/30/35/100% | global 250 € |

O limite de PPR é sempre apurado por titular segundo a sua idade, inclusive na tributação conjunta; não existe partilha do limite não utilizado. Em 2026, a renda standard usa o limite mínimo de 900 € e os limites transitórios configurados de 750 €/1.050 €, conforme o [artigo 78.º-E](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78e.aspx). Em 2025 permanecem isolados os valores de 700 €/1.000 €.

## IRS Jovem

Idade máxima, dez anos, limite 55 IAS, taxas 100/75/50/25%, opção anual e
englobamento para taxa estão no JSON de cada ano. Em 2025 o limite é 28.737,50
€; em 2026 é 29.542,15 €. O rendimento isento entra sem deduções na
determinação da taxa e a coleta correspondente é retirada proporcionalmente.

Fontes: [artigo 12.º-B](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs12b.aspx), [artigo 22.º](https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs22.aspx), [folheto AT IRS Jovem 2025](https://info.portaldasfinancas.gov.pt/pt/apoio_contribuinte/Folhetos_informativos/Documents/Folheto_IRS_jovem_2025.pdf) e [Newsletter AT janeiro 2026](https://info.portaldasfinancas.gov.pt/pt/at/Divulgacao/publicacoes_internas/Newsletter_AT/Documents/Newsletter-39-janeiro-2026.pdf).

URLs completas residem nos descritores. Alterações exigem versão, data, testes e revisão humana.

A 0.5 não altera valores nem expande o scope fiscal. Formaliza a validação
externa e a sequência de cálculo documentada em
[ROUNDING_POLICY.md](ROUNDING_POLICY.md). A inexistência atual de liquidações AT
anonimizadas permanece explícita em [AT_VALIDATION_REPORT.md](AT_VALIDATION_REPORT.md).
