# Tax rules — Taxy 0.3

Todos os valores executáveis são carregados de ficheiros versionados. Cêntimos e `ppm` são as únicas unidades do motor.

| Ano | Jurisdição | Versão | Estado |
|---|---|---|---|
| 2025 | Continente | `2025.3.0` | SUPPORTED |
| 2026 | Continente | `2026.3.0` | SUPPORTED |
| 2026 | Madeira | `2026.3.0-M` | SUPPORTED |
| 2026 | Açores | `2026.3.0-A` | SUPPORTED |

`TaxRuleRepository` resolve `year + jurisdiction`. Os descritores schema v3 aplicam overrides declarativos sobre a base validada.

## 2025 Continente

- escalões do artigo 68.º após Lei n.º 55-A/2025;
- IAS 522,50 € e dedução específica 8,54 IAS = 4.462,15 €;
- mínimo de existência de referência 12.180 €;
- renda standard 15%, limite base 700 € e transição até 1.000 €.

Fonte: AT, folheto “IRS — Deduções, benefícios fiscais e taxas para rendimentos do ano de 2025” e artigo 68.º em vigor até dezembro de 2025.

## 2026 regiões

Continente usa o artigo 68.º na redação da Lei n.º 73-A/2025. Madeira usa a tabela do artigo 18.º do DLR n.º 8/2025/M. Açores aplica redução de 30% às taxas nacionais pelo artigo 4.º do DLR n.º 2/99/A, redação do DLR n.º 15-A/2021/A.

## Casados e unidos de facto

Parâmetros JSON:

- `jointDivisor = 2` — CIRS artigo 69.º;
- `separateDependentExpenseSharePpm = 500000` — artigo 78.º, n.º 14;
- `familyLimitDivisor = 2` — limites familiares reduzidos na separada.

O adicional de solidariedade conjunto também usa metade do rendimento e multiplica o resultado por dois (artigo 68.º-A, n.º 3). O mínimo de existência considera os dois titulares.

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

## IRS Jovem

Idade máxima, dez anos, limite 55 IAS e taxas 100/75/50/25% estão no JSON. Fontes: artigo 12.º-B e folheto oficial IRS Jovem 2025. O motor atual determina elegibilidade; não liquida o benefício.

URLs completas residem nos descritores. Alterações exigem versão, data, testes e revisão humana.
