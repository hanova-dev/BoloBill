import 'package:flutter/material.dart';
// intl exports its own TextDirection class, which collides with Flutter's —
// hidden here since this file only needs intl for DateFormat.
import 'package:intl/intl.dart' hide TextDirection;

import '../core/theme/app_typography.dart';
import '../domain/entities/bill.dart';
import '../domain/entities/bill_item.dart';
import '../domain/entities/enums.dart';

/// The on-device receipt render (D1, FR-3.5.1) — always literal white paper
/// with dark ink, regardless of the app's active light/dark theme: a shared
/// image or a printed strip is read outside the app, so it has to look like
/// an actual receipt on its own, not follow whatever theme the retailer's
/// phone happened to be in when they tapped share.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.shopName,
    required this.bill,
    required this.items,
    this.customerName,
  });

  final String shopName;
  final Bill bill;
  final List<BillItem> items;

  /// Set only for khata bills (FR-3.4.6) — null for cash sales.
  final String? customerName;

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
      quantity == quantity.roundToDouble()
      ? quantity.toStringAsFixed(0)
      : quantity.toString();

  @override
  Widget build(BuildContext context) {
    final type = AppTypographyTokens.standard;
    const ink = Color(0xFF1A1A1A);
    const inkSoft = Color(0xFF666666);
    final dateStr = DateFormat('d MMM yyyy • h:mm a').format(bill.createdAt);

    // A receipt is a fixed-format document read outside the app (shared,
    // printed) — like the always-white/dark-ink colors above, its layout is
    // deliberately independent of the app's ambient locale direction, and an
    // inherited RTL Directionality would otherwise reorder the date's
    // neutral-character run (see the phone-number bidi note in
    // settings_screen.dart for the same underlying bug).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 340,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              shopName,
              textAlign: TextAlign.center,
              style: type.screenTitle.copyWith(color: ink, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              textAlign: TextAlign.center,
              style: type.caption.copyWith(color: inkSoft),
            ),
            if (customerName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Khata — $customerName',
                textAlign: TextAlign.center,
                style: type.caption.copyWith(
                  color: inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _DashedDivider(color: inkSoft),
            const SizedBox(height: 12),
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemNameRaw,
                          style: type.body.copyWith(color: ink),
                        ),
                        Text(
                          '${_formatQuantity(item.quantity)} ${_unitLabel(item.unit)} × '
                          '${item.pricePerUnit.format()}',
                          style: type.caption.copyWith(
                            color: inkSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.lineTotal.format(),
                    style: type.amountLine.copyWith(color: ink, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            _DashedDivider(color: inkSoft),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: type.eyebrow.copyWith(color: ink)),
                Text(
                  bill.totalAmount.format(),
                  style: type.amountHero.copyWith(color: ink, fontSize: 26),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Thank you!',
              textAlign: TextAlign.center,
              style: type.caption.copyWith(color: inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashGap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.only(right: dashGap),
              child: Container(width: dashWidth, height: 1, color: color),
            ),
          ),
        );
      },
    );
  }
}
