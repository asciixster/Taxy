import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'state/providers.dart';

import 'app/home/module_section.dart';
import 'domain/models.dart';
import 'domain/money.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_pt.dart';
import 'l10n/language_controller.dart';
import 'l10n/taxy_formatters.dart';
import 'l10n/theme_controller.dart';
import 'navigation/app_navigation.dart';
import 'modules/efatura/application/efatura_read_only_service.dart';
import 'modules/efatura/infrastructure/efatura_backend_bridge.dart';
import 'modules/efatura/infrastructure/efatura_api_configuration.dart';
import 'modules/efatura/infrastructure/efatura_screen_protection.dart';
import 'modules/efatura/infrastructure/efatura_session_token_store.dart';
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
import 'product/profile_screen.dart';
import 'product/ledger_screens.dart';
import 'product/product_models.dart';
import 'product/irs_scenario_models.dart';
import 'product/snapshots_screen.dart';
import 'product/app_error_state.dart';
import 'product/app_failure.dart';

const _taxyViolet = Color(0xFF6557E8);
const _taxyInk = Color(0xFF17172B);
const _taxyMint = Color(0xFF69E0B4);
const _taxyCream = Color(0xFFF6F5FA);

AppLocalizations _appLocalizations(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    AppLocalizationsPt('pt_PT');

String _localizedRegion(AppLocalizations l10n, TaxRegion region) =>
    switch (region) {
      TaxRegion.continent => l10n.mainlandPortugal,
      TaxRegion.madeira => l10n.madeira,
      TaxRegion.azores => l10n.azores,
    };

String _localizedCivilStatus(AppLocalizations l10n, CivilStatus status) =>
    switch (status) {
      CivilStatus.single => l10n.single,
      CivilStatus.married => l10n.married,
      CivilStatus.deFacto => l10n.deFactoUnion,
    };

String _localizedMoney(
  BuildContext context,
  Money value, {
  bool signed = false,
}) {
  if (!signed || value.cents == 0) {
    return TaxyFormatters.euros(context, value.cents);
  }
  final prefix = value.cents > 0 ? '+' : '−';
  return '$prefix${TaxyFormatters.euros(context, value.cents.abs())}';
}

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
  final theme = ThemeController(LocalThemePreferenceStore());
  await language.load();
  await theme.load();
  runApp(
    ProviderScope(
      child: TaxyApp(languageController: language, themeController: theme),
    ),
  );
}

final class TaxyApp extends StatefulWidget {
  const TaxyApp({super.key, this.languageController, this.themeController});

  final LanguageController? languageController;
  final ThemeController? themeController;

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
  late final ThemeController _themeController =
      widget.themeController ?? ThemeController(MemoryThemePreferenceStore());
  late final bool _ownsTheme = widget.themeController == null;

  @override
  void dispose() {
    if (_ownsLanguage) _language.dispose();
    if (_ownsTheme) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _language,
    child: ThemeScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: Listenable.merge([_language, _themeController]),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: _language.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: resolveTaxyLocale,
          themeMode: _themeController.mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomeScreen(),
        ),
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
    builder: (_) => SettingsScreen(
      languageController: LanguageScope.of(context),
      themeController: ThemeScope.of(context),
    ),
  ),
);

Future<void> _openFiscalProfile(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FiscalProfileScreen()),
);

Future<void> _openIncome(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const IncomeScreen()),
);

Future<void> _openExpenses(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
);

