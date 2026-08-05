import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import 'enums.dart';

/// bills (SRS §8.2.4). [totalAmount] is 0 while [status] is [BillStatus.draft]
/// and becomes an immutable snapshot the moment status reaches
/// [BillStatus.confirmed] ("Calculated via Jama Karain, snapshot at
/// confirmation" — SRS §8.2.4) — enforcing that immutability is the Bill
/// Engine's job (build order step 4), not this entity's.
@immutable
class Bill {
  const Bill({
    required this.billId,
    required this.shopId,
    required this.paymentType,
    required this.createdAt,
    this.customerId,
    this.totalAmount = Money.zero,
    this.status = BillStatus.draft,
    this.synced = false,
  });

  final String billId;
  final String shopId;

  /// Null for walk-in/cash sales with no khata link (SRS §8.2.4).
  final String? customerId;
  final PaymentType paymentType;
  final Money totalAmount;
  final BillStatus status;
  final bool synced;
  final DateTime createdAt;

  Bill copyWith({Money? totalAmount, BillStatus? status, bool? synced}) {
    return Bill(
      billId: billId,
      shopId: shopId,
      customerId: customerId,
      paymentType: paymentType,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'bill_id': billId,
        'shop_id': shopId,
        'customer_id': customerId,
        'payment_type': paymentType.dbValue,
        'total_amount': totalAmount.minorUnits,
        'status': status.dbValue,
        'synced': synced ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  static Bill fromMap(Map<String, Object?> map) => Bill(
        billId: map['bill_id']! as String,
        shopId: map['shop_id']! as String,
        customerId: map['customer_id'] as String?,
        paymentType: PaymentType.fromDb(map['payment_type']! as String),
        totalAmount: Money.fromMinorUnits(map['total_amount']! as int),
        status: BillStatus.fromDb(map['status']! as String),
        synced: (map['synced']! as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      );
}
