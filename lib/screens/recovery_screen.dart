import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _working = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_working) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    // A recovery that cannot write is a different failure from one that read
    // nothing usable, and this is the screen of last resort: saying which one
    // happened is the only thing standing between the user and a dead button.
    final l10n = AppLocalizations.of(context);
    bool success;
    String message = l10n.recoveryNotYet;
    try {
      success = await action();
    } on Object catch (error) {
      success = false;
      message = describeStoreFailure(l10n, error);
    }
    if (!mounted) return;
    setState(() => _working = false);
    if (!success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _startFresh(SobraStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.recoveryStartFreshQuestion),
          content: Text(l10n.recoveryStartFreshBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(l10n.recoveryStartFresh),
            ),
          ],
        );
      },
    );
    if (confirmed != true || _working || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    // Archiving the original is the whole promise of this button. If that
    // write fails the reset does not happen, and the user has to be told
    // rather than left looking at an unchanged screen.
    await guardStoreWrite(
      messenger,
      AppLocalizations.of(context),
      store.startFreshAfterCorruption,
    );
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 30),
                const Icon(Icons.storage, size: 58, color: AppColors.cashInk),
                const SizedBox(height: 20),
                Text(
                  l10n.recoveryTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.recoveryOriginalKept,
                  textAlign: TextAlign.center,
                  style: pixelText(
                    size: 15,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                PixelCard(
                  elevation: PixelElevation.none,
                  color: AppColors.cashSoft,
                  borderColor: AppColors.cashInk,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.cashInk,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.recoveryOptions,
                          style: pixelText(
                            size: 13,
                            bold: true,
                            color: AppColors.cashInk,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PixelButton(
                  label: _working ? l10n.recoveryRetrying : l10n.recoveryRetry,
                  onPressed: _working ? null : () => _run(store.retryRestore),
                ),
                const SizedBox(height: 14),
                PixelButton(
                  label: l10n.recoveryUseBackup,
                  onPressed: _working || !store.hasRecoverableBackup
                      ? null
                      : () => _run(store.restoreBackup),
                  color: AppColors.blue,
                ),
                const SizedBox(height: 10),
                PixelButton(
                  label: l10n.recoveryExport,
                  icon: Icons.copy,
                  variant: PixelButtonVariant.secondary,
                  onPressed: _working || store.exportCorruptedJson == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: store.exportCorruptedJson!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.recoveryExported)),
                          );
                        },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _working ? null : () => _startFresh(store),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dangerInk,
                  ),
                  child: Text(l10n.recoveryStartFresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
