import 'currency.dart';

/// The contents shown before replacing the current ledger with a JSON backup.
class BackupSummary {
  const BackupSummary({
    required this.expenses,
    required this.incomes,
    required this.fixedExpenses,
    required this.currency,
    required this.budgetCentavos,
  });

  final int expenses;
  final int incomes;
  final int fixedExpenses;
  final Currency currency;
  final int? budgetCentavos;
}
