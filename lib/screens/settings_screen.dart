import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/language.dart';
import '../models/currency.dart';
import '../l10n/labels.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import 'cycle_settings_screen.dart';
import 'gamification_preview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          PixelTopBar(title: l10n.settingsTitle),
          const SizedBox(height: 24),
          _SettingsRow(
            icon: Icons.translate,
            iconColor: AppColors.blue,
            label: l10n.settingsLanguage,
            value: SobraLanguage.fromCode(store.languageCode).label(l10n),
            onTap: () => _pickLanguage(context, store),
          ),
          _SettingsRow(
            icon: Icons.attach_money,
            iconColor: AppColors.teal,
            label: l10n.settingsCurrency,
            value: store.currency.code,
            onTap: () => _pickCurrency(context, store),
          ),
          _SettingsRow(
            icon: Icons.calendar_month,
            iconColor: AppColors.violet,
            label: l10n.settingsBudgetCycle,
            value:
                store.pendingPaySchedule?.type.label(l10n) ??
                store.paySchedule.type.label(l10n),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CycleSettingsScreen(),
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.event_available,
            iconColor: AppColors.blue,
            label: l10n.settingsCountDay,
            value: l10n.settingsCountDaySunday,
            onTap: () => _fixedSetting(context),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PixelCard(
              elevation: PixelElevation.none,
              child: Row(
                children: [
                  _IconTile(
                    icon: Icons.motion_photos_off,
                    color: AppColors.cash,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reduceMotion,
                          style: pixelText(size: 15, bold: true),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.settingsReduceMotionHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PixelSwitch(
                    value: store.reducedMotion,
                    onChanged: (value) => guardStoreWrite(
                      ScaffoldMessenger.of(context),
                      l10n,
                      () => store.setReducedMotion(value),
                    ),
                    semanticLabel: l10n.reduceMotion,
                  ),
                ],
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.cloud_upload,
            iconColor: AppColors.teal,
            label: l10n.settingsBackup,
            value: l10n.settingsCopy,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: store.exportJson()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsBackupCopied)),
              );
            },
          ),
          if (kDebugMode)
            _SettingsRow(
              icon: Icons.auto_awesome,
              iconColor: AppColors.violet,
              label: l10n.settingsXpPreview,
              value: l10n.settingsDesign,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GamificationPreviewScreen(),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            l10n.settingsStorageNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Relabels money in another currency, after saying that is all it does.
  ///
  /// Amounts are stored as a plain count of minor units, so switching would
  /// turn 20,000 centavos into 20,000 cents — the same digits, roughly
  /// seventeen times the money. Converting instead would need a rate, a rate
  /// history, and would quietly rewrite what the user counted weeks ago. So
  /// Sobra relabels, and shows the figure it is about to leave alone.
  Future<void> _pickCurrency(BuildContext context, SobraStore store) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final chosen = await showDialog<Currency>(
      context: context,
      builder: (dialogContext) => RadioGroup<Currency>(
        groupValue: store.currency,
        onChanged: (value) => Navigator.pop(dialogContext, value),
        child: SimpleDialog(
          title: Text(l10n.settingsCurrency),
          children: [
            for (final currency in Currency.values)
              RadioListTile<Currency>(
                value: currency,
                title: Text(currency.code),
                subtitle: Text(
                  formatMoney(currency, store.totalBudgetCentavos),
                ),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == store.currency || !context.mounted) return;

    final example = formatMoney(store.currency, store.totalBudgetCentavos);
    final relabelled = formatMoney(chosen, store.totalBudgetCentavos);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.currencyChangeTitle(chosen.code)),
        content: Text(l10n.currencyChangeBody(example, relabelled)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.currencyChangeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await guardStoreWrite(messenger, l10n, () => store.setCurrency(chosen));
  }

  /// Offers the languages Sobra ships, plus following the phone.
  ///
  /// Language and currency are deliberately separate settings: somebody
  /// earning dollars can still want the app in Spanish, and tying the two
  /// together would make that combination unsayable.
  Future<void> _pickLanguage(BuildContext context, SobraStore store) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final chosen = await showDialog<SobraLanguage>(
      context: context,
      builder: (dialogContext) => RadioGroup<SobraLanguage>(
        groupValue: SobraLanguage.fromCode(store.languageCode),
        onChanged: (value) => Navigator.pop(dialogContext, value),
        child: SimpleDialog(
          title: Text(l10n.settingsLanguage),
          children: [
            for (final language in SobraLanguage.available)
              RadioListTile<SobraLanguage>(
                value: language,
                title: Text(language.label(l10n)),
                subtitle: language == SobraLanguage.automatic
                    ? Text(l10n.languageAutomaticHint)
                    : null,
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await guardStoreWrite(
      messenger,
      l10n,
      () => store.setLanguageCode(chosen.code),
    );
  }

  void _fixedSetting(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).settingsFixedInV1)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelCard(
        elevation: PixelElevation.none,
        onTap: onTap,
        child: Row(
          children: [
            _IconTile(icon: icon, color: iconColor),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label, style: pixelText(size: 15, bold: true)),
            ),
            Text(
              value,
              style: pixelText(size: 14, bold: true, color: AppColors.muted),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Icon(icon, color: color),
    );
  }
}
