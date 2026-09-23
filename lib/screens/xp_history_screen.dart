import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/xp_event.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';

class XpHistoryScreen extends StatelessWidget {
  const XpHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = store.xpProgress;
    final events = store.xpEvents;

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
                  title: l10n.xpHistoryTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                LevelStrip(
                  level: progress.level,
                  title: xpLevelTitle(l10n, progress.level),
                  subtitle: l10n.xpTotal(progress.totalXp),
                  currentXp: progress.currentLevelXp,
                  targetXp: progress.targetLevelXp,
                  trailingLabel: progress.isMaxLevel
                      ? l10n.xpMaxLevel
                      : l10n.xpRemaining(progress.remainingXp),
                ),
                const SizedBox(height: 14),
                PixelHint(
                  tone: PixelHintTone.teal,
                  icon: Icons.verified_outlined,
                  text: l10n.xpHistoryHint,
                ),
                const SizedBox(height: 22),
                if (events.isEmpty)
                  PixelEmptyState(
                    icon: Icons.star_outline,
                    title: l10n.xpHistoryEmptyTitle,
                    message: l10n.xpHistoryEmptyMessage,
                  )
                else
                  ..._historyRows(context, events),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _historyRows(BuildContext context, List<XpEvent> events) {
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[];
    String? previousDay;
    for (final event in events) {
      final day = fullDate(l10n, event.occurredAt);
      if (day != previousDay) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
        rows
          ..add(Text(day, style: Theme.of(context).textTheme.titleSmall))
          ..add(const SizedBox(height: 8));
        previousDay = day;
      }
      rows
        ..add(_XpEventCard(event: event))
        ..add(const SizedBox(height: 9));
    }
    return rows;
  }
}

class _XpEventCard extends StatelessWidget {
  const _XpEventCard({required this.event});

  final XpEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _colorsFor(event.kind);
    return PixelCard(
      elevation: PixelElevation.none,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.$1,
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: Icon(_iconFor(event.kind), size: 20, color: colors.$2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title(l10n),
                      style: pixelText(size: 14, bold: true),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.kind.shortDetail(l10n),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.xpAmount(event.xp),
                style: pixelText(
                  size: 15,
                  bold: true,
                  color: AppColors.tealInk,
                ),
              ),
            ],
          ),
          if (event.hasCalculation) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showCalculation(context, event),
                child: Text(l10n.xpSeeCalculation),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCalculation(BuildContext context, XpEvent event) {
    final l10n = AppLocalizations.of(context);
    final currency = SobraScope.of(context).currency;
    final budget = event.budgetCentavos;
    final spent = event.spentCentavos;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.xpCalculationTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              if (event.cycleStart != null && event.cycleEnd != null)
                _DetailRow(
                  label: l10n.xpDetailCycle,
                  value: cycleDateRange(
                    l10n,
                    event.cycleStart!,
                    event.cycleEnd!,
                  ),
                ),
              if (budget != null)
                _DetailRow(
                  label: l10n.xpDetailBudget,
                  value: formatMoney(currency, budget),
                ),
              if (spent != null)
                _DetailRow(
                  label: l10n.xpDetailSpent,
                  value: formatMoney(currency, spent),
                ),
              if (budget != null && spent != null)
                _DetailRow(
                  label: l10n.xpDetailResult,
                  value: formatMoney(currency, budget - spent),
                ),
              _DetailRow(
                label: l10n.xpDetailRule,
                value: _ruleFor(l10n, event),
              ),
              const Divider(height: 24),
              _DetailRow(
                label: l10n.xpDetailCredited,
                value: l10n.xpAmount(event.xp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ruleFor(AppLocalizations l10n, XpEvent event) => switch (event.kind) {
    XpEventKind.cashCount => l10n.xpRuleCashCount,
    XpEventKind.cycleInGreen => l10n.xpRuleCycleInGreen(
      event.cycleEnd!.difference(event.cycleStart!).inDays + 1,
    ),
    XpEventKind.daysUnderDailyLimit => l10n.xpRuleDaysUnderDailyLimit(
      event.quantity ?? 0,
    ),
    XpEventKind.firstSuccessfulCycle => l10n.xpRuleFirstSuccessfulCycle,
    XpEventKind.dailyMissionRecord ||
    XpEventKind.dailyMissionSameDay ||
    XpEventKind.dailyMissionBudget ||
    XpEventKind.dailyMissionNote ||
    XpEventKind.dailyMissionReceipt ||
    XpEventKind.dailyMissionThreeToday => l10n.xpRuleDailyMission,
  };

  IconData _iconFor(XpEventKind kind) => switch (kind) {
    XpEventKind.cashCount => Icons.payments_outlined,
    XpEventKind.cycleInGreen => Icons.check,
    XpEventKind.daysUnderDailyLimit => Icons.calendar_month_outlined,
    XpEventKind.firstSuccessfulCycle => Icons.star,
    XpEventKind.dailyMissionRecord => Icons.edit_outlined,
    XpEventKind.dailyMissionSameDay => Icons.today_outlined,
    XpEventKind.dailyMissionBudget => Icons.bar_chart_outlined,
    XpEventKind.dailyMissionNote => Icons.sticky_note_2_outlined,
    XpEventKind.dailyMissionReceipt => Icons.receipt_long_outlined,
    XpEventKind.dailyMissionThreeToday => Icons.playlist_add_check,
  };

  (Color, Color) _colorsFor(XpEventKind kind) => switch (kind) {
    XpEventKind.cashCount => (AppColors.cashSoft, AppColors.cashInk),
    XpEventKind.cycleInGreen => (AppColors.tealSoft, AppColors.tealInk),
    XpEventKind.daysUnderDailyLimit => (AppColors.violetSoft, AppColors.violet),
    XpEventKind.firstSuccessfulCycle => (AppColors.blueSoft, AppColors.blue),
    XpEventKind.dailyMissionRecord => (AppColors.tealSoft, AppColors.tealInk),
    XpEventKind.dailyMissionSameDay => (AppColors.violetSoft, AppColors.violet),
    XpEventKind.dailyMissionBudget => (AppColors.blueSoft, AppColors.blue),
    XpEventKind.dailyMissionNote => (AppColors.cashSoft, AppColors.cashInk),
    XpEventKind.dailyMissionReceipt => (
      AppColors.dangerSoft,
      AppColors.dangerInk,
    ),
    XpEventKind.dailyMissionThreeToday => (
      AppColors.tealSoft,
      AppColors.tealInk,
    ),
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: pixelText(size: 13, bold: true),
          ),
        ),
      ],
    ),
  );
}
