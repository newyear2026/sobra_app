/// Two entry paths share the same saved amount and progress calculation.
enum SavingsGoalKind { amount, product }

/// A single, optional reason to save. Amounts label money already recorded;
/// creating or editing a goal never moves the budget or the wallet.
class SavingsGoal {
  SavingsGoal({
    required this.id,
    required String name,
    required this.targetCentavos,
    required this.startingCentavos,
    required this.createdAt,
    required Set<String> excludedIncomeIds,
    SavingsGoalKind? kind,
    this.targetDate,
    String? productUrl,
    String? imageUrl,
    String? merchantName,
  }) : kind =
           kind ??
           inferKind(
             productUrl: productUrl,
             imageUrl: imageUrl,
             merchantName: merchantName,
           ),
       name = name.trim(),
       productUrl = _optionalText(productUrl),
       imageUrl = _optionalText(imageUrl),
       merchantName = _optionalText(merchantName),
       excludedIncomeIds = Set.unmodifiable(excludedIncomeIds) {
    if (id.isEmpty || id.length > 256) {
      throw ArgumentError.value(id, 'id');
    }
    if (this.name.isEmpty || this.name.runes.length > 60) {
      throw ArgumentError.value(name, 'name');
    }
    if (targetCentavos <= 0 || targetCentavos > maxAmountCentavos) {
      throw ArgumentError.value(targetCentavos, 'targetCentavos');
    }
    if (startingCentavos < 0 || startingCentavos > maxAmountCentavos) {
      throw ArgumentError.value(startingCentavos, 'startingCentavos');
    }
    if (createdAt.year < 1900 || createdAt.year > 9999) {
      throw ArgumentError.value(createdAt, 'createdAt');
    }
    final date = targetDate;
    if (date != null &&
        (date.year > 9999 ||
            date.isBefore(
              DateTime(createdAt.year, createdAt.month, createdAt.day),
            ))) {
      throw ArgumentError.value(date, 'targetDate');
    }
    if (this.excludedIncomeIds.length > maxExcludedIncomeIds ||
        this.excludedIncomeIds.any((id) => id.isEmpty || id.length > 256)) {
      throw ArgumentError.value(excludedIncomeIds, 'excludedIncomeIds');
    }
    for (final url in [this.productUrl, this.imageUrl]) {
      if (url != null && !isSupportedUrl(url)) {
        throw ArgumentError.value(url, 'url');
      }
    }
    if ((this.merchantName?.runes.length ?? 0) > 80) {
      throw ArgumentError.value(merchantName, 'merchantName');
    }
    if (this.kind == SavingsGoalKind.amount &&
        (this.productUrl != null ||
            this.imageUrl != null ||
            this.merchantName != null)) {
      throw ArgumentError('An amount goal cannot contain product information');
    }
  }

  /// The same twelve whole digits accepted by the app's amount fields.
  static const maxAmountCentavos = 99999999999999;
  static const maxExcludedIncomeIds = 100000;

  final String id;
  final SavingsGoalKind kind;
  final String name;
  final int targetCentavos;
  final int startingCentavos;
  final DateTime createdAt;
  final DateTime? targetDate;
  final String? productUrl;
  final String? imageUrl;
  final String? merchantName;

  /// Income present when the goal was created is already represented, if
  /// desired, in [startingCentavos]. Keeping IDs also prevents same-day income
  /// from being counted twice when the goal is created later that afternoon.
  final Set<String> excludedIncomeIds;

  /// Goals saved before the type selector existed had no kind field. Their
  /// optional product references are the only reliable way to infer one.
  static SavingsGoalKind inferKind({
    String? productUrl,
    String? imageUrl,
    String? merchantName,
  }) =>
      [
        productUrl,
        imageUrl,
        merchantName,
      ].any((value) => _optionalText(value) != null)
      ? SavingsGoalKind.product
      : SavingsGoalKind.amount;

