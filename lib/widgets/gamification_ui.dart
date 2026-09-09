import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/xp_event.dart';
import '../theme/app_theme.dart';
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
  });

  final int level;
  final String title;
  final String subtitle;
  final int currentXp;
  final int targetXp;
  final String trailingLabel;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.ink;
    final secondary = dark ? const Color(0xFFB5BEDD) : AppColors.inkSoft;
    final progress = targetXp <= 0 ? 0.0 : currentXp / targetXp;
    return PixelCard(
      elevation: PixelElevation.none,
      color: dark ? AppColors.ink : AppColors.tealSoft,
      borderColor: dark ? AppColors.tealSoft : AppColors.ink,
      onTap: onTap,
      child: Column(
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
                    Text(
                      subtitle,
                      style: pixelText(size: 12, color: secondary),
                    ),
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
      ),
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

SnackBar xpSnackBar(XpNotice notice) => SnackBar(
  backgroundColor: AppColors.ink,
  behavior: SnackBarBehavior.floating,
  duration: const Duration(seconds: 4),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: BorderSide(color: AppColors.ink, width: 2.5),
  ),
  content: XpToast(notice: notice),
);
