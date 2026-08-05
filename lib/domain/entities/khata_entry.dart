import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import 'enums.dart';

/// khata_entries (SRS §8.2.6) — append-only ledger row. [amount] is always
/// positive; the debit/credit sign is implied by [entryType], never encoded
/// into the stored value (SRS §8.2.6: "Always positive; sign implied by
/// entry_type").
@immutable
class KhataEntry {
  const KhataEntry({
    required this.entryId,
    required this.customerId,
    required this.entryType,
    required this.amount,
    required this.timestamp,
    this.billId,
    this.note,
    this.synced = false,
  });

  final String entryId;
  final String customerId;

  /// Set for sale-driven debits; null for standalone entries (e.g. a
  /// manually recorded payment) — SRS §8.2.6.
  final String? billId;
  final KhataEntryType entryType;
  final Money amount;
  final String? note;
  final DateTime timestamp;
  final bool synced;

  Map<String, Object?> toMap() => {
        'entry_id': entryId,
        'customer_id': customerId,
        'bill_id': billId,
        'entry_type': entryType.dbValue,
        'amount': amount.minorUnits,
        'note': note,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
      };

  static KhataEntry fromMap(Map<String, Object?> map) => KhataEntry(
        entryId: map['entry_id']! as String,
        customerId: map['customer_id']! as String,
        billId: map['bill_id'] as String?,
        entryType: KhataEntryType.fromDb(map['entry_type']! as String),
        amount: Money.fromMinorUnits(map['amount']! as int),
        note: map['note'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
        synced: (map['synced']! as int) == 1,
      );
}
