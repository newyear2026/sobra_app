import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/app_update_service.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

enum _UpdateChoice { update, later }

/// Offers the update once, and acts on the answer.
///
/// The dialog can also be left by the back button, which is neither answer: it
/// closes this interruption without promising the update will never be
/// mentioned again. Only "Ahora no" is a decision, and only it is remembered.
Future<void> showUpdatePrompt(
  BuildContext context, {
  required AppUpdates updates,
  String? currentVersion,
}) async {
  // Before the dialog rather than after, so the policy already knows the
  // interruption has been spent. Anything that rebuilds while it is open then
  // sees a state that cannot ask for a second copy.
  updates.markPromptShown();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  final choice = await showDialog<_UpdateChoice>(
    context: context,
    barrierColor: const Color(0x99242B4A),
    builder: (context) => _UpdatePromptDialog(currentVersion: currentVersion),
  );

  if (choice == _UpdateChoice.later) {
    await updates.dismiss();
    return;
  }
  if (choice != _UpdateChoice.update) return;
  if (await updates.openStore()) return;
  // No store, no browser, no listing. Saying so is the whole recovery: there
  // is nothing the app can do on the user's behalf from here.
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.updateStoreFailed)));
}

class _UpdatePromptDialog extends StatelessWidget {
  const _UpdatePromptDialog({this.currentVersion});

  /// Null when the platform will not report the running build. The row is then
  /// dropped rather than shown with a dash: inside a dialog about versions, a
  /// version that reads "—" raises more questions than it answers.
  final String? currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = currentVersion;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: PixelCard(
        elevation: PixelElevation.hero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.arrow_circle_up_outlined,
                  size: 24,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.updateAvailableTitle,
                    style: pixelText(size: 19, bold: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.updateAvailableBody,
              style: pixelText(size: 14, color: AppColors.inkSoft, height: 1.5),
            ),
            if (version != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  border: Border.all(color: AppColors.tealInk, width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  child: Text(
                    l10n.updateCurrentVersion(version),
                    style: pixelText(size: 13, color: AppColors.tealInk),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PixelButton(
              label: l10n.updateAction,
              icon: Icons.open_in_new,
              onPressed: () =>
                  Navigator.of(context).pop(_UpdateChoice.update),
            ),
            // Clear of the primary button's own shadow, which otherwise runs
            // straight into this border and reads as one stacked control.
            const SizedBox(height: 6),
            PixelButton(
              label: l10n.updateLater,
              variant: PixelButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(_UpdateChoice.later),
            ),
          ],
        ),
      ),
    );
  }
}

/// The quiet line that outlives a dismissed dialog.
///
/// Deliberately not a second dialog and not a snackbar: it has to be
/// ignorable for as long as the user wants to ignore it, and still be there
/// when they change their mind.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cashSoft,
          border: Border.all(color: AppColors.cashInk, width: 2.5),
          boxShadow: const [
            BoxShadow(color: PixelDepth.shadowColor, offset: PixelDepth.card),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 8, 7, 8),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_circle_up_outlined,
                size: 19,
                color: AppColors.cashInk,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l10n.updateBannerMessage,
                  style: pixelText(size: 13, color: AppColors.cashInk),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: l10n.updateAction,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onUpdate,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.cash,
                      border: Border.all(color: AppColors.cashInk, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      child: Text(
                        l10n.updateAction,
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.cashInk,
                tooltip: l10n.updateBannerDismiss,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