Future<void> _openSnapshots(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SnapshotsScreen()),
);

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final simulations = ref.watch(simulationsProvider);
    final savedDraft = ref.watch(simulationDraftProvider);
    return Scaffold(
      body: SafeArea(
        child: rules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppErrorState(
            failure: const AppFailure(AppFailureKind.localDataError),
            onRetry: () => ref.invalidate(rulesProvider),
          ),
          data: (ruleSet) => savedDraft.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => simulations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AppErrorState(
                failure: const AppFailure(AppFailureKind.localDataError),
                onRetry: () {
                  ref.invalidate(simulationsProvider);
                  ref.invalidate(simulationDraftProvider);
                },
              ),
              data: (items) => items.isEmpty
                  ? _Welcome(rules: ruleSet, hasDraft: false)
                  : _DashboardRuleLoader(simulations: items, hasDraft: false),
            ),
            data: (draft) => simulations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AppErrorState(
                failure: const AppFailure(AppFailureKind.localDataError),
                onRetry: () => ref.invalidate(simulationsProvider),
              ),
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
    final profile = simulations.first.profile;
    final rules = ref.watch(
      rulesForProvider((year: profile.taxYear, region: profile.region)),
    );
    return rules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => AppErrorState(
        failure: const AppFailure(AppFailureKind.localDataError),
        onRetry: () => ref.invalidate(
          rulesForProvider((year: profile.taxYear, region: profile.region)),
        ),
      ),
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
    final l10n = _appLocalizations(context);
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
                    onOpenProfile: () => _openFiscalProfile(context),
                    onOpenIncome: () => _openIncome(context),
                    onOpenExpenses: () => _openExpenses(context),
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
    final l10n = _appLocalizations(context);
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
                  l10n.dashboardTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.simulationUpdatedForYear(rules.taxYear),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasDraft) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _openWizard(context, rules),
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(l10n.resumeDraft),
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
                        label: l10n.viewCalculation,
                        onTap: () => _openResult(context, latest, rules),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.tune_rounded,
                        label: l10n.change,
                        onTap: () =>
                            _openWizard(context, rules, source: latest),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.compare_arrows_rounded,
                        label: l10n.compare,
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
                    label: Text(l10n.exploreTaxOpportunities),
                  ),
                ],
                if (EfaturaFeatureFlags.experimental) ...[
                  const SizedBox(height: 22),
                  Card(
                    child: ListTile(
                      key: const Key('efatura-dashboard-entry'),
                      leading: const Icon(Icons.receipt_outlined),
                      title: Text(l10n.efaturaTitle),
                      subtitle: Text(l10n.readOnlyExperimental),
                      trailing: Chip(label: Text(l10n.experimental)),
                      onTap: () => _openEfatura(context),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addIncome),
                      onPressed: () => _openIncome(context),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addExpense),
                      onPressed: () => _openExpenses(context),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.compare_arrows, size: 18),
                      label: Text(l10n.scenarioComparison),
                      onPressed: result.available
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
                    ActionChip(
                      avatar: const Icon(Icons.bookmarks_outlined, size: 18),
                      label: Text(l10n.savedEstimates),
                      onPressed: () => _openSnapshots(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(l10n.fiscalProfile),
                        subtitle: Text(l10n.profileModuleDescription),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openFiscalProfile(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(l10n.income),
                        subtitle: Text(l10n.incomeModuleDescription),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openIncome(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined),
                        title: Text(l10n.expenses),
                        subtitle: Text(l10n.expensesModuleDescription),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openExpenses(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bookmarks_outlined),
                        title: Text(l10n.savedEstimates),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openSnapshots(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.yourSimulations,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.savedSimulationCount(simulations.length),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _openWizard(context, rules, resumeDraft: false),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.newSimulation),
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
                              ? l10n.refundAmount(
                                  _localizedMoney(context, itemResult.balance),
                                )
                              : l10n.taxDueAmount(
                                  _localizedMoney(context, -itemResult.balance),
                                ))
                        : l10n.calculationUnavailable,
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: l10n.options,
                    onSelected: (action) => _manage(context, ref, item, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: const Icon(Icons.drive_file_rename_outline),
                          title: Text(l10n.rename),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: const Icon(Icons.copy_rounded),
                          title: Text(l10n.duplicate),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.tune_rounded),
                          title: Text(l10n.changeData),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline_rounded),
                          title: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
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
          name: l10n.copySimulationName(simulation.name),
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
          title: Text(l10n.renameSimulation),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.save),
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
          title: Text(l10n.deleteSimulationTitle),
          content: Text(l10n.deleteSimulationMessage(simulation.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
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
  final screenProtection = AndroidEfaturaScreenProtection();
  final backendBridge = BackendEfaturaRuntimeBridge(
    baseUri: EfaturaApiConfiguration.baseUri,
    sessionTokenStore: SecureEfaturaSessionTokenStore(),
    screenProtection: screenProtection,
  );
  final screen = EfaturaScreen(
    service: EfaturaReadOnlyService(
      backendBridge,
      backendBridge,
      backendBridge,
    ),
    provisioning: backendBridge,
  );
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
        error = _appLocalizations(context).draftRestoreError;
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
    final l10n = _appLocalizations(context);
    final localizedStep = current.id == 'gross'
        ? (draft.incomeEntryMode == IncomeEntryMode.annual
              ? 'grossAnnual'
              : 'grossMonthly')
        : current.id;
    final progress = (index + 1) / steps.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
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
                      l10n.wizardSection(current.section.name).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.wizardStepTitle(localizedStep),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.wizardStepHelper(localizedStep),
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
                  current.id == 'review'
                      ? l10n.calculateEstimate
                      : l10n.continueAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(String id) {
    final l10n = _appLocalizations(context);
    return switch (id) {
      'taxYear' => _ChoiceGroup<int>(
        value: draft.taxYear,
        options: [
          (2025, '2025', l10n.wizardText('year2025Helper')),
          (2026, '2026', l10n.wizardText('currentYear')),
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
        options: [
          (
            CivilStatus.single,
            l10n.wizardText('singleStatus'),
            l10n.wizardText('individualAssessment'),
          ),
          (
            CivilStatus.married,
            l10n.wizardText('marriedStatus'),
            l10n.wizardText('compareJointSeparate'),
          ),
          (
            CivilStatus.deFacto,
            l10n.wizardText('deFactoStatus'),
            l10n.wizardText('compareJointSeparate'),
          ),
        ],
        onChanged: (v) => setState(() {
          draft.civilStatus = v;
          if (v == CivilStatus.single) draft.filingMode = FilingMode.separate;
        }),
      ),
      'residency' => _ChoiceGroup<bool>(
        value: draft.fullYearResident,
        options: [
          (true, l10n.yes, l10n.wizardText('fullYearResident')),
          (false, l10n.no, l10n.wizardText('unsupportedCannotContinue')),
        ],
        onChanged: (v) => setState(() => draft.fullYearResident = v),
      ),
      'region' => _ChoiceGroup<TaxRegion>(
        value: draft.region,
        options: [
          (
            TaxRegion.continent,
            l10n.mainlandPortugal,
            l10n.wizardText('calculationAvailable'),
          ),
          (TaxRegion.madeira, l10n.madeira, l10n.wizardText('available2026')),
          (TaxRegion.azores, l10n.azores, l10n.wizardText('available2026')),
        ],
        onChanged: (v) => setState(() => draft.region = v),
      ),
      'incomeTypes' => Column(
        children: [
          for (final type in IncomeType.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: draft.incomeTypes.contains(type),
              title: Text(_incomeTypeLabel(l10n, type)),
              subtitle: type == IncomeType.employment
                  ? Text(l10n.wizardText('categoryAAvailable'))
                  : Text(l10n.wizardText('notAvailableYet')),
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
        options: [
          (false, l10n.no, l10n.wizardText('standardCase')),
          (
            true,
            l10n.wizardText('yesUnsure'),
            l10n.wizardText('calculationBlockedSafety'),
          ),
        ],
        onChanged: (value) => setState(() => draft.hasSpecialSituation = value),
      ),
      'irsJovemInterest' => Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.wizardText('checkIrsJovemA')),
            subtitle: Text(l10n.wizardText('eligibilityByHistory')),
            value: draft.wantsIrsJovemA,
            onChanged: (value) => setState(() => draft.wantsIrsJovemA = value),
          ),
          if (draft.civilStatus != CivilStatus.single)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.wizardText('checkIrsJovemB')),
              value: draft.wantsIrsJovemB,
              onChanged: (value) =>
                  setState(() => draft.wantsIrsJovemB = value),
            ),
        ],
      ),
      'irsJovemHistory' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.wizardText('historyFormat')),
          const SizedBox(height: 12),
          if (draft.wantsIrsJovemA) ...[
            TextFormField(
              initialValue: draft.irsJovemHistoryA,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.wizardText('historyA'),
                hintText: '2024,A,true,true,false\n2025,A,false,true,false',
              ),
              onChanged: (value) => draft.irsJovemHistoryA = value,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.wizardText('historyCompleteA')),
              value: draft.irsJovemHistoryCompleteA,
              onChanged: (value) =>
                  setState(() => draft.irsJovemHistoryCompleteA = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.wizardText('taxRegularA')),
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
              decoration: InputDecoration(
                labelText: l10n.wizardText('historyB'),
              ),
              onChanged: (value) => draft.irsJovemHistoryB = value,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.wizardText('historyCompleteB')),
              value: draft.irsJovemHistoryCompleteB,
              onChanged: (value) =>
                  setState(() => draft.irsJovemHistoryCompleteB = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.wizardText('taxRegularB')),
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
        options: [
          (
            FilingMode.separate,
            l10n.wizardText('separate'),
            l10n.wizardText('separateFirst'),
          ),
          (
            FilingMode.joint,
            l10n.wizardText('joint'),
            l10n.wizardText('maritalQuotient'),
          ),
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
        options: [
          (true, l10n.yes, l10n.wizardText('standardSingleParent')),
          (
            false,
            l10n.wizardText('noUnsure'),
            l10n.wizardText('calculationBlockedSafety'),
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
                      l10n.dependentNumber(i + 1),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      initialValue: draft.dependentAges[i],
                      decoration: InputDecoration(suffixText: l10n.yearsSuffix),
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
        options: [
          (
            IncomeEntryMode.annual,
            l10n.wizardText('annualTotal'),
            l10n.wizardText('oneAnnualValue'),
          ),
          (
            IncomeEntryMode.monthly,
            l10n.wizardText('monthlyTimesMonths'),
            l10n.wizardText('appCalculatesAnnual'),
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
                ? l10n.wizardText('annualIncome')
                : l10n.wizardText('monthlyIncome'),
            onChanged: (v) => draft.incomeEntryMode == IncomeEntryMode.annual
                ? draft.gross = v
                : draft.monthly = v,
          ),
          if (draft.incomeEntryMode == IncomeEntryMode.monthly) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: draft.months,
              decoration: InputDecoration(
                labelText: l10n.wizardText('paymentCount'),
              ),
              items: [
                for (var n = 1; n <= 14; n++)
                  DropdownMenuItem(value: n, child: Text(l10n.monthCount(n))),
              ],
              onChanged: (v) => setState(() => draft.months = v ?? 14),
            ),
          ],
        ],
      ),
      'withholding' => _MoneyField(
        value: draft.withholding,
        label: l10n.wizardText('annualWithholding'),
        onChanged: (v) => draft.withholding = v,
      ),
      'socialSecurity' => _MoneyField(
        value: draft.socialSecurity,
        label: l10n.wizardText('annualContributions'),
        onChanged: (v) => draft.socialSecurity = v,
      ),
      'secondaryGross' => _MoneyField(
        value: draft.secondaryGross,
        label: l10n.wizardText('secondaryAnnualIncome'),
        onChanged: (value) => draft.secondaryGross = value,
      ),
      'secondaryWithholding' => _MoneyField(
        value: draft.secondaryWithholding,
        label: l10n.wizardText('secondaryAnnualWithholding'),
        onChanged: (value) => draft.secondaryWithholding = value,
      ),
      'secondarySocialSecurity' => _MoneyField(
        value: draft.secondarySocialSecurity,
        label: l10n.wizardText('secondaryAnnualContributions'),
        onChanged: (value) => draft.secondarySocialSecurity = value,
      ),
      'general' => _MoneyField(
        value: draft.general,
        label: l10n.wizardText('generalExpensesTotal'),
        hint: 'Ex.: 1.200,00',
        onChanged: (v) => draft.general = v,
      ),
      'health' => _MoneyField(
        value: draft.health,
        label: l10n.wizardText('healthTotal'),
        onChanged: (v) => draft.health = v,
      ),
      'education' => _MoneyField(
        value: draft.education,
        label: l10n.wizardText('eligibleEducation'),
        hint: l10n.wizardText('educationExclusions'),
        onChanged: (v) => draft.education = v,
      ),
      'rent' => _MoneyField(
        value: draft.rent,
        label: l10n.wizardText('annualRent'),
        onChanged: (v) => draft.rent = v,
      ),
      'careHomes' => _MoneyField(
        value: draft.careHomes,
        label: l10n.wizardText('annualCharges'),
        onChanged: (v) => draft.careHomes = v,
      ),
      'invoiceVat15' => _MoneyField(
        value: draft.invoiceVat15,
        label: l10n.wizardText('vat15'),
        onChanged: (v) => draft.invoiceVat15 = v,
      ),
      'invoiceVat30' => _MoneyField(
        value: draft.invoiceVat30,
        label: l10n.wizardText('vat30'),
        onChanged: (v) => draft.invoiceVat30 = v,
      ),
      'invoiceVat35' => _MoneyField(
        value: draft.invoiceVat35,
        label: l10n.wizardText('vat35'),
        onChanged: (v) => draft.invoiceVat35 = v,
      ),
      'invoiceVat100' => _MoneyField(
        value: draft.invoiceVat100,
        label: l10n.wizardText('vat100'),
        onChanged: (v) => draft.invoiceVat100 = v,
      ),
      'ppr' => _MoneyField(
        value: draft.ppr,
        label: l10n.wizardText('annualPpr'),
        onChanged: (v) => draft.ppr = v,
      ),
      'secondaryDeductions' => Column(
        children: [
          _MoneyField(
            value: draft.secondaryGeneral,
            label: l10n.wizardText('secondaryGeneral'),
            onChanged: (v) => draft.secondaryGeneral = v,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            value: draft.secondaryHealth,
            label: l10n.wizardText('secondaryHealth'),
            onChanged: (v) => draft.secondaryHealth = v,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            value: draft.secondaryEducation,
            label: l10n.wizardText('secondaryEducation'),
            onChanged: (v) => draft.secondaryEducation = v,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            value: draft.secondaryRent,
            label: l10n.wizardText('secondaryRent'),
            onChanged: (v) => draft.secondaryRent = v,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            value: draft.secondaryCareHomes,
            label: l10n.wizardText('secondaryCareHomes'),
            onChanged: (v) => draft.secondaryCareHomes = v,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            value: draft.secondaryPpr,
            label: l10n.wizardText('secondaryPpr'),
            onChanged: (v) => draft.secondaryPpr = v,
          ),
        ],
      ),
      'review' => _ReviewCard(draft: draft, onEdit: _editSection),
      _ => const SizedBox.shrink(),
    };
  }

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
        error = _appLocalizations(context).draftSaveError;
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
    final l10n = _appLocalizations(context);
    if (id == 'residency' && !draft.fullYearResident) {
      return l10n.partialResidenceError;
    }
    if (id == 'region' &&
        draft.taxYear == 2025 &&
        draft.region != TaxRegion.continent) {
      return l10n.regionalYearError;
    }
    if (id == 'incomeTypes' &&
        (draft.incomeTypes.isEmpty ||
            draft.incomeTypes.any((type) => type != IncomeType.employment))) {
      return l10n.incomeScopeError;
    }
    if (id == 'specialSituations' && draft.hasSpecialSituation) {
      return l10n.specialSituationError;
    }
    if (id == 'irsJovemHistory') {
      if (draft.wantsIrsJovemA &&
          (draft.irsJovemHistoryA.trim().isEmpty ||
              !draft.irsJovemHistoryCompleteA)) {
        return l10n.historyAError;
      }
      if (draft.wantsIrsJovemB &&
          (draft.irsJovemHistoryB.trim().isEmpty ||
              !draft.irsJovemHistoryCompleteB)) {
        return l10n.historyBError;
      }
    }
    if (id == 'singleParent' && !draft.isSingleParentHousehold) {
      return l10n.singleParentScopeError;
    }
    if (id == 'gross') {
      final value = draft.incomeEntryMode == IncomeEntryMode.annual
          ? draft.gross
          : draft.monthly;
      if (_money(value).cents <= 0) {
        return l10n.positiveIncomeError;
      }
    }
    if (id == 'secondaryGross' && _money(draft.secondaryGross).cents < 0) {
      return l10n.secondaryIncomeError;
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
      final product = await ref.read(productStateProvider.future);
      await ref
          .read(productRepositoryProvider)
          .save(
            product.copyWith(
              profile: FiscalProfile(
                activeTaxYear: simulation.profile.taxYear,
                region: simulation.profile.region,
                civilStatus: simulation.profile.civilStatus,
                dependentCount: simulation.profile.dependents,
                hasEmployment: simulation.incomeTypes.contains(
                  IncomeType.employment,
                ),
                hasSelfEmployment: simulation.incomeTypes.contains(
                  IncomeType.selfEmployment,
                ),
              ),
            ),
          );
      ref.invalidate(productStateProvider);
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
        error = _appLocalizations(context).moneyValuesError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = _appLocalizations(context).calculationSafetyError;
      });
    }
  }

  String _incomeTypeLabel(AppLocalizations l10n, IncomeType type) =>
      l10n.incomeTypeName(type.name);
}

