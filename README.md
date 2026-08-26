# taxy.pt

MVP Android-first de simulação guiada de IRS português. Os dados ficam no dispositivo e o cálculo é determinístico: nenhuma IA decide valores fiscais.

## Âmbito fiscal validado

- Ano fiscal 2026.
- Residente em Portugal durante todo o ano.
- Continente.
- Um sujeito passivo, tributação separada.
- Rendimentos de trabalho dependente (Categoria A).
- Deduções agregadas introduzidas manualmente.

Madeira, Açores, tributação conjunta, IRS Jovem e residência parcial são recusados explicitamente pelo motor com `NEEDS_VERIFICATION`; não são usados valores inventados.

## Arquitetura

```text
lib/
  core/             feature flags e entitlements
  data/             persistência local tipada
  domain/           modelos tipados e dinheiro exato em cêntimos
  question_engine/  ordem e condições do questionário
  tax_engine/       cálculo determinístico e carregamento de regras
  main.dart         UI Material 3 e composição da aplicação
assets/tax_rules/   parâmetros fiscais versionados por ano
test/               limites, regressões, questionário e arranque da UI
```

O `TaxEngine` recebe `TaxSimulation` e devolve `TaxResult`, incluindo rendimento coletável, coleta, deduções, retenções, saldo, explicações, avisos e pressupostos. A UI não contém fórmulas fiscais.

## Funcionalidades do produto

- Questionário conversacional com perguntas condicionais.
- Dashboard, histórico e detalhe explicável do cálculo.
- Laboratório de cenários para PPR, saúde, educação, rendas e despesas gerais.
- Cenários recalculados pelo mesmo motor e guardáveis como novas simulações.
- Oportunidades fiscais determinísticas através de simulações contrafactuais.
- Renomear, duplicar, editar e apagar simulações no dispositivo.

## Stack

- Flutter / Dart e Material 3.
- Riverpod para composição e estado assíncrono.
- JSON local com escrita atómica no diretório privado da aplicação Android.
- Valores monetários como cêntimos inteiros (`Money`); taxas em partes por milhão, com arredondamento half-up explícito.
- Sem backend, login, analytics ou serviços externos.

## Executar

```powershell
flutter pub get
flutter run
```

## Verificar e testar

```powershell
flutter analyze
flutter test
```

A suite contém mais de 15 cenários, fronteiras antes/depois de escalões, zero, rendimentos elevados, dependentes, limites de deduções, PPR, mínimo de existência, serialização e fluxo condicional.

## Gerar Android

APK instalável para testes:

```powershell
flutter build apk --release
```

Bundle para a Play Store (depois de configurar uma chave de assinatura de produção):

```powershell
flutter build appbundle --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`. Para publicação é ainda necessário trocar a assinatura de desenvolvimento por uma chave privada de produção, preencher a ficha da Play Store, política de privacidade e cumprir o processo de testes aplicável à conta.

Nota Android: este MVP não usa plugins Android auto-registados; o acesso ao diretório privado é feito por um `MethodChannel` em `MainActivity.kt`. Por isso, a compilação do registrant Java vazio está desativada. Ao acrescentar futuramente um plugin Android, remover esse bloco no fim de `android/app/build.gradle.kts`.

## Regras fiscais e novo ano

As regras estão em `assets/tax_rules/2026.json`, validadas ao carregar. Para adicionar 2027:

1. Copiar o ficheiro para `assets/tax_rules/2027.json`.
2. Atualizar apenas valores confirmados e respetivas fontes.
3. Alterar `taxYear`, `rulesVersion`, `verifiedAt` e estado.
4. Registar o asset no `pubspec.yaml`.
5. Acrescentar fixtures de fronteira e regressão.
6. Só disponibilizar o ano na UI depois de todos os testes passarem.

Ver [TAX_RULES.md](TAX_RULES.md) e [TAX_ENGINE_TEST_CASES.md](TAX_ENGINE_TEST_CASES.md).

## Privacidade e limitações

As simulações são guardadas apenas no armazenamento privado da app e são eliminadas ao remover a aplicação. O repositório está isolado, permitindo migrar para SQLite/Drift sem alterar UI ou motor. O resultado é uma estimativa baseada nos dados introduzidos e nas regras configuradas; não substitui a liquidação oficial da Autoridade Tributária nem constitui aconselhamento fiscal.
