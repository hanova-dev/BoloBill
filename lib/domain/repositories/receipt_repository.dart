import '../entities/receipt.dart';

/// Receipt delivery logging (SRS §9.1 Receipt Service, module 3.5).
abstract interface class ReceiptRepository {
  Future<void> createReceipt(Receipt receipt);
  Future<List<Receipt>> getReceiptsForBill(String billId);
}
