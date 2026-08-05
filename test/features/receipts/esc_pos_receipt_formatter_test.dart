import 'dart:convert';

import 'package:bolobill/core/utils/id_generator.dart';
import 'package:bolobill/core/utils/money.dart';
import 'package:bolobill/domain/entities/bill.dart';
import 'package:bolobill/domain/entities/bill_item.dart';
import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/features/receipts/application/esc_pos_receipt_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

// Hardware-dependent printing itself can't be exercised without a real
// Bluetooth thermal printer, which this environment doesn't have — so this
// suite verifies the one part that *is* deterministic and hardware-free:
// the ESC/POS byte sequence built from a bill's data.

Bill _sampleBill({String? customerId}) => Bill(
      billId: IdGenerator.newId(),
      shopId: IdGenerator.newId(),
      customerId: customerId,
      paymentType: customerId == null ? PaymentType.cash : PaymentType.khata,
      totalAmount: Money.fromRupees(480),
      status: BillStatus.confirmed,
      createdAt: DateTime(2026, 8, 4, 15, 30),
    );

BillItem _item(String name, {double quantity = 2, double price = 240}) => BillItem(
      billItemId: IdGenerator.newId(),
      billId: 'bill-1',
      itemNameRaw: name,
      inputMethod: InputMethod.manual,
      quantity: quantity,
      unit: QuantityUnit.kg,
      pricePerUnit: Money.fromRupees(price),
      lineTotal: Money.fromRupees(quantity * price),
    );

void main() {
  // CapabilityProfile.load() reads a bundled JSON asset, which needs the
  // test binding initialized even though this suite is otherwise a pure
  // logic test with no widgets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EscPosReceiptFormatter.format', () {
    test('produces a non-empty byte sequence', () async {
      final bytes = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(),
        items: [_item('Sugar')],
      );
      expect(bytes, isNotEmpty);
    });

    test('includes the shop name, item name, and total amount as readable text', () async {
      final bill = _sampleBill();
      final bytes = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: bill,
        items: [_item('Sugar')],
      );
      final decoded = latin1.decode(bytes, allowInvalid: true);

      expect(decoded, contains('Rahim Grocery Store'));
      expect(decoded, contains('Sugar'));
      expect(decoded, contains(bill.totalAmount.format()));
    });

    test('includes every line item name for a multi-item bill', () async {
      final bytes = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(),
        items: [_item('Sugar'), _item('Rice'), _item('Tea')],
      );
      final decoded = latin1.decode(bytes, allowInvalid: true);

      expect(decoded, contains('Sugar'));
      expect(decoded, contains('Rice'));
      expect(decoded, contains('Tea'));
    });

    test('includes "Khata" and the customer name only for khata bills', () async {
      final cashBytes = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(),
        items: [_item('Sugar')],
      );
      final khataBytes = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(customerId: 'cust-1'),
        items: [_item('Sugar')],
        customerName: 'Ali Khan',
      );

      final cashDecoded = latin1.decode(cashBytes, allowInvalid: true);
      final khataDecoded = latin1.decode(khataBytes, allowInvalid: true);

      expect(cashDecoded, isNot(contains('Ali Khan')));
      expect(khataDecoded, contains('Khata'));
      expect(khataDecoded, contains('Ali Khan'));
    });

    test('more line items produce a longer byte sequence', () async {
      final oneItem = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(),
        items: [_item('Sugar')],
      );
      final threeItems = await EscPosReceiptFormatter.format(
        shopName: 'Rahim Grocery Store',
        bill: _sampleBill(),
        items: [_item('Sugar'), _item('Rice'), _item('Tea')],
      );

      expect(threeItems.length, greaterThan(oneItem.length));
    });
  });
}
