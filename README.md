# taxy.pt — 0.2 Fiscal Hardening

Simulador Android-first de IRS português. A Taxy transforma um conjunto
estritamente limitado de dados fiscais num cálculo determinístico e explicado.
Não submete declarações, não acede ao Portal das Finanças e mantém as simulações
no dispositivo.

> Esta é uma simulação. Não substitui a liquidação oficial da Autoridade
> Tributária nem aconselhamento fiscal profissional.

## Âmbito da release 0.2

A Taxy calcula apenas um sujeito passivo não casado e não unido de facto,
residente fiscal durante todo o ano no Continente, com rendimentos exclusivos de
Categoria A e situações standard. Com dependentes, exige confirmação explícita
de agregado monoparental standard. Consulte [SUPPORTED_SCOPE.md](SUPPORTED_SCOPE.md).

Qualquer cenário fora deste contrato devolve `available: false`. Não existem
aproximações silenciosas.

## Arquitetura

- `lib/domain/`: modelos tipados, serialização e `Money` em cêntimos inteiros.
- `lib/tax_engine/`: motor determinístico, regras e validação central de scope.
- `lib/question_engine/`: fluxo condicional independente da UI.
- `lib/state/`: providers Riverpod.
- `lib/navigation/`: navegação partilhada.
- `lib/screens/`: ecrãs extraídos e Tax Validation Lab.
- `lib/widgets/`: componentes reutilizáveis.
- `lib/data/`: persistência JSON atómica no diretório privado Android.
- `assets/tax_rules/2026.json`: única fonte de parâmetros fiscais.

O `TaxEngine` não contém valores fiscais novos hardcoded. As regras 2026 usam
versão `2026.2.0`, data de validação e metadados de fonte/unidade/comentário.

## Executar

Pré-requisitos: Flutter stable compatível com Dart `^3.13.1`.

```text
flutter pub get
flutter run
```

## Verificar

```text
flutter analyze
flutter test
```

A CI executa exatamente estes dois controlos em cada push e Pull Request. Não
gera APK nem AAB.

## Tax Validation Lab

Em modo debug, abra `Como calculamos` e escolha `Abrir Tax Validation Lab`. O
laboratório permite introduzir todos os inputs suportados e auditar rendimento,
dedução específica, mínimo de existência, escalão, coleta, cada dedução, limites,
solidariedade, retenção e saldo em euros/cêntimos. A entrada é protegida por
`kDebugMode` e não aparece numa build normal de produção.

## Regras e novo ano fiscal

1. Copiar `assets/tax_rules/2026.json` para o novo ano.
2. Atualizar todos os valores apenas com fonte oficial.
3. Atualizar `taxYear`, `rulesVersion`, `verifiedAt`, metadados e scope.
4. Fazer o parser rejeitar schemas incompletos.
5. Criar testes de fronteira e regressão antes de disponibilizar o ano na UI.

Valores não confirmados devem permanecer fora do scope com
`NEEDS_VERIFICATION`; nunca devem ser estimados.

## Fixtures oficiais futuras

`test/fixtures/official_assessments/` contém o esquema e o processo para receber
liquidações reais anonimizadas. Não existem liquidações oficiais fictícias.

## Distribuição

Esta tarefa deliberadamente não gera APK/AAB. Os comandos de distribuição ficam
fora do procedimento de hardening fiscal 0.2.
