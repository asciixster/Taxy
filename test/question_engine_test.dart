import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/question_engine/question_engine.dart';

void main() {
  const engine = QuestionEngine();

  test('não apresenta modo de tributação', () {
    expect(
      engine.steps(TaxDraft()).map((e) => e.id),
      isNot(contains('filingMode')),
    );
  });

  test('não apresenta outras deduções', () {
    expect(engine.steps(TaxDraft()).map((e) => e.id), isNot(contains('other')));
  });

  test('não pergunta idades nem monoparental sem dependentes', () {
    final ids = engine.steps(TaxDraft()).map((e) => e.id);
    expect(ids, isNot(contains('dependentAges')));
    expect(ids, isNot(contains('singleParent')));
  });

  test('pergunta monoparental apenas com dependentes e single', () {
    final draft = TaxDraft()..dependentAges = [3];
    final ids = engine.steps(draft).map((e) => e.id);
    expect(ids, containsAllInOrder(['dependentAges', 'singleParent']));
  });

  test('casado recebe comparação de modo e dados do segundo titular', () {
    final draft = TaxDraft()..civilStatus = CivilStatus.married;
    expect(
      engine.steps(draft).map((e) => e.id),
      containsAll(['filingMode', 'secondaryAge', 'secondaryGross']),
    );
  });

  test('as quatro categorias IVA aparecem', () {
    final ids = engine.steps(TaxDraft()).map((e) => e.id);
    expect(
      ids,
      containsAll([
        'invoiceVat15',
        'invoiceVat30',
        'invoiceVat35',
        'invoiceVat100',
      ]),
    );
  });

  test('educação identifica explicitamente o cenário standard', () {
    final education = engine
        .steps(TaxDraft())
        .singleWhere((e) => e.id == 'education');
    expect(education.helper, contains('educação standard'));
    expect(education.helper, contains('Estudante deslocado'));
  });

  test('IVA inclui descrições setoriais e não uma taxa genérica', () {
    final steps = engine.steps(TaxDraft());
    expect(
      steps.singleWhere((e) => e.id == 'invoiceVat30').helper,
      contains('ginásios'),
    );
    expect(
      steps.singleWhere((e) => e.id == 'invoiceVat35').helper,
      contains('veterinário'),
    );
    expect(
      steps.singleWhere((e) => e.id == 'invoiceVat100').helper,
      contains('transportes públicos'),
    );
  });
}
