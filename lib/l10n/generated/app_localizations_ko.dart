// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get categoryFood => '식비';

  @override
  String get categoryTransport => '교통';

  @override
  String get categoryShopping => '쇼핑';

  @override
  String get categoryHome => '집';

  @override
  String get categoryServices => '공과금';

  @override
  String get categoryHealth => '건강';

  @override
  String get categoryEducation => '교육';

  @override
  String get categoryEntertainment => '여가';

  @override
  String get categoryPets => '반려동물';

  @override
  String get categoryOther => '기타';

  @override
  String get incomeKindSalary => '평소 받는 급여';

  @override
  String get incomeKindExtra => '추가 수입';

  @override
  String get incomeKindCash => '현금 수입';

  @override
  String get incomeKindRefund => '환불';

  @override
  String get incomeAllocationCycle => '이번 주기';

  @override
  String get incomeAllocationSavings => '저축';

  @override
  String get payCycleSemiMonthly => '월 2회';

  @override
  String get payCycleBiweekly => '2주마다';

  @override
  String get payCycleMonthly => '월 1회';

  @override
  String get payCycleWeekly => '매주';

  @override
  String get payCycleIrregular => '정해진 날 없음';

  @override
  String get cashResolutionExpense => '찾은 지출';

  @override
  String get cashResolutionIncome => '현금 수입';

  @override
  String get cashResolutionTransfer => '계좌 간 이동';

  @override
  String get cashResolutionCorrection => '이전 집계 정정';

  @override
  String get cashResolutionPending => '확인이 필요한 차액';

  @override
  String get paymentMethodCash => '현금';

  @override
  String get paymentMethodCard => '카드';

  @override
  String get movementPending => '미확인';

  @override
  String get movementCashCount => '현금 세기';

  @override
  String get xpCashCountTitle => '현금 세기';

  @override
  String get xpCashCountDetail => '이번 주 첫 집계로 받은 XP';

  @override
  String get xpCycleInGreenSemiMonthly => '이번 반달을 흑자로 마감했어요';

  @override
  String get xpCycleInGreenMonthly => '이번 달을 흑자로 마감했어요';

  @override
  String get xpCycleInGreenWeekly => '이번 주를 흑자로 마감했어요';

  @override
  String get xpCycleInGreenGeneric => '이번 주기를 흑자로 마감했어요';

  @override
  String get xpCycleInGreenDetail => '주기가 끝났을 때의 예산 결과';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '한도 안에서 보낸 $count일',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail => '마감할 때 한 번만 계산돼요';

  @override
  String get xpFirstSuccessfulCycleTitle => '첫 흑자 주기';

  @override
  String get xpFirstSuccessfulCycleDetail => '한 번만 주는 보너스';

  @override
  String get xpLevelTitle1 => '호기심 많은 미치';

  @override
  String get xpLevelTitle2 => '알뜰한 미치';

  @override
  String get xpLevelTitle3 => '계산하는 미치';

  @override
  String get xpLevelTitle4 => '지키는 미치';

  @override
  String get xpLevelTitle5 => '마스터 미치';

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '주기 $count개 마감',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP가 자동으로 적립됐어요.';

  @override
  String get xpNoticeCashCountTitle => '현금 집계 저장됨';

  @override
  String get xpNoticeCashCountDetail => '이번 주 첫 집계예요.';

  @override
  String get storeFailureGeneric => '변경 사항을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get storeFailureBudgetBelowCycleIncome => '총액은 이번 주기에 배정한 수입보다 커야 해요.';

  @override
  String get storeFailureFutureMovement => '미래 날짜로는 기록할 수 없어요.';

  @override
  String get storeFailureRestoreFailed => '백업을 복원하지 못했어요.';

  @override
  String get storeFailureOriginalNotKept => '원본 파일을 보관하지 못했어요.';

  @override
  String get storeFailureBackupNotSaved => '백업을 저장하지 못했어요.';

  @override
  String get storeFailureSaveFailed => '데이터를 저장하지 못했어요.';

  @override
  String get monthAbbr1 => '1월';

  @override
  String get monthAbbr2 => '2월';

  @override
  String get monthAbbr3 => '3월';

  @override
  String get monthAbbr4 => '4월';

  @override
  String get monthAbbr5 => '5월';

  @override
  String get monthAbbr6 => '6월';

  @override
  String get monthAbbr7 => '7월';

  @override
  String get monthAbbr8 => '8월';

  @override
  String get monthAbbr9 => '9월';

  @override
  String get monthAbbr10 => '10월';

  @override
  String get monthAbbr11 => '11월';

  @override
  String get monthAbbr12 => '12월';

  @override
  String get back => '뒤로';

  @override
  String get reduceMotion => '움직임 줄이기';

  @override
  String get catMotionIdle => '고양이가 편히 쉬고 있어요';

  @override
  String get catMotionWalk => '고양이가 걷고 있어요';

  @override
  String get catMotionCalculate => '고양이가 계산하고 있어요';

  @override
  String get catMotionSaving => '고양이가 저금통에 동전을 넣고 있어요';

  @override
  String get catMotionCelebrate => '고양이가 기뻐하고 있어요';

  @override
  String get catMotionConcern => '고양이가 예산을 걱정하고 있어요';

  @override
  String get characterRoleIdle => '캐릭터가 편히 쉬고 있어요';

  @override
  String get characterRoleActivity => '캐릭터가 움직이고 있어요';

  @override
  String get characterRoleProcessing => '캐릭터가 계산하고 있어요';

  @override
  String get characterRolePositive => '캐릭터가 좋은 변화를 보여줘요';

  @override
  String get characterRoleSuccess => '캐릭터가 성과를 축하하고 있어요';

  @override
  String get characterRoleWarning => '캐릭터가 걱정하고 있어요';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get cancel => '취소';

  @override
  String get tabHome => '홈';

  @override
  String get tabMovements => '내역';

  @override
  String get tabRegister => '기록';

  @override
  String get tabBudget => '예산';

  @override
  String get tabSettings => '설정';

  @override
  String get xpHistoryTitle => '내 진행 상황';

  @override
  String xpTotal(int count) {
    return '총 $count XP';
  }

  @override
  String get xpMaxLevel => '최고 레벨';

  @override
  String xpRemaining(int count) {
    return '$count XP 남음';
  }

  @override
  String get xpHistoryHint => 'XP는 자동으로 적립돼요. 앱을 닫아도 각 항목의 이유와 계산이 그대로 남아요.';

  @override
  String get xpHistoryEmptyTitle => '아직 XP가 없어요';

  @override
  String get xpHistoryEmptyMessage => '그 주의 첫 현금 집계와 주기 마감이 여기에 표시돼요.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => '계산 보기';

  @override
  String get xpCalculationTitle => '어떻게 계산했나요';

  @override
  String get xpDetailCycle => '주기';

  @override
  String get xpDetailBudget => '예산';

  @override
  String get xpDetailSpent => '지출';

  @override
  String get xpDetailResult => '결과';

  @override
  String get xpDetailRule => '규칙';

  @override
  String get xpDetailCredited => '적립된 XP';

  @override
  String get xpRuleCashCount => '일주일에 최대 한 번';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 기준으로 환산한 보상',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => '한 번만 주는 50 XP 보너스';

  @override
  String get recoveryNotYet => '아직 데이터를 복구하지 못했어요.';

  @override
  String get recoveryStartFreshQuestion => '처음부터 시작할까요?';

  @override
  String get recoveryStartFreshBody => '새 데이터를 만들기 전에 원본 파일을 복사해 둘게요.';

  @override
  String get recoveryStartFresh => '처음부터 시작';

  @override
  String get recoveryTitle => '데이터를 읽지 못했어요';

  @override
  String get recoveryOriginalKept => '원본 파일은 그대로 있어요. 덮어쓰거나 지우지 않았어요.';

  @override
  String get recoveryOptions => '다시 시도하거나, 백업을 쓰거나, 파일을 내보내 보관할 수 있어요.';

  @override
  String get recoveryRetrying => '다시 시도 중…';

  @override
  String get recoveryRetry => '다시 시도';

  @override
  String get recoveryUseBackup => '백업 사용';

  @override
  String get recoveryExport => '파일 내보내기';

  @override
  String get recoveryExported => '원본 파일을 복사했어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String currencyChangeTitle(String code) {
    return '$code로 바꿀까요?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return '금액은 환산되지 않아요. $example은(는) $converted이(가) 돼요. 표기만 바뀝니다.';
  }

  @override
  String get currencyChangeConfirm => '표기 바꾸기';

  @override
  String get settingsCurrency => '통화';

  @override
  String get settingsBudgetCycle => '예산 주기';

  @override
  String get settingsCountDay => '집계하는 날';

  @override
  String get settingsCountDaySunday => '일요일';

  @override
  String get settingsReduceMotionHint => '휴대폰에서 이미 설정했다면 자동으로 켜져요.';

  @override
  String get settingsBackup => '데이터 백업';

  @override
  String get settingsCopy => '복사';

  @override
  String get settingsBackupCopied => '백업을 클립보드에 복사했어요.';

  @override
  String get settingsXpPreview => 'XP 미리보기';

  @override
  String get settingsDesign => '디자인';

  @override
  String get settingsStorageNote => '데이터는 이 기기에만 저장돼요. Sobra를 쓰는 데 계정은 필요 없어요.';

  @override
  String get settingsFixedInV1 => '이 항목은 버전 1에서 고정이에요.';

  @override
  String get languageAutomatic => '자동';

  @override
  String get languageAutomaticHint => '휴대폰 설정을 따라요';

  @override
  String get transactionsTitle => '내역';

  @override
  String get transactionsEmptyTitle => '아직 내역이 없어요';

  @override
  String get transactionsEmptyMessage => '첫 지출을 기록하면 이번 주기 요약이 여기에 나와요.';

  @override
  String get transactionsExpensePinned =>
      '이 지출은 현금 집계에서 만들어졌어요. 고치려면 다시 세어 주세요.';

  @override
  String get transactionsIncomePinned =>
      '이 수입은 현금 집계에서 만들어졌어요. 고치려면 다시 세어 주세요.';

  @override
  String get transactionsExpenseDeleted => '지출을 삭제했어요.';

  @override
  String get transactionsIncomeDeleted => '수입을 삭제했어요.';

  @override
  String get undo => '실행 취소';

  @override
  String get edit => '수정';

  @override
  String get delete => '삭제';

  @override
  String get identifyDifference => '차액 확인하기';

  @override
  String get editMovement => '내역 수정';

  @override
  String get amount => '금액';

  @override
  String get editPendingHint => '금액은 현금 집계에서 왔어요. 분류와 메모는 바꿀 수 있어요.';

  @override
  String get category => '분류';

  @override
  String get note => '메모';

  @override
  String get noteExample => '예: 김밥';

  @override
  String get replacesPendingHint => '미확인 조정을 대체해요. 지출이 또 추가되지 않아요.';

  @override
  String get saveWithoutDuplicating => '중복 없이 저장';

  @override
  String get saveChanges => '변경 사항 저장';

  @override
  String get save => '저장';

  @override
  String get budget => '예산';

  @override
  String get spent => '지출';

  @override
  String get appName => 'Sobra';

  @override
  String get homeCycleBalance => '주기 잔액';

  @override
  String get homeTodayLeft => '오늘 남은 돈';

  @override
  String homeOverBudget(String budget) {
    return '이번 주기 예산 $budget을(를) 넘었어요';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return '오늘 한도 $limit · 주기에 $remaining 남음';
  }

  @override
  String get homeCycleProgress => '주기 진행';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => '예상 현금';

  @override
  String get homeCashUnset => '현금 미설정';

  @override
  String homeLastCount(String amount) {
    return '마지막 집계: $amount';
  }

  @override
  String get homeFirstCountHint => '먼저 한 번 세어 보면 시작할 수 있어요.';

  @override
  String get homeRecentMovements => '최근 내역';

  @override
  String get homeSeeAll => '전체 보기';

  @override
  String get homeGoingWell => '잘 하고 있어요';

  @override
  String get homeAdjustCalmly => '천천히 조정해 봐요';

  @override
  String get budgetTitle => '예산';

  @override
  String get budgetCycleTotal => '주기 총액';

  @override
  String get budgetTotal => '총예산';

  @override
  String budgetTooLow(String allocated) {
    return '총액은 이번 주기에 배정한 수입($allocated)보다 커야 해요.';
  }

  @override
  String get budgetChangedTitle => '예산이 바뀌었어요';

  @override
  String get budgetChangedBody =>
      '분류별 한도는 어떻게 할까요? 비례로 조정하면 각 한도가 같은 비율로 바뀌어서 지금 배분이 그대로 유지돼요.';

  @override
  String get budgetKeepLimits => '그대로 두기';

  @override
  String get budgetScaleLimits => '비례로 조정하기';

  @override
  String get budgetByCategory => '분류별 예산';

  @override
  String budgetCategoryLimit(String category) {
    return '$category 한도';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => '마감 시 예상';

  @override
  String get budgetEstimatedLeft => '남을 것으로 보이는 금액';

  @override
  String get continueLabel => '계속';

  @override
  String get saving => '저장 중…';

  @override
  String dayOfMonth(int day) {
    return '$day일';
  }

  @override
  String get weekdayMonday => '월요일';

  @override
  String get weekdayTuesday => '화요일';

  @override
  String get weekdayWednesday => '수요일';

  @override
  String get weekdayThursday => '목요일';

  @override
  String get weekdayFriday => '금요일';

  @override
  String get weekdaySaturday => '토요일';

  @override
  String get weekdaySunday => '일요일';

  @override
  String get weekdayShortMonday => '월';

  @override
  String get weekdayShortTuesday => '화';

  @override
  String get weekdayShortWednesday => '수';

  @override
  String get weekdayShortThursday => '목';

  @override
  String get weekdayShortFriday => '금';

  @override
  String get weekdayShortSaturday => '토';

  @override
  String get weekdayShortSunday => '일';

  @override
  String get registerTitle => '기록';

  @override
  String get registerExpense => '지출';

  @override
  String get registerIncome => '수입';

  @override
  String get registerAmountAboveZero => '0보다 큰 금액을 입력해 주세요.';

  @override
  String get registerNoFutureMovements => '미래 날짜로는 기록할 수 없어요.';

  @override
  String get registerDate => '날짜';

  @override
  String get registerNoteExpenseExample => '예: 동네 분식집';

  @override
  String get registerNoteIncomeExample => '예: 금요일 팁';

  @override
  String get registerPayment => '결제';

  @override
  String get registerPaymentHint => '현금은 집계에서 차감돼요. 카드는 아니고요.';

  @override
  String get registerIncomeKind => '수입 종류';

  @override
  String get registerWhatToDo => '어떻게 할까요?';

  @override
  String get registerThisCycle => '이번 주기';

  @override
  String get registerSaveIt => '저축하기';

  @override
  String get registerReceivedIn => '받은 곳';

  @override
  String get registerAccount => '계좌';

  @override
  String get registerReconcileQuestion => '이 지출이 그 차액인가요?';

  @override
  String registerReconcileBody(String amount) {
    return '지난 집계에서 $amount이(가) 확인되지 않은 채 남아 있어요. 같은 지출이라면 중복으로 더하지 않고 연결할게요.';
  }

  @override
  String get registerReconcileNo => '아니요, 새 지출이에요';

  @override
  String get registerReconcileYes => '네, 연결할게요';

  @override
  String get registerDifferenceReconciled => '차액을 연결했어요';

  @override
  String get registerExpenseSaved => '지출을 저장했어요';

  @override
  String get registerIncomeSaved => '수입을 저장했어요';

  @override
  String get cashCountTitle => '현금 세기';

  @override
  String get cashCountPickWhatHappened => '차액이 왜 생겼는지 선택해 주세요.';

  @override
  String get cashCountSavedWithoutDuplicates => '중복 없이 집계를 저장했어요.';

  @override
  String get cashCountPrompt => '지금 가진 현금만 세어 주세요.';

  @override
  String get cashCountNoneYet => '아직 집계가 없어요';

  @override
  String get cashCountResultPending => '금액을 입력하면 결과가 나와요.';

  @override
  String get cashCountBaselineHint => '이 금액이 기준이 돼요. 수입으로 기록되지는 않아요.';

  @override
  String get cashCountExpected => '예상';

  @override
  String get cashCountCounted => '실제';

  @override
  String get cashCountBalanced => '딱 맞아요';

  @override
  String cashCountShort(String amount) {
    return '$amount 부족';
  }

  @override
  String cashCountExtra(String amount) {
    return '$amount 많음';
  }

  @override
  String get cashCountWhatHappened => '무슨 일이 있었나요?';

  @override
  String get cashCountHelperExpense => '기록하지 않은 지출이었어요.';

  @override
  String get cashCountHelperIncome => '새로 받은 돈이었어요.';

  @override
  String get cashCountHelperTransferOut => '입금했거나 다른 계좌로 옮겼어요.';

  @override
  String get cashCountHelperTransferIn => '출금했거나 다른 계좌에서 가져왔어요.';

  @override
  String get cashCountHelperCorrection => '이전 집계가 틀렸어요.';

  @override
  String get cashCountHelperPending => '나중에 정할게요.';

  @override
  String get cashCountSingleExpenseHint => '지출 하나만 만들어요. 다시 기록하지 않아도 돼요.';

  @override
  String get cashCountNoteTipExample => '예: 팁';

  @override
  String get cashCountWhatToDoWithMoney => '이 돈은 어떻게 할까요?';

  @override
  String get cashCountSaveFirst => '첫 집계 저장';

  @override
  String get cashCountSave => '집계 저장';

  @override
  String get cycleTitle => '내 주기';

  @override
  String get cycleCurrent => '현재 주기';

  @override
  String get cycleInProgress => '진행 중';

  @override
  String get cycleUnchanged => '바뀌지 않아요';

  @override
  String get cycleNewFrequency => '새 주기';

  @override
  String get cycleFirstPay => '첫 급여일';

  @override
  String get cyclePayDay => '급여일';

  @override
  String get cycleNext => '다음 주기';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return '변경은 다음 주기부터 적용되고, 이후 $days일마다 반복돼요.';
  }

  @override
  String get cycleChangeApplies => '변경은 다음 주기부터 적용돼요.';

  @override
  String get cycleSaveChange => '변경 저장';

  @override
  String get onboardingBudgetAboveZero => '0보다 큰 예산을 입력해 주세요.';

  @override
  String get onboardingCashOrSkip => '현금을 입력하거나 “나중에”를 선택해 주세요.';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get onboardingTagline => '부담 없는 돈 관리.';

  @override
  String get onboardingPromise => '오늘 얼마나 쓸 수 있는지 알려드려요.';

  @override
  String get onboardingNoAccount => '계정이 필요 없어요. 데이터는 기기에만 남아요.';

  @override
  String get onboardingHowPaid => '수입을 어떻게 받나요?';

  @override
  String get onboardingHowPaidHint => '예산 주기의 날짜가 여기서 정해져요.';

  @override
  String get onboardingCycleHelperSemiMonthly => '한 달에 두 번: 15일과 말일.';

  @override
  String get onboardingCycleHelperMonthly => '한 달에 한 번.';

  @override
  String get onboardingCycleHelperWeekly => '매주.';

  @override
  String get onboardingCycleHelperIrregular => '정해진 날짜가 없어요.';

  @override
  String get onboardingPlanWithoutFixedDate => '정해진 날 없이 계획하기';

  @override
  String get onboardingWhichDayPaid => '며칠에 받나요?';

  @override
  String get onboardingSecondPayEndOfMonth => '두 번째 급여 · 말일';

  @override
  String get onboardingHowManyDays => '며칠 단위로 계획할까요?';

  @override
  String get onboardingCyclePreview => '주기는 이렇게 돼요';

  @override
  String onboardingRepeatsEvery(int days) {
    return '끝나면 $days일짜리 다음 기간이 자동으로 시작돼요.';
  }

  @override
  String get onboardingShortMonthsNote => '날짜가 짧은 달에는 알아서 조정돼요.';

  @override
  String get onboardingBudgetQuestion => '이번 주기에\n얼마를 쓸까요?';

  @override
  String get onboardingNotNow => '나중에';

  @override
  String get onboardingCashQuestion => '오늘 현금이\n얼마나 있나요?';

  @override
  String get onboardingCashOptional => '나중에 세고 싶다면 비워 두세요.';

  @override
  String get onboardingCashIsBaseline => '이건 첫 집계예요. 수입이 아니에요.';

  @override
  String get onboardingGoHome => '홈으로';

  @override
  String get onboardingPlanReady => '계획이 준비됐어요';

  @override
  String get onboardingCanSpendToday => '오늘 쓸 수 있는 돈';

  @override
  String onboardingStepOf(int step, int total) {
    return '$total단계 중 $step';
  }

  @override
  String progressPercent(int percent) {
    return '진행률 $percent퍼센트';
  }

  @override
  String stepOf(int step, int total) {
    return '$total단계 중 $step단계';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly => '이번 2주를 흑자로 마감했어요';

  @override
  String get onboardingCycleHelperBiweekly => '마지막 급여일부터 2주마다.';

  @override
  String get cycleLastPayday => '마지막 급여일';

  @override
  String get onboardingWhenLastPaid => '마지막으로 받은 날은 언제인가요?';

  @override
  String get onboardingBiweeklyNeedsDate => '마지막 급여일을 선택해 주세요.';

  @override
  String get pickDate => '날짜 선택';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }
}
