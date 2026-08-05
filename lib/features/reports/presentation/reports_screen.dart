import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// intl exports its own TextDirection class, which collides with Flutter's —
// hidden here since this file only needs intl for DateFormat.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/enums.dart';
import '../../receipts/presentation/receipt_screen.dart';

class _ReportsData {
  _ReportsData({
    required this.todayTotal,
    required this.weekTotal,
    required this.khataOutstanding,
    required this.recentBills,
  });
  final Money todayTotal;
  final Money weekTotal;
  final Money khataOutstanding;
  final List<Bill> recentBills;
}

/// Screen D2 — a shop-level summary: today's and this-week's sales, total
/// khata outstanding across every customer, and a recent-bills list (tap to
/// reopen that bill's D1 receipt). All figures are computed client-side from
/// the already-local bill/customer tables — the shop's data volume is small
/// enough (single retailer, offline-first) that a dedicated aggregate query
/// layer isn't warranted yet.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final Future<_ReportsData> _future = _load();

  Future<_ReportsData> _load() async {
    final shop = ref.read(currentShopProvider);
    if (shop == null) {
      return _ReportsData(
        todayTotal: Money.zero,
        weekTotal: Money.zero,
        khataOutstanding: Money.zero,
        recentBills: const [],
      );
    }

    final bills = await ref
        .read(billRepositoryProvider)
        .getBillsForShop(shop.shopId);
    final customers = await ref
        .read(customerRepositoryProvider)
        .getCustomersForShop(shop.shopId);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));

    var todayTotal = Money.zero;
    var weekTotal = Money.zero;
    for (final bill in bills) {
      if (bill.status != BillStatus.confirmed) continue;
      if (!bill.createdAt.isBefore(todayStart)) {
        todayTotal += bill.totalAmount;
      }
      if (!bill.createdAt.isBefore(weekStart)) {
        weekTotal += bill.totalAmount;
      }
    }

    var khataOutstanding = Money.zero;
    for (final customer in customers) {
      if (customer.currentBalance.minorUnits > 0) {
        khataOutstanding += customer.currentBalance;
      }
    }

    return _ReportsData(
      todayTotal: todayTotal,
      weekTotal: weekTotal,
      khataOutstanding: khataOutstanding,
      recentBills: bills.take(20).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: SafeArea(
        child: FutureBuilder<_ReportsData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: l10n.todaysSales,
                        amount: data.todayTotal,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: l10n.thisWeeksSales,
                        amount: data.weekTotal,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SummaryCard(
                  label: l10n.khataOutstandingLabel,
                  amount: data.khataOutstanding,
                  color: colors.alert,
                  fullWidth: true,
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.recentBillsLabel,
                  style: type.eyebrow.copyWith(color: colors.textSoft),
                ),
                const SizedBox(height: 10),
                if (data.recentBills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noBillsYet,
                      style: type.caption.copyWith(color: colors.textSoft),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final bill in data.recentBills)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        bill.paymentType == PaymentType.khata
                            ? Icons.menu_book_outlined
                            : Icons.payments_outlined,
                        color: colors.accent,
                      ),
                      // Explicit LTR: same bidi note as the phone-number fix
                      // in settings_screen.dart — a formatted date is neutral
                      // characters and reorders under ambient RTL.
                      title: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          DateFormat('d MMM, h:mm a').format(bill.createdAt),
                          style: type.bodyEmphasis.copyWith(color: colors.text),
                        ),
                      ),
                      subtitle: Text(
                        bill.paymentType == PaymentType.khata
                            ? l10n.khataTag
                            : l10n.paymentCash,
                        style: type.caption.copyWith(color: colors.textSoft),
                      ),
                      trailing: Text(
                        bill.totalAmount.format(),
                        style: type.amountSmall.copyWith(color: colors.text),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReceiptScreen(billId: bill.billId),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final Money amount;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.eyebrow.copyWith(color: colors.textSoft, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            amount.format(),
            style: type.amountLine.copyWith(color: color, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
