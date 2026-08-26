# Taxy 0.2 — Supported Scope

O motor segue uma política **fail closed**: só calcula o que está explicitamente
validado. A validação está centralizada em
`lib/tax_engine/supported_scope.dart`.

## SUPPORTED

- ano fiscal 2026, regras `2026.2.0`;
- Continente;
- residência fiscal em Portugal durante todo o ano;
- um único sujeito passivo;
- não casado e não unido de facto;
- Categoria A (trabalho dependente), sem outras categorias;
- tributação do único sujeito passivo;
- agregado sem dependentes; ou agregado com dependentes declarado explicitamente
  como família monoparental standard;
- despesas gerais standard;
- saúde standard;
- educação standard;
- rendas elegíveis de habitação permanente no caso standard;
- lares standard;
- PPR standard;
- IVA por exigência de fatura nas categorias explícitas de 15%, 30%, 35% e 100%.

## NOT SUPPORTED / NEEDS_VERIFICATION

- casados e unidos de facto, em tributação separada ou conjunta;
- tributação conjunta;
- residência parcial;
- Madeira e Açores;
- dependentes sem confirmação de agregado monoparental standard;
- residência alternada/guarda ou responsabilidades parentais partilhadas;
- IRS Jovem;
- Categoria B;
- pensões;
- rendimentos estrangeiros;
- rendimentos de capitais;
- rendimentos prediais;
- mais-valias mobiliárias, imobiliárias ou criptoativos;
- deficiência fiscalmente relevante;
- estudante deslocado;
- majorações territoriais de educação;
- qualquer outra situação especial sem módulo explícito.

Nestes casos o resultado tem `available: false`, valores fiscais a zero, lista de
motivos e o pressuposto de que o cálculo foi bloqueado para evitar um resultado
não validado.

## Decisão sobre famílias monoparentais

O perfil inclui `isSingleParentHousehold`. Quando existem dependentes, a Taxy só
continua se esta condição for afirmada. Aplica então 45% das despesas gerais com
limite de 335 €, conforme o artigo 78.º-B, n.º 9 do CIRS. Uma resposta negativa
ou incerta bloqueia o cálculo; não é convertida no regime standard de 35%/250 €.

## Educação

O input representa exclusivamente educação standard. Estudante deslocado e
majorações territoriais são recusados por flag e recordados nos pressupostos do
resultado.
