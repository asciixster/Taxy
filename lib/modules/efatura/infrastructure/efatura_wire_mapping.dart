import '../domain/efatura_models.dart';

EfaturaOverview efaturaOverviewFromMap(Map<String, Object?> map) {
  return EfaturaOverview(
    provisionalBenefitCents: _availabilityIntegerFromMap(
      map,
      'provisionalBenefitCents',
    ),
    pendingValidation: _availabilityIntegerFromMap(map, 'pendingValidation'),
    pendingRevenueAssociation: _availabilityIntegerFromMap(
      map,
      'pendingRevenueAssociation',
    ),
    sectors: map.containsKey('sectors')
        ? _sectorsAvailability(map['sectors'])
        : const AtValue.unavailable(),
  );
}

AtValue<int> _availabilityIntegerFromMap(
  Map<String, Object?> map,
  String key,
) => map.containsKey(key)
    ? efaturaAvailabilityInteger(map[key])
    : const AtValue.unavailable();

AtValue<int> efaturaAvailabilityInteger(Object? raw) {
  // Legacy runtime-native values are known observations and therefore
  // explicitly available. The backend contract uses the status wrapper.
  final legacy = efaturaInteger(raw);
  if (legacy != null) return AtValue.available(legacy);
  if (raw is! Map<Object?, Object?>) _unexpected();
  final status = raw['status']?.toString();
  return switch (status) {
    'available' => AtValue.available(_requiredWireInteger(raw['value'])),
    'unavailable' => const AtValue.unavailable(),
    'loading' => const AtValue.loading(),
    'error' => const AtValue.error(),
    _ => _unexpected(),
  };
}

AtValue<List<AtExpenseSector>> _sectorsAvailability(Object? raw) {
  if (raw is List<Object?>) {
    return AtValue.available(_parseSectors(raw));
  }
  if (raw is! Map<Object?, Object?>) _unexpected();
  final status = raw['status']?.toString();
  return switch (status) {
    'available' => AtValue.available(
      _parseSectors(_requiredWireList(raw['items'])),
    ),
    'unavailable' => const AtValue.unavailable(),
    'loading' => const AtValue.loading(),
    'error' => const AtValue.error(),
    _ => _unexpected(),
  };
}

List<AtExpenseSector> _parseSectors(List<Object?> rawSectors) => rawSectors
    .map((item) {
      if (item is! Map<Object?, Object?>) _unexpected();
      final code = item['code']?.toString().trim() ?? '';
      if (code.isEmpty) _unexpected();
      return AtExpenseSector(
        code: code,
        label: item['label']?.toString(),
        provisionalBenefitCents: _optionalAvailabilityInteger(
          item,
          availabilityKey: 'provisionalBenefit',
          legacyKey: 'provisionalBenefitCents',
        ),
        totalExpensesCents: _optionalAvailabilityInteger(
          item,
          availabilityKey: 'totalExpenses',
          legacyKey: 'totalExpensesCents',
        ),
        totalVatExpensesCents: _optionalAvailabilityInteger(
          item,
          availabilityKey: 'totalVatExpenses',
          legacyKey: 'totalVatExpensesCents',
        ),
        invoiceCount: _optionalAvailabilityInteger(
          item,
          availabilityKey: 'invoiceCount',
          legacyKey: 'invoiceCount',
        ),
        activity: switch (item['activity']?.toString()) {
          'active' => AtExpenseSectorActivity.active,
          'inactive' => AtExpenseSectorActivity.inactive,
          _ => AtExpenseSectorActivity.unknown,
        },
      );
    })
    .toList(growable: false);

AtValue<int> _optionalAvailabilityInteger(
  Map<Object?, Object?> map, {
  required String availabilityKey,
  required String legacyKey,
}) {
  if (map.containsKey(availabilityKey)) {
    return efaturaAvailabilityInteger(map[availabilityKey]);
  }
  if (map.containsKey(legacyKey)) {
    final value = efaturaInteger(map[legacyKey]);
    if (value == null) return const AtValue.unavailable();
    return AtValue.available(value);
  }
  return const AtValue.unavailable();
}

int _requiredWireInteger(Object? value) {
  final parsed = efaturaInteger(value);
  if (parsed == null) _unexpected();
  return parsed;
}

List<Object?> _requiredWireList(Object? value) {
  if (value is! List<Object?>) _unexpected();
  return value;
}

List<EfaturaInvoice> efaturaInvoiceList(Object? raw) {
  if (raw is! List<Object?>) _unexpected();
  return raw
      .map((item) {
        if (item is! Map<Object?, Object?>) _unexpected();
        final date = item['date']?.toString().trim() ?? '';
        final totalCents = efaturaInteger(item['totalCents']);
        if (date.isEmpty || totalCents == null) _unexpected();
        return EfaturaInvoice(
          date: date,
          totalCents: totalCents,
          issuerDisplayName: item['issuerDisplayName']?.toString(),
          vatCents: efaturaInteger(item['vatCents']),
          sectorCode: item['sectorCode']?.toString(),
          sectorLabel: item['sectorLabel']?.toString(),
          classificationStatus: item['classificationStatus']?.toString(),
          pendingClassification: item['pendingClassification'] == true,
        );
      })
      .toList(growable: false);
}

int? efaturaInteger(Object? value) => switch (value) {
  int value => value,
  num value => value.toInt(),
  _ => null,
};

Never _unexpected() => throw const EfaturaServiceException(
  EfaturaFailureKind.parsing,
  'Recebemos uma resposta inesperada do e-Fatura.',
);
