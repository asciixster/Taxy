# Taxy 0.3 — Supported Scope

O scope check ocorre antes do questionário completo. A validação executável está em `lib/tax_engine/supported_scope.dart`.

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

Na separada, cada titular recebe despesas próprias mais 50% das despesas dos dependentes e limites familiares reduzidos a metade. Na conjunta, as despesas do agregado são somadas e as taxas incidem sobre metade do rendimento coletável, multiplicando-se a coleta por dois.

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

O motor usa idade, qualidade de dependente, anos de rendimentos A/B como sujeito passivo, situação tributária e regimes incompatíveis. Devolve `ELIGIBLE`, `NOT_ELIGIBLE` ou `NEEDS_MORE_INFORMATION`, com percentagem e limite 55 IAS. A liquidação continua bloqueada até validar englobamento e dedução específica com casos oficiais.
