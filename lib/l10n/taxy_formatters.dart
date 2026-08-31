import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

abstract final class TaxyFormatters {
  static String euros(BuildContext context, int cents) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.currency(
      locale: locale.toLanguageTag(),
      symbol: '€',
      decimalDigits: 2,
    ).format(cents / 100);
  }

  static String date(BuildContext context, String isoDate) {
    final locale = Localizations.localeOf(context);
    final value = DateTime.tryParse(isoDate);
    if (value == null) return isoDate;
    final localeName = locale.toLanguageTag();
    return locale.languageCode == 'en'
        ? DateFormat.yMMMd(localeName).format(value)
        : DateFormat.yMd(localeName).format(value);
  }
}
