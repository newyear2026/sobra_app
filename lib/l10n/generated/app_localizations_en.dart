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
  String xpLevelTitle1(String name) {
    return 'Curious $name';
  }

  @override
  String xpLevelTitle2(String name) {
    return 'Saver $name';
  }

  @override
  String xpLevelTitle3(String name) {
    return 'Counter $name';
  }

  @override
  String xpLevelTitle4(String name) {
    return 'Guardian $name';
  }

  @override
  String xpLevelTitle5(String name) {
    return 'Master $name';
  }

  @override
  String xpLevelTitle6(String name) {
    return 'Expert $name';
  }

  @override
  String xpLevelTitle7(String name) {
    return 'Strategist $name';
  }

  @override
  String xpLevelTitle8(String name) {
    return 'Prosperous $name';
  }

  @override
  String xpLevelTitle9(String name) {
    return 'Wise $name';
  }

  @override
  String xpLevelTitle10(String name) {
    return 'Legendary $name';
  }

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
      'They change at midnight. They don\'t pile up.';

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
  String get dailyMissionNoteTitle => 'Add a note';

  @override
  String get dailyMissionNoteHint => 'One movement with a note';

  @override
  String get dailyMissionReceiptTitle => 'Keep a receipt';

  @override
  String get dailyMissionReceiptHint => 'Attach the photo to an expense';

  @override
  String get dailyMissionThreeTodayTitle => 'Record three today';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '$count movements dated today';
  }

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
  String get tabSettings => 'My Sobrita';

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
  String get collectionCharactersHint => 'Collect your companions';

  @override
  String get collectionItemsHint => 'Collect what goes in your space';

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
  String get collectionPlaceIt => 'Place it';

  @override
  String get collectionBuy => 'BUY';

  @override
  String get collectionWatchAd => 'WATCH AD';

  @override
  String get collectionAdLoading => 'LOADING';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'Watch rewarded ads · $progress/$target · one a day';
  }

  @override
  String get collectionAdUnavailable => 'NO ADS NOW';

  @override
  String get collectionAdDailyCap => 'TODAY\'S LIMIT';

  @override
  String get collectionAdTomorrow => 'CONTINUES TOMORROW';

  @override
  String collectionUnlockedNotice(String name) {
    return '$name is yours!';
  }

  @override
  String get collectionAdDismissedNotice =>
      'Watch the whole ad for it to count.';

  @override
  String get collectionPackOnly => 'PACK';

  @override
  String get collectionPackDecoration => 'Michi\'s star';

  @override
  String get collectionPackUnlock =>
      'Arrives with Michi & Friends. It is not sold separately.';

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
  String get roomTitle => 'My room';

  @override
  String get roomOpen => 'Open my room';

  @override
  String get roomDecorate => 'Decorate';

  @override
  String get roomDecorateTitle => 'Decorate';

  @override
  String get roomDone => 'Done';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => 'Garden house';

  @override
  String get roomThemeCasaDePlaya => 'Beach house';

  @override
  String get roomChooseTheme => 'Choose your room theme.';

  @override
  String get roomCatReaction => 'You did great today!';

  @override
  String get roomInstruction => 'Choose an item, then tap where you want it.';

  @override
  String get roomCategoryRooms => 'Room';

  @override
  String get roomCategoryFurniture => 'Furniture';

  @override
  String get roomCategoryWallFloor => 'Wall & floor';

  @override
  String get roomCategoryProps => 'Decor';

  @override
  String get roomCategoryCharacters => 'Characters';

  @override
  String get roomCharacterInstruction => 'Choose who keeps you company.';

  @override
  String get roomMoreInCollection => 'See more in the collection';

  @override
  String get roomDefaultRug => 'Lavender rug';

  @override
  String get roomFloorLamp => 'Green lamp';

  @override
  String get roomTablePlant => 'Table plant';

  @override
  String get roomWallFrame => 'Wall picture';

  @override
  String get roomRattanChair => 'Rattan chair';

  @override
  String get roomStandingLamp => 'Floor lamp';

  @override
  String get roomWallClock => 'Wall clock';

  @override
  String get roomLowCabinet => 'Low cabinet';

  @override
  String get roomPetBed => 'Pet bed';

  @override
  String get roomSavingsJar => 'Savings jar';

  @override
  String get roomWallShelf => 'Wall shelf';

  @override
  String get roomTerracottaPouf => 'Terracotta pouf';

  @override
  String get roomBlueCreamRug => 'Blue and cream rug';

  @override
  String get roomSuggestCabinet =>
      'Place it by the left wall. Tap the highlighted spot.';

  @override
  String get roomSuggestPetBed =>
      'Place it low to the left of your companion. Tap the highlighted spot.';

  @override
  String get roomSuggestSavingsJar =>
      'Try the table or the small floor nook. Tap a highlighted spot.';

  @override
  String get roomSuggestWallShelf =>
      'Hang it on an open wall. Tap a highlighted spot.';

  @override
  String get roomSuggestPouf =>
      'Balance the room on the right. Tap the highlighted spot.';

  @override
  String get roomSuggestBlueRug =>
      'Lay it beneath your companion. Tap the highlighted spot.';

  @override
  String get roomSaved => 'Your room was saved.';

  @override
  String get roomPlaced => 'Placed';

  @override
  String get roomSurfaceWall => 'Wall';

  @override
  String get roomSurfaceFloor => 'Floor';

  @override
  String get roomSurfaceTabletop => 'Table';

  @override
  String get roomSurfaceRug => 'Rug';

  @override
  String roomSlotLabel(String surface, int number) {
    return '$surface, spot $number';
  }

  @override
  String roomPickWall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count spots on the wall. Tap where it goes.',
      one: 'There is one spot on the wall. Tap it to hang this.',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count spots on the floor. Tap where it goes.',
      one: 'There is one spot on the floor. Tap it to put this there.',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count spots on the table. Tap where it goes.',
      one: 'There is one spot on the table. Tap it to put this there.',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count spots for a rug. Tap where it goes.',
      one: 'There is one spot for a rug. Tap it to lay this there.',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count spots it can go. Tap where it goes.',
      one: 'There is one spot it can go. Tap it to put this there.',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove =>
      'Tap another spot to move it, or its own spot to take it out.';

  @override
  String get roomTapToRemove => 'Tap its spot again to take it out.';

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
  String get settingsTitle => 'My Sobrita';

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
  String get currencyRegionAmericas => 'Americas';

  @override
  String get currencyRegionEurope => 'Europe';

  @override
  String get currencyRegionAsiaPacific => 'Asia and Oceania';

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
      'Allow Sobrita notifications to turn on quick entry.';

  @override
  String get widgetTodayLeft => 'Left today';

  @override
  String get widgetCycleBalance => 'Balance';

  @override
  String get widgetOpenApp => 'Open Sobrita';

  @override
  String get widgetRegisterExpense => 'Add expense';

  @override
  String get settingsBackup => 'Data backup';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsBackupCopied => 'Backup copied to the clipboard.';

  @override
  String get settingsRestorePurchases => 'Restore purchases';

  @override
  String get settingsAccount => 'Google account';

  @override
  String get settingsAccountConnect => 'Connect';

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
      'Your purchase arrived but could not be saved. It will be applied the next time you open Sobrita.';

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
      'Your data is kept on this device. You don\'t need an account to use Sobrita.';

  @override
  String get settingsSectionShop => 'Store';

  @override
  String get settingsRemoveAds => 'Remove general ads';

  @override
  String get settingsRemoveAdsHint =>
      'Removes ads from the activity list. Rewarded ads stay available.';

  @override
  String get settingsPackName => 'Michi & Friends';

  @override
  String get settingsPackHint =>
      '3 characters + Michi\'s star. Also removes general ads.';

  @override
  String get settingsOwned => 'Owned';

  @override
  String get settingsShopRestoreNote =>
      'Purchases stay with your store account. You can restore them after reinstalling.';

  @override
  String get settlementTitle => 'This cycle\'s close';

  @override
  String get settlementSpent => 'Spent';

  @override
  String get settlementLeft => 'Left over';

  @override
  String get settlementOver => 'Over';

  @override
  String get settlementAverage => 'Daily average';

  @override
  String get settlementContinue => 'Done';

  @override
  String get settlementCtaTitle => 'Go get a special decoration';

  @override
  String get settlementCtaAction => 'Open collection';

  @override
  String get settingsSectionBudget => 'Budget';

  @override
  String get settingsSectionScreen => 'Display';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsAdPrivacy => 'Ad privacy choices';

  @override
  String get settingsAdPrivacyValue => 'Manage';

  @override
  String get settingsAdPrivacyFailed =>
      'Couldn\'t open ad privacy choices. Please try again.';

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
      other: '$days days with Sobrita',
      one: '1 day with Sobrita',
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
  String get appName => 'Sobrita';

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
  String cycleHistoryAverage(String amount) {
    return 'Daily average $amount';
  }

  @override
  String get cycleHistoryAveragePending => 'Daily average · still gathering';

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
  String get prologuePoodleTrait => 'All energy.\nLooks after you.';

  @override
  String get prologueSchnauzerTrait => 'Thoughtful.\nKeeps watch.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'All energy.\nLooks after you.';

  @override
  String get prologueLockedSoon => 'Art on the way';

  @override
  String get prologueOtherStays =>
      'The other one stays too. You can switch companions later.';

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
  String get releaseNote103GuineaPig =>
      'Guinea Pig is in the collection. Two short ads, and they stay.';

  @override
  String get releaseNote103Widget =>
      'The home widget shows who you live with, and writes the amount the same way the app does.';

  @override
  String get releaseNote102Schnauzer =>
      'Schnauzer is in the collection. Two short ads, and they stay.';

  @override
  String get releaseNote102Rooms =>
      'The house can be a garden or a beach, and a chair, a lamp and a clock are ready to place.';

  @override
  String get releaseNote102Missions =>
      'Two of the three daily missions change every day, and the ones that take an extra step pay more XP.';

  @override
  String get releaseNote102Amounts =>
      'Colombian, Argentine and Chilean pesos, Brazilian reais and euros now use a comma, as in 1.234,56.';

  @override
  String get releaseNote101Currencies =>
      'Money can now be labelled in Colombian, Argentine and Chilean pesos, soles, pounds or yen.';

  @override
  String get releaseNote101Celebration =>
      'The celebration now fills its card and finishes its jump.';

  @override
  String get releaseNote100Launch => 'The first version of Sobrita.';

  @override
  String get updateAvailableTitle => 'There\'s a new version';

  @override
  String get updateAvailableBody => 'Update to get the latest Sobrita.';

  @override
  String updateCurrentVersion(String version) {
    return 'Your version: v$version';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get updateLater => 'Not now';

  @override
  String get updateBannerMessage => 'New version available';

  @override
  String get updateBannerDismiss => 'Dismiss the notice';

  @override
  String get updateStoreFailed => 'Couldn\'t open Google Play.';

  @override
  String get settingsCheckUpdate => 'Check for updates';

  @override
  String get settingsCheckUpdateBusy => 'Checking…';

  @override
  String get settingsCheckUpdateUpToDate => 'You\'re up to date.';

  @override
  String get settingsRateApp => 'Rate Sobrita';

  @override
  String get settingsOurApps => 'Recommended apps';

  @override
  String get ourAppsIntro => 'Made by the Sobrita team.';

  @override
  String get ourAppsOpen => 'View on Google Play';

  @override
  String get ourAppsLoopetKind => 'Routines';

  @override
  String get ourAppsLoopetBlurb =>
      'Your whole day in one circle. See what to do now and what comes next.';

  @override
  String get ourAppsRandomFocusKind => 'Focus';

  @override
  String get ourAppsRandomFocusBlurb =>
      'Spin the wheel to pick how long, then focus without overthinking it.';

  @override
  String get releaseAnnouncementViewAll => 'See all';

  @override
  String get releaseAnnouncementDone => 'Done';

  @override
  String get settingsReleaseNotesUnread => 'Unread release notes';

  @override
  String get fixedSectionTitle => 'Fixed expenses';

  @override
  String fixedSectionMonth(String month) {
    return '$month · separate from your daily amount';
  }

  @override
  String fixedPaidOfTotal(String paid, String total) {
    return 'Paid $paid of $total';
  }

  @override
  String get fixedAdd => 'Add fixed expense';

  @override
  String get fixedEmptyBody =>
      'Rent, phone, electricity: add them once and I\'ll remind you when they\'re due. They don\'t change your daily amount.';

  @override
  String get fixedFrequencyWeekly => 'Every week';

  @override
  String get fixedFrequencySemiMonthly => 'Twice a month';

  @override
  String get fixedFrequencyMonthly => 'Every month';

  @override
  String get fixedFrequencyBimonthly => 'Every 2 months';

  @override
  String get fixedStatusPaid => 'Paid';

  @override
  String get fixedStatusTomorrow => 'Tomorrow';

  @override
  String get fixedStatusOverdue => 'Past due';

  @override
  String fixedApprox(String amount) {
    return 'about $amount';
  }

  @override
  String get fixedFormNewTitle => 'New fixed expense';

  @override
  String get fixedFormEditTitle => 'Edit fixed expense';

  @override
  String get fixedName => 'Name';

  @override
  String get fixedNameHint => 'Rent, phone, electricity…';

  @override
  String get fixedNameRequired => 'Give it a name';

  @override
  String get fixedHowOften => 'How often?';

  @override
  String get fixedNextDue => 'Next payment';

  @override
  String fixedThenDates(String dates) {
    return 'Then: $dates…';
  }

  @override
  String get fixedVariable => 'The amount changes each time';

  @override
  String get fixedVariableHint =>
      'I\'ll use what you paid last as the estimate.';

  @override
  String get fixedFormNote =>
      'It doesn\'t change your daily amount: your budget is what\'s left after fixed expenses.';

  @override
  String get fixedSave => 'Save fixed expense';

  @override
  String get fixedDelete => 'Delete fixed expense';

  @override
  String fixedDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get fixedDeleteBody =>
      'Payments you already recorded stay in your movements.';

  @override
  String get fixedDueToday => 'Due today';

  @override
  String get fixedDueTomorrow => 'Due tomorrow';

  @override
  String fixedDueOn(String date) {
    return 'Due $date';
  }

  @override
  String fixedWasDue(String date) {
    return 'Was due $date';
  }

  @override
  String get fixedHowMuch => 'How much did you pay?';

  @override
  String fixedLastTime(String amount) {
    return 'Last time: $amount';
  }

  @override
  String fixedTodayUnchanged(String amount) {
    return 'Today\'s amount stays at $amount.';
  }

  @override
  String fixedCashChange(String from, String to) {
    return 'Estimated cash: $from to $to';
  }

  @override
  String fixedPaidWith(String method) {
    return 'Paid by $method';
  }

  @override
  String get fixedChange => 'Change';

  @override
  String get fixedMarkPaid => 'I paid it';

  @override
  String get fixedNotYet => 'Not yet';

  @override
  String get fixedBillOnly => 'I just got the bill';

  @override
  String fixedBillSaved(String amount) {
    return 'Got it, expecting $amount.';
  }

  @override
  String fixedPaymentSaved(String name) {
    return '$name recorded.';
  }

  @override
  String get fixedHomeLabel => 'Fixed expense';

  @override
  String fixedHomeMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fixed payments to check',
      one: '1 fixed payment to check',
    );
    return '$_temp0';
  }

  @override
  String get fixedHomeSee => 'See';

  @override
  String get fixedIntroTitle =>
      'Your budget is for spending, fixed costs aside';

  @override
  String fixedIntroBody(String budget, String name) {
    return 'Fixed expenses don\'t lower your daily amount. If your $budget already counted “$name”, lower the budget.';
  }

  @override
  String get fixedIntroKeep => 'It\'s fine as is';

  @override
  String get fixedIntroAdjust => 'Adjust budget';

  @override
  String get fixedBadge => 'Fixed';

  @override
  String get fixedNothingThisMonth => 'Nothing due this month.';

  @override
  String get fixedReminderLabel => 'Reminder';

  @override
  String get fixedReminderNone => 'No reminder';

  @override
  String get fixedReminderSameDay => 'On the day';

  @override
  String get fixedReminderDayBefore => '1 day before';

  @override
  String get fixedReminderThreeDaysBefore => '3 days before';

  @override
  String get fixedReminderHint => 'I\'ll remind you at 9:00 in the morning.';

  @override
  String get fixedReminderBlocked =>
      'Sobrita\'s notifications are off, so I can\'t remind you.';

  @override
  String fixedReminderTitleToday(String name) {
    return '$name is due today';
  }

  @override
  String fixedReminderTitleTomorrow(String name) {
    return '$name is due tomorrow';
  }

  @override
  String fixedReminderTitleInDays(String name, int days) {
    return '$name is due in $days days';
  }

  @override
  String fixedReminderBody(String amount, String method) {
    return '$amount · $method. Mark it paid in Sobrita once you pay.';
  }
}
