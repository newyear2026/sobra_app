import '../models/cash_reconciliation.dart';
import '../models/daily_mission.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/money_movement.dart';
import '../models/language.dart';
import '../models/pay_schedule.dart';
import '../models/store_failure.dart';
import '../services/purchase_service.dart';
import '../models/xp_event.dart';
import '../widgets/cat_sprite.dart';
import 'generated/app_localizations.dart';

/// How Sobra's enums and movements read on screen.
///
/// The models and the store carry what happened — an enum, an amount, a date.
/// Turning that into a sentence happens here, at the edge of the view, because
/// the same event has to read differently in every locale. The only text that
/// escapes this rule is what the user typed themselves: a note is data, not a
/// string to translate.
///
/// These take an [AppLocalizations] rather than a `BuildContext` so the home
/// screen widget sync, which has no element tree of its own, can hold onto one
/// and label its payload with the same words the app uses.

extension ExpenseCategoryL10n on ExpenseCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ExpenseCategory.food => l10n.categoryFood,
    ExpenseCategory.transport => l10n.categoryTransport,
    ExpenseCategory.shopping => l10n.categoryShopping,
    ExpenseCategory.home => l10n.categoryHome,
    ExpenseCategory.services => l10n.categoryServices,
    ExpenseCategory.health => l10n.categoryHealth,
    ExpenseCategory.education => l10n.categoryEducation,
    ExpenseCategory.entertainment => l10n.categoryEntertainment,
    ExpenseCategory.pets => l10n.categoryPets,
    ExpenseCategory.other => l10n.categoryOther,
  };
}

extension PaymentMethodL10n on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.paymentMethodCash,
    PaymentMethod.card => l10n.paymentMethodCard,
  };
}

extension IncomeKindL10n on IncomeKind {
  String label(AppLocalizations l10n) => switch (this) {
    IncomeKind.salary => l10n.incomeKindSalary,
    IncomeKind.extra => l10n.incomeKindExtra,
    IncomeKind.cash => l10n.incomeKindCash,
    IncomeKind.refund => l10n.incomeKindRefund,
  };
}

extension IncomeAllocationL10n on IncomeAllocation {
  String label(AppLocalizations l10n) => switch (this) {
    IncomeAllocation.cycle => l10n.incomeAllocationCycle,
    IncomeAllocation.savings => l10n.incomeAllocationSavings,
  };
}

extension PayCycleTypeL10n on PayCycleType {
  String label(AppLocalizations l10n) => switch (this) {
    PayCycleType.semiMonthly => l10n.payCycleSemiMonthly,
    PayCycleType.biweekly => l10n.payCycleBiweekly,
    PayCycleType.monthly => l10n.payCycleMonthly,
    PayCycleType.weekly => l10n.payCycleWeekly,
    PayCycleType.irregular => l10n.payCycleIrregular,
  };
}

extension CashResolutionL10n on CashResolution {
  String label(AppLocalizations l10n) => switch (this) {
    CashResolution.expense => l10n.cashResolutionExpense,
    CashResolution.income => l10n.cashResolutionIncome,
    CashResolution.transfer => l10n.cashResolutionTransfer,
    CashResolution.correction => l10n.cashResolutionCorrection,
    CashResolution.pending => l10n.cashResolutionPending,
  };
}

/// The headline for one expense.
///
/// A row saved before this app localized its text still carries the old
/// Spanish default in its note, so a non-empty note always wins. Newer rows
/// leave the note empty when the user did not write one, and fall back to the
/// category — which is the same sentence, only in the reader's language.
String expenseTitle(AppLocalizations l10n, ExpenseEntry entry) {
  if (entry.isPendingCashAdjustment) return l10n.cashResolutionPending;
  final note = entry.note.trim();
  return note.isEmpty ? entry.category.label(l10n) : note;
}

String incomeTitle(AppLocalizations l10n, IncomeEntry entry) {
  final note = entry.note.trim();
  return note.isEmpty ? entry.kind.label(l10n) : note;
}

String movementTitle(AppLocalizations l10n, MoneyMovement movement) {
  final expense = movement.expense;
  if (expense != null) return expenseTitle(l10n, expense);
  final income = movement.income;
  if (income != null) return incomeTitle(l10n, income);
  final reconciliation = movement.reconciliation;
  if (reconciliation != null) return reconciliation.resolution.label(l10n);
  return '';
}

/// The second line of a movement row: what kind of money moved, and where.
String movementSubtitle(AppLocalizations l10n, MoneyMovement movement) {
  final expense = movement.expense;
  if (expense != null) {
    if (expense.isPendingCashAdjustment) {
      return l10n.movementSubtitle(
        l10n.movementPending,
        expense.paymentMethod.label(l10n),
      );
    }
    // Without a note the headline is already the category, and repeating it
    // here gives a row that reads "Comida / Comida · Efectivo". The line
    // drops to what the headline is not saying.
    return expense.note.trim().isEmpty
        ? expense.paymentMethod.label(l10n)
        : l10n.movementSubtitle(
            expense.category.label(l10n),
            expense.paymentMethod.label(l10n),
          );
  }
  final income = movement.income;
  if (income != null) {
    return income.note.trim().isEmpty
        ? income.allocation.label(l10n)
        : l10n.movementSubtitle(
            income.kind.label(l10n),
            income.allocation.label(l10n),
          );
  }
  return l10n.movementCashCount;
}

