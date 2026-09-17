import 'package:flutter/material.dart';

import '../data/release_notes.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../screens/release_notes_screen.dart';
import '../services/release_announcement_service.dart';
import '../theme/app_theme.dart';
import 'gamification_ui.dart';
import 'pixel_ui.dart';

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

  final navigator = Navigator.of(context);
  final seeAll = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x99242B4A),
    builder: (context) => _ReleaseAnnouncementDialog(note: note),
  );
  if (seeAll != true) return;

  await announcements.markRead();
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ReleaseNotesScreen(currentVersion: announcements.version),
    ),
  );
}

class _ReleaseAnnouncementDialog extends StatelessWidget {
  const _ReleaseAnnouncementDialog({required this.note});

  final ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                color: AppColors.tealSoft,
                border: Border.all(color: AppColors.tealInk, width: 2.5),
              ),
              child: Padding(
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
                            color: AppColors.tealInk,
                          ),
                        ),
                        const Spacer(),
                        PixelTag(
                          label: l10n.releaseNotesCurrent,
                          color: AppColors.teal,
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
                                color: AppColors.tealInk,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line(l10n),
                                style: pixelText(
                                  size: 13,
                                  color: AppColors.tealInk,
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
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: l10n.releaseAnnouncementViewAll,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 6),
            PixelButton(
              label: l10n.releaseAnnouncementDone,
              variant: PixelButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
