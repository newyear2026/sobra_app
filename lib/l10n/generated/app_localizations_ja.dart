// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get categoryFood => '食費';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryShopping => '買い物';

  @override
  String get categoryHome => '住まい';

  @override
  String get categoryServices => '公共料金';

  @override
  String get categoryHealth => '健康';

  @override
  String get categoryEducation => '学び';

  @override
  String get categoryEntertainment => '娯楽';

  @override
  String get categoryPets => 'ペット';

  @override
  String get categoryOther => 'その他';

  @override
  String get incomeKindSalary => 'いつもの給料';

  @override
  String get incomeKindExtra => '臨時収入';

  @override
  String get incomeKindCash => '現金の収入';

  @override
  String get incomeKindRefund => '返金';

  @override
  String get incomeAllocationCycle => '今のサイクル';

  @override
  String get incomeAllocationSavings => '貯金';

  @override
  String get payCycleSemiMonthly => '月2回';

  @override
  String get payCycleBiweekly => '14日ごと';

  @override
  String get payCycleMonthly => '毎月';

  @override
  String get payCycleWeekly => '毎週';

  @override
  String get payCycleIrregular => '決まった日なし';

  @override
  String get cashResolutionExpense => 'わかった支出';

  @override
  String get cashResolutionIncome => '現金の収入';

  @override
  String get cashResolutionTransfer => '口座間の移動';

  @override
  String get cashResolutionCorrection => '数え直し';

  @override
  String get cashResolutionPending => '未確認の差額';

  @override
  String get paymentMethodCash => '現金';

  @override
  String get paymentMethodCard => 'カード';

  @override
  String get movementPending => '未確認';

  @override
  String get movementCashCount => '現金チェック';

  @override
  String get xpCashCountTitle => '現金チェック';

  @override
  String get xpCashCountDetail => '今週はじめてのXP付きチェック';

  @override
  String get xpCycleInGreenSemiMonthly => '半月を黒字で終えました';

  @override
  String get xpCycleInGreenMonthly => '1か月を黒字で終えました';

  @override
  String get xpCycleInGreenWeekly => '1週間を黒字で終えました';

  @override
  String get xpCycleInGreenGeneric => 'サイクルを黒字で終えました';

  @override
  String get xpCycleInGreenDetail => '締めたときの予算の結果';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '上限以下の日が$count日',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail => '締めたときに1回だけ計算';

  @override
  String get xpFirstSuccessfulCycleTitle => 'はじめての黒字サイクル';

  @override
  String get xpFirstSuccessfulCycleDetail => '1回かぎりのボーナス';

  @override
  String xpLevelTitle1(String name) {
    return '駆け出しの$name';
  }

  @override
  String xpLevelTitle2(String name) {
    return '節約家の$name';
  }

  @override
  String xpLevelTitle3(String name) {
    return '計算上手な$name';
  }

  @override
  String xpLevelTitle4(String name) {
    return '守り手の$name';
  }

  @override
  String xpLevelTitle5(String name) {
    return '達人の$name';
  }

  @override
  String xpLevelTitle6(String name) {
    return '熟練の$name';
  }

  @override
  String xpLevelTitle7(String name) {
    return '策士の$name';
  }

  @override
  String xpLevelTitle8(String name) {
    return '豊かな$name';
  }

  @override
  String xpLevelTitle9(String name) {
    return '賢者の$name';
  }

  @override
  String xpLevelTitle10(String name) {
    return '伝説の$name';
  }

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countつのサイクルを締めました',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XPは自動で加算されました。';

  @override
  String get xpNoticeCashCountTitle => '現金チェックを保存しました';

  @override
  String get xpNoticeCashCountDetail => '今週はじめてのXP付きチェックです。';

  @override
  String xpLevelUpTitle(int level) {
    return 'レベル$level！';
  }

  @override
  String get xpLevelUpContinue => '続ける';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいアイテムが$count個解放されました！',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => '今日のミッション';

  @override
  String get dailyMissionResetHint => '毎日0時に入れ替わります。持ち越しはありません。';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$total個中$done個クリア';
  }

  @override
  String get dailyMissionAllDone => '全部クリア';

  @override
  String get dailyMissionRecordTitle => '今日1件記録する';

  @override
  String get dailyMissionRecordHint => '支出でも収入でもOK';

  @override
  String get dailyMissionSameDayTitle => 'その日のうちに記録';

  @override
  String get dailyMissionSameDayHint => '使った日と記録した日が同じ';

  @override
  String get dailyMissionBudgetTitle => '予算を見る';

  @override
  String get dailyMissionBudgetHint => '予算タブを開く';

  @override
  String get dailyMissionNoteTitle => 'メモを付ける';

  @override
  String get dailyMissionNoteHint => 'メモ付きの記録を1件';

  @override
  String get dailyMissionReceiptTitle => 'レシートを残す';

  @override
  String get dailyMissionReceiptHint => '支出に写真を添付';

  @override
  String get dailyMissionThreeTodayTitle => '今日3件記録する';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '今日の日付の記録が$count件';
  }

  @override
  String get dailyMissionDone => 'クリア';

  @override
  String get dailyMissionPending => '未達成';

  @override
  String dailyMissionReadyAt(String time) {
    return 'クリア · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$total個中$done個クリア · 今日+$possible XP中+$earned XP';
  }

  @override
  String get dailyMissionXpDetail => 'ミッションクリア';

  @override
  String get xpRuleDailyMission => '1日1回。0時にリセット';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ミッションを$count個クリア',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => '今日の習慣にXPを加算しました。';

  @override
  String get storeFailureGeneric => '変更を保存できませんでした。もう一度お試しください。';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      '合計は、このサイクルにすでに割り当てた収入より多くしてください。';

  @override
  String get storeFailureFutureMovement => '未来の日付では記録できません。';

  @override
  String get storeFailureRestoreFailed => 'バックアップを復元できませんでした。';

  @override
  String get storeFailureOriginalNotKept => '元のファイルを残せませんでした。';

  @override
  String get storeFailureBackupNotSaved => 'バックアップを保存できませんでした。';

  @override
  String get storeFailureSaveFailed => 'データを保存できませんでした。';

  @override
  String get monthAbbr1 => '1月';

  @override
  String get monthAbbr2 => '2月';

  @override
  String get monthAbbr3 => '3月';

  @override
  String get monthAbbr4 => '4月';

  @override
  String get monthAbbr5 => '5月';

  @override
  String get monthAbbr6 => '6月';

  @override
  String get monthAbbr7 => '7月';

  @override
  String get monthAbbr8 => '8月';

  @override
  String get monthAbbr9 => '9月';

  @override
  String get monthAbbr10 => '10月';

  @override
  String get monthAbbr11 => '11月';

  @override
  String get monthAbbr12 => '12月';

  @override
  String dateShort(String day, String month) {
    return '$month$day日';
  }

  @override
  String dateFull(String day, String month, String year) {
    return '$year年$month$day日';
  }

  @override
  String get back => '戻る';

  @override
  String get reduceMotion => '動きを減らす';

  @override
  String get catMotionIdle => 'ネコがのんびり休んでいます';

  @override
  String get catMotionWalk => 'ネコが歩いています';

  @override
  String get catMotionCalculate => 'ネコが計算しています';

  @override
  String get catMotionSaving => 'ネコが貯金箱に小銭を入れています';

  @override
  String get catMotionCelebrate => 'ネコがお祝いしています';

  @override
  String get catMotionConcern => 'ネコが予算を心配しています';

  @override
  String get characterRoleIdle => 'キャラクターがのんびり休んでいます';

  @override
  String get characterRoleActivity => 'キャラクターが動いています';

  @override
  String get characterRoleProcessing => 'キャラクターが計算しています';

  @override
  String get characterRolePositive => 'キャラクターがうれしそうです';

  @override
  String get characterRoleSuccess => 'キャラクターがお祝いしています';

  @override
  String get characterRoleWarning => 'キャラクターが心配そうです';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get cancel => 'キャンセル';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabMovements => '履歴';

  @override
  String get tabRegister => '記録';

  @override
  String get tabBudget => '予算';

  @override
  String get tabSettings => 'マイページ';

  @override
  String get collectionTitle => 'コレクション';

  @override
  String get collectionSettingsValue => '見る';

  @override
  String get collectionCharacters => 'キャラクター';

  @override
  String get collectionItems => 'アイテム';

  @override
  String collectionLevel(int level) {
    return 'レベル$level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$total個中$owned個';
  }

  @override
  String get collectionCharactersHint => '仲間を集めよう';

  @override
  String get collectionItemsHint => 'お部屋に置くものを集めよう';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'キャラクター$number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'アイテム$number';
  }

  @override
  String get collectionEquipped => '使用中';

  @override
  String get collectionOwned => '入手済み';

  @override
  String get collectionPlaceIt => '置く';

  @override
  String get collectionBuy => '購入';

  @override
  String get collectionWatchAd => '広告を見る';

  @override
  String get collectionAdLoading => '準備中';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'リワード広告を見る · $progress/$target · 1日1回';
  }

  @override
  String get collectionAdUnavailable => '広告なし';

  @override
  String get collectionAdDailyCap => '今日の上限';

  @override
  String get collectionAdTomorrow => '続きは明日';

  @override
  String collectionUnlockedNotice(String name) {
    return '$nameが仲間になりました！';
  }

  @override
  String get collectionAdDismissedNotice => '最後まで見るとカウントされます。';

  @override
  String get collectionPackOnly => 'パック';

  @override
  String get collectionPackDecoration => 'Michiの星';

  @override
  String get collectionPackUnlock => '「Michiと仲間たち」に入っています。単品では売っていません。';

  @override
  String get collectionGiftOnly => 'ギフト';

  @override
  String get collectionGiftUnlock => '特別なプレゼントです。販売はしていません。';

  @override
  String collectionAdProgress(int progress, int target) {
    return '広告 $progress/$target';
  }

  @override
  String get collectionHowToGet => '入手方法';

  @override
  String get collectionAlreadyOwned => 'もうコレクションに入っています。';

  @override
  String get collectionIncludedUnlock => '最初から入っています。';

  @override
  String collectionPurchaseUnlock(String price) {
    return '買い切り · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'リワード広告を見る · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'レベル$levelで解放されます。';
  }

  @override
  String get collectionStorePricePending => 'ストア価格';

  @override
  String get collectionPreviewActionNotice => '購入と広告はこのあとの段階でつながります。';

  @override
  String get roomTitle => 'マイルーム';

  @override
  String get roomOpen => 'マイルームを開く';

  @override
  String get roomDecorate => '模様替え';

  @override
  String get roomDecorateTitle => '模様替え';

  @override
  String get roomDone => '完了';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => '庭のある家';

  @override
  String get roomThemeCasaDePlaya => '海辺の家';

  @override
  String get roomChooseTheme => 'お部屋の雰囲気を選んでください。';

  @override
  String get roomCatReaction => '今日もよくがんばりました！';

  @override
  String get roomInstruction => 'アイテムを選んで、置きたい場所をタップしてください。';

  @override
  String get roomCategoryRooms => 'お部屋';

  @override
  String get roomCategoryFurniture => '家具';

  @override
  String get roomCategoryWallFloor => '壁と床';

  @override
  String get roomCategoryProps => '小物';

  @override
  String get roomCategoryCharacters => 'キャラクター';

  @override
  String get roomCharacterInstruction => '一緒にいる仲間を選んでください。';

  @override
  String get roomMoreInCollection => 'コレクションでもっと見る';

  @override
  String get roomDefaultRug => 'ラベンダーのラグ';

  @override
  String get roomFloorLamp => '緑のランプ';

  @override
  String get roomTablePlant => '卓上の植物';

  @override
  String get roomWallFrame => '壁の絵';

  @override
  String get roomRattanChair => 'ラタンチェア';

  @override
  String get roomStandingLamp => 'フロアランプ';

  @override
  String get roomWallClock => '壁掛け時計';

  @override
  String get roomLowCabinet => 'ローキャビネット';

  @override
  String get roomPetBed => 'ペットベッド';

  @override
  String get roomSavingsJar => '貯金ビン';

  @override
  String get roomWallShelf => 'ウォールシェルフ';

  @override
  String get roomTerracottaPouf => 'テラコッタのスツール';

  @override
  String get roomBlueCreamRug => '青とクリームのラグ';

  @override
  String get roomLaunchSofa => 'ベルベットソファ';

  @override
  String get roomLaunchTv => 'おはなしテレビ';

  @override
  String get launchGiftTitle => 'リリース記念プレゼントが届きました！';

  @override
  String get launchGiftBody => '期間内にSobritaを始めたあなたに、ソファとテレビをプレゼントします。';

  @override
  String get launchGiftGoToRoom => '部屋に置く';

  @override
  String get launchGiftLater => 'あとで';

  @override
  String get roomSuggestCabinet => '左の壁ぎわに置きましょう。光っている場所をタップ。';

  @override
  String get roomSuggestPetBed => '仲間の左下に置きましょう。光っている場所をタップ。';

  @override
  String get roomSuggestSavingsJar => 'テーブルか床のすみがおすすめ。光っている場所をタップ。';

  @override
  String get roomSuggestWallShelf => '空いている壁に掛けましょう。光っている場所をタップ。';

  @override
  String get roomSuggestPouf => '右側でお部屋のバランスを。光っている場所をタップ。';

  @override
  String get roomSuggestBlueRug => '仲間の足元に敷きましょう。光っている場所をタップ。';

  @override
  String get roomSaved => 'お部屋を保存しました。';

  @override
  String get roomPlaced => '配置済み';

  @override
  String get roomSurfaceWall => '壁';

  @override
  String get roomSurfaceFloor => '床';

  @override
  String get roomSurfaceTabletop => 'テーブル';

  @override
  String get roomSurfaceRug => 'ラグ';

  @override
  String roomSlotLabel(String surface, int number) {
    return '$surfaceの$number番';
  }

  @override
  String roomPickWall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '壁に置ける場所が$countか所あります。置きたい場所をタップ。',
      one: '壁に置ける場所が1か所あります。タップして掛けましょう。',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '床に置ける場所が$countか所あります。置きたい場所をタップ。',
      one: '床に置ける場所が1か所あります。タップして置きましょう。',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'テーブルに置ける場所が$countか所あります。置きたい場所をタップ。',
      one: 'テーブルに置ける場所が1か所あります。タップして置きましょう。',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ラグを敷ける場所が$countか所あります。置きたい場所をタップ。',
      one: 'ラグを敷ける場所が1か所あります。タップして敷きましょう。',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '置ける場所が$countか所あります。置きたい場所をタップ。',
      one: '置ける場所が1か所あります。タップして置きましょう。',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove => '別の場所をタップすると移動、同じ場所をタップすると片づけます。';

  @override
  String get roomTapToRemove => 'もう一度同じ場所をタップすると片づけます。';

  @override
  String get xpHistoryTitle => 'これまでの成長';

  @override
  String xpTotal(int count) {
    return '合計$count XP';
  }

  @override
  String get xpMaxLevel => '最高レベル';

  @override
  String xpRemaining(int count) {
    return 'あと$count XP';
  }

  @override
  String get xpHistoryHint => 'XPは自動で加算されます。アプリを閉じても、理由と計算は1行ずつ残ります。';

  @override
  String get xpHistoryEmptyTitle => 'まだXPはありません';

  @override
  String get xpHistoryEmptyMessage => '週はじめての現金チェックとサイクルの締めがここに表示されます。';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => '計算を見る';

  @override
  String get xpCalculationTitle => '計算のしかた';

  @override
  String get xpDetailCycle => 'サイクル';

  @override
  String get xpDetailBudget => '予算';

  @override
  String get xpDetailSpent => '支出';

  @override
  String get xpDetailResult => '結果';

  @override
  String get xpDetailRule => 'ルール';

  @override
  String get xpDetailCredited => '加算XP';

  @override
  String get xpRuleCashCount => '週1回まで';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日分に換算した報酬',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日 × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => '1回かぎりの50 XPボーナス';

  @override
  String get recoveryNotYet => 'まだデータを復元できていません。';

  @override
  String get recoveryStartFreshQuestion => '最初からやり直しますか？';

  @override
  String get recoveryStartFreshBody => '新しいデータを作る前に、元のファイルのコピーを残します。';

  @override
  String get recoveryStartFresh => '最初からやり直す';

  @override
  String get recoveryTitle => 'データを読み込めませんでした';

  @override
  String get recoveryOriginalKept => '元のファイルはそのまま残っています。置き換えも削除もしていません。';

  @override
  String get recoveryOptions => 'もう一度試すか、バックアップを使うか、ファイルを書き出して保管できます。';

  @override
  String get recoveryRetrying => 'もう一度試しています…';

  @override
  String get recoveryRetry => 'もう一度試す';

  @override
  String get recoveryUseBackup => 'バックアップを使う';

  @override
  String get recoveryExport => 'ファイルを書き出す';

  @override
  String get recoveryExported => '元のファイルをコピーしました。';

  @override
  String get settingsTitle => 'マイSobrita';

  @override
  String get settingsLanguage => '言語';

  @override
  String currencyChangeTitle(String code) {
    return '$codeに切り替えますか？';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return '金額は換算されません。$exampleは$convertedのままで、表示の単位だけが変わります。';
  }

  @override
  String get currencyChangeConfirm => '単位を変える';

  @override
  String get currencyRegionAmericas => '南北アメリカ';

  @override
  String get currencyRegionEurope => 'ヨーロッパ';

  @override
  String get currencyRegionAsiaPacific => 'アジア・オセアニア';

  @override
  String get settingsCurrency => '通貨';

  @override
  String get settingsBudgetCycle => 'サイクル';

  @override
  String get settingsCountDay => 'チェックの日';

  @override
  String get settingsReduceMotionHint => 'スマホ側で設定されていれば自動でオンになります。';

  @override
  String get settingsQuickEntry => 'クイック記録';

  @override
  String get settingsQuickEntryHint => 'ロック画面に収入と支出を表示します。';

  @override
  String get quickEntryQuestion => '何を記録しますか？';

  @override
  String get quickEntryDenied => 'クイック記録を使うには、Sobritaの通知を許可してください。';

  @override
  String get widgetTodayLeft => '今日の残り';

  @override
  String get widgetCycleBalance => '残高';

  @override
  String get widgetOpenApp => 'Sobritaを開く';

  @override
  String get widgetRegisterExpense => '支出を記録';

  @override
  String get settingsBackup => 'データのバックアップ';

  @override
  String get settingsCopy => 'コピー';

  @override
  String get settingsBackupCopied => 'バックアップをクリップボードにコピーしました。';

  @override
  String get settingsRestorePurchases => '購入を復元';

  @override
  String get settingsAccount => 'Googleアカウント';

  @override
  String get settingsAccountConnect => '連携する';

  @override
  String get settingsRestore => '復元';

  @override
  String get purchaseRestored => '完了しました。購入が元に戻りました。';

  @override
  String get purchaseFailureStoreUnavailable => 'ストアに接続できません。しばらくしてからお試しください。';

  @override
  String get purchaseFailureRejected => '購入を完了できませんでした。料金はかかっていません。';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      '購入は届きましたが、保存できませんでした。次にSobritaを開いたときに反映されます。';

  @override
  String get purchaseFailureNothingToRestore => 'このアカウントには購入が見つかりませんでした。';

  @override
  String get collectionPurchasing => '購入中…';

  @override
  String get settingsXpPreview => 'XPプレビュー';

  @override
  String get settingsDesign => 'デザイン';

  @override
  String get settingsStorageNote => 'データはこの端末に保存されます。アカウントがなくてもSobritaを使えます。';

  @override
  String get settingsSectionShop => 'ショップ';

  @override
  String get settingsRemoveAds => '通常の広告をなくす';

  @override
  String get settingsRemoveAdsHint => '履歴の広告がなくなります。リワード広告はそのまま使えます。';

  @override
  String get settingsPackName => 'Michiと仲間たち';

  @override
  String get settingsPackHint => 'キャラクター3体 + Michiの星。通常の広告もなくなります。';

  @override
  String get settingsOwned => '購入済み';

  @override
  String get settingsShopRestoreNote => '購入はストアのアカウントに残ります。再インストール後も復元できます。';

  @override
  String get settlementTitle => '今回のサイクルの締め';

  @override
  String get settlementSpent => '使った額';

  @override
  String get settlementLeft => '残った額';

  @override
  String get settlementOver => 'オーバー';

  @override
  String get settlementAverage => '1日平均';

  @override
  String get settlementContinue => '完了';

  @override
  String get settlementCtaTitle => '特別な飾りをもらいに行こう';

  @override
  String get settlementCtaAction => 'コレクションを見る';

  @override
  String get settingsSectionBudget => '予算';

  @override
  String get settingsSectionScreen => '表示';

  @override
  String get settingsSectionData => 'データ';

  @override
  String get settingsSectionPrivacy => 'プライバシー';

  @override
  String get settingsAdPrivacy => '広告のプライバシー';

  @override
  String get settingsAdPrivacyValue => '管理';

  @override
  String get settingsAdPrivacyFailed => 'プライバシー設定を開けませんでした。もう一度お試しください。';

  @override
  String get settingsSectionDesign => 'デザイン';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '記録$movements件',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Sobritaと$days日目',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => '自動';

  @override
  String get languageAutomaticHint => 'スマホの設定に合わせる';

  @override
  String get transactionsTitle => '履歴';

  @override
  String get dailySpendTitle => '日ごとの支出';

  @override
  String dailySpendLimit(String amount) {
    return '1日$amount';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return '今のサイクル $amount';
  }

  @override
  String get dailyIncomeTitle => '日ごとの収入';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return '今のサイクル $amount';
  }

  @override
  String get transactionsEmptyTitle => 'まだ記録がありません';

  @override
  String get transactionsEmptyMessage => '最初の支出を記録すると、サイクルのまとめがここに出ます。';

  @override
  String get transactionsEmptyExpensesTitle => 'まだ支出がありません';

  @override
  String get transactionsEmptyExpensesMessage => '支出を記録すると、日ごとの流れがここに出ます。';

  @override
  String get transactionsEmptyIncomesTitle => 'まだ収入がありません';

  @override
  String get transactionsEmptyIncomesMessage => '収入を記録すると、日ごとの流れがここに出ます。';

  @override
  String get transactionsExpensePinned =>
      'この支出は現金チェックから作られました。直すにはもう一度数えてください。';

  @override
  String get transactionsIncomePinned => 'この収入は現金チェックから作られました。直すにはもう一度数えてください。';

  @override
  String get transactionsExpenseDeleted => '支出を削除しました。';

  @override
  String get transactionsIncomeDeleted => '収入を削除しました。';

  @override
  String get undo => '元に戻す';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get identifyDifference => '差額を確認';

  @override
  String get editMovement => '記録を編集';

  @override
  String get amount => '金額';

  @override
  String get editPendingHint => '金額は現金チェックから来ています。カテゴリーとメモは変更できます。';

  @override
  String get category => 'カテゴリー';

  @override
  String get note => 'メモ';

  @override
  String get noteExample => '例：ラーメン';

  @override
  String get replacesPendingHint => '未確認の調整と置き換わります。支出は増えません。';

  @override
  String get saveWithoutDuplicating => '重複させずに保存';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get save => '保存';

  @override
  String get budget => '予算';

  @override
  String get spent => '支出';

  @override
  String get appName => 'Sobrita';

  @override
  String get homeCycleBalance => 'サイクルの残高';

  @override
  String get homeTodayLeft => '今日使えるお金';

  @override
  String homeOverBudget(String budget) {
    return 'このサイクルの予算$budgetをオーバーしました';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return '今日の上限$limit · サイクル残り$remaining';
  }

  @override
  String get homeFirstQuestLabel => '最初のクエスト';

  @override
  String get homeBudgetQuestBody => '予算を決めると、1日に使える額を計算します。';

  @override
  String get homeCycleProgress => 'サイクルの進み具合';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => '手元の現金（推定）';

  @override
  String get homeCashUnset => '現金は未設定';

  @override
  String homeLastCount(String amount) {
    return '前回のチェック：$amount';
  }

  @override
  String get homeFirstCountHint => 'まずは現金を数えてみましょう。';

  @override
  String get homeRecentMovements => '最近の記録';

  @override
  String get homeSeeAll => 'すべて見る';

  @override
  String get homeGoingWell => 'いい調子';

  @override
  String get homeAdjustCalmly => '落ち着いて調整しよう';

  @override
  String get budgetTitle => '予算';

  @override
  String get budgetCycleTotal => 'サイクルの合計';

  @override
  String get budgetTotal => '予算の合計';

  @override
  String get budgetNotSetTitle => 'まだ予算がありません';

  @override
  String get budgetNotSetBody => '予算を決めると、1日に使える額を計算します。';

  @override
  String get budgetSetAction => '予算を決める';

  @override
  String budgetTooLow(String allocated) {
    return '合計は、このサイクルにすでに割り当てた収入（$allocated）より多くしてください。';
  }

  @override
  String budgetSpentShare(int percent) {
    return '予算の$percent%';
  }

  @override
  String budgetRingSpent(String amount) {
    return '支出 $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return '残り $amount';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent%';
  }

  @override
  String get cycleHistoryTitle => 'これまでのサイクル';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total回中$green回が黒字',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return '予算 $budget · 支出 $spent';
  }

  @override
  String get cycleHistoryEmpty => 'まだ締めたサイクルはありません。';

  @override
  String cycleHistoryAverage(String amount) {
    return '1日平均 $amount';
  }

  @override
  String get cycleHistoryAveragePending => '1日平均 · 集計中';

  @override
  String get budgetChangedTitle => '予算を変更しました';

  @override
  String get budgetChangedBody =>
      'カテゴリーごとの上限はどうしますか？比例で調整すると、どれも同じ割合で変わるので、配分はそのままです。';

  @override
  String get budgetKeepLimits => 'そのままにする';

  @override
  String get budgetScaleLimits => '比例で調整する';

  @override
  String get budgetByCategory => 'カテゴリー別の予算';

  @override
  String budgetCategoryLimit(String category) {
    return '$categoryの上限';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => '締めの見込み';

  @override
  String get budgetEstimatedLeft => '残りそうな額';

  @override
  String get continueLabel => '続ける';

  @override
  String get saving => '保存中…';

  @override
  String dayOfMonth(int day) {
    return '$day日';
  }

  @override
  String get weekdayMonday => '月曜日';

  @override
  String get weekdayTuesday => '火曜日';

  @override
  String get weekdayWednesday => '水曜日';

  @override
  String get weekdayThursday => '木曜日';

  @override
  String get weekdayFriday => '金曜日';

  @override
  String get weekdaySaturday => '土曜日';

  @override
  String get weekdaySunday => '日曜日';

  @override
  String get weekdayShortMonday => '月';

  @override
  String get weekdayShortTuesday => '火';

  @override
  String get weekdayShortWednesday => '水';

  @override
  String get weekdayShortThursday => '木';

  @override
  String get weekdayShortFriday => '金';

  @override
  String get weekdayShortSaturday => '土';

  @override
  String get weekdayShortSunday => '日';

  @override
  String get registerTitle => '記録';

  @override
  String get registerExpense => '支出';

  @override
  String get registerIncome => '収入';

  @override
  String get registerAmountAboveZero => '0より大きい金額を入力してください。';

  @override
  String get registerNoFutureMovements => '未来の日付では記録できません。';

  @override
  String get registerDate => '日付';

  @override
  String get registerNoteExpenseExample => '例：駅前のパン屋';

  @override
  String get registerNoteIncomeExample => '例：金曜のチップ';

  @override
  String get receiptTitle => 'レシート';

  @override
  String get receiptAdd => 'レシートを追加';

  @override
  String get receiptCamera => 'カメラ';

  @override
  String get receiptGallery => 'ギャラリー';

  @override
  String get receiptChange => '差し替え';

  @override
  String get receiptRemove => '外す';

  @override
  String get receiptHint => '何に使ったか思い出せるように写真を残しましょう。';

  @override
  String get receiptAttached => 'レシート添付済み';

  @override
  String get receiptView => 'レシートを見る';

  @override
  String get receiptClose => '閉じる';

  @override
  String get receiptMissing => '写真はもうこの端末にありません。';

  @override
  String get receiptFailed => '写真を保存できませんでした。';

  @override
  String get receiptBackupNote => 'バックアップにレシートの写真は含まれません。';

  @override
  String get registerPayment => '支払い方法';

  @override
  String get registerPaymentHint => '現金は手元の現金から引かれます。カードは引かれません。';

  @override
  String get registerIncomeKind => '収入の種類';

  @override
  String get registerWhatToDo => 'どうしますか？';

  @override
  String get registerThisCycle => '今のサイクル';

  @override
  String get registerSaveIt => '貯金する';

  @override
  String get registerReceivedIn => '受け取り方法';

  @override
  String get registerAccount => '口座';

  @override
  String get registerReconcileQuestion => 'この支出で差額の説明がつきますか？';

  @override
  String registerReconcileBody(String amount) {
    return '前回のチェックで$amountの差額が残っています。同じ支出なら、二重に数えずにひも付けます。';
  }

  @override
  String get registerReconcileNo => 'いいえ、別の支出';

  @override
  String get registerReconcileYes => 'はい、ひも付ける';

  @override
  String get registerDifferenceReconciled => '差額を解消しました';

  @override
  String get registerExpenseSaved => '支出を保存しました';

  @override
  String get registerIncomeSaved => '収入を保存しました';

  @override
  String get cashCountTitle => '現金チェック';

  @override
  String get cashCountPickWhatHappened => '差額の理由を選んでください。';

  @override
  String get cashCountSavedWithoutDuplicates => '重複なしで保存しました。';

  @override
  String get cashCountPrompt => '今手元にある現金だけを数えてください。';

  @override
  String get cashCountNoneYet => 'まだチェックしていません';

  @override
  String get cashCountResultPending => '数えた額を入力すると結果が出ます。';

  @override
  String get cashCountBaselineHint => 'ここがスタート地点になります。収入としては記録されません。';

  @override
  String get cashCountExpected => '予想';

  @override
  String get cashCountCounted => '実際';

  @override
  String get cashCountBalanced => 'ぴったり合っています';

  @override
  String cashCountShort(String amount) {
    return '$amount足りません';
  }

  @override
  String cashCountExtra(String amount) {
    return '$amount多いです';
  }

  @override
  String get cashCountWhatHappened => '何がありましたか？';

  @override
  String get cashCountHelperExpense => '記録していない支出でした。';

  @override
  String get cashCountHelperIncome => '新しく受け取ったお金でした。';

  @override
  String get cashCountHelperTransferOut => '預けたか、別の口座に移しました。';

  @override
  String get cashCountHelperTransferIn => '引き出したか、別の口座から移しました。';

  @override
  String get cashCountHelperCorrection => '前回の数え間違いでした。';

  @override
  String get cashCountHelperPending => 'あとで決める。';

  @override
  String get cashCountSingleExpenseHint => '支出が1件作られます。もう一度記録する必要はありません。';

  @override
  String get cashCountNoteTipExample => '例：チップ';

  @override
  String get cashCountWhatToDoWithMoney => 'このお金をどうしますか？';

  @override
  String get cashCountSaveFirst => '最初のチェックを保存';

  @override
  String get cashCountSave => 'チェックを保存';

  @override
  String get cycleTitle => 'サイクル';

  @override
  String get cycleCurrent => '今のサイクル';

  @override
  String get cycleInProgress => '進行中';

  @override
  String get cycleUnchanged => '変わりません';

  @override
  String get cycleNewFrequency => '新しい周期';

  @override
  String get cycleFirstPay => '最初の給料日';

  @override
  String get cyclePayDay => '給料日';

  @override
  String get cycleNext => '次のサイクル';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return '変更は次のサイクルから適用され、その後は$days日ごとにくり返します。';
  }

  @override
  String get cycleChangeApplies => '変更は次のサイクルから適用されます。';

  @override
  String get cycleSaveChange => '変更を保存';

  @override
  String get onboardingBudgetAboveZero => '0より大きい予算を入力してください。';

  @override
  String get onboardingCashOrSkip => '現金の額を入力するか、「あとで」を選んでください。';

  @override
  String get prologueRainNoEnd => '雨はやみそうになかった。';

  @override
  String get prologueRentPaid => '家賃は払ってある。口座に残ったお金で、次の給料日までやりくりしなければならない。';

  @override
  String get prologueSoundAtDoor => 'ドアのそばで何かが動いた。';

  @override
  String get prologueGoLook => '見に行く';

  @override
  String get prologueWetTracks => '濡れた足あとが二列、床を横切っていた。';

  @override
  String get prologueShelter => '雨がやむまで、いさせてください。';

  @override
  String get prologueItSpoke => '……しゃべった。';

  @override
  String get prologueReplySurprised => '今、しゃべった？';

  @override
  String get prologueReplyTowel => '（だまってタオルを持ってくる）';

  @override
  String get prologueEarnKeep => 'お世話になるからには、何かしないと。数字はまかせてください。';

  @override
  String get prologueAskSchedule => 'まずは、お金はいつ入ってきますか？';

  @override
  String get prologueAskPayday => '給料日はいつですか？最初の日だけ教えてくれれば、あとは数えます。';

  @override
  String prologueAskBudget(int days) {
    return '次の給料日まであと$days日。いくら使うつもりですか？';
  }

  @override
  String get prologueSkipIsFine => '飛ばしても大丈夫。家に着いたらまた聞きますね。';

  @override
  String get prologueSkip => '飛ばす';

  @override
  String get prologueDriedOff => '体をふいて、ふたりとも落ち着いた。外はまだ雨だった。';

  @override
  String get prologueWhoSits => 'だれがそばにいる？';

  @override
  String get prologueMichiTrait => '物静か。\n数字に強い。';

  @override
  String get prologuePoodleTrait => '元気いっぱい。\n面倒見がいい。';

  @override
  String get prologueSchnauzerTrait => '思慮深い。\n見守り役。';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => '元気いっぱい。\n面倒見がいい。';

  @override
  String get prologueLockedSoon => 'イラスト準備中';

  @override
  String get prologueOtherStays => 'もう一匹も一緒に暮らします。仲間はあとから変えられます。';

  @override
  String get prologueLiveTogether => '一緒に暮らす';

  @override
  String prologueGreeting(String name) {
    return '$nameといいます。ドアを開けてくれてありがとう。';
  }

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get onboardingTagline => 'お金のこと、気楽に。';

  @override
  String get onboardingPromise => '今日いくら使えるか、お知らせします。';

  @override
  String get onboardingHowPaid => 'お金はどう入ってきますか？';

  @override
  String get onboardingHowPaidHint => '予算の日付がこれで決まります。';

  @override
  String get onboardingCycleHelperSemiMonthly => '月に2回：15日と月末。';

  @override
  String get onboardingCycleHelperMonthly => '月に1回。';

  @override
  String get onboardingCycleHelperWeekly => '毎週。';

  @override
  String get onboardingCycleHelperIrregular => '収入の日が決まっていない。';

  @override
  String get onboardingPlanWithoutFixedDate => '日付を決めずに計画する';

  @override
  String get onboardingWhichDayPaid => 'お金が入るのは何日ですか？';

  @override
  String get onboardingSecondPayEndOfMonth => '2回目 · 月末';

  @override
  String get onboardingHowManyDays => '何日分の計画にしますか？';

  @override
  String get onboardingCyclePreview => 'サイクルはこうなります';

  @override
  String onboardingRepeatsEvery(int days) {
    return '終わったら、次の$days日間が自動で始まります。';
  }

  @override
  String get onboardingShortMonthsNote => '日数の少ない月は日付が自動で調整されます。';

  @override
  String get onboardingBudgetQuestion => 'このサイクルで\nいくら使いますか？';

  @override
  String get onboardingBudgetLater => 'あとでホームから決められます。';

  @override
  String get onboardingNotNow => 'あとで';

  @override
  String get onboardingCashQuestion => '今日、手元に現金は\nいくらありますか？';

  @override
  String get onboardingCashOptional => 'あとで数えるなら空欄のままで大丈夫です。';

  @override
  String get onboardingCashIsBaseline => '収入ではなく、最初の現金チェックになります。';

  @override
  String onboardingSettledIn(String name) {
    return '雨がやんだ。$nameはあなたのとなりに落ち着いた。';
  }

  @override
  String get onboardingFirstQuests => '最初のクエスト';

  @override
  String get onboardingWaitingAtHome => '家で待っています';

  @override
  String get onboardingGoHome => 'ホームへ';

  @override
  String get onboardingPlanReady => '計画ができました';

  @override
  String get onboardingCanSpendToday => '今日使えるお金';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String progressPercent(int percent) {
    return '進み具合 $percentパーセント';
  }

  @override
  String stepOf(int step, int total) {
    return 'ステップ$step / $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly => '2週間を黒字で終えました';

  @override
  String get onboardingCycleHelperBiweekly => '前回の給料日から2週間ごと。';

  @override
  String get cycleLastPayday => '前回の給料日';

  @override
  String get onboardingWhenLastPaid => '前回の給料日はいつでしたか？';

  @override
  String get onboardingBiweeklyNeedsDate => '前回の給料日を選んでください。';

  @override
  String get pickDate => '日付を選ぶ';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }

  @override
  String get settingsSectionAbout => 'このアプリについて';

  @override
  String get settingsReleaseNotes => '新機能';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => '新機能';

  @override
  String get releaseNotesCurrent => '現在';

  @override
  String releaseNotesRetention(int count) {
    return '直近$countバージョン分を残しています。';
  }

  @override
  String get releaseNote104Fixed =>
      '固定費を毎日の予算と分けて管理できるようになりました。ホームに表示され、支払い日の前にお知らせもできます。';

  @override
  String get releaseNote104Decor =>
      'お部屋に置けるものが増えました。ペットベッド、棚、ラグ、キャビネット、ビン、スツール。';

  @override
  String get releaseNote104Names =>
      'Miru、Yoshi、Cookieに名前がつき、レベルの称号にそばにいる仲間の名前が入るようになりました。';

  @override
  String get releaseNote104Widget => 'ホームウィジェットに金額がすべて表示されるようになりました。';

  @override
  String get releaseNote104Languages => 'Sobritaがポルトガル語、ドイツ語、フランス語、日本語に対応しました。';

  @override
  String get releaseNote103GuineaPig => 'モルモットがコレクションに登場。短い広告2本で仲間になります。';

  @override
  String get releaseNote103Widget =>
      'ホームウィジェットに一緒に暮らす仲間が表示され、金額もアプリと同じ書き方になりました。';

  @override
  String get releaseNote102Schnauzer => 'シュナウザーがコレクションに登場。短い広告2本で仲間になります。';

  @override
  String get releaseNote102Rooms => 'お部屋を庭や海辺にできるようになり、チェア、ランプ、時計も置けるようになりました。';

  @override
  String get releaseNote102Missions =>
      '毎日のミッション3つのうち2つが日替わりに。ひと手間かかるものはXPが多めです。';

  @override
  String get releaseNote102Amounts =>
      'コロンビア・アルゼンチン・チリのペソ、レアル、ユーロの金額が1.234,56のようにコンマ区切りになりました。';

  @override
  String get releaseNote101Currencies =>
      'コロンビア・アルゼンチン・チリのペソ、ソル、ポンド、円で金額を表示できるようになりました。';

  @override
  String get releaseNote101Celebration =>
      'お祝いの演出がカードいっぱいに広がり、ジャンプも最後まで見られるようになりました。';

  @override
  String get releaseNote100Launch => 'Sobritaの最初のバージョンです。';

  @override
  String get updateAvailableTitle => '新しいバージョンがあります';

  @override
  String get updateAvailableBody => 'アップデートして最新のSobritaを使いましょう。';

  @override
  String updateCurrentVersion(String version) {
    return '今のバージョン：v$version';
  }

  @override
  String get updateAction => 'アップデート';

  @override
  String get updateLater => 'あとで';

  @override
  String get updateBannerMessage => '新しいバージョンがあります';

  @override
  String get updateBannerDismiss => 'お知らせを閉じる';

  @override
  String get updateStoreFailed => 'Google Playを開けませんでした。';

  @override
  String get settingsCheckUpdate => 'アップデートを確認';

  @override
  String get settingsCheckUpdateBusy => '確認中…';

  @override
  String get settingsCheckUpdateUpToDate => '最新のバージョンです。';

  @override
  String get settingsRateApp => 'Sobritaを評価する';

  @override
  String get settingsOurApps => 'おすすめアプリ';

  @override
  String get ourAppsIntro => 'Sobritaチームが作ったアプリです。';

  @override
  String get ourAppsOpen => 'Google Playで見る';

  @override
  String get ourAppsLoopetKind => 'ルーティン';

  @override
  String get ourAppsLoopetBlurb => '1日24時間をひとつの円に。今やることと次にやることがひと目でわかります。';

  @override
  String get ourAppsRandomFocusKind => '集中';

  @override
  String get ourAppsRandomFocusBlurb => 'ルーレットを回して集中する時間を決めるタイマー。迷わずすぐ始められます。';

  @override
  String get releaseAnnouncementViewAll => 'すべて見る';

  @override
  String get releaseAnnouncementDone => 'OK';

  @override
  String get settingsReleaseNotesUnread => '未読の新機能';

  @override
  String get fixedSectionTitle => '固定費';

  @override
  String fixedSectionMonth(String month) {
    return '$month · 毎日の予算とは別';
  }

  @override
  String fixedPaidOfTotal(String paid, String total) {
    return '$total中$paid支払い済み';
  }

  @override
  String get fixedAdd => '固定費を追加';

  @override
  String get fixedEmptyBody => '家賃、スマホ代、電気代。一度登録すれば、支払い日にお知らせします。毎日の予算は変わりません。';

  @override
  String get fixedFrequencyWeekly => '毎週';

  @override
  String get fixedFrequencySemiMonthly => '月2回';

  @override
  String get fixedFrequencyMonthly => '毎月';

  @override
  String get fixedFrequencyBimonthly => '2か月ごと';

  @override
  String get fixedStatusPaid => '支払い済み';

  @override
  String get fixedStatusTomorrow => '明日';

  @override
  String get fixedStatusOverdue => '期限切れ';

  @override
  String fixedApprox(String amount) {
    return '約$amount';
  }

  @override
  String get fixedFormNewTitle => '新しい固定費';

  @override
  String get fixedFormEditTitle => '固定費を編集';

  @override
  String get fixedName => '名前';

  @override
  String get fixedNameHint => '家賃、スマホ代、電気代…';

  @override
  String get fixedNameRequired => '名前を入れてください';

  @override
  String get fixedHowOften => 'どのくらいの頻度？';

  @override
  String get fixedNextDue => '次の支払い';

  @override
  String fixedThenDates(String dates) {
    return 'その後：$dates…';
  }

  @override
  String get fixedVariable => '毎回金額が変わる';

  @override
  String get fixedVariableHint => '前回払った額を目安にします。';

  @override
  String get fixedFormNote => '毎日の予算は変わりません。予算は固定費を払ったあとに残るお金です。';

  @override
  String get fixedSave => '固定費を保存';

  @override
  String get fixedDelete => '固定費を削除';

  @override
  String fixedDeleteTitle(String name) {
    return '$nameを削除しますか？';
  }

  @override
  String get fixedDeleteBody => '記録済みの支払いは履歴に残ります。';

  @override
  String get fixedDueToday => '今日が支払い日';

  @override
  String get fixedDueTomorrow => '明日が支払い日';

  @override
  String fixedDueOn(String date) {
    return '支払い日：$date';
  }

  @override
  String fixedWasDue(String date) {
    return '支払い日は$dateでした';
  }

  @override
  String get fixedHowMuch => 'いくら払いましたか？';

  @override
  String fixedLastTime(String amount) {
    return '前回：$amount';
  }

  @override
  String fixedTodayUnchanged(String amount) {
    return '今日使えるお金は$amountのままです。';
  }

  @override
  String fixedCashChange(String from, String to) {
    return '手元の現金（推定）：$fromから$toに';
  }

  @override
  String fixedPaidWith(String method) {
    return '$methodで支払い';
  }

  @override
  String get fixedChange => '変更';

  @override
  String get fixedMarkPaid => '払いました';

  @override
  String get fixedNotYet => 'まだ';

  @override
  String get fixedBillOnly => '請求書が届いただけ';

  @override
  String fixedBillSaved(String amount) {
    return '了解です。$amountの予定にしておきます。';
  }

  @override
  String fixedPaymentSaved(String name) {
    return '$nameを記録しました。';
  }

  @override
  String get fixedHomeLabel => '固定費';

  @override
  String fixedHomeMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '確認が必要な固定費が$count件',
    );
    return '$_temp0';
  }

  @override
  String get fixedHomeSee => '見る';

  @override
  String get fixedIntroTitle => '予算は、固定費を除いた使えるお金です';

  @override
  String fixedIntroBody(String budget, String name) {
    return '固定費を足しても毎日の予算は減りません。$budgetに「$name」が含まれていたなら、予算を下げましょう。';
  }

  @override
  String get fixedIntroKeep => 'このままでいい';

  @override
  String get fixedIntroAdjust => '予算を調整';

  @override
  String get fixedBadge => '固定';

  @override
  String get fixedNothingThisMonth => '今月の支払いはありません。';

  @override
  String get fixedReminderLabel => 'リマインダー';

  @override
  String get fixedReminderNone => '通知しない';

  @override
  String get fixedReminderSameDay => '当日';

  @override
  String get fixedReminderDayBefore => '1日前';

  @override
  String get fixedReminderThreeDaysBefore => '3日前';

  @override
  String get fixedReminderHint => '朝9:00にお知らせします。';

  @override
  String get fixedReminderBlocked => 'Sobritaの通知がオフなので、お知らせできません。';

  @override
  String fixedReminderTitleToday(String name) {
    return '今日は$nameの支払い日です';
  }

  @override
  String fixedReminderTitleTomorrow(String name) {
    return '明日は$nameの支払い日です';
  }

  @override
  String fixedReminderTitleInDays(String name, int days) {
    return '$nameの支払いまであと$days日';
  }

  @override
  String fixedReminderBody(String amount, String method) {
    return '$amount · $method。払ったらSobritaで記録しましょう。';
  }
}
