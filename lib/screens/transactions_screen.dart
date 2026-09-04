import 'package:flutter/material.dart';

import '../models/expense_entry.dart';
import '../models/money_movement.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/transaction_row.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  String _groupLabel(DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Hoy';
    if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
    return shortCycleDate(day);
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
    final entries = store.movements;
    final grouped = <String, List<MoneyMovement>>{};
    for (final entry in entries) {
      final label = _groupLabel(entry.occurredAt, store.today);
      grouped.putIfAbsent(label, () => []).add(entry);
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('movements-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          const PixelTopBar(title: 'Movimientos'),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            const PixelEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aún no hay movimientos',
              message:
                  'Registra tu primer gasto y aquí verás el resumen del ciclo.',
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
                trailing: movement.expense == null && movement.income == null
                    ? null
                    : PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 22,
                        ),
                        iconSize: 17,
                        onSelected: (value) async {
                          if (value == 'edit' && movement.expense != null) {
                            await _editExpense(context, movement.expense!);
                            return;
                          }
                          if (value != 'delete') return;
                          if (movement.expense != null) {
                            final entry = movement.expense!;
                            await store.deleteExpense(entry.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Movimiento eliminado.'),
                                action: SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: () => store.restoreExpense(entry),
                                ),
                              ),
                            );
                          } else if (movement.income != null) {
                            final entry = movement.income!;
                            await store.deleteIncome(entry.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Ingreso eliminado.'),
                                action: SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: () => store.restoreIncome(entry),
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          if (movement.expense != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
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
    final amount = parsePesos(_amountController.text);
    if (amount == null) return;
    if (widget.entry.isPendingCashAdjustment) {
      await SobraScope.of(context).classifyPendingCashExpense(
        expenseId: widget.entry.id,
        category: _category,
        note: _noteController.text,
      );
    } else {
      await SobraScope.of(context).updateExpense(
        widget.entry.copyWith(
          amountCentavos: amount,
          category: _category,
          note: _noteController.text.trim().isEmpty
              ? _category.label
              : _noteController.text.trim(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
                ? 'Identificar diferencia'
                : 'Editar movimiento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _amountController,
            enabled: !widget.entry.isPendingCashAdjustment,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              suffixText: 'MXN',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: ExpenseCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
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
            decoration: const InputDecoration(
              labelText: 'Nota',
              hintText: 'Ej. Tacos',
            ),
          ),
          if (widget.entry.isPendingCashAdjustment) ...[
            const SizedBox(height: 12),
            const PixelCard(
              elevation: PixelElevation.none,
              color: AppColors.tealSoft,
              child: Text(
                'Esto reemplaza el ajuste pendiente. No suma otro gasto.',
                style: TextStyle(
                  color: AppColors.teal,
                  fontVariations: AppType.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PixelButton(
            label: widget.entry.isPendingCashAdjustment
                ? 'Guardar sin duplicar'
                : 'Guardar cambios',
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}
