import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/khata_entry.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/khata_repository.dart';
import '../local/database/daos/customers_dao.dart';
import '../local/database/daos/khata_entries_dao.dart';
import '../local/database/daos/payments_dao.dart';

/// Every write in this class runs inside a single [Database.transaction] so
/// the khata_entries row, the payments row (where applicable), and the
/// customers.current_balance cache refresh either all land or none do —
/// the cache must never be observably stale relative to the ledger it's
/// derived from (SRS §8.3).
class KhataRepositoryImpl implements KhataRepository {
  KhataRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> postBillDebit({
    required String customerId,
    required String billId,
    required Money amount,
  }) async {
    await _db.transaction((txn) async {
      final entriesDao = KhataEntriesDao(txn);
      await entriesDao.insertEntry(KhataEntry(
        entryId: IdGenerator.newId(),
        customerId: customerId,
        billId: billId,
        entryType: KhataEntryType.debit,
        amount: amount,
        timestamp: DateTime.now(),
      ));
      await _refreshCachedBalance(txn, customerId);
    });
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required Money amountReceived,
    required InputMethod recordedVia,
    String? note,
  }) async {
    await _db.transaction((txn) async {
      final entriesDao = KhataEntriesDao(txn);
      final paymentsDao = PaymentsDao(txn);

      final entryId = IdGenerator.newId();
      await entriesDao.insertEntry(KhataEntry(
        entryId: entryId,
        customerId: customerId,
        entryType: KhataEntryType.credit,
        amount: amountReceived,
        note: note,
        timestamp: DateTime.now(),
      ));
      await paymentsDao.insertPayment(Payment(
        paymentId: IdGenerator.newId(),
        customerId: customerId,
        amountReceived: amountReceived,
        recordedVia: recordedVia,
        timestamp: DateTime.now(),
        linkedKhataEntryId: entryId,
      ));
      await _refreshCachedBalance(txn, customerId);
    });
  }

  @override
  Future<void> reversePayment({
    required String customerId,
    required KhataEntry originalCreditEntry,
  }) async {
    await _db.transaction((txn) async {
      final entriesDao = KhataEntriesDao(txn);
      await entriesDao.insertEntry(KhataEntry(
        entryId: IdGenerator.newId(),
        customerId: customerId,
        entryType: KhataEntryType.debit,
        amount: originalCreditEntry.amount,
        note: 'Payment correction',
        timestamp: DateTime.now(),
        reversalOfEntryId: originalCreditEntry.entryId,
      ));
      await _refreshCachedBalance(txn, customerId);
    });
  }

  Future<void> _refreshCachedBalance(DatabaseExecutor txn, String customerId) async {
    final summary = await KhataEntriesDao(txn).summarizeForCustomer(customerId);
    await CustomersDao(txn).updateCachedBalance(
      customerId,
      balance: summary.balance,
      lastTransactionAt: summary.lastTransactionAt,
    );
  }

  @override
  Future<List<KhataEntry>> getLedger(String customerId) =>
      KhataEntriesDao(_db).getByCustomer(customerId);

  @override
  Future<List<Payment>> getPayments(String customerId) =>
      PaymentsDao(_db).getByCustomer(customerId);

  @override
  Future<Money> getBalance(String customerId) async =>
      (await KhataEntriesDao(_db).summarizeForCustomer(customerId)).balance;
}