final class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.simulation,
    required this.rules,
  });
  final TaxSimulation simulation;
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
      appBar: AppBar(title: Text(l10n.legacyUiText('estimateTitle'))),
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
                      Text(
                        '${l10n.legacyUiText('normalIrs')}: ${_localizedMoney(context, singleJovem.normal.taxDue)}',
                      ),
                      if (singleJovem.withIrsJovem != null) ...[
                        Text(
                          'IRS Jovem: ${_localizedMoney(context, singleJovem.withIrsJovem!.taxDue)}',
                        ),
                        Text(
                          '${l10n.legacyUiText('estimatedTaxBenefit')}: ${_localizedMoney(context, singleJovem.estimatedBenefit)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${singleJovem.eligibility.relevantIncomeYear}.º ano · '
                          '${singleJovem.eligibility.exemptionRatePpm / 10000}% · '
                          'limite ${_localizedMoney(context, singleJovem.eligibility.exemptionLimit)} · '
                          'isento ${_localizedMoney(context, singleJovem.adjustment!.exemptIncome)}',
                        ),
                      ] else
                        Text(singleJovem.eligibility.reasons.join(' ')),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(l10n.legacyUiText('whyEligible')),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              singleJovem.eligibility.reasons.isEmpty
                                  ? l10n.legacyUiText('eligibilityDefault')
                                  : singleJovem.eligibility.reasons.join(' '),
                            ),
                          ),
                        ],
                      ),
                    ] else if (householdJovem != null) ...[
                      Text(
                        '${l10n.legacyUiText('separateWithoutJovem')}: ${_localizedMoney(context, householdJovem.normal.separate!.taxDue)}',
                      ),
                      Text(
                        '${l10n.legacyUiText('jointWithoutJovem')}: ${_localizedMoney(context, householdJovem.normal.joint!.taxDue)}',
                      ),
                      if (householdJovem.withIrsJovem != null) ...[
                        Text(
                          '${l10n.legacyUiText('separateWithJovem')}: ${_localizedMoney(context, householdJovem.withIrsJovem!.separate!.taxDue)}',
                        ),
                        Text(
                          '${l10n.legacyUiText('jointWithJovem')}: ${_localizedMoney(context, householdJovem.withIrsJovem!.joint!.taxDue)}',
                        ),
                        Text(
                          '${l10n.legacyUiText('estimatedBestBenefit')}: ${_localizedMoney(context, householdJovem.estimatedBenefit)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ] else
                        Text(householdJovem.warnings.join(' ')),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(l10n.legacyUiText('whyEligiblePlural')),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.legacyUiText('taxpayerA')}: ${householdJovem.primaryEligibility.reasons.join(' ')}\n'
                              '${l10n.legacyUiText('taxpayerB')}: ${householdJovem.secondaryEligibility.reasons.join(' ')}',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(l10n.legacyUiText('estimateDisclaimer')),
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
                      l10n.legacyUiText('taxComparison'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.legacyUiText('separateTaxation')),
                    const SizedBox(height: 4),
                    Text(
                      _localizedMoney(context, household!.separate!.taxDue),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.legacyUiText('jointTaxation')),
                    const SizedBox(height: 4),
                    Text(
                      _localizedMoney(context, household.joint!.taxDue),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.legacyUiText('difference')),
                    Text(
                      _localizedMoney(context, household.difference),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.legacyUiText('estimatedBestOption')),
                    Text(
                      household.difference.cents == 0
                          ? l10n.legacyUiText('noEstimatedDifference')
                          : household.recommendedMode == FilingMode.joint
                          ? l10n.legacyUiText('jointTaxation')
                          : l10n.legacyUiText('separateTaxation'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      household.difference.cents == 0
                          ? l10n.legacyUiText('equalTax')
                          : household.recommendedMode == FilingMode.joint
                          ? l10n.legacyUiText('jointLower')
                          : l10n.legacyUiText('separateLower'),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.legacyUiText('officialDisclaimer')),
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
              Chip(label: Text(l10n.legacyUiText('categoryA'))),
              Chip(
                label: Text(
                  simulation.profile.civilStatus == CivilStatus.single
                      ? l10n.legacyUiText('individualTaxpayer')
                      : '${simulation.profile.civilStatus.name} · ${simulation.profile.filingMode.name}',
                ),
              ),
              Chip(
                label: Text(
                  '${l10n.legacyUiText('rules')} ${rules.rulesVersion}',
                ),
              ),
              if (jovemRequested)
                Chip(
                  label: Text(
                    (singleJovem?.applied ??
                            (householdJovem?.withIrsJovem != null))
                        ? l10n.legacyUiText('jovemApplied')
                        : l10n.legacyUiText('jovemNotApplied'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.estimateBasis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _EstimateInputRow(
                    label: l10n.incomeConsidered,
                    value: _localizedMoney(context, simulation.income.gross),
                    source: l10n.userEnteredSource,
                  ),
                  _EstimateInputRow(
                    label: l10n.deductionsConsidered,
                    value: result.available
                        ? _localizedMoney(context, result.taxCredits)
                        : l10n.unavailable,
                    source: l10n.userEnteredSource,
                  ),
                  _EstimateInputRow(
                    label: l10n.withholdingConsidered,
                    value: _localizedMoney(
                      context,
                      simulation.income.withholding,
                    ),
                    source: l10n.userEnteredSource,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.available
                        ? l10n.estimateNotOfficial
                        : l10n.missingInformationImprove,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result.available) ...[
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: l10n.legacyUiText('taxableIncome'),
                    value: _localizedMoney(context, result.taxableIncome),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: l10n.legacyUiText('retainedYear'),
                    value: _localizedMoney(context, result.withholding),
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
              label: Text(l10n.legacyUiText('compareScenario')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _saveSnapshot(context, ref, result),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.saveEstimate),
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
              label: Text(l10n.legacyUiText('viewOpportunities')),
            ),
            const SizedBox(height: 20),
            Card(
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  l10n.legacyUiText('detailedCalculation'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  l10n.legacyUiText('detailedCalculationSubtitle'),
                ),
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
                        _localizedMoney(
                          context,
                          result.breakdown[i].amount,
                          signed: true,
                        ),
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
                  ? l10n.legacyUiText('limitsWarning')
                  : l10n.legacyUiText('calculationUnavailable'),
              messages: result.warnings,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: 20),
          NoticeCard(
            title: l10n.legacyUiText('simulationAssumptions'),
            messages: result.assumptions,
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.legacyUiText('officialDisclaimer'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.verifiedRulesScope(
              rules.rulesVersion,
              MaterialLocalizations.of(context)
                  .formatCompactDate(rules.verifiedAt),
            ),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _saveSnapshot(
    BuildContext context,
    WidgetRef ref,
    TaxResult result,
  ) async {
    final savedEstimateLabel = AppLocalizations.of(context).savedEstimate;
    final now = DateTime.now();
    final current = await ref.read(productStateProvider.future);
    final snapshot = IrsSnapshot(
      id: now.microsecondsSinceEpoch.toString(),
      label: '$savedEstimateLabel ${simulation.profile.taxYear}',
      createdAt: now,
      taxYear: simulation.profile.taxYear,
      calculationModelVersion: rules.rulesVersion,
      inputSchemaVersion: 1,
      simulation: simulation,
      balanceCents: result.balance.cents,
      grossIncomeCents: result.grossIncome.cents,
      withholdingCents: result.withholding.cents,
      taxCreditsCents: result.taxCredits.cents,
    );
    await ref
        .read(productRepositoryProvider)
        .save(current.copyWith(snapshots: [...current.snapshots, snapshot]));
    ref.invalidate(productStateProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).estimateSaved)),
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
  late int grossIncomeCents = widget.simulation.income.gross.cents;
  late int withholdingCents = widget.simulation.income.withholding.cents;
  late int pprCents = widget.simulation.deductions.ppr.cents;
  late int healthCents = widget.simulation.deductions.health.cents;
  late int educationCents = widget.simulation.deductions.education.cents;
  late int rentCents = widget.simulation.deductions.rent.cents;
  late int generalCents = widget.simulation.deductions.general.cents;

  ScenarioOverrides get overrides => ScenarioOverrides(
    grossIncomeCents: grossIncomeCents,
    withholdingCents: withholdingCents,
    pprCents: pprCents,
    healthExpensesCents: healthCents,
    educationExpensesCents: educationCents,
    rentExpensesCents: rentCents,
    generalExpensesCents: generalCents,
  );

  TaxSimulation get changedSimulation => overrides.applyTo(widget.simulation);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final original = _calculateSimulation(widget.simulation, widget.rules);
    final changed = _calculateSimulation(changedSimulation, widget.rules);
    final difference = changed.balance - original.balance;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scenarioComparison)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            l10n.scenarioComparison,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.scenarioIntro,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          _ScenarioSlider(
            label: l10n.incomeConsidered,
            helper: l10n.scenarioOverrideNotice,
            cents: grossIncomeCents,
            maxCents: (widget.simulation.income.gross.cents * 2)
                .clamp(100000, 50000000)
                .toInt(),
            onChanged: (v) => setState(() => grossIncomeCents = v),
          ),
          _ScenarioSlider(
            label: l10n.withholdingConsidered,
            helper: l10n.scenarioOverrideNotice,
            cents: withholdingCents,
            maxCents: (widget.simulation.income.withholding.cents * 2)
                .clamp(100000, 10000000)
                .toInt(),
            onChanged: (v) => setState(() => withholdingCents = v),
          ),
          _ScenarioSlider(
            label: l10n.legacyUiText('ppr'),
            helper: l10n.legacyUiText('annualApplied'),
            cents: pprCents,
            maxCents: 500000,
            onChanged: (v) => setState(() => pprCents = v),
          ),
          _ScenarioSlider(
            label: l10n.legacyUiText('health'),
            helper: l10n.legacyUiText('eligibleExpenses'),
            cents: healthCents,
            maxCents: 800000,
            onChanged: (v) => setState(() => healthCents = v),
          ),
          _ScenarioSlider(
            label: l10n.legacyUiText('education'),
            helper: l10n.legacyUiText('eligibleExpenses'),
            cents: educationCents,
            maxCents: 500000,
            onChanged: (v) => setState(() => educationCents = v),
          ),
          _ScenarioSlider(
            label: l10n.legacyUiText('rent'),
            helper: l10n.legacyUiText('eligibleRents'),
            cents: rentCents,
            maxCents: 1500000,
            onChanged: (v) => setState(() => rentCents = v),
          ),
          _ScenarioSlider(
            label: l10n.legacyUiText('generalExpenses'),
            helper: l10n.legacyUiText('nifInvoice'),
            cents: generalCents,
            maxCents: 300000,
            onChanged: (v) => setState(() => generalCents = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScenarioCard(
                  label: l10n.currentScenario,
                  ppr: widget.simulation.deductions.ppr,
                  result: original,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScenarioCard(
                  label: l10n.alternativeScenario,
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
                  Expanded(
                    child: Text(
                      l10n.resultDifference,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    _localizedMoney(context, difference, signed: true),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatChanged,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (overrides.changesFrom(widget.simulation).isEmpty)
                    Text(l10n.noScenarioChanges)
                  else
                    for (final change in overrides.changesFrom(
                      widget.simulation,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${change.field}: ${_localizedMoney(context, Money.fromCents(change.differenceCents), signed: true)}',
                        ),
                      ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.scenarioOverrideNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: difference.cents == 0 ? null : _saveScenario,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.legacyUiText('saveNewSimulation')),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.legacyUiText('pprDisclaimer'),
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
      name:
          '${widget.simulation.name} — ${AppLocalizations.of(context).legacyUiText('compareScenario')}',
      updatedAt: now,
    );
    await ref.read(repositoryProvider).save(saved);
    ref.invalidate(simulationsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).legacyUiText('scenarioSaved'),
        ),
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
    final l10n = AppLocalizations.of(context);
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
        l10n.legacyUiText('ppr'),
        l10n.legacyUiText('pprDisclaimer'),
        Icons.savings_outlined,
        d.ppr,
        pprTarget,
        (x, value) => x.copyWith(ppr: value),
      ),
      _OpportunityCandidate(
        l10n.legacyUiText('generalExpenses'),
        l10n.legacyUiText('nifInvoice'),
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
        l10n.legacyUiText('health'),
        l10n.legacyUiText('realExpensesOnly'),
        Icons.health_and_safety_outlined,
        d.health,
        target('healthCapCents', 'healthRatePpm'),
        (x, value) => x.copyWith(health: value),
      ),
      _OpportunityCandidate(
        l10n.legacyUiText('education'),
        l10n.legacyUiText('eligibleExpenses'),
        Icons.school_outlined,
        d.education,
        target('educationCapCents', 'educationRatePpm'),
        (x, value) => x.copyWith(education: value),
      ),
      _OpportunityCandidate(
        l10n.legacyUiText('rent'),
        l10n.legacyUiText('eligibleRents'),
        Icons.home_outlined,
        d.rent,
        target('rentFloorCapCents', 'rentRatePpm'),
        (x, value) => x.copyWith(rent: value),
      ),
      _OpportunityCandidate(
        l10n.sectorNursingHomes,
        l10n.legacyUiText('eligibleExpenses'),
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
      appBar: AppBar(title: Text(l10n.legacyUiText('opportunities'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
        children: [
          Text(
            l10n.legacyUiText('whereMargin'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.legacyUiText('opportunitiesIntro'),
            style: TextStyle(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          if (opportunities.isEmpty)
            NoticeCard(
              title: l10n.legacyUiText('noExtraOpportunities'),
              messages: [l10n.legacyUiText('limitsReached')],
              icon: Icons.task_alt_rounded,
            )
          else
            for (final opportunity in opportunities) ...[
              _OpportunityCard(result: opportunity),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 10),
          NoticeCard(
            title: l10n.legacyUiText('important'),
            icon: Icons.info_outline_rounded,
            messages: [
              l10n.legacyUiText('upToDisclaimer'),
              l10n.legacyUiText('dontSpend'),
              l10n.legacyUiText('realExpensesOnly'),
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
    final l10n = AppLocalizations.of(context);
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
                        l10n.upToAdditional(
                          _localizedMoney(context, result.delta),
                        ),
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
                    l10n.enteredExpenseMargin(
                      _localizedMoney(context, missing),
                    ),
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

final class _EstimateInputRow extends StatelessWidget {
  const _EstimateInputRow({
    required this.label,
    required this.value,
    required this.source,
  });
  final String label;
  final String value;
  final String source;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(source, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

final class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.result, required this.year, this.onTap});
  final TaxResult result;
  final int year;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                          ? l10n.estimatedRefund
                          : l10n.estimatedAdditionalTax)
                    : l10n.estimateUnavailable,
                style: TextStyle(
                  color: result.available ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.available
                    ? _localizedMoney(
                        context,
                        positive ? result.balance : -result.balance,
                      )
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
                      l10n.openDetails,
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
    final l10n = AppLocalizations.of(context);
    String safe(String value) {
      try {
        return _localizedMoney(context, Money.parseEuros(value));
      } on FormatException {
        return _localizedMoney(context, Money.zero);
      }
    }

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
          title: l10n.legacyUiText('fiscalScope'),
          onEdit: () => onEdit(QuestionSection.eligibility),
          rows: [
            (
              l10n.legacyUiText('yearAndRegion'),
              '${draft.taxYear} · ${_localizedRegion(l10n, draft.region)}',
            ),
            (
              l10n.legacyUiText('household'),
              '${_localizedCivilStatus(l10n, draft.civilStatus)} · ${l10n.wizardText(draft.filingMode == FilingMode.joint ? 'joint' : 'separate')}',
            ),
            (
              'IRS Jovem',
              draft.wantsIrsJovemA || draft.wantsIrsJovemB
                  ? l10n.legacyUiText('pendingReview')
                  : l10n.legacyUiText('notRequested'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.legacyUiText('profileHousehold'),
          onEdit: () => onEdit(QuestionSection.profile),
          rows: [
            (
              l10n.legacyUiText('taxpayerA'),
              '${draft.age} ${l10n.yearsSuffix}',
            ),
            if (draft.civilStatus != CivilStatus.single)
              (
                l10n.legacyUiText('taxpayerB'),
                '${draft.secondaryAge} ${l10n.yearsSuffix}',
              ),
            (
              l10n.legacyUiText('dependants'),
              draft.dependentAges.isEmpty
                  ? l10n.legacyUiText('none')
                  : draft.dependentAges
                        .map((age) => '$age ${l10n.yearsSuffix}')
                        .join(', '),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.legacyUiText('incomeWithholding'),
          onEdit: () => onEdit(QuestionSection.income),
          rows: [
            (l10n.legacyUiText('incomeA'), gross),
            (l10n.legacyUiText('withholdingA'), safe(draft.withholding)),
            (l10n.legacyUiText('socialA'), safe(draft.socialSecurity)),
            if (draft.civilStatus != CivilStatus.single) ...[
              (l10n.legacyUiText('incomeB'), safe(draft.secondaryGross)),
              (
                l10n.legacyUiText('withholdingB'),
                safe(draft.secondaryWithholding),
              ),
              (
                l10n.legacyUiText('socialB'),
                safe(draft.secondarySocialSecurity),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.legacyUiText('deductionsEntered'),
          onEdit: () => onEdit(QuestionSection.deductions),
          rows: [
            (
              l10n.legacyUiText('totalA'),
              _localizedMoney(context, deductionsA),
            ),
            if (draft.civilStatus != CivilStatus.single)
              (
                l10n.legacyUiText('totalB'),
                _localizedMoney(context, deductionsB),
              ),
            (
              l10n.legacyUiText('education'),
              l10n.legacyUiText('standardEducationOnly'),
            ),
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
                label: Text(AppLocalizations.of(context).legacyUiText('edit')),
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
                  _localizedMoney(context, Money.fromCents(cents)),
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
              label: _localizedMoney(context, Money.fromCents(cents)),
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
            'PPR ${_localizedMoney(context, ppr)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(result.isRefund ? 'Reembolso' : 'A pagar'),
          const SizedBox(height: 4),
          Text(
            _localizedMoney(
              context,
              result.isRefund ? result.balance : -result.balance,
            ),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final highlights = <(String, IconData)>[
      ('5 min', Icons.timer_outlined),
      (l10n.privateLabel, Icons.lock_outline_rounded),
      (l10n.explainedLabel, Icons.lightbulb_outline_rounded),
    ];
    return Container(
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
              Expanded(
                child: Text(
                  l10n.legacyUiText('estimateTitle'),
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
          Text(
            l10n.previewClearAnswer,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          Text(
            l10n.previewTransparentAccounts,
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
              for (final item in highlights)
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
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.whatEstimateMeans,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  difference.cents >= 0
                      ? l10n.refundEstimateMeaning
                      : l10n.taxDueEstimateMeaning,
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
      Flexible(
        child: Text(
          'taxy.pt',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: compact ? 17 : 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
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
