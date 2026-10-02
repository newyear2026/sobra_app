import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'pixel_ui.dart';

/// The starter left at the door, as the last section of Inicio's level card.
///
/// Two ways over, in the order they are offered: recorded days, which is the
/// habit the app wants, and rewarded ads, kept small underneath for somebody
/// who would rather not wait.
class StarterWaitingRow extends StatelessWidget {
  const StarterWaitingRow({
    super.key,
    required this.characterId,
    required this.recordedDays,
    required this.recordedToday,
    required this.adProgress,
    required this.adTarget,
    required this.onCallWithAds,
  });

  final String characterId;
  final int recordedDays;
  final bool recordedToday;
  final int adProgress;
  final int adTarget;
  final VoidCallback onCallWithAds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const target = CatalogPreviewData.starterRecordedDaysTarget;
    final name = CharacterCatalog.resolve(characterId).displayName;
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Door(characterId: characterId),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeStarterWaiting(name),
                        style: pixelText(size: 13, bold: true),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.homeStarterDays(target),
                        style: pixelText(size: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 7),
                      _DaySteps(
                        filled: recordedDays.clamp(0, target),
                        // Today's cell waits dashed until something dated
                        // today is recorded, so the row says what to do.
                        todayOpen: !recordedToday && recordedDays < target,
                        target: target,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCallWithAds,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.violetSoft,
                    border: Border.all(color: AppColors.violet, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        color: AppColors.violet,
                        child: Text(
                          'AD',
                          style: pixelText(
                            size: 10,
                            bold: true,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.homeStarterCallNow(adTarget, adProgress),
                            style: pixelText(
                              size: 12,
                              bold: true,
                              color: AppColors.violet,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A door frame with the starter peeking round it.
class _Door extends StatelessWidget {
  const _Door({required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 62,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: AppColors.beige,
      border: Border.all(color: AppColors.ink, width: 2.5),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 8,
          right: -4,
          bottom: -2,
          child: CharacterSprite(
            characterId: characterId,
            role: CharacterMotionRole.idle,
            width: 52,
            animate: !reducedMotionOf(context),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 9,
            decoration: const BoxDecoration(
              color: AppColors.cash,
              border: Border(right: BorderSide(color: AppColors.ink, width: 2)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DaySteps extends StatelessWidget {
  const _DaySteps({
    required this.filled,
    required this.todayOpen,
    required this.target,
  });

  final int filled;
  final bool todayOpen;
  final int target;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var step = 0; step < target; step++) ...[
        if (step > 0) const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: step < filled
                  ? AppColors.teal
                  : step == filled && todayOpen
                  ? AppColors.tealSoft
                  : AppColors.surface,
              border: Border.all(
                color: step == filled && todayOpen
                    ? AppColors.teal
                    : AppColors.ink,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Shows the starter that came over by recorded days. True means the user
/// chose to switch to it; the default keeps the companion they have.
Future<bool> showStarterArrivalDialog(
  BuildContext context, {
  required String arrivedId,
  required String currentId,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99242B4A),
      builder: (context) =>
          _StarterArrivalDialog(arrivedId: arrivedId, currentId: currentId),
    ) ??
    false;

class _StarterArrivalDialog extends StatelessWidget {
  const _StarterArrivalDialog({
    required this.arrivedId,
    required this.currentId,
  });

  final String arrivedId;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animate = !reducedMotionOf(context);
    final arrivedName = CharacterCatalog.resolve(arrivedId).displayName;
    final currentName = CharacterCatalog.resolve(currentId).displayName;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: PixelCard(
        elevation: PixelElevation.hero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.starterArrivalKicker(
                CatalogPreviewData.starterRecordedDaysTarget,
              ),
              textAlign: TextAlign.center,
              style: pixelText(size: 12, bold: true, color: AppColors.violet),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.starterArrivalTitle(arrivedName),
              textAlign: TextAlign.center,
              style: pixelText(size: 19, bold: true),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.only(bottom: 8),
              // The success pose leaps; it stays inside the frame.
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.violetSoft,
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CharacterSprite(
                    characterId: currentId,
                    role: CharacterMotionRole.idle,
                    width: 92,
                    animate: animate,
                  ),
                  CharacterSprite(
                    characterId: arrivedId,
                    role: CharacterMotionRole.success,
                    width: 92,
                    animate: animate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.starterArrivalLine,
              textAlign: TextAlign.center,
              style: pixelText(size: 13, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Keeping comes first and is the primary action: three days with
            // one companion is not something to swap out on the user's behalf.
            PixelButton(
              label: l10n.starterArrivalKeep(currentName),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 5),
            PixelButton(
              label: l10n.starterArrivalSwitch(arrivedName),
              variant: PixelButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
