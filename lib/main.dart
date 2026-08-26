import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/simulation_repository.dart';
import 'domain/models.dart';
import 'domain/money.dart';
import 'question_engine/question_engine.dart';
import 'tax_engine/tax_engine.dart';
import 'tax_engine/tax_rules.dart';

final repositoryProvider = Provider<SimulationRepository>((ref) => LocalSimulationRepository());
final rulesProvider = FutureProvider<TaxRuleSet>((ref) async {
  final source = await rootBundle.loadString('assets/tax_rules/2026.json');
  return TaxRuleSet.fromJsonString(source);
});
final simulationsProvider = FutureProvider<List<TaxSimulation>>(
  (ref) => ref.watch(repositoryProvider).list(),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TaxyApp()));
}

final class TaxyApp extends StatelessWidget {
  const TaxyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'taxy.pt',
    themeMode: ThemeMode.system,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const HomeScreen(),
  );

  ThemeData _theme(Brightness brightness) {
    const seed = Color(0xFF5B5CE2);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F7FB)
          : const Color(0xFF101014),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.2),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final simulations = ref.watch(simulationsProvider);
    return Scaffold(
      body: SafeArea(
        child: rules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _FatalError(message: 'Não foi possível validar as regras fiscais: $error'),
          data: (ruleSet) => simulations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _FatalError(message: 'Não foi possível abrir as simulações: $error'),
            data: (items) => items.isEmpty
                ? _Welcome(rules: ruleSet)
                : _Dashboard(rules: ruleSet, simulations: items),
          ),
        ),
      ),
    );
  }
}

final class _Welcome extends StatelessWidget {
  const _Welcome({required this.rules});
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Brand(),
        const Spacer(),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary, size: 34),
        ),
        const SizedBox(height: 28),
        Text('Percebe o teu IRS\nsem falar fiscalês.',
          style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 18),
        Text(
          'Responde a perguntas simples e recebe uma estimativa explicada passo a passo. Os dados ficam neste dispositivo.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const Spacer(),
        _TrustRow(icon: Icons.verified_outlined, text: 'Regras do Continente ${rules.taxYear} verificadas'),
        const SizedBox(height: 10),
        const _TrustRow(icon: Icons.lock_outline_rounded, text: 'Sem conta e sem envio de dados'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _openWizard(context, rules),
          child: const Text('Começar simulação'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => HowWeCalculateScreen(rules: rules))),
          child: const Text('Como calculamos'),
        ),
      ],
    ),
  );
}

final class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.rules, required this.simulations});
  final TaxRuleSet rules;
  final List<TaxSimulation> simulations;

  @override
  Widget build(BuildContext context) {
    final latest = simulations.first;
    final result = TaxEngine(rules).calculate(latest);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              const Expanded(child: _Brand()),
              IconButton(
                tooltip: 'Como calculamos',
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => HowWeCalculateScreen(rules: rules))),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Olá', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              _ResultHero(result: result, year: latest.profile.taxYear,
                onTap: () => _openResult(context, latest, rules)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _openWizard(context, rules, source: latest),
                  icon: const Icon(Icons.edit_outlined), label: const Text('Alterar dados'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: result.available
                      ? () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CompareScreen(simulation: latest, rules: rules)))
                      : null,
                  icon: const Icon(Icons.compare_arrows_rounded), label: const Text('Comparar'))),
              ]),
              const SizedBox(height: 30),
              Row(children: [
                Expanded(child: Text('Simulações', style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: () => _openWizard(context, rules),
                  icon: const Icon(Icons.add_rounded), label: const Text('Nova')),
              ]),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverList.separated(
            itemCount: simulations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = simulations[index];
              final itemResult = TaxEngine(rules).calculate(item);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: CircleAvatar(child: Text('${item.profile.taxYear % 100}')),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(itemResult.available
                      ? (itemResult.isRefund ? 'Reembolso ${itemResult.balance.format()}'
                          : 'A pagar ${(-itemResult.balance).format()}')
                      : 'Cálculo indisponível'),
                  trailing: IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _openWizard(context, rules, source: item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  onTap: () => _openResult(context, item, rules),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> _openWizard(BuildContext context, TaxRuleSet rules, {TaxSimulation? source}) async {
  await Navigator.push(context, MaterialPageRoute(
    builder: (_) => WizardScreen(rules: rules, source: source)));
}

void _openResult(BuildContext context, TaxSimulation simulation, TaxRuleSet rules) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => ResultScreen(simulation: simulation, rules: rules)));
}

final class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key, required this.rules, this.source});
  final TaxRuleSet rules;
  final TaxSimulation? source;

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

