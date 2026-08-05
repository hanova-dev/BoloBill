import 'package:flutter/foundation.dart';

import '../../core/localization/app_locale.dart';
import '../../core/utils/money.dart';

/// customers (SRS §8.2.3) — a khata customer profile. [currentBalance] is a
/// cached/derived value (SRS §8.3): the authoritative balance is always the
/// sum of that customer's khata_entries, recomputed on every ledger write —
/// never set directly by callers outside that recompute path.
@immutable
class Customer {
  const Customer({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.createdAt,
    this.phone,
    this.profilePhotoPath,
    this.cnicPhotoPath,
    this.preferredLanguage,
    this.currentBalance = Money.zero,
    this.lastTransactionAt,
    this.synced = false,
  });

  final String customerId;
  final String shopId;
  final String name;
  final String? phone;
  final String? profilePhotoPath;
  final String? cnicPhotoPath;

  /// Overrides the shop's default language for this customer's receipts
  /// (FR-3.6.4). Null means "use the shop default".
  final AppLocale? preferredLanguage;
  final Money currentBalance;
  final DateTime createdAt;
  final DateTime? lastTransactionAt;
  final bool synced;

  Customer copyWith({
    String? name,
    String? phone,
    String? profilePhotoPath,
    String? cnicPhotoPath,
    AppLocale? preferredLanguage,
    Money? currentBalance,
    DateTime? lastTransactionAt,
    bool? synced,
  }) {
    return Customer(
      customerId: customerId,
      shopId: shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      cnicPhotoPath: cnicPhotoPath ?? this.cnicPhotoPath,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toMap() => {
        'customer_id': customerId,
        'shop_id': shopId,
        'name': name,
        'phone': phone,
        'profile_photo_path': profilePhotoPath,
        'cnic_photo_path': cnicPhotoPath,
        'preferred_language': preferredLanguage?.dbCode,
        'current_balance': currentBalance.minorUnits,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_transaction_at': lastTransactionAt?.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
      };

  static Customer fromMap(Map<String, Object?> map) => Customer(
        customerId: map['customer_id']! as String,
        shopId: map['shop_id']! as String,
        name: map['name']! as String,
        phone: map['phone'] as String?,
        profilePhotoPath: map['profile_photo_path'] as String?,
        cnicPhotoPath: map['cnic_photo_path'] as String?,
        preferredLanguage: map['preferred_language'] == null
            ? null
            : AppLocale.fromDbCode(map['preferred_language']! as String),
        currentBalance: Money.fromMinorUnits(map['current_balance']! as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        lastTransactionAt: map['last_transaction_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['last_transaction_at']! as int),
        synced: (map['synced']! as int) == 1,
      );
}
