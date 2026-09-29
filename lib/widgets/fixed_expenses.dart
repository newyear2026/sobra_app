import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../models/recurring_expense.dart';
import '../screens/fixed_expense_form_screen.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

/// The budget tab's list of this month's fixed expenses.
///
/// By calendar month rather than by pay cycle: rent and bills are thought of
/// per month, and nothing here feeds the cycle's figures above it.
class FixedExpensesSection extends StatelessWidget {
  const FixedExpensesSection({super.key, required this.onAdjustBudget});

  /// Opens the budget editor, for the one-time note after the first fixed
  /// expense suggests the budget may still be counting it.
  final VoidCallback onAdjustBudget;

  Future<void> _add(BuildContext context) async {
    final store = SobraScope.of(context);
    final wasFirst = store.recurringExpenses.isEmpty;
    final created = await Navigator.of(context).push<RecurringExpense>(
      MaterialPageRoute(builder: (_) => const FixedExpenseFormScreen()),
    );
    if (created == null || !wasFirst || !context.mounted) return;
    final adjust = await showFixedIntroSheet(context, created);
    if (adjust == true) onAdjustBudget();
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final currency = store.currency;
    final month = store.today;
    final occurrences = store.fixedOccurrencesInMonth(month);
    final total = occurrences.fold(0, (sum, o) => sum + o.amountCentavos);
    final paid = occurrences
        .where((occurrence) => occurrence.isPaid)
        .fold(0, (sum, occurrence) => sum + occurrence.amountCentavos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.fixedSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          l10n.fixedSectionMonth(monthAbbreviation(l10n, month.month)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        if (store.recurringExpenses.isEmpty)
          PixelEmptyState(
            icon: Icons.event_repeat,
            title: l10n.fixedSectionTitle,
            message: l10n.fixedEmptyBody,
          )
        else ...[
          if (occurrences.isNotEmpty) ...[
            Text(
              l10n.fixedPaidOfTotal(
                formatMoney(currency, paid, showCode: false),
                formatMoney(currency, total, showCode: false),
              ),
              style: pixelText(size: 13, bold: true, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 6),
            SegmentedProgress(value: total == 0 ? 0 : paid / total),
            const SizedBox(height: 8),
          ],
          PixelCard(
            elevation: PixelElevation.none,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: occurrences.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      l10n.fixedNothingThisMonth,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (final (index, occurrence)
                          in occurrences.indexed) ...[
                        if (index > 0)
                          const Divider(
                            height: 2,
                            thickness: 2,
                            color: AppColors.line,
                          ),
                        FixedOccurrenceRow(
                          occurrence: occurrence,
                          onTap: () => occurrence.isPaid
                              ? openFixedExpenseEditor(
                                  context,
                                  occurrence.expense,
                                )
                              : showFixedPaymentSheet(context, occurrence),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 10),
        PixelButton(
          label: l10n.fixedAdd,
          icon: Icons.add,
          variant: PixelButtonVariant.secondary,
          onPressed: () => _add(context),
        ),
      ],
    );
  }
}

Future<void> openFixedExpenseEditor(
  BuildContext context,
  RecurringExpense expense,
) => Navigator.of(context).push<RecurringExpense>(
  MaterialPageRoute(builder: (_) => FixedExpenseFormScreen(existing: expense)),
);

class FixedOccurrenceRow extends StatelessWidget {
  const FixedOccurrenceRow({super.key, required this.occurrence, this.onTap});

  final FixedOccurrence occurrence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = SobraScope.of(context).currency;
    final expense = occurrence.expense;
    final amount = formatMoney(
      currency,
      occurrence.amountCentavos,
      showCode: false,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CategoryIconBox(category: expense.category, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.movementSubtitle(
                      expense.frequency?.label(l10n) ?? '',
                      shortCycleDate(l10n, occurrence.date),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.isVariable && !occurrence.isPaid
                      ? l10n.fixedApprox(amount)
                      : amount,
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 3),
                FixedStatusTag(occurrence: occurrence),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FixedStatusTag extends StatelessWidget {
  const FixedStatusTag({super.key, required this.occurrence});

  final FixedOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final (background, ink) = switch (occurrence.status) {
      FixedOccurrenceStatus.paid => (AppColors.tealSoft, AppColors.tealInk),
      FixedOccurrenceStatus.dueToday => (AppColors.cashSoft, AppColors.cashInk),
      FixedOccurrenceStatus.overdue => (
        AppColors.dangerSoft,
        AppColors.dangerInk,
      ),
      _ => (AppColors.surface, AppColors.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (occurrence.isPaid) ...[
            Icon(Icons.check, size: 12, color: ink),
            const SizedBox(width: 3),
          ],
          Text(
            fixedStatusTag(AppLocalizations.of(context), occurrence),
            style: pixelText(size: 12, bold: true, color: ink),
          ),
        ],
      ),
    );
  }
}

/// Asks how a fixed expense was paid and files it.
Future<void> showFixedPaymentSheet(
  BuildContext context,
  FixedOccurrence occurrence,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _FixedPaymentSheet(
    occurrence: occurrence,
    currency: SobraScope.of(context).currency,
  ),
);

class _FixedPaymentSheet extends StatefulWidget {
  const _FixedPaymentSheet({required this.occurrence, required this.currency});

  final FixedOccurrence occurrence;

  /// Handed in: the field's opening figure is spelled in [initState].
  final Currency currency;

  @override
  State<_FixedPaymentSheet> createState() => _FixedPaymentSheetState();
}

class _FixedPaymentSheetState extends State<_FixedPaymentSheet> {
  late final TextEditingController _amount;
  late PaymentMethod _method;
  bool _saving = false;

  RecurringExpense get _expense => widget.occurrence.expense;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: amountFieldText(widget.currency, _expense.amountCentavos),
    )..addListener(() => setState(() {}));
    _method = _expense.paymentMethod;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = parseAmount(widget.currency, _amount.text);
    if (amount == null || _saving) return;
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final saved = await guardStoreWrite(
      messenger,
      l10n,
      () => store.recordFixedPayment(
        recurringId: _expense.id,
        occurrenceDate: widget.occurrence.date,
        amountCentavos: amount,
        paymentMethod: _method,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.fixedPaymentSaved(_expense.name))),
    );
  }

  Future<void> _billOnly() async {
    final amount = parseAmount(widget.currency, _amount.text);
    if (amount == null || _saving) return;
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final saved = await guardStoreWrite(
      messenger,
      l10n,
      () => store.updateRecurringExpense(
        _expense.copyWith(amountCentavos: amount),
      ),
    );
    if (!saved || !mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.fixedBillSaved(formatMoney(widget.currency, amount)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = widget.currency;
    final amount = parseAmount(currency, _amount.text);
    final cashMoves =
        amount != null &&
        _method == PaymentMethod.cash &&
        store.hasCashBaseline;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CategoryIconBox(category: _expense.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _expense.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        l10n.movementSubtitle(
                          _expense.frequency?.label(l10n) ?? '',
                          fixedDueLine(l10n, widget.occurrence),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amount,
              keyboardType: amountKeyboardType(currency),
              inputFormatters: amountInputFormattersFor(currency),
              style: pixelText(size: 26, bold: true),
              decoration: InputDecoration(
                labelText: l10n.fixedHowMuch,
                suffixText: currency.code,
              ),
            ),
            if (_expense.isVariable) ...[
              const SizedBox(height: 6),
              Text(
                l10n.fixedLastTime(
                  formatMoney(currency, _expense.amountCentavos),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 14),
            if (store.hasBudget || cashMoves)
              PixelHint(
                tone: PixelHintTone.teal,
                text: [
                  if (store.hasBudget)
                    l10n.fixedTodayUnchanged(
                      formatMoney(currency, store.todayRemainingCentavos),
                    ),
                  if (cashMoves)
                    l10n.fixedCashChange(
                      formatMoney(
                        currency,
                        store.expectedCashCentavos,
                        showCode: false,
                      ),
                      formatMoney(
                        currency,
                        store.expectedCashCentavos - amount,
                        showCode: false,
                      ),
                    ),
                ].join('\n'),
              ),
            const SizedBox(height: 18),
            PixelButton(
              label: l10n.fixedMarkPaid,
              icon: Icons.check,
              onPressed: amount == null || _saving ? null : _pay,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.fixedPaidWith(_method.label(l10n)),
                  style: pixelText(size: 13, color: AppColors.inkSoft),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _method = _method == PaymentMethod.cash
                        ? PaymentMethod.card
                        : PaymentMethod.cash,
                  ),
                  child: Text(l10n.fixedChange),
                ),
              ],
            ),
            if (_expense.isVariable) ...[
              const SizedBox(height: 4),
              PixelButton(
                label: l10n.fixedBillOnly,
                variant: PixelButtonVariant.secondary,
                onPressed: amount == null || _saving ? null : _billOnly,
              ),
            ],
            Center(
              child: TextButton(
                onPressed: () {
                  // The navigator outlives this sheet; its context does not.
                  final navigator = Navigator.of(context);
                  navigator
                    ..pop()
                    ..push<RecurringExpense>(
                      MaterialPageRoute(
                        builder: (_) =>
                            FixedExpenseFormScreen(existing: _expense),
                      ),
                    );
                },
                child: Text(l10n.fixedFormEditTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says once, after the first fixed expense, what the budget now means.
///
/// Returns true when the user wants to change the budget.
Future<bool?> showFixedIntroSheet(
  BuildContext context,
  RecurringExpense first,
) {
  final store = SobraScope.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.fixedIntroTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.fixedIntroBody(
                  formatMoney(store.currency, store.baseBudgetCentavos),
                  first.name,
                ),
                style: pixelText(
                  size: 14,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              PixelButton(
                label: l10n.fixedIntroKeep,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
              const SizedBox(height: 4),
              PixelButton(
                label: l10n.fixedIntroAdjust,
                variant: PixelButtonVariant.secondary,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Inicio's card for fixed expenses that are due today or a little late.
///
/// It asks once and steps aside: "Todavía no" hides it for the day, and a
/// date more than [SobraStore.fixedOverdueDaysOnHome] days gone stops showing
/// here at all and stays marked in the budget tab instead.
class FixedDueCard extends StatelessWidget {
  const FixedDueCard({
    super.key,
    required this.occurrences,
    required this.onSeeAll,
  });

  final List<FixedOccurrence> occurrences;
  final VoidCallback onSeeAll;

  Future<void> _markPaid(BuildContext context, FixedOccurrence due) async {
    // A bill that changes asks what it came to; a fixed one is filed as is.
    if (due.expense.isVariable) return showFixedPaymentSheet(context, due);
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await guardStoreWrite(
      messenger,
      l10n,
      () => store.recordFixedPayment(
        recurringId: due.expense.id,
        occurrenceDate: due.date,
        amountCentavos: due.expense.amountCentavos,
      ),
    );
    if (saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.fixedPaymentSaved(due.expense.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    final single = occurrences.length == 1 ? occurrences.single : null;

    return PixelCard(
      color: AppColors.violetSoft,
      borderColor: AppColors.violet,
      elevation: PixelElevation.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (single != null) ...[
                CategoryIconBox(category: single.expense.category, size: 36),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      single == null
                          ? l10n.fixedHomeLabel
                          : l10n.movementSubtitle(
                              l10n.fixedHomeLabel,
                              fixedDueLine(l10n, single),
                            ),
                      style: pixelText(
                        size: 12,
                        bold: true,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      single == null
                          ? l10n.fixedHomeMany(occurrences.length)
                          : l10n.movementSubtitle(
                              single.expense.name,
                              formatMoney(
                                currency,
                                single.amountCentavos,
                                showCode: false,
                              ),
                            ),
                      style: pixelText(size: 16, bold: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PixelButton(
                  label: single == null
                      ? l10n.fixedHomeSee
                      : l10n.fixedMarkPaid,
                  onPressed: single == null
                      ? onSeeAll
                      : () => _markPaid(context, single),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: l10n.fixedNotYet,
                  variant: PixelButtonVariant.secondary,
                  onPressed: () => guardStoreWrite(
                    ScaffoldMessenger.of(context),
                    l10n,
                    store.snoozeFixedHomeCard,
                  ),
                ),
              ),
            ],
          ),
          if (store.hasBudget) ...[
            const SizedBox(height: 4),
            Text(
              l10n.fixedTodayUnchanged(
                formatMoney(currency, store.todayRemainingCentavos),
              ),
              style: pixelText(size: 12, color: AppColors.violet),
            ),
          ],
        ],
      ),
    );
  }
}