final class _WizardScreenState extends ConsumerState<WizardScreen> {
  late final TaxDraft draft = TaxDraft(source: widget.source);
  final engine = const QuestionEngine();
  int index = 0;
  String? error;

  List<QuestionStep> get steps => engine.steps(draft);
  QuestionStep get step => steps[index.clamp(0, steps.length - 1)];

  @override
  Widget build(BuildContext context) {
    final current = step;
    final progress = (index + 1) / steps.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: index == 0 ? () => Navigator.pop(context) : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(_sectionLabel(current.section), style: const TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(children: [
          LinearProgressIndicator(value: progress, minHeight: 4),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(current.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(current.helper, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(key: ValueKey(current.id), child: _question(current.id)),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600)),
              ],
            ]),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: FilledButton(
              onPressed: current.id == 'review' ? _calculate : _next,
              child: Text(current.id == 'review' ? 'Calcular estimativa' : 'Continuar'),
            ),
          ),
        ]),
      ),
    );
  }

  String _sectionLabel(QuestionSection section) => switch (section) {
    QuestionSection.profile => 'Perfil',
    QuestionSection.income => 'Rendimentos',
    QuestionSection.deductions => 'Despesas',
    QuestionSection.review => 'Revisão',
  };

  Widget _question(String id) => switch (id) {
    'taxYear' => _ChoiceGroup<int>(value: draft.taxYear,
      options: const [(2026, '2026', 'Regras validadas para o MVP')],
      onChanged: (v) => setState(() => draft.taxYear = v)),
    'age' => _NumberPicker(value: draft.age, min: 18, max: 99,
      onChanged: (v) => setState(() => draft.age = v)),
    'civilStatus' => _ChoiceGroup<CivilStatus>(value: draft.civilStatus,
      options: const [
        (CivilStatus.single, 'Solteiro/a', 'Uma pessoa titular'),
        (CivilStatus.married, 'Casado/a', 'Agregado com dois titulares'),
        (CivilStatus.deFacto, 'União de facto', 'Agregado com dois titulares'),
      ], onChanged: (v) => setState(() {
        draft.civilStatus = v;
        if (v == CivilStatus.single) draft.filingMode = FilingMode.separate;
      })),
    'filingMode' => _ChoiceGroup<FilingMode>(value: draft.filingMode,
      options: const [
        (FilingMode.separate, 'Separada', 'Disponível: simula apenas este titular'),
        (FilingMode.joint, 'Conjunta', 'Em validação — o cálculo será bloqueado'),
      ], onChanged: (v) => setState(() => draft.filingMode = v)),
    'residency' => _ChoiceGroup<bool>(value: draft.fullYearResident,
      options: const [(true, 'Sim', 'Residente todo o ano'),
        (false, 'Não', 'Exige regras adicionais ainda em validação')],
      onChanged: (v) => setState(() => draft.fullYearResident = v)),
    'region' => _ChoiceGroup<TaxRegion>(value: draft.region,
      options: const [
        (TaxRegion.continent, 'Continente', 'Cálculo disponível'),
        (TaxRegion.madeira, 'Madeira', 'Tabelas em validação'),
        (TaxRegion.azores, 'Açores', 'Tabelas em validação'),
      ], onChanged: (v) => setState(() => draft.region = v)),
    'dependents' => _NumberPicker(value: draft.dependentAges.length, min: 0, max: 8,
      onChanged: (v) => setState(() {
        while (draft.dependentAges.length < v) {
          draft.dependentAges.add(5);
        }
        while (draft.dependentAges.length > v) {
          draft.dependentAges.removeLast();
        }
      })),
    'dependentAges' => Column(children: [
      for (var i = 0; i < draft.dependentAges.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(child: Text('Dependente ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
            SizedBox(width: 150, child: DropdownButtonFormField<int>(
              initialValue: draft.dependentAges[i],
              decoration: const InputDecoration(suffixText: 'anos'),
              items: [for (var age = 0; age <= 25; age++)
                DropdownMenuItem(value: age, child: Text('$age'))],
              onChanged: (v) => setState(() => draft.dependentAges[i] = v ?? 0),
            )),
          ]),
        ),
    ]),
    'incomeMode' => _ChoiceGroup<IncomeEntryMode>(value: draft.incomeEntryMode,
      options: const [
        (IncomeEntryMode.annual, 'Total anual', 'Um único valor do ano'),
        (IncomeEntryMode.monthly, 'Mensal × meses', 'A app calcula o total anual'),
      ], onChanged: (v) => setState(() => draft.incomeEntryMode = v)),
    'gross' => Column(children: [
      _MoneyField(value: draft.incomeEntryMode == IncomeEntryMode.annual ? draft.gross : draft.monthly,
        label: draft.incomeEntryMode == IncomeEntryMode.annual ? 'Rendimento anual' : 'Rendimento mensal',
        onChanged: (v) => draft.incomeEntryMode == IncomeEntryMode.annual ? draft.gross = v : draft.monthly = v),
      if (draft.incomeEntryMode == IncomeEntryMode.monthly) ...[
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: draft.months,
          decoration: const InputDecoration(labelText: 'Número de pagamentos'),
          items: [for (var n = 1; n <= 14; n++) DropdownMenuItem(value: n, child: Text('$n meses'))],
          onChanged: (v) => setState(() => draft.months = v ?? 14),
        ),
      ],
    ]),
    'withholding' => _MoneyField(value: draft.withholding, label: 'Retenção anual de IRS',
      onChanged: (v) => draft.withholding = v),
    'socialSecurity' => _MoneyField(value: draft.socialSecurity, label: 'Contribuições anuais',
      onChanged: (v) => draft.socialSecurity = v),
    'general' => _MoneyField(value: draft.general, label: 'Total de despesas gerais',
      hint: 'Ex.: 1.200,00', onChanged: (v) => draft.general = v),
    'health' => _MoneyField(value: draft.health, label: 'Total de saúde', onChanged: (v) => draft.health = v),
    'education' => _MoneyField(value: draft.education, label: 'Total de educação', onChanged: (v) => draft.education = v),
    'rent' => _MoneyField(value: draft.rent, label: 'Rendas anuais', onChanged: (v) => draft.rent = v),
    'careHomes' => _MoneyField(value: draft.careHomes, label: 'Encargos anuais', onChanged: (v) => draft.careHomes = v),
    'invoiceVat' => _MoneyField(value: draft.invoiceVat, label: 'IVA elegível', onChanged: (v) => draft.invoiceVat = v),
    'ppr' => _MoneyField(value: draft.ppr, label: 'Aplicações anuais em PPR', onChanged: (v) => draft.ppr = v),
    'other' => _MoneyField(value: draft.other, label: 'Crédito fiscal elegível', onChanged: (v) => draft.other = v),
    'review' => _ReviewCard(draft: draft),
    _ => const SizedBox.shrink(),
  };

  void _back() => setState(() {
    error = null;
    index = (index - 1).clamp(0, steps.length - 1);
  });

  void _next() {
    final validation = _validate(step.id);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    setState(() {
      error = null;
      index = (index + 1).clamp(0, steps.length - 1);
    });
  }

  String? _validate(String id) {
    if (id == 'gross') {
      final value = draft.incomeEntryMode == IncomeEntryMode.annual ? draft.gross : draft.monthly;
      if (_money(value).cents <= 0) return 'Indica um rendimento superior a zero.';
    }
    return null;
  }

  Money _money(String raw) {
    try { return Money.parseEuros(raw); } on FormatException { return Money.zero; }
  }

  Future<void> _calculate() async {
    final now = DateTime.now();
    final gross = draft.incomeEntryMode == IncomeEntryMode.annual
        ? _money(draft.gross)
        : Money.fromCents(_money(draft.monthly).cents * draft.months);
    final simulation = TaxSimulation(
      id: widget.source?.id ?? now.microsecondsSinceEpoch.toString(),
      name: widget.source?.name ?? 'IRS ${draft.taxYear}',
      createdAt: widget.source?.createdAt ?? now,
      updatedAt: now,
      profile: TaxpayerProfile(
        taxYear: draft.taxYear,
        age: draft.age,
        civilStatus: draft.civilStatus,
        dependentAges: [...draft.dependentAges],
        fullYearResident: draft.fullYearResident,
        region: draft.region,
        filingMode: draft.filingMode,
      ),
      income: EmploymentIncome(
        entryMode: draft.incomeEntryMode,
        gross: gross,
        withholding: _money(draft.withholding),
        socialSecurity: _money(draft.socialSecurity),
        monthlyAmount: _money(draft.monthly),
        months: draft.months,
      ),
      deductions: DeductionInput(
        general: _money(draft.general), health: _money(draft.health),
        education: _money(draft.education), rent: _money(draft.rent),
        careHomes: _money(draft.careHomes), eligibleInvoiceVat: _money(draft.invoiceVat),
        ppr: _money(draft.ppr), otherEligibleTaxCredit: _money(draft.other),
      ),
    );
    await ref.read(repositoryProvider).save(simulation);
    ref.invalidate(simulationsProvider);
    if (!mounted) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ResultScreen(simulation: simulation, rules: widget.rules)));
  }
}

