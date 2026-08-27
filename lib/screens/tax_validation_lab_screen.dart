import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/money.dart';
import '../tax_engine/tax_engine.dart';
import '../tax_engine/household_tax_engine.dart';
import '../tax_engine/irs_jovem_eligibility_engine.dart';
import '../tax_engine/irs_jovem_tax_engine.dart';
import '../tax_engine/tax_rules.dart';

/// Ferramenta developer-only. A navegação para este ecrã é protegida por
/// [kDebugMode], portanto não surge numa build de produção normal.
final class TaxValidationLabScreen extends StatefulWidget {
  const TaxValidationLabScreen({super.key, required this.rules});
  final TaxRuleSet rules;

  @override
  State<TaxValidationLabScreen> createState() => _TaxValidationLabScreenState();
}

final class _TaxValidationLabScreenState extends State<TaxValidationLabScreen> {
  final _values = <String, TextEditingController>{
    'gross': TextEditingController(text: '30000,00'),
    'withholding': TextEditingController(text: '4000,00'),
    'socialSecurity': TextEditingController(text: '3300,00'),
    'age': TextEditingController(text: '30'),
    'grossB': TextEditingController(),
    'withholdingB': TextEditingController(),
    'socialSecurityB': TextEditingController(),
    'ageB': TextEditingController(text: '30'),
    'dependents': TextEditingController(),
    'general': TextEditingController(),
    'health': TextEditingController(),
    'education': TextEditingController(),
    'rent': TextEditingController(),
    'careHomes': TextEditingController(),
    'ppr': TextEditingController(),
    'vat15': TextEditingController(),
    'vat30': TextEditingController(),
    'vat35': TextEditingController(),
    'vat100': TextEditingController(),
    'jovemHistoryA': TextEditingController(text: '2026,A,false,true,false'),
    'jovemHistoryB': TextEditingController(text: '2026,A,false,true,false'),
  };
  bool _singleParent = false;
  late TaxRuleSet _rules = widget.rules;
  late int _year = widget.rules.taxYear;
  late TaxRegion _region = TaxRegion.values.byName(
    widget.rules.jurisdiction.toLowerCase(),
  );
  CivilStatus _civilStatus = CivilStatus.single;
  FilingMode _filingMode = FilingMode.separate;
  bool _irsJovem = false;
  bool _historyCompleteA = true;
  bool _historyCompleteB = true;
  bool _regularizedA = true;
  bool _regularizedB = true;

