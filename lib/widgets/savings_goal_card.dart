import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/pay_schedule.dart';
import '../models/savings_goal.dart';
import '../screens/savings_goal_screen.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'goal_product_thumbnail.dart';
import 'pixel_ui.dart';

/// Lives below the complete room, without changing its size or position.
class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = store.activeSavingsGoal;
    void open() => Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => SavingsGoalScreen(existing: goal)),
    );
    if (goal == null) {
      return Semantics(
        button: true,
        label: '${l10n.goalEmptyPrompt}. ${l10n.goalCreate}',
        child: PixelCard(
          key: const ValueKey('savings-goal-empty'),
          elevation: PixelElevation.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          onTap: open,
          child: Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                color: AppColors.tealInk,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goalEmptyPrompt,
                      style: pixelText(size: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.goalCreate,
                      style: pixelText(
                        size: 14,
                        bold: true,
                        color: AppColors.tealInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.tealInk,
                size: 24,
              ),
            ],
          ),
        ),
      );
    }
    final amount = store.savingsGoalProgressCentavos;
    final completed = store.isSavingsGoalComplete;
    final title = completed ? l10n.goalCompleted : l10n.goalTitle;
    final progress = (amount / goal.targetCentavos).clamp(0.0, 1.0);
    final percent = (progress * 100).floor();
    final figures =
        '${formatMoney(store.currency, amount, showCode: false)} / '
        '${formatMoney(store.currency, goal.targetCentavos)}';
    final deadline = completed
        ? null
        : _Deadline.of(
            l10n,
            store,
            goal.targetDate,
            goal.targetCentavos - amount,
          );
    return Semantics(
      button: true,
      label: [
        '$title. ${goal.name}. $figures. $percent%',
        if (deadline != null) deadline.semantics,
      ].join('. '),
      child: PixelCard(
        key: const ValueKey('savings-goal-active'),
        elevation: PixelElevation.none,
        color: AppColors.tealSoft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        onTap: open,
        child: Row(
          children: [
            if (completed)
              const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.verified,
                  key: ValueKey('savings-goal-complete-icon'),
                  color: AppColors.tealInk,
                  size: 28,
                ),
              )
            else
              GoalProductThumbnail(url: goal.imageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · ${goal.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          figures,
                          maxLines: goal.kind == SavingsGoalKind.amount ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: pixelText(
                            size: 12,
                            bold: true,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$percent%',
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: AppColors.tealInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: AppColors.teal,
                    backgroundColor: AppColors.line,
                  ),
                  if (deadline != null) ...[
                    const SizedBox(height: 6),
                    _DeadlineLine(deadline: deadline),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

/// The line under the progress bar of a goal that is not reached yet.
///
/// - Within a month: a day countdown and the money still missing.
/// - Further out: what to put aside per pay cycle, because "D-369" or "a year
///   from now, $9,000 more" gives nothing to act on this week.
/// - Past the date: the missing money, without a countdown below zero.
/// - No date: just the missing money.
class _Deadline {
  const _Deadline({required this.text, this.chip, this.emphasized = true});

  /// Days left. Only for a near date: a countdown below zero reads as blame.
  final String? chip;
  final String text;
  final bool emphasized;

  String get semantics => chip == null ? text : '$chip. $text';

  /// A countdown stops being useful past about a month, the longest cycle.
  static const countdownDays = 31;

  static _Deadline? of(
    AppLocalizations l10n,
    SobraStore store,
    DateTime? targetDate,
    int missingCentavos,
  ) {
    if (missingCentavos <= 0) return null;
    String money(int centavos) =>
        formatMoney(store.currency, centavos, showCode: false);
    final missing = money(missingCentavos);
    if (targetDate == null) {
      return _Deadline(text: l10n.goalRemaining(missing));
    }
    final today = store.today;
    final days = daysBetween(today, targetDate);
    // Next year's 13 Nov must not read as this year's.
    final date = targetDate.year == today.year
        ? shortCycleDate(l10n, targetDate)
        : fullDate(l10n, targetDate);
    if (days < 0) {
      return _Deadline(
        text: l10n.goalCardDatePassed(date, missing),
        emphasized: false,
      );
    }
    final cycles = days > countdownDays
        ? store.payCyclesThrough(targetDate)
        : 1;
    if (cycles > 1) {
      // Rounded up to a whole unit: "$24.99 per cycle" asks for false
      // precision, and rounding down would end the plan short.
      final share = (missingCentavos + cycles - 1) ~/ cycles;
      final whole = (share + 99) ~/ 100 * 100;
      return _Deadline(text: l10n.goalCardPerCycle(date, money(whole)));
    }
    return _Deadline(
      chip: l10n.goalCardDaysLeft(days),
      text: l10n.goalCardUntil(date, missing),
    );
  }
}

class _DeadlineLine extends StatelessWidget {
  const _DeadlineLine({required this.deadline});

  final _Deadline deadline;

  @override
  Widget build(BuildContext context) {
    final chip = deadline.chip;
    return Row(
      key: const ValueKey('savings-goal-deadline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chip != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            color: AppColors.tealInk,
            child: Text(
              chip,
              style: pixelText(size: 12, bold: true, color: AppColors.surface),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            deadline.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: pixelText(
              size: 12,
              bold: true,
              color: deadline.emphasized
                  ? AppColors.tealInk
                  : AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
