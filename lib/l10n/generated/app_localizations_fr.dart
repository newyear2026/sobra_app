// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get categoryFood => 'Nourriture';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Achats';

  @override
  String get categoryHome => 'Maison';

  @override
  String get categoryServices => 'Factures';

  @override
  String get categoryHealth => 'Santé';

  @override
  String get categoryEducation => 'Éducation';

  @override
  String get categoryEntertainment => 'Loisirs';

  @override
  String get categoryPets => 'Animaux';

  @override
  String get categoryOther => 'Autres';

  @override
  String get incomeKindSalary => 'Ma paie habituelle';

  @override
  String get incomeKindExtra => 'Revenu en plus';

  @override
  String get incomeKindCash => 'Rentrée en espèces';

  @override
  String get incomeKindRefund => 'Remboursement';

  @override
  String get incomeAllocationCycle => 'Ce cycle';

  @override
  String get incomeAllocationSavings => 'Épargne';

  @override
  String get payCycleSemiMonthly => 'Deux fois par mois';

  @override
  String get payCycleBiweekly => 'Tous les 14 jours';

  @override
  String get payCycleMonthly => 'Mensuel';

  @override
  String get payCycleWeekly => 'Hebdomadaire';

  @override
  String get payCycleIrregular => 'Sans date fixe';

  @override
  String get cashResolutionExpense => 'Dépense retrouvée';

  @override
  String get cashResolutionIncome => 'Rentrée en espèces';

  @override
  String get cashResolutionTransfer => 'Virement entre comptes';

  @override
  String get cashResolutionCorrection => 'Correction du comptage';

  @override
  String get cashResolutionPending => 'Écart à identifier';

  @override
  String get paymentMethodCash => 'Espèces';

  @override
  String get paymentMethodCard => 'Carte';

  @override
  String get movementPending => 'En attente';

  @override
  String get movementCashCount => 'Comptage du liquide';

  @override
  String get xpCashCountTitle => 'Comptage du liquide';

  @override
  String get xpCashCountDetail => 'Premier comptage avec XP de la semaine';

  @override
  String get xpCycleInGreenSemiMonthly =>
      'Tu as fini la quinzaine dans le vert';

  @override
  String get xpCycleInGreenMonthly => 'Tu as fini le mois dans le vert';

  @override
  String get xpCycleInGreenWeekly => 'Tu as fini la semaine dans le vert';

  @override
  String get xpCycleInGreenGeneric => 'Tu as fini le cycle dans le vert';

  @override
  String get xpCycleInGreenDetail => 'Où en était le budget à la clôture';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours sous ta limite',
      one: '$count jour sous ta limite',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail =>
      'Calculé une seule fois, à la clôture';

  @override
  String get xpFirstSuccessfulCycleTitle => 'Premier cycle dans le vert';

  @override
  String get xpFirstSuccessfulCycleDetail => 'Bonus unique';

  @override
  String xpLevelTitle1(String name) {
    return 'Novice $name';
  }

  @override
  String xpLevelTitle2(String name) {
    return 'Économe $name';
  }

  @override
  String xpLevelTitle3(String name) {
    return 'Comptable $name';
  }

  @override
  String xpLevelTitle4(String name) {
    return 'Sentinelle $name';
  }

  @override
  String xpLevelTitle5(String name) {
    return 'Virtuose $name';
  }

  @override
  String xpLevelTitle6(String name) {
    return 'Spécialiste $name';
  }

  @override
  String xpLevelTitle7(String name) {
    return 'Stratège $name';
  }

  @override
  String xpLevelTitle8(String name) {
    return 'Prospère $name';
  }

  @override
  String xpLevelTitle9(String name) {
    return 'Sage $name';
  }

  @override
  String xpLevelTitle10(String name) {
    return 'Légende $name';
  }

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cycles clôturés',
      one: 'Cycle clôturé',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP ajoutés automatiquement.';

  @override
  String get xpNoticeCashCountTitle => 'Comptage enregistré';

  @override
  String get xpNoticeCashCountDetail =>
      'Premier comptage avec XP de la semaine.';

  @override
  String xpLevelUpTitle(int level) {
    return 'NIVEAU $level !';
  }

  @override
  String get xpLevelUpContinue => 'Continuer';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux objets débloqués !',
      one: 'Nouvel objet débloqué !',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => 'Mission du jour';

  @override
  String get dailyMissionResetHint =>
      'Elles changent à minuit. Elles ne s’accumulent pas.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done sur $total faites';
  }

  @override
  String get dailyMissionAllDone => 'Tout est fait';

  @override
  String get dailyMissionRecordTitle => 'Note quelque chose aujourd’hui';

  @override
  String get dailyMissionRecordHint => 'Une dépense ou une rentrée';

  @override
  String get dailyMissionSameDayTitle => 'Note-le le jour même';

  @override
  String get dailyMissionSameDayHint => 'La dépense et la saisie, aujourd’hui';

  @override
  String get dailyMissionBudgetTitle => 'Jette un œil au budget';

  @override
  String get dailyMissionBudgetHint => 'Ouvre l’onglet Budget';

  @override
  String get dailyMissionNoteTitle => 'Ajoute une note';

  @override
  String get dailyMissionNoteHint => 'Une opération avec une note';

  @override
  String get dailyMissionReceiptTitle => 'Garde un ticket';

  @override
  String get dailyMissionReceiptHint => 'Joins la photo à une dépense';

  @override
  String get dailyMissionThreeTodayTitle => 'Note-en trois aujourd’hui';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '$count opérations datées d’aujourd’hui';
  }

  @override
  String get dailyMissionDone => 'Faite';

  @override
  String get dailyMissionPending => 'À faire';

  @override
  String dailyMissionReadyAt(String time) {
    return 'Faite · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done sur $total faites · +$earned XP sur +$possible XP aujourd’hui';
  }

  @override
  String get dailyMissionXpDetail => 'Mission accomplie';

  @override
  String get xpRuleDailyMission =>
      'Une fois par jour ; à minuit, on recommence';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missions faites',
      one: 'Mission faite',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => 'XP pour l’habitude du jour.';

  @override
  String get storeFailureGeneric =>
      'Impossible d’enregistrer la modification. Réessaie.';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      'Le total doit dépasser les rentrées déjà réservées à ce cycle.';

  @override
  String get storeFailureFutureMovement =>
      'Impossible de noter quelque chose daté dans le futur.';

  @override
  String get storeFailureRestoreFailed =>
      'Impossible de restaurer la sauvegarde.';

  @override
  String get storeFailureOriginalNotKept =>
      'Impossible de conserver le fichier d’origine.';

  @override
  String get storeFailureBackupNotSaved =>
      'Impossible d’enregistrer la sauvegarde.';

  @override
  String get storeFailureSaveFailed => 'Impossible d’enregistrer tes données.';

  @override
  String get monthAbbr1 => 'janv.';

  @override
  String get monthAbbr2 => 'févr.';

  @override
  String get monthAbbr3 => 'mars';

  @override
  String get monthAbbr4 => 'avr.';

  @override
  String get monthAbbr5 => 'mai';

  @override
  String get monthAbbr6 => 'juin';

  @override
  String get monthAbbr7 => 'juil.';

  @override
  String get monthAbbr8 => 'août';

  @override
  String get monthAbbr9 => 'sept.';

  @override
  String get monthAbbr10 => 'oct.';

  @override
  String get monthAbbr11 => 'nov.';

  @override
  String get monthAbbr12 => 'déc.';

  @override
  String dateShort(String day, String month) {
    return '$day $month';
  }

  @override
  String dateFull(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String get back => 'Retour';

  @override
  String get reduceMotion => 'Réduire les animations';

  @override
  String get catMotionIdle => 'Le chat se repose tranquillement';

  @override
  String get catMotionWalk => 'Le chat se promène';

  @override
  String get catMotionCalculate => 'Le chat fait les calculs';

  @override
  String get catMotionSaving => 'Le chat met des pièces dans la tirelire';

  @override
  String get catMotionCelebrate => 'Le chat fait la fête';

  @override
  String get catMotionConcern => 'Le chat s’inquiète pour le budget';

  @override
  String get characterRoleIdle => 'Le personnage se repose tranquillement';

  @override
  String get characterRoleActivity => 'Le personnage bouge';

  @override
  String get characterRoleProcessing => 'Le personnage fait les calculs';

  @override
  String get characterRolePositive =>
      'Le personnage montre un changement positif';

  @override
  String get characterRoleSuccess => 'Le personnage fait la fête';

  @override
  String get characterRoleWarning => 'Le personnage a l’air inquiet';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get cancel => 'Annuler';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabMovements => 'Activité';

  @override
  String get tabRegister => 'Ajouter';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabSettings => 'Profil';

  @override
  String get collectionTitle => 'Collection';

  @override
  String get collectionSettingsValue => 'Voir';

  @override
  String get collectionCharacters => 'Personnages';

  @override
  String get collectionItems => 'Objets';

  @override
  String collectionLevel(int level) {
    return 'NIVEAU $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned sur $total';
  }

  @override
  String get collectionCharactersHint => 'Rassemble tes compagnons';

  @override
  String get collectionItemsHint => 'Rassemble ce qui va chez toi';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'Personnage $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'Objet $number';
  }

  @override
  String get collectionEquipped => 'ÉQUIPÉ';

  @override
  String get collectionOwned => 'OBTENU';

  @override
  String get collectionPlaceIt => 'Placer';

  @override
  String get collectionBuy => 'ACHETER';

  @override
  String get collectionWatchAd => 'VOIR LA PUB';

  @override
  String get collectionAdLoading => 'CHARGEMENT';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'Regarde des pubs récompensées · $progress/$target · une par jour';
  }

  @override
  String get collectionAdUnavailable => 'PAS DE PUB';

  @override
  String get collectionAdDailyCap => 'LIMITE DU JOUR';

  @override
  String get collectionAdTomorrow => 'SUITE DEMAIN';

  @override
  String collectionUnlockedNotice(String name) {
    return '$name est à toi !';
  }

  @override
  String get collectionAdDismissedNotice =>
      'Regarde la pub en entier pour qu’elle compte.';

  @override
  String get collectionPackOnly => 'PACK';

  @override
  String get collectionPackDecoration => 'L’étoile de Michi';

  @override
  String get collectionPackUnlock =>
      'Arrive avec Michi et ses amis. Pas vendu séparément.';

  @override
  String get collectionGiftOnly => 'CADEAU';

  @override
  String get collectionGiftUnlock =>
      'Un cadeau spécial. Il n’est pas en vente.';

  @override
  String collectionAdProgress(int progress, int target) {
    return 'PUB $progress/$target';
  }

  @override
  String get collectionHowToGet => 'COMMENT L’OBTENIR';

  @override
  String get collectionAlreadyOwned => 'Fait déjà partie de ta collection.';

  @override
  String get collectionIncludedUnlock => 'Inclus dès le départ.';

  @override
  String collectionPurchaseUnlock(String price) {
    return 'Achat unique · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'Regarde des pubs récompensées · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'Se débloque au niveau $level.';
  }

  @override
  String get collectionStorePricePending => 'prix du store';

  @override
  String get collectionPreviewActionNotice =>
      'Les achats et les pubs seront branchés plus tard.';

  @override
  String get roomTitle => 'Ma maison';

  @override
  String get roomOpen => 'Ouvrir ma maison';

  @override
  String get roomDecorate => 'Décorer';

  @override
  String get roomDecorateTitle => 'Décorer';

  @override
  String get roomDone => 'Terminé';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => 'Maison jardin';

  @override
  String get roomThemeCasaDePlaya => 'Maison de plage';

  @override
  String get roomChooseTheme => 'Choisis l’ambiance de ta maison.';

  @override
  String get roomCatReaction => 'Tu as super bien géré aujourd’hui !';

  @override
  String get roomInstruction =>
      'Choisis un objet, puis touche l’endroit où il va.';

  @override
  String get roomCategoryRooms => 'Pièce';

  @override
  String get roomCategoryFurniture => 'Meubles';

  @override
  String get roomCategoryWallFloor => 'Mur et sol';

  @override
  String get roomCategoryProps => 'Déco';

  @override
  String get roomCategoryCharacters => 'Personnages';

  @override
  String get roomCharacterInstruction => 'Choisis qui te tient compagnie.';

  @override
  String get roomMoreInCollection => 'Plus dans la collection';

  @override
  String get roomDefaultRug => 'Tapis lavande';

  @override
  String get roomFloorLamp => 'Lampe verte';

  @override
  String get roomTablePlant => 'Plante de table';

  @override
  String get roomWallFrame => 'Tableau';

  @override
  String get roomRattanChair => 'Fauteuil en rotin';

  @override
  String get roomStandingLamp => 'Lampadaire';

  @override
  String get roomWallClock => 'Horloge murale';

  @override
  String get roomLowCabinet => 'Buffet bas';

  @override
  String get roomPetBed => 'Panier pour animal';

  @override
  String get roomSavingsJar => 'Bocal d’économies';

  @override
  String get roomWallShelf => 'Étagère murale';

  @override
  String get roomTerracottaPouf => 'Pouf terracotta';

  @override
  String get roomBlueCreamRug => 'Tapis bleu et crème';

  @override
  String get roomLaunchSofa => 'Canapé en velours';

  @override
  String get roomLaunchTv => 'Télé des histoires';

  @override
  String get launchGiftTitle => 'Votre cadeau de lancement est arrivé !';

  @override
  String get launchGiftBody =>
      'Vous avez commencé Sobrita à temps. Le canapé et la télé sont à vous.';

  @override
  String get launchGiftGoToRoom => 'Les placer chez moi';

  @override
  String get launchGiftLater => 'Plus tard';

  @override
  String get roomSuggestCabinet =>
      'Mets-le contre le mur de gauche. Touche l’endroit en surbrillance.';

  @override
  String get roomSuggestPetBed =>
      'Mets-le à gauche de ton compagnon. Touche l’endroit en surbrillance.';

  @override
  String get roomSuggestSavingsJar =>
      'Essaie la table ou le petit coin au sol. Touche un endroit en surbrillance.';

  @override
  String get roomSuggestWallShelf =>
      'Accroche-la sur un mur libre. Touche un endroit en surbrillance.';

  @override
  String get roomSuggestPouf =>
      'Équilibre la pièce à droite. Touche l’endroit en surbrillance.';

  @override
  String get roomSuggestBlueRug =>
      'Pose-le sous ton compagnon. Touche l’endroit en surbrillance.';

  @override
  String get roomSaved => 'Ta maison est enregistrée.';

  @override
  String get roomPlaced => 'Placé';

  @override
  String get roomSurfaceWall => 'Mur';

  @override
  String get roomSurfaceFloor => 'Sol';

  @override
  String get roomSurfaceTabletop => 'Table';

  @override
  String get roomSurfaceRug => 'Tapis';

  @override
  String roomSlotLabel(String surface, int number) {
    return '$surface, place $number';
  }

  @override
  String roomPickWall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count places au mur. Touche là où ça va.',
      one: 'Il y a une place au mur. Touche-la pour l’accrocher.',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count places au sol. Touche là où ça va.',
      one: 'Il y a une place au sol. Touche-la pour le poser.',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count places sur la table. Touche là où ça va.',
      one: 'Il y a une place sur la table. Touche-la pour le poser.',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count places pour un tapis. Touche là où ça va.',
      one: 'Il y a une place pour un tapis. Touche-la pour le poser.',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count places possibles. Touche là où ça va.',
      one: 'Il y a une place possible. Touche-la pour le poser.',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove =>
      'Touche une autre place pour le déplacer, ou la sienne pour le retirer.';

  @override
  String get roomTapToRemove => 'Touche encore sa place pour le retirer.';

  @override
  String get xpHistoryTitle => 'Ta progression';

  @override
  String xpTotal(int count) {
    return '$count XP au total';
  }

  @override
  String get xpMaxLevel => 'Niveau max';

  @override
  String xpRemaining(int count) {
    return 'Encore $count XP';
  }

  @override
  String get xpHistoryHint =>
      'Les XP s’ajoutent tout seuls. Chaque ligne garde la raison et le calcul, même si tu fermes l’app.';

  @override
  String get xpHistoryEmptyTitle => 'Pas encore d’XP';

  @override
  String get xpHistoryEmptyMessage =>
      'Ton premier comptage de la semaine et la clôture de ton cycle apparaîtront ici.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => 'Voir le calcul';

  @override
  String get xpCalculationTitle => 'Comment on a calculé';

  @override
  String get xpDetailCycle => 'Cycle';

  @override
  String get xpDetailBudget => 'Budget';

  @override
  String get xpDetailSpent => 'Dépensé';

  @override
  String get xpDetailResult => 'Résultat';

  @override
  String get xpDetailRule => 'Règle';

  @override
  String get xpDetailCredited => 'XP ajoutés';

  @override
  String get xpRuleCashCount => 'Une fois par semaine au plus';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récompense ramenée à $count jours',
      one: 'Récompense ramenée à $count jour',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours × 5 XP',
      one: '$count jour × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => 'Bonus unique de 50 XP';

  @override
  String get recoveryNotYet =>
      'Impossible de récupérer tes données pour l’instant.';

  @override
  String get recoveryStartFreshQuestion => 'Tout recommencer ?';

  @override
  String get recoveryStartFreshBody =>
      'On garde une copie du fichier d’origine avant de créer de nouvelles données.';

  @override
  String get recoveryStartFresh => 'Tout recommencer';

  @override
  String get recoveryTitle => 'Impossible de lire tes données';

  @override
  String get recoveryOriginalKept =>
      'Le fichier d’origine est toujours là. On ne l’a ni remplacé ni supprimé.';

  @override
  String get recoveryOptions =>
      'Tu peux réessayer, utiliser la sauvegarde ou exporter le fichier pour le garder.';

  @override
  String get recoveryRetrying => 'Nouvel essai…';

  @override
  String get recoveryRetry => 'Réessayer';

  @override
  String get recoveryUseBackup => 'Utiliser la sauvegarde';

  @override
  String get recoveryExport => 'Exporter le fichier';

  @override
  String get recoveryExported => 'Fichier d’origine copié.';

  @override
  String get settingsTitle => 'Mon Sobrita';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String currencyChangeTitle(String code) {
    return 'Passer en $code ?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return 'Tes montants ne sont pas convertis : $example reste $converted. Seule l’étiquette change.';
  }

  @override
  String get currencyChangeConfirm => 'Changer l’étiquette';

  @override
  String get currencyRegionAmericas => 'Amériques';

  @override
  String get currencyRegionEurope => 'Europe';

  @override
  String get currencyRegionAsiaPacific => 'Asie et Océanie';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsBudgetCycle => 'Cycle';

  @override
  String get settingsCountDay => 'Jour de comptage';

  @override
  String get settingsReduceMotionHint =>
      'S’active tout seul si ton téléphone le demande déjà.';

  @override
  String get settingsQuickEntry => 'Saisie rapide';

  @override
  String get settingsQuickEntryHint =>
      'Affiche Rentrée et Dépense sur l’écran verrouillé.';

  @override
  String get quickEntryQuestion => 'Que veux-tu noter ?';

  @override
  String get quickEntryDenied =>
      'Autorise les notifications de Sobrita pour activer la saisie rapide.';

  @override
  String get widgetTodayLeft => 'Reste du jour';

  @override
  String get widgetCycleBalance => 'Solde';

  @override
  String get widgetOpenApp => 'Ouvrir Sobrita';

  @override
  String get widgetRegisterExpense => 'Noter une dépense';

  @override
  String get settingsBackup => 'Sauvegarde des données';

  @override
  String get settingsCopy => 'Copier';

  @override
  String get settingsBackupCopied =>
      'Sauvegarde copiée dans le presse-papiers.';

  @override
  String get settingsRestorePurchases => 'Restaurer les achats';

  @override
  String get settingsAccount => 'Compte Google';

  @override
  String get settingsAccountConnect => 'Connecter';

  @override
  String get settingsRestore => 'Restaurer';

  @override
  String get purchaseRestored => 'C’est fait. Tes achats sont de retour.';

  @override
  String get purchaseFailureStoreUnavailable =>
      'Le store n’est pas disponible pour le moment. Réessaie plus tard.';

  @override
  String get purchaseFailureRejected =>
      'L’achat n’a pas pu aboutir. Rien ne t’a été débité.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      'Ton achat est arrivé mais n’a pas pu être enregistré. Il sera appliqué à la prochaine ouverture de Sobrita.';

  @override
  String get purchaseFailureNothingToRestore =>
      'Aucun achat trouvé sur ce compte.';

  @override
  String get collectionPurchasing => 'ACHAT…';

  @override
  String get settingsXpPreview => 'Aperçu XP';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsStorageNote =>
      'Tes données restent sur cet appareil. Pas besoin de compte pour utiliser Sobrita.';

  @override
  String get settingsSectionShop => 'Boutique';

  @override
  String get settingsRemoveAds => 'Retirer les pubs générales';

  @override
  String get settingsRemoveAdsHint =>
      'Retire les pubs de l’activité. Les pubs récompensées restent disponibles.';

  @override
  String get settingsPackName => 'Michi et ses amis';

  @override
  String get settingsPackHint =>
      '3 personnages + l’étoile de Michi. Retire aussi les pubs générales.';

  @override
  String get settingsOwned => 'Acheté';

  @override
  String get settingsShopRestoreNote =>
      'Les achats restent liés à ton compte du store. Tu peux les récupérer après une réinstallation.';

  @override
  String get settlementTitle => 'Clôture du cycle';

  @override
  String get settlementSpent => 'Dépensé';

  @override
  String get settlementLeft => 'Il reste';

  @override
  String get settlementOver => 'Dépassé';

  @override
  String get settlementAverage => 'Moyenne par jour';

  @override
  String get settlementContinue => 'Terminé';

  @override
  String get settlementCtaTitle => 'Va chercher une déco spéciale';

  @override
  String get settlementCtaAction => 'Voir la collection';

  @override
  String get settingsSectionBudget => 'Budget';

  @override
  String get settingsSectionScreen => 'Affichage';

  @override
  String get settingsSectionData => 'Données';

  @override
  String get settingsSectionPrivacy => 'Confidentialité';

  @override
  String get settingsAdPrivacy => 'Confidentialité des pubs';

  @override
  String get settingsAdPrivacyValue => 'Gérer';

  @override
  String get settingsAdPrivacyFailed =>
      'Impossible d’ouvrir les choix de confidentialité. Réessaie.';

  @override
  String get settingsSectionDesign => 'Design';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '$movements opérations',
      one: '$movements opération',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours avec Sobrita',
      one: '$days jour avec Sobrita',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => 'Automatique';

  @override
  String get languageAutomaticHint => 'Comme ton téléphone';

  @override
  String get transactionsTitle => 'Activité';

  @override
  String get dailySpendTitle => 'Dépenses par jour';

  @override
  String dailySpendLimit(String amount) {
    return '$amount par jour';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return 'Ce cycle $amount';
  }

  @override
  String get dailyIncomeTitle => 'Rentrées par jour';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return 'Ce cycle $amount';
  }

  @override
  String get transactionsEmptyTitle => 'Rien pour l’instant';

  @override
  String get transactionsEmptyMessage =>
      'Note ta première dépense et le résumé du cycle s’affichera ici.';

  @override
  String get transactionsEmptyExpensesTitle => 'Pas encore de dépenses';

  @override
  String get transactionsEmptyExpensesMessage =>
      'Note une dépense et tu verras ici le jour par jour.';

  @override
  String get transactionsEmptyIncomesTitle => 'Pas encore de rentrées';

  @override
  String get transactionsEmptyIncomesMessage =>
      'Note une rentrée et tu verras ici le jour par jour.';

  @override
  String get transactionsExpensePinned =>
      'Cette dépense vient d’un comptage du liquide. Recompte pour la corriger.';

  @override
  String get transactionsIncomePinned =>
      'Cette rentrée vient d’un comptage du liquide. Recompte pour la corriger.';

  @override
  String get transactionsExpenseDeleted => 'Dépense supprimée.';

  @override
  String get transactionsIncomeDeleted => 'Rentrée supprimée.';

  @override
  String get undo => 'Annuler';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get identifyDifference => 'Expliquer l’écart';

  @override
  String get editMovement => 'Modifier l’opération';

  @override
  String get amount => 'Montant';

  @override
  String get editPendingHint =>
      'Le montant vient de ton comptage du liquide. Tu peux quand même changer la catégorie et la note.';

  @override
  String get category => 'Catégorie';

  @override
  String get note => 'Note';

  @override
  String get noteExample => 'Ex. : Croissants';

  @override
  String get replacesPendingHint =>
      'Ceci remplace l’ajustement en attente. Ça n’ajoute pas une autre dépense.';

  @override
  String get saveWithoutDuplicating => 'Enregistrer sans doublon';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get save => 'Enregistrer';

  @override
  String get budget => 'Budget';

  @override
  String get spent => 'Dépensé';

  @override
  String get appName => 'Sobrita';

  @override
  String get homeCycleBalance => 'Solde du cycle';

  @override
  String get homeTodayLeft => 'Il te reste aujourd’hui';

  @override
  String homeOverBudget(String budget) {
    return 'Tu as dépassé le budget de $budget de ce cycle';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return 'Limite du jour $limit · $remaining restants dans le cycle';
  }

  @override
  String get homeFirstQuestLabel => 'Première quête';

  @override
  String get homeBudgetQuestBody =>
      'Fixe un budget et je calcule ce que tu peux dépenser chaque jour.';

  @override
  String get homeCycleProgress => 'Avancée du cycle';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => 'Liquide estimé';

  @override
  String get homeCashUnset => 'Liquide non configuré';

  @override
  String homeLastCount(String amount) {
    return 'Dernier comptage : $amount';
  }

  @override
  String get homeFirstCountHint => 'Fais un premier comptage pour commencer.';

  @override
  String get homeRecentMovements => 'Activité récente';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeGoingWell => 'Ça roule';

  @override
  String get homeAdjustCalmly => 'On ajuste, tranquillement';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetCycleTotal => 'Total du cycle';

  @override
  String get budgetTotal => 'Budget total';

  @override
  String get budgetNotSetTitle => 'Pas encore de budget';

  @override
  String get budgetNotSetBody =>
      'Fixe-le et on calcule ce que tu peux dépenser chaque jour.';

  @override
  String get budgetSetAction => 'Fixer un budget';

  @override
  String budgetTooLow(String allocated) {
    return 'Le total doit dépasser les rentrées déjà réservées à ce cycle ($allocated).';
  }

  @override
  String budgetSpentShare(int percent) {
    return '$percent % du budget';
  }

  @override
  String budgetRingSpent(String amount) {
    return 'Dépensé $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return 'Reste $amount';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent %';
  }

  @override
  String get cycleHistoryTitle => 'Cycles précédents';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$green cycles sur $total dans le vert',
      one: '$green cycle sur $total dans le vert',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return 'Budget $budget · Dépensé $spent';
  }

  @override
  String get cycleHistoryEmpty => 'Aucun cycle n’est encore clôturé.';

  @override
  String cycleHistoryAverage(String amount) {
    return 'Moyenne par jour $amount';
  }

  @override
  String get cycleHistoryAveragePending =>
      'Moyenne par jour · en cours de calcul';

  @override
  String get budgetChangedTitle => 'Tu as changé ton budget';

  @override
  String get budgetChangedBody =>
      'Que fait-on des limites par catégorie ? En les ajustant, chacune bouge dans la même proportion et ta répartition reste la tienne.';

  @override
  String get budgetKeepLimits => 'Les garder';

  @override
  String get budgetScaleLimits => 'Les ajuster en proportion';

  @override
  String get budgetByCategory => 'Budget par catégorie';

  @override
  String budgetCategoryLimit(String category) {
    return 'Limite $category';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => 'Prévision à la clôture';

  @override
  String get budgetEstimatedLeft => 'Ce qu’il devrait te rester';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get saving => 'Enregistrement…';

  @override
  String dayOfMonth(int day) {
    return 'Le $day';
  }

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get weekdayShortMonday => 'Lun';

  @override
  String get weekdayShortTuesday => 'Mar';

  @override
  String get weekdayShortWednesday => 'Mer';

  @override
  String get weekdayShortThursday => 'Jeu';

  @override
  String get weekdayShortFriday => 'Ven';

  @override
  String get weekdayShortSaturday => 'Sam';

  @override
  String get weekdayShortSunday => 'Dim';

  @override
  String get registerTitle => 'Ajouter';

  @override
  String get registerExpense => 'Dépense';

  @override
  String get registerIncome => 'Rentrée';

  @override
  String get registerAmountAboveZero => 'Saisis un montant supérieur à zéro.';

  @override
  String get registerNoFutureMovements =>
      'Impossible de noter quelque chose daté dans le futur.';

  @override
  String get registerDate => 'Date';

  @override
  String get registerNoteExpenseExample => 'Ex. : Boulangerie du coin';

  @override
  String get registerNoteIncomeExample => 'Ex. : Pourboires de vendredi';

  @override
  String get receiptTitle => 'Ticket';

  @override
  String get receiptAdd => 'Ajouter un ticket';

  @override
  String get receiptCamera => 'Appareil photo';

  @override
  String get receiptGallery => 'Galerie';

  @override
  String get receiptChange => 'Remplacer';

  @override
  String get receiptRemove => 'Retirer';

  @override
  String get receiptHint =>
      'Une photo pour te rappeler ce qu’était cette dépense.';

  @override
  String get receiptAttached => 'Ticket joint';

  @override
  String get receiptView => 'Voir le ticket';

  @override
  String get receiptClose => 'Fermer';

  @override
  String get receiptMissing => 'La photo n’est plus sur cet appareil.';

  @override
  String get receiptFailed => 'Impossible d’enregistrer la photo.';

  @override
  String get receiptBackupNote =>
      'La sauvegarde n’inclut pas les photos des tickets.';

  @override
  String get registerPayment => 'Paiement';

  @override
  String get registerPaymentHint =>
      'Les espèces sont déduites de ton comptage. La carte, non.';

  @override
  String get registerIncomeKind => 'Type de rentrée';

  @override
  String get registerWhatToDo => 'Que veux-tu faire ?';

  @override
  String get registerThisCycle => 'Ce cycle';

  @override
  String get registerSaveIt => 'L’épargner';

  @override
  String get registerReceivedIn => 'Reçu en';

  @override
  String get registerAccount => 'Compte';

  @override
  String get registerReconcileQuestion =>
      'Cette dépense explique-t-elle l’écart ?';

  @override
  String registerReconcileBody(String amount) {
    return 'Il reste $amount en attente de ton dernier comptage. Si c’est la même dépense, on les rapproche sans la compter deux fois.';
  }

  @override
  String get registerReconcileNo => 'Non, elle est nouvelle';

  @override
  String get registerReconcileYes => 'Oui, rapprocher';

  @override
  String get registerDifferenceReconciled => 'Écart rapproché';

  @override
  String get registerExpenseSaved => 'Dépense enregistrée';

  @override
  String get registerIncomeSaved => 'Rentrée enregistrée';

  @override
  String get cashCountTitle => 'Comptage du liquide';

  @override
  String get cashCountPickWhatHappened => 'Choisis ce qui explique l’écart.';

  @override
  String get cashCountSavedWithoutDuplicates =>
      'Comptage enregistré, sans doublon.';

  @override
  String get cashCountPrompt =>
      'Compte seulement le liquide que tu as sur toi maintenant.';

  @override
  String get cashCountNoneYet => 'Pas encore de comptage';

  @override
  String get cashCountResultPending =>
      'Le résultat s’affiche une fois le comptage saisi.';

  @override
  String get cashCountBaselineHint =>
      'Ce sera ton point de départ. Il ne sera pas noté comme une rentrée.';

  @override
  String get cashCountExpected => 'Attendu';

  @override
  String get cashCountCounted => 'Compté';

  @override
  String get cashCountBalanced => 'Tout tombe juste';

  @override
  String cashCountShort(String amount) {
    return 'Il manque $amount';
  }

  @override
  String cashCountExtra(String amount) {
    return '$amount en trop';
  }

  @override
  String get cashCountWhatHappened => 'Que s’est-il passé ?';

  @override
  String get cashCountHelperExpense =>
      'C’était une dépense que tu n’avais pas notée.';

  @override
  String get cashCountHelperIncome => 'C’était de l’argent que tu as reçu.';

  @override
  String get cashCountHelperTransferOut =>
      'Tu l’as déposé ou mis sur un autre compte.';

  @override
  String get cashCountHelperTransferIn =>
      'Tu l’as retiré ou pris sur un autre compte.';

  @override
  String get cashCountHelperCorrection => 'Le comptage précédent était faux.';

  @override
  String get cashCountHelperPending => 'Décider plus tard.';

  @override
  String get cashCountSingleExpenseHint =>
      'Ça crée une seule dépense. Tu n’auras pas à la noter à nouveau.';

  @override
  String get cashCountNoteTipExample => 'Ex. : Pourboire';

  @override
  String get cashCountWhatToDoWithMoney => 'Que fait-on de cet argent ?';

  @override
  String get cashCountSaveFirst => 'Enregistrer le premier comptage';

  @override
  String get cashCountSave => 'Enregistrer le comptage';

  @override
  String get cycleTitle => 'Ton cycle';

  @override
  String get cycleCurrent => 'Cycle en cours';

  @override
  String get cycleInProgress => 'En cours';

  @override
  String get cycleUnchanged => 'Ne change pas';

  @override
  String get cycleNewFrequency => 'Nouveau rythme';

  @override
  String get cycleFirstPay => 'Première paie';

  @override
  String get cyclePayDay => 'Jour de paie';

  @override
  String get cycleNext => 'Cycle suivant';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return 'Le changement s’applique au cycle suivant, puis se renouvelle tous les $days jours.';
  }

  @override
  String get cycleChangeApplies => 'Le changement s’applique au cycle suivant.';

  @override
  String get cycleSaveChange => 'Enregistrer le changement';

  @override
  String get onboardingBudgetAboveZero => 'Saisis un budget supérieur à zéro.';

  @override
  String get onboardingCashOrSkip =>
      'Saisis ton liquide ou choisis « Plus tard ».';

  @override
  String get prologueRainNoEnd => 'La pluie ne voulait pas s’arrêter.';

  @override
  String get prologueRentPaid =>
      'Le loyer était payé, et ce qui restait sur le compte devait tenir jusqu’à la paie.';

  @override
  String get prologueSoundAtDoor => 'Quelque chose a bougé près de la porte.';

  @override
  String get prologueGoLook => 'Aller voir';

  @override
  String get prologueWetTracks =>
      'Deux rangées d’empreintes mouillées traversaient le sol.';

  @override
  String get prologueShelter => 'Laisse-nous attendre que la pluie passe.';

  @override
  String get prologueItSpoke => '… ça a parlé.';

  @override
  String get prologueReplySurprised => 'Tu viens de parler ?';

  @override
  String get prologueReplyTowel =>
      '(tu vas chercher une serviette sans rien dire)';

  @override
  String get prologueEarnKeep =>
      'Je dois me rendre utile. Je m’occupe des chiffres.';

  @override
  String get prologueAskSchedule =>
      'D’abord : quand est-ce que l’argent rentre ?';

  @override
  String get prologueAskPayday =>
      'Quel jour es-tu payé ? Donne-moi le premier, je compte le reste.';

  @override
  String prologueAskBudget(int days) {
    return 'Encore $days jours avant la prochaine paie. Combien comptes-tu dépenser ?';
  }

  @override
  String get prologueSkipIsFine =>
      'Tu peux passer. Je redemanderai une fois à la maison.';

  @override
  String get prologueSkip => 'Passer';

  @override
  String get prologueDriedOff =>
      'Une fois séchés, tous les deux se sont calmés. Dehors, il pleuvait encore.';

  @override
  String get prologueWhoSits => 'Qui s’assoit avec toi ?';

  @override
  String get prologueMichiTrait => 'Calme.\nDoué avec les chiffres.';

  @override
  String get prologuePoodleTrait => 'Plein d’énergie.\nVeille sur toi.';

  @override
  String get prologueSchnauzerTrait => 'Réfléchi.\nMonte la garde.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'Plein d’énergie.\nVeille sur toi.';

  @override
  String get prologueLockedSoon => 'Dessin en route';

  @override
  String get prologueOtherStays =>
      'L’autre reste aussi. Tu pourras changer de compagnon plus tard.';

  @override
  String get prologueLiveTogether => 'Ils peuvent rester';

  @override
  String prologueGreeting(String name) {
    return 'Je m’appelle $name. Merci d’avoir ouvert.';
  }

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingTagline => 'Ton argent, sans pression.';

  @override
  String get onboardingPromise =>
      'On te dit combien tu peux dépenser aujourd’hui.';

  @override
  String get onboardingHowPaid => 'Comment es-tu payé ?';

  @override
  String get onboardingHowPaidHint => 'Ça fixe les dates de ton budget.';

  @override
  String get onboardingCycleHelperSemiMonthly =>
      'Deux paies par mois : le 15 et le dernier jour.';

  @override
  String get onboardingCycleHelperMonthly => 'Une paie par mois.';

  @override
  String get onboardingCycleHelperWeekly => 'Chaque semaine.';

  @override
  String get onboardingCycleHelperIrregular =>
      'Mes revenus n’ont pas de date fixe.';

  @override
  String get onboardingPlanWithoutFixedDate => 'Prévoir sans date fixe';

  @override
  String get onboardingWhichDayPaid => 'Quel jour es-tu payé ?';

  @override
  String get onboardingSecondPayEndOfMonth => 'Deuxième paie · fin du mois';

  @override
  String get onboardingHowManyDays => 'Sur combien de jours veux-tu prévoir ?';

  @override
  String get onboardingCyclePreview => 'Ton cycle ressemblerait à ça';

  @override
  String onboardingRepeatsEvery(int days) {
    return 'À la fin, une nouvelle période de $days jours démarre toute seule.';
  }

  @override
  String get onboardingShortMonthsNote =>
      'Les dates s’ajustent toutes seules les mois courts.';

  @override
  String get onboardingBudgetQuestion =>
      'Combien veux-tu dépenser\nsur ce cycle ?';

  @override
  String get onboardingBudgetLater =>
      'Tu pourras le fixer plus tard depuis l’Accueil.';

  @override
  String get onboardingNotNow => 'Plus tard';

  @override
  String get onboardingCashQuestion =>
      'Combien de liquide\nas-tu aujourd’hui ?';

  @override
  String get onboardingCashOptional =>
      'Laisse vide si tu préfères compter plus tard.';

  @override
  String get onboardingCashIsBaseline =>
      'Ce sera ton premier comptage, pas une rentrée.';

  @override
  String onboardingSettledIn(String name) {
    return 'La pluie s’est arrêtée. $name s’est installé à côté de toi.';
  }

  @override
  String get onboardingFirstQuests => 'Tes premières quêtes';

  @override
  String get onboardingWaitingAtHome => 'T’attend à la maison';

  @override
  String get onboardingGoHome => 'Aller à l’Accueil';

  @override
  String get onboardingPlanReady => 'Ton plan est prêt';

  @override
  String get onboardingCanSpendToday => 'Aujourd’hui, tu peux dépenser';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step sur $total';
  }

  @override
  String progressPercent(int percent) {
    return 'Progression $percent pour cent';
  }

  @override
  String stepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly =>
      'Tu as fini les deux semaines dans le vert';

  @override
  String get onboardingCycleHelperBiweekly =>
      'Toutes les deux semaines, depuis ma dernière paie.';

  @override
  String get cycleLastPayday => 'Dernière paie';

  @override
  String get onboardingWhenLastPaid =>
      'Quand as-tu été payé la dernière fois ?';

  @override
  String get onboardingBiweeklyNeedsDate =>
      'Choisis le jour de ta dernière paie.';

  @override
  String get pickDate => 'Choisir une date';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsReleaseNotes => 'Nouveautés';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => 'Nouveautés';

  @override
  String get releaseNotesCurrent => 'Actuelle';

  @override
  String releaseNotesRetention(int count) {
    return 'On garde les $count dernières versions.';
  }

  @override
  String get releaseNote104Fixed =>
      'Les dépenses fixes restent à part du budget du jour. Elles apparaissent sur l’Accueil et peuvent te prévenir avant l’échéance.';

  @override
  String get releaseNote104Decor =>
      'La maison a plus à placer : un panier, une étagère, un tapis, un buffet, un bocal et un pouf.';

  @override
  String get releaseNote104Names =>
      'Miru, Yoshi et Cookie ont enfin un nom, et le titre de niveau porte celui de ton compagnon.';

  @override
  String get releaseNote104Widget => 'Le widget affiche le montant en entier.';

  @override
  String get releaseNote104Languages =>
      'Sobrita parle maintenant portugais, allemand, français et japonais.';

  @override
  String get releaseNote103GuineaPig =>
      'Le cochon d’Inde arrive dans la collection. Deux pubs courtes, et il reste.';

  @override
  String get releaseNote103Widget =>
      'Le widget montre avec qui tu vis, et écrit le montant comme l’app.';

  @override
  String get releaseNote102Schnauzer =>
      'Le schnauzer arrive dans la collection. Deux pubs courtes, et il reste.';

  @override
  String get releaseNote102Rooms =>
      'La maison peut être un jardin ou une plage, et un fauteuil, une lampe et une horloge sont prêts à placer.';

  @override
  String get releaseNote102Missions =>
      'Deux des trois missions du jour changent chaque jour, et celles qui demandent un effort de plus rapportent plus d’XP.';

  @override
  String get releaseNote102Amounts =>
      'Les pesos colombiens, argentins et chiliens, le réal et l’euro s’écrivent maintenant avec une virgule, comme 1.234,56.';

  @override
  String get releaseNote101Currencies =>
      'L’argent peut maintenant s’afficher en pesos colombiens, argentins et chiliens, en soles, en livres ou en yens.';

  @override
  String get releaseNote101Celebration =>
      'La fête remplit maintenant sa carte et termine son saut.';

  @override
  String get releaseNote100Launch => 'La première version de Sobrita.';

  @override
  String get updateAvailableTitle => 'Une nouvelle version est là';

  @override
  String get updateAvailableBody =>
      'Mets à jour pour avoir le dernier Sobrita.';

  @override
  String updateCurrentVersion(String version) {
    return 'Ta version : v$version';
  }

  @override
  String get updateAction => 'Mettre à jour';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateBannerMessage => 'Nouvelle version disponible';

  @override
  String get updateBannerDismiss => 'Fermer l’avis';

  @override
  String get updateStoreFailed => 'Impossible d’ouvrir Google Play.';

  @override
  String get settingsCheckUpdate => 'Chercher une mise à jour';

  @override
  String get settingsCheckUpdateBusy => 'Recherche…';

  @override
  String get settingsCheckUpdateUpToDate => 'Tu es à jour.';

  @override
  String get settingsRateApp => 'Noter Sobrita';

  @override
  String get settingsOurApps => 'Apps recommandées';

  @override
  String get ourAppsIntro => 'Faites par l’équipe de Sobrita.';

  @override
  String get ourAppsOpen => 'Voir sur Google Play';

  @override
  String get ourAppsLoopetKind => 'Routines';

  @override
  String get ourAppsLoopetBlurb =>
      'Toute ta journée dans un cercle. Vois ce qui t’attend maintenant et ensuite.';

  @override
  String get ourAppsRandomFocusKind => 'Concentration';

  @override
  String get ourAppsRandomFocusBlurb =>
      'Fais tourner la roue, laisse-la choisir la durée et concentre-toi.';

  @override
  String get releaseAnnouncementViewAll => 'Tout voir';

  @override
  String get releaseAnnouncementDone => 'Terminé';

  @override
  String get settingsReleaseNotesUnread => 'Nouveautés non lues';

  @override
  String get fixedSectionTitle => 'Dépenses fixes';

  @override
  String fixedSectionMonth(String month) {
    return '$month · à part de ton budget du jour';
  }

  @override
  String fixedPaidOfTotal(String paid, String total) {
    return 'Payé $paid sur $total';
  }

  @override
  String get fixedAdd => 'Ajouter une dépense fixe';

  @override
  String get fixedEmptyBody =>
      'Loyer, téléphone, électricité : note-les une fois et je te préviens à l’échéance. Ils ne changent pas ton budget du jour.';

  @override
  String get fixedFrequencyWeekly => 'Chaque semaine';

  @override
  String get fixedFrequencySemiMonthly => 'Deux fois par mois';

  @override
  String get fixedFrequencyMonthly => 'Chaque mois';

  @override
  String get fixedFrequencyBimonthly => 'Tous les 2 mois';

  @override
  String get fixedStatusPaid => 'Payé';

  @override
  String get fixedStatusTomorrow => 'Demain';

  @override
  String get fixedStatusOverdue => 'En retard';

  @override
  String fixedApprox(String amount) {
    return 'env. $amount';
  }

  @override
  String get fixedFormNewTitle => 'Nouvelle dépense fixe';

  @override
  String get fixedFormEditTitle => 'Modifier la dépense fixe';

  @override
  String get fixedName => 'Nom';

  @override
  String get fixedNameHint => 'Loyer, téléphone, électricité…';

  @override
  String get fixedNameRequired => 'Donne-lui un nom';

  @override
  String get fixedHowOften => 'À quelle fréquence ?';

  @override
  String get fixedNextDue => 'Prochain paiement';

  @override
  String fixedThenDates(String dates) {
    return 'Ensuite : $dates…';
  }

  @override
  String get fixedVariable => 'Le montant change à chaque fois';

  @override
  String get fixedVariableHint =>
      'Je prends ton dernier paiement comme estimation.';

  @override
  String get fixedFormNote =>
      'Ça ne change pas ton budget du jour : ton budget, c’est ce qui reste après les dépenses fixes.';

  @override
  String get fixedSave => 'Enregistrer la dépense fixe';

  @override
  String get fixedDelete => 'Supprimer la dépense fixe';

  @override
  String fixedDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get fixedDeleteBody =>
      'Les paiements déjà notés restent dans ton activité.';

  @override
  String get fixedDueToday => 'À payer aujourd’hui';

  @override
  String get fixedDueTomorrow => 'À payer demain';

  @override
  String fixedDueOn(String date) {
    return 'À payer le $date';
  }

  @override
  String fixedWasDue(String date) {
    return 'Était à payer le $date';
  }

  @override
  String get fixedHowMuch => 'Combien as-tu payé ?';

  @override
  String fixedLastTime(String amount) {
    return 'La dernière fois : $amount';
  }

  @override
  String fixedTodayUnchanged(String amount) {
    return 'Ton budget du jour reste à $amount.';
  }

  @override
  String fixedCashChange(String from, String to) {
    return 'Liquide estimé : de $from à $to';
  }

  @override
  String fixedPaidWith(String method) {
    return 'Payé par $method';
  }

  @override
  String get fixedChange => 'Changer';

  @override
  String get fixedMarkPaid => 'C’est payé';

  @override
  String get fixedNotYet => 'Pas encore';

  @override
  String get fixedBillOnly => 'J’ai juste reçu la facture';

  @override
  String fixedBillSaved(String amount) {
    return 'Noté, j’attends $amount.';
  }

  @override
  String fixedPaymentSaved(String name) {
    return '$name noté.';
  }

  @override
  String get fixedHomeLabel => 'Dépense fixe';

  @override
  String fixedHomeMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements fixes à vérifier',
      one: '$count paiement fixe à vérifier',
    );
    return '$_temp0';
  }

  @override
  String get fixedHomeSee => 'Voir';

  @override
  String get fixedIntroTitle =>
      'Ton budget, c’est pour dépenser, hors dépenses fixes';

  @override
  String fixedIntroBody(String budget, String name) {
    return 'Les dépenses fixes ne baissent pas ton budget du jour. Si tes $budget comptaient déjà « $name », baisse plutôt le budget.';
  }

  @override
  String get fixedIntroKeep => 'C’est bien comme ça';

  @override
  String get fixedIntroAdjust => 'Ajuster le budget';

  @override
  String get fixedBadge => 'Fixe';

  @override
  String get fixedNothingThisMonth => 'Rien à payer ce mois-ci.';

  @override
  String get fixedReminderLabel => 'Rappel';

  @override
  String get fixedReminderNone => 'Pas de rappel';

  @override
  String get fixedReminderSameDay => 'Le jour même';

  @override
  String get fixedReminderDayBefore => '1 jour avant';

  @override
  String get fixedReminderThreeDaysBefore => '3 jours avant';

  @override
  String get fixedReminderHint => 'Je te préviens à 9 h 00 le matin.';

  @override
  String get fixedReminderBlocked =>
      'Les notifications de Sobrita sont désactivées, je ne peux donc pas te prévenir.';

  @override
  String fixedReminderTitleToday(String name) {
    return '$name est à payer aujourd’hui';
  }

  @override
  String fixedReminderTitleTomorrow(String name) {
    return '$name est à payer demain';
  }

  @override
  String fixedReminderTitleInDays(String name, int days) {
    return '$name est à payer dans $days jours';
  }

  @override
  String fixedReminderBody(String amount, String method) {
    return '$amount · $method. Note-le dans Sobrita une fois payé.';
  }
}
