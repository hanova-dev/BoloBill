import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_item.dart';
import '../../../domain/entities/enums.dart';

/// Turns a confirmed bill into ESC/POS command bytes for a Bluetooth thermal
/// printer (D1, FR-3.5.2). Kept as a pure function of its inputs — no
/// Bluetooth transport dependency — so the byte-generation logic itself is
/// unit-testable without real printer hardware, which this project's
/// environment can't provide.
abstract final class EscPosReceiptFormatter {
  static String _unitLabel(QuantityUnit unit) => switch (unit) {
        QuantityUnit.piece => 'pc',
        QuantityUnit.dozen => 'dz',
        QuantityUnit.kg => 'kg',
        QuantityUnit.gram => 'g',
        QuantityUnit.litre => 'L',
        QuantityUnit.meter => 'm',
        QuantityUnit.custom => '',
      };

  static String _formatQuantity(double quantity) =>
      quantity == quantity.roundToDouble() ? quantity.toStringAsFixed(0) : quantity.toString();

  static Future<List<int>> format({
    required String shopName,
    required Bill bill,
    required List<BillItem> items,
    String? customerName,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      shopName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      DateFormat('d MMM yyyy • h:mm a').format(bill.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    ));
    if (customerName != null) {
      bytes.addAll(generator.text(
        'Khata - $customerName',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
    }
    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(generator.text(item.itemNameRaw, styles: const PosStyles(bold: true)));
      bytes.addAll(generator.row([
        PosColumn(
          text: '${_formatQuantity(item.quantity)} ${_unitLabel(item.unit)} x ${item.pricePerUnit.format()}',
          width: 8,
        ),
        PosColumn(text: item.lineTotal.format(), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: bill.totalAmount.format(),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
