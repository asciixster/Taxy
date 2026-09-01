import 'efatura_models.dart';

enum InvoiceSort { newest, oldest, highestValue, lowestValue, issuer }

final class InvoiceFilter {
  const InvoiceFilter({
    this.query = '',
    this.from,
    this.to,
    this.minimumCents,
    this.maximumCents,
    this.sort = InvoiceSort.newest,
  });

  final String query;
  final DateTime? from;
  final DateTime? to;
  final int? minimumCents;
  final int? maximumCents;
  final InvoiceSort sort;
}

final class InvoiceMonthSummary {
  const InvoiceMonthSummary({
    required this.year,
    required this.month,
    required this.documentCount,
    required this.totalCents,
  });
  final int year;
  final int month;
  final int documentCount;
  final int totalCents;
  int get averageCents => documentCount == 0 ? 0 : totalCents ~/ documentCount;
}

List<EfaturaInvoice> filterInvoices(
  Iterable<EfaturaInvoice> source,
  InvoiceFilter filter,
) {
  final normalized = filter.query.trim().toLowerCase();
  final result = source
      .where((invoice) {
        final date = DateTime.tryParse(invoice.date);
        if (normalized.isNotEmpty &&
            !(invoice.issuerDisplayName ?? '').toLowerCase().contains(
              normalized,
            )) {
          return false;
        }
        if (filter.from != null &&
            (date == null || date.isBefore(filter.from!))) {
          return false;
        }
        if (filter.to != null &&
            (date == null || date.isAfter(_endOfDay(filter.to!)))) {
          return false;
        }
        if (filter.minimumCents != null &&
            invoice.totalCents < filter.minimumCents!) {
          return false;
        }
        if (filter.maximumCents != null &&
            invoice.totalCents > filter.maximumCents!) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
  result.sort(
    (a, b) => switch (filter.sort) {
      InvoiceSort.newest => b.date.compareTo(a.date),
      InvoiceSort.oldest => a.date.compareTo(b.date),
      InvoiceSort.highestValue => b.totalCents.compareTo(a.totalCents),
      InvoiceSort.lowestValue => a.totalCents.compareTo(b.totalCents),
      InvoiceSort.issuer => (a.issuerDisplayName ?? '').toLowerCase().compareTo(
        (b.issuerDisplayName ?? '').toLowerCase(),
      ),
    },
  );
  return result;
}

List<InvoiceMonthSummary> summarizeInvoicesByMonth(
  Iterable<EfaturaInvoice> source,
) {
  final buckets = <(int, int), (int, int)>{};
  for (final invoice in source) {
    final date = DateTime.tryParse(invoice.date);
    if (date == null) continue;
    final key = (date.year, date.month);
    final current = buckets[key] ?? (0, 0);
    buckets[key] = (current.$1 + 1, current.$2 + invoice.totalCents);
  }
  final result = buckets.entries
      .map(
        (entry) => InvoiceMonthSummary(
          year: entry.key.$1,
          month: entry.key.$2,
          documentCount: entry.value.$1,
          totalCents: entry.value.$2,
        ),
      )
      .toList(growable: false);
  result.sort(
    (a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month),
  );
  return result;
}

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