final class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.simulation, required this.rules});
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) {
    final result = TaxEngine(rules).calculate(simulation);
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado estimado')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 14, 24, 36), children: [
        _ResultHero(result: result, year: simulation.profile.taxYear),
        const SizedBox(height: 16),
        if (result.available) ...[
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CompareScreen(simulation: simulation, rules: rules))),
            icon: const Icon(Icons.compare_arrows_rounded),
            label: const Text('Comparar cenário'),
          ),
          const SizedBox(height: 28),
          Text('Como chegámos aqui', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(child: Column(children: [
            for (var i = 0; i < result.breakdown.length; i++) ...[
              ExpansionTile(
                shape: const Border(), collapsedShape: const Border(),
                title: Text(result.breakdown[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(result.breakdown[i].amount.format(signed: true),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [Align(alignment: Alignment.centerLeft,
                  child: Text(result.breakdown[i].explanation,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)))],
              ),
              if (i < result.breakdown.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ])),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Notice(title: result.available ? 'Atenção aos limites' : 'Cálculo não disponível',
            messages: result.warnings, icon: Icons.warning_amber_rounded),
        ],
        const SizedBox(height: 20),
        _Notice(title: 'Pressupostos da simulação', messages: result.assumptions,
          icon: Icons.fact_check_outlined),
        const SizedBox(height: 20),
        Text('Esta é uma simulação baseada nos dados introduzidos e nas regras fiscais configuradas para o ano selecionado. Não substitui a liquidação oficial da Autoridade Tributária.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

final class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.simulation, required this.rules});
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

final class _CompareScreenState extends State<CompareScreen> {
  late int pprCents = widget.simulation.deductions.ppr.cents;

  @override
  Widget build(BuildContext context) {
    final engine = TaxEngine(widget.rules);
    final original = engine.calculate(widget.simulation);
    final changedSimulation = widget.simulation.copyWith(
      deductions: widget.simulation.deductions.copyWith(ppr: Money.fromCents(pprCents)));
    final changed = engine.calculate(changedSimulation);
    final difference = changed.balance - original.balance;
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar cenário')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
        Text('E se alterares o PPR?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('O mesmo motor fiscal recalcula apenas a variável escolhida.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Text(Money.fromCents(pprCents).format(),
          style: Theme.of(context).textTheme.displaySmall),
        Slider(
          value: pprCents.toDouble(), min: 0, max: 500000, divisions: 50,
          label: Money.fromCents(pprCents).format(),
          onChanged: (v) => setState(() => pprCents = (v ~/ 10000) * 10000),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _ScenarioCard(label: 'Cenário A', ppr: widget.simulation.deductions.ppr,
            result: original)),
          const SizedBox(width: 12),
          Expanded(child: _ScenarioCard(label: 'Cenário B', ppr: Money.fromCents(pprCents),
            result: changed)),
        ]),
        const SizedBox(height: 14),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Expanded(child: Text('Diferença no resultado', style: TextStyle(fontWeight: FontWeight.w700))),
              Text(difference.format(signed: true), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Text('A vantagem fiscal de um PPR está sujeita a condições de elegibilidade e manutenção. Esta comparação não avalia custos, risco ou rentabilidade do produto.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45)),
      ]),
    );
  }
}

final class HowWeCalculateScreen extends StatelessWidget {
  const HowWeCalculateScreen({super.key, required this.rules});
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Como calculamos')),
    body: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 36), children: [
      Text('Transparência primeiro', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('O cálculo é determinístico e não usa inteligência artificial. Valores monetários são tratados em cêntimos inteiros, com arredondamento explícito.'),
      const SizedBox(height: 24),
      const _MethodStep(number: '1', title: 'Rendimento líquido da categoria',
        text: 'Ao rendimento bruto subtraímos a dedução específica aplicável ao trabalho dependente.'),
      const _MethodStep(number: '2', title: 'Mínimo de existência',
        text: 'Quando aplicável, calculamos o abatimento previsto no artigo 70.º do Código do IRS.'),
      _MethodStep(number: '3', title: 'Escalões progressivos',
        text: 'Aplicamos as taxas gerais de ${rules.taxYear} ao rendimento coletável.'),
      const _MethodStep(number: '4', title: 'Deduções e retenções',
        text: 'Aplicamos limites por categoria e o limite conjunto. Por fim, descontamos o IRS já retido.'),
      const SizedBox(height: 24),
      _Notice(title: 'Âmbito validado', icon: Icons.verified_outlined, messages: [
        'Residente durante todo o ano no Continente.',
        'Rendimentos exclusivamente da Categoria A.',
        'Simulação de um titular com tributação separada.',
        'Regras ${rules.rulesVersion}, verificadas em 26/08/2026.',
      ]),
      const SizedBox(height: 18),
      const _Notice(title: 'Ainda não calculamos', icon: Icons.schedule_rounded, messages: [
        'Madeira e Açores.', 'Tributação conjunta.', 'IRS Jovem.',
        'Trabalho independente e outros tipos de rendimento.',
      ]),
    ]),
  );
}

