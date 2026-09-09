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
  });

  final String id;
  final int amountCentavos;
  final ExpenseCategory category;
  final String note;
  final DateTime occurredAt;
  final PaymentMethod paymentMethod;
  final String? cashReconciliationId;
  final bool isPendingCashAdjustment;

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
    );
  }
}
