import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigation.dart';
import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import '../tax_engine/tax_rules.dart';
import '../widgets/notice_card.dart';
import 'tax_validation_lab_screen.dart';

final class HowWeCalculateScreen extends StatelessWidget {
  const HowWeCalculateScreen({super.key, required this.rules});
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.howWeCalculate)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        children: [
          Text(
            l10n.transparencyFirst,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(l10n.calculationMethodIntro),
          const SizedBox(height: 24),
          _MethodStep(
            number: '1',
            title: l10n.netCategoryIncome,
            text: l10n.netCategoryIncomeExplanation,
          ),
          _MethodStep(
            number: '2',
            title: l10n.minimumExistence,
            text: l10n.minimumExistenceExplanation,
          ),
          _MethodStep(
            number: '3',
            title: l10n.progressiveBrackets,
            text: l10n.progressiveBracketsExplanation(rules.taxYear),
          ),
          _MethodStep(
            number: '4',
            title: l10n.deductionsAndWithholding,
            text: l10n.deductionsAndWithholdingExplanation,
          ),
          const SizedBox(height: 24),
          NoticeCard(
            title: l10n.validatedScope,
            icon: Icons.verified_outlined,
            messages: [
              l10n.validatedResidentScope(rules.jurisdiction),
              l10n.categoryAOnlyScope,
              l10n.standardHouseholdScope,
              l10n.couplesComparisonScope,
              l10n.standardDependantsScope,
              l10n.standardEducationScope,
              l10n.verifiedRulesScope(
                rules.rulesVersion,
                TaxyFormatters.date(
                  context,
                  rules.verifiedAt.toIso8601String(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          NoticeCard(
            title: l10n.unsupportedScope,
            icon: Icons.block_outlined,
            messages: [
              if (rules.taxYear == 2025) l10n.regional2025Unsupported,
              l10n.partialResidenceUnsupported,
              l10n.incomeTypesUnsupported,
              l10n.foreignIncomeUnsupported,
              l10n.specialSituationsUnsupported,
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => AppNavigation.push(
                context,
                TaxValidationLabScreen(rules: rules),
              ),
              icon: const Icon(Icons.science_outlined),
              label: Text(l10n.openValidationLab),
            ),
          ],
        ],
      ),
    );
  }
}

final class _MethodStep extends StatelessWidget {
  const _MethodStep({
    required this.number,
    required this.title,
    required this.text,
  });
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 18, child: Text(number)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
