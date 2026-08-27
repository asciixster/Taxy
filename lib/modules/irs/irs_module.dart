/// Fronteira pública do primeiro módulo de produção da Taxy.
///
/// O shell deve depender deste barrel em vez de conhecer a organização interna
/// do IRS. A migração física dos ficheiros legados é incremental para reduzir
/// risco fiscal; motores novos já vivem atrás desta fronteira.
library;

export '../../domain/models.dart';
export '../../domain/money.dart';
export '../../question_engine/question_engine.dart';
export '../../tax_engine/household_tax_engine.dart';
export '../../tax_engine/irs_jovem_eligibility_engine.dart';
export '../../tax_engine/supported_scope.dart';
export '../../tax_engine/tax_engine.dart';
export '../../tax_engine/tax_rules.dart';
