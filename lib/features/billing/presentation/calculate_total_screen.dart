import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../shared_widgets/bolo_chip.dart';
import '../../../shared_widgets/line_item_row.dart';
import '../../../shared_widgets/total_hero.dart';
import '../application/billing_controller.dart';
import 'payment_type_screen.dart';
import 'running_bill_screen.dart';

/// Screen B5 — Jama Karain (FR-3.3.1-3.3.6). The mandatory, non-skippable
/// TTS read-back (FR-3.3.4) is the app's primary defense against voice
/// misrecognition, so it fires automatically the moment this screen opens,
/// not on a "listen" tap. The mockup's chip shows the spelled-out amount as
/// text ("one thousand two hundred seventy rupees") — that's design-doc
/// annotation of what plays, not literal production copy: SRS §4.1.1
/// explicitly wants numerals over spelled-out text for this audience, so
/// the on-screen chip stays a numeral-free "listen again" affordance and
/// only the *audio* spells the amount out.
class CalculateTotalScreen extends ConsumerStatefulWidget {
  const CalculateTotalScreen({super.key});

  @override
  ConsumerState<CalculateTotalScreen> createState() => _CalculateTotalScreenState();
}

class _CalculateTotalScreenState extends ConsumerState<CalculateTotalScreen> {
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateAndSpeak());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _calculateAndSpeak() async {
    final total = ref.read(billingControllerProvider.notifier).calculateTotal();
    await _speak(total.rupees.round());
  }

  Future<void> _speak(int wholeRupees) async {
    final locale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context);
    await _tts.setLanguage(switch (locale) {
      AppLocale.urdu => 'ur-PK',
      AppLocale.romanUrdu || AppLocale.english => 'en-US',
    });
    await _tts.speak(l10n.totalReadBackSpeech(wholeRupees));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final state = ref.watch(billingControllerProvider);
    final total = state.total;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calculateTotal)),
      body: SafeArea(
        child: Column(
          children: [
            if (total != null)
              TotalHero(
                label: l10n.billTotalLabel,
                amount: total,
                child: BoloChip(
                  label: l10n.listenAgain,
                  selected: false,
                  leading: Icon(Icons.volume_up, size: 14, color: colors.accent),
                  onTap: () => _speak(total.rupees.round()),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final item in state.items)
                    LineItemRow(name: item.itemNameRaw, amount: item.lineTotal),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RunningBillScreen()),
                    ),
                    child: Text(l10n.editItems),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: total == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PaymentTypeScreen()),
                            ),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.confirmBill),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
