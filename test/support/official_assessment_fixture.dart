import 'dart:convert';
import 'dart:io';

import 'package:taxy_pt/domain/models.dart';

final class OfficialAssessmentFixture {
  const OfficialAssessmentFixture({
    required this.name,
    required this.rulesVersion,
    required this.simulation,
    required this.expected,
    required this.documentedRoundingCents,
    required this.notes,
    required this.source,
  });

  final String name;
  final String rulesVersion;
  final TaxSimulation simulation;
  final Map<String, int> expected;
  final Map<String, int> documentedRoundingCents;
  final String notes;
  final String source;

  factory OfficialAssessmentFixture.fromFile(File file) {
    final json = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    if (json['schemaVersion'] != 1) {
      throw FormatException('Fixture ${file.path}: schemaVersion inválida');
    }
    if (json['source'] != 'OFFICIAL_AT_ASSESSMENT') {
      throw FormatException(
        'Fixture ${file.path}: origem não é uma liquidação oficial da AT',
      );
    }
    const requiredExpected = {
      'taxableIncomeCents',
      'grossTaxCents',
      'deductionsCents',
      'exemptIncomeCents',
      'taxDueCents',
      'withholdingCents',
      'balanceCents',
    };
    final expected = (json['expected'] as Map).cast<String, int>();
    if (!expected.keys.toSet().containsAll(requiredExpected)) {
      throw FormatException(
        'Fixture ${file.path}: outputs obrigatórios em falta',
      );
    }
    return OfficialAssessmentFixture(
      name: json['name'] as String,
      rulesVersion: json['rulesVersion'] as String,
      simulation: TaxSimulation.fromJson(
        (json['inputs'] as Map).cast<String, Object?>(),
      ),
      expected: expected,
      documentedRoundingCents:
          (json['documentedRoundingCents'] as Map? ?? const {})
              .cast<String, int>(),
      notes: json['notes'] as String? ?? '',
      source: json['source'] as String,
    );
  }
}
