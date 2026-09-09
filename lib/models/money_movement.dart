import 'cash_reconciliation.dart';
import 'expense_entry.dart';
import 'income_entry.dart';

enum MovementType { expense, income, adjustment }

/// One line in a money list, whatever kind of money it was.
///
/// This carries the event, not its wording: the entry it came from, the amount
/// and the day. What the row says is built in the view, from these fields, so
/// the same movement can read in any language. See `l10n/labels.dart`.
class MoneyMovement {
  const MoneyMovement({
    required this.id,
    required this.amountCentavos,
    required this.occurredAt,
    required this.type,
    this.expense,
    this.income,
    this.reconciliation,
    this.isPending = false,
  });

  final String id;
  final int amountCentavos;
  final DateTime occurredAt;
  final MovementType type;
  final ExpenseEntry? expense;
  final IncomeEntry? income;
  final CashReconciliationEntry? reconciliation;
  final bool isPending;
}
