import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/customer.dart';
import '../../../shared_widgets/customer_avatar.dart';
import '../../khata/presentation/new_customer_screen.dart';
import '../application/billing_controller.dart';

/// Screen C1 — the photo-first customer picker (FR-3.4.4), reached from B6
/// when a bill is marked "khata" with no customer chosen yet. Shares
/// [CustomerAvatar] and [NewCustomerScreen] with the standalone khata module
/// (C2/C5) so a customer looks and is created identically whether you're
/// mid-sale or browsing the khata list directly.
class CustomerPickerScreen extends ConsumerStatefulWidget {
  const CustomerPickerScreen({super.key});

  @override
  ConsumerState<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends ConsumerState<CustomerPickerScreen> {
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _loadCustomers();
  }

  Future<List<Customer>> _loadCustomers() {
    final shop = ref.read(currentShopProvider);
    if (shop == null) return Future.value(const []);
    return ref.read(customerRepositoryProvider).getCustomersForShop(shop.shopId);
  }

  void _select(Customer customer) {
    ref.read(billingControllerProvider.notifier).selectCustomer(customer);
    Navigator.of(context).pop();
  }

  Future<void> _addNew() async {
    final created = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const NewCustomerScreen()),
    );
    if (created == null || !mounted) return;
    _select(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectCustomerTitle)),
      body: SafeArea(
        child: FutureBuilder<List<Customer>>(
          future: _customersFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final customers = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.tint,
                    child: Icon(Icons.add, color: colors.accent),
                  ),
                  title: Text(l10n.newCustomerTitle, style: type.bodyEmphasis.copyWith(color: colors.text)),
                  onTap: _addNew,
                ),
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noCustomersYet,
                      style: type.caption.copyWith(color: colors.textSoft),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final customer in customers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CustomerAvatar(name: customer.name, photoPath: customer.profilePhotoPath),
                      title: Text(customer.name, style: type.bodyEmphasis.copyWith(color: colors.text)),
                      trailing: Text(
                        customer.currentBalance.format(),
                        style: type.amountSmall.copyWith(
                          color: customer.currentBalance.minorUnits > 0 ? colors.alert : colors.success,
                        ),
                      ),
                      onTap: () => _select(customer),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
