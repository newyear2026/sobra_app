enum CashResolution { expense, income, transfer, correction, pending }

class CashReconciliationEntry {
  const CashReconciliationEntry({
    required this.id,
    required this.expectedBeforeCentavos,
    required this.actualCentavos,
    required this.occurredAt,
    required this.resolution,
    this.linkedExpenseId,
    this.linkedIncomeId,
  });

  final String id;
  final int expectedBeforeCentavos;
  final int actualCentavos;
  final DateTime occurredAt;
  final CashResolution resolution;
  final String? linkedExpenseId;
  final String? linkedIncomeId;

  int get differenceCentavos => actualCentavos - expectedBeforeCentavos;
  bool get isExtra => differenceCentavos > 0;

  Map<String, Object?> toJson() => {
    'id': id,
    'expectedBeforeCentavos': expectedBeforeCentavos,
    'actualCentavos': actualCentavos,
    'occurredAt': occurredAt.toIso8601String(),
    'resolution': resolution.name,
    'linkedExpenseId': linkedExpenseId,
    'linkedIncomeId': linkedIncomeId,
  };

  factory CashReconciliationEntry.fromJson(Map<String, dynamic> json) =>
      CashReconciliationEntry(
        id: json['id'] as String,
        expectedBeforeCentavos: (json['expectedBeforeCentavos'] as num).toInt(),
        actualCentavos: (json['actualCentavos'] as num).toInt(),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        resolution: CashResolution.values.byName(json['resolution'] as String),
        linkedExpenseId: json['linkedExpenseId'] as String?,
        linkedIncomeId: json['linkedIncomeId'] as String?,
      );
}
