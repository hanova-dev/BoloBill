import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../local/database/daos/receipts_dao.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._dao);

  final ReceiptsDao _dao;

  @override
  Future<void> createReceipt(Receipt receipt) => _dao.insertReceipt(receipt);

  @override
  Future<List<Receipt>> getReceiptsForBill(String billId) => _dao.getByBill(billId);
}
