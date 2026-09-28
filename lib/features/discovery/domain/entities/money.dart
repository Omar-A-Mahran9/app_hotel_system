import 'package:flutter/foundation.dart';

/// A price in a single currency.
///
/// The Guest App design references only ever show whole-number amounts with the
/// Saudi Riyal mark, so [amount] is a whole currency unit. Formatting for the
/// user (the "﷼" / "SAR" mark and the "/ night" suffix) is done through
/// localization, never here — this type only carries the value.
@immutable
class Money {
  const Money({required this.amount, this.currency = fallbackCurrency});

  /// The single home for the "backend has no configured currency yet"
  /// fallback (mobile/docs/coding_rules.md §2 — no duplicate constants for the
  /// same concept). Every data-layer `?? 'SAR'` across the app should read
  /// this instead of repeating the literal. This is a de-duplication only —
  /// the fallback behaviour itself is a deliberate, documented backend gap
  /// and is not being removed.
  static const String fallbackCurrency = 'SAR';

  /// Currency units. Whole amounts stay `int`; the backend's `decimal:2`
  /// values keep their halalas (e.g. a 20% deposit of 466 → `93.2`), so the
  /// app never shows a rounded figure the server didn't charge.
  final num amount;
  final String currency;

  Money operator *(int factor) => Money(amount: amount * factor, currency: currency);

  /// Parses a Laravel `decimal:2` wire value (`"93.20"`, `93.2`, `945`) —
  /// the single parser every money-carrying model uses.
  static num parseAmount(Object? raw) {
    final double? value = switch (raw) {
      num() => raw.toDouble(),
      String() => double.tryParse(raw),
      _ => null,
    };
    if (value == null || !value.isFinite) return 0;
    final double cents = (value * 100).roundToDouble() / 100;
    return cents == cents.truncateToDouble() ? cents.toInt() : cents;
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => 'Money($amount $currency)';
}
