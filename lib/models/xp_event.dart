import 'pay_schedule.dart';

enum XpEventKind {
  cashCount,
  cycleInGreen,
  daysUnderDailyLimit,
  firstSuccessfulCycle,
}

extension XpEventKindLabel on XpEventKind {
  String title({int? quantity, PayCycleType? cycleType}) => switch (this) {
    XpEventKind.cashCount => 'Conteo de efectivo',
    XpEventKind.cycleInGreen => switch (cycleType) {
      PayCycleType.semiMonthly => 'Cerraste la quincena en verde',
      PayCycleType.monthly => 'Cerraste el mes en verde',
      PayCycleType.weekly => 'Cerraste la semana en verde',
      PayCycleType.irregular || null => 'Cerraste el ciclo en verde',
    },
    XpEventKind.daysUnderDailyLimit =>
      '${quantity ?? 0} ${(quantity ?? 0) == 1 ? 'día' : 'días'} bajo tu límite',
    XpEventKind.firstSuccessfulCycle => 'Primer ciclo en verde',
  };

  String get shortDetail => switch (this) {
    XpEventKind.cashCount => 'Primer conteo con XP de la semana',
    XpEventKind.cycleInGreen => 'Resultado del presupuesto al cerrar',
    XpEventKind.daysUnderDailyLimit => 'Calculado una sola vez al cerrar',
    XpEventKind.firstSuccessfulCycle => 'Bono de una sola vez',
  };
}

class XpEvent {
  const XpEvent({
    required this.id,
    required this.kind,
    required this.xp,
    required this.occurredAt,
    required this.sourceKey,
    this.cycleType,
    this.cycleStart,
    this.cycleEnd,
    this.quantity,
    this.budgetCentavos,
    this.spentCentavos,
  });

  final String id;
  final XpEventKind kind;
  final int xp;
  final DateTime occurredAt;

  /// A deterministic business key, independent from the generated row id.
  ///
  /// This is the idempotency boundary: a weekly cash count or a cycle reward
  /// can be evaluated repeatedly, but only one event with this key can exist.
  final String sourceKey;
  final PayCycleType? cycleType;
  final DateTime? cycleStart;
  final DateTime? cycleEnd;
  final int? quantity;
  final int? budgetCentavos;
  final int? spentCentavos;

  bool get hasCalculation => cycleStart != null && cycleEnd != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'xp': xp,
    'occurredAt': occurredAt.toIso8601String(),
    'sourceKey': sourceKey,
    'cycleType': cycleType?.name,
    'cycleStart': cycleStart?.toIso8601String(),
    'cycleEnd': cycleEnd?.toIso8601String(),
    'quantity': quantity,
    'budgetCentavos': budgetCentavos,
    'spentCentavos': spentCentavos,
  };

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
    id: json['id'] as String,
    kind: XpEventKind.values.byName(json['kind'] as String),
    xp: (json['xp'] as num).toInt(),
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    sourceKey: json['sourceKey'] as String,
    cycleType: json['cycleType'] == null
        ? null
        : PayCycleType.values.byName(json['cycleType'] as String),
    cycleStart: json['cycleStart'] == null
        ? null
        : DateTime.parse(json['cycleStart'] as String),
    cycleEnd: json['cycleEnd'] == null
        ? null
        : DateTime.parse(json['cycleEnd'] as String),
    quantity: (json['quantity'] as num?)?.toInt(),
    budgetCentavos: (json['budgetCentavos'] as num?)?.toInt(),
    spentCentavos: (json['spentCentavos'] as num?)?.toInt(),
  );
}

class XpNotice {
  const XpNotice({required this.title, required this.detail, required this.xp});

  final String title;
  final String detail;
  final int xp;
}

class XpProgress {
  const XpProgress({
    required this.level,
    required this.title,
    required this.totalXp,
    required this.levelStartXp,
    required this.nextLevelXp,
  });

  static const _levelStarts = [0, 150, 450, 850, 1550];
  static const _titles = [
    'Michi curioso',
    'Michi ahorrador',
    'Michi contador',
    'Michi guardián',
    'Michi maestro',
  ];

  factory XpProgress.fromTotal(int totalXp) {
    final safeTotal = totalXp < 0 ? 0 : totalXp;
    var index = 0;
    for (var candidate = 1; candidate < _levelStarts.length; candidate++) {
      if (safeTotal < _levelStarts[candidate]) break;
      index = candidate;
    }
    return XpProgress(
      level: index + 1,
      title: _titles[index],
      totalXp: safeTotal,
      levelStartXp: _levelStarts[index],
      nextLevelXp: index == _levelStarts.length - 1
          ? null
          : _levelStarts[index + 1],
    );
  }

  final int level;
  final String title;
  final int totalXp;
  final int levelStartXp;
  final int? nextLevelXp;

  bool get isMaxLevel => nextLevelXp == null;
  int get currentLevelXp => totalXp - levelStartXp;
  int get targetLevelXp => isMaxLevel
      ? (currentLevelXp == 0 ? 1 : currentLevelXp)
      : nextLevelXp! - levelStartXp;
  int get remainingXp => isMaxLevel ? 0 : nextLevelXp! - totalXp;
}
