enum ExpenseCategory {
  food,
  transport,
  shopping,
  home,
  services,
  health,
  education,
  entertainment,
  pets,
  other,
}

enum PaymentMethod { cash, card }

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.amountCentavos,
    required this.category,
    required this.note,
    required this.occurredAt,
    required this.paymentMethod,
    this.cashReconciliationId,
    this.isPendingCashAdjustment = false,
    this.receiptFileName,
    this.recurringId,
    this.occurrenceDate,
  });

  final String id;
  final int amountCentavos;
  final ExpenseCategory category;
  final String note;
  final DateTime occurredAt;
  final PaymentMethod paymentMethod;
  final String? cashReconciliationId;
  final bool isPendingCashAdjustment;

  /// File name of the attached receipt photo, or null.
  ///
  /// A name, never a path: the documents directory is handed a new container
  /// path on every iOS build and reinstall, so an absolute path saved today
  /// points nowhere tomorrow. `ReceiptStore` resolves the name at read time.
  /// The photo itself lives outside this JSON — see `ReceiptStore`.
  final String? receiptFileName;

  bool get hasReceipt => receiptFileName != null;

  /// The fixed expense this pays, or null for everyday spending.
  ///
  /// A payment keeps the id after its fixed expense is deleted, and that is
  /// the point: rent paid in March was still rent, and letting it fall back
  /// into March's spending would fail a cycle after the fact.
  final String? recurringId;

  /// The due date this payment settles, which need not be the day it was paid.
  final DateTime? occurrenceDate;

  /// Whether this is a fixed-expense payment rather than everyday spending.
  ///
  /// Fixed payments stay in the ledger and in the wallet, but out of every
  /// figure the budget is measured with — "Hoy te queda", the cycle's
  /// spending, category limits and the cycle's result.
  bool get isFixedPayment => recurringId != null;

  /// Whether this expense exists because a physical cash count came up short.
  ///
  /// Its amount is a measurement of money that already left the wallet, not a
  /// figure the user typed, so it cannot be re-priced or deleted on its own —
  /// doing that leaves the budget and the cash count telling different stories.
  bool get isLinkedToCashCount => cashReconciliationId != null;

  ExpenseEntry copyWith({
    int? amountCentavos,
    ExpenseCategory? category,
    String? note,
    DateTime? occurredAt,
    PaymentMethod? paymentMethod,
    String? cashReconciliationId,
    bool? isPendingCashAdjustment,
    String? receiptFileName,
    bool clearReceipt = false,
  }) {
    return ExpenseEntry(
      id: id,
      amountCentavos: amountCentavos ?? this.amountCentavos,
      category: category ?? this.category,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReconciliationId: cashReconciliationId ?? this.cashReconciliationId,
      isPendingCashAdjustment:
          isPendingCashAdjustment ?? this.isPendingCashAdjustment,
      // Detaching a photo has to be expressible, and `?? this` can only ever
      // set a name — it cannot take one away.
      receiptFileName: clearReceipt
          ? null
          : receiptFileName ?? this.receiptFileName,
      // Not editable: an edit changes what was paid, never what it paid for.
      recurringId: recurringId,
      occurrenceDate: occurrenceDate,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'amountCentavos': amountCentavos,
    'category': category.name,
    'note': note,
    'occurredAt': occurredAt.toIso8601String(),
    'paymentMethod': paymentMethod.name,
    'cashReconciliationId': cashReconciliationId,
    'isPendingCashAdjustment': isPendingCashAdjustment,
    'receiptFileName': receiptFileName,
    'recurringId': recurringId,
    'occurrenceDate': occurrenceDate?.toIso8601String(),
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      amountCentavos: json['amountCentavos'] as int,
      category: ExpenseCategory.values.byName(json['category'] as String),
      note: json['note'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      paymentMethod: PaymentMethod.values.byName(
        json['paymentMethod'] as String,
      ),
      cashReconciliationId: json['cashReconciliationId'] as String?,
      isPendingCashAdjustment:
          json['isPendingCashAdjustment'] as bool? ?? false,
      receiptFileName: json['receiptFileName'] as String?,
      recurringId: json['recurringId'] as String?,
      occurrenceDate: switch (json['occurrenceDate']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
    );
  }
}
