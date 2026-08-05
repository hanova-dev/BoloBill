/// Shop's declared business type (SRS §3.1, FR-3.1.1; screens A2).
/// Stored as free-form VARCHAR(30) per SRS §8.2.1 ("e.g. grocery, tea_stall,
/// ...") rather than a DB-level CHECK-constrained enum — the schema itself
/// treats this list as non-exhaustive so new business types can be added
/// without a migration (FR-3.9.3 also implies this stays open-ended).
enum BusinessType {
  grocery('grocery'),
  teaStall('tea_stall'),
  vegetableCart('vegetable_cart'),
  tailor('tailor'),
  bakery('bakery'),
  generalStore('general_store'),
  other('other');

  const BusinessType(this.dbValue);
  final String dbValue;

  static BusinessType fromDb(String value) =>
      values.firstWhere((v) => v.dbValue == value, orElse: () => BusinessType.other);
}

/// users.role (SRS §8.2.2) — ENUM, default 'owner'.
enum UserRole {
  owner('owner'),
  staff('staff');

  const UserRole(this.dbValue);
  final String dbValue;

  static UserRole fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// bills.payment_type (SRS §8.2.4) — ENUM.
enum PaymentType {
  cash('cash'),
  khata('khata');

  const PaymentType(this.dbValue);
  final String dbValue;

  static PaymentType fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// bills.status (SRS §8.2.4, §7.4) — ENUM. Mirrors the Draft → Calculated →
/// Confirmed → Voided lifecycle; the finer-grained post-confirmation states
/// in the §7.4 state diagram (LocallySaved, KhataLinked, ReceiptStage,
/// Delivered, PendingSync, Synced) are process milestones layered on top of
/// the Confirmed row (tracked via bills.synced + receipts/khata_entries
/// existing), not additional values of this column.
enum BillStatus {
  draft('draft'),
  calculated('calculated'),
  confirmed('confirmed'),
  voided('voided');

  const BillStatus(this.dbValue);
  final String dbValue;

  static BillStatus fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// input_method on bill_items (SRS §8.2.5) and recorded_via on payments
/// (SRS §8.2.7) — both share the same voice/manual vocabulary (FR-3.2,
/// FR-3.4.7), so one enum serves both columns rather than two identical ones.
enum InputMethod {
  voice('voice'),
  manual('manual');

  const InputMethod(this.dbValue);
  final String dbValue;

  static InputMethod fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// bill_items.unit (SRS §8.2.5, FR-3.2.6) — ENUM.
enum QuantityUnit {
  piece('piece'),
  dozen('dozen'),
  kg('kg'),
  gram('gram'),
  litre('litre'),
  meter('meter'),
  custom('custom');

  const QuantityUnit(this.dbValue);
  final String dbValue;

  static QuantityUnit fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// khata_entries.entry_type (SRS §8.2.6) — ENUM.
enum KhataEntryType {
  debit('debit'),
  credit('credit');

  const KhataEntryType(this.dbValue);
  final String dbValue;

  static KhataEntryType fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// receipts.format (SRS §8.2.8) — ENUM.
enum ReceiptFormat {
  image('image'),
  print('print');

  const ReceiptFormat(this.dbValue);
  final String dbValue;

  static ReceiptFormat fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}

/// receipts.delivery_channel (SRS §8.2.8) — ENUM.
enum DeliveryChannel {
  whatsapp('whatsapp'),
  bluetoothPrinter('bluetooth_printer'),
  skipped('skipped');

  const DeliveryChannel(this.dbValue);
  final String dbValue;

  static DeliveryChannel fromDb(String value) => values.firstWhere((v) => v.dbValue == value);
}
