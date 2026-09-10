import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/daily_mission.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';

class DailyMissionScreen extends StatelessWidget {
  const DailyMissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final board = store.dailyMissions;

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
                  title: l10n.dailyMissionTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dailyMissionResetHint,
                  style: pixelText(size: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < board.missions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _MissionTile(mission: board.missions[i]),
                ],
                const SizedBox(height: 18),
                PixelHint(
                  tone: PixelHintTone.teal,
                  icon: Icons.star_outline,
                  text: l10n.dailyMissionBoardSummary(
                    board.completedCount,
                    board.totalCount,
                    board.earnedXp,
                    board.possibleXp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (tint, iconColor) = _colorsFor(mission.kind);
    final doneAt = mission.completedAt;
    return MissionCard(
      title: mission.kind.title(l10n),
      xp: mission.xp,
      progress: mission.isDone ? 1 : 0,
      leadingLabel: doneAt == null
          ? mission.kind.hint(l10n)
          : l10n.dailyMissionReadyAt(_clock(doneAt)),
      trailingLabel: mission.isDone
          ? l10n.dailyMissionDone
          : l10n.dailyMissionPending,
      icon: _iconFor(mission.kind),
      tint: tint,
      iconColor: iconColor,
      completed: mission.isDone,
    );
  }

  static String _clock(DateTime at) {
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static IconData _iconFor(DailyMissionKind kind) => switch (kind) {
    DailyMissionKind.recordMovement => Icons.edit_outlined,
    DailyMissionKind.sameDay => Icons.today_outlined,
    DailyMissionKind.reviewBudget => Icons.bar_chart_outlined,
  };

  static (Color, Color) _colorsFor(DailyMissionKind kind) => switch (kind) {
    DailyMissionKind.recordMovement => (AppColors.tealSoft, AppColors.tealInk),
    DailyMissionKind.sameDay => (AppColors.violetSoft, AppColors.violet),
    DailyMissionKind.reviewBudget => (AppColors.blueSoft, AppColors.blue),
  };
}
