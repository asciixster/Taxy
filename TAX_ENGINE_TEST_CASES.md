# Tax Engine — matriz de testes 0.8

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

## Fixtures oficiais e validação 0.5

O runner descobre fixtures automaticamente e exige zero cêntimos de diferença
em todos os campos presentes. Rendimento coletável, coleta, deduções, imposto,
retenções e saldo são obrigatórios. Não existem tolerâncias globais ou locais.

Testes adicionais cobrem:

- schema v3, trace tipado e metadados coerentes com os inputs;
- independência total entre o runner e os labels do breakdown;
- casos de trace individual, IRS Jovem, casal separado, conjunto e conjunto
  com IRS Jovem;
- fonte/documento oficial e identificador anónimo;
- rejeição recursiva de NIF, IBAN, email, telefone, morada e identificadores;
- ausência de mutação/anonimização automática;
- diferença de 0,01 € como falha `UNKNOWN` até triagem humana;
- versões de regras incompatíveis e outputs obrigatórios em falta;
- contagens absolutas e relatório vazio sem alegações de precisão;
- gravação, recuperação e eliminação de rascunhos;
- home com retoma, ecrã compacto/dark mode e Validation Lab AT.

O loader só aceita `source: OFFICIAL_AT_ASSESSMENT` e tipos de documento AT
documentados. O exemplo não é executado como liquidação real. Nesta release:
**1 fixture oficial**, **29 referências manuais**.

## Referências independentes

Além das nove referências conjugais 2026 existentes,
`test/fixtures/reference_calculations/irs_jovem/cases_2025_continent.json`
contém 12 casos ao cêntimo: anos 1/2/5/8, limite 55 IAS, rendimento elevado e
as combinações conjugais A/B/ambos. São referências de revisão, não
liquidações oficiais, e usam `MANUALLY_AUDITED_REFERENCE`.

O caso `single-category-a-positive-tax-2025-001` acrescenta uma referência
manual individual com coleta positiva. Audita separadamente o 5.º escalão de
2025, o arredondamento por parcela, despesas gerais, saúde, imposto final,
retenções e saldo. Não aumenta a cobertura oficial AT.

A 0.8 acrescenta sete referências 2025 Continente: coleta positiva sem
créditos, deduções gerais/saúde/rendas com limite global, o mesmo agregado em
separada e conjunta, limites PPR individuais, mínimo de existência e IRS Jovem
no quinto ano com coleta positiva. Todas têm expected fixo, audit trail e
provenance por input; a comparação é ao cêntimo.

Um grupo adicional cobre as oito fronteiras finitas dos escalões 2025 a −1/0/+1
cêntimo, zero e um cêntimo de rendimento coletável, crédito no cap e cap+1,
coleta igual e um cêntimo inferior aos créditos, quociente conjunto ímpar,
half-up e regressões fail-closed.

O repositório de regras também é testado contra ano/base divergente, descriptor não verificado, schema incompatível, override desconhecido, ficheiro ausente e tentativa de carregar regiões 2025 não existentes. Não existe fallback silencioso.
