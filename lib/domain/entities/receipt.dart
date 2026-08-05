import 'package:flutter/foundation.dart';

import 'enums.dart';

/// receipts (SRS §8.2.8) — a delivery record for a confirmed bill.
@immutable
class Receipt {
  const Receipt({
    required this.receiptId,
    required this.billId,
    required this.format,
    required this.deliveryChannel,
    this.sentAt,
    this.synced = false,
  });

  final String receiptId;
  final String billId;
  final ReceiptFormat format;
  final DeliveryChannel deliveryChannel;

  /// Null if [deliveryChannel] is [DeliveryChannel.skipped] (SRS §8.2.8).
  final DateTime? sentAt;
  final bool synced;

  Map<String, Object?> toMap() => {
        'receipt_id': receiptId,
        'bill_id': billId,
        'format': format.dbValue,
        'delivery_channel': deliveryChannel.dbValue,
        'sent_at': sentAt?.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
      };

  static Receipt fromMap(Map<String, Object?> map) => Receipt(
        receiptId: map['receipt_id']! as String,
        billId: map['bill_id']! as String,
        format: ReceiptFormat.fromDb(map['format']! as String),
        deliveryChannel: DeliveryChannel.fromDb(map['delivery_channel']! as String),
        sentAt: map['sent_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['sent_at']! as int),
        synced: (map['synced']! as int) == 1,
      );
}
