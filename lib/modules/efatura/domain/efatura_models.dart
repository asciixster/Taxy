enum EfaturaConnectionStatus {
  notConfigured,
  connecting,
  connected,
  authenticationError,
  networkError,
  serviceError,
  expired,
  disconnected,
}

enum EfaturaFailureKind {
  notConfigured,
  authentication,
  authorization,
  network,
  serviceUnavailable,
  expired,
  ntp,
  tls,
  soap,
  business,
  parsing,
  unknown,
}

enum AtValueStatus { available, unavailable, loading, error }

/// Explicit availability for values obtained from an external tax service.
///
/// In particular, `available(0)` is a real observed zero while `unavailable`
/// means the upstream source did not provide the value.
final class AtValue<T> {
  const AtValue.available(T value)
    : status = AtValueStatus.available,
      _value = value;
  const AtValue.unavailable()
    : status = AtValueStatus.unavailable,
      _value = null;
  const AtValue.loading() : status = AtValueStatus.loading, _value = null;
  const AtValue.error() : status = AtValueStatus.error, _value = null;

  final AtValueStatus status;
  final T? _value;

  bool get isAvailable => status == AtValueStatus.available;
  T? get valueOrNull => isAvailable ? _value : null;
  T get value {
    if (!isAvailable) throw StateError('Value is not available');
    return _value as T;
  }
}

enum AtExpenseSectorActivity { active, inactive, unknown }

enum EfaturaOverviewOutcome { success, partialSuccess }

final class AtExpenseSector {
  const AtExpenseSector({
    required this.code,
    this.label,
    this.provisionalBenefitCents = const AtValue.unavailable(),
    this.invoiceCount = const AtValue.unavailable(),
    this.activity = AtExpenseSectorActivity.unknown,
  });
  final String code;
  final String? label;
  final AtValue<int> provisionalBenefitCents;
  final AtValue<int> invoiceCount;
  final AtExpenseSectorActivity activity;
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
  final AtValue<int> provisionalBenefitCents;
  final AtValue<int> pendingValidation;
  final AtValue<int> pendingRevenueAssociation;
  final AtValue<List<AtExpenseSector>> sectors;

  EfaturaOverviewOutcome get outcome {
    final values = <AtValue<Object?>>[
      provisionalBenefitCents,
      pendingValidation,
      pendingRevenueAssociation,
      sectors,
    ];
    return values.every((value) => value.isAvailable)
        ? EfaturaOverviewOutcome.success
        : EfaturaOverviewOutcome.partialSuccess;
  }
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

final class EfaturaCredentials {
  const EfaturaCredentials({required this.nif, required this.password});

  final String nif;
  final String password;
}

/// Non-secret configuration state. It is safe to expose this object to the UI.
final class EfaturaRuntimeReadiness {
  const EfaturaRuntimeReadiness({
    required this.hasCredentials,
    required this.hasClientIdentity,
    required this.hasCipherCertificate,
  });

  final bool hasCredentials;
  final bool hasClientIdentity;
  final bool hasCipherCertificate;

  bool get isReady =>
      hasCredentials && hasClientIdentity && hasCipherCertificate;
}

final class EfaturaServiceException implements Exception {
  const EfaturaServiceException(this.kind, this.safeMessage);
  final EfaturaFailureKind kind;
  final String safeMessage;
  @override
  String toString() => 'EfaturaServiceException($kind)';
}