  /// Only ordinary HTTPS website links are kept in a portable goal. This is
  /// a URL-shape check, not a promise about a website's content or DNS.
  static bool isSupportedUrl(String value) {
    if (value.isEmpty || value.length > 4096 || value != value.trim()) {
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        (uri.hasPort && uri.port != 443)) {
      return false;
    }
    final host = uri.host.toLowerCase();
    final labels = host.split('.');
    if (host.length > 253 ||
        labels.length < 2 ||
        !RegExp(r'[a-z]').hasMatch(labels.last) ||
        labels.any(
          (part) =>
              !RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$').hasMatch(part),
        )) {
      return false;
    }
    return !const [
      'localhost',
      'local',
      'localdomain',
      'internal',
      'lan',
      'home',
      'test',
      'invalid',
    ].contains(labels.last);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'targetCentavos': targetCentavos,
    'startingCentavos': startingCentavos,
    'createdAt': createdAt.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'productUrl': productUrl,
    'imageUrl': imageUrl,
    'merchantName': merchantName,
    'excludedIncomeIds': excludedIncomeIds.toList()..sort(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final excluded = json['excludedIncomeIds'];
    if (excluded is! List ||
        excluded.length > maxExcludedIncomeIds ||
        excluded.any((id) => id is! String) ||
        excluded.toSet().length != excluded.length) {
      throw const FormatException('Invalid savings goal baseline');
    }
    final targetDate = json['targetDate'];
    return SavingsGoal(
      id: json['id'] as String,
      kind: _readKind(json),
      name: json['name'] as String,
      targetCentavos: json['targetCentavos'] as int,
      startingCentavos: json['startingCentavos'] as int,
      createdAt: _readDate(json['createdAt']),
      targetDate: targetDate == null ? null : _readDate(targetDate),
      productUrl: json['productUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      merchantName: json['merchantName'] as String?,
      excludedIncomeIds: excluded.cast<String>().toSet(),
    );
  }

  static SavingsGoalKind? _readKind(Map<String, dynamic> json) {
    if (!json.containsKey('kind')) return null;
    return switch (json['kind']) {
      'amount' => SavingsGoalKind.amount,
      'product' => SavingsGoalKind.product,
      _ => throw const FormatException('Invalid savings goal kind'),
    };
  }

  static String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _readDate(Object? raw) {
    if (raw is! String) throw const FormatException('Invalid goal date');
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|T)').firstMatch(raw);
    final parsed = DateTime.tryParse(raw);
    if (match == null || parsed == null) {
      throw const FormatException('Invalid goal date');
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final check = DateTime.utc(year, month, day);
    if (year < 1900 ||
        check.year != year ||
        check.month != month ||
        check.day != day) {
      throw const FormatException('Invalid goal date');
    }
    return parsed;
  }
}

/// One explicit earmark of a closed cycle's leftover, never a new income.
/// Entries survive removal or archiving of a goal so money cannot be reused.
class SavingsGoalCycleAllocation {
  SavingsGoalCycleAllocation({
    required this.cycleStart,
    required this.goalId,
    required this.amountCentavos,
    required this.createdAt,
  }) {
    if (goalId.isEmpty ||
        goalId.length > 256 ||
        amountCentavos <= 0 ||
        amountCentavos > SavingsGoal.maxAmountCentavos ||
        cycleStart !=
            DateTime(cycleStart.year, cycleStart.month, cycleStart.day) ||
        cycleStart.year < 1900 ||
        cycleStart.year > 9999 ||
        createdAt.isBefore(cycleStart) ||
        createdAt.year > 9999) {
      throw ArgumentError('Invalid goal cycle allocation');
    }
  }

  final DateTime cycleStart;
  final String goalId;
  final int amountCentavos;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'cycleStart': cycleStart.toIso8601String(),
    'goalId': goalId,
    'amountCentavos': amountCentavos,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoalCycleAllocation.fromJson(Map<String, dynamic> json) =>
      SavingsGoalCycleAllocation(
        cycleStart: SavingsGoal._readDate(json['cycleStart']),
        goalId: json['goalId'] as String,
        amountCentavos: json['amountCentavos'] as int,
        createdAt: SavingsGoal._readDate(json['createdAt']),
      );
}

/// A finished goal's immutable snapshot, kept in the goal history.
///
/// A goal finishes either by reaching its target (the user then starts a new
/// one) or by buying the thing with the money saved so far, which can be
/// before the target: a Buen Fin price is often under the list price.
class CompletedSavingsGoal {
  CompletedSavingsGoal({
    required this.goal,
    required this.progressCentavos,
    required this.completedAt,
    this.purchaseCentavos,
    this.purchaseExpenseId,
  }) {
    final purchase = purchaseCentavos;
    final bought = purchase != null || purchaseExpenseId != null;
    if ((bought && (purchase == null || purchaseExpenseId == null)) ||
        (purchase != null && (purchase <= 0 || purchase > progressCentavos)) ||
        (purchaseExpenseId != null &&
            (purchaseExpenseId!.isEmpty || purchaseExpenseId!.length > 256)) ||
        (!bought && progressCentavos < goal.targetCentavos) ||
        progressCentavos < 0 ||
        progressCentavos > 9007199254740991 ||
        completedAt.isBefore(goal.createdAt) ||
        completedAt.year > 9999) {
      throw ArgumentError('Invalid completed savings goal');
    }
  }

  final SavingsGoal goal;
  final int progressCentavos;
  final DateTime completedAt;

  /// What the purchase cost, when the goal ended in buying the thing.
  final int? purchaseCentavos;

  /// The ledger expense recorded for that purchase.
  final String? purchaseExpenseId;

  bool get wasPurchased => purchaseCentavos != null;

  Map<String, Object?> toJson() => {
    'goal': goal.toJson(),
    'progressCentavos': progressCentavos,
    'completedAt': completedAt.toIso8601String(),
    if (purchaseCentavos != null) 'purchaseCentavos': purchaseCentavos,
    if (purchaseExpenseId != null) 'purchaseExpenseId': purchaseExpenseId,
  };

  factory CompletedSavingsGoal.fromJson(Map<String, dynamic> json) =>
      CompletedSavingsGoal(
        goal: SavingsGoal.fromJson(json['goal'] as Map<String, dynamic>),
        progressCentavos: json['progressCentavos'] as int,
        completedAt: SavingsGoal._readDate(json['completedAt']),
        purchaseCentavos: json['purchaseCentavos'] as int?,
        purchaseExpenseId: json['purchaseExpenseId'] as String?,
      );
}
