import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/data/simulation_repository.dart';

void main() {
  test('memory repository saves, restores and clears wizard draft', () async {
    final repository = MemorySimulationRepository();
    expect(await repository.loadDraft(), isNull);

    await repository.saveDraft({
      'schemaVersion': 1,
      'stepIndex': 4,
      'draft': <String, Object?>{'gross': '30000,00'},
    });
    final restored = await repository.loadDraft();
    expect(restored?['stepIndex'], 4);
    expect((restored?['draft'] as Map)['gross'], '30000,00');

    await repository.clearDraft();
    expect(await repository.loadDraft(), isNull);
  });

  test('memory draft read does not expose mutable top-level storage', () async {
    final repository = MemorySimulationRepository();
    await repository.saveDraft({'stepIndex': 2});
    final restored = await repository.loadDraft();
    restored!['stepIndex'] = 99;
    expect((await repository.loadDraft())?['stepIndex'], 2);
  });
}
