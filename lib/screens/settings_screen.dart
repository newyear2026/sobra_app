import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/language.dart';
import '../models/currency.dart';
import '../l10n/labels.dart';
import '../services/app_version_service.dart';
import '../services/purchase_service.dart';
import '../services/sobra_quick_entry.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import 'collection_screen.dart';
import 'login_screen.dart';
import 'cycle_settings_screen.dart';
import 'gamification_preview_screen.dart';
import 'release_notes_screen.dart';
import 'xp_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.versionLoader = loadAppVersion});

  /// Injected so a test can say what the platform reports without standing up
  /// the plugin channel.
  final AppVersionLoader versionLoader;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Null until the platform answers, and null for good if it will not. The
  /// rows read as a dash in the meantime rather than flickering a wrong
  /// number, and this screen rebuilds on every store change — so the read
  /// happens here once instead of inside a FutureBuilder that would re-fire.
  AppVersion? _version;
  bool _quickEntrySaving = false;

  /// Guards the restore row while the store is being asked.
  ///
  /// A restore takes as long as the network does and reports only once it is
  /// finished, so without this the row invites a second tap that would race
  /// the first and answer twice.
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await widget.versionLoader();
    if (!mounted) return;
    setState(() => _version = version);
  }

  Future<void> _openAccountOffer() async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (routeContext) => LoginScreen(
          isInitialOffer: false,
          // Both close the screen for now. Connecting an account is still a
          // stub: there is no Google client configured, so a row that claimed
          // to sign somebody in would be lying to them.
          onGoogleContinue: () => Navigator.of(routeContext).pop(),
          onGuestContinue: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  Future<void> _restorePurchases(SobraPurchases purchases) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _restoring = true);
    final failure = await purchases.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? l10n.purchaseRestored
                : describePurchaseFailure(l10n, failure),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    // Null in a test or the design gallery, where there is no store to ask.
    // The row is then absent rather than present and dead.
    final purchases = PurchaseScope.maybeOf(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          PixelTopBar(title: l10n.settingsTitle),
          const SizedBox(height: 20),
          _ProfileCard(store: store),
          const SizedBox(height: 14),
          _SettingsRow(
            icon: Icons.pets,
            iconColor: AppColors.teal,
            label: l10n.collectionTitle,
            value: l10n.collectionSettingsValue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CollectionScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(l10n.settingsSectionBudget),
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
            value: weekdayName(l10n, store.cashCountWeekday),
            onTap: () => _pickCountDay(context, store),
          ),
          _SettingsRow(
            icon: Icons.attach_money,
            iconColor: AppColors.teal,
            label: l10n.settingsCurrency,
            value: store.currency.code,
            onTap: () => _pickCurrency(context, store),
          ),
          const SizedBox(height: 10),
          _SectionHeader(l10n.settingsSectionScreen),
          _SettingsRow(
            icon: Icons.translate,
            iconColor: AppColors.blue,
            label: l10n.settingsLanguage,
            value: SobraLanguage.fromCode(store.languageCode).label(l10n),
            onTap: () => _pickLanguage(context, store),
          ),
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ValueListenableBuilder<bool>(
              valueListenable: SobraQuickEntry.enabled,
              builder: (context, enabled, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PixelCard(
                  elevation: PixelElevation.none,
                  child: Row(
                    children: [
                      const _IconTile(
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settingsQuickEntry,
                              style: pixelText(size: 15, bold: true),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.settingsQuickEntryHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PixelSwitch(
                        value: enabled,
                        onChanged: _quickEntrySaving
                            ? null
                            : (value) => _setQuickEntry(value),
                        semanticLabel: l10n.settingsQuickEntry,
                      ),
                    ],
                  ),
                ),
              ),
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
          const SizedBox(height: 10),
          _SectionHeader(l10n.settingsSectionData),
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
          // The backup is a JSON string on the clipboard, so receipt photos —
          // which live as files outside it — cannot travel with it. Saying so
          // here is cheaper than a user discovering it on a new phone.
          Padding(
            // Tighter above than below, so the line reads as a footnote to the
            // backup row rather than a preamble to the next section header.
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Text(
              l10n.receiptBackupNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // The offer is made once, at first launch, and then never again on
          // its own. This row is the only way back to it — without it,
          // declining at the start would be a decision with no undo.
          _SettingsRow(
            icon: Icons.account_circle_outlined,
            iconColor: AppColors.blue,
            label: l10n.settingsAccount,
            value: l10n.settingsAccountConnect,
            onTap: _openAccountOffer,
          ),
          // Required by the App Store the moment Sobra ships on iOS, and
          // worth having on Android too: a user whose purchases did not come
          // back needs somewhere to press before they ask for a refund.
          if (purchases != null)
            _SettingsRow(
              icon: Icons.restore,
              iconColor: AppColors.teal,
              label: l10n.settingsRestorePurchases,
              value: l10n.settingsRestore,
              onTap: _restoring ? null : () => _restorePurchases(purchases),
            ),
          const SizedBox(height: 10),
          _SectionHeader(l10n.settingsSectionAbout),
          _SettingsRow(
            // A document, not the sparkle the debug gallery row already uses.
            icon: Icons.article_outlined,
            iconColor: AppColors.teal,
            label: l10n.settingsReleaseNotes,
            value: _version == null
                ? l10n.settingsVersionUnknown
                : 'v${_version!.version}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReleaseNotesScreen(currentVersion: _version),
              ),
            ),
          ),
          // No destination, so no chevron: this row is the answer, not a way
          // to one. It exists so a support question has a number to quote.
          _SettingsRow(
            icon: Icons.info_outline,
            iconColor: AppColors.slate,
            label: l10n.settingsVersion,
            value: _version?.displayLabel ?? l10n.settingsVersionUnknown,
          ),
          // Its own section: a design gallery is not data, and sitting beside
          // the backup row made it look like one.
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            _SectionHeader(l10n.settingsSectionDesign),
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
          ],
          const SizedBox(height: 18),
          Text(
            l10n.settingsStorageNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _setQuickEntry(bool value) async {
    setState(() => _quickEntrySaving = true);
    final applied = await SobraQuickEntry.setEnabled(value);
    if (!mounted) return;
    setState(() => _quickEntrySaving = false);
    if (!applied && value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).quickEntryDenied)),
      );
    }
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
    // A formatting sample, not a figure of the user's. Without a budget the
    // stored default is nothing they chose, so showing it here would invent
    // an amount for them.
    final sample = store.hasBudget ? store.totalBudgetCentavos : 123456;
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
                subtitle: Text(formatMoney(currency, sample)),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == store.currency || !context.mounted) return;

    final example = formatMoney(store.currency, sample);
    final relabelled = formatMoney(chosen, sample);
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

  /// Chooses the day a cash-count week turns over.
  Future<void> _pickCountDay(BuildContext context, SobraStore store) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialogContext) => RadioGroup<int>(
        groupValue: store.cashCountWeekday,
        onChanged: (value) => Navigator.pop(dialogContext, value),
        child: SimpleDialog(
          title: Text(l10n.settingsCountDay),
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              RadioListTile<int>(
                value: day,
                title: Text(weekdayName(l10n, day)),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await guardStoreWrite(
      messenger,
      l10n,
      () => store.setCashCountWeekday(chosen),
    );
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
}

/// Michi, the level, and one light line of accumulated history.
///
/// This is the settings screen's counterpart to the home LevelStrip and its
/// second doorway into the XP screen. It deliberately carries no money
/// figures: those belong to Inicio, and repeating them here would give the
/// same numbers two places to disagree.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.store});

  final SobraStore store;

  /// Days since onboarding completed, counting the first day as day one.
  int _daysWithSobra() {
    final started = store.xpTrackingStartedAt;
    if (started == null) return 1;
    final startDay = DateTime(started.year, started.month, started.day);
    return store.today.difference(startDay).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final xp = store.xpProgress;
    final progress = xp.targetLevelXp <= 0
        ? 0.0
        : xp.currentLevelXp / xp.targetLevelXp;

    return PixelCard(
      elevation: PixelElevation.hero,
      color: AppColors.tealSoft,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const XpHistoryScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // A portrait, not a scene: the shell keeps every tab alive in
              // its IndexedStack, so a looping sprite here would tick and
              // repaint behind every other screen. The still poster frame is
              // also what reduced motion would show.
              const CatSprite(
                motion: CatMotion.idle,
                width: 84,
                animate: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            border: Border.all(
                              color: AppColors.ink,
                              width: 2.5,
                            ),
                          ),
                          child: Text(
                            '${xp.level}',
                            style: pixelText(
                              size: 15,
                              bold: true,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            xpLevelTitle(l10n, xp.level),
                            style: pixelText(size: 17, bold: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.settingsProfileStats(
                        store.movements.length,
                        _daysWithSobra(),
                      ),
                      style: pixelText(size: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedProgress(value: progress),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                l10n.xpOfTarget(xp.currentLevelXp, xp.targetLevelXp),
                style: pixelText(
                  size: 12,
                  bold: true,
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(),
              Text(
                xp.isMaxLevel
                    ? l10n.xpMaxLevel
                    : l10n.xpRemaining(xp.remainingXp),
                style: pixelText(
                  size: 12,
                  bold: true,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        label.toUpperCase(),
        style: pixelText(size: 12, bold: true, color: AppColors.muted),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// Null for a row that only reports something. It then loses its chevron
  /// and its press-down, because a surface that moves under a finger and
  /// leads nowhere reads as a broken button.
  final VoidCallback? onTap;

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
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
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
