# Taxy 0.3 — Supported Scope

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
- elegibilidade IRS Jovem para 2025+, sem aplicar a isenção à liquidação.

Na separada, cada titular recebe despesas próprias mais 50% das despesas dos dependentes e os limites referidos ao agregado são reduzidos a metade. O limite de despesas gerais e o PPR permanecem individuais. Na conjunta, as despesas do agregado são somadas, mas o PPR continua limitado pela idade de cada titular; as taxas incidem sobre metade do rendimento coletável e a coleta é multiplicada por dois.

## NOT SUPPORTED / NEEDS_VERIFICATION

- Madeira e Açores em 2025;
- residência parcial ou não residência;
- aplicação da isenção IRS Jovem e comparação com/sem benefício;
- Categoria B, pensões, rendas recebidas, capitais, ações/ETF, cripto, rendimentos estrangeiros e outros;
- guarda partilhada, residência alternada ou percentagem especial de despesas;
- dependentes com rendimentos próprios ou situações especiais;
- deficiência, estudante deslocado e majorações territoriais;
- pensões de alimentos, ascendentes, ex-residentes, RNH/IFICI;
- qualquer módulo ou benefício não explicitamente tipado.

Selecionar rendimento não suportado termina cedo o fluxo. O motor nunca calcula apenas Categoria A ignorando o restante.

## IRS Jovem

O motor de elegibilidade usa idade, qualidade de dependente, histórico anual de rendimentos A/B como sujeito passivo, situação tributária e regimes incompatíveis. Anos sem rendimento e anos como dependente não consomem o período. Devolve `ELIGIBLE`, `NOT_ELIGIBLE` ou `NEEDS_MORE_INFORMATION`, com percentagem e limite 55 IAS. O campo antigo `qualifyingIncomeYears` é apenas compatibilidade transitória; novos casos devem usar `incomeHistory`. A liquidação continua bloqueada até validar englobamento e dedução específica com casos oficiais.
