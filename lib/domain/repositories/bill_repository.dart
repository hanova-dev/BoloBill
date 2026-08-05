import '../entities/bill.dart';
import '../entities/bill_item.dart';

/// Bill + line-item management (SRS §9.1 Bill Engine).
///
/// The active draft (adding/correcting/removing line items per FR-3.2.7/
/// FR-3.2.8, then Jama Karain calculating per module 3.3) lives in the
/// Bill Engine's in-memory state, not in this repository — FR-3.7.1 says
/// records are written "immediately upon confirmation", not per keystroke.
/// [createConfirmedBill] is therefore the only write this repository
/// exposes: one atomic transaction for the bill row plus every line item,
/// called once, at confirmation, with the final total and payment type
/// already known (payment type isn't chosen until B6, after Jama Karain —
/// bills.payment_type is NOT NULL, so the row cannot exist any earlier).
abstract interface class BillRepository {
  Future<void> createConfirmedBill(Bill bill, List<BillItem> items);

  Future<Bill?> getBill(String billId);
  Future<List<Bill>> getBillsForShop(String shopId);
  Future<List<Bill>> getBillsForCustomer(String customerId);
  Future<List<BillItem>> getLineItems(String billId);
}
