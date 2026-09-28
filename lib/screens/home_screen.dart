import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/recurring_expense.dart';
import '../models/room_design.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/fixed_expenses.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/room_scene.dart';
import '../widgets/transaction_row.dart';
import 'app_shell.dart';
import 'cash_count_screen.dart';
import 'daily_mission_screen.dart';
import 'room_screen.dart';
import 'xp_history_screen.dart';

/// What stands in for the headline while no budget has been set.
///
/// It leads to Presupuesto rather than opening an amount dialog of its own:
/// that screen already asks this exact question, and one place to answer it
/// keeps the two from drifting apart.
class _BudgetQuest extends StatelessWidget {
  const _BudgetQuest({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PixelCard(
      color: AppColors.tealSoft,
      borderColor: AppColors.tealInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.homeFirstQuestLabel,
            style: pixelText(size: 12, bold: true, color: AppColors.tealInk),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeBudgetQuestBody,
            style: pixelText(size: 14, bold: true, height: 1.45),
          ),
          const SizedBox(height: 12),
          PixelButton(label: l10n.budgetSetAction, onPressed: onTap),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final shell = AppShellScope.of(context);
    final recent = store.movements.take(3).toList();
    final hasBudget = store.hasBudget;
    // Over budget the headline stops being about today and reports the
    // cycle's own deficit, so the label and the colour follow it. Nothing is
    // over when nothing was set.
    final overCycleBudget = hasBudget && store.remainingBudgetCentavos < 0;
    // The cat still reacts to the day itself: the headline now floors at
    // zero, so it can no longer tell a spent day from an untouched one.
    // Without a budget the allowance is zero, and measuring the day against
    // it would have the cat counselling restraint about a limit nobody set.
    final onTrack =
        !hasBudget ||
        (!overCycleBudget &&
            store.spentTodayCentavos <= store.dailyAllowanceCentavos);
    final xp = store.xpProgress;
    final missions = store.dailyMissions;
    final l10n = AppLocalizations.of(context);
    final currency = store.currency;
    final textTheme = Theme.of(context).textTheme;
    final fixedDue = store.isFixedHomeCardSnoozed
        ? const <FixedOccurrence>[]
        : store.fixedDueOnHome;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.list(
              children: [
                PixelTopBar(
                  title: l10n.appName,
                  trailing: IconButton(
                    tooltip: l10n.settingsTitle,
                    onPressed: () => shell.select(AppTab.settings),
                    icon: const Icon(Icons.settings, size: 28),
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  overCycleBudget ? l10n.homeCycleBalance : l10n.homeTodayLeft,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (!hasBudget) ...[
                  // The figure's place is kept rather than closed up, so the
                  // screen still reads as the one it always was and the card
                  // under it is plainly what fills the gap.
                  Text(
                    emDash,
                    style: textTheme.displayLarge?.copyWith(
                      color: AppColors.line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BudgetQuest(onTap: () => shell.select(AppTab.budget)),
                ] else ...[
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(currency, store.todayRemainingCentavos),
                      style: textTheme.displayLarge?.copyWith(
                        color: overCycleBudget
                            ? AppColors.dangerInk
                            : AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Whichever figure the headline carries, the other one goes
                  // right under it: a zero day is only readable next to the
                  // limit it ran out of, and a deficit next to the budget it
                  // came from.
                  Text(
                    overCycleBudget
                        ? l10n.homeOverBudget(
                            formatMoney(
                              currency,
                              store.totalBudgetCentavos,
                              showCode: false,
                            ),
                          )
                        : l10n.homeDailyLimit(
                            formatMoney(
                              currency,
                              store.dailyAllowanceCentavos,
                              showCode: false,
                            ),
                            formatMoney(
                              currency,
                              store.remainingBudgetCentavos,
                              showCode: false,
                            ),
                          ),
                    style: textTheme.bodySmall?.copyWith(
                      color: overCycleBudget
                          ? AppColors.dangerInk
                          : AppColors.muted,
                    ),
                  ),
                ],
                if (fixedDue.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FixedDueCard(
                    occurrences: fixedDue,
                    onSeeAll: () => shell.select(AppTab.budget),
                  ),
                ],
                const SizedBox(height: 18),
                _HomeRoomCard(
                  message: onTrack ? l10n.homeGoingWell : l10n.homeAdjustCalmly,
                  roomId: store.equippedRoomId,
                  placements: store.roomDecorationsFor(),
                  catMotion: onTrack ? CatMotion.idle : CatMotion.concern,
                  catLoop: onTrack,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const RoomScreen()),
                  ),
                ),
                const SizedBox(height: 18),
                LevelStrip(
                  level: xp.level,
                  title: xpLevelTitle(l10n, xp.level),
                  subtitle: l10n.xpTotal(xp.totalXp),
                  currentXp: xp.currentLevelXp,
                  targetXp: xp.targetLevelXp,
                  trailingLabel: xp.isMaxLevel
                      ? l10n.xpMaxLevel
                      : l10n.xpRemaining(xp.remainingXp),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const XpHistoryScreen(),
                    ),
                  ),
                  missionLabel: l10n.dailyMissionTitle,
                  missionProgress: missions.allDone
                      ? l10n.dailyMissionAllDone
                      : l10n.dailyMissionProgress(
                          missions.completedCount,
                          missions.totalCount,
                        ),
                  missionXpLabel: missions.allDone
                      ? l10n.dailyMissionAllDone
                      : l10n.xpAmount(missions.possibleXp - missions.earnedXp),
                  missionCompletedCount: missions.completedCount,
                  onMissionTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DailyMissionScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeCycleProgress, style: textTheme.titleSmall),
                    Text(
                      l10n.daysCount(store.daysRemaining),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // The bar is a share of the budget, so it has nothing to fill
                // without one. Days remaining and what was spent are both
                // true either way, and they stay.
                if (hasBudget) ...[
                  SegmentedProgress(
                    value: store.budgetProgress,
                    danger: store.budgetProgress > 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetFigure(
                          label: l10n.budget,
                          value: formatMoney(
                            currency,
                            store.totalBudgetCentavos,
                            showCode: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetFigure(
                          label: l10n.spent,
                          value: formatMoney(
                            currency,
                            store.totalSpentCentavos,
                            showCode: false,
                          ),
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ] else
                  _BudgetFigure(
                    label: l10n.spent,
                    value: formatMoney(
                      currency,
                      store.totalSpentCentavos,
                      showCode: false,
                    ),
                  ),
                const SizedBox(height: 18),
                PixelCard(
                  // The one card on the screen that leads somewhere else, so
                  // it takes the single hero depth step.
                  elevation: PixelElevation.hero,
                  color: AppColors.cashSoft,
                  borderColor: AppColors.cashInk,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CashCountScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.cashInk,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.hasCashBaseline
                                  ? l10n.homeCashEstimated
                                  : l10n.homeCashUnset,
                              style: pixelText(
                                size: 13,
                                bold: true,
                                color: AppColors.cashInk,
                              ),
                            ),
                            if (store.hasCashBaseline) ...[
                              Text(
                                formatMoney(
                                  currency,
                                  store.expectedCashCentavos,
                                ),
                                style: pixelText(
                                  size: 23,
                                  bold: true,
                                  color: AppColors.cashInk,
                                ),
                              ),
                              Text(
                                l10n.homeLastCount(
                                  formatMoney(
                                    currency,
                                    store.countedCashCentavos,
                                    showCode: false,
                                  ),
                                ),
                                style: pixelText(
                                  size: 12,
                                  color: AppColors.cashInk,
                                ),
                              ),
                            ] else
                              Text(
                                l10n.homeFirstCountHint,
                                style: pixelText(
                                  size: 12,
                                  color: AppColors.cashInk,
                                  height: 1.45,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.cashInk),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeRecentMovements,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (recent.isNotEmpty)
                      TextButton(
                        onPressed: () => shell.select(AppTab.movements),
                        child: Text(l10n.homeSeeAll),
                      ),
                  ],
                ),
                if (recent.isEmpty) ...[
                  const SizedBox(height: 6),
                  PixelEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.transactionsEmptyTitle,
                    message: l10n.transactionsEmptyMessage,
                  ),
                ] else
                  ...recent.map((entry) => MovementRow(movement: entry)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeRoomCard extends StatelessWidget {
  const _HomeRoomCard({
    required this.message,
    required this.roomId,
    required this.placements,
    required this.catMotion,
    required this.catLoop,
    required this.onTap,
  });

  final String message;
  final String roomId;
  final Map<RoomSlot, String> placements;
  final CatMotion catMotion;
  final bool catLoop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.roomOpen,
      child: PixelCard(
        padding: EdgeInsets.zero,
        elevation: PixelElevation.none,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.home, color: AppColors.ink, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.roomTitle,
                      style: pixelText(size: 16, bold: true),
                    ),
                  ),
                  Text(
                    l10n.roomDecorate,
                    style: pixelText(
                      size: 13,
                      bold: true,
                      color: AppColors.tealInk,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right, color: AppColors.ink),
                ],
              ),
            ),
            const Divider(height: 2.5, thickness: 2.5, color: AppColors.ink),
            AspectRatio(
              aspectRatio: 2,
              child: RoomScene(
                variant: RoomSceneVariant.preview,
                roomId: roomId,
                placements: placements,
                message: message,
                catMotion: catMotion,
                catLoop: catLoop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of the budget line under the progress bar.
///
/// The label stays quiet and the number takes the ink, so the pair reads at a
/// glance without either half dropping under the minimum legible size.
class _BudgetFigure extends StatelessWidget {
  const _BudgetFigure({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: pixelText(size: 12, color: AppColors.muted),
          ),
          TextSpan(text: value, style: pixelText(size: 12, bold: true)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    );
  }
}
