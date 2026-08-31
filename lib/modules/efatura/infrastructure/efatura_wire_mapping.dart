import '../domain/efatura_models.dart';

EfaturaOverview efaturaOverviewFromMap(Map<String, Object?> map) {
  final rawSectors = map['sectors'];
  if (rawSectors is! List<Object?>) _unexpected();
  return EfaturaOverview(
    provisionalBenefitCents: efaturaRequiredInteger(
      map,
      'provisionalBenefitCents',
    ),
    pendingValidation: efaturaRequiredInteger(map, 'pendingValidation'),
    pendingRevenueAssociation: efaturaRequiredInteger(
      map,
      'pendingRevenueAssociation',
    ),
    sectors: rawSectors
        .map((item) {
          if (item is! Map<Object?, Object?>) _unexpected();
          final code = item['code']?.toString().trim() ?? '';
          if (code.isEmpty) _unexpected();
          return AtExpenseSector(
            code: code,
            label: item['label']?.toString(),
            provisionalBenefitCents: efaturaInteger(
              item['provisionalBenefitCents'],
            ),
            invoiceCount: efaturaInteger(item['invoiceCount']),
          );
        })
        .toList(growable: false),
  );
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

int efaturaRequiredInteger(Map<String, Object?> map, String key) {
  final value = efaturaInteger(map[key]);
  if (value == null) {
    _unexpected();
  }
  return value;
}

Never _unexpected() => throw const EfaturaServiceException(
  EfaturaFailureKind.parsing,
  'Recebemos uma resposta inesperada do e-Fatura.',
);
