import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// intl exports its own TextDirection class, which collides with Flutter's —
// hidden here since this file only needs intl for DateFormat.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/khata_entry.dart';
import '../../../shared_widgets/customer_avatar.dart';
import '../../../shared_widgets/total_hero.dart';
import 'record_payment_screen.dart';

/// Screen C3 — a customer's full itemized ledger (FR-3.4.9): every debit
/// (sale on khata) and credit (payment received) that produced their
/// current balance, oldest first, plus the authoritative balance itself
/// (always re-read from [KhataRepository.getBalance], never assumed from
/// the list passed in by C5/C1 — SRS §8.3's "never a stored value trusted
/// on its own" applies here too).
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late Future<(Customer, List<KhataEntry>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Customer, List<KhataEntry>)> _load() async {
    final customer = await ref
        .read(customerRepositoryProvider)
        .getCustomer(widget.customerId);
    final ledger = await ref
        .read(khataRepositoryProvider)
        .getLedger(widget.customerId);
    return (customer!, ledger);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _recordPayment(Customer customer) async {
    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordPaymentScreen(
          customerId: customer.customerId,
          customerName: customer.name,
        ),
      ),
    );
    if (recorded == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(Customer, List<KhataEntry>)>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final (customer, ledger) = snapshot.data!;
            final minorUnits = customer.currentBalance.minorUnits;
            final owesShop = minorUnits > 0;
            // A negative balance (net credits exceed net debits) means the
            // shop owes the customer, not merely "settled" — distinct from
            // an exact-zero balance, so it gets its own label rather than
            // being folded into the "clear" state.
            final balanceLabel = minorUnits > 0
                ? l10n.customerOwesLabel
                : minorUnits < 0
                ? l10n.shopOwesCustomerLabel
                : l10n.customerClearLabel;

            return Column(
              children: [
                AppBar(title: Text(customer.name)),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              CustomerAvatar(
                                name: customer.name,
                                photoPath: customer.profilePhotoPath,
                                radius: 36,
                              ),
                              if (customer.phone != null) ...[
                                const SizedBox(height: 8),
                                // Explicit LTR: a phone number is all neutral
                                // characters, so a leading "+" has no bidi
                                // anchor in RTL and would render at the wrong end.
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    customer.phone!,
                                    style: type.caption.copyWith(
                                      color: colors.textSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TotalHero(
                          label: balanceLabel,
                          amount: customer.currentBalance.abs,
                          amountColor: owesShop ? colors.alert : colors.success,
                        ),
                        const SizedBox(height: 8),
                        if (ledger.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            child: Text(
                              l10n.noLedgerEntriesYet,
                              style: type.caption.copyWith(
                                color: colors.textSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              children: [
                                for (final entry in ledger.reversed)
                                  _LedgerRow(entry: entry, l10n: l10n),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<(Customer, List<KhataEntry>)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final customer = snapshot.data!.$1;
          return FloatingActionButton.extended(
            onPressed: () => _recordPayment(customer),
            icon: const Icon(Icons.payments_outlined),
            label: Text(l10n.recordPaymentButton),
          );
        },
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.l10n});

  final KhataEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final isDebit = entry.entryType == KhataEntryType.debit;
    final dateStr = DateFormat('d MMM, h:mm a').format(entry.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18,
            color: isDebit ? colors.alert : colors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDebit ? l10n.ledgerSaleOnKhata : l10n.ledgerPaymentReceived,
                  style: type.bodyEmphasis.copyWith(color: colors.text),
                ),
                const SizedBox(height: 2),
                // Explicit LTR: same bidi note as the phone-number fix above
                // — a formatted date is neutral characters and reorders
                // under ambient RTL.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    dateStr,
                    style: type.caption.copyWith(
                      color: colors.textSoft,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.amount.format(),
            style: type.amountLine.copyWith(
              color: isDebit ? colors.alert : colors.success,
            ),
          ),
        ],
      ),
    );
  }
}
