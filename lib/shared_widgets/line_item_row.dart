import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/money.dart';

/// A single bill/receipt/ledger line (mockup `.line-item`): name + meta on
/// one side, amount on the other. [meta] (e.g. "0.5 kg × Rs. 400/kg") is
/// optional — the mockup's B5 total-review list omits it, showing only
/// name + amount, while B3's running list includes it.
class LineItemRow extends StatelessWidget {
  const LineItemRow({
    super.key,
    required this.name,
    required this.amount,
    this.meta,
    this.onDelete,
  });

  final String name;
  final String? meta;
  final Money amount;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: type.bodyEmphasis.copyWith(color: colors.text)),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: type.caption.copyWith(color: colors.textSoft, fontSize: 11)),
                ],
              ],
            ),
          ),
          Text(amount.format(), style: type.amountLine.copyWith(color: colors.text)),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colors.alert),
              onPressed: onDelete,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
