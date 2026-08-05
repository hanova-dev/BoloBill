import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import 'enums.dart';

/// payments (SRS §8.2.7) — a payment received, always paired 1:1 with the
/// khata credit entry it produces via [linkedKhataEntryId].
@immutable
class Payment {
  const Payment({
    required this.paymentId,
    required this.customerId,
    required this.amountReceived,
    required this.recordedVia,
    required this.timestamp,
    required this.linkedKhataEntryId,
    this.synced = false,
  });

  final String paymentId;
  final String customerId;
  final Money amountReceived;
  final InputMethod recordedVia;
  final DateTime timestamp;
  final String linkedKhataEntryId;
  final bool synced;

  Map<String, Object?> toMap() => {
        'payment_id': paymentId,
        'customer_id': customerId,
        'amount_received': amountReceived.minorUnits,
        'recorded_via': recordedVia.dbValue,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'linked_khata_entry_id': linkedKhataEntryId,
        'synced': synced ? 1 : 0,
      };

  static Payment fromMap(Map<String, Object?> map) => Payment(
        paymentId: map['payment_id']! as String,
        customerId: map['customer_id']! as String,
        amountReceived: Money.fromMinorUnits(map['amount_received']! as int),
        recordedVia: InputMethod.fromDb(map['recorded_via']! as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
        linkedKhataEntryId: map['linked_khata_entry_id']! as String,
        synced: (map['synced']! as int) == 1,
      );
}
