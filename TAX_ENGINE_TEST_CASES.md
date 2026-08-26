# Tax Engine — matriz de testes 0.2

A fonte executável está em `test/`. A suite contém mais de 50 casos fiscais
determinísticos e compara sempre cêntimos inteiros.

## Escalões — 26 casos

Para cada um dos oito limites finitos do JSON existem três casos:

| Input de rendimento coletável | Output esperado |
|---|---|
| limite − 0,01 € | coleta pela taxa marginal do escalão corrente |
| limite exato | coleta exata obtida pela taxa média configurada |
| limite + 0,01 € | coleta base + excesso de 0,01 € à taxa do escalão seguinte |

Acrescem rendimento zero → coleta zero e 500.000 € → último escalão. Os outputs
esperados são calculados no teste por uma implementação de referência separada,
usando apenas os parâmetros do JSON.

## Mínimo de existência — 11 casos

| Input | Output esperado |
|---|---|
| 0 € | rendimento coletável e imposto zero |
| referência − 0,01 € | fase 1, abatimento exato |
| referência | fase 1, abatimento exato |
| referência + 0,01 € | início da fase 2 |
| L − 0,01 € | fim da fase 2 |
| L | fronteira exata |
| L + 0,01 € | início da fase 3 |
| limite final | última aplicação do mecanismo |
| limite final + 0,01 € | abatimento zero |
| contribuições > dedução fixa | contribuições usadas como dedução específica |
| rendimento < dedução fixa | dedução limitada ao rendimento |

## Deduções — casos isolados e combinados

| Input isolado | Output esperado |
|---|---:|
| Gerais standard, 1.000 € | 250 € |
| Gerais monoparental, 1.000 € | 335 € |
| Saúde, 10.000 € | 1.000 € |
| Educação standard, 4.000 € | 800 € |
| Lares, 2.000 € | 403,75 € |
| Rendas, 10.000 € em rendimento alto | 900 € |
| PPR 2.000 €, idade 30 | 400 € |
| PPR 2.000 €, idade 40 | 350 € |
| PPR 2.000 €, idade 60 | 300 € |
| IVA 15%, IVA suportado 100 € | 15 € |
| IVA 30%, IVA suportado 100 € | 30 € |
| IVA 35%, IVA suportado 100 € | 35 € |
| IVA 100%, IVA suportado 100 € | 100 € |
| quatro IVA de 1.000 € cada | 250 € após limite global |

Há ainda combinação de saúde, educação, rendas, lares e PPR acima do limite
global, com output ajustado ao cap e linha de auditoria específica.

## Dependentes — 5 casos

- `[10, 2]` e `[2, 10]` → coleta, créditos e imposto idênticos;
- `[12, 5, 2]` e `[2, 12, 5]` → idênticos;
- quatro dependentes em ordem normal/inversa → idênticos;
- dependente único com 2 anos → 726 €;
- dependentes `[10, 5]` → 1.500 €.

## Limite global — 8 casos

- limite do primeiro escalão;
- 0,01 € acima;
- 20.000 €;
- 50.000 €;
- 79.999,99 €;
- 80.000 €;
- 50.000 € com três dependentes → majoração de 15%;
- combinação de deduções acima do cap → warning e ajuste no breakdown.

## Solidariedade — 7 casos

| Rendimento coletável | Adicional esperado |
|---:|---:|
| 79.999,99 € | 0,00 € |
| 80.000,00 € | 0,00 € |
| 80.000,01 € | 0,00 € após arredondamento ao cêntimo |
| 249.999,99 € | 4.250,00 € |
| 250.000,00 € | 4.250,00 € |
| 250.000,01 € | 4.250,00 € após arredondamento |
| 250.000,20 € | 4.250,01 € |

## Fail-safe — 21 casos

Cada cenário espera `available: false`, sem breakdown fiscal nem saldo:
casado, unido de facto, tributação conjunta, residência parcial, Madeira,
Açores, dependentes sem confirmação monoparental, flag monoparental inválida,
IRS Jovem, Categoria B, pensões, estrangeiro, capitais, prediais, mais-valias,
deficiência, estudante deslocado, guarda partilhada, outra situação especial e
valores negativos. O caso standard é o controlo positivo.

## Question engine e UI

Os testes confirmam ausência de modo de tributação e “outras deduções”, pergunta
monoparental condicional, quatro IVA, aviso de educação standard, remoção visual
de casado/união de facto e bloqueio pré-cálculo de residência parcial, Madeira e
Açores.

## Fixtures oficiais

`test/fixtures/official_assessments/` contém apenas infraestrutura. Nenhuma
liquidação oficial foi inventada.
