import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'state/providers.dart';

import 'app/home/module_section.dart';
import 'domain/models.dart';
import 'domain/money.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_controller.dart';
import 'navigation/app_navigation.dart';
import 'modules/efatura/application/efatura_read_only_service.dart';
import 'modules/efatura/infrastructure/efatura_backend_bridge.dart';
import 'modules/efatura/infrastructure/efatura_runtime_bridge.dart';
import 'modules/efatura/screens/efatura_screen.dart';
import 'question_engine/question_engine.dart';
import 'screens/how_we_calculate_screen.dart';
import 'screens/settings_screen.dart';
import 'state/providers.dart';
import 'tax_engine/tax_engine.dart';
import 'tax_engine/household_tax_engine.dart';
import 'tax_engine/irs_jovem_tax_engine.dart';
import 'tax_engine/tax_rules.dart';
import 'widgets/notice_card.dart';

const _taxyViolet = Color(0xFF6557E8);
const _taxyInk = Color(0xFF17172B);
const _taxyMint = Color(0xFF69E0B4);
const _taxyCream = Color(0xFFF6F5FA);

TaxResult _calculateSimulation(TaxSimulation simulation, TaxRuleSet rules) {
  if (simulation.profile.civilStatus == CivilStatus.single) {
    if (simulation.primaryIrsJovem.requested) {
      final comparison = IrsJovemTaxEngine(rules).compare(simulation);
      return comparison.withIrsJovem ?? comparison.normal;
    }
    return TaxEngine(rules).calculate(simulation);
  }
  final requested =
      simulation.primaryIrsJovem.requested ||
      (simulation.secondaryTaxpayer?.irsJovem.requested ?? false);
  final comparison = requested
      ? HouseholdTaxEngine(rules).compareWithIrsJovem(simulation).withIrsJovem
      : HouseholdTaxEngine(rules).compare(simulation);
  if (comparison == null) {
    final normal = HouseholdTaxEngine(rules).compare(simulation);
    if (!normal.available) return TaxEngine(rules).calculate(simulation);
    return simulation.profile.filingMode == FilingMode.joint
        ? normal.joint!
        : normal.separate!;
  }
  if (!comparison.available) return TaxEngine(rules).calculate(simulation);
  return simulation.profile.filingMode == FilingMode.joint
      ? comparison.joint!
      : comparison.separate!;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final language = LanguageController(LocalLanguagePreferenceStore());
  await language.load();
  runApp(ProviderScope(child: TaxyApp(languageController: language)));
}

final class TaxyApp extends StatefulWidget {
  const TaxyApp({super.key, this.languageController});

  final LanguageController? languageController;

  @override
  State<TaxyApp> createState() => _TaxyAppState();
}

final class _TaxyAppState extends State<TaxyApp> {
  late final LanguageController _language =
      widget.languageController ??
      LanguageController(
        MemoryLanguagePreferenceStore(LanguagePreference.portuguese),
        initial: LanguagePreference.portuguese,
      );
  late final bool _ownsLanguage = widget.languageController == null;

  @override
  void dispose() {
    if (_ownsLanguage) _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _language,
    child: ListenableBuilder(
      listenable: _language,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: _language.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeResolutionCallback: resolveTaxyLocale,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    ),
  );

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _taxyViolet,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? _taxyCream
          : const Color(0xFF0E0E18),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.6,
          height: 1.03,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1.08,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.35),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF191925),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

void _openSettings(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        SettingsScreen(languageController: LanguageScope.of(context)),
  ),
);

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider);
    final simulations = ref.watch(simulationsProvider);
    final savedDraft = ref.watch(simulationDraftProvider);
    return Scaffold(
      body: SafeArea(
        child: rules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _FatalError(message: l10n.rulesLoadError),
          data: (ruleSet) => savedDraft.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => simulations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _FatalError(message: l10n.savedDataLoadError),
              data: (items) => items.isEmpty
                  ? _Welcome(rules: ruleSet, hasDraft: false)
                  : _DashboardRuleLoader(simulations: items, hasDraft: false),
            ),
            data: (draft) => simulations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _FatalError(message: l10n.simulationsLoadError),
              data: (items) => items.isEmpty
                  ? _Welcome(rules: ruleSet, hasDraft: draft != null)
                  : _DashboardRuleLoader(
                      simulations: items,
                      hasDraft: draft != null,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DashboardRuleLoader extends ConsumerWidget {
  const _DashboardRuleLoader({
    required this.simulations,
    required this.hasDraft,
  });

  final List<TaxSimulation> simulations;
  final bool hasDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = simulations.first.profile;
    final rules = ref.watch(
      rulesForProvider((year: profile.taxYear, region: profile.region)),
    );
    return rules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _FatalError(message: l10n.simulationRulesLoadError),
      data: (value) => _Dashboard(
        rules: value,
        simulations: simulations,
        hasDraft: hasDraft,
      ),
    );
  }
}

