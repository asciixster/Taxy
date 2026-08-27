import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/money.dart';
import '../tax_engine/tax_engine.dart';
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
  };
  bool _singleParent = false;

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

  TaxSimulation get _simulation => TaxSimulation(
    id: 'validation-lab',
    name: 'Tax Validation Lab',
    createdAt: DateTime.utc(widget.rules.taxYear),
    updatedAt: DateTime.utc(widget.rules.taxYear),
    profile: TaxpayerProfile(
      taxYear: widget.rules.taxYear,
      age: int.tryParse(_values['age']!.text) ?? 30,
      civilStatus: CivilStatus.single,
      dependentAges: _dependentAges,
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.separate,
      isSingleParentHousehold: _singleParent,
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
  );

  @override
  Widget build(BuildContext context) {
    final result = TaxEngine(widget.rules).calculate(_simulation);
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Validation Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Developer-only · regras ${widget.rules.rulesVersion}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          _section('Inputs suportados'),
          _input('Gross income', 'gross'),
          _input('Withholding', 'withholding'),
          _input('Social Security', 'socialSecurity'),
          _input('Age', 'age', money: false),
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
        ],
      ),
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
