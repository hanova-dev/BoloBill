import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/icon_tile.dart';
import '../application/onboarding_controller.dart';
import 'shop_name_screen.dart';

/// Screen A2 — business-type selection as an icon grid (FR-3.1.1), not a
/// text list.
class BusinessTypeScreen extends ConsumerStatefulWidget {
  const BusinessTypeScreen({super.key});

  @override
  ConsumerState<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends ConsumerState<BusinessTypeScreen> {
  BusinessType? _selected;

  static const _tiles = [
    (BusinessType.grocery, '🛒'),
    (BusinessType.teaStall, '☕'),
    (BusinessType.vegetableCart, '🥬'),
    (BusinessType.tailor, '🧵'),
    (BusinessType.bakery, '🍞'),
    (BusinessType.generalStore, '🏪'),
    (BusinessType.medicalStore, '💊'),
    (BusinessType.other, '🏬'),
  ];

  String _labelFor(AppLocalizations l10n, BusinessType type) => switch (type) {
        BusinessType.grocery => l10n.businessTypeGrocery,
        BusinessType.teaStall => l10n.businessTypeTeaStall,
        BusinessType.vegetableCart => l10n.businessTypeVegetableCart,
        BusinessType.tailor => l10n.businessTypeTailor,
        BusinessType.bakery => l10n.businessTypeBakery,
        BusinessType.generalStore => l10n.businessTypeGeneralStore,
        BusinessType.medicalStore => l10n.businessTypeMedicalStore,
        BusinessType.other => l10n.businessTypeOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseShopTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.chooseShopSubtitle),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: _tiles.map((entry) {
                    final (type, emoji) = entry;
                    return IconTile(
                      emoji: emoji,
                      label: _labelFor(l10n, type),
                      selected: _selected == type,
                      onTap: () => setState(() => _selected = type),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selected == null
                    ? null
                    : () {
                        ref.read(onboardingControllerProvider.notifier).setBusinessType(_selected!);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ShopNameScreen()),
                        );
                      },
                icon: const Icon(Icons.check),
                label: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
