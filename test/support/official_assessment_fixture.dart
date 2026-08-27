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
  });

  final String name;
  final String rulesVersion;
  final TaxSimulation simulation;
  final Map<String, int> expected;
  final Map<String, int> documentedRoundingCents;
  final String notes;

  factory OfficialAssessmentFixture.fromFile(File file) {
    final json = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    if (json['schemaVersion'] != 1) {
      throw FormatException('Fixture ${file.path}: schemaVersion inválida');
    }
    return OfficialAssessmentFixture(
      name: json['name'] as String,
      rulesVersion: json['rulesVersion'] as String,
      simulation: TaxSimulation.fromJson(
        (json['inputs'] as Map).cast<String, Object?>(),
      ),
      expected: (json['expected'] as Map).cast<String, int>(),
      documentedRoundingCents:
          (json['documentedRoundingCents'] as Map? ?? const {})
              .cast<String, int>(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