extension XpEventKindL10n on XpEventKind {
  /// What the XP row says it was for.
  ///
  /// The counts live in the event, so a locale decides its own plural rather
  /// than the store picking between "día" and "días" on Spanish's behalf.
  String title(
    AppLocalizations l10n, {
    int? quantity,
    PayCycleType? cycleType,
  }) => switch (this) {
    XpEventKind.cashCount => l10n.xpCashCountTitle,
    XpEventKind.cycleInGreen => switch (cycleType) {
      PayCycleType.semiMonthly => l10n.xpCycleInGreenSemiMonthly,
      PayCycleType.biweekly => l10n.xpCycleInGreenBiweekly,
      PayCycleType.monthly => l10n.xpCycleInGreenMonthly,
      PayCycleType.weekly => l10n.xpCycleInGreenWeekly,
      PayCycleType.irregular || null => l10n.xpCycleInGreenGeneric,
    },
    XpEventKind.daysUnderDailyLimit => l10n.xpDaysUnderDailyLimitTitle(
      quantity ?? 0,
    ),
    XpEventKind.firstSuccessfulCycle => l10n.xpFirstSuccessfulCycleTitle,
    XpEventKind.dailyMissionRecord => l10n.dailyMissionRecordTitle,
    XpEventKind.dailyMissionSameDay => l10n.dailyMissionSameDayTitle,
    XpEventKind.dailyMissionBudget => l10n.dailyMissionBudgetTitle,
  };

  String shortDetail(AppLocalizations l10n) => switch (this) {
    XpEventKind.cashCount => l10n.xpCashCountDetail,
    XpEventKind.cycleInGreen => l10n.xpCycleInGreenDetail,
    XpEventKind.daysUnderDailyLimit => l10n.xpDaysUnderDailyLimitDetail,
    XpEventKind.firstSuccessfulCycle => l10n.xpFirstSuccessfulCycleDetail,
    XpEventKind.dailyMissionRecord ||
    XpEventKind.dailyMissionSameDay ||
    XpEventKind.dailyMissionBudget => l10n.dailyMissionXpDetail,
  };
}

extension XpEventL10n on XpEvent {
  String title(AppLocalizations l10n) =>
      kind.title(l10n, quantity: quantity, cycleType: cycleType);
}

extension DailyMissionKindL10n on DailyMissionKind {
  String title(AppLocalizations l10n) => switch (this) {
    DailyMissionKind.recordMovement => l10n.dailyMissionRecordTitle,
    DailyMissionKind.sameDay => l10n.dailyMissionSameDayTitle,
    DailyMissionKind.reviewBudget => l10n.dailyMissionBudgetTitle,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    DailyMissionKind.recordMovement => l10n.dailyMissionRecordHint,
    DailyMissionKind.sameDay => l10n.dailyMissionSameDayHint,
    DailyMissionKind.reviewBudget => l10n.dailyMissionBudgetHint,
  };
}

/// The name of a level, from 1 up to [XpProgress.levelCount].
String xpLevelTitle(AppLocalizations l10n, int level) => switch (level) {
  1 => l10n.xpLevelTitle1,
  2 => l10n.xpLevelTitle2,
  3 => l10n.xpLevelTitle3,
  4 => l10n.xpLevelTitle4,
  5 => l10n.xpLevelTitle5,
  6 => l10n.xpLevelTitle6,
  7 => l10n.xpLevelTitle7,
  8 => l10n.xpLevelTitle8,
  9 => l10n.xpLevelTitle9,
  _ => l10n.xpLevelTitle10,
};

String xpNoticeTitle(AppLocalizations l10n, XpNotice notice) =>
    switch (notice.kind) {
      XpNoticeKind.cyclesClosed => l10n.xpNoticeCyclesClosedTitle(
        notice.closedCycles,
      ),
      XpNoticeKind.cashCountSaved => l10n.xpNoticeCashCountTitle,
      XpNoticeKind.missionCompleted => l10n.xpNoticeMissionTitle(
        notice.missionCount,
      ),
    };

String xpNoticeDetail(AppLocalizations l10n, XpNotice notice) =>
    switch (notice.kind) {
      XpNoticeKind.cyclesClosed => l10n.xpNoticeCyclesClosedDetail,
      XpNoticeKind.cashCountSaved => l10n.xpNoticeCashCountDetail,
      XpNoticeKind.missionCompleted => l10n.xpNoticeMissionDetail,
    };