final class _Welcome extends StatelessWidget {
  const _Welcome({required this.rules, required this.hasDraft});
  final TaxRuleSet rules;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        const Positioned(
          top: -90,
          right: -90,
          child: _Glow(size: 250, color: _taxyMint),
        ),
        Positioned(
          top: 160,
          left: -120,
          child: _Glow(size: 260, color: _taxyViolet.withValues(alpha: .3)),
        ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 46,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: _Brand()),
                      IconButton(
                        key: const Key('open-settings'),
                        tooltip: l10n.settings,
                        onPressed: () => _openSettings(context),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 58),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _taxyMint.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      l10n.welcomeTagline,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.welcomeTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.welcomeBody,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _PreviewCard(),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _TrustRow(
                        icon: Icons.verified_user_outlined,
                        text: l10n.rulesVerified(rules.taxYear),
                      ),
                      _TrustRow(
                        icon: Icons.lock_outline_rounded,
                        text: l10n.dataOnDevice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  ModuleSection(
                    onOpenIrs: () => _openWizard(context, rules),
                    showExperimentalEfatura: EfaturaFeatureFlags.experimental,
                    onOpenEfatura: () => _openEfatura(context),
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: () => _openWizard(context, rules),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      hasDraft ? l10n.resumeSimulation : l10n.startSimulation,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HowWeCalculateScreen(rules: rules),
                        ),
                      ),
                      child: Text(l10n.howWeCalculate),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _Dashboard extends ConsumerWidget {
  const _Dashboard({
    required this.rules,
    required this.simulations,
    required this.hasDraft,
  });
  final TaxRuleSet rules;
  final List<TaxSimulation> simulations;
  final bool hasDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final latest = simulations.first;
    final result = _calculateSimulation(latest, rules);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(child: _Brand()),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _taxyMint.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.privateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.howWeCalculate,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HowWeCalculateScreen(rules: rules),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
                IconButton(
                  key: const Key('open-settings'),
                  tooltip: l10n.settings,
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O teu IRS, num relance',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  'Simulação atualizada com as regras ${rules.taxYear}.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasDraft) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _openWizard(context, rules),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Retomar simulação em curso'),
                  ),
                ],
                const SizedBox(height: 22),
                _ResultHero(
                  result: result,
                  year: latest.profile.taxYear,
                  onTap: () => _openResult(context, latest, rules),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.receipt_long_outlined,
                        label: 'Ver cálculo',
                        onTap: () => _openResult(context, latest, rules),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.tune_rounded,
                        label: 'Alterar',
                        onTap: () =>
                            _openWizard(context, rules, source: latest),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.compare_arrows_rounded,
                        label: 'Comparar',
                        onTap: result.available
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompareScreen(
                                    simulation: latest,
                                    rules: rules,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                if (result.available) ...[
                  const SizedBox(height: 22),
                  _InsightCard(result: result),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpportunitiesScreen(
                          simulation: latest,
                          rules: rules,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Explorar oportunidades fiscais'),
                  ),
                ],
                if (EfaturaFeatureFlags.experimental) ...[
                  const SizedBox(height: 22),
                  Card(
                    child: ListTile(
                      key: const Key('efatura-dashboard-entry'),
                      leading: const Icon(Icons.receipt_outlined),
                      title: const Text('e-Fatura'),
                      subtitle: const Text('Consulta read-only experimental'),
                      trailing: const Chip(label: Text('Experimental')),
                      onTap: () => _openEfatura(context),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'As tuas simulações',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${simulations.length} guardada${simulations.length == 1 ? '' : 's'} neste dispositivo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _openWizard(context, rules, resumeDraft: false),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nova'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverList.separated(
            itemCount: simulations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = simulations[index];
              final itemResult = _calculateSimulation(item, rules);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${item.profile.taxYear % 100}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    itemResult.available
                        ? (itemResult.isRefund
                              ? 'Reembolso ${itemResult.balance.format()}'
                              : 'A pagar ${(-itemResult.balance).format()}')
                        : 'Cálculo indisponível',
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opções',
                    onSelected: (action) => _manage(context, ref, item, action),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.drive_file_rename_outline),
                          title: Text('Renomear'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy_rounded),
                          title: Text('Duplicar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.tune_rounded),
                          title: Text('Alterar dados'),
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Apagar'),
                        ),
                      ),
                    ],
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

  Future<void> _manage(
    BuildContext context,
    WidgetRef ref,
    TaxSimulation simulation,
    String action,
  ) async {
    final repository = ref.read(repositoryProvider);
    if (action == 'edit') {
      await _openWizard(context, rules, source: simulation);
      return;
    }
    if (action == 'duplicate') {
      final now = DateTime.now();
      await repository.save(
        simulation.copyWith(
          id: now.microsecondsSinceEpoch.toString(),
          name: '${simulation.name} — cópia',
          updatedAt: now,
        ),
      );
      ref.invalidate(simulationsProvider);
      return;
    }
    if (action == 'rename') {
      final controller = TextEditingController(text: simulation.name);
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Renomear simulação'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (name != null && name.isNotEmpty) {
        await repository.save(
          simulation.copyWith(name: name, updatedAt: DateTime.now()),
        );
        ref.invalidate(simulationsProvider);
      }
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded),
          title: const Text('Apagar esta simulação?'),
          content: Text(
            '“${simulation.name}” será removida apenas deste dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repository.delete(simulation.id);
        ref.invalidate(simulationsProvider);
      }
    }
  }
}

Future<void> _openWizard(
  BuildContext context,
  TaxRuleSet rules, {
  TaxSimulation? source,
  bool resumeDraft = true,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          WizardScreen(rules: rules, source: source, resumeDraft: resumeDraft),
    ),
  );
}

Future<void> _openEfatura(BuildContext context) {
  const backendUrl = String.fromEnvironment('TAXY_EFATURA_BACKEND_URL');
  final directBridge = AndroidEfaturaRuntimeBridge();
  late final EfaturaScreen screen;
  if (backendUrl.trim().isEmpty) {
    screen = EfaturaScreen(
      service: EfaturaReadOnlyService(directBridge, directBridge),
      provisioning: directBridge,
    );
  } else {
    final backendBridge = BackendEfaturaRuntimeBridge(
      baseUri: Uri.parse(backendUrl),
      screenProtection: directBridge,
    );
    screen = EfaturaScreen(
      service: EfaturaReadOnlyService(backendBridge, backendBridge),
      provisioning: backendBridge,
    );
  }
  return Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

void _openResult(
  BuildContext context,
  TaxSimulation simulation,
  TaxRuleSet rules,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ResultScreen(simulation: simulation, rules: rules),
    ),
  );
}

final class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({
    super.key,
    required this.rules,
    this.source,
    this.resumeDraft = true,
  });
  final TaxRuleSet rules;
  final TaxSimulation? source;
  final bool resumeDraft;

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

final class _WizardScreenState extends ConsumerState<WizardScreen> {
  late TaxDraft draft;
  final engine = const QuestionEngine();
  int index = 0;
  String? error;
  bool restoring = true;

  @override
  void initState() {
    super.initState();
    draft = TaxDraft(source: widget.source);
    if (widget.source != null || !widget.resumeDraft) {
      restoring = false;
    } else {
      _restoreDraft();
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final saved = await ref.read(repositoryProvider).loadDraft();
      if (!mounted) return;
      setState(() {
        if (saved != null && saved['schemaVersion'] == 1) {
          draft = TaxDraft.fromJson(
            (saved['draft'] as Map).cast<String, Object?>(),
          );
          index = (saved['stepIndex'] as int? ?? 0).clamp(
            0,
            engine.steps(draft).length - 1,
          );
        }
        restoring = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        restoring = false;
        error = 'Não foi possível recuperar o rascunho. Os dados guardados não foram alterados.';
      });
    }
  }

  List<QuestionStep> get steps => engine.steps(draft);
  QuestionStep get step => steps[index.clamp(0, steps.length - 1)];

