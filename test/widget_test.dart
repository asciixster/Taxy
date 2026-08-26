import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxy_pt/data/simulation_repository.dart';
import 'package:taxy_pt/main.dart';

void main() {
  testWidgets('a aplicação arranca', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(MemorySimulationRepository()),
        ],
        child: const TaxyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaxyApp), findsOneWidget);
    expect(find.text('Começar simulação'), findsOneWidget);
  });
}
