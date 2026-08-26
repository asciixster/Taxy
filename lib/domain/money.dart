import 'dart:math' as math;

/// Valor monetário exato, guardado em cêntimos. Nunca usa ponto flutuante.
final class Money implements Comparable<Money> {
  const Money.fromCents(this.cents);

  static const zero = Money.fromCents(0);
  final int cents;

  factory Money.parseEuros(String raw) {
    var normalized = raw.trim().replaceAll(' ', '');
    if (normalized.contains(',')) {
      // Portuguese input: dots separate thousands and the comma separates cents.
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if ('.'.allMatches(normalized).length > 1) {
      final lastDot = normalized.lastIndexOf('.');
      normalized =
          '${normalized.substring(0, lastDot).replaceAll('.', '')}${normalized.substring(lastDot)}';
    }
    if (normalized.isEmpty) return zero;
    if (!RegExp(r'^-?\d+(\.\d{0,2})?$').hasMatch(normalized)) {
      throw const FormatException('Valor monetário inválido');
    }
    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    final parts = unsigned.split('.');
    final euros = int.parse(parts[0]);
    final decimals = parts.length == 1 ? '' : parts[1];
    final centPart = int.parse('${decimals}00'.substring(0, 2));
    final value = euros * 100 + centPart;
    return Money.fromCents(negative ? -value : value);
  }

  Money operator +(Money other) => Money.fromCents(cents + other.cents);
  Money operator -(Money other) => Money.fromCents(cents - other.cents);
  Money operator -() => Money.fromCents(-cents);

  Money min(Money other) => cents <= other.cents ? this : other;
  Money max(Money other) => cents >= other.cents ? this : other;
  Money clamp(Money lower, Money upper) =>
      Money.fromCents(cents.clamp(lower.cents, upper.cents));

  /// Multiplica por uma taxa em partes por milhão, arredondando ao cêntimo.
  Money timesPpm(int ppm) => Money.fromCents(mulDiv(cents, ppm, 1000000));

  static int mulDiv(int value, int numerator, int denominator) {
    if (denominator == 0) throw ArgumentError('Divisor não pode ser zero');
    final product = BigInt.from(value) * BigInt.from(numerator);
    final divisor = BigInt.from(denominator);
    final negative = product.isNegative != divisor.isNegative;
    final absoluteProduct = product.abs();
    final absoluteDivisor = divisor.abs();
    final quotient = absoluteProduct ~/ absoluteDivisor;
    final remainder = absoluteProduct.remainder(absoluteDivisor);
    final rounded = remainder * BigInt.two >= absoluteDivisor
        ? quotient + BigInt.one
        : quotient;
    return (negative ? -rounded : rounded).toInt();
  }

  String format({bool signed = false}) {
    final absolute = cents.abs();
    final euros = absolute ~/ 100;
    final decimals = (absolute % 100).toString().padLeft(2, '0');
    final groups = <String>[];
    var remaining = euros.toString();
    while (remaining.length > 3) {
      groups.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    groups.insert(0, remaining);
    final sign = cents < 0 ? '−' : (signed && cents > 0 ? '+' : '');
    return '$sign${groups.join('.')},$decimals €';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && cents == other.cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => format();
}

Money moneyMax(Money a, Money b) => a.cents >= b.cents ? a : b;
Money moneyMin(Money a, Money b) => a.cents <= b.cents ? a : b;
int intMax(int a, int b) => math.max(a, b);
