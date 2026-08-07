/// The full BoloBill local schema (SRS §8.2), version 1.
///
/// Deliberately flat and append-only for the transactional tables (bills,
/// bill_items, khata_entries, payments) per SRS §8.1 — there is no
/// products/catalog table (SRS §2.5). Money columns are INTEGER minor units
/// (paisa), never REAL, per the rounding-error rationale in [Money]
/// (core/utils/money.dart) and SRS §8.3. Timestamps are INTEGER Unix epoch
/// milliseconds.
///
/// `bill_items` has no `synced` column of its own — the Sync Manager (build
/// order step 7) always pushes/pulls a bill's line items embedded inside
/// that bill's Firestore document, since they have no independent existence
/// (always read together with their parent bill, never queried standalone).
const int kDatabaseVersion = 2;

const List<String> kCreateTableStatementsV1 = [
  '''
  CREATE TABLE shops (
    shop_id TEXT PRIMARY KEY NOT NULL,
    owner_phone TEXT NOT NULL UNIQUE,
    owner_uid TEXT,
    shop_name TEXT NOT NULL,
    business_type TEXT NOT NULL,
    preferred_language TEXT NOT NULL DEFAULT 'ur'
      CHECK (preferred_language IN ('en', 'ur', 'roman_ur')),
    color_theme_id TEXT NOT NULL DEFAULT 'default',
    created_at INTEGER NOT NULL,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE users (
    user_id TEXT PRIMARY KEY NOT NULL,
    shop_id TEXT NOT NULL REFERENCES shops(shop_id),
    name TEXT,
    phone TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'staff')),
    created_at INTEGER NOT NULL,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1))
  )
  ''',
  'CREATE INDEX idx_users_shop_id ON users(shop_id)',
  '''
  CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY NOT NULL,
    shop_id TEXT NOT NULL REFERENCES shops(shop_id),
    name TEXT NOT NULL,
    phone TEXT,
    profile_photo_path TEXT,
    cnic_photo_path TEXT,
    preferred_language TEXT CHECK (preferred_language IS NULL OR preferred_language IN ('en', 'ur', 'roman_ur')),
    current_balance INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    last_transaction_at INTEGER,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1))
  )
  ''',
  'CREATE INDEX idx_customers_shop_id ON customers(shop_id)',
  // Powers the C1/C5 photo grid + list, sortable by balance (highest first,
  // FR-3.4.4) or recency.
  'CREATE INDEX idx_customers_shop_balance ON customers(shop_id, current_balance DESC)',
  'CREATE INDEX idx_customers_shop_recency ON customers(shop_id, last_transaction_at DESC)',
  '''
  CREATE TABLE bills (
    bill_id TEXT PRIMARY KEY NOT NULL,
    shop_id TEXT NOT NULL REFERENCES shops(shop_id),
    customer_id TEXT REFERENCES customers(customer_id),
    payment_type TEXT NOT NULL CHECK (payment_type IN ('cash', 'khata')),
    total_amount INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'calculated', 'confirmed', 'voided')),
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1)),
    created_at INTEGER NOT NULL
  )
  ''',
  'CREATE INDEX idx_bills_shop_id ON bills(shop_id)',
  'CREATE INDEX idx_bills_customer_id ON bills(customer_id)',
  '''
  CREATE TABLE bill_items (
    bill_item_id TEXT PRIMARY KEY NOT NULL,
    bill_id TEXT NOT NULL REFERENCES bills(bill_id),
    item_name_raw TEXT NOT NULL,
    input_method TEXT NOT NULL CHECK (input_method IN ('voice', 'manual')),
    quantity REAL NOT NULL,
    unit TEXT NOT NULL CHECK (unit IN ('piece', 'dozen', 'kg', 'gram', 'litre', 'meter', 'custom')),
    price_per_unit INTEGER NOT NULL,
    line_total INTEGER NOT NULL
  )
  ''',
  'CREATE INDEX idx_bill_items_bill_id ON bill_items(bill_id)',
  '''
  CREATE TABLE khata_entries (
    entry_id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    bill_id TEXT REFERENCES bills(bill_id),
    entry_type TEXT NOT NULL CHECK (entry_type IN ('debit', 'credit')),
    amount INTEGER NOT NULL CHECK (amount >= 0),
    note TEXT,
    timestamp INTEGER NOT NULL,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1)),
    reversal_of_entry_id TEXT REFERENCES khata_entries(entry_id)
  )
  ''',
  // Drives the chronological ledger view (FR-3.4.9) and the balance-recompute
  // aggregate query — both filter/order by (customer_id, timestamp).
  'CREATE INDEX idx_khata_entries_customer_timestamp ON khata_entries(customer_id, timestamp)',
  'CREATE INDEX idx_khata_entries_bill_id ON khata_entries(bill_id)',
  '''
  CREATE TABLE payments (
    payment_id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    amount_received INTEGER NOT NULL,
    recorded_via TEXT NOT NULL CHECK (recorded_via IN ('voice', 'manual')),
    timestamp INTEGER NOT NULL,
    linked_khata_entry_id TEXT NOT NULL REFERENCES khata_entries(entry_id),
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1))
  )
  ''',
  'CREATE INDEX idx_payments_customer_id ON payments(customer_id)',
  '''
  CREATE TABLE receipts (
    receipt_id TEXT PRIMARY KEY NOT NULL,
    bill_id TEXT NOT NULL REFERENCES bills(bill_id),
    format TEXT NOT NULL CHECK (format IN ('image', 'print')),
    delivery_channel TEXT NOT NULL CHECK (delivery_channel IN ('whatsapp', 'bluetooth_printer', 'skipped')),
    sent_at INTEGER,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0, 1))
  )
  ''',
  'CREATE INDEX idx_receipts_bill_id ON receipts(bill_id)',
];

/// v1 -> v2: adds [reversal_of_entry_id] to khata_entries so a mistakenly
/// recorded payment can be corrected (FR-3.4.7 amendment) without ever
/// updating or deleting the original row — a correction is a new debit
/// entry that points back at the credit entry it offsets, preserving the
/// append-only guarantee documented on [KhataEntriesDao].
const List<String> kMigrationV1ToV2 = [
  'ALTER TABLE khata_entries ADD COLUMN reversal_of_entry_id TEXT REFERENCES khata_entries(entry_id)',
];
