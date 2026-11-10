import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

typedef LedgerExportRow = ({
  DateTime at,
  String type,
  String category,
  String note,
  String payment,
  int centavos,
});

/// One snapshot for both formats: the same columns, labels and ordering.
/// Plain values also let XLSX encoding run outside the UI isolate.
class LedgerExportData {
  LedgerExportData({
    required AppLocalizations l10n,
    required this.currency,
    required Iterable<ExpenseEntry> expenses,
    required Iterable<IncomeEntry> incomes,
  }) : headers = [
         l10n.csvHeaderDate,
         l10n.csvHeaderTime,
         l10n.csvHeaderType,
         l10n.csvHeaderCategory,
         l10n.csvHeaderNote,
         l10n.csvHeaderPayment,
         l10n.csvHeaderAmount,
         l10n.csvHeaderCurrency,
       ],
       rows = <LedgerExportRow>[
         for (final expense in expenses)
           (
             at: expense.occurredAt,
             type: expense.isFixedPayment
                 ? l10n.csvTypeFixedExpense
                 : expense.isGoalPurchase
                 ? l10n.csvTypeGoalPurchase
                 : l10n.csvTypeExpense,
             category: expense.category.label(l10n),
             note: expense.isPendingCashAdjustment
                 ? l10n.cashResolutionPending
                 : expense.note.trim(),
             payment: expense.paymentMethod.label(l10n),
             centavos: -expense.amountCentavos,
           ),
         for (final income in incomes)
           (
             at: income.occurredAt,
             type: l10n.csvTypeIncome,
             category: income.kind.label(l10n),
             note: income.note.trim(),
             payment: income.destination.label(l10n),
             centavos: income.amountCentavos,
           ),
       ]..sort((a, b) => a.at.compareTo(b.at));

  final Currency currency;
  final List<String> headers;
  final List<LedgerExportRow> rows;
}

/// Same half-up rounding as the ledger for KRW, JPY and other whole-unit money.
int ledgerWholeAmount(int centavos) =>
    centavos.sign *
    ((centavos.abs() + Currency.minorUnitsPerUnit ~/ 2) ~/
        Currency.minorUnitsPerUnit);
