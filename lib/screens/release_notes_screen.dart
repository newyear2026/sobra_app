import 'package:flutter/material.dart';

import '../data/release_notes.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../services/app_version_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';

/// What changed, for whoever comes looking.
///
/// Nothing pushes the user here — no dialog on the first launch after an
/// update, no unread dot on the tab. The notes sit in Ajustes and are read by
/// the people who want them. That is the same posture as the rest of the app,
/// which has no notification channel at all.
class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({super.key, this.currentVersion});

  /// Marks one card as the build in hand. Null when the platform would not
  /// say which build that is, and then no card is marked — better than
  /// guessing at the newest and being wrong on a phone that skipped an update.
  final AppVersion? currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                PixelTopBar(
                  title: l10n.releaseNotesTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                for (final note in releaseNotes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _NoteCard(
                      note: note,
                      isCurrent: note.version == currentVersion?.version,
                    ),
                  ),
                const SizedBox(height: 4),
                // Says out loud what `releaseNoteRetention` enforces, so the
                // absence of older versions reads as a decision rather than
                // as something the screen failed to load.
                Text(
                  l10n.releaseNotesRetention(releaseNoteRetention),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.isCurrent});

  final ReleaseNote note;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = isCurrent ? AppColors.tealInk : AppColors.ink;

    return PixelCard(
      color: isCurrent ? AppColors.tealSoft : AppColors.surface,
      borderColor: ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${note.version}',
                style: pixelText(size: 21, bold: true, color: ink),
              ),
              if (isCurrent) ...[
                const Spacer(),
                PixelTag(
                  label: l10n.releaseNotesCurrent,
                  color: AppColors.teal,
                  ink: Colors.white,
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            fullDate(l10n, note.releasedOn),
            style: pixelText(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          for (final line in note.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '›',
                    style: pixelText(size: 13, bold: true, color: ink),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line(l10n),
                      style: pixelText(
                        size: 13,
                        color: isCurrent ? AppColors.tealInk : AppColors.inkSoft,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
