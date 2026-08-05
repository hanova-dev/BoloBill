import '../../core/utils/money.dart';
import '../entities/enums.dart';
import '../entities/khata_entry.dart';
import '../entities/payment.dart';

/// Khata ledger operations (SRS §9.1 Khata Engine: postDebit() /
/// postCredit() / recomputeBalance()). Payments and khata_entries are
/// grouped into one repository because they are never written independently
/// — every payment is paired 1:1 with the credit entry it produces
/// (FR-3.4.7), and this is the only place [Customer.currentBalance] is ever
/// refreshed (SRS §8.3).
abstract interface class KhataRepository {
  /// Posts a sale-driven debit when a confirmed bill is marked "khata"
  /// (FR-3.4.6), then recomputes and caches the customer's balance —
  /// atomically, so the ledger and the cache never observably disagree.
  Future<void> postBillDebit({
    required String customerId,
    required String billId,
    required Money amount,
  });

  /// Records a payment independent of any new sale (FR-3.4.7): writes the
  /// payment row and its paired khata credit entry atomically, then
  /// recomputes and caches the balance.
  Future<void> recordPayment({
    required String customerId,
    required Money amountReceived,
    required InputMethod recordedVia,
    String? note,
  });

  /// Full itemized transaction history, chronological (FR-3.4.9).
  Future<List<KhataEntry>> getLedger(String customerId);

  Future<List<Payment>> getPayments(String customerId);

  /// The authoritative balance — always SUM(khata_entries), never a stored
  /// value trusted on its own (FR-3.4.8).
  Future<Money> getBalance(String customerId);
}
