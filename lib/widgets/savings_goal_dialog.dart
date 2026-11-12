import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/xp_event.dart';
import '../screens/savings_goal_screen.dart';
import '../screens/settlement_screen.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

enum _AllocationAction { createGoal, allocated, details }

/// A cycle remains the source through goal creation. Nothing is recorded as
/// initial savings or new income; only the final confirmation writes it.
///
/// [settlement] is the cycle-close notice when this popup stands in for the
/// settlement screen. The popup then carries the cycle's XP and a link to the
/// full settlement, so closing a green cycle never hides what it earned.
Future<bool> showCycleGoalAllocation(
  BuildContext context, {
  required DateTime cycleStart,
  XpNotice? settlement,
}) async {
  final store = SobraScope.of(context);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (store.availableGoalAllocationForCycle(cycleStart) <= 0) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.goalCycleUnavailable)));
    return false;
  }
  final acknowledged = await guardStoreWrite(
    messenger,
    l10n,
    () => store.acknowledgeSavingsGoalCyclePrompt(cycleStart),
  );
  if (!acknowledged || !context.mounted) return false;
  while (context.mounted) {
    final previous = store.activeSavingsGoal;
    final replaceCompleted = store.isSavingsGoalComplete;
    final action = await showDialog<_AllocationAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x80202848),
      builder: (_) =>
          _GoalAllocationDialog(cycleStart: cycleStart, settlement: settlement),
    );
    if (!context.mounted || action == null) return false;
    if (action == _AllocationAction.details) {
      final start = DateTime(cycleStart.year, cycleStart.month, cycleStart.day);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SettlementScreen(
            notice: settlement!,
            record: store.cycleRecords
                .where((record) => record.start == start)
                .firstOrNull,
          ),
        ),
      );
      return false;
    }
    if (action == _AllocationAction.allocated) {
      if (store.pendingSavingsGoalCompletionId != null) {
        await showSavingsGoalCompletion(context);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.goalAllocationSaved(
                  formatMoney(
                    store.currency,
                    store.goalAllocationForCycle(cycleStart),
                    showCode: false,
                  ),
                ),
              ),
            ),
          );
      }
      return true;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SavingsGoalScreen(
          replacingCompletedGoalId: replaceCompleted ? previous?.id : null,
        ),
      ),
    );
    if (!context.mounted) return false;
    final created = store.activeSavingsGoal;
    if (created == null || created.id == previous?.id) return false;
    if (store.isSavingsGoalComplete) {
      await showSavingsGoalCompletion(context);
      return false;
    }
    if (store.availableGoalAllocationForCycle(cycleStart) <= 0) return false;
  }
  return false;
}

/// Completion is acknowledged durably, independently of closing the modal or
/// choosing a new goal. The completed goal stays active until a new one saves.
Future<void> showSavingsGoalCompletion(BuildContext context) async {
  final store = SobraScope.of(context);
  final id = store.pendingSavingsGoalCompletionId;
  final goal = store.activeSavingsGoal;
  if (id == null || goal == null || goal.id != id) return;
  final l10n = AppLocalizations.of(context);
  final acknowledged = await guardStoreWrite(
    ScaffoldMessenger.of(context),
    l10n,
    () => store.acknowledgeSavingsGoalCompletion(id),
  );
  if (!acknowledged || !context.mounted) return;
  if (store.activeSavingsGoal?.id != id || !store.isSavingsGoalComplete) return;
  final create = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x80202848),
    builder: (dialogContext) => _GoalDialogFrame(
      key: const ValueKey('goal-completion-dialog'),
      title: l10n.goalCompletionTitle,
      onClose: () => Navigator.pop(dialogContext, false),
      children: [
        const Icon(Icons.verified_outlined, color: AppColors.teal, size: 36),
        const SizedBox(height: 10),
        Text(
          l10n.goalCompletionHeadline(goal.name),
          textAlign: TextAlign.center,
          style: pixelText(size: 24, bold: true),
        ),
        const SizedBox(height: 12),
        Text(
          formatMoney(
            store.currency,
            store.savingsGoalProgressCentavos,
            showCode: false,
          ),
          textAlign: TextAlign.center,
          style: pixelText(size: 25, bold: true, color: AppColors.tealInk),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.goalCompletionBody,
          textAlign: TextAlign.center,
          style: pixelText(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        PixelButton(
          key: const ValueKey('goal-completion-confirm'),
          label: MaterialLocalizations.of(dialogContext).okButtonLabel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        TextButton(
          key: const ValueKey('goal-completion-new-goal'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.goalNewGoal),
        ),
        Text(
          l10n.goalCompletionKept,
          textAlign: TextAlign.center,
          style: pixelText(size: 12, color: AppColors.muted),
        ),
      ],
    ),
  );
  if (create != true || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SavingsGoalScreen(replacingCompletedGoalId: id),
    ),
  );
}

