import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// intl exports its own TextDirection class, which collides with Flutter's —
// hidden here since this file only needs intl for DateFormat.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/providers.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/bolo_chip.dart';

/// Screen D3 — shop profile (read-only), language, theme, and live sync
/// status (build order step 7) with a manual "Sync Now" trigger.
/// Shop-profile editing isn't in scope yet, so the name/business type shown
/// here mirror what onboarding captured.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _businessTypeLabel(AppLocalizations l10n, BusinessType type) => switch (type) {
        BusinessType.grocery => l10n.businessTypeGrocery,
        BusinessType.teaStall => l10n.businessTypeTeaStall,
        BusinessType.vegetableCart => l10n.businessTypeVegetableCart,
        BusinessType.tailor => l10n.businessTypeTailor,
        BusinessType.bakery => l10n.businessTypeBakery,
        BusinessType.generalStore => l10n.businessTypeGeneralStore,
        BusinessType.other => l10n.businessTypeOther,
      };

  Future<void> _setLocale(WidgetRef ref, AppLocale locale) async {
    ref.read(localeProvider.notifier).state = locale;
    final shop = ref.read(currentShopProvider);
    if (shop != null) {
      await ref.read(shopRepositoryProvider).updatePreferredLanguage(shop.shopId, locale);
      ref.read(currentShopProvider.notifier).state = shop.copyWith(preferredLanguage: locale);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final shop = ref.watch(currentShopProvider);
    final activeLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (shop != null) ...[
              Text(l10n.shopProfileLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.cardBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.shopName, style: type.bodyEmphasis.copyWith(color: colors.text)),
                    const SizedBox(height: 4),
                    Text(
                      _businessTypeLabel(l10n, shop.businessType),
                      style: type.caption.copyWith(color: colors.textSoft),
                    ),
                    if (shop.ownerPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      // Explicit LTR: a phone number is all neutral characters
                      // (digits/+), so it has no bidi anchor of its own in an
                      // RTL context and would otherwise render "92...+" with
                      // the sign at the wrong end — the same fix already
                      // applied to onboarding's phone/OTP fields.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(shop.ownerPhone, style: type.caption.copyWith(color: colors.textSoft)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
            Text(l10n.languageLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppLocale.supported.map((locale) {
                final label = switch (locale) {
                  AppLocale.urdu => l10n.languageUrdu,
                  AppLocale.romanUrdu => l10n.languageRomanUrdu,
                  AppLocale.english => l10n.languageEnglish,
                };
                return BoloChip(
                  label: label,
                  selected: locale == activeLocale,
                  onTap: () => _setLocale(ref, locale),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: themeMode == ThemeMode.dark,
              onChanged: (isDark) => ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.dark : ThemeMode.light,
              title: Text(l10n.darkThemeLabel, style: type.body.copyWith(color: colors.text)),
            ),
            const SizedBox(height: 22),
            Text(l10n.syncStatusLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
            const SizedBox(height: 8),
            _SyncStatusCard(status: ref.watch(syncManagerProvider)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: ref.watch(syncManagerProvider) is SyncInProgress
                  ? null
                  : () => ref.read(syncManagerProvider.notifier).syncNow(),
              icon: const Icon(Icons.sync),
              label: Text(l10n.syncNowButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    final (icon, plainMessage, lastSyncedAt, isError) = switch (status) {
      SyncIdle() => (Icons.cloud_outlined, l10n.syncStatusIdle, null, false),
      SyncInProgress() => (Icons.sync, l10n.syncStatusInProgress, null, false),
      SyncSuccess(:final lastSyncedAt) => (Icons.cloud_done_outlined, null, lastSyncedAt, false),
      SyncOffline() => (Icons.cloud_off_outlined, l10n.syncStatusOffline, null, false),
      SyncError(:final lastSyncedAt) => (Icons.error_outline, l10n.syncStatusError, lastSyncedAt, true),
    };
    final style = type.caption.copyWith(color: isError ? colors.alert : colors.textSoft);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: isError ? colors.alert : colors.textSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (plainMessage != null) Text(plainMessage, style: style),
                if (lastSyncedAt != null) ...[
                  if (plainMessage != null) const SizedBox(width: 6),
                  Text(l10n.syncLastSyncedLabel, style: style),
                  const SizedBox(width: 4),
                  // Explicit LTR: same bidi note as the date fixes elsewhere
                  // in D1-D3 — a formatted date is neutral characters and
                  // reorders under ambient RTL if not anchored.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_formatTime(lastSyncedAt), style: style),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) => DateFormat('d MMM, h:mm a').format(time);
}
