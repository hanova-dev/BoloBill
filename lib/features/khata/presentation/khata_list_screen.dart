import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../../shared_widgets/bolo_chip.dart';
import '../../../shared_widgets/customer_avatar.dart';
import 'customer_detail_screen.dart';
import 'new_customer_screen.dart';

/// Screen C5 — the khata module's home: every customer for this shop,
/// photo-first, sortable by balance or recency (FR-3.4.4).
class KhataListScreen extends ConsumerStatefulWidget {
  const KhataListScreen({super.key});

  @override
  ConsumerState<KhataListScreen> createState() => _KhataListScreenState();
}

class _KhataListScreenState extends ConsumerState<KhataListScreen> {
  CustomerSort _sortBy = CustomerSort.highestBalanceFirst;
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _load();
  }

  Future<List<Customer>> _load() {
    final shop = ref.read(currentShopProvider);
    if (shop == null) return Future.value(const []);
    return ref.read(customerRepositoryProvider).getCustomersForShop(shop.shopId, sortBy: _sortBy);
  }

  void _setSort(CustomerSort sort) {
    setState(() {
      _sortBy = sort;
      _customersFuture = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _customersFuture = _load();
    });
    await _customersFuture;
  }

  Future<void> _addCustomer() async {
    final created = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const NewCustomerScreen()),
    );
    if (created != null) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.khataListTitle),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: _addCustomer),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Row(
                children: [
                  BoloChip(
                    label: l10n.sortByBalance,
                    selected: _sortBy == CustomerSort.highestBalanceFirst,
                    onTap: () => _setSort(CustomerSort.highestBalanceFirst),
                  ),
                  const SizedBox(width: 8),
                  BoloChip(
                    label: l10n.sortByRecent,
                    selected: _sortBy == CustomerSort.mostRecentFirst,
                    onTap: () => _setSort(CustomerSort.mostRecentFirst),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Customer>>(
                future: _customersFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final customers = snapshot.data!;
                  if (customers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.noCustomersYet,
                          style: type.caption.copyWith(color: colors.textSoft),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final owesShop = customer.currentBalance.minorUnits > 0;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          leading: CustomerAvatar(
                            name: customer.name,
                            photoPath: customer.profilePhotoPath,
                          ),
                          title: Text(
                            customer.name,
                            style: type.bodyEmphasis.copyWith(color: colors.text),
                          ),
                          subtitle: customer.phone == null
                              ? null
                              : Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    customer.phone!,
                                    style: type.caption.copyWith(color: colors.textSoft),
                                  ),
                                ),
                          trailing: Text(
                            customer.currentBalance.abs.format(),
                            style: type.amountSmall.copyWith(
                              color: owesShop ? colors.alert : colors.success,
                            ),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customerId: customer.customerId),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