/// The sentence to show when a store write did not go through.
///
/// A typed [SobraStoreException] is a refusal the store means the user to
/// read. Anything else is a failure they can do nothing about except try
/// again — and its message is Dart's, not ours, so it gets one plain line
/// rather than being repeated at them.
String describeStoreFailure(AppLocalizations l10n, Object error) =>
    switch (error) {
      SobraStoreException(:final failure) => switch (failure) {
        StoreFailure.budgetBelowCycleIncome =>
          l10n.storeFailureBudgetBelowCycleIncome,
        StoreFailure.futureMovement => l10n.storeFailureFutureMovement,
        StoreFailure.restoreFailed => l10n.storeFailureRestoreFailed,
        StoreFailure.originalNotKept => l10n.storeFailureOriginalNotKept,
        StoreFailure.backupNotSaved => l10n.storeFailureBackupNotSaved,
        StoreFailure.saveFailed => l10n.storeFailureSaveFailed,
      },
      _ => l10n.storeFailureGeneric,
    };

/// The sentence to show when a purchase did not go through.
///
/// There is no case for a cancellation. [PurchaseFailure] has none, because a
/// user who backed out of the store sheet got the outcome they asked for and
/// telling them about it would read as a complaint.
String describePurchaseFailure(
  AppLocalizations l10n,
  PurchaseFailure failure,
) => switch (failure) {
  PurchaseFailure.storeUnavailable => l10n.purchaseFailureStoreUnavailable,
  PurchaseFailure.purchaseRejected => l10n.purchaseFailureRejected,
  PurchaseFailure.nothingToRestore => l10n.purchaseFailureNothingToRestore,
};

/// The three-letter month, kept short enough for the pixel layouts.
String monthAbbreviation(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.monthAbbr1,
  2 => l10n.monthAbbr2,
  3 => l10n.monthAbbr3,
  4 => l10n.monthAbbr4,
  5 => l10n.monthAbbr5,
  6 => l10n.monthAbbr6,
  7 => l10n.monthAbbr7,
  8 => l10n.monthAbbr8,
  9 => l10n.monthAbbr9,
  10 => l10n.monthAbbr10,
  11 => l10n.monthAbbr11,
  _ => l10n.monthAbbr12,
};

/// A date the way Sobra writes one: day, then the month by name.
///
/// Spelling the month out is what lets the order stay put in every locale —
/// "15 sep" cannot be misread the way "09/15" and "15/09" can.
String shortCycleDate(AppLocalizations l10n, DateTime date) =>
    '${date.day} ${monthAbbreviation(l10n, date.month)}';

String cycleDateRange(AppLocalizations l10n, DateTime start, DateTime end) =>
    '${shortCycleDate(l10n, start)}–${shortCycleDate(l10n, end)}';

String fullDate(AppLocalizations l10n, DateTime date) =>
    '${date.day} ${monthAbbreviation(l10n, date.month)} ${date.year}';

extension CatMotionL10n on CatMotion {
  /// What a screen reader says the cat is doing.
  String semanticLabel(AppLocalizations l10n) => switch (this) {
    CatMotion.idle => l10n.catMotionIdle,
    CatMotion.walk => l10n.catMotionWalk,
    CatMotion.calculate => l10n.catMotionCalculate,
    CatMotion.saving => l10n.catMotionSaving,
    CatMotion.celebrate => l10n.catMotionCelebrate,
    CatMotion.concern => l10n.catMotionConcern,
  };
}

extension CharacterMotionRoleL10n on CharacterMotionRole {
  String genericSemanticLabel(AppLocalizations l10n) => switch (this) {
    CharacterMotionRole.idle => l10n.characterRoleIdle,
    CharacterMotionRole.activity => l10n.characterRoleActivity,
    CharacterMotionRole.processing => l10n.characterRoleProcessing,
    CharacterMotionRole.positive => l10n.characterRolePositive,
    CharacterMotionRole.success => l10n.characterRoleSuccess,
    CharacterMotionRole.warning => l10n.characterRoleWarning,
  };
}

/// Weekday names, indexed the way [DateTime.monday] and friends number them.
String weekdayName(AppLocalizations l10n, int weekday) => switch (weekday) {
  DateTime.monday => l10n.weekdayMonday,
  DateTime.tuesday => l10n.weekdayTuesday,
  DateTime.wednesday => l10n.weekdayWednesday,
  DateTime.thursday => l10n.weekdayThursday,
  DateTime.friday => l10n.weekdayFriday,
  DateTime.saturday => l10n.weekdaySaturday,
  _ => l10n.weekdaySunday,
};

String weekdayShortName(AppLocalizations l10n, int weekday) =>
    switch (weekday) {
      DateTime.monday => l10n.weekdayShortMonday,
      DateTime.tuesday => l10n.weekdayShortTuesday,
      DateTime.wednesday => l10n.weekdayShortWednesday,
      DateTime.thursday => l10n.weekdayShortThursday,
      DateTime.friday => l10n.weekdayShortFriday,
      DateTime.saturday => l10n.weekdayShortSaturday,
      _ => l10n.weekdayShortSunday,
    };

extension SobraLanguageL10n on SobraLanguage {
  /// Every language names itself, so a reader can find their own however the
  /// rest of the app happens to be written. Only the automatic option is a
  /// sentence in the surrounding language.
  String label(AppLocalizations l10n) => switch (this) {
    SobraLanguage.automatic => l10n.languageAutomatic,
    SobraLanguage.spanish => 'Español',
    SobraLanguage.english => 'English',
    SobraLanguage.korean => '한국어',
  };
}
