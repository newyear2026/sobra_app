import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/savings_goal.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

/// Completed snapshots remain readable after the user starts another goal.
class CompletedSavingsGoalsScreen extends StatelessWidget {
  const CompletedSavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final records = store.completedSavingsGoals;
    final active = store.activeSavingsGoal;
    final showCurrent =
        active != null &&
        store.isSavingsGoalComplete &&
        !records.any((record) => record.goal.id == active.id);

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
                  title: l10n.goalCompletedHistory,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                if (records.isEmpty && !showCurrent)
                  PixelEmptyState(
                    icon: Icons.flag_outlined,
                    title: l10n.goalCompletedHistory,
                    message: l10n.goalNoCompletedHistory,
                  ),
                if (showCurrent)
                  _CompletedGoalRow(
                    goal: active,
                    progressCentavos: store.savingsGoalProgressCentavos,
                  ),
                for (final record in records)
                  _CompletedGoalRow(
                    goal: record.goal,
                    progressCentavos: record.progressCentavos,
                    completedAt: record.completedAt,
                    purchaseCentavos: record.purchaseCentavos,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedGoalRow extends StatelessWidget {
  const _CompletedGoalRow({
    required this.goal,
    required this.progressCentavos,
    this.completedAt,
    this.purchaseCentavos,
  });

  final SavingsGoal goal;
  final int progressCentavos;
  final DateTime? completedAt;

  /// Set when the goal ended in buying the thing, often under the target.
  final int? purchaseCentavos;

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final date = completedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelCard(
        key: ValueKey('completed-goal-${goal.id}'),
        elevation: PixelElevation.none,
        color: AppColors.tealSoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              purchaseCentavos == null
                  ? Icons.verified
                  : Icons.shopping_bag_outlined,
              color: AppColors.tealInk,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name, style: pixelText(size: 17, bold: true)),
                  const SizedBox(height: 8),
                  Text(
                    '${formatMoney(store.currency, progressCentavos, showCode: false)} / '
                    '${formatMoney(store.currency, goal.targetCentavos)}',
                    style: pixelText(size: 14, bold: true),
                  ),
                  if (purchaseCentavos case final paid?) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.goalCompletedPurchased(
                        formatMoney(store.currency, paid, showCode: false),
                      ),
                      style: pixelText(size: 14, bold: true),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    date == null
                        ? l10n.goalCompleted
                        : l10n.goalCompletedOn(
                            MaterialLocalizations.of(
                              context,
                            ).formatFullDate(date),
                          ),
                    style: pixelText(size: 13, color: AppColors.tealInk),
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
