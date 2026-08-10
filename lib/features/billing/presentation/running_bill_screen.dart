import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/line_item_row.dart';
import '../application/billing_controller.dart';
import 'calculate_total_screen.dart';
import 'manual_entry_screen.dart';
import 'voice_listening_screen.dart';

/// Screen B3 — the running line-item list (FR-3.2.7). No grand total is
/// shown here on purpose — only Jama Karain (B5) reveals it, per the
/// explicit-calculation principle.
class RunningBillScreen extends ConsumerWidget {
  const RunningBillScreen({super.key});

  String _unitLabel(AppLocalizations l10n, QuantityUnit unit) => switch (unit) {
        QuantityUnit.piece => l10n.unitPiece,
        QuantityUnit.dozen => l10n.unitDozen,
        QuantityUnit.kg => l10n.unitKg,
        QuantityUnit.gram => l10n.unitGram,
        QuantityUnit.litre => l10n.unitLitre,
        QuantityUnit.meter => l10n.unitMeter,
        QuantityUnit.bottle => l10n.unitBottle,
        QuantityUnit.tablet => l10n.unitTablet,
        QuantityUnit.strip => l10n.unitStrip,
        QuantityUnit.packet => l10n.unitPacket,
        QuantityUnit.box => l10n.unitBox,
        QuantityUnit.custom => l10n.unitCustom,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final state = ref.watch(billingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newBillTitle),
        bottom: state.customer != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(18),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${state.customer!.name} • ${l10n.khataTag}',
                    style: type.caption.copyWith(
                      color: colors.appBarForeground.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final item in state.items)
                    LineItemRow(
                      name: item.itemNameRaw,
                      meta: '${_formatQuantity(item.quantity)} ${_unitLabel(l10n, item.unit)} × '
                          '${item.pricePerUnit.format()}',
                      amount: item.lineTotal,
                      onDelete: () =>
                          ref.read(billingControllerProvider.notifier).removeItem(item.localId),
                    ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VoiceListeningScreen()),
                          ),
                          child: const Icon(Icons.mic),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
                          ),
                          icon: const Icon(Icons.keyboard),
                          label: Text(l10n.manualLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: state.hasItems
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CalculateTotalScreen()),
                            )
                        : null,
                    child: Text(l10n.calculateTotal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatQuantity(double quantity) =>
      quantity == quantity.roundToDouble() ? quantity.toStringAsFixed(0) : quantity.toString();
}
