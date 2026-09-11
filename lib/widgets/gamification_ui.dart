import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/xp_event.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'pixel_ui.dart';

class LevelStrip extends StatelessWidget {
  const LevelStrip({
    super.key,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.currentXp,
    required this.targetXp,
    required this.trailingLabel,
    this.onTap,
    this.dark = false,
    this.missionLabel,
    this.missionProgress,
    this.missionXpLabel,
    this.missionCompletedCount,
    this.onMissionTap,
  });

  final int level;
  final String title;
  final String subtitle;
  final int currentXp;
  final int targetXp;
  final String trailingLabel;
  final VoidCallback? onTap;
  final bool dark;
  final String? missionLabel;
  final String? missionProgress;
  final String? missionXpLabel;
  final int? missionCompletedCount;
  final VoidCallback? onMissionTap;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.ink;
    final secondary = dark ? const Color(0xFFB5BEDD) : AppColors.inkSoft;
    final progress = targetXp <= 0 ? 0.0 : currentXp / targetXp;
    final showMission =
        onMissionTap != null &&
        missionLabel != null &&
        missionProgress != null &&
        missionXpLabel != null;
    final body = Column(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? AppColors.tealSoft : AppColors.teal,
                border: Border.all(color: foreground, width: 2.5),
              ),
              child: Text(
                '$level',
                style: pixelText(
                  size: 18,
                  bold: true,
                  color: dark ? AppColors.ink : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: pixelText(size: 15, bold: true, color: foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: pixelText(size: 12, color: secondary)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: foreground, size: 24),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedProgress(value: progress),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              AppLocalizations.of(context).xpOfTarget(currentXp, targetXp),
              style: pixelText(size: 12, bold: true, color: secondary),
            ),
            const Spacer(),
            Text(
              trailingLabel,
              style: pixelText(size: 12, bold: true, color: secondary),
            ),
          ],
        ),
      ],
    );
    if (!showMission) {
      return PixelCard(
        elevation: PixelElevation.none,
        color: dark ? AppColors.ink : AppColors.tealSoft,
        borderColor: dark ? AppColors.tealSoft : AppColors.ink,
        onTap: onTap,
        child: body,
      );
    }
    return PixelCard(
      elevation: PixelElevation.none,
      color: dark ? AppColors.ink : AppColors.tealSoft,
      borderColor: dark ? AppColors.tealSoft : AppColors.ink,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _StripTap(
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(14), child: body),
          ),
          Container(height: 2.5, color: foreground),
          _StripTap(
            onTap: onMissionTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                    ),
                    child: Text(
                      '${missionCompletedCount ?? 0}',
                      style: pixelText(size: 12, bold: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          missionLabel!,
                          style: pixelText(
                            size: 11,
                            bold: true,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          missionProgress!,
                          style: pixelText(size: 13, bold: true),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    missionXpLabel!,
                    style: pixelText(
                      size: 12,
                      bold: true,
                      color: AppColors.tealInk,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.ink,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripTap extends StatelessWidget {
  const _StripTap({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.title,
    required this.xp,
    required this.progress,
    required this.leadingLabel,
    required this.trailingLabel,
    required this.icon,
    this.tint = AppColors.tealSoft,
    this.iconColor = AppColors.tealInk,
    this.completed = false,
  });

  final String title;
  final int xp;
  final double progress;
  final String leadingLabel;
  final String trailingLabel;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final bool completed;

  @override
  Widget build(BuildContext context) => PixelCard(
    elevation: PixelElevation.none,
    color: completed ? AppColors.tealSoft : AppColors.surface,
    borderColor: completed ? AppColors.tealInk : AppColors.ink,
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed ? AppColors.surface : tint,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 19,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: pixelText(size: 14, bold: true)),
            ),
            Text(
              '+$xp',
              style: pixelText(size: 14, bold: true, color: AppColors.tealInk),
            ),
          ],
        ),
        if (!completed) ...[
          const SizedBox(height: 10),
          SegmentedProgress(value: progress),
        ],
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                leadingLabel,
                style: pixelText(size: 12, color: AppColors.muted),
              ),
            ),
            Text(
              trailingLabel,
              style: pixelText(
                size: 12,
                bold: true,
                color: completed ? AppColors.tealInk : AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class XpRewardRow extends StatelessWidget {
  const XpRewardRow({
    super.key,
    required this.label,
    required this.xp,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final int xp;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint,
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: pixelText(size: 14, bold: true))),
        Text(
          '+$xp',
          style: pixelText(size: 15, bold: true, color: AppColors.tealInk),
        ),
      ],
    ),
  );
}

