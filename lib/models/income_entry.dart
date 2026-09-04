import 'expense_entry.dart';

enum IncomeKind { salary, extra, cash, refund }

extension IncomeKindLabel on IncomeKind {
  String get label => switch (this) {
    IncomeKind.salary => 'Mi pago de siempre',
    IncomeKind.extra => 'Ingreso extra',
    IncomeKind.cash => 'Ingreso en efectivo',
    IncomeKind.refund => 'Devolución',
  };
}

enum IncomeAllocation { cycle, savings }

class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.amountCentavos,
    required this.kind,
    required this.note,
    required this.occurredAt,
    required this.destination,
    required this.allocation,
    this.cashReconciliationId,
  });

  final String id;
  final int amountCentavos;
  final IncomeKind kind;
  final String note;
  final DateTime occurredAt;
  final PaymentMethod destination;
  final IncomeAllocation allocation;
  final String? cashReconciliationId;

  Map<String, Object?> toJson() => {
    'id': id,
    'amountCentavos': amountCentavos,
    'kind': kind.name,
    'note': note,
    'occurredAt': occurredAt.toIso8601String(),
    'destination': destination.name,
    'allocation': allocation.name,
    'cashReconciliationId': cashReconciliationId,
  };

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => IncomeEntry(
    id: json['id'] as String,
    amountCentavos: (json['amountCentavos'] as num).toInt(),
    kind: IncomeKind.values.byName(json['kind'] as String),
    note: json['note'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    destination: PaymentMethod.values.byName(json['destination'] as String),
    allocation: IncomeAllocation.values.byName(json['allocation'] as String),
    cashReconciliationId: json['cashReconciliationId'] as String?,
  );
}
