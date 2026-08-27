import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/screens/tax_validation_lab_screen.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  testWidgets(
    'Validation Lab exposes manual AT comparison and fixture export',
    (tester) async {
      final rules = TaxRuleSet.fromJsonString(
        File('assets/tax_rules/2026.json').readAsStringSync(),
      );
      await tester.pumpWidget(
        MaterialApp(home: TaxValidationLabScreen(rules: rules)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Marital quotient (divisor)'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Taxable income'), findsOneWidget);
      expect(find.text('Marital quotient (divisor)'), findsOneWidget);
      expect(find.text('Rate-determining income'), findsOneWidget);
      expect(find.text('Rate-determining quotient'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Comparação manual com a AT'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Comparação manual com a AT'), findsOneWidget);
      expect(find.textContaining('Nunca introduzas NIF'), findsOneWidget);
      expect(find.text('Valores oficiais e diferenças'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Export official fixture template'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Export official fixture template'), findsOneWidget);
      expect(
        find.text('Source notes (opcional e sem dados pessoais)'),
        findsOneWidget,
      );
    },
  );
}
