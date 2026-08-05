import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore layout for the Sync Manager (build order step 7, SRS §5.3):
/// everything for a shop lives under `shops/{shopId}`, so per-shop security
/// rules and a single-shop-per-device sync scope (SRS: "one shop per device/
/// install") both fall out of one root path. `bill_items` has no collection
/// of its own — every bill document embeds its line items (see
/// db_schema.dart's note on why), so there is no `billItems` path below.
class FirestorePaths {
  FirestorePaths(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> shop(String shopId) =>
      _firestore.collection('shops').doc(shopId);

  CollectionReference<Map<String, dynamic>> users(String shopId) => shop(shopId).collection('users');

  CollectionReference<Map<String, dynamic>> customers(String shopId) =>
      shop(shopId).collection('customers');

  CollectionReference<Map<String, dynamic>> bills(String shopId) => shop(shopId).collection('bills');

  CollectionReference<Map<String, dynamic>> khataEntries(String shopId) =>
      shop(shopId).collection('khataEntries');

  CollectionReference<Map<String, dynamic>> payments(String shopId) =>
      shop(shopId).collection('payments');

  CollectionReference<Map<String, dynamic>> receipts(String shopId) =>
      shop(shopId).collection('receipts');
}