final class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.result, required this.year, this.onTap});
  final TaxResult result;
  final int year;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = result.isRefund;
    return Card(
      color: result.available
          ? (positive ? const Color(0xFF183D35) : const Color(0xFF4A2925))
          : scheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(24), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('IRS $year', style: TextStyle(color: result.available ? Colors.white70 : scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text(result.available
                ? (positive ? 'Reembolso estimado' : 'Imposto adicional estimado')
                : 'Estimativa indisponível',
              style: TextStyle(color: result.available ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(result.available
                ? (positive ? result.balance : -result.balance).format()
                : '—',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: result.available ? Colors.white : scheme.onSurface)),
            if (onTap != null) ...[
              const SizedBox(height: 14),
              Text('Ver cálculo →', style: TextStyle(color: result.available ? Colors.white70 : scheme.primary,
                fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
      ),
    );
  }
}

final class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({required this.value, required this.options, required this.onChanged});
  final T value;
  final List<(T, String, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (v) { if (v != null) onChanged(v); },
    child: Column(children: [
      for (final option in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            color: option.$1 == value ? Theme.of(context).colorScheme.primaryContainer : null,
            child: RadioListTile<T>(
              value: option.$1,
              title: Text(option.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(option.$3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
    ]),
  );
}

final class _NumberPicker extends StatelessWidget {
  const _NumberPicker({required this.value, required this.min, required this.max, required this.onChanged});
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton.filledTonal(onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_rounded)),
      SizedBox(width: 130, child: Text('$value', textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall)),
      IconButton.filled(onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_rounded)),
    ]),
  ));
}

