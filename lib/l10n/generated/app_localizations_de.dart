// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get categoryFood => 'Essen';

  @override
  String get categoryTransport => 'Verkehr';

  @override
  String get categoryShopping => 'Einkäufe';

  @override
  String get categoryHome => 'Zuhause';

  @override
  String get categoryServices => 'Rechnungen';

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryEducation => 'Bildung';

  @override
  String get categoryEntertainment => 'Freizeit';

  @override
  String get categoryPets => 'Haustiere';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get incomeKindSalary => 'Mein normales Gehalt';

  @override
  String get incomeKindExtra => 'Extra-Einnahme';

  @override
  String get incomeKindCash => 'Bareinnahme';

  @override
  String get incomeKindRefund => 'Erstattung';

  @override
  String get incomeAllocationCycle => 'Dieser Zyklus';

  @override
  String get incomeAllocationSavings => 'Sparen';

  @override
  String get payCycleSemiMonthly => 'Zweimal im Monat';

  @override
  String get payCycleBiweekly => 'Alle 14 Tage';

  @override
  String get payCycleMonthly => 'Monatlich';

  @override
  String get payCycleWeekly => 'Wöchentlich';

  @override
  String get payCycleIrregular => 'Kein festes Datum';

  @override
  String get cashResolutionExpense => 'Ausgabe gefunden';

  @override
  String get cashResolutionIncome => 'Bareinnahme';

  @override
  String get cashResolutionTransfer => 'Zwischen Konten verschoben';

  @override
  String get cashResolutionCorrection => 'Zählkorrektur';

  @override
  String get cashResolutionPending => 'Differenz offen';

  @override
  String get paymentMethodCash => 'Bar';

  @override
  String get paymentMethodCard => 'Karte';

  @override
  String get movementPending => 'Offen';

  @override
  String get movementCashCount => 'Kassensturz';

  @override
  String get xpCashCountTitle => 'Kassensturz';

  @override
  String get xpCashCountDetail => 'Erster Kassensturz mit XP diese Woche';

  @override
  String get xpCycleInGreenSemiMonthly =>
      'Du hast den halben Monat im Plus abgeschlossen';

  @override
  String get xpCycleInGreenMonthly => 'Du hast den Monat im Plus abgeschlossen';

  @override
  String get xpCycleInGreenWeekly => 'Du hast die Woche im Plus abgeschlossen';

  @override
  String get xpCycleInGreenGeneric =>
      'Du hast den Zyklus im Plus abgeschlossen';

  @override
  String get xpCycleInGreenDetail => 'So stand das Budget am Ende';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage unter deinem Limit',
      one: '$count Tag unter deinem Limit',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail => 'Einmal berechnet, beim Abschluss';

  @override
  String get xpFirstSuccessfulCycleTitle => 'Erster Zyklus im Plus';

  @override
  String get xpFirstSuccessfulCycleDetail => 'Einmaliger Bonus';

  @override
  String xpLevelTitle1(String name) {
    return 'Entdecker $name';
  }

  @override
  String xpLevelTitle2(String name) {
    return 'Sparfuchs $name';
  }

  @override
  String xpLevelTitle3(String name) {
    return 'Rechenprofi $name';
  }

  @override
  String xpLevelTitle4(String name) {
    return 'Hüter $name';
  }

  @override
  String xpLevelTitle5(String name) {
    return 'Meister $name';
  }

  @override
  String xpLevelTitle6(String name) {
    return 'Experte $name';
  }

  @override
  String xpLevelTitle7(String name) {
    return 'Stratege $name';
  }

  @override
  String xpLevelTitle8(String name) {
    return 'Schatzmeister $name';
  }

  @override
  String xpLevelTitle9(String name) {
    return 'Weiser $name';
  }

  @override
  String xpLevelTitle10(String name) {
    return 'Legende $name';
  }

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zyklen abgeschlossen',
      one: 'Zyklus abgeschlossen',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP automatisch gutgeschrieben.';

  @override
  String get xpNoticeCashCountTitle => 'Kassensturz gespeichert';

  @override
  String get xpNoticeCashCountDetail =>
      'Erster Kassensturz mit XP diese Woche.';

  @override
  String xpLevelUpTitle(int level) {
    return 'LEVEL $level!';
  }

  @override
  String get xpLevelUpContinue => 'Weiter';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Objekte freigeschaltet!',
      one: 'Neues Objekt freigeschaltet!',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => 'Heutige Mission';

  @override
  String get dailyMissionResetHint =>
      'Sie wechseln um Mitternacht. Sie sammeln sich nicht an.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String get dailyMissionAllDone => 'Alles erledigt';

  @override
  String get dailyMissionRecordTitle => 'Trag heute etwas ein';

  @override
  String get dailyMissionRecordHint => 'Eine Ausgabe oder eine Einnahme';

  @override
  String get dailyMissionSameDayTitle => 'Am selben Tag eintragen';

  @override
  String get dailyMissionSameDayHint => 'Ausgabe und Eintrag, beide heute';

  @override
  String get dailyMissionBudgetTitle => 'Schau dein Budget an';

  @override
  String get dailyMissionBudgetHint => 'Öffne den Tab Budget';

  @override
  String get dailyMissionNoteTitle => 'Füg eine Notiz hinzu';

  @override
  String get dailyMissionNoteHint => 'Ein Eintrag mit Notiz';

  @override
  String get dailyMissionReceiptTitle => 'Heb einen Beleg auf';

  @override
  String get dailyMissionReceiptHint => 'Häng das Foto an eine Ausgabe';

  @override
  String get dailyMissionThreeTodayTitle => 'Heute drei eintragen';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '$count Einträge mit heutigem Datum';
  }

  @override
  String get dailyMissionDone => 'Erledigt';

  @override
  String get dailyMissionPending => 'Offen';

  @override
  String dailyMissionReadyAt(String time) {
    return 'Erledigt · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done von $total erledigt · +$earned XP von +$possible XP heute';
  }

  @override
  String get dailyMissionXpDetail => 'Mission erledigt';

  @override
  String get xpRuleDailyMission =>
      'Einmal am Tag; um Mitternacht geht es von vorn los';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Missionen erledigt',
      one: 'Mission erledigt',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => 'XP für die Gewohnheit von heute.';

  @override
  String get storeFailureGeneric =>
      'Die Änderung konnte nicht gespeichert werden. Versuch es noch einmal.';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      'Der Betrag muss höher sein als die Einnahmen, die diesem Zyklus schon zugeteilt sind.';

  @override
  String get storeFailureFutureMovement =>
      'Du kannst nichts mit einem Datum in der Zukunft eintragen.';

  @override
  String get storeFailureRestoreFailed =>
      'Die Sicherung konnte nicht wiederhergestellt werden.';

  @override
  String get storeFailureOriginalNotKept =>
      'Die Originaldatei konnte nicht behalten werden.';

  @override
  String get storeFailureBackupNotSaved =>
      'Die Sicherung konnte nicht gespeichert werden.';

  @override
  String get storeFailureSaveFailed =>
      'Deine Daten konnten nicht gespeichert werden.';

  @override
  String get monthAbbr1 => 'Jan';

  @override
  String get monthAbbr2 => 'Feb';

  @override
  String get monthAbbr3 => 'Mär';

  @override
  String get monthAbbr4 => 'Apr';

  @override
  String get monthAbbr5 => 'Mai';

  @override
  String get monthAbbr6 => 'Jun';

  @override
  String get monthAbbr7 => 'Jul';

  @override
  String get monthAbbr8 => 'Aug';

  @override
  String get monthAbbr9 => 'Sep';

  @override
  String get monthAbbr10 => 'Okt';

  @override
  String get monthAbbr11 => 'Nov';

  @override
  String get monthAbbr12 => 'Dez';

  @override
  String dateShort(String day, String month) {
    return '$day. $month';
  }

  @override
  String dateFull(String day, String month, String year) {
    return '$day. $month $year';
  }

  @override
  String get back => 'Zurück';

  @override
  String get reduceMotion => 'Bewegung reduzieren';

  @override
  String get catMotionIdle => 'Die Katze ruht sich aus';

  @override
  String get catMotionWalk => 'Die Katze läuft';

  @override
  String get catMotionCalculate => 'Die Katze rechnet';

  @override
  String get catMotionSaving => 'Die Katze wirft Münzen ins Sparschwein';

  @override
  String get catMotionCelebrate => 'Die Katze feiert';

  @override
  String get catMotionConcern => 'Die Katze sorgt sich ums Budget';

  @override
  String get characterRoleIdle => 'Die Figur ruht sich aus';

  @override
  String get characterRoleActivity => 'Die Figur bewegt sich';

  @override
  String get characterRoleProcessing => 'Die Figur rechnet';

  @override
  String get characterRolePositive => 'Die Figur zeigt eine gute Veränderung';

  @override
  String get characterRoleSuccess => 'Die Figur feiert';

  @override
  String get characterRoleWarning => 'Die Figur wirkt besorgt';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get tabHome => 'Start';

  @override
  String get tabMovements => 'Verlauf';

  @override
  String get tabRegister => 'Neu';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabSettings => 'Profil';

  @override
  String get collectionTitle => 'Sammlung';

  @override
  String get collectionSettingsValue => 'Ansehen';

  @override
  String get collectionCharacters => 'Figuren';

  @override
  String get collectionItems => 'Objekte';

  @override
  String collectionLevel(int level) {
    return 'LEVEL $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned von $total';
  }

  @override
  String get collectionCharactersHint => 'Sammle deine Begleiter';

  @override
  String get collectionItemsHint => 'Sammle, was in dein Zuhause gehört';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'Figur $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'Objekt $number';
  }

  @override
  String get collectionEquipped => 'AKTIV';

  @override
  String get collectionOwned => 'DEINS';

  @override
  String get collectionPlaceIt => 'Platzieren';

  @override
  String get collectionBuy => 'KAUFEN';

  @override
  String get collectionWatchAd => 'WERBUNG';

  @override
  String get collectionAdLoading => 'LÄDT';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'Belohnungswerbung ansehen · $progress/$target · eine pro Tag';
  }

  @override
  String get collectionAdUnavailable => 'KEINE WERBUNG';

  @override
  String get collectionAdDailyCap => 'LIMIT HEUTE';

  @override
  String get collectionAdTomorrow => 'MORGEN WEITER';

  @override
  String collectionUnlockedNotice(String name) {
    return '$name gehört dir!';
  }

  @override
  String get collectionAdDismissedNotice =>
      'Schau die Werbung ganz, damit sie zählt.';

  @override
  String get collectionPackOnly => 'PAKET';

  @override
  String get collectionPackDecoration => 'Michis Stern';

  @override
  String get collectionPackUnlock =>
      'Kommt mit Michi & Freunde. Nicht einzeln erhältlich.';

  @override
  String get collectionGiftOnly => 'GESCHENK';

  @override
  String get collectionGiftUnlock => 'Ein besonderes Geschenk. Nicht käuflich.';

  @override
  String collectionAdProgress(int progress, int target) {
    return 'WERBUNG $progress/$target';
  }

  @override
  String get collectionHowToGet => 'SO BEKOMMST DU ES';

  @override
  String get collectionAlreadyOwned => 'Schon Teil deiner Sammlung.';

  @override
  String get collectionIncludedUnlock => 'Von Anfang an dabei.';

  @override
  String collectionPurchaseUnlock(String price) {
    return 'Einmalkauf · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'Belohnungswerbung ansehen · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'Wird ab Level $level freigeschaltet.';
  }

  @override
  String get collectionStorePricePending => 'Store-Preis';

  @override
  String get collectionPreviewActionNotice =>
      'Käufe und Werbung werden später angebunden.';

  @override
  String get roomTitle => 'Mein Zuhause';

  @override
  String get roomOpen => 'Mein Zuhause öffnen';

  @override
  String get roomDecorate => 'Einrichten';

  @override
  String get roomDecorateTitle => 'Einrichten';

  @override
  String get roomDone => 'Fertig';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => 'Gartenhaus';

  @override
  String get roomThemeCasaDePlaya => 'Strandhaus';

  @override
  String get roomChooseTheme => 'Wähl den Stil deines Zuhauses.';

  @override
  String get roomCatReaction => 'Das hast du heute toll gemacht!';

  @override
  String get roomInstruction => 'Wähl ein Objekt und tippe, wo es hin soll.';

  @override
  String get roomCategoryRooms => 'Zimmer';

  @override
  String get roomCategoryFurniture => 'Möbel';

  @override
  String get roomCategoryWallFloor => 'Wand & Boden';

  @override
  String get roomCategoryProps => 'Deko';

  @override
  String get roomCategoryCharacters => 'Figuren';

  @override
  String get roomCharacterInstruction => 'Wähl, wer dir Gesellschaft leistet.';

  @override
  String get roomMoreInCollection => 'Mehr in der Sammlung';

  @override
  String get roomDefaultRug => 'Lavendelteppich';

  @override
  String get roomFloorLamp => 'Grüne Lampe';

  @override
  String get roomTablePlant => 'Tischpflanze';

  @override
  String get roomWallFrame => 'Wandbild';

  @override
  String get roomRattanChair => 'Rattansessel';

  @override
  String get roomStandingLamp => 'Stehlampe';

  @override
  String get roomWallClock => 'Wanduhr';

  @override
  String get roomLowCabinet => 'Sideboard';

  @override
  String get roomPetBed => 'Tierbett';

  @override
  String get roomSavingsJar => 'Sparglas';

  @override
  String get roomWallShelf => 'Wandregal';

  @override
  String get roomTerracottaPouf => 'Terrakotta-Pouf';

  @override
  String get roomBlueCreamRug => 'Blau-cremefarbener Teppich';

  @override
  String get roomLaunchSofa => 'Samtsofa';

  @override
  String get roomLaunchTv => 'Geschichten-TV';

  @override
  String get launchGiftTitle => 'Dein Startgeschenk ist da!';

  @override
  String get launchGiftBody =>
      'Du hast Sobrita rechtzeitig gestartet. Sofa und Fernseher gehören dir.';

  @override
  String get launchGiftGoToRoom => 'In mein Zuhause stellen';

  @override
  String get launchGiftLater => 'Später';

  @override
  String get roomSuggestCabinet =>
      'Stell es an die linke Wand. Tippe auf die markierte Stelle.';

  @override
  String get roomSuggestPetBed =>
      'Stell es links neben deinen Begleiter. Tippe auf die markierte Stelle.';

  @override
  String get roomSuggestSavingsJar =>
      'Probier den Tisch oder die kleine Bodenecke. Tippe auf eine markierte Stelle.';

  @override
  String get roomSuggestWallShelf =>
      'Häng es an eine freie Wand. Tippe auf eine markierte Stelle.';

  @override
  String get roomSuggestPouf =>
      'Gleich das Zimmer rechts aus. Tippe auf die markierte Stelle.';

  @override
  String get roomSuggestBlueRug =>
      'Leg ihn unter deinen Begleiter. Tippe auf die markierte Stelle.';

  @override
  String get roomSaved => 'Dein Zuhause wurde gespeichert.';

  @override
  String get roomPlaced => 'Platziert';

  @override
  String get roomSurfaceWall => 'Wand';

  @override
  String get roomSurfaceFloor => 'Boden';

  @override
  String get roomSurfaceTabletop => 'Tisch';

  @override
  String get roomSurfaceRug => 'Teppich';

  @override
  String roomSlotLabel(String surface, int number) {
    return '$surface, Platz $number';
  }

  @override
  String roomPickWall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'An der Wand sind $count Plätze. Tippe, wo es hin soll.',
      one: 'An der Wand ist ein Platz. Tippe darauf, um es aufzuhängen.',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auf dem Boden sind $count Plätze. Tippe, wo es hin soll.',
      one: 'Auf dem Boden ist ein Platz. Tippe darauf, um es hinzustellen.',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auf dem Tisch sind $count Plätze. Tippe, wo es hin soll.',
      one: 'Auf dem Tisch ist ein Platz. Tippe darauf, um es hinzustellen.',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es gibt $count Plätze für einen Teppich. Tippe, wo er hin soll.',
      one:
          'Es gibt einen Platz für einen Teppich. Tippe darauf, um ihn hinzulegen.',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es gibt $count passende Plätze. Tippe, wo es hin soll.',
      one: 'Es gibt einen passenden Platz. Tippe darauf, um es hinzustellen.',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove =>
      'Tippe auf einen anderen Platz, um es zu verschieben, oder auf seinen, um es wegzunehmen.';

  @override
  String get roomTapToRemove =>
      'Tippe noch einmal auf seinen Platz, um es wegzunehmen.';

  @override
  String get xpHistoryTitle => 'Dein Fortschritt';

  @override
  String xpTotal(int count) {
    return '$count XP insgesamt';
  }

  @override
  String get xpMaxLevel => 'Höchstes Level';

  @override
  String xpRemaining(int count) {
    return 'Noch $count XP';
  }

  @override
  String get xpHistoryHint =>
      'XP werden automatisch gutgeschrieben. Jede Zeile behält den Grund und die Rechnung, auch wenn du die App schließt.';

  @override
  String get xpHistoryEmptyTitle => 'Noch keine XP';

  @override
  String get xpHistoryEmptyMessage =>
      'Dein erster Kassensturz der Woche und der Abschluss deines Zyklus erscheinen hier.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => 'Rechnung ansehen';

  @override
  String get xpCalculationTitle => 'So wurde gerechnet';

  @override
  String get xpDetailCycle => 'Zyklus';

  @override
  String get xpDetailBudget => 'Budget';

  @override
  String get xpDetailSpent => 'Ausgegeben';

  @override
  String get xpDetailResult => 'Ergebnis';

  @override
  String get xpDetailRule => 'Regel';

  @override
  String get xpDetailCredited => 'XP gutgeschrieben';

  @override
  String get xpRuleCashCount => 'Höchstens einmal pro Woche';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Belohnung auf $count Tage umgerechnet',
      one: 'Belohnung auf $count Tag umgerechnet',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage × 5 XP',
      one: '$count Tag × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => 'Einmaliger Bonus von 50 XP';

  @override
  String get recoveryNotYet =>
      'Deine Daten konnten noch nicht wiederhergestellt werden.';

  @override
  String get recoveryStartFreshQuestion => 'Neu anfangen?';

  @override
  String get recoveryStartFreshBody =>
      'Wir behalten eine Kopie der Originaldatei, bevor neue Daten angelegt werden.';

  @override
  String get recoveryStartFresh => 'Neu anfangen';

  @override
  String get recoveryTitle => 'Deine Daten konnten nicht gelesen werden';

  @override
  String get recoveryOriginalKept =>
      'Die Originaldatei ist noch gespeichert. Wir haben nichts ersetzt oder gelöscht.';

  @override
  String get recoveryOptions =>
      'Du kannst es erneut versuchen, die Sicherung nutzen oder die Datei exportieren, um sie aufzubewahren.';

  @override
  String get recoveryRetrying => 'Neuer Versuch…';

  @override
  String get recoveryRetry => 'Erneut versuchen';

  @override
  String get recoveryUseBackup => 'Sicherung nutzen';

  @override
  String get recoveryExport => 'Datei exportieren';

  @override
  String get recoveryExported => 'Originaldatei kopiert.';

  @override
  String get settingsTitle => 'Mein Sobrita';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String currencyChangeTitle(String code) {
    return 'Zu $code wechseln?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return 'Deine Beträge werden nicht umgerechnet: $example bleibt $converted. Nur die Bezeichnung ändert sich.';
  }

  @override
  String get currencyChangeConfirm => 'Bezeichnung ändern';

  @override
  String get currencyRegionAmericas => 'Amerika';

  @override
  String get currencyRegionEurope => 'Europa';

  @override
  String get currencyRegionAsiaPacific => 'Asien und Ozeanien';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsBudgetCycle => 'Zyklus';

  @override
  String get settingsCountDay => 'Zähltag';

  @override
  String get settingsReduceMotionHint =>
      'Schaltet sich selbst ein, wenn dein Handy es schon verlangt.';

  @override
  String get settingsQuickEntry => 'Schnelleintrag';

  @override
  String get settingsQuickEntryHint =>
      'Zeigt Einnahme und Ausgabe auf dem Sperrbildschirm.';

  @override
  String get quickEntryQuestion => 'Was möchtest du eintragen?';

  @override
  String get quickEntryDenied =>
      'Erlaube Mitteilungen von Sobrita, um den Schnelleintrag einzuschalten.';

  @override
  String get widgetTodayLeft => 'Heute übrig';

  @override
  String get widgetCycleBalance => 'Saldo';

  @override
  String get widgetOpenApp => 'Sobrita öffnen';

  @override
  String get widgetRegisterExpense => 'Ausgabe eintragen';

  @override
  String get settingsBackup => 'Datensicherung';

  @override
  String get settingsCopy => 'Kopieren';

  @override
  String get settingsBackupCopied => 'Sicherung in die Zwischenablage kopiert.';

  @override
  String get settingsRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get settingsAccount => 'Google-Konto';

  @override
  String get settingsAccountConnect => 'Verbinden';

  @override
  String get settingsRestore => 'Wiederherstellen';

  @override
  String get purchaseRestored => 'Fertig. Deine Käufe sind wieder da.';

  @override
  String get purchaseFailureStoreUnavailable =>
      'Der Store ist gerade nicht erreichbar. Versuch es später noch einmal.';

  @override
  String get purchaseFailureRejected =>
      'Der Kauf konnte nicht abgeschlossen werden. Dir wurde nichts berechnet.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      'Dein Kauf ist angekommen, konnte aber nicht gespeichert werden. Er wird beim nächsten Öffnen von Sobrita angewendet.';

  @override
  String get purchaseFailureNothingToRestore =>
      'Auf diesem Konto wurden keine Käufe gefunden.';

  @override
  String get collectionPurchasing => 'KAUFE…';

  @override
  String get settingsXpPreview => 'XP-Vorschau';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsStorageNote =>
      'Deine Daten bleiben auf diesem Gerät. Du brauchst kein Konto, um Sobrita zu nutzen.';

  @override
  String get settingsSectionShop => 'Shop';

  @override
  String get settingsRemoveAds => 'Allgemeine Werbung entfernen';

  @override
  String get settingsRemoveAdsHint =>
      'Entfernt die Werbung aus dem Verlauf. Belohnungswerbung bleibt verfügbar.';

  @override
  String get settingsPackName => 'Michi & Freunde';

  @override
  String get settingsPackHint =>
      '3 Figuren + Michis Stern. Entfernt auch die allgemeine Werbung.';

  @override
  String get settingsOwned => 'Gekauft';

  @override
  String get settingsShopRestoreNote =>
      'Käufe bleiben bei deinem Store-Konto. Nach einer Neuinstallation kannst du sie wiederherstellen.';

  @override
  String get settlementTitle => 'Abschluss dieses Zyklus';

  @override
  String get settlementSpent => 'Ausgegeben';

  @override
  String get settlementLeft => 'Übrig';

  @override
  String get settlementOver => 'Drüber';

  @override
  String get settlementAverage => 'Tagesdurchschnitt';

  @override
  String get settlementContinue => 'Fertig';

  @override
  String get settlementCtaTitle => 'Hol dir eine besondere Deko';

  @override
  String get settlementCtaAction => 'Sammlung öffnen';

  @override
  String get settingsSectionBudget => 'Budget';

  @override
  String get settingsSectionScreen => 'Anzeige';

  @override
  String get settingsSectionData => 'Daten';

  @override
  String get settingsSectionPrivacy => 'Datenschutz';

  @override
  String get settingsAdPrivacy => 'Werbe-Datenschutz';

  @override
  String get settingsAdPrivacyValue => 'Verwalten';

  @override
  String get settingsAdPrivacyFailed =>
      'Die Datenschutzoptionen konnten nicht geöffnet werden. Versuch es noch einmal.';

  @override
  String get settingsSectionDesign => 'Design';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '$movements Einträge',
      one: '1 Eintrag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage mit Sobrita',
      one: '1 Tag mit Sobrita',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => 'Automatisch';

  @override
  String get languageAutomaticHint => 'Wie dein Handy';

  @override
  String get transactionsTitle => 'Verlauf';

  @override
  String get dailySpendTitle => 'Ausgaben pro Tag';

  @override
  String dailySpendLimit(String amount) {
    return '$amount pro Tag';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return 'Dieser Zyklus $amount';
  }

  @override
  String get dailyIncomeTitle => 'Einnahmen pro Tag';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return 'Dieser Zyklus $amount';
  }

  @override
  String get transactionsEmptyTitle => 'Noch nichts hier';

  @override
  String get transactionsEmptyMessage =>
      'Trag deine erste Ausgabe ein, dann erscheint hier die Übersicht des Zyklus.';

  @override
  String get transactionsEmptyExpensesTitle => 'Noch keine Ausgaben';

  @override
  String get transactionsEmptyExpensesMessage =>
      'Trag eine Ausgabe ein, dann siehst du hier Tag für Tag.';

  @override
  String get transactionsEmptyIncomesTitle => 'Noch keine Einnahmen';

  @override
  String get transactionsEmptyIncomesMessage =>
      'Trag eine Einnahme ein, dann siehst du hier Tag für Tag.';

  @override
  String get transactionsExpensePinned =>
      'Diese Ausgabe stammt aus einem Kassensturz. Zähl neu, um sie zu korrigieren.';

  @override
  String get transactionsIncomePinned =>
      'Diese Einnahme stammt aus einem Kassensturz. Zähl neu, um sie zu korrigieren.';

  @override
  String get transactionsExpenseDeleted => 'Ausgabe gelöscht.';

  @override
  String get transactionsIncomeDeleted => 'Einnahme gelöscht.';

  @override
  String get undo => 'Rückgängig';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get identifyDifference => 'Differenz klären';

  @override
  String get editMovement => 'Eintrag bearbeiten';

  @override
  String get amount => 'Betrag';

  @override
  String get editPendingHint =>
      'Der Betrag stammt aus deinem Kassensturz. Kategorie und Notiz kannst du trotzdem ändern.';

  @override
  String get category => 'Kategorie';

  @override
  String get note => 'Notiz';

  @override
  String get noteExample => 'z. B. Döner';

  @override
  String get replacesPendingHint =>
      'Das ersetzt die offene Korrektur. Es kommt keine weitere Ausgabe dazu.';

  @override
  String get saveWithoutDuplicating => 'Ohne Duplikat speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get save => 'Speichern';

  @override
  String get budget => 'Budget';

  @override
  String get spent => 'Ausgegeben';

  @override
  String get appName => 'Sobrita';

  @override
  String get homeCycleBalance => 'Saldo des Zyklus';

  @override
  String get homeTodayLeft => 'Heute hast du noch';

  @override
  String homeOverBudget(String budget) {
    return 'Du hast das Budget von $budget in diesem Zyklus überschritten';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return 'Limit heute $limit · $remaining übrig im Zyklus';
  }

  @override
  String get homeFirstQuestLabel => 'Erste Quest';

  @override
  String get homeBudgetQuestBody =>
      'Leg ein Budget fest, und ich rechne aus, wie viel du pro Tag ausgeben kannst.';

  @override
  String get homeCycleProgress => 'Fortschritt des Zyklus';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => 'Geschätztes Bargeld';

  @override
  String get homeCashUnset => 'Bargeld nicht eingerichtet';

  @override
  String homeLastCount(String amount) {
    return 'Letzte Zählung: $amount';
  }

  @override
  String get homeFirstCountHint => 'Mach zum Start einen ersten Kassensturz.';

  @override
  String get homeRecentMovements => 'Letzte Einträge';

  @override
  String get homeSeeAll => 'Alle';

  @override
  String get homeGoingWell => 'Läuft gut';

  @override
  String get homeAdjustCalmly => 'Ganz ruhig nachjustieren';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetCycleTotal => 'Summe des Zyklus';

  @override
  String get budgetTotal => 'Gesamtbudget';

  @override
  String get budgetNotSetTitle => 'Noch kein Budget';

  @override
  String get budgetNotSetBody =>
      'Leg eins fest, und wir rechnen aus, wie viel du pro Tag ausgeben kannst.';

  @override
  String get budgetSetAction => 'Budget festlegen';

  @override
  String budgetTooLow(String allocated) {
    return 'Der Betrag muss höher sein als die Einnahmen, die diesem Zyklus schon zugeteilt sind ($allocated).';
  }

  @override
  String budgetSpentShare(int percent) {
    return '$percent % des Budgets';
  }

  @override
  String budgetRingSpent(String amount) {
    return 'Ausgegeben $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return '$amount übrig';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent %';
  }

  @override
  String get cycleHistoryTitle => 'Frühere Zyklen';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$green von $total Zyklen im Plus',
      one: '$green von $total Zyklus im Plus',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return 'Budget $budget · Ausgegeben $spent';
  }

  @override
  String get cycleHistoryEmpty => 'Noch kein Zyklus abgeschlossen.';

  @override
  String cycleHistoryAverage(String amount) {
    return 'Tagesdurchschnitt $amount';
  }

  @override
  String get cycleHistoryAveragePending =>
      'Tagesdurchschnitt · wird noch ermittelt';

  @override
  String get budgetChangedTitle => 'Du hast dein Budget geändert';

  @override
  String get budgetChangedBody =>
      'Was machen wir mit den Kategorie-Limits? Beim Anpassen ändert sich jedes im gleichen Verhältnis, deine Aufteilung bleibt also deine.';

  @override
  String get budgetKeepLimits => 'Behalten';

  @override
  String get budgetScaleLimits => 'Anteilig anpassen';

  @override
  String get budgetByCategory => 'Budget nach Kategorie';

  @override
  String budgetCategoryLimit(String category) {
    return 'Limit für $category';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => 'Prognose zum Abschluss';

  @override
  String get budgetEstimatedLeft => 'Was dir übrig bleiben sollte';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get saving => 'Speichert…';

  @override
  String dayOfMonth(int day) {
    return 'Tag $day';
  }

  @override
  String get weekdayMonday => 'Montag';

  @override
  String get weekdayTuesday => 'Dienstag';

  @override
  String get weekdayWednesday => 'Mittwoch';

  @override
  String get weekdayThursday => 'Donnerstag';

  @override
  String get weekdayFriday => 'Freitag';

  @override
  String get weekdaySaturday => 'Samstag';

  @override
  String get weekdaySunday => 'Sonntag';

  @override
  String get weekdayShortMonday => 'Mo';

  @override
  String get weekdayShortTuesday => 'Di';

  @override
  String get weekdayShortWednesday => 'Mi';

  @override
  String get weekdayShortThursday => 'Do';

  @override
  String get weekdayShortFriday => 'Fr';

  @override
  String get weekdayShortSaturday => 'Sa';

  @override
  String get weekdayShortSunday => 'So';

  @override
  String get registerTitle => 'Neu';

  @override
  String get registerExpense => 'Ausgabe';

  @override
  String get registerIncome => 'Einnahme';

  @override
  String get registerAmountAboveZero => 'Gib einen Betrag über null ein.';

  @override
  String get registerNoFutureMovements =>
      'Du kannst nichts mit einem Datum in der Zukunft eintragen.';

  @override
  String get registerDate => 'Datum';

  @override
  String get registerNoteExpenseExample => 'z. B. Bäckerei Müller';

  @override
  String get registerNoteIncomeExample => 'z. B. Trinkgeld vom Freitag';

  @override
  String get receiptTitle => 'Beleg';

  @override
  String get receiptAdd => 'Beleg hinzufügen';

  @override
  String get receiptCamera => 'Kamera';

  @override
  String get receiptGallery => 'Galerie';

  @override
  String get receiptChange => 'Ersetzen';

  @override
  String get receiptRemove => 'Entfernen';

  @override
  String get receiptHint => 'Ein Foto, damit du weißt, was diese Ausgabe war.';

  @override
  String get receiptAttached => 'Beleg angehängt';

  @override
  String get receiptView => 'Beleg ansehen';

  @override
  String get receiptClose => 'Schließen';

  @override
  String get receiptMissing => 'Das Foto ist nicht mehr auf diesem Gerät.';

  @override
  String get receiptFailed => 'Das Foto konnte nicht gespeichert werden.';

  @override
  String get receiptBackupNote => 'Die Sicherung enthält keine Belegfotos.';

  @override
  String get registerPayment => 'Zahlung';

  @override
  String get registerPaymentHint =>
      'Bargeld wird von deiner Zählung abgezogen. Karte nicht.';

  @override
  String get registerIncomeKind => 'Art der Einnahme';

  @override
  String get registerWhatToDo => 'Was möchtest du tun?';

  @override
  String get registerThisCycle => 'Dieser Zyklus';

  @override
  String get registerSaveIt => 'Sparen';

  @override
  String get registerReceivedIn => 'Erhalten als';

  @override
  String get registerAccount => 'Konto';

  @override
  String get registerReconcileQuestion =>
      'Erklärt diese Ausgabe die Differenz?';

  @override
  String registerReconcileBody(String amount) {
    return 'Aus deinem letzten Kassensturz sind $amount offen. Wenn es dieselbe Ausgabe ist, gleichen wir sie ab, ohne doppelt zu zählen.';
  }

  @override
  String get registerReconcileNo => 'Nein, sie ist neu';

  @override
  String get registerReconcileYes => 'Ja, abgleichen';

  @override
  String get registerDifferenceReconciled => 'Differenz abgeglichen';

  @override
  String get registerExpenseSaved => 'Ausgabe gespeichert';

  @override
  String get registerIncomeSaved => 'Einnahme gespeichert';

  @override
  String get cashCountTitle => 'Kassensturz';

  @override
  String get cashCountPickWhatHappened =>
      'Wähl, was mit der Differenz passiert ist.';

  @override
  String get cashCountSavedWithoutDuplicates =>
      'Kassensturz gespeichert, nichts doppelt.';

  @override
  String get cashCountPrompt => 'Zähl nur das Bargeld, das du gerade hast.';

  @override
  String get cashCountNoneYet => 'Noch keine Zählung';

  @override
  String get cashCountResultPending =>
      'Das Ergebnis erscheint, sobald du die Zählung eingibst.';

  @override
  String get cashCountBaselineHint =>
      'Das wird dein Ausgangspunkt. Es wird nicht als Einnahme erfasst.';

  @override
  String get cashCountExpected => 'Erwartet';

  @override
  String get cashCountCounted => 'Gezählt';

  @override
  String get cashCountBalanced => 'Alles stimmt';

  @override
  String cashCountShort(String amount) {
    return '$amount fehlen';
  }

  @override
  String cashCountExtra(String amount) {
    return '$amount zu viel';
  }

  @override
  String get cashCountWhatHappened => 'Was ist passiert?';

  @override
  String get cashCountHelperExpense =>
      'Es war eine Ausgabe, die du nicht eingetragen hattest.';

  @override
  String get cashCountHelperIncome =>
      'Es war neues Geld, das du bekommen hast.';

  @override
  String get cashCountHelperTransferOut =>
      'Du hast es eingezahlt oder auf ein anderes Konto verschoben.';

  @override
  String get cashCountHelperTransferIn =>
      'Du hast es abgehoben oder von einem anderen Konto geholt.';

  @override
  String get cashCountHelperCorrection => 'Die letzte Zählung war falsch.';

  @override
  String get cashCountHelperPending => 'Später entscheiden.';

  @override
  String get cashCountSingleExpenseHint =>
      'Das legt eine einzige Ausgabe an. Du musst sie nicht noch einmal eintragen.';

  @override
  String get cashCountNoteTipExample => 'z. B. Trinkgeld';

  @override
  String get cashCountWhatToDoWithMoney => 'Was machen wir mit diesem Geld?';

  @override
  String get cashCountSaveFirst => 'Ersten Kassensturz speichern';

  @override
  String get cashCountSave => 'Kassensturz speichern';

  @override
  String get cycleTitle => 'Dein Zyklus';

  @override
  String get cycleCurrent => 'Aktueller Zyklus';

  @override
  String get cycleInProgress => 'Läuft';

  @override
  String get cycleUnchanged => 'Bleibt gleich';

  @override
  String get cycleNewFrequency => 'Neuer Rhythmus';

  @override
  String get cycleFirstPay => 'Erster Zahltag';

  @override
  String get cyclePayDay => 'Zahltag';

  @override
  String get cycleNext => 'Nächster Zyklus';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return 'Die Änderung gilt ab dem nächsten Zyklus und wiederholt sich danach alle $days Tage.';
  }

  @override
  String get cycleChangeApplies => 'Die Änderung gilt ab dem nächsten Zyklus.';

  @override
  String get cycleSaveChange => 'Änderung speichern';

  @override
  String get onboardingBudgetAboveZero => 'Gib ein Budget über null ein.';

  @override
  String get onboardingCashOrSkip =>
      'Gib dein Bargeld ein oder wähl „Jetzt nicht“.';

  @override
  String get prologueRainNoEnd => 'Der Regen wollte einfach nicht aufhören.';

  @override
  String get prologueRentPaid =>
      'Die Miete war bezahlt, und was auf dem Konto lag, musste bis zum Zahltag reichen.';

  @override
  String get prologueSoundAtDoor => 'An der Tür regte sich etwas.';

  @override
  String get prologueGoLook => 'Nachsehen';

  @override
  String get prologueWetTracks =>
      'Zwei Reihen nasser Pfotenabdrücke zogen sich über den Boden.';

  @override
  String get prologueShelter => 'Lass uns den Regen abwarten.';

  @override
  String get prologueItSpoke => '…es sprach.';

  @override
  String get prologueReplySurprised => 'Hast du gerade geredet?';

  @override
  String get prologueReplyTowel => '(du holst wortlos ein Handtuch)';

  @override
  String get prologueEarnKeep =>
      'Ich sollte mich nützlich machen. Ich kümmere mich um die Zahlen.';

  @override
  String get prologueAskSchedule => 'Also, zuerst: Wann kommt Geld rein?';

  @override
  String get prologueAskPayday =>
      'An welchem Tag bekommst du Geld? Sag mir den ersten, den Rest zähle ich.';

  @override
  String prologueAskBudget(int days) {
    return 'Noch $days Tage bis zum nächsten Zahltag. Wie viel willst du ausgeben?';
  }

  @override
  String get prologueSkipIsFine =>
      'Du kannst es überspringen. Ich frage zu Hause noch mal.';

  @override
  String get prologueSkip => 'Überspringen';

  @override
  String get prologueDriedOff =>
      'Abgetrocknet kamen beide zur Ruhe. Draußen regnete es noch.';

  @override
  String get prologueWhoSits => 'Wer sitzt bei dir?';

  @override
  String get prologueMichiTrait => 'Ruhig.\nGut mit Zahlen.';

  @override
  String get prologuePoodleTrait => 'Voller Energie.\nPasst auf dich auf.';

  @override
  String get prologueSchnauzerTrait => 'Nachdenklich.\nHält Wache.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'Voller Energie.\nPasst auf dich auf.';

  @override
  String get prologueLockedSoon => 'Bild folgt';

  @override
  String get prologueOtherStays =>
      'Der andere bleibt auch. Du kannst deinen Begleiter später wechseln.';

  @override
  String get prologueLiveTogether => 'Sie dürfen bleiben';

  @override
  String prologueGreeting(String name) {
    return 'Ich bin $name. Danke, dass du aufgemacht hast.';
  }

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get onboardingTagline => 'Dein Geld, ganz ohne Druck.';

  @override
  String get onboardingPromise =>
      'Wir sagen dir, wie viel du heute ausgeben kannst.';

  @override
  String get onboardingHowPaid => 'Wie bekommst du dein Geld?';

  @override
  String get onboardingHowPaidHint => 'Das legt die Daten deines Budgets fest.';

  @override
  String get onboardingCycleHelperSemiMonthly =>
      'Zwei Zahltage im Monat: der 15. und der letzte Tag.';

  @override
  String get onboardingCycleHelperMonthly => 'Ein Zahltag im Monat.';

  @override
  String get onboardingCycleHelperWeekly => 'Jede Woche.';

  @override
  String get onboardingCycleHelperIrregular =>
      'Mein Einkommen hat kein festes Datum.';

  @override
  String get onboardingPlanWithoutFixedDate => 'Ohne festes Datum planen';

  @override
  String get onboardingWhichDayPaid => 'An welchem Tag bekommst du Geld?';

  @override
  String get onboardingSecondPayEndOfMonth => 'Zweiter Zahltag · Monatsende';

  @override
  String get onboardingHowManyDays => 'Für wie viele Tage willst du planen?';

  @override
  String get onboardingCyclePreview => 'So sähe dein Zyklus aus';

  @override
  String onboardingRepeatsEvery(int days) {
    return 'Wenn er endet, beginnt von selbst ein neuer Abschnitt von $days Tagen.';
  }

  @override
  String get onboardingShortMonthsNote =>
      'In kurzen Monaten passen sich die Daten selbst an.';

  @override
  String get onboardingBudgetQuestion =>
      'Wie viel willst du\nin diesem Zyklus ausgeben?';

  @override
  String get onboardingBudgetLater =>
      'Du kannst es später auf dem Startbildschirm festlegen.';

  @override
  String get onboardingNotNow => 'Jetzt nicht';

  @override
  String get onboardingCashQuestion => 'Wie viel Bargeld\nhast du heute?';

  @override
  String get onboardingCashOptional =>
      'Lass es leer, wenn du lieber später zählst.';

  @override
  String get onboardingCashIsBaseline =>
      'Das wird dein erster Kassensturz, keine Einnahme.';

  @override
  String onboardingSettledIn(String name) {
    return 'Der Regen hörte auf. $name machte es sich neben dir gemütlich.';
  }

  @override
  String get onboardingFirstQuests => 'Deine ersten Quests';

  @override
  String get onboardingWaitingAtHome => 'Wartet zu Hause auf dich';

  @override
  String get onboardingGoHome => 'Zum Start';

  @override
  String get onboardingPlanReady => 'Dein Plan steht';

  @override
  String get onboardingCanSpendToday => 'Heute kannst du ausgeben';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step von $total';
  }

  @override
  String progressPercent(int percent) {
    return 'Fortschritt $percent Prozent';
  }

  @override
  String stepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly =>
      'Du hast die zwei Wochen im Plus abgeschlossen';

  @override
  String get onboardingCycleHelperBiweekly =>
      'Alle zwei Wochen, ab meinem letzten Zahltag.';

  @override
  String get cycleLastPayday => 'Letzter Zahltag';

  @override
  String get onboardingWhenLastPaid => 'Wann war dein letzter Zahltag?';

  @override
  String get onboardingBiweeklyNeedsDate =>
      'Wähl den Tag deines letzten Zahltags.';

  @override
  String get pickDate => 'Datum wählen';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }

  @override
  String get settingsSectionAbout => 'Info';

  @override
  String get settingsReleaseNotes => 'Neuigkeiten';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => 'Neuigkeiten';

  @override
  String get releaseNotesCurrent => 'Aktuell';

  @override
  String releaseNotesRetention(int count) {
    return 'Wir behalten die letzten $count Versionen.';
  }

  @override
  String get releaseNote104Fixed =>
      'Fixkosten laufen getrennt vom Tagesbudget. Sie erscheinen auf dem Startbildschirm und können dich vor der Fälligkeit erinnern.';

  @override
  String get releaseNote104Decor =>
      'Im Zuhause gibt es mehr zu platzieren: ein Bett, ein Regal, einen Teppich, ein Sideboard, ein Glas und einen Pouf.';

  @override
  String get releaseNote104Names =>
      'Miru, Yoshi und Cookie haben jetzt Namen, und der Level-Titel trägt den Namen deines Begleiters.';

  @override
  String get releaseNote104Widget => 'Das Widget zeigt den vollen Betrag.';

  @override
  String get releaseNote104Languages =>
      'Sobrita spricht jetzt Portugiesisch, Deutsch, Französisch und Japanisch.';

  @override
  String get releaseNote103GuineaPig =>
      'Das Meerschweinchen ist in der Sammlung. Zwei kurze Werbungen, und es bleibt.';

  @override
  String get releaseNote103Widget =>
      'Das Widget zeigt, mit wem du wohnst, und schreibt den Betrag so wie die App.';

  @override
  String get releaseNote102Schnauzer =>
      'Der Schnauzer ist in der Sammlung. Zwei kurze Werbungen, und er bleibt.';

  @override
  String get releaseNote102Rooms =>
      'Das Zuhause kann ein Garten oder ein Strand sein, und ein Sessel, eine Lampe und eine Uhr stehen bereit.';

  @override
  String get releaseNote102Missions =>
      'Zwei der drei Tagesmissionen wechseln täglich, und die mit einem Extraschritt bringen mehr XP.';

  @override
  String get releaseNote102Amounts =>
      'Kolumbianische, argentinische und chilenische Pesos, Real und Euro schreiben sich jetzt mit Komma, wie 1.234,56.';

  @override
  String get releaseNote101Currencies =>
      'Geld lässt sich jetzt in kolumbianischen, argentinischen und chilenischen Pesos, Soles, Pfund oder Yen bezeichnen.';

  @override
  String get releaseNote101Celebration =>
      'Die Feier füllt jetzt ihre Karte und beendet ihren Sprung.';

  @override
  String get releaseNote100Launch => 'Die erste Version von Sobrita.';

  @override
  String get updateAvailableTitle => 'Es gibt eine neue Version';

  @override
  String get updateAvailableBody =>
      'Aktualisiere, um das neueste Sobrita zu bekommen.';

  @override
  String updateCurrentVersion(String version) {
    return 'Deine Version: v$version';
  }

  @override
  String get updateAction => 'Aktualisieren';

  @override
  String get updateLater => 'Jetzt nicht';

  @override
  String get updateBannerMessage => 'Neue Version verfügbar';

  @override
  String get updateBannerDismiss => 'Hinweis schließen';

  @override
  String get updateStoreFailed => 'Google Play konnte nicht geöffnet werden.';

  @override
  String get settingsCheckUpdate => 'Nach Updates suchen';

  @override
  String get settingsCheckUpdateBusy => 'Suche…';

  @override
  String get settingsCheckUpdateUpToDate => 'Du bist auf dem neuesten Stand.';

  @override
  String get settingsRateApp => 'Sobrita bewerten';

  @override
  String get settingsOurApps => 'Empfohlene Apps';

  @override
  String get ourAppsIntro => 'Vom Sobrita-Team gemacht.';

  @override
  String get ourAppsOpen => 'Bei Google Play ansehen';

  @override
  String get ourAppsLoopetKind => 'Routinen';

  @override
  String get ourAppsLoopetBlurb =>
      'Dein ganzer Tag in einem Kreis. Sieh, was jetzt dran ist und was danach kommt.';

  @override
  String get ourAppsRandomFocusKind => 'Fokus';

  @override
  String get ourAppsRandomFocusBlurb =>
      'Dreh am Rad, lass es die Dauer wählen und konzentrier dich einfach.';

  @override
  String get releaseAnnouncementViewAll => 'Alle ansehen';

  @override
  String get releaseAnnouncementDone => 'Fertig';

  @override
  String get settingsReleaseNotesUnread => 'Ungelesene Neuigkeiten';

  @override
  String get fixedSectionTitle => 'Fixkosten';

  @override
  String fixedSectionMonth(String month) {
    return '$month · getrennt vom Tagesbetrag';
  }

  @override
  String fixedPaidOfTotal(String paid, String total) {
    return 'Bezahlt $paid von $total';
  }

  @override
  String get fixedAdd => 'Fixkosten hinzufügen';

  @override
  String get fixedEmptyBody =>
      'Miete, Handy, Strom: einmal eintragen, und ich erinnere dich, wenn sie fällig sind. Deinen Tagesbetrag ändern sie nicht.';

  @override
  String get fixedFrequencyWeekly => 'Jede Woche';

  @override
  String get fixedFrequencySemiMonthly => 'Zweimal im Monat';

  @override
  String get fixedFrequencyMonthly => 'Jeden Monat';

  @override
  String get fixedFrequencyBimonthly => 'Alle 2 Monate';

  @override
  String get fixedStatusPaid => 'Bezahlt';

  @override
  String get fixedStatusTomorrow => 'Morgen';

  @override
  String get fixedStatusOverdue => 'Überfällig';

  @override
  String fixedApprox(String amount) {
    return 'ca. $amount';
  }

  @override
  String get fixedFormNewTitle => 'Neue Fixkosten';

  @override
  String get fixedFormEditTitle => 'Fixkosten bearbeiten';

  @override
  String get fixedName => 'Name';

  @override
  String get fixedNameHint => 'Miete, Handy, Strom…';

  @override
  String get fixedNameRequired => 'Gib einen Namen ein';

  @override
  String get fixedHowOften => 'Wie oft?';

  @override
  String get fixedNextDue => 'Nächste Zahlung';

  @override
  String fixedThenDates(String dates) {
    return 'Danach: $dates…';
  }

  @override
  String get fixedVariable => 'Der Betrag ändert sich jedes Mal';

  @override
  String get fixedVariableHint =>
      'Ich nehme deine letzte Zahlung als Schätzung.';

  @override
  String get fixedFormNote =>
      'Dein Tagesbetrag bleibt gleich: Dein Budget ist das, was nach den Fixkosten übrig bleibt.';

  @override
  String get fixedSave => 'Fixkosten speichern';

  @override
  String get fixedDelete => 'Fixkosten löschen';

  @override
  String fixedDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get fixedDeleteBody =>
      'Zahlungen, die du schon eingetragen hast, bleiben im Verlauf.';

  @override
  String get fixedDueToday => 'Heute fällig';

  @override
  String get fixedDueTomorrow => 'Morgen fällig';

  @override
  String fixedDueOn(String date) {
    return 'Fällig am $date';
  }

  @override
  String fixedWasDue(String date) {
    return 'War fällig am $date';
  }

  @override
  String get fixedHowMuch => 'Wie viel hast du bezahlt?';

  @override
  String fixedLastTime(String amount) {
    return 'Letztes Mal: $amount';
  }

  @override
  String fixedTodayUnchanged(String amount) {
    return 'Dein Betrag für heute bleibt bei $amount.';
  }

  @override
  String fixedCashChange(String from, String to) {
    return 'Geschätztes Bargeld: von $from auf $to';
  }

  @override
  String fixedPaidWith(String method) {
    return 'Bezahlt mit $method';
  }

  @override
  String get fixedChange => 'Ändern';

  @override
  String get fixedMarkPaid => 'Ist bezahlt';

  @override
  String get fixedNotYet => 'Noch nicht';

  @override
  String get fixedBillOnly => 'Nur die Rechnung kam';

  @override
  String fixedBillSaved(String amount) {
    return 'Alles klar, ich rechne mit $amount.';
  }

  @override
  String fixedPaymentSaved(String name) {
    return '$name eingetragen.';
  }

  @override
  String get fixedHomeLabel => 'Fixkosten';

  @override
  String fixedHomeMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feste Zahlungen zu prüfen',
      one: '1 feste Zahlung zu prüfen',
    );
    return '$_temp0';
  }

  @override
  String get fixedHomeSee => 'Ansehen';

  @override
  String get fixedIntroTitle => 'Dein Budget ist zum Ausgeben, ohne Fixkosten';

  @override
  String fixedIntroBody(String budget, String name) {
    return 'Fixkosten senken deinen Tagesbetrag nicht. Wenn deine $budget „$name“ schon enthielten, senk lieber das Budget.';
  }

  @override
  String get fixedIntroKeep => 'Passt so';

  @override
  String get fixedIntroAdjust => 'Budget anpassen';

  @override
  String get fixedBadge => 'Fix';

  @override
  String get fixedNothingThisMonth => 'Diesen Monat ist nichts fällig.';

  @override
  String get fixedReminderLabel => 'Erinnerung';

  @override
  String get fixedReminderNone => 'Keine Erinnerung';

  @override
  String get fixedReminderSameDay => 'Am selben Tag';

  @override
  String get fixedReminderDayBefore => '1 Tag vorher';

  @override
  String get fixedReminderThreeDaysBefore => '3 Tage vorher';

  @override
  String get fixedReminderHint => 'Ich erinnere dich um 9:00 Uhr morgens.';

  @override
  String get fixedReminderBlocked =>
      'Die Mitteilungen von Sobrita sind aus, deshalb kann ich dich nicht erinnern.';

  @override
  String fixedReminderTitleToday(String name) {
    return '$name ist heute fällig';
  }

  @override
  String fixedReminderTitleTomorrow(String name) {
    return '$name ist morgen fällig';
  }

  @override
  String fixedReminderTitleInDays(String name, int days) {
    return '$name ist in $days Tagen fällig';
  }

  @override
  String fixedReminderBody(String amount, String method) {
    return '$amount · $method. Markier es in Sobrita als bezahlt, sobald du zahlst.';
  }
}
