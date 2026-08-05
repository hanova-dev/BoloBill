import 'package:flutter/foundation.dart';

/// A monetary amount stored as integer minor units (paisa), never as a
/// floating-point rupee value.
///
/// SRS §8.3: "All monetary fields use DECIMAL(12,2) rather than floating
/// point, to avoid rounding errors accumulating across many small daily
/// transactions." SQLite has no fixed-point DECIMAL storage, so every money
/// column in the schema (bills.total_amount, bill_items.price_per_unit,
/// bill_items.line_total, khata_entries.amount, payments.amount_received)
/// is persisted as an INTEGER of minor units, and this type is the single
/// place that converts between that and a display/entry rupee value —
/// centralizing the one conversion that, if duplicated per call site, is
/// exactly how rounding bugs creep in.
@immutable
class Money implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits);

  /// Rounds to the nearest paisa — the only point where floating point is
  /// allowed to touch a monetary value, at the entry boundary.
  factory Money.fromRupees(num rupees) => Money.fromMinorUnits((rupees * 100).round());

  static const zero = Money.fromMinorUnits(0);

  /// Integer paisa (1 rupee = 100 minor units).
  final int minorUnits;

  double get rupees => minorUnits / 100;

  Money operator +(Money other) => Money.fromMinorUnits(minorUnits + other.minorUnits);
  Money operator -(Money other) => Money.fromMinorUnits(minorUnits - other.minorUnits);
  Money operator *(num factor) => Money.fromMinorUnits((minorUnits * factor).round());
  Money get abs => Money.fromMinorUnits(minorUnits.abs());
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;
  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) => other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  /// Formats using South Asian digit grouping (e.g. "Rs. 12,34,567"),
  /// matching the "Rs. 1,270" style shown throughout the screens mockups.
  /// Numerals are always Western Arabic digits — the screens' footer note
  /// confirms Space Grotesk numerals are used identically in all three
  /// languages, so this formatter needs no locale parameter.
  String format({String currencySymbol = 'Rs.'}) {
    final isNegative = minorUnits < 0;
    final absMinor = minorUnits.abs();
    final whole = absMinor ~/ 100;
    final fraction = absMinor % 100;
    final sign = isNegative ? '-' : '';
    final wholeStr = _groupSouthAsian(whole);
    if (fraction == 0) {
      return '$sign$currencySymbol $wholeStr';
    }
    return '$sign$currencySymbol $wholeStr.${fraction.toString().padLeft(2, '0')}';
  }

  static String _groupSouthAsian(int value) {
    final str = value.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }
    groups.add(lastThree);
    return groups.join(',');
  }

  @override
  String toString() => format();
}
