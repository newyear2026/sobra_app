import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../models/money_movement.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/transaction_row.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  String _groupLabel(AppLocalizations l10n, DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return l10n.today;
    if (day == today.subtract(const Duration(days: 1))) return l10n.yesterday;
    return shortCycleDate(l10n, day);
  }

  /// Deletes what a row stands for, or says why it has to stay.
  ///
  /// Both halves of a cash count are pinned. The count hides its own row in
  /// favour of the expense or income it produced, so removing that one row
  /// would take the whole count off the ledger while the counted cash figure
  /// kept the money — the two would stop telling the same story.
  Future<void> _deleteMovement(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    SobraStore store,
    MoneyMovement movement,
  ) async {
    final expense = movement.expense;
    final income = movement.income;
    if (expense == null && income == null) return;

    var removed = false;
    final wrote = await guardStoreWrite(messenger, l10n, () async {
      removed = expense != null
          ? await store.deleteExpense(expense.id)
          : await store.deleteIncome(income!.id);
    });
    if (!wrote) return;

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
      return;
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
    final canEdit = expense != null;
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
        if (value == 'edit' && expense != null) {
          await _editExpense(context, expense);
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

  Future<void> _editExpense(BuildContext context, ExpenseEntry entry) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 3),
        ),
        builder: (_) => _EditExpenseSheet(entry: entry),
      );

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = store.movements;
    final grouped = <String, List<MoneyMovement>>{};
    for (final entry in entries) {
      final label = _groupLabel(l10n, entry.occurredAt, store.today);
      grouped.putIfAbsent(label, () => []).add(entry);
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('movements-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          PixelTopBar(title: l10n.transactionsTitle),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            PixelEmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.transactionsEmptyTitle,
              message: l10n.transactionsEmptyMessage,
            ),
          for (final group in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 5),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            for (final movement in group.value)
              MovementRow(
                movement: movement,
                onTap: movement.expense == null
                    ? null
                    : () => _editExpense(context, movement.expense!),
                trailing: _rowMenu(context, store, movement),
              ),
          ],
        ],
      ),
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({required this.entry});
  final ExpenseEntry entry;
  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.entry.amountCentavos / 100).toStringAsFixed(0),
    );
    _noteController = TextEditingController(
      text: widget.entry.isPendingCashAdjustment ? '' : widget.entry.note,
    );
    _category = widget.entry.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountController.text);
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
        );
      }
      return store.updateExpense(
        widget.entry.copyWith(
          amountCentavos: amount ?? widget.entry.amountCentavos,
          category: _category,
          note: _noteController.text.trim(),
        ),
      );
    });
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: SobraScope.of(context).currency.code,
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
          ],
        ),
      ),
    );
  }
}