class _GoalAllocationDialog extends StatefulWidget {
  const _GoalAllocationDialog({required this.cycleStart, this.settlement});
  final DateTime cycleStart;
  final XpNotice? settlement;

  @override
  State<_GoalAllocationDialog> createState() => _GoalAllocationDialogState();
}

class _GoalAllocationDialogState extends State<_GoalAllocationDialog> {
  final _amount = TextEditingController();
  bool _initialized = false;
  bool _editing = false;
  bool _saving = false;
  String? _goalId;
  String? _error;
  int _initialAmount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = SobraScope.of(context);
    _goalId = store.activeSavingsGoal?.id;
    final existing = store.goalAllocationForCycle(widget.cycleStart);
    _initialAmount = existing > 0
        ? existing
        : store.availableGoalAllocationForCycle(widget.cycleStart);
    _amount.text = amountFieldText(store.currency, _initialAmount);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final maximum = store.availableGoalAllocationForCycle(widget.cycleStart);
    final amount = _editing
        ? parseAmount(store.currency, _amount.text)
        : _initialAmount;
    if (amount == null || amount <= 0 || amount > maximum) {
      setState(() {
        _editing = true;
        _error = l10n.goalAllocationInvalid(
          formatMoney(store.currency, maximum, showCode: false),
        );
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await store.allocateCycleToSavingsGoal(
        cycleStart: widget.cycleStart,
        goalId: _goalId!,
        amountCentavos: amount,
      );
      if (!mounted) return;
      Navigator.pop(context, _AllocationAction.allocated);
    } on Object catch (error) {
      if (mounted) setState(() => _error = describeStoreFailure(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = store.activeSavingsGoal;
    final maximum = store.availableGoalAllocationForCycle(widget.cycleStart);
    final existing = store.goalAllocationForCycle(widget.cycleStart);
    final completed = store.isSavingsGoalComplete;
    final needsGoal = goal == null || (completed && existing == 0);
    final chosen = _editing
        ? parseAmount(store.currency, _amount.text) ?? 0
        : _initialAmount;
    final preview = store.savingsGoalProgressCentavos - existing + chosen;
    String money(int value) =>
        formatMoney(store.currency, value, showCode: false);
    void close() => Navigator.pop(context);

    return PopScope(
      canPop: !_saving,
      child: _GoalDialogFrame(
        key: const ValueKey('goal-allocation-dialog'),
        title: l10n.goalCyclePopupTitle,
        onClose: _saving ? null : close,
        children: [
          Text(
            l10n.goalCycleLeftover(money(maximum)),
            style: pixelText(size: 22, bold: true, color: AppColors.tealInk),
          ),
          if (widget.settlement case final notice? when notice.xp > 0) ...[
            const SizedBox(height: 10),
            _CycleXpRow(notice: notice),
          ],
          const SizedBox(height: 12),
          if (needsGoal) ...[
            Text(
              completed
                  ? l10n.goalNextGoalInvitation
                  : l10n.goalNoGoalInvitation,
              style: pixelText(size: 17, bold: true),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.goalNoGoalExamples,
              style: pixelText(size: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            PixelButton(
              key: const ValueKey('goal-allocation-create'),
              label: completed ? l10n.goalNewGoal : l10n.goalCreateAndAllocate,
              maxLines: 2,
              onPressed: () =>
                  Navigator.pop(context, _AllocationAction.createGoal),
            ),
            TextButton(
              key: const ValueKey('goal-allocation-later'),
              onPressed: close,
              child: Text(l10n.goalLater),
            ),
            Text(
              l10n.goalCreateThenConfirm,
              textAlign: TextAlign.center,
              style: pixelText(size: 13, color: AppColors.muted),
            ),
          ] else ...[
            Text(l10n.goalCycleApplyTo(goal.name), style: pixelText(size: 15)),
            const SizedBox(height: 16),
            if (_editing) ...[
              TextField(
                key: const ValueKey('goal-allocation-amount'),
                controller: _amount,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AmountInputFormatter(store.currency)],
                decoration: InputDecoration(
                  labelText: l10n.goalAllocationAmount,
                  prefixText: store.currency.symbol,
                  suffixText: store.currency.code,
                  helperText: l10n.goalAllocationMaximum(money(maximum)),
                  helperMaxLines: 3,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
            ],
            _GoalAmountRow(
              label: l10n.goalCurrentAmount,
              amount: money(store.savingsGoalProgressCentavos),
            ),
            const SizedBox(height: 8),
            _GoalAmountRow(
              label: l10n.goalAfterAmount,
              amount: money(preview),
              emphasize: true,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(
                _error!,
                style: pixelText(size: 13, color: AppColors.dangerInk),
              ),
              const SizedBox(height: 10),
            ],
            PixelButton(
              key: const ValueKey('goal-allocation-confirm'),
              label: !_editing && existing == 0
                  ? l10n.goalAllocateAll(money(chosen))
                  : l10n.goalAllocateAmount(money(chosen)),
              maxLines: 2,
              onPressed: _saving || maximum <= 0 ? null : _confirm,
            ),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              children: [
                if (!_editing)
                  TextButton(
                    key: const ValueKey('goal-allocation-change-amount'),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _editing = true),
                    child: Text(l10n.goalChangeAmount),
                  ),
                TextButton(
                  key: const ValueKey('goal-allocation-later'),
                  onPressed: _saving ? null : close,
                  child: Text(l10n.goalLater),
                ),
              ],
            ),
            Text(
              l10n.goalAllocationNotice,
              textAlign: TextAlign.center,
              style: pixelText(size: 13, color: AppColors.muted),
            ),
          ],
          if (widget.settlement != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              key: const ValueKey('goal-allocation-details'),
              onPressed: _saving
                  ? null
                  : () => Navigator.pop(context, _AllocationAction.details),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(l10n.goalCycleDetails),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalDialogFrame extends StatelessWidget {
  const _GoalDialogFrame({
    super.key,
    required this.title,
    required this.onClose,
    required this.children,
  });
  final String title;
  final VoidCallback? onClose;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    alignment: const Alignment(0, -0.4),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: SingleChildScrollView(
        child: PixelCard(
          color: AppColors.surface,
          elevation: PixelElevation.hero,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: pixelText(size: 16, bold: true)),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class _GoalAmountRow extends StatelessWidget {
  const _GoalAmountRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });
  final String label;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 4,
    children: [
      Text(label, style: pixelText(size: 14, bold: true)),
      Text(
        amount,
        style: pixelText(
          size: 16,
          bold: true,
          color: emphasize ? AppColors.tealInk : AppColors.ink,
        ),
      ),
    ],
  );
}

/// The cycle's XP, as the settlement screen would have announced it.
class _CycleXpRow extends StatelessWidget {
  const _CycleXpRow({required this.notice});
  final XpNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PixelCard(
      key: const ValueKey('goal-allocation-xp'),
      elevation: PixelElevation.none,
      color: AppColors.cashSoft,
      borderColor: AppColors.cashInk,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppColors.cash),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.xpAmount(notice.xp),
                  style: pixelText(
                    size: 16,
                    bold: true,
                    color: AppColors.cashInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  xpNoticeDetail(l10n, notice),
                  style: pixelText(size: 13, color: AppColors.cashInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
