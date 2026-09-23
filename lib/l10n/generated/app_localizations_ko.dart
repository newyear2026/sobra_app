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
  String get xpLevelTitle6 => '전문가 미치';

  @override
  String get xpLevelTitle7 => '전략가 미치';

  @override
  String get xpLevelTitle8 => '성장하는 미치';

  @override
  String get xpLevelTitle9 => '현명한 미치';

  @override
  String get xpLevelTitle10 => '전설의 미치';

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
  String xpLevelUpTitle(int level) {
    return '레벨 $level 달성!';
  }

  @override
  String get xpLevelUpContinue => '계속하기';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    return '새 아이템 $count개가 해금됐어요!';
  }

  @override
  String get dailyMissionTitle => '오늘의 미션';

  @override
  String get dailyMissionResetHint => '매일 자정에 새 미션으로 바뀌고, 밀린 미션은 쌓이지 않아요.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done / $total 완료';
  }

  @override
  String get dailyMissionAllDone => '모두 완료';

  @override
  String get dailyMissionRecordTitle => '오늘 기록 남기기';

  @override
  String get dailyMissionRecordHint => '지출이나 수입 한 건';

  @override
  String get dailyMissionSameDayTitle => '그날 일은 그날에';

  @override
  String get dailyMissionSameDayHint => '발생한 날과 기록한 날이 같아야 해요';

  @override
  String get dailyMissionBudgetTitle => '예산 확인하기';

  @override
  String get dailyMissionBudgetHint => '예산 탭을 한 번 열기';

  @override
  String get dailyMissionNoteTitle => '메모 남기기';

  @override
  String get dailyMissionNoteHint => '메모를 적은 기록 한 건';

  @override
  String get dailyMissionReceiptTitle => '영수증 남기기';

  @override
  String get dailyMissionReceiptHint => '지출에 영수증 사진 붙이기';

  @override
  String get dailyMissionThreeTodayTitle => '오늘 세 건 기록하기';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '오늘 날짜의 기록 $count건';
  }

  @override
  String get dailyMissionDone => '완료';

  @override
  String get dailyMissionPending => '남음';

  @override
  String dailyMissionReadyAt(String time) {
    return '완료 · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done / $total 완료 · 오늘 +$earned XP / +$possible XP';
  }

  @override
  String get dailyMissionXpDetail => '완료한 미션';

  @override
  String get xpRuleDailyMission => '하루에 한 번, 자정에 다시 시작';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '미션 $count개 완료',
      one: '미션 완료',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => '오늘의 습관으로 XP가 적립됐어요.';

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
  String get tabSettings => '내 정보';

  @override
  String get collectionTitle => '컬렉션';

  @override
  String get collectionSettingsValue => '보기';

  @override
  String get collectionCharacters => '캐릭터';

  @override
  String get collectionItems => '아이템';

  @override
  String collectionLevel(int level) {
    return '레벨 $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned / $total';
  }

  @override
  String get collectionCharactersHint => '함께할 캐릭터를 모아요';

  @override
  String get collectionItemsHint => '내 공간에 둘 물건을 모아요';

  @override
  String collectionCharacterPlaceholder(int number) {
    return '캐릭터 $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return '아이템 $number';
  }

  @override
  String get collectionEquipped => '선택됨';

  @override
  String get collectionOwned => '보유 중';

  @override
  String get collectionPlaceIt => '꾸미기에서 놓기';

  @override
  String get collectionBuy => '구매하기';

  @override
  String get collectionWatchAd => '광고 보기';

  @override
  String get collectionAdLoading => '광고 준비 중';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return '보상형 광고 보기 · $progress/$target · 하루 1편씩';
  }

  @override
  String get collectionAdUnavailable => '현재 광고 없음';

  @override
  String get collectionAdDailyCap => '오늘 한도 도달';

  @override
  String get collectionAdTomorrow => '내일 이어서';

  @override
  String collectionUnlockedNotice(String name) {
    return '$name을(를) 해금했어요!';
  }

  @override
  String get collectionAdDismissedNotice => '광고를 끝까지 봐야 진행돼요.';

  @override
  String get collectionPackOnly => '팩 전용';

  @override
  String get collectionPackDecoration => '미치의 별';

  @override
  String get collectionPackUnlock => '미치와 친구들에 들어 있어요. 따로 판매하지 않아요.';

  @override
  String collectionAdProgress(int progress, int target) {
    return '광고 $progress/$target';
  }

  @override
  String get collectionHowToGet => '획득 방법';

  @override
  String get collectionAlreadyOwned => '이미 컬렉션에 포함되어 있어요.';

  @override
  String get collectionIncludedUnlock => '처음부터 포함되어 있어요.';

  @override
  String collectionPurchaseUnlock(String price) {
    return '1회 구매 · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return '보상형 광고 보기 · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return '레벨 $level에서 해금돼요.';
  }

  @override
  String get collectionStorePricePending => '스토어 가격';

  @override
  String get collectionPreviewActionNotice => '구매와 광고는 다음 단계에서 연결할 예정이에요.';

  @override
  String get roomTitle => '내 방';

  @override
  String get roomOpen => '내 방 열기';

  @override
  String get roomDecorate => '꾸미기';

  @override
  String get roomDecorateTitle => '꾸미기';

  @override
  String get roomDone => '완료';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomCatReaction => '오늘도 잘했어!';

  @override
  String get roomInstruction => '아이템을 고르고 놓을 자리를 눌러주세요.';

  @override
  String get roomCategoryRooms => '방';

  @override
  String get roomCategoryFurniture => '가구';

  @override
  String get roomCategoryWallFloor => '벽·바닥';

  @override
  String get roomCategoryProps => '소품';

  @override
  String get roomCategoryCharacters => '캐릭터';

  @override
  String get roomCharacterInstruction => '함께 지낼 캐릭터를 골라요.';

  @override
  String get roomMoreInCollection => '컬렉션에서 더 보기';

  @override
  String get roomDefaultRug => '라벤더 러그';

  @override
  String get roomFloorLamp => '초록 조명';

  @override
  String get roomTablePlant => '테이블 화분';

  @override
  String get roomWallFrame => '벽 액자';

  @override
  String get roomSaved => '꾸미기를 저장했어요.';

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
  String get settingsTitle => '내 정보';

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
  String get currencyRegionAmericas => '아메리카';

  @override
  String get currencyRegionEurope => '유럽';

  @override
  String get currencyRegionAsiaPacific => '아시아·오세아니아';

  @override
  String get settingsCurrency => '통화';

  @override
  String get settingsBudgetCycle => '예산 주기';

  @override
  String get settingsCountDay => '집계하는 날';

  @override
  String get settingsReduceMotionHint => '휴대폰에서 이미 설정했다면 자동으로 켜져요.';

  @override
  String get settingsQuickEntry => '빠른 기록';

  @override
  String get settingsQuickEntryHint => '잠금화면에 수입과 지출 버튼을 표시해요.';

  @override
  String get quickEntryQuestion => '무엇을 기록할까요?';

  @override
  String get quickEntryDenied => '빠른 기록을 사용하려면 Sobrita 알림을 허용해 주세요.';

  @override
  String get settingsBackup => '데이터 백업';

  @override
  String get settingsCopy => '복사';

  @override
  String get settingsBackupCopied => '백업을 클립보드에 복사했어요.';

  @override
  String get settingsRestorePurchases => '구매 복원';

  @override
  String get settingsAccount => '구글 계정';

  @override
  String get settingsAccountConnect => '연결';

  @override
  String get settingsRestore => '복원';

  @override
  String get purchaseRestored => '완료했어요. 구매 항목이 돌아왔어요.';

  @override
  String get purchaseFailureStoreUnavailable =>
      '지금은 스토어에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get purchaseFailureRejected => '구매를 완료하지 못했어요. 결제된 금액은 없어요.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      '구매는 도착했지만 저장하지 못했어요. 다음에 앱을 열 때 적용돼요.';

  @override
  String get purchaseFailureNothingToRestore => '이 계정에서 구매 내역을 찾지 못했어요.';

  @override
  String get collectionPurchasing => '구매 중…';

  @override
  String get settingsXpPreview => 'XP 미리보기';

  @override
  String get settingsDesign => '디자인';

  @override
  String get settingsStorageNote =>
      '데이터는 이 기기에만 저장돼요. Sobrita를 쓰는 데 계정은 필요 없어요.';

  @override
  String get settingsSectionShop => '상점';

  @override
  String get settingsRemoveAds => '일반 광고 제거';

  @override
  String get settingsRemoveAdsHint =>
      '거래 내역의 일반 광고가 사라져요. 보상형 광고는 그대로 볼 수 있어요.';

  @override
  String get settingsPackName => '미치와 친구들';

  @override
  String get settingsPackHint => '캐릭터 3종 + 미치의 별. 일반 광고도 함께 제거돼요.';

  @override
  String get settingsOwned => '보유 중';

  @override
  String get settingsShopRestoreNote => '구매 항목은 스토어 계정으로 언제든 복원할 수 있어요.';

  @override
  String get settlementTitle => '이번 주기 결산';

  @override
  String get settlementSpent => '지출';

  @override
  String get settlementLeft => '남음';

  @override
  String get settlementOver => '초과';

  @override
  String get settlementAverage => '일평균';

  @override
  String get settlementContinue => '확인';

  @override
  String get settlementCtaTitle => '특별 꾸미기 받으러 가기';

  @override
  String get settlementCtaAction => '컬렉션 보기';

  @override
  String get settingsSectionBudget => '예산';

  @override
  String get settingsSectionScreen => '화면';

  @override
  String get settingsSectionData => '데이터';

  @override
  String get settingsSectionPrivacy => '개인정보';

  @override
  String get settingsAdPrivacy => '광고 개인정보 설정';

  @override
  String get settingsAdPrivacyValue => '관리';

  @override
  String get settingsAdPrivacyFailed => '광고 개인정보 설정을 열지 못했어요. 다시 시도해 주세요.';

  @override
  String get settingsSectionDesign => '디자인';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '기록 $movements건',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Sobrita와 함께한 $days일',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => '자동';

  @override
  String get languageAutomaticHint => '휴대폰 설정을 따라요';

  @override
  String get transactionsTitle => '내역';

  @override
  String get dailySpendTitle => '일별 지출';

  @override
  String dailySpendLimit(String amount) {
    return '하루 $amount';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return '이번 주기 $amount';
  }

  @override
  String get dailyIncomeTitle => '일별 수입';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return '이번 주기 $amount';
  }

  @override
  String get transactionsEmptyTitle => '아직 내역이 없어요';

  @override
  String get transactionsEmptyMessage => '첫 지출을 기록하면 이번 주기 요약이 여기에 나와요.';

  @override
  String get transactionsEmptyExpensesTitle => '아직 지출이 없어요';

  @override
  String get transactionsEmptyExpensesMessage => '지출을 기록하면 날짜별로 여기에 나와요.';

  @override
  String get transactionsEmptyIncomesTitle => '아직 수입이 없어요';

  @override
  String get transactionsEmptyIncomesMessage => '수입을 기록하면 날짜별로 여기에 나와요.';

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
  String get appName => 'Sobrita';

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
  String get homeFirstQuestLabel => '첫 퀘스트';

  @override
  String get homeBudgetQuestBody => '예산을 정해줘. 그래야 하루에 쓸 수 있는 돈을 계산해 줄게.';

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
  String get budgetNotSetTitle => '아직 예산이 없어요';

  @override
  String get budgetNotSetBody => '예산을 정하면 하루에 얼마 쓸 수 있는지 알려드려요.';

  @override
  String get budgetSetAction => '예산 정하기';

  @override
  String budgetTooLow(String allocated) {
    return '총액은 이번 주기에 배정한 수입($allocated)보다 커야 해요.';
  }

  @override
  String budgetSpentShare(int percent) {
    return '예산의 $percent%';
  }

  @override
  String budgetRingSpent(String amount) {
    return '지출 $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return '$amount 남음';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent%';
  }

  @override
  String get cycleHistoryTitle => '지난 주기';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '주기 $total개 중 $green개 흑자',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return '예산 $budget · 지출 $spent';
  }

  @override
  String get cycleHistoryEmpty => '아직 마감된 주기가 없어요.';

  @override
  String cycleHistoryAverage(String amount) {
    return '일평균 $amount';
  }

  @override
  String get cycleHistoryAveragePending => '일평균 · 데이터를 모으는 중이에요';

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
  String get receiptTitle => '영수증';

  @override
  String get receiptAdd => '영수증 추가';

  @override
  String get receiptCamera => '카메라';

  @override
  String get receiptGallery => '사진첩';

  @override
  String get receiptChange => '변경';

  @override
  String get receiptRemove => '삭제';

  @override
  String get receiptHint => '이 지출이 뭐였는지 기억나게 해 줄 사진 한 장.';

  @override
  String get receiptAttached => '영수증 첨부됨';

  @override
  String get receiptView => '영수증 보기';

  @override
  String get receiptClose => '닫기';

  @override
  String get receiptMissing => '사진이 이 기기에 더 이상 없어요.';

  @override
  String get receiptFailed => '사진을 저장하지 못했어요.';

  @override
  String get receiptBackupNote => '백업에는 영수증 사진이 포함되지 않아요.';

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
  String get prologueRainNoEnd => '비가 그칠 기미가 없다.';

  @override
  String get prologueRentPaid => '월세는 냈고, 통장에는 다음 급여일까지 쓸 돈이 남아 있었다.';

  @override
  String get prologueSoundAtDoor => '현관 쪽에서 소리가 났다.';

  @override
  String get prologueGoLook => '나가 본다';

  @override
  String get prologueWetTracks => '젖은 발자국 두 줄이 마루를 가로질렀다.';

  @override
  String get prologueShelter => '비 좀 피하자.';

  @override
  String get prologueItSpoke => '…말을 했다.';

  @override
  String get prologueReplySurprised => '지금 말했어?';

  @override
  String get prologueReplyTowel => '(조용히 수건을 가져온다)';

  @override
  String get prologueEarnKeep => '재워준 값은 해야지. 숫자 세는 건 내가 맡을게.';

  @override
  String get prologueAskSchedule => '그럼 먼저 — 돈이 언제 들어와?';

  @override
  String get prologueAskPayday => '며칠에 받아? 앞 날짜만 알려주면 나머지는 내가 셀게.';

  @override
  String prologueAskBudget(int days) {
    return '다음 급여일까지 $days일 남았어. 이 기간에 얼마나 쓸 생각이야?';
  }

  @override
  String get prologueSkipIsFine => '건너뛰어도 괜찮아. 대신 집에 가서 잊지 말라고 한 번 물어볼게.';

  @override
  String get prologueSkip => '건너뛰기';

  @override
  String get prologueDriedOff => '수건으로 닦아주자 둘 다 얌전해졌다. 비는 아직 그치지 않았다.';

  @override
  String get prologueWhoSits => '누가 옆에 앉을까?';

  @override
  String get prologueMichiTrait => '조용하다.\n셈이 빠르다.';

  @override
  String get prologuePoodleName => '푸들';

  @override
  String get prologuePoodleTrait => '기운이 넘친다.\n잘 챙긴다.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => '기운이 넘친다.\n잘 챙긴다.';

  @override
  String get prologueLockedSoon => '아트 준비 중';

  @override
  String get prologueOtherStays => '다른 한 쪽도 함께 지내요. 나중에 언제든 바꿀 수 있어요.';

  @override
  String get prologueLiveTogether => '같이 지내자';

  @override
  String prologueGreeting(String name) {
    return '나는 $name. 문 열어줘서 고마워.';
  }

  @override
  String get onboardingStart => '시작하기';

  @override
  String get onboardingTagline => '부담 없는 돈 관리.';

  @override
  String get onboardingPromise => '오늘 얼마나 쓸 수 있는지 알려드려요.';

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
  String get onboardingBudgetLater => '예산은 나중에 홈에서 정할 수 있어요.';

  @override
  String get onboardingNotNow => '나중에';

  @override
  String get onboardingCashQuestion => '오늘 현금이\n얼마나 있나요?';

  @override
  String get onboardingCashOptional => '나중에 세고 싶다면 비워 두세요.';

  @override
  String get onboardingCashIsBaseline => '이건 첫 집계예요. 수입이 아니에요.';

  @override
  String onboardingSettledIn(String name) {
    return '비가 그쳤다. $name가 네 옆에 자리를 잡았다.';
  }

  @override
  String get onboardingFirstQuests => '오늘의 퀘스트';

  @override
  String get onboardingWaitingAtHome => '집에서 기다리는 것';

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

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsReleaseNotes => '새로운 소식';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => '새로운 소식';

  @override
  String get releaseNotesCurrent => '현재';

  @override
  String releaseNotesRetention(int count) {
    return '최근 $count개 버전까지 보관해요.';
  }

  @override
  String get releaseNote101Currencies =>
      '이제 콜롬비아·아르헨티나·칠레 페소, 솔, 파운드, 엔으로도 금액을 표시할 수 있어요.';

  @override
  String get releaseNote101Celebration => '축하 연출이 카드에 꽉 차게 나오고, 중간에 끊기지 않아요.';

  @override
  String get releaseNote100Launch => 'Sobrita의 첫 번째 버전이에요.';

  @override
  String get updateAvailableTitle => '새 버전이 있어요';

  @override
  String get updateAvailableBody => '업데이트하면 최신 Sobrita를 쓸 수 있어요.';

  @override
  String updateCurrentVersion(String version) {
    return '현재 버전: v$version';
  }

  @override
  String get updateAction => '업데이트하기';

  @override
  String get updateLater => '나중에하기';

  @override
  String get updateBannerMessage => '새 버전이 나왔어요';

  @override
  String get updateBannerDismiss => '알림 닫기';

  @override
  String get updateStoreFailed => '구글 플레이를 열 수 없어요.';

  @override
  String get settingsCheckUpdate => '업데이트 확인';

  @override
  String get settingsCheckUpdateBusy => '확인 중…';

  @override
  String get settingsCheckUpdateUpToDate => '최신 버전이에요.';

  @override
  String get settingsRateApp => '앱 평가하기';

  @override
  String get releaseAnnouncementViewAll => '전체 보기';

  @override
  String get releaseAnnouncementDone => '확인';

  @override
  String get settingsReleaseNotesUnread => '읽지 않은 새로운 소식';
}