class PixelTag extends StatelessWidget {
  const PixelTag({
    super.key,
    required this.label,
    this.color = AppColors.surface,
    this.ink = AppColors.ink,
  });

  final String label;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.ink, width: 2),
    ),
    child: Text(label, style: pixelText(size: 12, bold: true, color: ink)),
  );
}

class XpToast extends StatelessWidget {
  const XpToast({super.key, required this.notice});

  final XpNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFF7FD8CE), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                xpNoticeTitle(l10n, notice),
                style: pixelText(size: 13, bold: true, color: Colors.white),
              ),
              Text(
                xpNoticeDetail(l10n, notice),
                style: pixelText(size: 12, color: const Color(0xFFB5BEDD)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.xpAmount(notice.xp),
          style: pixelText(
            size: 14,
            bold: true,
            color: const Color(0xFF7FD8CE),
          ),
        ),
      ],
    );
  }
}

/// The one loud moment in Sobra's gamification.
///
/// Regular XP awards ride the quiet snackbar so they never interrupt a
/// record. A level-up happens once every few weeks, so it earns a card the
/// user has to close — otherwise a four-second toast is all that marks it
/// and most of them would go unseen.
Future<void> showLevelUpCelebration(
  BuildContext context,
  int newLevel, {
  List<String> newlyUnlockedItemNames = const [],
}) => showDialog<void>(
  context: context,
  barrierColor: const Color(0x99242B4A),
  builder: (context) => LevelUpCelebration(
    newLevel: newLevel,
    newlyUnlockedItemNames: newlyUnlockedItemNames,
  ),
);

class LevelUpCelebration extends StatelessWidget {
  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    this.newlyUnlockedItemNames = const [],
  });

  final int newLevel;
  final List<String> newlyUnlockedItemNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: PixelCard(
        color: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.xpLevelUpTitle(newLevel),
              textAlign: TextAlign.center,
              style: pixelText(size: 24, bold: true, color: AppColors.tealInk),
            ),
            const SizedBox(height: 4),
            Text(
              xpLevelTitle(l10n, newLevel),
              textAlign: TextAlign.center,
              style: pixelText(size: 14, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 14),
            // A still frame of the celebration pose. The sprite's loop never
            // settles, which stalls `pumpAndSettle` in any test that meets
            // this dialog — and a portrait reads just as well here.
            const CatSprite(
              motion: CatMotion.celebrate,
              width: 130,
              animate: false,
            ),
            if (newlyUnlockedItemNames.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  border: Border.all(color: AppColors.tealInk, width: 2.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 24,
                      color: AppColors.tealInk,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.xpLevelUpItemsUnlocked(
                              newlyUnlockedItemNames.length,
                            ),
                            style: pixelText(
                              size: 13,
                              bold: true,
                              color: AppColors.tealInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            newlyUnlockedItemNames.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: pixelText(size: 12, bold: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PixelButton(
              label: l10n.xpLevelUpContinue,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

SnackBar xpSnackBar(BuildContext context, XpNotice notice) {
  // The tab bar lives inside the Scaffold body, so a floating snackbar's
  // default slot is on top of it. Lift by the bar plus the home indicator.
  final bottom =
      kPixelBottomBarHeight + MediaQuery.paddingOf(context).bottom + 12;
  return SnackBar(
    backgroundColor: AppColors.ink,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
    margin: EdgeInsets.fromLTRB(12, 0, 12, bottom),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: AppColors.ink, width: 2.5),
    ),
    content: XpToast(notice: notice),
  );
}
