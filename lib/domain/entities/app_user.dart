import 'package:flutter/foundation.dart';

import 'enums.dart';

/// users (SRS §8.2.2) — a shop staff/owner account. Named `AppUser` to avoid
/// colliding with the many platform/plugin types named `User`.
@immutable
class AppUser {
  const AppUser({
    required this.userId,
    required this.shopId,
    required this.phone,
    required this.createdAt,
    this.name,
    this.role = UserRole.owner,
    this.synced = false,
  });

  final String userId;
  final String shopId;
  final String? name;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() => {
        'user_id': userId,
        'shop_id': shopId,
        'name': name,
        'phone': phone,
        'role': role.dbValue,
        'created_at': createdAt.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
      };

  static AppUser fromMap(Map<String, Object?> map) => AppUser(
        userId: map['user_id']! as String,
        shopId: map['shop_id']! as String,
        name: map['name'] as String?,
        phone: map['phone']! as String,
        role: UserRole.fromDb(map['role']! as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        synced: (map['synced']! as int) == 1,
      );
}
