import 'cash_reconciliation.dart';
import 'expense_entry.dart';
import 'income_entry.dart';

enum MovementType { expense, income, adjustment }

class MoneyMovement {
  const MoneyMovement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amountCentavos,
    required this.occurredAt,
    required this.type,
    this.expense,
    this.income,
    this.reconciliation,
    this.isPending = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amountCentavos;
  final DateTime occurredAt;
  final MovementType type;
  final ExpenseEntry? expense;
  final IncomeEntry? income;
  final CashReconciliationEntry? reconciliation;
  final bool isPending;
}
