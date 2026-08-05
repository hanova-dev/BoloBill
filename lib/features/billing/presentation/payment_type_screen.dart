import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/icon_tile.dart';
import '../../notifications/presentation/in_app_toast.dart';
import '../../receipts/presentation/receipt_screen.dart';
import '../application/billing_controller.dart';
import 'customer_picker_screen.dart';

/// Screen B6 — payment type (FR-3.4.6). Jama Karain (B5) is already the
/// deliberate, explicit confirmation gate against voice misrecognition;
/// picking Cash/Khata here is a single clear choice with no ambiguity risk,
/// so tapping a tile finalizes directly rather than requiring yet another
/// confirm step.
class PaymentTypeScreen extends ConsumerStatefulWidget {
  const PaymentTypeScreen({super.key});

  @override
  ConsumerState<PaymentTypeScreen> createState() => _PaymentTypeScreenState();
}

class _PaymentTypeScreenState extends ConsumerState<PaymentTypeScreen> {
  bool _confirming = false;

  Future<void> _chooseCash() async {
    ref.read(billingControllerProvider.notifier).setPaymentType(PaymentType.cash);
    await _confirm();
  }

  Future<void> _chooseKhata() async {
    var customer = ref.read(billingControllerProvider).customer;
    if (customer == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomerPickerScreen()),
      );
      customer = ref.read(billingControllerProvider).customer;
      if (customer == null) return; // picker was dismissed without selecting
    }
    ref.read(billingControllerProvider.notifier).setPaymentType(PaymentType.khata);
    await _confirm();
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final bill = await ref.read(billingControllerProvider.notifier).confirmBill();
    if (!mounted) return;
    // F2: fired before navigating, into the *root* overlay, so it survives
    // the pushAndRemoveUntil below instead of vanishing with this route.
    showBoloToast(
      context,
      kind: BoloToastKind.success,
      message: AppLocalizations.of(context).billSavedOfflineToast,
    );
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ReceiptScreen(billId: bill.billId)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final state = ref.watch(billingControllerProvider);
    final customer = state.customer;

    return Scaffold(
      body: SafeArea(
        child: _confirming
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.howWillTheyPay,
                      style: type.eyebrow.copyWith(color: colors.textSoft),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.total?.format() ?? '',
                      style: type.amountHero.copyWith(color: colors.accent, fontSize: 30),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: IconTile(
                            emoji: '💵',
                            label: l10n.paymentCash,
                            selected: false,
                            onTap: _chooseCash,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: IconTile(
                            emoji: '📒',
                            label: l10n.paymentKhata,
                            selected: false,
                            onTap: _chooseKhata,
                          ),
                        ),
                      ],
                    ),
                    if (customer != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: colors.cardBorder, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.secondary,
                              child: Text(
                                customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name, style: type.bodyEmphasis.copyWith(color: colors.text)),
                                Text(
                                  l10n.previousBalance(customer.currentBalance.format()),
                                  style: type.caption.copyWith(color: colors.textSoft, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