final class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.value, required this.label, required this.onChanged, this.hint});
  final String value;
  final String label;
  final String? hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    autofocus: true,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,. ]'))],
    decoration: InputDecoration(labelText: label, hintText: hint, suffixText: '€'),
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    onChanged: onChanged,
  );
}

final class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.draft});
  final TaxDraft draft;

  @override
  Widget build(BuildContext context) {
    String safe(String value) => value.trim().isEmpty ? '0 €' : '$value €';
    final gross = draft.incomeEntryMode == IncomeEntryMode.annual
        ? safe(draft.gross) : '${safe(draft.monthly)} × ${draft.months}';
    return Card(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _ReviewRow('Ano fiscal', '${draft.taxYear}'),
        _ReviewRow('Idade', '${draft.age} anos'),
        _ReviewRow('Dependentes', '${draft.dependentAges.length}'),
        _ReviewRow('Rendimento bruto', gross),
        _ReviewRow('Retenção', safe(draft.withholding)),
        _ReviewRow('Segurança Social', safe(draft.socialSecurity)),
      ]),
    ));
  }
}

final class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]),
  );
}

final class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.label, required this.ppr, required this.result});
  final String label;
  final Money ppr;
  final TaxResult result;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text('PPR ${ppr.format()}', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 18),
      Text(result.isRefund ? 'Reembolso' : 'A pagar'),
      const SizedBox(height: 4),
      Text((result.isRefund ? result.balance : -result.balance).format(),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    ]),
  ));
}

final class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.messages, required this.icon});
  final String title;
  final List<String> messages;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon), const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        for (final message in messages)
          Padding(padding: const EdgeInsets.only(bottom: 7),
            child: Text('• $message', style: const TextStyle(height: 1.35))),
      ]),
    ),
  );
}

final class _MethodStep extends StatelessWidget {
  const _MethodStep({required this.number, required this.title, required this.text});
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 18, child: Text(number)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
      ])),
    ]),
  );
}

final class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 34, height: 34,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(11)),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 21)),
    const SizedBox(width: 10),
    const Text('taxy.pt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
      letterSpacing: -.5)),
  ]);
}

final class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 10), Text(text),
  ]);
}

final class _FatalError extends StatelessWidget {
  const _FatalError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 16), Text(message, textAlign: TextAlign.center),
    ])),
  );
}
