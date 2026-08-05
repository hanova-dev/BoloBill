import 'package:flutter/foundation.dart';

import '../../core/localization/app_locale.dart';
import 'enums.dart';

/// shops (SRS §8.2.1) — the shop profile created during onboarding (module 3.1).
@immutable
class Shop {
  const Shop({
    required this.shopId,
    required this.ownerPhone,
    required this.shopName,
    required this.businessType,
    required this.preferredLanguage,
    required this.createdAt,
    this.ownerUid,
    this.colorThemeId = 'default',
    this.synced = false,
  });

  final String shopId;
  final String ownerPhone;

  /// The signed-in Firebase user who owns this shop (SRS §5.4 auth) — null
  /// only for the TEMP DEBUG BOOTSTRAP path, which never runs real Firebase
  /// Auth. The Sync Manager (build order step 7) writes this into the
  /// shop's Firestore doc so security rules can scope access to it.
  final String? ownerUid;
  final String shopName;
  final BusinessType businessType;
  final AppLocale preferredLanguage;
  final String colorThemeId;
  final DateTime createdAt;
  final bool synced;

  Shop copyWith({
    String? shopName,
    BusinessType? businessType,
    AppLocale? preferredLanguage,
    String? colorThemeId,
    bool? synced,
  }) {
    return Shop(
      shopId: shopId,
      ownerPhone: ownerPhone,
      ownerUid: ownerUid,
      shopName: shopName ?? this.shopName,
      businessType: businessType ?? this.businessType,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      colorThemeId: colorThemeId ?? this.colorThemeId,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toMap() => {
        'shop_id': shopId,
        'owner_phone': ownerPhone,
        'owner_uid': ownerUid,
        'shop_name': shopName,
        'business_type': businessType.dbValue,
        'preferred_language': preferredLanguage.dbCode,
        'color_theme_id': colorThemeId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
      };

  static Shop fromMap(Map<String, Object?> map) => Shop(
        shopId: map['shop_id']! as String,
        ownerPhone: map['owner_phone']! as String,
        ownerUid: map['owner_uid'] as String?,
        shopName: map['shop_name']! as String,
        businessType: BusinessType.fromDb(map['business_type']! as String),
        preferredLanguage: AppLocale.fromDbCode(map['preferred_language']! as String),
        colorThemeId: map['color_theme_id']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        synced: (map['synced']! as int) == 1,
      );
}
