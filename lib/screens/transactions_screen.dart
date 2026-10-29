import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/money_movement.dart';
import '../models/pay_schedule.dart';
import '../services/native_ad_service.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/receipt_field.dart';
import '../widgets/sobra_native_ad.dart';
import '../widgets/transaction_row.dart';

enum _LedgerKind { expense, income }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _LedgerKind _kind = _LedgerKind.expense;

  String _groupLabel(AppLocalizations l10n, DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return l10n.today;
    if (day == addDays(today, -1)) return l10n.yesterday;
    return shortCycleDate(l10n, day);
  }

  bool _matches(MoneyMovement movement) => switch (_kind) {
    _LedgerKind.expense =>
      movement.expense != null || movement.reconciliation != null,
    _LedgerKind.income => movement.income != null,
  };

  /// Deletes what a row stands for, or says why it has to stay.
  ///
  /// Both halves of a cash count are pinned. The count hides its own row in
  /// favour of the expense or income it produced, so removing that one row
  /// would take the whole count off the ledger while the counted cash figure
  /// kept the money — the two would stop telling the same story.
  ///
  /// Reports whether the row went, so the edit sheet knows to close.
  Future<bool> _deleteMovement(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    SobraStore store,
    MoneyMovement movement,
  ) async {
    final expense = movement.expense;
    final income = movement.income;
    if (expense == null && income == null) return false;

    var removed = false;
    final wrote = await guardStoreWrite(messenger, l10n, () async {
      removed = expense != null
          ? await store.deleteExpense(expense.id)
          : await store.deleteIncome(income!.id);
    });
    if (!wrote) return false;

    // An undo waiting behind an XP notice is an undo that times out unseen.
    messenger.hideCurrentSnackBar();
    if (!removed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            expense != null
                ? l10n.transactionsExpensePinned
                : l10n.transactionsIncomePinned,
          ),
        ),
      );
      return false;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          expense != null
              ? l10n.transactionsExpenseDeleted
              : l10n.transactionsIncomeDeleted,
        ),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(
            guardStoreWrite(
              messenger,
              l10n,
              () => expense != null
                  ? store.restoreExpense(expense)
                  : store.restoreIncome(income!),
            ),
          ),
        ),
      ),
    );
    return true;
  }

  /// The ⋮ menu for a row, or nothing at all when it would be empty.
  ///
  /// A cash-count income can be neither edited nor deleted, so without this
  /// it keeps a button that opens onto nothing. Its expense counterpart still
  /// has a menu, because the category and the note are always the user's.
  Widget? _rowMenu(
    BuildContext context,
    SobraStore store,
    MoneyMovement movement,
  ) {
    final l10n = AppLocalizations.of(context);
    final expense = movement.expense;
    final income = movement.income;
    final canEdit =
        expense != null || (income != null && !income.isLinkedToCashCount);
    // Either half of a cash count measures money that already moved, so there
    // is nothing to undo here.
    final canDelete =
        (expense != null || income != null) &&
        expense?.isLinkedToCashCount != true &&
        income?.isLinkedToCashCount != true;
    if (!canEdit && !canDelete) return null;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 22),
      iconSize: 17,
      onSelected: (value) async {
        if (value == 'edit') {
          await _edit(context, store, movement);
          return;
        }
        if (value != 'delete') return;
        await _deleteMovement(
          ScaffoldMessenger.of(context),
          AppLocalizations.of(context),
          store,
          movement,
        );
      },
      itemBuilder: (_) => [
        if (canEdit) PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
        if (canDelete) PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
    );
  }

  /// Whether tapping the row opens an editor. A cash-count income has
  /// nothing the user could change, so it has no sheet to open.
  bool _canEdit(MoneyMovement movement) =>
      movement.expense != null ||
      (movement.income != null && !movement.income!.isLinkedToCashCount);

  /// Opens the editor for an expense or income row.
  ///
  /// Tapping the row is where people look for delete, so the sheet carries it
  /// too, through the same path as the ⋮ menu. The messenger is the ledger's:
  /// the undo has to outlive the sheet that asked for it.
  Future<void> _edit(
    BuildContext context,
    SobraStore store,
    MoneyMovement movement,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    Future<bool> delete() => _deleteMovement(messenger, l10n, store, movement);
    final expense = movement.expense;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // The income editor can run the full height; it stops under the status
      // bar instead of putting its title behind it.
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 3),
      ),
      builder: (_) => expense != null
          ? _EditExpenseSheet(
              entry: expense,
              currency: store.currency,
              onDelete: delete,
            )
          : _EditIncomeSheet(
              entry: movement.income!,
              currency: store.currency,
              onDelete: delete,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = store.movements.where(_matches).toList();
    final grouped = <String, List<MoneyMovement>>{};
    for (final entry in entries) {
      final label = _groupLabel(l10n, entry.occurredAt, store.today);
      grouped.putIfAbsent(label, () => []).add(entry);
    }
    final nativeAds = NativeAdScope.maybeOf(context);
    // Under the third row, or under the last one when there are fewer, so a
    // ledger with even one movement has a place for it. Never above a row.
    final adAfterRow = entries.length < 3 ? entries.length : 3;
    final ledger = <Widget>[];
    var movementIndex = 0;
    for (final group in grouped.entries) {
      ledger.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 5),
          child: Text(
            group.key,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
      ledger.add(const Divider(height: 1));
      for (final movement in group.value) {
        ledger.add(
          MovementRow(
            movement: movement,
            onTap: _canEdit(movement)
                ? () => _edit(context, store, movement)
                : null,
            trailing: _rowMenu(context, store, movement),
          ),
        );
        movementIndex++;
        // Date headings are deliberately not counted: the rows above the ad
        // are real movements, even when the last of them ends a date group.
        if (movementIndex == adAfterRow && nativeAds?.shouldPlace == true) {
          ledger.add(
            SobraNativeAd(
              key: ValueKey('native-ad-${nativeAds!.visitId}'),
              controller: nativeAds,
            ),
          );
        }
      }
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('movements-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          PixelTopBar(title: l10n.transactionsTitle),
          const SizedBox(height: 18),
          PixelSegmented<_LedgerKind>(
            segments: [
              PixelSegment(
                value: _LedgerKind.expense,
                label: l10n.registerExpense,
              ),
              PixelSegment(
                value: _LedgerKind.income,
                label: l10n.registerIncome,
              ),
            ],
            selected: _kind,
            onChanged: (value) => setState(() => _kind = value),
          ),
          const SizedBox(height: 18),
          _DailyChartCard(store: store, kind: _kind),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            PixelEmptyState(
              icon: _kind == _LedgerKind.income
                  ? Icons.arrow_upward
                  : Icons.receipt_long_outlined,
              title: _kind == _LedgerKind.income
                  ? l10n.transactionsEmptyIncomesTitle
                  : l10n.transactionsEmptyExpensesTitle,
              message: _kind == _LedgerKind.income
                  ? l10n.transactionsEmptyIncomesMessage
                  : l10n.transactionsEmptyExpensesMessage,
            ),
          ...ledger,
        ],
      ),
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({
    required this.entry,
    required this.currency,
    required this.onDelete,
  });
  final ExpenseEntry entry;

  /// Handed in rather than read from the scope: the figure the sheet opens on
  /// is spelled in [initState], out of reach of an inherited widget.
  final Currency currency;

  /// Deletes the entry, reporting whether it went.
  final Future<bool> Function() onDelete;
  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ExpenseCategory _category;
  late String? _receiptFileName;
  late DateTime _occurredAt;

  @override
  void initState() {
    super.initState();
    _occurredAt = widget.entry.occurredAt;
    _amountController = TextEditingController(
      text: amountFieldText(widget.currency, widget.entry.amountCentavos),
    );
    _noteController = TextEditingController(
      text: widget.entry.isPendingCashAdjustment ? '' : widget.entry.note,
    );
    _category = widget.entry.category;
    _receiptFileName = widget.entry.receiptFileName;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(widget.currency, _amountController.text);
    if (amount == null && !widget.entry.isLinkedToCashCount) return;
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // The sheet stays open on a failure, with the user's edit still in it, so
    // there is something to retry rather than a change that looked saved.
    final saved = await guardStoreWrite(messenger, l10n, () {
      if (widget.entry.isPendingCashAdjustment) {
        return store.classifyPendingCashExpense(
          expenseId: widget.entry.id,
          category: _category,
          note: _noteController.text,
          receiptFileName: _receiptFileName,
        );
      }
      return store.updateExpense(
        widget.entry.copyWith(
          amountCentavos: amount ?? widget.entry.amountCentavos,
          category: _category,
          note: _noteController.text.trim(),
          occurredAt: _occurredAt,
          receiptFileName: _receiptFileName,
          clearReceipt: _receiptFileName == null,
        ),
      );
    });
    if (saved && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final removed = await widget.onDelete();
    if (removed && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    final dueDate = entry.occurrenceDate;
    return _SheetFrame(
      children: [
        Text(
          widget.entry.isPendingCashAdjustment
              ? l10n.identifyDifference
              : l10n.editMovement,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _amountController,
          enabled: !widget.entry.isLinkedToCashCount,
          keyboardType: amountKeyboardType(widget.currency),
          inputFormatters: amountInputFormattersFor(widget.currency),
          decoration: InputDecoration(
            labelText: l10n.amount,
            suffixText: widget.currency.code,
          ),
        ),
        if (widget.entry.isLinkedToCashCount) ...[
          const SizedBox(height: 10),
          PixelHint(tone: PixelHintTone.cash, text: l10n.editPendingHint),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: _category,
          decoration: InputDecoration(labelText: l10n.category),
          items: ExpenseCategory.values
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.label(l10n)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: l10n.note,
            hintText: l10n.noteExample,
          ),
        ),
        const SizedBox(height: 14),
        ReceiptField(
          fileName: _receiptFileName,
          onChanged: (value) => setState(() => _receiptFileName = value),
        ),
        const SizedBox(height: 16),
        // A fixed payment can move the day it was paid; the due date it
        // settles is a separate field, so its installment stays put. A
        // cash count's date is the count itself, pinned like its amount.
        _DateField(
          label: entry.isFixedPayment ? l10n.editPaidDate : l10n.registerDate,
          date: _occurredAt,
          hint: entry.isLinkedToCashCount
              ? null
              : entry.isFixedPayment && dueDate != null
              ? l10n.editFixedOccurrence(shortCycleDate(l10n, dueDate))
              : l10n.registerNoFutureMovements,
          onChanged: entry.isLinkedToCashCount
              ? null
              : (value) => setState(() => _occurredAt = value),
        ),
        if (widget.entry.isPendingCashAdjustment) ...[
          const SizedBox(height: 12),
          PixelCard(
            elevation: PixelElevation.none,
            color: AppColors.tealSoft,
            child: Text(
              l10n.replacesPendingHint,
              style: const TextStyle(
                color: AppColors.teal,
                fontVariations: AppType.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        PixelButton(
          label: widget.entry.isPendingCashAdjustment
              ? l10n.saveWithoutDuplicating
              : l10n.saveChanges,
          onPressed: _save,
        ),
        const SizedBox(height: 8),
        // A cash-count expense keeps its place in the sheet with the reason
        // it cannot go; a missing button read as a broken delete.
        if (widget.entry.isLinkedToCashCount)
          PixelHint(
            tone: PixelHintTone.cash,
            icon: Icons.lock_outline,
            text: l10n.transactionsExpensePinned,
          )
        else
          PixelButton(
            label: l10n.delete,
            icon: Icons.delete_outline,
            variant: PixelButtonVariant.danger,
            onPressed: _delete,
          ),
      ],
    );
  }
}

/// An income on file, opened from its row.
///
/// The same fields the register screen asks for, so changing an income reads
/// like recording it. A cash-count income never gets here: its amount and day
/// are the count, and there is nothing else on it to change.
class _EditIncomeSheet extends StatefulWidget {
  const _EditIncomeSheet({
    required this.entry,
    required this.currency,
    required this.onDelete,
  });
  final IncomeEntry entry;
  final Currency currency;

  /// Deletes the entry, reporting whether it went.
  final Future<bool> Function() onDelete;

  @override
  State<_EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends State<_EditIncomeSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late IncomeKind _kind;
  late IncomeAllocation _allocation;
  late PaymentMethod _destination;
  late DateTime _occurredAt;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _amountController = TextEditingController(
      text: amountFieldText(widget.currency, entry.amountCentavos),
    );
    _noteController = TextEditingController(text: entry.note);
    _kind = entry.kind;
    _allocation = entry.allocation;
    _destination = entry.destination;
    _occurredAt = entry.occurredAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(widget.currency, _amountController.text);
    if (amount == null) return;
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    final saved = await guardStoreWrite(
      messenger,
      l10n,
      () => store.updateIncome(
        IncomeEntry(
          id: entry.id,
          amountCentavos: amount,
          kind: _kind,
          note: _noteController.text.trim(),
          occurredAt: _occurredAt,
          destination: _destination,
          allocation: _allocation,
        ),
      ),
    );
    if (saved && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final removed = await widget.onDelete();
    if (removed && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return _SheetFrame(
      children: [
        Text(l10n.editIncome, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        TextField(
          controller: _amountController,
          keyboardType: amountKeyboardType(widget.currency),
          inputFormatters: amountInputFormattersFor(widget.currency),
          decoration: InputDecoration(
            labelText: l10n.amount,
            suffixText: widget.currency.code,
          ),
        ),
        // Only the two kinds the register screen offers can be swapped. A
        // refund or a cash income keeps the kind it came in with.
        if (_kind == IncomeKind.salary || _kind == IncomeKind.extra) ...[
          const SizedBox(height: 16),
          Text(l10n.registerIncomeKind, style: titleStyle),
          const SizedBox(height: 8),
          PixelSegmented<IncomeKind>(
            segments: [
              for (final kind in const [IncomeKind.salary, IncomeKind.extra])
                PixelSegment(value: kind, label: kind.label(l10n)),
            ],
            selected: _kind,
            onChanged: (value) => setState(() => _kind = value),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.registerWhatToDo, style: titleStyle),
        const SizedBox(height: 8),
        PixelSegmented<IncomeAllocation>(
          segments: [
            PixelSegment(
              value: IncomeAllocation.cycle,
              label: l10n.registerThisCycle,
            ),
            PixelSegment(
              value: IncomeAllocation.savings,
              label: l10n.registerSaveIt,
            ),
          ],
          selected: _allocation,
          onChanged: (value) => setState(() => _allocation = value),
        ),
        const SizedBox(height: 16),
        Text(l10n.registerReceivedIn, style: titleStyle),
        const SizedBox(height: 8),
        PixelSegmented<PaymentMethod>(
          segments: [
            PixelSegment(
              value: PaymentMethod.cash,
              label: PaymentMethod.cash.label(l10n),
              icon: Icons.payments,
            ),
            PixelSegment(
              value: PaymentMethod.card,
              label: l10n.registerAccount,
              icon: Icons.account_balance,
            ),
          ],
          selected: _destination,
          onChanged: (value) => setState(() => _destination = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: l10n.note,
            hintText: l10n.registerNoteIncomeExample,
          ),
        ),
        const SizedBox(height: 16),
        _DateField(
          label: l10n.registerDate,
          date: _occurredAt,
          hint: l10n.registerNoFutureMovements,
          onChanged: (value) => setState(() => _occurredAt = value),
        ),
        const SizedBox(height: 20),
        PixelButton(label: l10n.saveChanges, onPressed: _save),
        const SizedBox(height: 8),
        PixelButton(
          label: l10n.delete,
          icon: Icons.delete_outline,
          variant: PixelButtonVariant.danger,
          onPressed: _delete,
        ),
      ],
    );
  }
}

/// The bottom sheet's padding and scroll, shared by both editors.
///
/// Scrolls because the income editor runs taller than a small phone with the
/// keyboard up, and an edit sheet whose save button sits under the keyboard
/// cannot be saved.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

/// The register screen's date row, for a movement already on file.
///
/// [onChanged] null locks it: the row stays, greyed with a lock, so the date
/// is still there to read and its absence never looks like a missing feature.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime>? onChanged;
  final String? hint;

  /// Picks a day in the range the register screen offers, and keeps the
  /// moment's time when the day does not change. A new day today takes the
  /// clock's time; any other takes noon, as a new past entry would.
  Future<void> _pick(
    BuildContext context,
    ValueChanged<DateTime> onChanged,
  ) async {
    final store = SobraScope.of(context);
    final today = store.today;
    final firstDate = DateTime(today.year - 1);
    final current = dateOnly(date);
    final selected = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate) ? firstDate : current,
      firstDate: current.isBefore(firstDate) ? current : firstDate,
      lastDate: today,
    );
    if (selected == null || dateOnly(selected) == current) return;
    onChanged(
      dateOnly(selected) == today
          ? store.currentMoment
          : DateTime(selected.year, selected.month, selected.day, 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final change = onChanged;
    final locked = change == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        PixelCard(
          elevation: PixelElevation.none,
          color: locked ? AppColors.beige : AppColors.surface,
          onTap: locked ? null : () => _pick(context, change),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: locked ? AppColors.muted : AppColors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullDate(l10n, date),
                  style: pixelText(
                    size: 15,
                    bold: true,
                    color: locked ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.expand_more,
                color: locked ? AppColors.muted : AppColors.ink,
              ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// The cycle's shape, above the list that spells it out.
class _DailyChartCard extends StatelessWidget {
  const _DailyChartCard({required this.store, required this.kind});

  final SobraStore store;
  final _LedgerKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bounds = store.cycleBounds;
    final showingIncome = kind == _LedgerKind.income;
    // The even share of the *planned* budget. `totalBudgetCentavos` also
    // carries extra income assigned to this cycle, and using that as the
    // scale would squash the bars the moment a large inflow lands — the
    // chart would stop being about spending. Home and Presupuesto still
    // count that extra as spendable; this line does not.
    //
    // `dailyAllowanceCentavos` is also rejected: that one moves as the
    // cycle is spent, so past days would be measured against a line that
    // did not exist when they happened. Income has no such line at all.
    // Zero already means "draw no limit line": that is what the income tab
    // passes. A cycle with no budget has no daily share to draw either.
    final perDay = !store.hasBudget || bounds.lengthInDays <= 0
        ? 0
        : store.cycleBaseBudgetCentavos ~/ bounds.lengthInDays;
    final cycleIncome = store.cycleIncomes.fold<int>(
      0,
      (sum, entry) => sum + entry.amountCentavos,
    );
    final days = showingIncome
        ? dailyIncome(
            bounds: bounds,
            entries: store.cycleIncomes,
            today: store.today,
          )
        : dailySpend(
            bounds: bounds,
            entries: store.cycleSpending,
            today: store.today,
          );
    final caption = showingIncome
        ? l10n.dailyIncomeCycleTotal(
            formatMoney(store.currency, cycleIncome, showCode: false),
          )
        : store.hasBudget
        ? l10n.dailySpendLimit(
            formatMoney(store.currency, perDay, showCode: false),
          )
        // No limit to name, so the caption reports what did happen instead.
        : l10n.dailySpendCycleTotal(
            formatMoney(
              store.currency,
              store.totalSpentCentavos,
              showCode: false,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showingIncome ? l10n.dailyIncomeTitle : l10n.dailySpendTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        PixelCard(
          elevation: PixelElevation.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DailySpendChart(
                days: days,
                dailyLimitCentavos: showingIncome ? 0 : perDay,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    shortCycleDate(l10n, bounds.start),
                    style: pixelText(size: 12, color: AppColors.muted),
                  ),
                  // The middle takes what the two dates leave and wraps
                  // inside it, so a long limit on a narrow phone breaks
                  // onto a second line instead of pushing a date off.
                  Expanded(
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: pixelText(size: 12, color: AppColors.muted),
                    ),
                  ),
                  Text(
                    shortCycleDate(l10n, bounds.end),
                    style: pixelText(size: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