  @override
  void dispose() {
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Money _money(String key) {
    try {
      return Money.parseEuros(_values[key]!.text);
    } on FormatException {
      return Money.zero;
    }
  }

  List<int> get _dependentAges => _values['dependents']!.text
      .split(',')
      .map((value) => int.tryParse(value.trim()))
      .whereType<int>()
      .toList(growable: false);

  List<IrsJovemIncomeYear> _history(String key) {
    final result = <IrsJovemIncomeYear>[];
    for (final rawLine in _values[key]!.text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final values = line.split(',').map((value) => value.trim()).toList();
      if (values.length != 5 || int.tryParse(values[0]) == null) continue;
      final income = values[1].toUpperCase();
      result.add(
        IrsJovemIncomeYear(
          year: int.parse(values[0]),
          hadCategoryAIncome: income.contains('A'),
          hadCategoryBIncome: income.contains('B'),
          wasDependent: values[2].toLowerCase() == 'true',
          residentInPortugal: values[3].toLowerCase() == 'true',
          usedIncompatibleRegime: values[4].toLowerCase() == 'true',
        ),
      );
    }
    return result;
  }

  IrsJovemAnswers _jovemAnswers({required bool secondary}) => IrsJovemAnswers(
    requested: _irsJovem,
    taxSituationRegularized: secondary ? _regularizedB : _regularizedA,
    historyConfirmedComplete: secondary ? _historyCompleteB : _historyCompleteA,
    incomeHistory: _history(secondary ? 'jovemHistoryB' : 'jovemHistoryA'),
  );

  TaxSimulation get _simulation => TaxSimulation(
    id: 'validation-lab',
    name: 'Tax Validation Lab',
    createdAt: DateTime.utc(_rules.taxYear),
    updatedAt: DateTime.utc(_rules.taxYear),
    profile: TaxpayerProfile(
      taxYear: _rules.taxYear,
      age: int.tryParse(_values['age']!.text) ?? 30,
      civilStatus: _civilStatus,
      dependentAges: _dependentAges,
      fullYearResident: true,
      region: _region,
      filingMode: _filingMode,
      isSingleParentHousehold:
          _civilStatus == CivilStatus.single && _singleParent,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: _money('gross'),
      withholding: _money('withholding'),
      socialSecurity: _money('socialSecurity'),
    ),
    deductions: DeductionInput(
      general: _money('general'),
      health: _money('health'),
      education: _money('education'),
      rent: _money('rent'),
      careHomes: _money('careHomes'),
      ppr: _money('ppr'),
      invoiceVat15: _money('vat15'),
      invoiceVat30: _money('vat30'),
      invoiceVat35: _money('vat35'),
      invoiceVat100: _money('vat100'),
    ),
    dependents: [
      for (var i = 0; i < _dependentAges.length; i++)
        Dependent(id: 'lab-$i', ageAtYearEnd: _dependentAges[i]),
    ],
    primaryIrsJovem: _jovemAnswers(secondary: false),
    secondaryTaxpayer: _civilStatus == CivilStatus.single
        ? null
        : TaxpayerInput(
            id: 'B',
            age: int.tryParse(_values['ageB']!.text) ?? 30,
            income: EmploymentIncome(
              entryMode: IncomeEntryMode.annual,
              gross: _money('grossB'),
              withholding: _money('withholdingB'),
              socialSecurity: _money('socialSecurityB'),
            ),
            deductions: const DeductionInput(),
            irsJovem: _jovemAnswers(secondary: true),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final normalHousehold = _civilStatus == CivilStatus.single
        ? null
        : HouseholdTaxEngine(_rules).compare(_simulation);
    final jovemHousehold = _civilStatus == CivilStatus.single || !_irsJovem
        ? null
        : HouseholdTaxEngine(_rules).compareWithIrsJovem(_simulation);
    final singleComparison = _civilStatus != CivilStatus.single || !_irsJovem
        ? null
        : IrsJovemTaxEngine(_rules).compare(_simulation);
    final result = normalHousehold?.available ?? false
        ? (_filingMode == FilingMode.joint
              ? normalHousehold!.joint!
              : normalHousehold!.separate!)
        : TaxEngine(_rules).calculate(_simulation);
    final jovem =
        singleComparison?.eligibility ??
        jovemHousehold?.primaryEligibility ??
        IrsJovemEligibilityEngine(_rules).evaluate(
          ageAtYearEnd: int.tryParse(_values['age']!.text) ?? 30,
          categoryAIncome: _money('gross'),
          answers: _jovemAnswers(secondary: false),
        );
    final jovemResult =
        singleComparison?.withIrsJovem ??
        (jovemHousehold?.withIrsJovem == null
            ? null
            : _filingMode == FilingMode.joint
            ? jovemHousehold!.withIrsJovem!.joint
            : jovemHousehold!.withIrsJovem!.separate);
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Validation Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Developer-only · regras ${_rules.rulesVersion}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          _section('Inputs suportados'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'Ano'),
                  items: const [
                    DropdownMenuItem(value: 2025, child: Text('2025')),
                    DropdownMenuItem(value: 2026, child: Text('2026')),
                  ],
                  onChanged: (value) => _changeRules(value ?? _year, _region),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<TaxRegion>(
                  initialValue: _region,
                  decoration: const InputDecoration(labelText: 'Região'),
                  items: [
                    for (final region in TaxRegion.values)
                      DropdownMenuItem(value: region, child: Text(region.name)),
                  ],
                  onChanged: (value) => _changeRules(_year, value ?? _region),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CivilStatus>(
            initialValue: _civilStatus,
            decoration: const InputDecoration(labelText: 'Estado civil'),
            items: [
              for (final status in CivilStatus.values)
                DropdownMenuItem(value: status, child: Text(status.name)),
            ],
            onChanged: (value) =>
                setState(() => _civilStatus = value ?? _civilStatus),
          ),
          if (_civilStatus != CivilStatus.single) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<FilingMode>(
              initialValue: _filingMode,
              decoration: const InputDecoration(labelText: 'Filing mode'),
              items: [
                for (final mode in FilingMode.values)
                  DropdownMenuItem(value: mode, child: Text(mode.name)),
              ],
              onChanged: (value) =>
                  setState(() => _filingMode = value ?? _filingMode),
            ),
          ],
          _input('Gross income', 'gross'),
          _input('Withholding', 'withholding'),
          _input('Social Security', 'socialSecurity'),
          _input('Age', 'age', money: false),
          if (_civilStatus != CivilStatus.single) ...[
            _input('Gross income B', 'grossB'),
            _input('Withholding B', 'withholdingB'),
            _input('Social Security B', 'socialSecurityB'),
            _input('Age B', 'ageB', money: false),
          ],
          _input(
            'Dependent ages (comma-separated)',
            'dependents',
            money: false,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Single-parent household'),
            value: _singleParent,
            onChanged: (value) => setState(() => _singleParent = value),
          ),
          _input('General expenses', 'general'),
          _input('Health', 'health'),
          _input('Education standard', 'education'),
          _input('Rent', 'rent'),
          _input('Care homes', 'careHomes'),
          _input('PPR', 'ppr'),
          _input('Invoice VAT 15%', 'vat15'),
          _input('Invoice VAT 30%', 'vat30'),
          _input('Invoice VAT 35%', 'vat35'),
          _input('Invoice VAT 100%', 'vat100'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('IRS Jovem eligibility check'),
            subtitle: Text(jovem.status.name),
            value: _irsJovem,
            onChanged: (value) => setState(() => _irsJovem = value),
          ),
          if (_irsJovem) ...[
            _historyInput('Histórico anual A', 'jovemHistoryA'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Histórico A completo'),
              value: _historyCompleteA,
              onChanged: (value) => setState(() => _historyCompleteA = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Situação tributária A regularizada'),
              value: _regularizedA,
              onChanged: (value) => setState(() => _regularizedA = value),
            ),
            if (_civilStatus != CivilStatus.single) ...[
              _historyInput('Histórico anual B', 'jovemHistoryB'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Histórico B completo'),
                value: _historyCompleteB,
                onChanged: (value) => setState(() => _historyCompleteB = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Situação tributária B regularizada'),
                value: _regularizedB,
                onChanged: (value) => setState(() => _regularizedB = value),
              ),
            ],
            Text(
              'Formato por linha: ano,A|B|AB|N,dependente,residente,regimeIncompatível',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          _section(result.available ? 'Audit trail' : 'Blocked safely'),
          if (!result.available)
            for (final warning in result.warnings)
              _row('Scope validation', warning)
          else ...[
            _moneyRow('Gross income', result.grossIncome),
            _moneyRow('Specific deduction', result.specificDeduction),
            _moneyRow(
              'Minimum existence allowance',
              result.minimumExistenceAllowance,
            ),
            _moneyRow('Taxable income', result.taxableIncome),
            _moneyRow('Bracket base tax', result.bracketBaseTax),
            _moneyRow('Bracket excess', result.bracketExcess),
            _row('Marginal rate', '${result.marginalRatePpm / 10000}%'),
            _moneyRow('Gross tax', result.grossTax),
            const Divider(height: 28),
            for (final credit in result.creditBreakdown)
              _moneyRow(credit.label, credit.amount),
            _row(
              'Overall deductions cap',
              result.overallDeductionsCap?.format() ?? 'Not applicable',
            ),
            _moneyRow('Tax credits applied', result.taxCredits),
            _moneyRow('Solidarity tax', result.solidarityTax),
            _moneyRow('Final tax due', result.taxDue),
            _moneyRow('Withholding', result.withholding),
            _moneyRow('Final balance', result.balance),
          ],
          if (_irsJovem) ...[
            const SizedBox(height: 20),
            _section('IRS Jovem audit'),
            _row('Eligibility', jovem.status.name),
            _row('Reason', jovem.reasons.join(' · ')),
            _row(
              'Relevant income year',
              jovem.relevantIncomeYear?.toString() ?? '—',
            ),
            _row('Exemption rate', '${jovem.exemptionRatePpm / 10000}%'),
            _moneyRow('55 IAS limit', jovem.exemptionLimit),
            _moneyRow('Eligible exempt income A', jovem.eligibleExemptIncome),
            if (singleComparison?.adjustment case final adjustment?) ...[
              _moneyRow('Taxable after exemption', adjustment.taxableIncome),
              _moneyRow(
                'Income determining rate',
                adjustment.rateDeterminingIncome,
              ),
              _moneyRow(
                'Tax allocated to exempt income',
                adjustment.taxOnExemptIncome,
              ),
            ],
            _moneyRow('Normal tax due', result.taxDue),
            if (jovemResult != null)
              _moneyRow('IRS Jovem tax due', jovemResult.taxDue),
            if (singleComparison != null)
              _moneyRow('Estimated benefit', singleComparison.estimatedBenefit)
            else if (jovemHousehold != null)
              _moneyRow(
                'Estimated best-case benefit',
                jovemHousehold.estimatedBenefit,
              ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _export(
              result,
              jovemResult,
              jovem,
              singleComparison?.adjustment,
              jovemHousehold,
            ),
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Export validation case'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRules(int year, TaxRegion region) async {
    if (year == 2025 && region != TaxRegion.continent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2025 regional permanece NEEDS_VERIFICATION.'),
        ),
      );
      return;
    }
    final repository = TaxRuleRepository(rootBundle.loadString);
    final loaded = await repository.load(year, region.name);
    if (!mounted) return;
    setState(() {
      _year = year;
      _region = region;
      _rules = loaded;
    });
  }

  Future<void> _export(
    TaxResult result,
    TaxResult? jovemResult,
    IrsJovemEligibilityResult jovem,
    IrsJovemTaxAdjustment? adjustment,
    HouseholdIrsJovemComparison? household,
  ) async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'rulesVersion': _rules.rulesVersion,
      'inputs': _simulation.toJson(),
      'outputs': {
        'taxableIncomeCents': result.taxableIncome.cents,
        'grossTaxCents': result.grossTax.cents,
        'deductionsCents': result.taxCredits.cents,
        'taxDueCents': result.taxDue.cents,
        'withholdingCents': result.withholding.cents,
        'balanceCents': result.balance.cents,
        'irsJovemEligibility': jovem.status.name,
        'irsJovemRelevantYear': jovem.relevantIncomeYear,
        'irsJovemRatePpm': jovem.exemptionRatePpm,
        'irsJovemLimitCents': jovem.exemptionLimit.cents,
        'irsJovemExemptIncomeCents':
            adjustment?.exemptIncome.cents ?? jovem.eligibleExemptIncome.cents,
        'irsJovemTaxableIncomeCents': jovemResult?.taxableIncome.cents,
        'irsJovemTaxDueCents': jovemResult?.taxDue.cents,
        'irsJovemBenefitCents': jovemResult == null
            ? null
            : (result.taxDue - jovemResult.taxDue).max(Money.zero).cents,
        'householdBestBenefitCents': household?.estimatedBenefit.cents,
      },
      'breakdown': [
        for (final row in result.breakdown)
          {'label': row.label, 'amountCents': row.amount.cents},
      ],
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caso JSON copiado para o clipboard.')),
    );
  }

  Widget _input(String label, String key, {bool money = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: _values[key],
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        suffixText: money ? '€' : null,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _historyInput(String label, String key) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: _values[key],
      minLines: 2,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _moneyRow(String label, Money value) => _row(label, value.format());

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
