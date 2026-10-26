import 'package:flutter/material.dart';

import '../data/release_notes.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/character_costume.dart';
import '../screens/release_notes_screen.dart';
import '../services/release_announcement_service.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'gamification_ui.dart';
import 'pixel_ui.dart';
import 'seasonal_costume_gift.dart';

enum _AnnouncementChoice { seeAll, openGift }

/// Says what changed, once, on the first launch after an update.
///
/// It carries the note itself rather than a link to it. A card that only
/// announced there was something to read would be an interruption that costs
/// a tap to satisfy, and most releases are two lines long.
Future<void> showReleaseAnnouncement(
  BuildContext context, {
  required ReleaseAnnouncements announcements,
}) async {
  final note = announcements.currentNote;
  if (note == null) return;
  // Before the dialog, so anything that rebuilds while it is open already
  // sees a state that cannot ask for a second copy.
  await announcements.markAnnounced();
  if (!context.mounted) return;

  // Decided once, before the card opens: a gift that has been claimed or has
  // run out leaves the card with the ordinary way into the notes.
  final offersGift =
      note.seasonalGift &&
      (SobraScope.maybeOf(context)?.canClaimSeasonalCostumes ?? false);
  final navigator = Navigator.of(context);
  final choice = await showDialog<_AnnouncementChoice>(
    context: context,
    barrierColor: const Color(0x99242B4A),
    builder: (context) =>
        _ReleaseAnnouncementDialog(note: note, offersGift: offersGift),
  );
  switch (choice) {
    case null:
      return;
    case _AnnouncementChoice.openGift:
      // Opening the gift is not reading the notes, so the Ajustes dot stays.
      if (context.mounted) await openSeasonalCostumeGift(context);
    case _AnnouncementChoice.seeAll:
      await announcements.markRead();
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ReleaseNotesScreen(currentVersion: announcements.version),
        ),
      );
  }
}

class _ReleaseAnnouncementDialog extends StatelessWidget {
  const _ReleaseAnnouncementDialog({
    required this.note,
    required this.offersGift,
  });

  final ReleaseNote note;
  final bool offersGift;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The gift release wears the gift banner's pumpkin tint instead of teal.
    final seasonal = note.seasonalGift;
    final soft = seasonal ? AppColors.cashSoft : AppColors.tealSoft;
    final ink = seasonal ? AppColors.cashInk : AppColors.tealInk;
    final accent = seasonal ? AppColors.cash : AppColors.teal;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: PixelCard(
        elevation: PixelElevation.hero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.releaseNotesTitle,
              style: pixelText(size: 19, bold: true),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: soft,
                border: Border.all(color: ink, width: 2.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (seasonal) const _CostumeNight(),
                  Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'v${note.version}',
                              style: pixelText(
                                size: 18,
                                bold: true,
                                color: ink,
                              ),
                            ),
                            const Spacer(),
                            PixelTag(
                              label: l10n.releaseNotesCurrent,
                              color: accent,
                              ink: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullDate(l10n, note.releasedOn),
                          style: pixelText(size: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 9),
                        for (final line in note.lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '›',
                                  style: pixelText(
                                    size: 13,
                                    bold: true,
                                    color: ink,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    line(l10n),
                                    style: pixelText(
                                      size: 13,
                                      color: ink,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (offersGift)
              PixelButton(
                key: const ValueKey('release-announcement-gift'),
                label: l10n.seasonalGiftView,
                onPressed: () =>
                    Navigator.of(context).pop(_AnnouncementChoice.openGift),
              )
            else
              PixelButton(
                label: l10n.releaseAnnouncementViewAll,
                onPressed: () =>
                    Navigator.of(context).pop(_AnnouncementChoice.seeAll),
              ),
            const SizedBox(height: 6),
            PixelButton(
              label: l10n.releaseAnnouncementDone,
              variant: PixelButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three of the costumes under a night sky, the same three the gift sheet
/// previews.
class _CostumeNight extends StatelessWidget {
  const _CostumeNight();

  static const _sky = Color(0xFF2B2550);
  static const _star = Color(0xFFF7E9CE);
  static const _moon = Color(0xFFF2D58A);
  static const _stars = [
    Alignment(-.84, .24),
    Alignment(-.56, -.64),
    Alignment(-.18, -.8),
    Alignment(.26, -.56),
    Alignment(.86, -.2),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 112,
        color: _sky,
        child: Stack(
          children: [
            for (final star in _stars)
              Align(
                alignment: star,
                child: const SizedBox.square(
                  dimension: 3,
                  child: ColoredBox(color: _star),
                ),
              ),
            const Positioned(
              top: 8,
              right: 10,
              child: SizedBox.square(
                dimension: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _moon,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final id in const ['poodle', 'michi', 'alpaca'])
                    CharacterSprite(
                      characterId: id,
                      costumeId: CharacterCostumes.forCharacter(id).single.id,
                      role: CharacterMotionRole.idle,
                      width: 82,
                      animate: false,
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
