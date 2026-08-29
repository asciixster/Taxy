enum EfaturaConnectionStatus {
  notConfigured,
  loading,
  authenticated,
  error,
  ready,
}

enum EfaturaFailureKind {
  notConfigured,
  authentication,
  network,
  serviceUnavailable,
  ntp,
  tls,
  soap,
  business,
  parsing,
  unknown,
}

final class AtExpenseSector {
  const AtExpenseSector({
    required this.code,
    this.label,
    this.provisionalBenefitCents,
    this.invoiceCount,
  });
  final String code;
  final String? label;
  final int? provisionalBenefitCents;
  final int? invoiceCount;
}

final class EfaturaInvoice {
  const EfaturaInvoice({
    required this.date,
    required this.totalCents,
    this.issuerDisplayName,
    this.vatCents,
    this.sectorCode,
    this.sectorLabel,
    this.classificationStatus,
    this.pendingClassification = false,
  });
  final String date;
  final int totalCents;
  final String? issuerDisplayName;
  final int? vatCents;
  final String? sectorCode;
  final String? sectorLabel;
  final String? classificationStatus;
  final bool pendingClassification;
}

final class EfaturaOverview {
  const EfaturaOverview({
    required this.provisionalBenefitCents,
    required this.pendingValidation,
    required this.pendingRevenueAssociation,
    required this.sectors,
  });
  final int provisionalBenefitCents;
  final int pendingValidation;
  final int pendingRevenueAssociation;
  final List<AtExpenseSector> sectors;
}

final class EfaturaSnapshot {
  const EfaturaSnapshot({
    required this.overview,
    this.pendingInvoices = const [],
    this.sectorInvoices = const {},
  });
  final EfaturaOverview overview;
  final List<EfaturaInvoice> pendingInvoices;
  final Map<String, List<EfaturaInvoice>> sectorInvoices;
}

final class EfaturaServiceException implements Exception {
  const EfaturaServiceException(this.kind, this.safeMessage);
  final EfaturaFailureKind kind;
  final String safeMessage;
  @override
  String toString() => 'EfaturaServiceException($kind)';
}
