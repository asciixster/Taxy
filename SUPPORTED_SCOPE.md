# Taxy 0.8 — Supported Scope

O scope check ocorre antes do questionário completo. O contrato declarativo está no `supportedScope` da base fiscal de cada ano; `lib/tax_engine/supported_scope.dart` aplica esse contrato e as exclusões especiais fail-closed.

## SUPPORTED

- residência fiscal em Portugal durante todo o ano;
- Categoria A exclusiva;
- 2025: Continente;
- 2026: Continente, Madeira e Açores;
- titular individual ou família monoparental standard confirmada;
- casado ou unido de facto com dois titulares completos;
- tributação separada e conjunta standard, com comparação;
- dependentes sem guarda partilhada, residência alternada ou alocação especial;
- despesas gerais, saúde, educação standard, rendas, lares, PPR e IVA explícito a 15%, 30%, 35% e 100%;
- IRS Jovem 2025/2026 para Categoria A, com histórico anual completo,
  situação tributária regularizada e ausência de regimes incompatíveis;
- comparação normal/Jovem individual e, nos agregados standard, titular A,
  titular B, ambos ou nenhum em separada e conjunta.

Na separada, cada titular recebe despesas próprias mais 50% das despesas dos dependentes e os limites referidos ao agregado são reduzidos a metade. O limite de despesas gerais e o PPR permanecem individuais. Na conjunta, as despesas do agregado são somadas, mas o PPR continua limitado pela idade de cada titular; as taxas incidem sobre metade do rendimento coletável e a coleta é multiplicada por dois.

## NOT SUPPORTED / NEEDS_VERIFICATION

- Madeira e Açores em 2025;
- residência parcial ou não residência;
- IRS Jovem com histórico incompleto/contraditório ou casos transitórios que
  não possam ser determinados objetivamente;
- IRS Jovem com rendimentos A/B em anos anteriores de não residência;
- componente de rendimento Categoria B (pode contar para a elegibilidade, mas
  a sua liquidação permanece fora do âmbito);
- Categoria B, pensões, rendas recebidas, capitais, ações/ETF, cripto, rendimentos estrangeiros e outros;
- guarda partilhada, residência alternada ou percentagem especial de despesas;
- dependentes com rendimentos próprios ou situações especiais;
- deficiência, estudante deslocado e majorações territoriais;
- pensões de alimentos, ascendentes, ex-residentes, RNH/IFICI;
- qualquer módulo ou benefício não explicitamente tipado.

Selecionar rendimento não suportado termina cedo o fluxo. O motor nunca calcula apenas Categoria A ignorando o restante.

## IRS Jovem

O motor de elegibilidade usa idade em 31 de dezembro, qualidade de dependente,
histórico anual completo de rendimentos A/B, residência, situação tributária e
regimes incompatíveis. Anos sem A/B e anos como dependente não consomem o
período. `qualifyingIncomeYears` existe apenas para migração de dados 0.3; a UX
0.4 recolhe `incomeHistory`. A liquidação aplica a isenção apenas a Categoria A
e usa o artigo 22.º para a taxa. Ver [IRS_JOVEM.md](IRS_JOVEM.md).

## Evidência externa

O âmbito fiscal é igual ao da 0.7; a 0.8 não adiciona regras. Existem atualmente
**1 liquidação oficial AT anonimizada** e **29 cálculos de referência manual**.
Isto não equivale a validação oficial nem autoriza promessas de precisão. Ver
[AT_VALIDATION.md](AT_VALIDATION.md) e
[VALIDATION_COVERAGE_MATRIX.md](VALIDATION_COVERAGE_MATRIX.md).