  @override
  Widget build(BuildContext context) {
    if (restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final current = step;
    final progress = (index + 1) / steps.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: index == 0 ? () => Navigator.pop(context) : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const _Brand(compact: true),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Text(
                '${index + 1}/${steps.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _SectionProgress(
                section: current.section,
                value: progress,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sectionLabel(current.section).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      current.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      current.helper,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(current.id),
                        child: _question(current.id),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: FilledButton.icon(
                onPressed: current.id == 'review' ? _calculate : _next,
                icon: Icon(
                  current.id == 'review'
                      ? Icons.calculate_outlined
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  current.id == 'review' ? 'Calcular estimativa' : 'Continuar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionLabel(QuestionSection section) => switch (section) {
    QuestionSection.eligibility => 'Âmbito',
    QuestionSection.profile => 'Perfil',
    QuestionSection.income => 'Rendimentos',
    QuestionSection.deductions => 'Despesas',
    QuestionSection.review => 'Revisão',
  };

  Widget _question(String id) => switch (id) {
    'taxYear' => _ChoiceGroup<int>(
      value: draft.taxYear,
      options: const [
        (2025, '2025', 'Declaração entregue em 2026'),
        (2026, '2026', 'Ano corrente'),
      ],
      onChanged: (v) => setState(() => draft.taxYear = v),
    ),
    'age' => _NumberPicker(
      value: draft.age,
      min: 18,
      max: 99,
      onChanged: (v) => setState(() => draft.age = v),
    ),
    'civilStatus' => _ChoiceGroup<CivilStatus>(
      value: draft.civilStatus,
      options: const [
        (
          CivilStatus.single,
          'Não casado/a nem unido/a de facto',
          'Liquidação individual',
        ),
        (CivilStatus.married, 'Casado/a', 'Compara conjunta e separada'),
        (CivilStatus.deFacto, 'União de facto', 'Compara conjunta e separada'),
      ],
      onChanged: (v) => setState(() {
        draft.civilStatus = v;
        if (v == CivilStatus.single) draft.filingMode = FilingMode.separate;
      }),
    ),
    'residency' => _ChoiceGroup<bool>(
      value: draft.fullYearResident,
      options: const [
        (true, 'Sim', 'Residente todo o ano'),
        (false, 'Não', 'Não suportado — não será possível continuar'),
      ],
      onChanged: (v) => setState(() => draft.fullYearResident = v),
    ),
    'region' => _ChoiceGroup<TaxRegion>(
      value: draft.region,
      options: const [
        (TaxRegion.continent, 'Continente', 'Cálculo disponível'),
        (TaxRegion.madeira, 'Madeira', 'Disponível para 2026'),
        (TaxRegion.azores, 'Açores', 'Disponível para 2026'),
      ],
      onChanged: (v) => setState(() => draft.region = v),
    ),
    'incomeTypes' => Column(
      children: [
        for (final type in IncomeType.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.incomeTypes.contains(type),
            title: Text(_incomeTypeLabel(type)),
            subtitle: type == IncomeType.employment
                ? const Text('Categoria A · disponível')
                : const Text('Ainda não disponível'),
            onChanged: (selected) => setState(() {
              if (selected ?? false) {
                draft.incomeTypes.add(type);
              } else {
                draft.incomeTypes.remove(type);
              }
            }),
          ),
      ],
    ),
    'specialSituations' => _ChoiceGroup<bool>(
      value: draft.hasSpecialSituation,
      options: const [
        (false, 'Não', 'Caso standard'),
        (
          true,
          'Sim / não tenho a certeza',
          'O cálculo será bloqueado por segurança',
        ),
      ],
      onChanged: (value) => setState(() => draft.hasSpecialSituation = value),
    ),
    'irsJovemInterest' => Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Verificar IRS Jovem para o titular A'),
          subtitle: const Text('A elegibilidade será apurada por histórico.'),
          value: draft.wantsIrsJovemA,
          onChanged: (value) => setState(() => draft.wantsIrsJovemA = value),
        ),
        if (draft.civilStatus != CivilStatus.single)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Verificar IRS Jovem para o titular B'),
            value: draft.wantsIrsJovemB,
            onChanged: (value) => setState(() => draft.wantsIrsJovemB = value),
          ),
      ],
    ),
    'irsJovemHistory' => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uma linha por ano: ano,A|B|AB|N,dependente,residente,regime incompatível',
        ),
        const SizedBox(height: 12),
        if (draft.wantsIrsJovemA) ...[
          TextFormField(
            initialValue: draft.irsJovemHistoryA,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Histórico do titular A',
              hintText: '2024,A,true,true,false\n2025,A,false,true,false',
            ),
            onChanged: (value) => draft.irsJovemHistoryA = value,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('O histórico A está completo'),
            value: draft.irsJovemHistoryCompleteA,
            onChanged: (value) =>
                setState(() => draft.irsJovemHistoryCompleteA = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Situação tributária A regularizada'),
            value: draft.irsJovemRegularizedA,
            onChanged: (value) =>
                setState(() => draft.irsJovemRegularizedA = value),
          ),
        ],
        if (draft.wantsIrsJovemB) ...[
          TextFormField(
            initialValue: draft.irsJovemHistoryB,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Histórico do titular B',
            ),
            onChanged: (value) => draft.irsJovemHistoryB = value,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('O histórico B está completo'),
            value: draft.irsJovemHistoryCompleteB,
            onChanged: (value) =>
                setState(() => draft.irsJovemHistoryCompleteB = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Situação tributária B regularizada'),
            value: draft.irsJovemRegularizedB,
            onChanged: (value) =>
                setState(() => draft.irsJovemRegularizedB = value),
          ),
        ],
      ],
    ),
    'secondaryAge' => _NumberPicker(
      value: draft.secondaryAge,
      min: 18,
      max: 99,
      onChanged: (value) => setState(() => draft.secondaryAge = value),
    ),
    'filingMode' => _ChoiceGroup<FilingMode>(
      value: draft.filingMode,
      options: const [
        (
          FilingMode.separate,
          'Separada',
          'Mostra primeiro as duas liquidações',
        ),
        (FilingMode.joint, 'Conjunta', 'Aplica quociente conjugal 2'),
      ],
      onChanged: (value) => setState(() => draft.filingMode = value),
    ),
    'dependents' => _NumberPicker(
      value: draft.dependentAges.length,
      min: 0,
      max: 8,
      onChanged: (v) => setState(() {
        while (draft.dependentAges.length < v) {
          draft.dependentAges.add(5);
        }
        while (draft.dependentAges.length > v) {
          draft.dependentAges.removeLast();
        }
        if (v == 0) draft.isSingleParentHousehold = false;
      }),
    ),
    'singleParent' => _ChoiceGroup<bool>(
      value: draft.isSingleParentHousehold,
      options: const [
        (true, 'Sim', 'Agregado monoparental standard'),
        (
          false,
          'Não / não tenho a certeza',
          'O cálculo será bloqueado por segurança',
        ),
      ],
      onChanged: (v) => setState(() => draft.isSingleParentHousehold = v),
    ),
    'dependentAges' => Column(
      children: [
        for (var i = 0; i < draft.dependentAges.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dependente ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    initialValue: draft.dependentAges[i],
                    decoration: const InputDecoration(suffixText: 'anos'),
                    items: [
                      for (var age = 0; age <= 25; age++)
                        DropdownMenuItem(value: age, child: Text('$age')),
                    ],
                    onChanged: (v) =>
                        setState(() => draft.dependentAges[i] = v ?? 0),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
    'incomeMode' => _ChoiceGroup<IncomeEntryMode>(
      value: draft.incomeEntryMode,
      options: const [
        (IncomeEntryMode.annual, 'Total anual', 'Um único valor do ano'),
        (
          IncomeEntryMode.monthly,
          'Mensal × meses',
          'A app calcula o total anual',
        ),
      ],
      onChanged: (v) => setState(() => draft.incomeEntryMode = v),
    ),
    'gross' => Column(
      children: [
        _MoneyField(
          value: draft.incomeEntryMode == IncomeEntryMode.annual
              ? draft.gross
              : draft.monthly,
          label: draft.incomeEntryMode == IncomeEntryMode.annual
              ? 'Rendimento anual'
              : 'Rendimento mensal',
          onChanged: (v) => draft.incomeEntryMode == IncomeEntryMode.annual
              ? draft.gross = v
              : draft.monthly = v,
        ),
        if (draft.incomeEntryMode == IncomeEntryMode.monthly) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: draft.months,
            decoration: const InputDecoration(
              labelText: 'Número de pagamentos',
            ),
            items: [
              for (var n = 1; n <= 14; n++)
                DropdownMenuItem(value: n, child: Text('$n meses')),
            ],
            onChanged: (v) => setState(() => draft.months = v ?? 14),
          ),
        ],
      ],
    ),
    'withholding' => _MoneyField(
      value: draft.withholding,
      label: 'Retenção anual de IRS',
      onChanged: (v) => draft.withholding = v,
    ),
    'socialSecurity' => _MoneyField(
      value: draft.socialSecurity,
      label: 'Contribuições anuais',
      onChanged: (v) => draft.socialSecurity = v,
    ),
    'secondaryGross' => _MoneyField(
      value: draft.secondaryGross,
      label: 'Rendimento anual do titular B',
      onChanged: (value) => draft.secondaryGross = value,
    ),
    'secondaryWithholding' => _MoneyField(
      value: draft.secondaryWithholding,
      label: 'Retenção anual do titular B',
      onChanged: (value) => draft.secondaryWithholding = value,
    ),
    'secondarySocialSecurity' => _MoneyField(
      value: draft.secondarySocialSecurity,
      label: 'Contribuições anuais do titular B',
      onChanged: (value) => draft.secondarySocialSecurity = value,
    ),
    'general' => _MoneyField(
      value: draft.general,
      label: 'Total de despesas gerais',
      hint: 'Ex.: 1.200,00',
      onChanged: (v) => draft.general = v,
    ),
    'health' => _MoneyField(
      value: draft.health,
      label: 'Total de saúde',
      onChanged: (v) => draft.health = v,
    ),
    'education' => _MoneyField(
      value: draft.education,
      label: 'Educação standard elegível',
      hint: 'Não inclui estudante deslocado ou majorações territoriais',
      onChanged: (v) => draft.education = v,
    ),
    'rent' => _MoneyField(
      value: draft.rent,
      label: 'Rendas anuais',
      onChanged: (v) => draft.rent = v,
    ),
    'careHomes' => _MoneyField(
      value: draft.careHomes,
      label: 'Encargos anuais',
      onChanged: (v) => draft.careHomes = v,
    ),
    'invoiceVat15' => _MoneyField(
      value: draft.invoiceVat15,
      label: 'IVA elegível à taxa de 15%',
      onChanged: (v) => draft.invoiceVat15 = v,
    ),
    'invoiceVat30' => _MoneyField(
      value: draft.invoiceVat30,
      label: 'IVA elegível à taxa de 30%',
      onChanged: (v) => draft.invoiceVat30 = v,
    ),
    'invoiceVat35' => _MoneyField(
      value: draft.invoiceVat35,
      label: 'IVA elegível à taxa de 35%',
      onChanged: (v) => draft.invoiceVat35 = v,
    ),
    'invoiceVat100' => _MoneyField(
      value: draft.invoiceVat100,
      label: 'IVA elegível à taxa de 100%',
      onChanged: (v) => draft.invoiceVat100 = v,
    ),
    'ppr' => _MoneyField(
      value: draft.ppr,
      label: 'Aplicações anuais em PPR',
      onChanged: (v) => draft.ppr = v,
    ),
    'secondaryDeductions' => Column(
      children: [
        _MoneyField(
          value: draft.secondaryGeneral,
          label: 'Despesas gerais · titular B',
          onChanged: (v) => draft.secondaryGeneral = v,
        ),
        const SizedBox(height: 10),
        _MoneyField(
          value: draft.secondaryHealth,
          label: 'Saúde · titular B',
          onChanged: (v) => draft.secondaryHealth = v,
        ),
        const SizedBox(height: 10),
        _MoneyField(
          value: draft.secondaryEducation,
          label: 'Educação standard · titular B',
          onChanged: (v) => draft.secondaryEducation = v,
        ),
        const SizedBox(height: 10),
        _MoneyField(
          value: draft.secondaryRent,
          label: 'Rendas · titular B',
          onChanged: (v) => draft.secondaryRent = v,
        ),
        const SizedBox(height: 10),
        _MoneyField(
          value: draft.secondaryCareHomes,
          label: 'Lares · titular B',
          onChanged: (v) => draft.secondaryCareHomes = v,
        ),
        const SizedBox(height: 10),
        _MoneyField(
          value: draft.secondaryPpr,
          label: 'PPR · titular B',
          onChanged: (v) => draft.secondaryPpr = v,
        ),
      ],
    ),
    'review' => _ReviewCard(draft: draft, onEdit: _editSection),
    _ => const SizedBox.shrink(),
  };

  Future<void> _back() async {
    setState(() {
      error = null;
      index = (index - 1).clamp(0, steps.length - 1);
    });
    await _persistDraft();
  }

  Future<void> _next() async {
    final validation = _validate(step.id);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    setState(() {
      error = null;
      index = (index + 1).clamp(0, steps.length - 1);
    });
    await _persistDraft();
  }

  Future<void> _persistDraft() async {
    if (widget.source != null) return;
    try {
      await ref.read(repositoryProvider).saveDraft({
        'schemaVersion': 1,
        'stepIndex': index,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'draft': draft.toJson(),
      });
      ref.invalidate(simulationDraftProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Não foi possível guardar o progresso neste dispositivo. Podes continuar, mas confirma o armazenamento antes de fechar.';
      });
    }
  }

  void _editSection(QuestionSection section) {
    final target = steps.indexWhere(
      (candidate) => candidate.section == section,
    );
    if (target < 0) return;
    setState(() {
      error = null;
      index = target;
    });
  }

  String? _validate(String id) {
    if (id == 'residency' && !draft.fullYearResident) {
      return 'Ainda não suportado: residência fiscal parcial.';
    }
    if (id == 'region' &&
        draft.taxYear == 2025 &&
        draft.region != TaxRegion.continent) {
      return 'Ainda não suportado: Madeira e Açores em 2025 permanecem NEEDS_VERIFICATION.';
    }
    if (id == 'incomeTypes' &&
        (draft.incomeTypes.isEmpty ||
            draft.incomeTypes.any((type) => type != IncomeType.employment))) {
      return 'Ainda não suportado: só conseguimos calcular quando existe exclusivamente trabalho dependente.';
    }
    if (id == 'specialSituations' && draft.hasSpecialSituation) {
      return 'Ainda não suportado: este caso exige validação adicional e não será aproximado.';
    }
    if (id == 'irsJovemHistory') {
      if (draft.wantsIrsJovemA &&
          (draft.irsJovemHistoryA.trim().isEmpty ||
              !draft.irsJovemHistoryCompleteA)) {
        return 'Dados insuficientes: falta o histórico anual completo do titular A.';
      }
      if (draft.wantsIrsJovemB &&
          (draft.irsJovemHistoryB.trim().isEmpty ||
              !draft.irsJovemHistoryCompleteB)) {
        return 'Dados insuficientes: falta o histórico anual completo do titular B.';
      }
    }
    if (id == 'singleParent' && !draft.isSingleParentHousehold) {
      return 'Ainda não suportado: com dependentes, só está validado o agregado monoparental standard.';
    }
    if (id == 'gross') {
      final value = draft.incomeEntryMode == IncomeEntryMode.annual
          ? draft.gross
          : draft.monthly;
      if (_money(value).cents <= 0) {
        return 'Dados inválidos: indica um rendimento superior a zero.';
      }
    }
    if (id == 'secondaryGross' && _money(draft.secondaryGross).cents < 0) {
      return 'Dados inválidos: o rendimento do segundo titular não pode ser negativo.';
    }
    return null;
  }

  Money _money(String raw) {
    try {
      return Money.parseEuros(raw);
    } on FormatException {
      return Money.zero;
    }
  }

  List<IrsJovemIncomeYear> _irsHistory(String raw) {
    final history = <IrsJovemIncomeYear>[];
    for (final rawLine in raw.split('\n')) {
      final values = rawLine.split(',').map((value) => value.trim()).toList();
      final year = values.isEmpty ? null : int.tryParse(values[0]);
      if (values.length != 5 || year == null) continue;
      final income = values[1].toUpperCase();
      history.add(
        IrsJovemIncomeYear(
          year: year,
          hadCategoryAIncome: income.contains('A'),
          hadCategoryBIncome: income.contains('B'),
          wasDependent: values[2].toLowerCase() == 'true',
          residentInPortugal: values[3].toLowerCase() == 'true',
          usedIncompatibleRegime: values[4].toLowerCase() == 'true',
        ),
      );
    }
    return history;
  }

  Future<void> _calculate() async {
    try {
      final now = DateTime.now();
      final gross = draft.incomeEntryMode == IncomeEntryMode.annual
          ? _money(draft.gross)
          : Money.fromCents(_money(draft.monthly).cents * draft.months);
      final selectedRules = await ref
          .read(taxRuleRepositoryProvider)
          .load(draft.taxYear, draft.region.name);
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
          isSingleParentHousehold: draft.isSingleParentHousehold,
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
          general: _money(draft.general),
          health: _money(draft.health),
          education: _money(draft.education),
          rent: _money(draft.rent),
          careHomes: _money(draft.careHomes),
          invoiceVat15: _money(draft.invoiceVat15),
          invoiceVat30: _money(draft.invoiceVat30),
          invoiceVat35: _money(draft.invoiceVat35),
          invoiceVat100: _money(draft.invoiceVat100),
          ppr: _money(draft.ppr),
        ),
        primaryIrsJovem: IrsJovemAnswers(
          requested: draft.wantsIrsJovemA,
          taxSituationRegularized: draft.irsJovemRegularizedA,
          historyConfirmedComplete: draft.irsJovemHistoryCompleteA,
          incomeHistory: _irsHistory(draft.irsJovemHistoryA),
        ),
        secondaryTaxpayer: draft.civilStatus == CivilStatus.single
            ? null
            : TaxpayerInput(
                id: 'B',
                age: draft.secondaryAge,
                income: EmploymentIncome(
                  entryMode: IncomeEntryMode.annual,
                  gross: _money(draft.secondaryGross),
                  withholding: _money(draft.secondaryWithholding),
                  socialSecurity: _money(draft.secondarySocialSecurity),
                ),
                deductions: DeductionInput(
                  general: _money(draft.secondaryGeneral),
                  health: _money(draft.secondaryHealth),
                  education: _money(draft.secondaryEducation),
                  rent: _money(draft.secondaryRent),
                  careHomes: _money(draft.secondaryCareHomes),
                  ppr: _money(draft.secondaryPpr),
                  invoiceVat15: _money(draft.secondaryVat15),
                  invoiceVat30: _money(draft.secondaryVat30),
                  invoiceVat35: _money(draft.secondaryVat35),
                  invoiceVat100: _money(draft.secondaryVat100),
                ),
                irsJovem: IrsJovemAnswers(
                  requested: draft.wantsIrsJovemB,
                  taxSituationRegularized: draft.irsJovemRegularizedB,
                  historyConfirmedComplete: draft.irsJovemHistoryCompleteB,
                  incomeHistory: _irsHistory(draft.irsJovemHistoryB),
                ),
              ),
        dependents: [
          for (var i = 0; i < draft.dependentAges.length; i++)
            Dependent(id: 'dependent-$i', ageAtYearEnd: draft.dependentAges[i]),
        ],
        incomeTypes: {...draft.incomeTypes},
        situations: TaxSituationFlags(
          irsJovem: draft.wantsIrsJovemA || draft.wantsIrsJovemB,
          otherSpecialSituation: draft.hasSpecialSituation,
        ),
      );
      await ref.read(repositoryProvider).save(simulation);
      if (widget.source == null) {
        await ref.read(repositoryProvider).clearDraft();
        ref.invalidate(simulationDraftProvider);
      }
      ref.invalidate(simulationsProvider);
      if (!mounted) return;
      await AppNavigation.replace(
        context,
        ResultScreen(simulation: simulation, rules: selectedRules),
      );
    } on FormatException {
      if (!mounted) return;
      setState(() {
        error =
            'Dados inválidos: revê os valores monetários antes de calcular.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Não foi possível concluir o cálculo com segurança. O teu rascunho continua guardado; tenta novamente.';
      });
    }
  }

  String _incomeTypeLabel(IncomeType type) => switch (type) {
    IncomeType.employment => 'Trabalho dependente',
    IncomeType.selfEmployment => 'Trabalho independente',
    IncomeType.pensions => 'Pensões',
    IncomeType.property => 'Rendas',
    IncomeType.capital => 'Juros ou dividendos',
    IncomeType.securities => 'Ações ou ETFs',
    IncomeType.crypto => 'Criptoativos',
    IncomeType.foreign => 'Rendimentos estrangeiros',
    IncomeType.other => 'Outros rendimentos',
  };
}

