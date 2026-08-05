import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/bolo_chip.dart';
import 'sign_up_method_screen.dart';

/// Screen A1 — the app's very first screen. Tapping a language chip both
/// sets the shop's language and advances to E1; there is no separate
/// "Continue" action; per the low-literacy design principle, every primary
/// action reads more like a photo/icon prompt than a form to fill in.
class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final activeLocale = ref.watch(localeProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface.withValues(alpha: 0.4), colors.scaffoldBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.appName,
                    style: type.screenTitle.copyWith(color: colors.accent, fontSize: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appTagline,
                    style: type.caption.copyWith(color: colors.textSoft),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    l10n.chooseYourLanguage,
                    style: type.eyebrow.copyWith(color: colors.textSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
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
                        onTap: () {
                          ref.read(localeProvider.notifier).state = locale;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpMethodScreen()),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
