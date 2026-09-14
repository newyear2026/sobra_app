// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryServices => 'Bills';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryEntertainment => 'Fun';

  @override
  String get categoryPets => 'Pets';

  @override
  String get categoryOther => 'Other';

  @override
  String get incomeKindSalary => 'My usual pay';

  @override
  String get incomeKindExtra => 'Extra income';

  @override
  String get incomeKindCash => 'Cash income';

  @override
  String get incomeKindRefund => 'Refund';

  @override
  String get incomeAllocationCycle => 'This cycle';

  @override
  String get incomeAllocationSavings => 'Savings';

  @override
  String get payCycleSemiMonthly => 'Twice a month';

  @override
  String get payCycleBiweekly => 'Every two weeks';

  @override
  String get payCycleMonthly => 'Monthly';

  @override
  String get payCycleWeekly => 'Weekly';

  @override
  String get payCycleIrregular => 'No fixed date';

  @override
  String get cashResolutionExpense => 'Expense found';

  @override
  String get cashResolutionIncome => 'Cash income';

  @override
  String get cashResolutionTransfer => 'Moved between accounts';

  @override
  String get cashResolutionCorrection => 'Count correction';

  @override
  String get cashResolutionPending => 'Difference to sort out';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get movementPending => 'Pending';

  @override
  String get movementCashCount => 'Cash count';

  @override
  String get xpCashCountTitle => 'Cash count';

  @override
  String get xpCashCountDetail => 'First count with XP this week';

  @override
  String get xpCycleInGreenSemiMonthly =>
      'You closed the half-month in the green';

  @override
  String get xpCycleInGreenMonthly => 'You closed the month in the green';

  @override
  String get xpCycleInGreenWeekly => 'You closed the week in the green';

  @override
  String get xpCycleInGreenGeneric => 'You closed the cycle in the green';

  @override
  String get xpCycleInGreenDetail => 'How the budget ended up';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days under your limit',
      one: '$count day under your limit',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail => 'Worked out once, at closing';

  @override
  String get xpFirstSuccessfulCycleTitle => 'First cycle in the green';

  @override
  String get xpFirstSuccessfulCycleDetail => 'One-time bonus';

  @override
  String get xpLevelTitle1 => 'Curious Michi';

  @override
  String get xpLevelTitle2 => 'Saver Michi';

  @override
  String get xpLevelTitle3 => 'Counter Michi';

  @override
  String get xpLevelTitle4 => 'Guardian Michi';

  @override
  String get xpLevelTitle5 => 'Master Michi';

  @override
  String get xpLevelTitle6 => 'Expert Michi';

  @override
  String get xpLevelTitle7 => 'Strategist Michi';

  @override
  String get xpLevelTitle8 => 'Prosperous Michi';

  @override
  String get xpLevelTitle9 => 'Wise Michi';

  @override
  String get xpLevelTitle10 => 'Legendary Michi';

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cycles closed',
      one: 'Cycle closed',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP added automatically.';

  @override
  String get xpNoticeCashCountTitle => 'Cash count saved';

  @override
  String get xpNoticeCashCountDetail => 'First count with XP this week.';

  @override
  String xpLevelUpTitle(int level) {
    return 'LEVEL $level!';
  }

  @override
  String get xpLevelUpContinue => 'Continue';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new items unlocked!',
      one: 'New item unlocked!',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => 'Today\'s mission';

  @override
  String get dailyMissionResetHint =>
      'They reset at midnight. They don\'t pile up.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get dailyMissionAllDone => 'All done';

  @override
  String get dailyMissionRecordTitle => 'Record a movement today';

  @override
  String get dailyMissionRecordHint => 'One expense or one income';

  @override
  String get dailyMissionSameDayTitle => 'Log it the same day';

  @override
  String get dailyMissionSameDayHint =>
      'The day it happened, and the day you write it';

  @override
  String get dailyMissionBudgetTitle => 'Check your budget';

  @override
  String get dailyMissionBudgetHint => 'Open the Budget tab';

  @override
  String get dailyMissionDone => 'Done';

  @override
  String get dailyMissionPending => 'To do';

  @override
  String dailyMissionReadyAt(String time) {
    return 'Done · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done of $total done · +$earned XP of +$possible XP today';
  }

  @override
  String get dailyMissionXpDetail => 'Completed mission';

  @override
  String get xpRuleDailyMission => 'Once a day; at midnight it starts over';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missions done',
      one: 'Mission done',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => 'XP added for today\'s habit.';

  @override
  String get storeFailureGeneric =>
      'We couldn\'t save that change. Please try again.';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      'The total has to be more than the income already set aside for this cycle.';

  @override
  String get storeFailureFutureMovement =>
      'You can\'t record something dated in the future.';

  @override
  String get storeFailureRestoreFailed => 'We couldn\'t restore the backup.';

  @override
  String get storeFailureOriginalNotKept =>
      'We couldn\'t keep the original file.';

  @override
  String get storeFailureBackupNotSaved => 'We couldn\'t save the backup.';

  @override
  String get storeFailureSaveFailed => 'We couldn\'t save your data.';

  @override
  String get monthAbbr1 => 'Jan';

  @override
  String get monthAbbr2 => 'Feb';

  @override
  String get monthAbbr3 => 'Mar';

  @override
  String get monthAbbr4 => 'Apr';

  @override
  String get monthAbbr5 => 'May';

  @override
  String get monthAbbr6 => 'Jun';

  @override
  String get monthAbbr7 => 'Jul';

  @override
  String get monthAbbr8 => 'Aug';

  @override
  String get monthAbbr9 => 'Sep';

  @override
  String get monthAbbr10 => 'Oct';

  @override
  String get monthAbbr11 => 'Nov';

  @override
  String get monthAbbr12 => 'Dec';

  @override
  String get back => 'Back';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get catMotionIdle => 'The cat is resting quietly';

  @override
  String get catMotionWalk => 'The cat is walking';

  @override
  String get catMotionCalculate => 'The cat is doing the math';

  @override
  String get catMotionSaving => 'The cat is putting coins in the piggy bank';

  @override
  String get catMotionCelebrate => 'The cat is celebrating';

  @override
  String get catMotionConcern => 'The cat looks worried about the budget';

  @override
  String get characterRoleIdle => 'The character is resting quietly';

  @override
  String get characterRoleActivity => 'The character is moving';

  @override
  String get characterRoleProcessing => 'The character is doing the math';

  @override
  String get characterRolePositive => 'The character shows a positive change';

  @override
  String get characterRoleSuccess => 'The character is celebrating';

  @override
  String get characterRoleWarning => 'The character looks worried';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get cancel => 'Cancel';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMovements => 'Activity';

  @override
  String get tabRegister => 'Add';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabSettings => 'My Sobra';

  @override
  String get collectionTitle => 'Collection';

  @override
  String get collectionSettingsValue => 'View';

  @override
  String get collectionCharacters => 'Characters';

  @override
  String get collectionItems => 'Items';

  @override
  String collectionLevel(int level) {
    return 'LEVEL $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned of $total';
  }

  @override
  String get collectionCharactersHint => 'Choose your companion';

  @override
  String get collectionItemsHint => 'Decorate your space';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'Character $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'Item $number';
  }

  @override
  String get collectionEquipped => 'EQUIPPED';

  @override
  String get collectionOwned => 'OWNED';

  @override
  String get collectionEquip => 'EQUIP';

  @override
  String get collectionBuy => 'BUY';

  @override
  String get collectionWatchAd => 'WATCH AD';

  @override
  String collectionAdProgress(int progress, int target) {
    return 'AD $progress/$target';
  }

  @override
  String get collectionHowToGet => 'HOW TO GET IT';

  @override
  String get collectionAlreadyOwned => 'Already part of your collection.';

  @override
  String get collectionIncludedUnlock => 'Included from the start.';

  @override
  String collectionPurchaseUnlock(String price) {
    return 'One-time purchase · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'Watch rewarded ads · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'Unlocks at level $level.';
  }

  @override
  String get collectionStorePricePending => 'store price';

  @override
  String get collectionPreviewActionNotice =>
      'Purchases and ads will be connected in a later stage.';

  @override
  String collectionEquippedNotice(String name) {
    return '$name is now selected.';
  }

  @override
  String get xpHistoryTitle => 'Your progress';

  @override
  String xpTotal(int count) {
    return '$count XP total';
  }

  @override
  String get xpMaxLevel => 'Top level';

  @override
  String xpRemaining(int count) {
    return '$count XP to go';
  }

  @override
  String get xpHistoryHint =>
      'XP is added automatically. Every row keeps the reason and the math, even if you close the app.';

  @override
  String get xpHistoryEmptyTitle => 'No XP yet';

  @override
  String get xpHistoryEmptyMessage =>
      'Your first cash count of the week and the close of your cycle will show up here.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => 'See the math';

  @override
  String get xpCalculationTitle => 'How this was worked out';

  @override
  String get xpDetailCycle => 'Cycle';

  @override
  String get xpDetailBudget => 'Budget';

  @override
  String get xpDetailSpent => 'Spent';

  @override
  String get xpDetailResult => 'Result';

  @override
  String get xpDetailRule => 'Rule';

  @override
  String get xpDetailCredited => 'XP added';

  @override
  String get xpRuleCashCount => 'Once a week at most';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reward scaled to $count days',
      one: 'Reward scaled to $count day',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days × 5 XP',
      one: '$count day × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => 'One-time 50 XP bonus';

  @override
  String get recoveryNotYet => 'We couldn\'t recover your data yet.';

  @override
  String get recoveryStartFreshQuestion => 'Start over?';

  @override
  String get recoveryStartFreshBody =>
      'We\'ll keep a copy of the original file before creating new data.';

  @override
  String get recoveryStartFresh => 'Start over';

  @override
  String get recoveryTitle => 'We couldn\'t read your data';

  @override
  String get recoveryOriginalKept =>
      'The original file is still saved. We haven\'t replaced or deleted it.';

  @override
  String get recoveryOptions =>
      'You can try again, use the backup, or export the file to keep it.';

  @override
  String get recoveryRetrying => 'Trying again…';

  @override
  String get recoveryRetry => 'Try again';

  @override
  String get recoveryUseBackup => 'Use backup';

  @override
  String get recoveryExport => 'Export file';

  @override
  String get recoveryExported => 'Original file copied.';

  @override
  String get settingsTitle => 'My Sobra';

  @override
  String get settingsLanguage => 'Language';

  @override
  String currencyChangeTitle(String code) {
    return 'Switch to $code?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return 'Your amounts aren\'t converted: $example stays $converted. Only the label changes.';
  }

  @override
  String get currencyChangeConfirm => 'Change label';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsBudgetCycle => 'Budget cycle';

  @override
  String get settingsCountDay => 'Count day';

  @override
  String get settingsReduceMotionHint =>
      'Turns on by itself if your phone already asks for it.';

  @override
  String get settingsQuickEntry => 'Quick entry';

  @override
  String get settingsQuickEntryHint =>
      'Shows Income and Expense on the lock screen.';

  @override
  String get quickEntryQuestion => 'What do you want to add?';

  @override
  String get quickEntryDenied =>
      'Allow Sobra notifications to turn on quick entry.';

  @override
  String get settingsBackup => 'Data backup';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsBackupCopied => 'Backup copied to the clipboard.';

  @override
  String get settingsRestorePurchases => 'Restore purchases';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get purchaseRestored => 'Done. Your purchases are back.';

  @override
  String get purchaseFailureStoreUnavailable =>
      'The store is unavailable right now. Try again later.';

  @override
  String get purchaseFailureRejected =>
      'The purchase could not be completed. You were not charged.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      'Your purchase arrived but could not be saved. It will be applied the next time you open Sobra.';

  @override
  String get purchaseFailureNothingToRestore =>
      'We found no purchases on this account.';

  @override
  String get collectionPurchasing => 'BUYING…';

  @override
  String get settingsXpPreview => 'XP preview';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsStorageNote =>
      'Your data is kept on this device. You don\'t need an account to use Sobra.';

  @override
  String get settingsSectionBudget => 'Budget';

  @override
  String get settingsSectionScreen => 'Display';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionDesign => 'Design';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '$movements movements',
      one: '1 movement',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days with Sobra',
      one: '1 day with Sobra',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => 'Automatic';

  @override
  String get languageAutomaticHint => 'Follows your phone';

  @override
  String get transactionsTitle => 'Activity';

  @override
  String get dailySpendTitle => 'Daily spending';

  @override
  String dailySpendLimit(String amount) {
    return '$amount a day';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return 'This cycle $amount';
  }

  @override
  String get dailyIncomeTitle => 'Daily income';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return 'This cycle $amount';
  }

  @override
  String get transactionsEmptyTitle => 'Nothing here yet';

  @override
  String get transactionsEmptyMessage =>
      'Add your first expense and the cycle summary will show up here.';

  @override
  String get transactionsEmptyExpensesTitle => 'No expenses yet';

  @override
  String get transactionsEmptyExpensesMessage =>
      'Add an expense and the day-by-day will show up here.';

  @override
  String get transactionsEmptyIncomesTitle => 'No income yet';

  @override
  String get transactionsEmptyIncomesMessage =>
      'Add an income and the day-by-day will show up here.';

  @override
  String get transactionsExpensePinned =>
      'This expense came from a cash count. Count again to correct it.';

  @override
  String get transactionsIncomePinned =>
      'This income came from a cash count. Count again to correct it.';

  @override
  String get transactionsExpenseDeleted => 'Expense deleted.';

  @override
  String get transactionsIncomeDeleted => 'Income deleted.';

  @override
  String get undo => 'Undo';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get identifyDifference => 'Sort out difference';

  @override
  String get editMovement => 'Edit entry';

  @override
  String get amount => 'Amount';

  @override
  String get editPendingHint =>
      'The amount comes from your cash count. You can still change the category and the note.';

  @override
  String get category => 'Category';

  @override
  String get note => 'Note';

  @override
  String get noteExample => 'e.g. Tacos';

  @override
  String get replacesPendingHint =>
      'This replaces the pending adjustment. It doesn\'t add another expense.';

  @override
  String get saveWithoutDuplicating => 'Save without duplicating';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get save => 'Save';

  @override
  String get budget => 'Budget';

  @override
  String get spent => 'Spent';

  @override
  String get appName => 'Sobra';

  @override
  String get homeCycleBalance => 'Cycle balance';

  @override
  String get homeTodayLeft => 'You have left today';

  @override
  String homeOverBudget(String budget) {
    return 'You went over this cycle\'s $budget budget';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return 'Today\'s limit $limit · $remaining left in the cycle';
  }

  @override
  String get homeFirstQuestLabel => 'First quest';

  @override
  String get homeBudgetQuestBody =>
      'Set a budget and I will work out what you can spend each day.';

  @override
  String get homeCycleProgress => 'Cycle progress';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => 'Estimated cash';

  @override
  String get homeCashUnset => 'Cash not set up';

  @override
  String homeLastCount(String amount) {
    return 'Last count: $amount';
  }

  @override
  String get homeFirstCountHint => 'Do a first count to get started.';

  @override
  String get homeRecentMovements => 'Recent activity';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeGoingWell => 'Going well';

  @override
  String get homeAdjustCalmly => 'Let\'s adjust, calmly';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetCycleTotal => 'Cycle total';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get budgetNotSetTitle => 'No budget yet';

  @override
  String get budgetNotSetBody =>
      'Set one and we will work out what you can spend each day.';

  @override
  String get budgetSetAction => 'Set a budget';

  @override
  String budgetTooLow(String allocated) {
    return 'The total has to be more than the income already set aside for this cycle ($allocated).';
  }

  @override
  String budgetSpentShare(int percent) {
    return '$percent% of the budget';
  }

  @override
  String budgetRingSpent(String amount) {
    return 'Spent $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return '$amount left';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent%';
  }

  @override
  String get cycleHistoryTitle => 'Past cycles';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$green of $total cycles in the green',
      one: '$green of $total cycle in the green',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return 'Budget $budget · Spent $spent';
  }

  @override
  String get cycleHistoryEmpty => 'No cycle has closed yet.';

  @override
  String get budgetChangedTitle => 'You changed your budget';

  @override
  String get budgetChangedBody =>
      'What should we do with the category limits? Scaling them moves each one by the same proportion, so your split stays yours.';

  @override
  String get budgetKeepLimits => 'Keep them';

  @override
  String get budgetScaleLimits => 'Scale them proportionally';

  @override
  String get budgetByCategory => 'Budget by category';

  @override
  String budgetCategoryLimit(String category) {
    return '$category limit';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => 'Projected at close';

  @override
  String get budgetEstimatedLeft => 'What you should have left';

  @override
  String get continueLabel => 'Continue';

  @override
  String get saving => 'Saving…';

  @override
  String dayOfMonth(int day) {
    return 'Day $day';
  }

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayShortMonday => 'Mon';

  @override
  String get weekdayShortTuesday => 'Tue';

  @override
  String get weekdayShortWednesday => 'Wed';

  @override
  String get weekdayShortThursday => 'Thu';

  @override
  String get weekdayShortFriday => 'Fri';

  @override
  String get weekdayShortSaturday => 'Sat';

  @override
  String get weekdayShortSunday => 'Sun';

  @override
  String get registerTitle => 'Add';

  @override
  String get registerExpense => 'Expense';

  @override
  String get registerIncome => 'Income';

  @override
  String get registerAmountAboveZero => 'Enter an amount above zero.';

  @override
  String get registerNoFutureMovements =>
      'You can\'t add anything dated in the future.';

  @override
  String get registerDate => 'Date';

  @override
  String get registerNoteExpenseExample => 'e.g. Taquería El Faro';

  @override
  String get registerNoteIncomeExample => 'e.g. Friday tips';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptAdd => 'Add receipt';

  @override
  String get receiptCamera => 'Camera';

  @override
  String get receiptGallery => 'Gallery';

  @override
  String get receiptChange => 'Replace';

  @override
  String get receiptRemove => 'Remove';

  @override
  String get receiptHint => 'A photo to remember what this expense was.';

  @override
  String get receiptAttached => 'Receipt attached';

  @override
  String get receiptView => 'View receipt';

  @override
  String get receiptClose => 'Close';

  @override
  String get receiptMissing => 'The photo is no longer on this device.';

  @override
  String get receiptFailed => 'The photo could not be saved.';

  @override
  String get receiptBackupNote => 'The backup does not include receipt photos.';

  @override
  String get registerPayment => 'Payment';

  @override
  String get registerPaymentHint => 'Cash comes off your count. Card doesn\'t.';

  @override
  String get registerIncomeKind => 'Kind of income';

  @override
  String get registerWhatToDo => 'What do you want to do?';

  @override
  String get registerThisCycle => 'This cycle';

  @override
  String get registerSaveIt => 'Save it';

  @override
  String get registerReceivedIn => 'You got it in';

  @override
  String get registerAccount => 'Account';

  @override
  String get registerReconcileQuestion =>
      'Does this expense explain the difference?';

  @override
  String registerReconcileBody(String amount) {
    return 'You have $amount pending from your last count. If it\'s the same expense, we\'ll match it without counting it twice.';
  }

  @override
  String get registerReconcileNo => 'No, it\'s new';

  @override
  String get registerReconcileYes => 'Yes, match it';

  @override
  String get registerDifferenceReconciled => 'Difference matched';

  @override
  String get registerExpenseSaved => 'Expense saved';

  @override
  String get registerIncomeSaved => 'Income saved';

  @override
  String get cashCountTitle => 'Cash count';

  @override
  String get cashCountPickWhatHappened =>
      'Pick what happened with the difference.';

  @override
  String get cashCountSavedWithoutDuplicates =>
      'Count saved without duplicating anything.';

  @override
  String get cashCountPrompt => 'Count only the cash you have right now.';

  @override
  String get cashCountNoneYet => 'No count yet';

  @override
  String get cashCountResultPending =>
      'The result shows up once you type the count.';

  @override
  String get cashCountBaselineHint =>
      'This will be your starting point. It won\'t be recorded as income.';

  @override
  String get cashCountExpected => 'We expected';

  @override
  String get cashCountCounted => 'You counted';

  @override
  String get cashCountBalanced => 'It all adds up';

  @override
  String cashCountShort(String amount) {
    return '$amount short';
  }

  @override
  String cashCountExtra(String amount) {
    return '$amount extra';
  }

  @override
  String get cashCountWhatHappened => 'What happened?';

  @override
  String get cashCountHelperExpense =>
      'It was an expense you hadn\'t recorded.';

  @override
  String get cashCountHelperIncome => 'It was new money you received.';

  @override
  String get cashCountHelperTransferOut =>
      'You deposited it or moved it to another account.';

  @override
  String get cashCountHelperTransferIn =>
      'You withdrew it or moved it from another account.';

  @override
  String get cashCountHelperCorrection => 'The earlier count was wrong.';

  @override
  String get cashCountHelperPending => 'Decide later.';

  @override
  String get cashCountSingleExpenseHint =>
      'This creates one expense. You won\'t have to add it again.';

  @override
  String get cashCountNoteTipExample => 'e.g. Tip';

  @override
  String get cashCountWhatToDoWithMoney => 'What should we do with this money?';

  @override
  String get cashCountSaveFirst => 'Save first count';

  @override
  String get cashCountSave => 'Save count';

  @override
  String get cycleTitle => 'Your cycle';

  @override
  String get cycleCurrent => 'Current cycle';

  @override
  String get cycleInProgress => 'In progress';

  @override
  String get cycleUnchanged => 'Won\'t change';

  @override
  String get cycleNewFrequency => 'New frequency';

  @override
  String get cycleFirstPay => 'First payday';

  @override
  String get cyclePayDay => 'Payday';

  @override
  String get cycleNext => 'Next cycle';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return 'The change applies to the next cycle, and after that it renews every $days days.';
  }

  @override
  String get cycleChangeApplies => 'The change applies to the next cycle.';

  @override
  String get cycleSaveChange => 'Save change';

  @override
  String get onboardingBudgetAboveZero => 'Enter a budget above zero.';

  @override
  String get onboardingCashOrSkip => 'Enter your cash or choose “Not now”.';

  @override
  String get prologueRainNoEnd => 'The rain showed no sign of stopping.';

  @override
  String get prologueRentPaid =>
      'The rent was paid, and what sat in the account was what had to last until payday.';

  @override
  String get prologueSoundAtDoor => 'Something stirred by the door.';

  @override
  String get prologueGoLook => 'Go and look';

  @override
  String get prologueWetTracks => 'Two rows of wet prints crossed the floor.';

  @override
  String get prologueShelter => 'Let us wait out the rain.';

  @override
  String get prologueItSpoke => '…it spoke.';

  @override
  String get prologueReplySurprised => 'Did you just talk?';

  @override
  String get prologueReplyTowel => '(you fetch a towel without a word)';

  @override
  String get prologueEarnKeep =>
      'I should earn my keep. I\'ll handle the numbers.';

  @override
  String get prologueAskSchedule => 'First, then — when does money come in?';

  @override
  String get prologueAskPayday =>
      'What day do you get paid? Give me the first one and I\'ll count the rest.';

  @override
  String prologueAskBudget(int days) {
    return '$days days until the next payday. How much do you plan to spend?';
  }

  @override
  String get prologueSkipIsFine =>
      'You can skip it. I\'ll ask again once we\'re home.';

  @override
  String get prologueSkip => 'Skip';

  @override
  String get prologueDriedOff =>
      'Dried off, both settled. Outside it was still raining.';

  @override
  String get prologueWhoSits => 'Who sits with you?';

  @override
  String get prologueMichiTrait => 'Quiet.\nGood with numbers.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'All energy.\nLooks after you.';

  @override
  String get prologueLockedSoon => 'Art on the way';

  @override
  String get prologueOtherStays =>
      'The other one stays too. It is just shy for now.';

  @override
  String get prologueLiveTogether => 'They can stay';

  @override
  String prologueGreeting(String name) {
    return 'I\'m $name. Thanks for opening the door.';
  }

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingTagline => 'Your money, no pressure.';

  @override
  String get onboardingPromise => 'We tell you how much you can spend today.';

  @override
  String get onboardingNoAccount => 'No account. Your data stays with you.';

  @override
  String get onboardingHowPaid => 'How do you get paid?';

  @override
  String get onboardingHowPaidHint => 'This sets the dates of your budget.';

  @override
  String get onboardingCycleHelperSemiMonthly =>
      'Two paydays a month: the 15th and the last day.';

  @override
  String get onboardingCycleHelperMonthly => 'One payday a month.';

  @override
  String get onboardingCycleHelperWeekly => 'Every week.';

  @override
  String get onboardingCycleHelperIrregular => 'My income has no fixed date.';

  @override
  String get onboardingPlanWithoutFixedDate => 'Plan without a fixed date';

  @override
  String get onboardingWhichDayPaid => 'What day do you get paid?';

  @override
  String get onboardingSecondPayEndOfMonth => 'Second payday · end of month';

  @override
  String get onboardingHowManyDays => 'How many days do you want to plan for?';

  @override
  String get onboardingCyclePreview => 'Your cycle would look like this';

  @override
  String onboardingRepeatsEvery(int days) {
    return 'When it ends, another $days-day stretch starts on its own.';
  }

  @override
  String get onboardingShortMonthsNote =>
      'The dates adjust themselves in short months.';

  @override
  String get onboardingBudgetQuestion =>
      'How much do you want\nto spend this cycle?';

  @override
  String get onboardingBudgetLater =>
      'You can set it later from the home screen.';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingCashQuestion => 'How much cash\ndo you have today?';

  @override
  String get onboardingCashOptional =>
      'Leave it empty if you\'d rather count later.';

  @override
  String get onboardingCashIsBaseline =>
      'This will be your first count, not income.';

  @override
  String onboardingSettledIn(String name) {
    return 'The rain stopped. $name settled in beside you.';
  }

  @override
  String get onboardingFirstQuests => 'Your first quests';

  @override
  String get onboardingWaitingAtHome => 'Waiting for you at home';

  @override
  String get onboardingGoHome => 'Go to Home';

  @override
  String get onboardingPlanReady => 'Your plan is ready';

  @override
  String get onboardingCanSpendToday => 'You can spend today';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step of $total';
  }

  @override
  String progressPercent(int percent) {
    return 'Progress $percent percent';
  }

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly => 'You closed the two weeks in the green';

  @override
  String get onboardingCycleHelperBiweekly =>
      'Every two weeks, from my last payday.';

  @override
  String get cycleLastPayday => 'Last payday';

  @override
  String get onboardingWhenLastPaid => 'When was your last payday?';

  @override
  String get onboardingBiweeklyNeedsDate => 'Pick the day of your last payday.';

  @override
  String get pickDate => 'Pick a date';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsReleaseNotes => 'What\'s new';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => 'What\'s new';

  @override
  String get releaseNotesCurrent => 'Current';

  @override
  String releaseNotesRetention(int count) {
    return 'We keep the last $count versions.';
  }

  @override
  String get releaseNote100Launch => 'The first version of Sobra.';
}
