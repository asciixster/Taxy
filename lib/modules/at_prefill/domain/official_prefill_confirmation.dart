import '../../../guided_tax/tax_interview_models.dart';
import 'official_prefill_evidence.dart';

enum OfficialPrefillField {
  employmentGross,
  withholding,
  socialSecurity,
  selfEmploymentPresence,
}

final class OfficialPrefillConfirmation {
  const OfficialPrefillConfirmation({
    required this.taxYear,
    required this.fields,
    required this.evidence,
  });

  final int taxYear;
  final Set<OfficialPrefillField> fields;
  final OfficialPrefillEvidence evidence;
}

/// Applies only fields the user explicitly selected on the review screen.
///
/// This is the sole boundary between official read-only evidence and active
/// TaxAnswers. Existing answers may only be replaced by this explicit action.
Map<String, TaxAnswer> applyOfficialPrefillConfirmation({
  required Map<String, TaxAnswer> current,
  required int taxYear,
  required OfficialPrefillConfirmation confirmation,
}) {
  if (confirmation.taxYear != taxYear ||
      confirmation.evidence.taxYear != taxYear) {
    return current;
  }
  final updated = <String, TaxAnswer>{...current};
  void official(String questionId, Object value) {
    updated[questionId] = TaxAnswer(
      questionId: questionId,
      value: value,
      provenance: TaxFactProvenance.official,
    );
  }

  final totals = confirmation.evidence.categoryATotals;
  if (confirmation.fields.contains(OfficialPrefillField.employmentGross)) {
    official('employmentIncome', true);
    official('employmentGrossCents', totals.grossIncomeCents);
  }
  if (confirmation.fields.contains(OfficialPrefillField.withholding)) {
    official('employmentIncome', true);
    official('withholdingCents', totals.withholdingCents);
  }
  if (confirmation.fields.contains(OfficialPrefillField.socialSecurity)) {
    official('employmentIncome', true);
    official('socialSecurityCents', totals.socialSecurityCents);
  }
  if (confirmation.fields.contains(
    OfficialPrefillField.selfEmploymentPresence,
  )) {
    official('selfEmploymentIncome', true);
  }
  return updated;
}