final class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.simulation,
    required this.rules,
  });
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) {
    final result = _calculateSimulation(simulation, rules);
    final jovemRequested =
        simulation.primaryIrsJovem.requested ||
        (simulation.secondaryTaxpayer?.irsJovem.requested ?? false);
    final singleJovem =
        simulation.profile.civilStatus == CivilStatus.single && jovemRequested
        ? IrsJovemTaxEngine(rules).compare(simulation)
        : null;
    final householdJovem =
        simulation.profile.civilStatus != CivilStatus.single && jovemRequested
        ? HouseholdTaxEngine(rules).compareWithIrsJovem(simulation)
        : null;
    final household = simulation.profile.civilStatus == CivilStatus.single
        ? null
        : HouseholdTaxEngine(rules).compare(simulation);
    return Scaffold(
      appBar: AppBar(title: const Text('A tua estimativa')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
        children: [
          _ResultHero(result: result, year: simulation.profile.taxYear),
          if (jovemRequested) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IRS Jovem',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (singleJovem != null) ...[
                      Text('IRS normal: ${singleJovem.normal.taxDue.format()}'),
                      if (singleJovem.withIrsJovem != null) ...[
                        Text(
                          'IRS Jovem: ${singleJovem.withIrsJovem!.taxDue.format()}',
                        ),
                        Text(
                          'Benefício fiscal estimado: ${singleJovem.estimatedBenefit.format()}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${singleJovem.eligibility.relevantIncomeYear}.º ano · '
                          '${singleJovem.eligibility.exemptionRatePpm / 10000}% · '
                          'limite ${singleJovem.eligibility.exemptionLimit.format()} · '
                          'isento ${singleJovem.adjustment!.exemptIncome.format()}',
                        ),
                      ] else
                        Text(singleJovem.eligibility.reasons.join(' ')),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const Text('Porque sou elegível?'),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              singleJovem.eligibility.reasons.isEmpty
                                  ? 'A elegibilidade foi determinada pelo histórico anual, idade, residência e situação tributária indicados.'
                                  : singleJovem.eligibility.reasons.join(' '),
                            ),
                          ),
                        ],
                      ),
                    ] else if (householdJovem != null) ...[
                      Text(
                        'Separada sem IRS Jovem: ${householdJovem.normal.separate!.taxDue.format()}',
                      ),
                      Text(
                        'Conjunta sem IRS Jovem: ${householdJovem.normal.joint!.taxDue.format()}',
                      ),
                      if (householdJovem.withIrsJovem != null) ...[
                        Text(
                          'Separada com IRS Jovem: ${householdJovem.withIrsJovem!.separate!.taxDue.format()}',
                        ),
                        Text(
                          'Conjunta com IRS Jovem: ${householdJovem.withIrsJovem!.joint!.taxDue.format()}',
                        ),
                        Text(
                          'Benefício fiscal estimado na melhor opção: ${householdJovem.estimatedBenefit.format()}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ] else
                        Text(householdJovem.warnings.join(' ')),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const Text('Porque somos elegíveis?'),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Titular A: ${householdJovem.primaryEligibility.reasons.join(' ')}\n'
                              'Titular B: ${householdJovem.secondaryEligibility.reasons.join(' ')}',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Com os dados introduzidos, esta é a diferença de imposto estimado; não constitui garantia de benefício.',
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (household?.available ?? false) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparação de tributação',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text('Tributação separada'),
                    const SizedBox(height: 4),
                    Text(
                      household!.separate!.taxDue.format(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text('Tributação conjunta'),
                    const SizedBox(height: 4),
                    Text(
                      household.joint!.taxDue.format(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text('Diferença'),
                    Text(
                      household.difference.format(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text('Opção estimada mais favorável'),
                    Text(
                      household.difference.cents == 0
                          ? 'Sem diferença estimada'
                          : household.recommendedMode == FilingMode.joint
                          ? 'Tributação conjunta'
                          : 'Tributação separada',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      household.difference.cents == 0
                          ? 'Nesta simulação, as duas opções apresentam o mesmo imposto estimado.'
                          : household.recommendedMode == FilingMode.joint
                          ? 'Nesta simulação, a tributação conjunta apresenta menor imposto estimado.'
                          : 'Nesta simulação, a tributação separada apresenta menor imposto estimado.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Simulação baseada nos dados introduzidos e regras fiscais configuradas; não substitui a liquidação oficial da AT.',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text('IRS ${simulation.profile.taxYear}')),
              Chip(label: Text(rules.jurisdiction)),
              const Chip(label: Text('Categoria A')),
              Chip(
                label: Text(
                  simulation.profile.civilStatus == CivilStatus.single
                      ? 'Titular individual'
                      : '${simulation.profile.civilStatus.name} · ${simulation.profile.filingMode.name}',
                ),
              ),
              Chip(label: Text('Regras ${rules.rulesVersion}')),
              if (jovemRequested)
                Chip(
                  label: Text(
                    (singleJovem?.applied ??
                            (householdJovem?.withIrsJovem != null))
                        ? 'IRS Jovem aplicado'
                        : 'IRS Jovem não aplicado',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.available) ...[
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Rendimento coletável',
                    value: result.taxableIncome.format(),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Retido durante o ano',
                    value: result.withholding.format(),
                    icon: Icons.savings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CompareScreen(simulation: simulation, rules: rules),
                ),
              ),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Comparar cenário'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OpportunitiesScreen(simulation: simulation, rules: rules),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Ver oportunidades'),
            ),
            const SizedBox(height: 20),
            Card(
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text(
                  'Ver cálculo detalhado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Valores e explicações linha a linha'),
                children: [
                  const Divider(height: 1),
                  for (var i = 0; i < result.breakdown.length; i++) ...[
                    ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        result.breakdown[i].label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        result.breakdown[i].amount.format(signed: true),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            result.breakdown[i].explanation,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < result.breakdown.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ],
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            NoticeCard(
              title: result.available
                  ? 'Atenção aos limites'
                  : 'Cálculo não disponível',
              messages: result.warnings,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: 20),
          NoticeCard(
            title: 'Pressupostos da simulação',
            messages: result.assumptions,
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            'Esta é uma simulação baseada nos dados introduzidos e nas regras fiscais configuradas para o ano selecionado. Não substitui a liquidação oficial da Autoridade Tributária.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Regras fiscais ${rules.taxYear} — versão ${rules.rulesVersion} · validadas em ${rules.verifiedAt.day.toString().padLeft(2, '0')}/${rules.verifiedAt.month.toString().padLeft(2, '0')}/${rules.verifiedAt.year}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

final class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({
    super.key,
    required this.simulation,
    required this.rules,
  });
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

final class _CompareScreenState extends ConsumerState<CompareScreen> {
  late int pprCents = widget.simulation.deductions.ppr.cents;
  late int healthCents = widget.simulation.deductions.health.cents;
  late int educationCents = widget.simulation.deductions.education.cents;
  late int rentCents = widget.simulation.deductions.rent.cents;
  late int generalCents = widget.simulation.deductions.general.cents;

  TaxSimulation get changedSimulation => widget.simulation.copyWith(
    deductions: widget.simulation.deductions.copyWith(
      ppr: Money.fromCents(pprCents),
      health: Money.fromCents(healthCents),
      education: Money.fromCents(educationCents),
      rent: Money.fromCents(rentCents),
      general: Money.fromCents(generalCents),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final original = _calculateSimulation(widget.simulation, widget.rules);
    final changed = _calculateSimulation(changedSimulation, widget.rules);
    final difference = changed.balance - original.balance;
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratório de cenários')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            'Experimenta sem risco.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Altera despesas e PPR. O resultado é recalculado instantaneamente pelo mesmo motor fiscal.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          _ScenarioSlider(
            label: 'PPR',
            helper: 'Valor aplicado durante o ano',
            cents: pprCents,
            maxCents: 500000,
            onChanged: (v) => setState(() => pprCents = v),
          ),
          _ScenarioSlider(
            label: 'Saúde',
            helper: 'Despesas elegíveis',
            cents: healthCents,
            maxCents: 800000,
            onChanged: (v) => setState(() => healthCents = v),
          ),
          _ScenarioSlider(
            label: 'Educação',
            helper: 'Despesas elegíveis',
            cents: educationCents,
            maxCents: 500000,
            onChanged: (v) => setState(() => educationCents = v),
          ),
          _ScenarioSlider(
            label: 'Rendas',
            helper: 'Rendas elegíveis',
            cents: rentCents,
            maxCents: 1500000,
            onChanged: (v) => setState(() => rentCents = v),
          ),
          _ScenarioSlider(
            label: 'Despesas gerais',
            helper: 'Com NIF na fatura',
            cents: generalCents,
            maxCents: 300000,
            onChanged: (v) => setState(() => generalCents = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScenarioCard(
                  label: 'Cenário A',
                  ppr: widget.simulation.deductions.ppr,
                  result: original,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScenarioCard(
                  label: 'Cenário B',
                  ppr: Money.fromCents(pprCents),
                  result: changed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            color: difference.cents >= 0
                ? _taxyMint.withValues(alpha: .18)
                : Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Diferença no resultado',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    difference.format(signed: true),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: difference.cents == 0 ? null : _saveScenario,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Guardar como nova simulação'),
          ),
          const SizedBox(height: 18),
          Text(
            'A vantagem fiscal de um PPR está sujeita a condições de elegibilidade e manutenção. Esta comparação não avalia custos, risco ou rentabilidade do produto.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScenario() async {
    final now = DateTime.now();
    final saved = changedSimulation.copyWith(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${widget.simulation.name} — cenário',
      updatedAt: now,
    );
    await ref.read(repositoryProvider).save(saved);
    ref.invalidate(simulationsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cenário guardado no dispositivo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

final class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({
    super.key,
    required this.simulation,
    required this.rules,
  });
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) {
    final baseline = _calculateSimulation(simulation, rules);
    final d = simulation.deductions;
    Money target(String cap, String rate) =>
        Money.fromCents(Money.mulDiv(rules.d(cap), 1000000, rules.d(rate)));
    final pprTarget = Money.fromCents(
      simulation.profile.age < 35
          ? 200000
          : simulation.profile.age <= 50
          ? 175000
          : 150000,
    );
    final candidates = <_OpportunityCandidate>[
      _OpportunityCandidate(
        'PPR',
        'Benefício fiscal sujeito às condições legais do produto.',
        Icons.savings_outlined,
        d.ppr,
        pprTarget,
        (x, value) => x.copyWith(ppr: value),
      ),
      _OpportunityCandidate(
        'Despesas gerais',
        'Faturas elegíveis associadas ao teu NIF.',
        Icons.receipt_long_outlined,
        d.general,
        simulation.profile.isSingleParentHousehold
            ? target(
                'generalSingleParentCapCents',
                'generalSingleParentRatePpm',
              )
            : target('generalCapPerTaxpayerCents', 'generalRatePpm'),
        (x, value) => x.copyWith(general: value),
      ),
      _OpportunityCandidate(
        'Saúde',
        'Apenas despesas reais, elegíveis e não reembolsadas.',
        Icons.health_and_safety_outlined,
        d.health,
        target('healthCapCents', 'healthRatePpm'),
        (x, value) => x.copyWith(health: value),
      ),
      _OpportunityCandidate(
        'Educação',
        'Propinas e outras despesas elegíveis comprovadas.',
        Icons.school_outlined,
        d.education,
        target('educationCapCents', 'educationRatePpm'),
        (x, value) => x.copyWith(education: value),
      ),
      _OpportunityCandidate(
        'Rendas',
        'Rendas de habitação permanente fiscalmente elegíveis.',
        Icons.home_outlined,
        d.rent,
        target('rentFloorCapCents', 'rentRatePpm'),
        (x, value) => x.copyWith(rent: value),
      ),
      _OpportunityCandidate(
        'Lares',
        'Encargos elegíveis com apoio residencial.',
        Icons.elderly_outlined,
        d.careHomes,
        target('careHomeCapCents', 'careHomeRatePpm'),
        (x, value) => x.copyWith(careHomes: value),
      ),
    ];
    final opportunities = <_OpportunityResult>[];
    for (final candidate in candidates) {
      if (candidate.current.cents >= candidate.target.cents) {
        continue;
      }
      final changed = simulation.copyWith(
        deductions: candidate.apply(d, candidate.target),
      );
      final delta =
          _calculateSimulation(changed, rules).balance - baseline.balance;
      if (delta.cents > 0) {
        opportunities.add(_OpportunityResult(candidate, delta));
      }
    }
    opportunities.sort((a, b) => b.delta.compareTo(a.delta));
    return Scaffold(
      appBar: AppBar(title: const Text('Oportunidades')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
        children: [
          Text(
            'Onde pode existir margem?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Simulamos cada categoria isoladamente até ao respetivo limite. Não assumimos que tiveste despesas que não declaraste.',
            style: TextStyle(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          if (opportunities.isEmpty)
            const NoticeCard(
              title: 'Sem oportunidades adicionais nesta simulação',
              messages: [
                'Os limites podem já estar atingidos ou não existir imposto suficiente para deduzir.',
              ],
              icon: Icons.task_alt_rounded,
            )
          else
            for (final opportunity in opportunities) ...[
              _OpportunityCard(result: opportunity),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 10),
          const NoticeCard(
            title: 'Importante',
            icon: Icons.info_outline_rounded,
            messages: [
              '“Até” não é uma promessa de reembolso: depende do conjunto da simulação.',
              'Não gastes apenas para obter uma dedução fiscal.',
              'Introduz somente despesas reais, elegíveis e documentadas.',
            ],
          ),
        ],
      ),
    );
  }
}

typedef _ApplyDeduction = DeductionInput Function(DeductionInput, Money);

final class _OpportunityCandidate {
  const _OpportunityCandidate(
    this.label,
    this.helper,
    this.icon,
    this.current,
    this.target,
    this.apply,
  );
  final String label;
  final String helper;
  final IconData icon;
  final Money current;
  final Money target;
  final _ApplyDeduction apply;
}

final class _OpportunityResult {
  const _OpportunityResult(this.candidate, this.delta);
  final _OpportunityCandidate candidate;
  final Money delta;
}

final class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.result});
  final _OpportunityResult result;

  @override
  Widget build(BuildContext context) {
    final missing = result.candidate.target - result.candidate.current;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _taxyViolet.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                result.candidate.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.candidate.label,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        'até +${result.delta.format()}',
                        style: const TextStyle(
                          color: Color(0xFF137253),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    result.candidate.helper,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Margem de despesas introduzidas: ${missing.format()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final start = positive ? const Color(0xFF153F39) : const Color(0xFF552F39);
    final end = positive ? const Color(0xFF225E50) : const Color(0xFF7A3D43);
    return Container(
      decoration: BoxDecoration(
        gradient: result.available
            ? LinearGradient(
                colors: [start, end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: result.available ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: result.available
            ? [
                BoxShadow(
                  color: start.withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'IRS $year',
                      style: TextStyle(
                        color: result.available
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (result.available)
                    Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: _taxyMint,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                result.available
                    ? (positive
                          ? 'Reembolso estimado'
                          : 'Imposto adicional estimado')
                    : 'Estimativa indisponível',
                style: TextStyle(
                  color: result.available ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.available
                    ? (positive ? result.balance : -result.balance).format()
                    : '—',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 42,
                  color: result.available ? Colors.white : scheme.onSurface,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Abrir detalhe',
                      style: TextStyle(
                        color: result.available
                            ? Colors.white70
                            : scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: result.available ? Colors.white70 : scheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final T value;
  final List<(T, String, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
    child: Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: option.$1 == value
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: RadioListTile<T>(
                value: option.$1,
                title: Text(
                  option.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(option.$3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

final class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 130,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          IconButton.filled(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    ),
  );
}

final class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hint,
  });
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
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: '€',
    ),
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    onChanged: onChanged,
  );
}

final class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.draft, required this.onEdit});
  final TaxDraft draft;
  final ValueChanged<QuestionSection> onEdit;

  @override
  Widget build(BuildContext context) {
    String safe(String value) => value.trim().isEmpty ? '0 €' : '$value €';
    final gross = draft.incomeEntryMode == IncomeEntryMode.annual
        ? safe(draft.gross)
        : '${safe(draft.monthly)} × ${draft.months}';
    Money read(String value) {
      try {
        return Money.parseEuros(value);
      } on FormatException {
        return Money.zero;
      }
    }

    final deductionsA = [
      draft.general,
      draft.health,
      draft.education,
      draft.rent,
      draft.careHomes,
      draft.invoiceVat15,
      draft.invoiceVat30,
      draft.invoiceVat35,
      draft.invoiceVat100,
      draft.ppr,
    ].fold(Money.zero, (total, value) => total + read(value));
    final deductionsB = [
      draft.secondaryGeneral,
      draft.secondaryHealth,
      draft.secondaryEducation,
      draft.secondaryRent,
      draft.secondaryCareHomes,
      draft.secondaryVat15,
      draft.secondaryVat30,
      draft.secondaryVat35,
      draft.secondaryVat100,
      draft.secondaryPpr,
    ].fold(Money.zero, (total, value) => total + read(value));
    return Column(
      children: [
        _ReviewSection(
          title: 'Âmbito fiscal',
          onEdit: () => onEdit(QuestionSection.eligibility),
          rows: [
            ('Ano e região', '${draft.taxYear} · ${draft.region.name}'),
            (
              'Agregado',
              '${draft.civilStatus.name} · ${draft.filingMode.name}',
            ),
            (
              'IRS Jovem',
              draft.wantsIrsJovemA || draft.wantsIrsJovemB
                  ? 'A verificar'
                  : 'Não pedido',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Perfil e agregado',
          onEdit: () => onEdit(QuestionSection.profile),
          rows: [
            ('Titular A', '${draft.age} anos'),
            if (draft.civilStatus != CivilStatus.single)
              ('Titular B', '${draft.secondaryAge} anos'),
            (
              'Dependentes',
              draft.dependentAges.isEmpty
                  ? 'Nenhum'
                  : draft.dependentAges.map((age) => '$age anos').join(', '),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Rendimentos e retenções',
          onEdit: () => onEdit(QuestionSection.income),
          rows: [
            ('Rendimento A', gross),
            ('Retenção A', safe(draft.withholding)),
            ('Segurança Social A', safe(draft.socialSecurity)),
            if (draft.civilStatus != CivilStatus.single) ...[
              ('Rendimento B', safe(draft.secondaryGross)),
              ('Retenção B', safe(draft.secondaryWithholding)),
              ('Segurança Social B', safe(draft.secondarySocialSecurity)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Deduções introduzidas',
          onEdit: () => onEdit(QuestionSection.deductions),
          rows: [
            ('Total titular A', deductionsA.format()),
            if (draft.civilStatus != CivilStatus.single)
              ('Total titular B', deductionsB.format()),
            ('Educação', 'Apenas cenário standard'),
          ],
        ),
      ],
    );
  }
}

final class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar'),
              ),
            ],
          ),
          for (final row in rows) _ReviewRow(row.$1, row.$2),
        ],
      ),
    ),
  );
}

final class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

final class _ScenarioSlider extends StatelessWidget {
  const _ScenarioSlider({
    required this.label,
    required this.helper,
    required this.cents,
    required this.maxCents,
    required this.onChanged,
  });
  final String label;
  final String helper;
  final int cents;
  final int maxCents;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxCents < cents ? cents : maxCents;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        helper,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  Money.fromCents(cents).format(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Slider(
              value: cents.toDouble().clamp(0, safeMax.toDouble()),
              min: 0,
              max: safeMax.toDouble(),
              divisions: safeMax == 0 ? null : 50,
              label: Money.fromCents(cents).format(),
              onChanged: safeMax == 0
                  ? null
                  : (value) => onChanged((value ~/ 10000) * 10000),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.label,
    required this.ppr,
    required this.result,
  });
  final String label;
  final Money ppr;
  final TaxResult result;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'PPR ${ppr.format()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(result.isRefund ? 'Reembolso' : 'A pagar'),
          const SizedBox(height: 4),
          Text(
            (result.isRefund ? result.balance : -result.balance).format(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

final class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .38), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

final class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _taxyInk,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: _taxyViolet.withValues(alpha: .18),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'A tua estimativa',
                maxLines: 2,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _taxyMint.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: _taxyMint,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Uma resposta clara,',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const Text(
          'contas transparentes.',
          style: TextStyle(
            color: _taxyMint,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final item in const [
              ('5 min', Icons.timer_outlined),
              ('Privado', Icons.lock_outline_rounded),
              ('Explicado', Icons.lightbulb_outline_rounded),
            ])
              Expanded(
                child: Row(
                  children: [
                    Icon(item.$2, size: 15, color: Colors.white54),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

final class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? .45 : 1,
    child: Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.result});
  final TaxResult result;

  @override
  Widget build(BuildContext context) {
    final difference = result.withholding - result.taxDue;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _taxyMint.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _taxyMint.withValues(alpha: .32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _taxyMint.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF127054),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O que isto significa',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  difference.cents >= 0
                      ? 'Retiveste mais IRS ao longo do ano do que o imposto estimado nesta simulação.'
                      : 'As retenções feitas durante o ano ficam abaixo do imposto estimado.',
                  style: const TextStyle(height: 1.35, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _SectionProgress extends StatelessWidget {
  const _SectionProgress({required this.section, required this.value});
  final QuestionSection section;
  final double value;

  @override
  Widget build(BuildContext context) {
    final active = QuestionSection.values.indexOf(section);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: Row(
        children: [
          for (var i = 0; i < QuestionSection.values.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 6,
                decoration: BoxDecoration(
                  color: i <= active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (i < QuestionSection.values.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

final class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 29 : 36,
        height: compact ? 29 : 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_taxyViolet, Color(0xFF8A6CF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 9 : 12),
          boxShadow: [
            BoxShadow(
              color: _taxyViolet.withValues(alpha: .25),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: compact ? 18 : 22,
        ),
      ),
      SizedBox(width: compact ? 8 : 10),
      Text(
        'taxy.pt',
        style: TextStyle(
          fontSize: compact ? 17 : 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -.5,
        ),
      ),
    ],
  );
}

final class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Flexible(child: Text(text)),
    ],
  );
}

final class _FatalError extends StatelessWidget {
  const _FatalError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
