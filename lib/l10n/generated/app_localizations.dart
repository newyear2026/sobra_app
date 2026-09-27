import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ko'),
  ];

  /// No description provided for @categoryFood.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In es, this message translates to:
  /// **'Compras'**
  String get categoryShopping;

  /// No description provided for @categoryHome.
  ///
  /// In es, this message translates to:
  /// **'Hogar'**
  String get categoryHome;

  /// No description provided for @categoryServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get categoryServices;

  /// No description provided for @categoryHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In es, this message translates to:
  /// **'Educación'**
  String get categoryEducation;

  /// No description provided for @categoryEntertainment.
  ///
  /// In es, this message translates to:
  /// **'Ocio'**
  String get categoryEntertainment;

  /// No description provided for @categoryPets.
  ///
  /// In es, this message translates to:
  /// **'Mascotas'**
  String get categoryPets;

  /// No description provided for @categoryOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get categoryOther;

  /// No description provided for @incomeKindSalary.
  ///
  /// In es, this message translates to:
  /// **'Mi pago de siempre'**
  String get incomeKindSalary;

  /// No description provided for @incomeKindExtra.
  ///
  /// In es, this message translates to:
  /// **'Ingreso extra'**
  String get incomeKindExtra;

  /// No description provided for @incomeKindCash.
  ///
  /// In es, this message translates to:
  /// **'Ingreso en efectivo'**
  String get incomeKindCash;

  /// No description provided for @incomeKindRefund.
  ///
  /// In es, this message translates to:
  /// **'Devolución'**
  String get incomeKindRefund;

  /// No description provided for @incomeAllocationCycle.
  ///
  /// In es, this message translates to:
  /// **'Este ciclo'**
  String get incomeAllocationCycle;

  /// No description provided for @incomeAllocationSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get incomeAllocationSavings;

  /// No description provided for @payCycleSemiMonthly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal'**
  String get payCycleSemiMonthly;

  /// No description provided for @payCycleBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Cada 14 días'**
  String get payCycleBiweekly;

  /// No description provided for @payCycleMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get payCycleMonthly;

  /// No description provided for @payCycleWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get payCycleWeekly;

  /// No description provided for @payCycleIrregular.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha fija'**
  String get payCycleIrregular;

  /// No description provided for @cashResolutionExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto identificado'**
  String get cashResolutionExpense;

  /// No description provided for @cashResolutionIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso en efectivo'**
  String get cashResolutionIncome;

  /// No description provided for @cashResolutionTransfer.
  ///
  /// In es, this message translates to:
  /// **'Movimiento entre cuentas'**
  String get cashResolutionTransfer;

  /// No description provided for @cashResolutionCorrection.
  ///
  /// In es, this message translates to:
  /// **'Corrección del conteo'**
  String get cashResolutionCorrection;

  /// No description provided for @cashResolutionPending.
  ///
  /// In es, this message translates to:
  /// **'Diferencia por identificar'**
  String get cashResolutionPending;

  /// No description provided for @paymentMethodCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentMethodCard;

  /// No description provided for @movementPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get movementPending;

  /// No description provided for @movementCashCount.
  ///
  /// In es, this message translates to:
  /// **'Conteo de efectivo'**
  String get movementCashCount;

  /// No description provided for @xpCashCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Conteo de efectivo'**
  String get xpCashCountTitle;

  /// No description provided for @xpCashCountDetail.
  ///
  /// In es, this message translates to:
  /// **'Primer conteo con XP de la semana'**
  String get xpCashCountDetail;

  /// No description provided for @xpCycleInGreenSemiMonthly.
  ///
  /// In es, this message translates to:
  /// **'Cerraste la quincena en verde'**
  String get xpCycleInGreenSemiMonthly;

  /// No description provided for @xpCycleInGreenMonthly.
  ///
  /// In es, this message translates to:
  /// **'Cerraste el mes en verde'**
  String get xpCycleInGreenMonthly;

  /// No description provided for @xpCycleInGreenWeekly.
  ///
  /// In es, this message translates to:
  /// **'Cerraste la semana en verde'**
  String get xpCycleInGreenWeekly;

  /// No description provided for @xpCycleInGreenGeneric.
  ///
  /// In es, this message translates to:
  /// **'Cerraste el ciclo en verde'**
  String get xpCycleInGreenGeneric;

  /// No description provided for @xpCycleInGreenDetail.
  ///
  /// In es, this message translates to:
  /// **'Resultado del presupuesto al cerrar'**
  String get xpCycleInGreenDetail;

  /// How many days of a closed cycle stayed under the daily limit. Spanish and English both need a singular form here; a locale without plural agreement collapses the two cases.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} día bajo tu límite} other{{count} días bajo tu límite}}'**
  String xpDaysUnderDailyLimitTitle(int count);

  /// No description provided for @xpDaysUnderDailyLimitDetail.
  ///
  /// In es, this message translates to:
  /// **'Calculado una sola vez al cerrar'**
  String get xpDaysUnderDailyLimitDetail;

  /// No description provided for @xpFirstSuccessfulCycleTitle.
  ///
  /// In es, this message translates to:
  /// **'Primer ciclo en verde'**
  String get xpFirstSuccessfulCycleTitle;

  /// No description provided for @xpFirstSuccessfulCycleDetail.
  ///
  /// In es, this message translates to:
  /// **'Bono de una sola vez'**
  String get xpFirstSuccessfulCycleDetail;

  /// No description provided for @xpLevelTitle1.
  ///
  /// In es, this message translates to:
  /// **'Michi curioso'**
  String get xpLevelTitle1;

  /// No description provided for @xpLevelTitle2.
  ///
  /// In es, this message translates to:
  /// **'Michi ahorrador'**
  String get xpLevelTitle2;

  /// No description provided for @xpLevelTitle3.
  ///
  /// In es, this message translates to:
  /// **'Michi contador'**
  String get xpLevelTitle3;

  /// No description provided for @xpLevelTitle4.
  ///
  /// In es, this message translates to:
  /// **'Michi guardián'**
  String get xpLevelTitle4;

  /// No description provided for @xpLevelTitle5.
  ///
  /// In es, this message translates to:
  /// **'Michi maestro'**
  String get xpLevelTitle5;

  /// No description provided for @xpLevelTitle6.
  ///
  /// In es, this message translates to:
  /// **'Michi experto'**
  String get xpLevelTitle6;

  /// No description provided for @xpLevelTitle7.
  ///
  /// In es, this message translates to:
  /// **'Michi estratega'**
  String get xpLevelTitle7;

  /// No description provided for @xpLevelTitle8.
  ///
  /// In es, this message translates to:
  /// **'Michi próspero'**
  String get xpLevelTitle8;

  /// No description provided for @xpLevelTitle9.
  ///
  /// In es, this message translates to:
  /// **'Michi sabio'**
  String get xpLevelTitle9;

  /// No description provided for @xpLevelTitle10.
  ///
  /// In es, this message translates to:
  /// **'Michi leyenda'**
  String get xpLevelTitle10;

  /// Shown after settling closed cycles, when at least one of them earned XP.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Ciclo cerrado} other{{count} ciclos cerrados}}'**
  String xpNoticeCyclesClosedTitle(int count);

  /// No description provided for @xpNoticeCyclesClosedDetail.
  ///
  /// In es, this message translates to:
  /// **'XP acreditados automáticamente.'**
  String get xpNoticeCyclesClosedDetail;

  /// No description provided for @xpNoticeCashCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Conteo de efectivo guardado'**
  String get xpNoticeCashCountTitle;

  /// No description provided for @xpNoticeCashCountDetail.
  ///
  /// In es, this message translates to:
  /// **'Primer conteo con XP de la semana.'**
  String get xpNoticeCashCountDetail;

  /// Headline of the celebration card shown once when the user reaches a new level.
  ///
  /// In es, this message translates to:
  /// **'¡NIVEL {level}!'**
  String xpLevelUpTitle(int level);

  /// No description provided for @xpLevelUpContinue.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get xpLevelUpContinue;

  /// Shown inside the level-up card when that level grants collection items.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{¡Nuevo objeto desbloqueado!} other{¡{count} objetos nuevos desbloqueados!}}'**
  String xpLevelUpItemsUnlocked(int count);

  /// No description provided for @dailyMissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Misión de hoy'**
  String get dailyMissionTitle;

  /// No description provided for @dailyMissionResetHint.
  ///
  /// In es, this message translates to:
  /// **'Cambian cada medianoche. No se acumulan.'**
  String get dailyMissionResetHint;

  /// No description provided for @dailyMissionProgress.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} listas'**
  String dailyMissionProgress(int done, int total);

  /// No description provided for @dailyMissionAllDone.
  ///
  /// In es, this message translates to:
  /// **'¡Listas!'**
  String get dailyMissionAllDone;

  /// No description provided for @dailyMissionRecordTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra un movimiento hoy'**
  String get dailyMissionRecordTitle;

  /// No description provided for @dailyMissionRecordHint.
  ///
  /// In es, this message translates to:
  /// **'Un gasto o un ingreso'**
  String get dailyMissionRecordHint;

  /// No description provided for @dailyMissionSameDayTitle.
  ///
  /// In es, this message translates to:
  /// **'Anótalo el mismo día'**
  String get dailyMissionSameDayTitle;

  /// No description provided for @dailyMissionSameDayHint.
  ///
  /// In es, this message translates to:
  /// **'El gasto y el registro, hoy'**
  String get dailyMissionSameDayHint;

  /// No description provided for @dailyMissionBudgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu presupuesto'**
  String get dailyMissionBudgetTitle;

  /// No description provided for @dailyMissionBudgetHint.
  ///
  /// In es, this message translates to:
  /// **'Abre la pestaña Presupuesto'**
  String get dailyMissionBudgetHint;

  /// No description provided for @dailyMissionNoteTitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega una nota'**
  String get dailyMissionNoteTitle;

  /// No description provided for @dailyMissionNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Un movimiento con nota'**
  String get dailyMissionNoteHint;

  /// No description provided for @dailyMissionReceiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda un recibo'**
  String get dailyMissionReceiptTitle;

  /// No description provided for @dailyMissionReceiptHint.
  ///
  /// In es, this message translates to:
  /// **'Adjunta la foto a un gasto'**
  String get dailyMissionReceiptHint;

  /// No description provided for @dailyMissionThreeTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tres hoy'**
  String get dailyMissionThreeTodayTitle;

  /// No description provided for @dailyMissionThreeTodayHint.
  ///
  /// In es, this message translates to:
  /// **'{count} movimientos con fecha de hoy'**
  String dailyMissionThreeTodayHint(int count);

  /// No description provided for @dailyMissionDone.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get dailyMissionDone;

  /// No description provided for @dailyMissionPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get dailyMissionPending;

  /// No description provided for @dailyMissionReadyAt.
  ///
  /// In es, this message translates to:
  /// **'Listo · {time}'**
  String dailyMissionReadyAt(String time);

  /// No description provided for @dailyMissionBoardSummary.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} listas · +{earned} XP de +{possible} XP hoy'**
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  );

  /// No description provided for @dailyMissionXpDetail.
  ///
  /// In es, this message translates to:
  /// **'Misión completada'**
  String get dailyMissionXpDetail;

  /// No description provided for @xpRuleDailyMission.
  ///
  /// In es, this message translates to:
  /// **'Una vez al día; a medianoche empieza de nuevo'**
  String get xpRuleDailyMission;

  /// No description provided for @xpNoticeMissionTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Misión lista} other{{count} misiones listas}}'**
  String xpNoticeMissionTitle(int count);

  /// No description provided for @xpNoticeMissionDetail.
  ///
  /// In es, this message translates to:
  /// **'XP por el hábito de hoy.'**
  String get xpNoticeMissionDetail;

  /// No description provided for @storeFailureGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio. Vuelve a intentarlo.'**
  String get storeFailureGeneric;

  /// No description provided for @storeFailureBudgetBelowCycleIncome.
  ///
  /// In es, this message translates to:
  /// **'El total debe ser mayor que los ingresos asignados al ciclo.'**
  String get storeFailureBudgetBelowCycleIncome;

  /// No description provided for @storeFailureFutureMovement.
  ///
  /// In es, this message translates to:
  /// **'No se permiten movimientos futuros.'**
  String get storeFailureFutureMovement;

  /// No description provided for @storeFailureRestoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar el respaldo.'**
  String get storeFailureRestoreFailed;

  /// No description provided for @storeFailureOriginalNotKept.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conservar el archivo original.'**
  String get storeFailureOriginalNotKept;

  /// No description provided for @storeFailureBackupNotSaved.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el respaldo.'**
  String get storeFailureBackupNotSaved;

  /// No description provided for @storeFailureSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar los datos.'**
  String get storeFailureSaveFailed;

  /// No description provided for @monthAbbr1.
  ///
  /// In es, this message translates to:
  /// **'ene'**
  String get monthAbbr1;

  /// No description provided for @monthAbbr2.
  ///
  /// In es, this message translates to:
  /// **'feb'**
  String get monthAbbr2;

  /// No description provided for @monthAbbr3.
  ///
  /// In es, this message translates to:
  /// **'mar'**
  String get monthAbbr3;

  /// No description provided for @monthAbbr4.
  ///
  /// In es, this message translates to:
  /// **'abr'**
  String get monthAbbr4;

  /// No description provided for @monthAbbr5.
  ///
  /// In es, this message translates to:
  /// **'may'**
  String get monthAbbr5;

  /// No description provided for @monthAbbr6.
  ///
  /// In es, this message translates to:
  /// **'jun'**
  String get monthAbbr6;

  /// No description provided for @monthAbbr7.
  ///
  /// In es, this message translates to:
  /// **'jul'**
  String get monthAbbr7;

  /// No description provided for @monthAbbr8.
  ///
  /// In es, this message translates to:
  /// **'ago'**
  String get monthAbbr8;

  /// No description provided for @monthAbbr9.
  ///
  /// In es, this message translates to:
  /// **'sep'**
  String get monthAbbr9;

  /// No description provided for @monthAbbr10.
  ///
  /// In es, this message translates to:
  /// **'oct'**
  String get monthAbbr10;

  /// No description provided for @monthAbbr11.
  ///
  /// In es, this message translates to:
  /// **'nov'**
  String get monthAbbr11;

  /// No description provided for @monthAbbr12.
  ///
  /// In es, this message translates to:
  /// **'dic'**
  String get monthAbbr12;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @reduceMotion.
  ///
  /// In es, this message translates to:
  /// **'Reducir movimiento'**
  String get reduceMotion;

  /// No description provided for @catMotionIdle.
  ///
  /// In es, this message translates to:
  /// **'El gato descansa tranquilo'**
  String get catMotionIdle;

  /// No description provided for @catMotionWalk.
  ///
  /// In es, this message translates to:
  /// **'El gato camina'**
  String get catMotionWalk;

  /// No description provided for @catMotionCalculate.
  ///
  /// In es, this message translates to:
  /// **'El gato hace cuentas'**
  String get catMotionCalculate;

  /// No description provided for @catMotionSaving.
  ///
  /// In es, this message translates to:
  /// **'El gato guarda monedas en la alcancía'**
  String get catMotionSaving;

  /// No description provided for @catMotionCelebrate.
  ///
  /// In es, this message translates to:
  /// **'El gato celebra contento'**
  String get catMotionCelebrate;

  /// No description provided for @catMotionConcern.
  ///
  /// In es, this message translates to:
  /// **'El gato muestra preocupación por el presupuesto'**
  String get catMotionConcern;

  /// No description provided for @characterRoleIdle.
  ///
  /// In es, this message translates to:
  /// **'El personaje descansa tranquilo'**
  String get characterRoleIdle;

  /// No description provided for @characterRoleActivity.
  ///
  /// In es, this message translates to:
  /// **'El personaje está en movimiento'**
  String get characterRoleActivity;

  /// No description provided for @characterRoleProcessing.
  ///
  /// In es, this message translates to:
  /// **'El personaje está haciendo cuentas'**
  String get characterRoleProcessing;

  /// No description provided for @characterRolePositive.
  ///
  /// In es, this message translates to:
  /// **'El personaje muestra un cambio positivo'**
  String get characterRolePositive;

  /// No description provided for @characterRoleSuccess.
  ///
  /// In es, this message translates to:
  /// **'El personaje celebra un logro'**
  String get characterRoleSuccess;

  /// No description provided for @characterRoleWarning.
  ///
  /// In es, this message translates to:
  /// **'El personaje muestra preocupación'**
  String get characterRoleWarning;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabMovements.
  ///
  /// In es, this message translates to:
  /// **'Movim.'**
  String get tabMovements;

  /// No description provided for @tabRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get tabRegister;

  /// No description provided for @tabBudget.
  ///
  /// In es, this message translates to:
  /// **'Presup.'**
  String get tabBudget;

  /// No description provided for @tabSettings.
  ///
  /// In es, this message translates to:
  /// **'Mi Sobrita'**
  String get tabSettings;

  /// No description provided for @collectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Colección'**
  String get collectionTitle;

  /// No description provided for @collectionSettingsValue.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get collectionSettingsValue;

  /// No description provided for @collectionCharacters.
  ///
  /// In es, this message translates to:
  /// **'Personajes'**
  String get collectionCharacters;

  /// No description provided for @collectionGuineaPigName.
  ///
  /// In es, this message translates to:
  /// **'Cobaya'**
  String get collectionGuineaPigName;

  /// No description provided for @collectionItems.
  ///
  /// In es, this message translates to:
  /// **'Objetos'**
  String get collectionItems;

  /// No description provided for @collectionLevel.
  ///
  /// In es, this message translates to:
  /// **'NIVEL {level}'**
  String collectionLevel(int level);

  /// No description provided for @collectionOwnedCount.
  ///
  /// In es, this message translates to:
  /// **'{owned} de {total}'**
  String collectionOwnedCount(int owned, int total);

  /// No description provided for @collectionCharactersHint.
  ///
  /// In es, this message translates to:
  /// **'Reúne a quien te acompaña'**
  String get collectionCharactersHint;

  /// No description provided for @collectionItemsHint.
  ///
  /// In es, this message translates to:
  /// **'Reúne lo que va en tu espacio'**
  String get collectionItemsHint;

  /// No description provided for @collectionCharacterPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Personaje {number}'**
  String collectionCharacterPlaceholder(int number);

  /// No description provided for @collectionItemPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Objeto {number}'**
  String collectionItemPlaceholder(int number);

  /// No description provided for @collectionEquipped.
  ///
  /// In es, this message translates to:
  /// **'EQUIPADO'**
  String get collectionEquipped;

  /// No description provided for @collectionOwned.
  ///
  /// In es, this message translates to:
  /// **'OBTENIDO'**
  String get collectionOwned;

  /// No description provided for @collectionPlaceIt.
  ///
  /// In es, this message translates to:
  /// **'Colocarlo'**
  String get collectionPlaceIt;

  /// No description provided for @collectionBuy.
  ///
  /// In es, this message translates to:
  /// **'COMPRAR'**
  String get collectionBuy;

  /// No description provided for @collectionWatchAd.
  ///
  /// In es, this message translates to:
  /// **'VER ANUNCIO'**
  String get collectionWatchAd;

  /// No description provided for @collectionAdLoading.
  ///
  /// In es, this message translates to:
  /// **'PREPARANDO'**
  String get collectionAdLoading;

  /// No description provided for @collectionAdProgressLine.
  ///
  /// In es, this message translates to:
  /// **'{progress}/{target}'**
  String collectionAdProgressLine(int progress, int target);

  /// No description provided for @collectionAdUnlockDaily.
  ///
  /// In es, this message translates to:
  /// **'Mira anuncios de recompensa · {progress}/{target} · uno por día'**
  String collectionAdUnlockDaily(int progress, int target);

  /// No description provided for @collectionAdUnavailable.
  ///
  /// In es, this message translates to:
  /// **'SIN ANUNCIOS'**
  String get collectionAdUnavailable;

  /// No description provided for @collectionAdDailyCap.
  ///
  /// In es, this message translates to:
  /// **'LÍMITE DE HOY'**
  String get collectionAdDailyCap;

  /// No description provided for @collectionAdTomorrow.
  ///
  /// In es, this message translates to:
  /// **'SIGUE MAÑANA'**
  String get collectionAdTomorrow;

  /// No description provided for @collectionUnlockedNotice.
  ///
  /// In es, this message translates to:
  /// **'¡{name} es tuyo!'**
  String collectionUnlockedNotice(String name);

  /// No description provided for @collectionAdDismissedNotice.
  ///
  /// In es, this message translates to:
  /// **'Mira el anuncio completo para que cuente.'**
  String get collectionAdDismissedNotice;

  /// No description provided for @collectionPackOnly.
  ///
  /// In es, this message translates to:
  /// **'PAQUETE'**
  String get collectionPackOnly;

  /// No description provided for @collectionPackDecoration.
  ///
  /// In es, this message translates to:
  /// **'Estrella de Michi'**
  String get collectionPackDecoration;

  /// No description provided for @collectionPackUnlock.
  ///
  /// In es, this message translates to:
  /// **'Llega con Michi y sus amigos. No se vende por separado.'**
  String get collectionPackUnlock;

  /// No description provided for @collectionAdProgress.
  ///
  /// In es, this message translates to:
  /// **'ANUNCIO {progress}/{target}'**
  String collectionAdProgress(int progress, int target);

  /// No description provided for @collectionHowToGet.
  ///
  /// In es, this message translates to:
  /// **'CÓMO OBTENERLO'**
  String get collectionHowToGet;

  /// No description provided for @collectionAlreadyOwned.
  ///
  /// In es, this message translates to:
  /// **'Ya forma parte de tu colección.'**
  String get collectionAlreadyOwned;

  /// No description provided for @collectionIncludedUnlock.
  ///
  /// In es, this message translates to:
  /// **'Incluido desde el inicio.'**
  String get collectionIncludedUnlock;

  /// No description provided for @collectionPurchaseUnlock.
  ///
  /// In es, this message translates to:
  /// **'Compra única · {price}'**
  String collectionPurchaseUnlock(String price);

  /// No description provided for @collectionAdUnlock.
  ///
  /// In es, this message translates to:
  /// **'Mira anuncios de recompensa · {progress}/{target}'**
  String collectionAdUnlock(int progress, int target);

  /// No description provided for @collectionLevelUnlock.
  ///
  /// In es, this message translates to:
  /// **'Se desbloquea en el nivel {level}.'**
  String collectionLevelUnlock(int level);

  /// No description provided for @collectionStorePricePending.
  ///
  /// In es, this message translates to:
  /// **'precio de la tienda'**
  String get collectionStorePricePending;

  /// No description provided for @collectionPreviewActionNotice.
  ///
  /// In es, this message translates to:
  /// **'La compra y los anuncios se conectarán en una etapa posterior.'**
  String get collectionPreviewActionNotice;

  /// No description provided for @roomTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi casa'**
  String get roomTitle;

  /// No description provided for @roomOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir mi casa'**
  String get roomOpen;

  /// No description provided for @roomDecorate.
  ///
  /// In es, this message translates to:
  /// **'Decorar'**
  String get roomDecorate;

  /// No description provided for @roomDecorateTitle.
  ///
  /// In es, this message translates to:
  /// **'Decorar'**
  String get roomDecorateTitle;

  /// No description provided for @roomDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get roomDone;

  /// No description provided for @roomThemeCasaClara.
  ///
  /// In es, this message translates to:
  /// **'Casa clara'**
  String get roomThemeCasaClara;

  /// No description provided for @roomThemeCasaJardin.
  ///
  /// In es, this message translates to:
  /// **'Casa jardín'**
  String get roomThemeCasaJardin;

  /// No description provided for @roomThemeCasaDePlaya.
  ///
  /// In es, this message translates to:
  /// **'Casa de playa'**
  String get roomThemeCasaDePlaya;

  /// No description provided for @roomChooseTheme.
  ///
  /// In es, this message translates to:
  /// **'Elige el ambiente de tu casa.'**
  String get roomChooseTheme;

  /// No description provided for @roomCatReaction.
  ///
  /// In es, this message translates to:
  /// **'¡Hoy lo hiciste muy bien!'**
  String get roomCatReaction;

  /// No description provided for @roomInstruction.
  ///
  /// In es, this message translates to:
  /// **'Elige un objeto y toca el lugar donde va.'**
  String get roomInstruction;

  /// No description provided for @roomCategoryRooms.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get roomCategoryRooms;

  /// No description provided for @roomCategoryFurniture.
  ///
  /// In es, this message translates to:
  /// **'Muebles'**
  String get roomCategoryFurniture;

  /// No description provided for @roomCategoryWallFloor.
  ///
  /// In es, this message translates to:
  /// **'Pared y piso'**
  String get roomCategoryWallFloor;

  /// No description provided for @roomCategoryProps.
  ///
  /// In es, this message translates to:
  /// **'Adornos'**
  String get roomCategoryProps;

  /// No description provided for @roomCategoryCharacters.
  ///
  /// In es, this message translates to:
  /// **'Personajes'**
  String get roomCategoryCharacters;

  /// No description provided for @roomCharacterInstruction.
  ///
  /// In es, this message translates to:
  /// **'Elige quién te acompaña.'**
  String get roomCharacterInstruction;

  /// No description provided for @roomMoreInCollection.
  ///
  /// In es, this message translates to:
  /// **'Ver más en la colección'**
  String get roomMoreInCollection;

  /// No description provided for @roomDefaultRug.
  ///
  /// In es, this message translates to:
  /// **'Tapete lavanda'**
  String get roomDefaultRug;

  /// No description provided for @roomFloorLamp.
  ///
  /// In es, this message translates to:
  /// **'Lámpara verde'**
  String get roomFloorLamp;

  /// No description provided for @roomTablePlant.
  ///
  /// In es, this message translates to:
  /// **'Planta de mesa'**
  String get roomTablePlant;

  /// No description provided for @roomWallFrame.
  ///
  /// In es, this message translates to:
  /// **'Cuadro'**
  String get roomWallFrame;

  /// No description provided for @roomRattanChair.
  ///
  /// In es, this message translates to:
  /// **'Sillón de ratán'**
  String get roomRattanChair;

  /// No description provided for @roomStandingLamp.
  ///
  /// In es, this message translates to:
  /// **'Lámpara de pie'**
  String get roomStandingLamp;

  /// No description provided for @roomWallClock.
  ///
  /// In es, this message translates to:
  /// **'Reloj de pared'**
  String get roomWallClock;

  /// No description provided for @roomSaved.
  ///
  /// In es, this message translates to:
  /// **'Tu casa quedó guardada.'**
  String get roomSaved;

  /// No description provided for @roomPlaced.
  ///
  /// In es, this message translates to:
  /// **'Colocado'**
  String get roomPlaced;

  /// No description provided for @roomSurfaceWall.
  ///
  /// In es, this message translates to:
  /// **'Pared'**
  String get roomSurfaceWall;

  /// No description provided for @roomSurfaceFloor.
  ///
  /// In es, this message translates to:
  /// **'Piso'**
  String get roomSurfaceFloor;

  /// No description provided for @roomSurfaceTabletop.
  ///
  /// In es, this message translates to:
  /// **'Mesa'**
  String get roomSurfaceTabletop;

  /// No description provided for @roomSurfaceRug.
  ///
  /// In es, this message translates to:
  /// **'Tapete'**
  String get roomSurfaceRug;

  /// Screen-reader name of one place in the room while an item is being placed. The surface is one of roomSurfaceWall, roomSurfaceFloor, roomSurfaceTabletop or roomSurfaceRug.
  ///
  /// In es, this message translates to:
  /// **'{surface}, lugar {number}'**
  String roomSlotLabel(String surface, int number);

  /// Hint while an item that hangs on the wall is chosen; only the matching places are lit.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un lugar en la pared. Tócalo para colgarlo.} other{Hay {count} lugares en la pared. Toca dónde va.}}'**
  String roomPickWall(int count);

  /// No description provided for @roomPickFloor.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un lugar en el piso. Tócalo para ponerlo.} other{Hay {count} lugares en el piso. Toca dónde va.}}'**
  String roomPickFloor(int count);

  /// No description provided for @roomPickTabletop.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un lugar en la mesa. Tócalo para ponerlo.} other{Hay {count} lugares en la mesa. Toca dónde va.}}'**
  String roomPickTabletop(int count);

  /// No description provided for @roomPickRug.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un lugar para el tapete. Tócalo para ponerlo.} other{Hay {count} lugares para el tapete. Toca dónde va.}}'**
  String roomPickRug(int count);

  /// Hint while an item that fits more than one surface is chosen, such as a small plant that goes on a table or the floor.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un lugar donde puede ir. Tócalo para ponerlo.} other{Hay {count} lugares donde puede ir. Toca dónde va.}}'**
  String roomPickAny(int count);

  /// No description provided for @roomMoveOrRemove.
  ///
  /// In es, this message translates to:
  /// **'Toca otro lugar para moverlo, o el suyo para quitarlo.'**
  String get roomMoveOrRemove;

  /// No description provided for @roomTapToRemove.
  ///
  /// In es, this message translates to:
  /// **'Toca su lugar otra vez para quitarlo.'**
  String get roomTapToRemove;

  /// No description provided for @xpHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get xpHistoryTitle;

  /// No description provided for @xpTotal.
  ///
  /// In es, this message translates to:
  /// **'{count} XP totales'**
  String xpTotal(int count);

  /// No description provided for @xpMaxLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel máximo'**
  String get xpMaxLevel;

  /// No description provided for @xpRemaining.
  ///
  /// In es, this message translates to:
  /// **'Faltan {count} XP'**
  String xpRemaining(int count);

  /// No description provided for @xpHistoryHint.
  ///
  /// In es, this message translates to:
  /// **'El XP se acredita automáticamente. Cada fila conserva la razón y el cálculo, aunque cierres la app.'**
  String get xpHistoryHint;

  /// No description provided for @xpHistoryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay XP'**
  String get xpHistoryEmptyTitle;

  /// No description provided for @xpHistoryEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'El primer conteo de efectivo de la semana y el cierre de tu ciclo aparecerán aquí.'**
  String get xpHistoryEmptyMessage;

  /// No description provided for @xpAmount.
  ///
  /// In es, this message translates to:
  /// **'+{count} XP'**
  String xpAmount(int count);

  /// No description provided for @xpSeeCalculation.
  ///
  /// In es, this message translates to:
  /// **'Ver cálculo'**
  String get xpSeeCalculation;

  /// No description provided for @xpCalculationTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo se calculó'**
  String get xpCalculationTitle;

  /// No description provided for @xpDetailCycle.
  ///
  /// In es, this message translates to:
  /// **'Ciclo'**
  String get xpDetailCycle;

  /// No description provided for @xpDetailBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get xpDetailBudget;

  /// No description provided for @xpDetailSpent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get xpDetailSpent;

  /// No description provided for @xpDetailResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get xpDetailResult;

  /// No description provided for @xpDetailRule.
  ///
  /// In es, this message translates to:
  /// **'Regla'**
  String get xpDetailRule;

  /// No description provided for @xpDetailCredited.
  ///
  /// In es, this message translates to:
  /// **'XP acreditado'**
  String get xpDetailCredited;

  /// No description provided for @xpRuleCashCount.
  ///
  /// In es, this message translates to:
  /// **'Máximo una vez por semana'**
  String get xpRuleCashCount;

  /// No description provided for @xpRuleCycleInGreen.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Recompensa normalizada por {count} día} other{Recompensa normalizada por {count} días}}'**
  String xpRuleCycleInGreen(int count);

  /// No description provided for @xpRuleDaysUnderDailyLimit.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} día × 5 XP} other{{count} días × 5 XP}}'**
  String xpRuleDaysUnderDailyLimit(int count);

  /// No description provided for @xpRuleFirstSuccessfulCycle.
  ///
  /// In es, this message translates to:
  /// **'Bono único de 50 XP'**
  String get xpRuleFirstSuccessfulCycle;

  /// No description provided for @recoveryNotYet.
  ///
  /// In es, this message translates to:
  /// **'No pudimos recuperar los datos todavía.'**
  String get recoveryNotYet;

  /// No description provided for @recoveryStartFreshQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Empezar de nuevo?'**
  String get recoveryStartFreshQuestion;

  /// No description provided for @recoveryStartFreshBody.
  ///
  /// In es, this message translates to:
  /// **'Conservaremos una copia del archivo original antes de crear datos nuevos.'**
  String get recoveryStartFreshBody;

  /// No description provided for @recoveryStartFresh.
  ///
  /// In es, this message translates to:
  /// **'Empezar de nuevo'**
  String get recoveryStartFresh;

  /// No description provided for @recoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer tus datos'**
  String get recoveryTitle;

  /// No description provided for @recoveryOriginalKept.
  ///
  /// In es, this message translates to:
  /// **'El archivo original sigue guardado. No lo reemplazamos ni borramos.'**
  String get recoveryOriginalKept;

  /// No description provided for @recoveryOptions.
  ///
  /// In es, this message translates to:
  /// **'Puedes reintentar, usar el respaldo o exportar el archivo para conservarlo.'**
  String get recoveryOptions;

  /// No description provided for @recoveryRetrying.
  ///
  /// In es, this message translates to:
  /// **'Reintentando…'**
  String get recoveryRetrying;

  /// No description provided for @recoveryRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get recoveryRetry;

  /// No description provided for @recoveryUseBackup.
  ///
  /// In es, this message translates to:
  /// **'Usar respaldo'**
  String get recoveryUseBackup;

  /// No description provided for @recoveryExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar archivo'**
  String get recoveryExport;

  /// No description provided for @recoveryExported.
  ///
  /// In es, this message translates to:
  /// **'Archivo original copiado.'**
  String get recoveryExported;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Sobrita'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// Asked before switching currency. Nothing is converted, so the user has to know the figures keep their numbers and only change their label.
  ///
  /// In es, this message translates to:
  /// **'¿Cambiar a {code}?'**
  String currencyChangeTitle(String code);

  /// No description provided for @currencyChangeBody.
  ///
  /// In es, this message translates to:
  /// **'Tus montos no se convierten: {example} seguirá siendo {converted}. Solo cambia la etiqueta.'**
  String currencyChangeBody(String example, String converted);

  /// No description provided for @currencyChangeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cambiar etiqueta'**
  String get currencyChangeConfirm;

  /// No description provided for @currencyRegionAmericas.
  ///
  /// In es, this message translates to:
  /// **'América'**
  String get currencyRegionAmericas;

  /// No description provided for @currencyRegionEurope.
  ///
  /// In es, this message translates to:
  /// **'Europa'**
  String get currencyRegionEurope;

  /// No description provided for @currencyRegionAsiaPacific.
  ///
  /// In es, this message translates to:
  /// **'Asia y Oceanía'**
  String get currencyRegionAsiaPacific;

  /// No description provided for @settingsCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get settingsCurrency;

  /// No description provided for @settingsBudgetCycle.
  ///
  /// In es, this message translates to:
  /// **'Ciclo de presupuesto'**
  String get settingsBudgetCycle;

  /// No description provided for @settingsCountDay.
  ///
  /// In es, this message translates to:
  /// **'Día de conteo'**
  String get settingsCountDay;

  /// No description provided for @settingsReduceMotionHint.
  ///
  /// In es, this message translates to:
  /// **'Se activa solo si tu teléfono ya lo pide.'**
  String get settingsReduceMotionHint;

  /// No description provided for @settingsQuickEntry.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido'**
  String get settingsQuickEntry;

  /// No description provided for @settingsQuickEntryHint.
  ///
  /// In es, this message translates to:
  /// **'Muestra Ingreso y Gasto en la pantalla bloqueada.'**
  String get settingsQuickEntryHint;

  /// No description provided for @quickEntryQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres registrar?'**
  String get quickEntryQuestion;

  /// No description provided for @quickEntryDenied.
  ///
  /// In es, this message translates to:
  /// **'Permite las notificaciones de Sobrita para activar el acceso rápido.'**
  String get quickEntryDenied;

  /// No description provided for @settingsBackup.
  ///
  /// In es, this message translates to:
  /// **'Respaldo de datos'**
  String get settingsBackup;

  /// No description provided for @settingsCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get settingsCopy;

  /// No description provided for @settingsBackupCopied.
  ///
  /// In es, this message translates to:
  /// **'Respaldo copiado al portapapeles.'**
  String get settingsBackupCopied;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de Google'**
  String get settingsAccount;

  /// No description provided for @settingsAccountConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get settingsAccountConnect;

  /// No description provided for @settingsRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get settingsRestore;

  /// No description provided for @purchaseRestored.
  ///
  /// In es, this message translates to:
  /// **'Listo. Tus compras volvieron.'**
  String get purchaseRestored;

  /// No description provided for @purchaseFailureStoreUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La tienda no está disponible ahora. Inténtalo más tarde.'**
  String get purchaseFailureStoreUnavailable;

  /// No description provided for @purchaseFailureRejected.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la compra. No se te cobró nada.'**
  String get purchaseFailureRejected;

  /// No description provided for @purchaseFailureDeliveryNotSaved.
  ///
  /// In es, this message translates to:
  /// **'Tu compra llegó, pero no se pudo guardar. Se aplicará la próxima vez que abras Sobrita.'**
  String get purchaseFailureDeliveryNotSaved;

  /// No description provided for @purchaseFailureNothingToRestore.
  ///
  /// In es, this message translates to:
  /// **'No encontramos compras en esta cuenta.'**
  String get purchaseFailureNothingToRestore;

  /// No description provided for @collectionPurchasing.
  ///
  /// In es, this message translates to:
  /// **'COMPRANDO…'**
  String get collectionPurchasing;

  /// No description provided for @settingsXpPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa XP'**
  String get settingsXpPreview;

  /// No description provided for @settingsDesign.
  ///
  /// In es, this message translates to:
  /// **'Diseño'**
  String get settingsDesign;

  /// No description provided for @settingsStorageNote.
  ///
  /// In es, this message translates to:
  /// **'Tus datos se guardan en este dispositivo. No se necesita una cuenta para usar Sobrita.'**
  String get settingsStorageNote;

  /// No description provided for @settingsSectionShop.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get settingsSectionShop;

  /// No description provided for @settingsRemoveAds.
  ///
  /// In es, this message translates to:
  /// **'Quitar anuncios generales'**
  String get settingsRemoveAds;

  /// No description provided for @settingsRemoveAdsHint.
  ///
  /// In es, this message translates to:
  /// **'Quita los anuncios del historial. Los de recompensa siguen disponibles.'**
  String get settingsRemoveAdsHint;

  /// No description provided for @settingsPackName.
  ///
  /// In es, this message translates to:
  /// **'Michi y sus amigos'**
  String get settingsPackName;

  /// No description provided for @settingsPackHint.
  ///
  /// In es, this message translates to:
  /// **'3 personajes + la estrella de Michi. También quita los anuncios generales.'**
  String get settingsPackHint;

  /// No description provided for @settingsOwned.
  ///
  /// In es, this message translates to:
  /// **'Ya lo tienes'**
  String get settingsOwned;

  /// No description provided for @settingsShopRestoreNote.
  ///
  /// In es, this message translates to:
  /// **'Las compras se guardan en tu cuenta de la tienda. Puedes recuperarlas al reinstalar.'**
  String get settingsShopRestoreNote;

  /// No description provided for @settlementTitle.
  ///
  /// In es, this message translates to:
  /// **'Cierre de este ciclo'**
  String get settlementTitle;

  /// No description provided for @settlementSpent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get settlementSpent;

  /// No description provided for @settlementLeft.
  ///
  /// In es, this message translates to:
  /// **'Sobrante'**
  String get settlementLeft;

  /// No description provided for @settlementOver.
  ///
  /// In es, this message translates to:
  /// **'Pasaste'**
  String get settlementOver;

  /// No description provided for @settlementAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio diario'**
  String get settlementAverage;

  /// No description provided for @settlementContinue.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get settlementContinue;

  /// No description provided for @settlementCtaTitle.
  ///
  /// In es, this message translates to:
  /// **'Ir por un adorno especial'**
  String get settlementCtaTitle;

  /// No description provided for @settlementCtaAction.
  ///
  /// In es, this message translates to:
  /// **'Ver colección'**
  String get settlementCtaAction;

  /// No description provided for @settingsSectionBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get settingsSectionBudget;

  /// No description provided for @settingsSectionScreen.
  ///
  /// In es, this message translates to:
  /// **'Pantalla'**
  String get settingsSectionScreen;

  /// No description provided for @settingsSectionData.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsAdPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad de anuncios'**
  String get settingsAdPrivacy;

  /// No description provided for @settingsAdPrivacyValue.
  ///
  /// In es, this message translates to:
  /// **'Administrar'**
  String get settingsAdPrivacyValue;

  /// No description provided for @settingsAdPrivacyFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron abrir las opciones de privacidad. Inténtalo de nuevo.'**
  String get settingsAdPrivacyFailed;

  /// Groups the debug design gallery, which is not data and does not belong beside the backup row.
  ///
  /// In es, this message translates to:
  /// **'Diseño'**
  String get settingsSectionDesign;

  /// The light history line under the profile card's name: how much the ledger has accumulated, without repeating the money figures the home screen already carries.
  ///
  /// In es, this message translates to:
  /// **'{movements, plural, =1{1 movimiento} other{{movements} movimientos}} · {days, plural, =1{1 día con Sobrita} other{{days} días con Sobrita}}'**
  String settingsProfileStats(int movements, int days);

  /// The language setting that follows the phone. The names of the languages themselves are not translated — a reader looks for their own language written in it.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get languageAutomatic;

  /// No description provided for @languageAutomaticHint.
  ///
  /// In es, this message translates to:
  /// **'Sigue tu teléfono'**
  String get languageAutomaticHint;

  /// No description provided for @transactionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get transactionsTitle;

  /// No description provided for @dailySpendTitle.
  ///
  /// In es, this message translates to:
  /// **'Gasto por día'**
  String get dailySpendTitle;

  /// The line across the daily chart: what one day of the cycle is worth.
  ///
  /// In es, this message translates to:
  /// **'Límite de {amount} al día'**
  String dailySpendLimit(String amount);

  /// The caption under the spending chart when no budget has been set, so there is no daily limit line to name.
  ///
  /// In es, this message translates to:
  /// **'Este ciclo {amount}'**
  String dailySpendCycleTotal(String amount);

  /// No description provided for @dailyIncomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingreso por día'**
  String get dailyIncomeTitle;

  /// The caption under the income chart: what came in during this cycle. Income has no daily limit line.
  ///
  /// In es, this message translates to:
  /// **'Este ciclo {amount}'**
  String dailyIncomeCycleTotal(String amount);

  /// No description provided for @transactionsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos'**
  String get transactionsEmptyTitle;

  /// No description provided for @transactionsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer gasto y aquí verás el resumen del ciclo.'**
  String get transactionsEmptyMessage;

  /// No description provided for @transactionsEmptyExpensesTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay gastos'**
  String get transactionsEmptyExpensesTitle;

  /// No description provided for @transactionsEmptyExpensesMessage.
  ///
  /// In es, this message translates to:
  /// **'Registra un gasto y aquí verás el día a día.'**
  String get transactionsEmptyExpensesMessage;

  /// No description provided for @transactionsEmptyIncomesTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay ingresos'**
  String get transactionsEmptyIncomesTitle;

  /// No description provided for @transactionsEmptyIncomesMessage.
  ///
  /// In es, this message translates to:
  /// **'Registra un ingreso y aquí verás el día a día.'**
  String get transactionsEmptyIncomesMessage;

  /// No description provided for @transactionsExpensePinned.
  ///
  /// In es, this message translates to:
  /// **'Este gasto viene de un conteo de efectivo. Vuelve a contar para corregirlo.'**
  String get transactionsExpensePinned;

  /// No description provided for @transactionsIncomePinned.
  ///
  /// In es, this message translates to:
  /// **'Este ingreso viene de un conteo de efectivo. Vuelve a contar para corregirlo.'**
  String get transactionsIncomePinned;

  /// No description provided for @transactionsExpenseDeleted.
  ///
  /// In es, this message translates to:
  /// **'Movimiento eliminado.'**
  String get transactionsExpenseDeleted;

  /// No description provided for @transactionsIncomeDeleted.
  ///
  /// In es, this message translates to:
  /// **'Ingreso eliminado.'**
  String get transactionsIncomeDeleted;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @identifyDifference.
  ///
  /// In es, this message translates to:
  /// **'Identificar diferencia'**
  String get identifyDifference;

  /// No description provided for @editMovement.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get editMovement;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amount;

  /// No description provided for @editPendingHint.
  ///
  /// In es, this message translates to:
  /// **'El monto viene de tu conteo de efectivo. Puedes cambiar la categoría y la nota.'**
  String get editPendingHint;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @note.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get note;

  /// No description provided for @noteExample.
  ///
  /// In es, this message translates to:
  /// **'Ej. Tacos'**
  String get noteExample;

  /// No description provided for @replacesPendingHint.
  ///
  /// In es, this message translates to:
  /// **'Esto reemplaza el ajuste pendiente. No suma otro gasto.'**
  String get replacesPendingHint;

  /// No description provided for @saveWithoutDuplicating.
  ///
  /// In es, this message translates to:
  /// **'Guardar sin duplicar'**
  String get saveWithoutDuplicating;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @budget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get budget;

  /// No description provided for @spent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get spent;

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Sobrita'**
  String get appName;

  /// No description provided for @homeCycleBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo del ciclo'**
  String get homeCycleBalance;

  /// No description provided for @homeTodayLeft.
  ///
  /// In es, this message translates to:
  /// **'Hoy te queda'**
  String get homeTodayLeft;

  /// No description provided for @homeOverBudget.
  ///
  /// In es, this message translates to:
  /// **'Te pasaste del presupuesto de {budget} de este ciclo'**
  String homeOverBudget(String budget);

  /// No description provided for @homeDailyLimit.
  ///
  /// In es, this message translates to:
  /// **'Límite de hoy {limit} · Quedan {remaining} en el ciclo'**
  String homeDailyLimit(String limit, String remaining);

  /// No description provided for @homeFirstQuestLabel.
  ///
  /// In es, this message translates to:
  /// **'Primera misión'**
  String get homeFirstQuestLabel;

  /// No description provided for @homeBudgetQuestBody.
  ///
  /// In es, this message translates to:
  /// **'Ponle un presupuesto y te digo cuánto puedes gastar cada día.'**
  String get homeBudgetQuestBody;

  /// No description provided for @homeCycleProgress.
  ///
  /// In es, this message translates to:
  /// **'Avance del ciclo'**
  String get homeCycleProgress;

  /// No description provided for @daysCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} día} other{{count} días}}'**
  String daysCount(int count);

  /// No description provided for @homeCashEstimated.
  ///
  /// In es, this message translates to:
  /// **'Efectivo estimado'**
  String get homeCashEstimated;

  /// No description provided for @homeCashUnset.
  ///
  /// In es, this message translates to:
  /// **'Efectivo sin configurar'**
  String get homeCashUnset;

  /// No description provided for @homeLastCount.
  ///
  /// In es, this message translates to:
  /// **'Último conteo: {amount}'**
  String homeLastCount(String amount);

  /// No description provided for @homeFirstCountHint.
  ///
  /// In es, this message translates to:
  /// **'Haz un primer conteo para empezar.'**
  String get homeFirstCountHint;

  /// No description provided for @homeRecentMovements.
  ///
  /// In es, this message translates to:
  /// **'Movimientos recientes'**
  String get homeRecentMovements;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get homeSeeAll;

  /// No description provided for @homeGoingWell.
  ///
  /// In es, this message translates to:
  /// **'Vas muy bien'**
  String get homeGoingWell;

  /// No description provided for @homeAdjustCalmly.
  ///
  /// In es, this message translates to:
  /// **'Ajustemos con calma'**
  String get homeAdjustCalmly;

  /// No description provided for @budgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get budgetTitle;

  /// No description provided for @budgetCycleTotal.
  ///
  /// In es, this message translates to:
  /// **'Total del ciclo'**
  String get budgetCycleTotal;

  /// No description provided for @budgetTotal.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto total'**
  String get budgetTotal;

  /// No description provided for @budgetNotSetTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay presupuesto'**
  String get budgetNotSetTitle;

  /// No description provided for @budgetNotSetBody.
  ///
  /// In es, this message translates to:
  /// **'Defínelo y calculamos cuánto puedes gastar cada día.'**
  String get budgetNotSetBody;

  /// No description provided for @budgetSetAction.
  ///
  /// In es, this message translates to:
  /// **'Definir presupuesto'**
  String get budgetSetAction;

  /// No description provided for @budgetTooLow.
  ///
  /// In es, this message translates to:
  /// **'El total debe ser mayor que los ingresos asignados al ciclo ({allocated}).'**
  String budgetTooLow(String allocated);

  /// How much of the cycle's budget is already gone. Shown beside the ring, and in the danger colour once it passes 100.
  ///
  /// In es, this message translates to:
  /// **'{percent}% del presupuesto'**
  String budgetSpentShare(int percent);

  /// No description provided for @budgetRingSpent.
  ///
  /// In es, this message translates to:
  /// **'Gastado {amount}'**
  String budgetRingSpent(String amount);

  /// No description provided for @budgetRingLeft.
  ///
  /// In es, this message translates to:
  /// **'Queda {amount}'**
  String budgetRingLeft(String amount);

  /// A category's share of everything spent this cycle, shown next to its name.
  ///
  /// In es, this message translates to:
  /// **'{percent}%'**
  String budgetCategoryShare(int percent);

  /// No description provided for @cycleHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Ciclos anteriores'**
  String get cycleHistoryTitle;

  /// How many of the closed cycles stayed inside their budget.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{green} de {total} ciclo en verde} other{{green} de {total} ciclos en verde}}'**
  String cycleHistorySummary(int green, int total);

  /// No description provided for @cycleHistoryAmounts.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto {budget} · Gastado {spent}'**
  String cycleHistoryAmounts(String budget, String spent);

  /// No description provided for @cycleHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no se ha cerrado ningún ciclo.'**
  String get cycleHistoryEmpty;

  /// No description provided for @cycleHistoryAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio diario {amount}'**
  String cycleHistoryAverage(String amount);

  /// No description provided for @cycleHistoryAveragePending.
  ///
  /// In es, this message translates to:
  /// **'Promedio diario · reuniendo datos'**
  String get cycleHistoryAveragePending;

  /// No description provided for @budgetChangedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiaste tu presupuesto'**
  String get budgetChangedTitle;

  /// No description provided for @budgetChangedBody.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con los límites por categoría? Al ajustarlos, cada uno cambia en la misma proporción y conservas tu reparto.'**
  String get budgetChangedBody;

  /// No description provided for @budgetKeepLimits.
  ///
  /// In es, this message translates to:
  /// **'Conservarlos'**
  String get budgetKeepLimits;

  /// No description provided for @budgetScaleLimits.
  ///
  /// In es, this message translates to:
  /// **'Ajustarlos proporcionalmente'**
  String get budgetScaleLimits;

  /// No description provided for @budgetByCategory.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto por categoría'**
  String get budgetByCategory;

  /// No description provided for @budgetCategoryLimit.
  ///
  /// In es, this message translates to:
  /// **'Límite de {category}'**
  String budgetCategoryLimit(String category);

  /// No description provided for @budgetSpentOfLimit.
  ///
  /// In es, this message translates to:
  /// **'{spent} / {limit}'**
  String budgetSpentOfLimit(String spent, String limit);

  /// No description provided for @budgetProjection.
  ///
  /// In es, this message translates to:
  /// **'Proyección al cierre'**
  String get budgetProjection;

  /// No description provided for @budgetEstimatedLeft.
  ///
  /// In es, this message translates to:
  /// **'Estimado que te quedará'**
  String get budgetEstimatedLeft;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get saving;

  /// No description provided for @dayOfMonth.
  ///
  /// In es, this message translates to:
  /// **'Día {day}'**
  String dayOfMonth(int day);

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @weekdayShortMonday.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get weekdayShortMonday;

  /// No description provided for @weekdayShortTuesday.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get weekdayShortTuesday;

  /// No description provided for @weekdayShortWednesday.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get weekdayShortWednesday;

  /// No description provided for @weekdayShortThursday.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get weekdayShortThursday;

  /// No description provided for @weekdayShortFriday.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get weekdayShortFriday;

  /// No description provided for @weekdayShortSaturday.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get weekdayShortSaturday;

  /// No description provided for @weekdayShortSunday.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get weekdayShortSunday;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get registerTitle;

  /// No description provided for @registerExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get registerExpense;

  /// No description provided for @registerIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get registerIncome;

  /// No description provided for @registerAmountAboveZero.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto mayor a cero.'**
  String get registerAmountAboveZero;

  /// No description provided for @registerNoFutureMovements.
  ///
  /// In es, this message translates to:
  /// **'No puedes registrar movimientos futuros.'**
  String get registerNoFutureMovements;

  /// No description provided for @registerDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get registerDate;

  /// No description provided for @registerNoteExpenseExample.
  ///
  /// In es, this message translates to:
  /// **'Ej. Taquería El Faro'**
  String get registerNoteExpenseExample;

  /// No description provided for @registerNoteIncomeExample.
  ///
  /// In es, this message translates to:
  /// **'Ej. Propina del viernes'**
  String get registerNoteIncomeExample;

  /// No description provided for @receiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Ticket'**
  String get receiptTitle;

  /// No description provided for @receiptAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar ticket'**
  String get receiptAdd;

  /// No description provided for @receiptCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get receiptCamera;

  /// No description provided for @receiptGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get receiptGallery;

  /// No description provided for @receiptChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get receiptChange;

  /// No description provided for @receiptRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get receiptRemove;

  /// No description provided for @receiptHint.
  ///
  /// In es, this message translates to:
  /// **'Una foto para recordar qué fue este gasto.'**
  String get receiptHint;

  /// No description provided for @receiptAttached.
  ///
  /// In es, this message translates to:
  /// **'Ticket adjunto'**
  String get receiptAttached;

  /// No description provided for @receiptView.
  ///
  /// In es, this message translates to:
  /// **'Ver ticket'**
  String get receiptView;

  /// No description provided for @receiptClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get receiptClose;

  /// No description provided for @receiptMissing.
  ///
  /// In es, this message translates to:
  /// **'La foto ya no está en este dispositivo.'**
  String get receiptMissing;

  /// No description provided for @receiptFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la foto.'**
  String get receiptFailed;

  /// No description provided for @receiptBackupNote.
  ///
  /// In es, this message translates to:
  /// **'La copia no incluye las fotos de tickets.'**
  String get receiptBackupNote;

  /// No description provided for @registerPayment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get registerPayment;

  /// No description provided for @registerPaymentHint.
  ///
  /// In es, this message translates to:
  /// **'El efectivo se descuenta de tu conteo. La tarjeta no.'**
  String get registerPaymentHint;

  /// No description provided for @registerIncomeKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo de ingreso'**
  String get registerIncomeKind;

  /// No description provided for @registerWhatToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get registerWhatToDo;

  /// No description provided for @registerThisCycle.
  ///
  /// In es, this message translates to:
  /// **'Este ciclo'**
  String get registerThisCycle;

  /// No description provided for @registerSaveIt.
  ///
  /// In es, this message translates to:
  /// **'Guardarlo'**
  String get registerSaveIt;

  /// No description provided for @registerReceivedIn.
  ///
  /// In es, this message translates to:
  /// **'Lo recibiste en'**
  String get registerReceivedIn;

  /// No description provided for @registerAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get registerAccount;

  /// No description provided for @registerReconcileQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Este gasto explica la diferencia?'**
  String get registerReconcileQuestion;

  /// No description provided for @registerReconcileBody.
  ///
  /// In es, this message translates to:
  /// **'Tienes {amount} pendiente del último conteo. Si es el mismo gasto, lo identificaremos sin sumarlo otra vez.'**
  String registerReconcileBody(String amount);

  /// No description provided for @registerReconcileNo.
  ///
  /// In es, this message translates to:
  /// **'No, es nuevo'**
  String get registerReconcileNo;

  /// No description provided for @registerReconcileYes.
  ///
  /// In es, this message translates to:
  /// **'Sí, conciliar'**
  String get registerReconcileYes;

  /// No description provided for @registerDifferenceReconciled.
  ///
  /// In es, this message translates to:
  /// **'Diferencia conciliada'**
  String get registerDifferenceReconciled;

  /// No description provided for @registerExpenseSaved.
  ///
  /// In es, this message translates to:
  /// **'Gasto guardado'**
  String get registerExpenseSaved;

  /// No description provided for @registerIncomeSaved.
  ///
  /// In es, this message translates to:
  /// **'Ingreso guardado'**
  String get registerIncomeSaved;

  /// No description provided for @cashCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Conteo de efectivo'**
  String get cashCountTitle;

  /// No description provided for @cashCountPickWhatHappened.
  ///
  /// In es, this message translates to:
  /// **'Elige qué pasó con la diferencia.'**
  String get cashCountPickWhatHappened;

  /// No description provided for @cashCountSavedWithoutDuplicates.
  ///
  /// In es, this message translates to:
  /// **'Conteo guardado sin duplicar movimientos.'**
  String get cashCountSavedWithoutDuplicates;

  /// No description provided for @cashCountPrompt.
  ///
  /// In es, this message translates to:
  /// **'Cuenta solo el efectivo que tienes ahora.'**
  String get cashCountPrompt;

  /// No description provided for @cashCountNoneYet.
  ///
  /// In es, this message translates to:
  /// **'Sin conteo todavía'**
  String get cashCountNoneYet;

  /// No description provided for @cashCountResultPending.
  ///
  /// In es, this message translates to:
  /// **'El resultado aparecerá después de escribir el conteo.'**
  String get cashCountResultPending;

  /// No description provided for @cashCountBaselineHint.
  ///
  /// In es, this message translates to:
  /// **'Este será tu punto de partida. No se registrará como ingreso.'**
  String get cashCountBaselineHint;

  /// No description provided for @cashCountExpected.
  ///
  /// In es, this message translates to:
  /// **'Esperábamos'**
  String get cashCountExpected;

  /// No description provided for @cashCountCounted.
  ///
  /// In es, this message translates to:
  /// **'Contaste'**
  String get cashCountCounted;

  /// No description provided for @cashCountBalanced.
  ///
  /// In es, this message translates to:
  /// **'Todo cuadra'**
  String get cashCountBalanced;

  /// No description provided for @cashCountShort.
  ///
  /// In es, this message translates to:
  /// **'Faltan {amount}'**
  String cashCountShort(String amount);

  /// No description provided for @cashCountExtra.
  ///
  /// In es, this message translates to:
  /// **'Hay {amount} de más'**
  String cashCountExtra(String amount);

  /// No description provided for @cashCountWhatHappened.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasó?'**
  String get cashCountWhatHappened;

  /// No description provided for @cashCountHelperExpense.
  ///
  /// In es, this message translates to:
  /// **'Fue un gasto que no habías registrado.'**
  String get cashCountHelperExpense;

  /// No description provided for @cashCountHelperIncome.
  ///
  /// In es, this message translates to:
  /// **'Fue dinero nuevo que recibiste.'**
  String get cashCountHelperIncome;

  /// No description provided for @cashCountHelperTransferOut.
  ///
  /// In es, this message translates to:
  /// **'Lo depositaste o lo moviste a otra cuenta.'**
  String get cashCountHelperTransferOut;

  /// No description provided for @cashCountHelperTransferIn.
  ///
  /// In es, this message translates to:
  /// **'Lo retiraste o lo moviste desde otra cuenta.'**
  String get cashCountHelperTransferIn;

  /// No description provided for @cashCountHelperCorrection.
  ///
  /// In es, this message translates to:
  /// **'El conteo anterior estaba equivocado.'**
  String get cashCountHelperCorrection;

  /// No description provided for @cashCountHelperPending.
  ///
  /// In es, this message translates to:
  /// **'Decídelo después.'**
  String get cashCountHelperPending;

  /// No description provided for @cashCountSingleExpenseHint.
  ///
  /// In es, this message translates to:
  /// **'Esto crea un solo gasto. No tendrás que registrarlo otra vez.'**
  String get cashCountSingleExpenseHint;

  /// No description provided for @cashCountNoteTipExample.
  ///
  /// In es, this message translates to:
  /// **'Ej. Propina'**
  String get cashCountNoteTipExample;

  /// No description provided for @cashCountWhatToDoWithMoney.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con este dinero?'**
  String get cashCountWhatToDoWithMoney;

  /// No description provided for @cashCountSaveFirst.
  ///
  /// In es, this message translates to:
  /// **'Guardar primer conteo'**
  String get cashCountSaveFirst;

  /// No description provided for @cashCountSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar conteo'**
  String get cashCountSave;

  /// No description provided for @cycleTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu ciclo'**
  String get cycleTitle;

  /// No description provided for @cycleCurrent.
  ///
  /// In es, this message translates to:
  /// **'Ciclo actual'**
  String get cycleCurrent;

  /// No description provided for @cycleInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get cycleInProgress;

  /// No description provided for @cycleUnchanged.
  ///
  /// In es, this message translates to:
  /// **'No cambiará'**
  String get cycleUnchanged;

  /// No description provided for @cycleNewFrequency.
  ///
  /// In es, this message translates to:
  /// **'Nueva frecuencia'**
  String get cycleNewFrequency;

  /// No description provided for @cycleFirstPay.
  ///
  /// In es, this message translates to:
  /// **'Primer pago'**
  String get cycleFirstPay;

  /// No description provided for @cyclePayDay.
  ///
  /// In es, this message translates to:
  /// **'Día de pago'**
  String get cyclePayDay;

  /// No description provided for @cycleNext.
  ///
  /// In es, this message translates to:
  /// **'Próximo ciclo'**
  String get cycleNext;

  /// No description provided for @cycleChangeAppliesRepeating.
  ///
  /// In es, this message translates to:
  /// **'El cambio se aplicará al siguiente ciclo y después se renovará cada {days} días.'**
  String cycleChangeAppliesRepeating(int days);

  /// No description provided for @cycleChangeApplies.
  ///
  /// In es, this message translates to:
  /// **'El cambio se aplicará al siguiente ciclo.'**
  String get cycleChangeApplies;

  /// No description provided for @cycleSaveChange.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambio'**
  String get cycleSaveChange;

  /// No description provided for @onboardingBudgetAboveZero.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un presupuesto mayor a cero.'**
  String get onboardingBudgetAboveZero;

  /// No description provided for @onboardingCashOrSkip.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el efectivo o elige “Ahora no”.'**
  String get onboardingCashOrSkip;

  /// No description provided for @prologueRainNoEnd.
  ///
  /// In es, this message translates to:
  /// **'La lluvia no daba señales de parar.'**
  String get prologueRainNoEnd;

  /// No description provided for @prologueRentPaid.
  ///
  /// In es, this message translates to:
  /// **'La renta estaba pagada, y en la cuenta quedaba lo justo hasta el próximo pago.'**
  String get prologueRentPaid;

  /// No description provided for @prologueSoundAtDoor.
  ///
  /// In es, this message translates to:
  /// **'Algo se movió junto a la puerta.'**
  String get prologueSoundAtDoor;

  /// No description provided for @prologueGoLook.
  ///
  /// In es, this message translates to:
  /// **'Ir a ver'**
  String get prologueGoLook;

  /// No description provided for @prologueWetTracks.
  ///
  /// In es, this message translates to:
  /// **'Dos hileras de huellas mojadas cruzaron el piso.'**
  String get prologueWetTracks;

  /// No description provided for @prologueShelter.
  ///
  /// In es, this message translates to:
  /// **'Déjanos esperar a que pase.'**
  String get prologueShelter;

  /// No description provided for @prologueItSpoke.
  ///
  /// In es, this message translates to:
  /// **'…habló.'**
  String get prologueItSpoke;

  /// No description provided for @prologueReplySurprised.
  ///
  /// In es, this message translates to:
  /// **'¿Acabas de hablar?'**
  String get prologueReplySurprised;

  /// No description provided for @prologueReplyTowel.
  ///
  /// In es, this message translates to:
  /// **'(traes una toalla sin decir nada)'**
  String get prologueReplyTowel;

  /// No description provided for @prologueEarnKeep.
  ///
  /// In es, this message translates to:
  /// **'Algo tengo que aportar. Yo llevo los números.'**
  String get prologueEarnKeep;

  /// No description provided for @prologueAskSchedule.
  ///
  /// In es, this message translates to:
  /// **'Primero: ¿cuándo entra el dinero?'**
  String get prologueAskSchedule;

  /// No description provided for @prologueAskPayday.
  ///
  /// In es, this message translates to:
  /// **'¿Qué día te pagan? Con el primero me basta; el resto lo cuento yo.'**
  String get prologueAskPayday;

  /// No description provided for @prologueAskBudget.
  ///
  /// In es, this message translates to:
  /// **'Faltan {days} días para el próximo pago. ¿Cuánto piensas gastar?'**
  String prologueAskBudget(int days);

  /// No description provided for @prologueSkipIsFine.
  ///
  /// In es, this message translates to:
  /// **'Puedes saltarlo. Te lo recuerdo en casa.'**
  String get prologueSkipIsFine;

  /// No description provided for @prologueSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get prologueSkip;

  /// No description provided for @prologueDriedOff.
  ///
  /// In es, this message translates to:
  /// **'Secos, los dos se calmaron. Afuera seguía lloviendo.'**
  String get prologueDriedOff;

  /// No description provided for @prologueWhoSits.
  ///
  /// In es, this message translates to:
  /// **'¿Quién se sienta contigo?'**
  String get prologueWhoSits;

  /// No description provided for @prologueMichiTrait.
  ///
  /// In es, this message translates to:
  /// **'Callado.\nBueno con los números.'**
  String get prologueMichiTrait;

  /// No description provided for @prologuePoodleName.
  ///
  /// In es, this message translates to:
  /// **'Poodle'**
  String get prologuePoodleName;

  /// No description provided for @prologuePoodleTrait.
  ///
  /// In es, this message translates to:
  /// **'Puro ánimo.\nMuy atento.'**
  String get prologuePoodleTrait;

  /// No description provided for @prologueSchnauzerName.
  ///
  /// In es, this message translates to:
  /// **'Schnauzer'**
  String get prologueSchnauzerName;

  /// No description provided for @prologueSchnauzerTrait.
  ///
  /// In es, this message translates to:
  /// **'Observador.\nSiempre atento.'**
  String get prologueSchnauzerTrait;

  /// No description provided for @prologueLockedName.
  ///
  /// In es, this message translates to:
  /// **'???'**
  String get prologueLockedName;

  /// No description provided for @prologueLockedTrait.
  ///
  /// In es, this message translates to:
  /// **'Puro ánimo.\nMuy atento.'**
  String get prologueLockedTrait;

  /// No description provided for @prologueLockedSoon.
  ///
  /// In es, this message translates to:
  /// **'Arte en camino'**
  String get prologueLockedSoon;

  /// No description provided for @prologueOtherStays.
  ///
  /// In es, this message translates to:
  /// **'El otro también se queda. Puedes cambiar de compañero más adelante.'**
  String get prologueOtherStays;

  /// No description provided for @prologueLiveTogether.
  ///
  /// In es, this message translates to:
  /// **'Que se queden'**
  String get prologueLiveTogether;

  /// The chosen character introducing itself, right after it is picked.
  ///
  /// In es, this message translates to:
  /// **'Me llamo {name}. Gracias por abrir.'**
  String prologueGreeting(String name);

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onboardingStart;

  /// No description provided for @onboardingTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu dinero, sin presión.'**
  String get onboardingTagline;

  /// No description provided for @onboardingPromise.
  ///
  /// In es, this message translates to:
  /// **'Te decimos cuánto puedes gastar hoy.'**
  String get onboardingPromise;

  /// No description provided for @onboardingHowPaid.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo recibes tus ingresos?'**
  String get onboardingHowPaid;

  /// No description provided for @onboardingHowPaidHint.
  ///
  /// In es, this message translates to:
  /// **'Esto define las fechas de tu presupuesto.'**
  String get onboardingHowPaidHint;

  /// No description provided for @onboardingCycleHelperSemiMonthly.
  ///
  /// In es, this message translates to:
  /// **'Dos pagos al mes: el 15 y el fin de mes.'**
  String get onboardingCycleHelperSemiMonthly;

  /// No description provided for @onboardingCycleHelperMonthly.
  ///
  /// In es, this message translates to:
  /// **'Un pago al mes.'**
  String get onboardingCycleHelperMonthly;

  /// No description provided for @onboardingCycleHelperWeekly.
  ///
  /// In es, this message translates to:
  /// **'Cada semana.'**
  String get onboardingCycleHelperWeekly;

  /// No description provided for @onboardingCycleHelperIrregular.
  ///
  /// In es, this message translates to:
  /// **'Mis ingresos no tienen fecha fija.'**
  String get onboardingCycleHelperIrregular;

  /// No description provided for @onboardingPlanWithoutFixedDate.
  ///
  /// In es, this message translates to:
  /// **'Planea sin una fecha fija'**
  String get onboardingPlanWithoutFixedDate;

  /// No description provided for @onboardingWhichDayPaid.
  ///
  /// In es, this message translates to:
  /// **'¿Qué día recibes dinero?'**
  String get onboardingWhichDayPaid;

  /// No description provided for @onboardingSecondPayEndOfMonth.
  ///
  /// In es, this message translates to:
  /// **'Segundo pago · fin de mes'**
  String get onboardingSecondPayEndOfMonth;

  /// No description provided for @onboardingHowManyDays.
  ///
  /// In es, this message translates to:
  /// **'¿Para cuántos días quieres planear?'**
  String get onboardingHowManyDays;

  /// No description provided for @onboardingCyclePreview.
  ///
  /// In es, this message translates to:
  /// **'Tu ciclo quedaría así'**
  String get onboardingCyclePreview;

  /// No description provided for @onboardingRepeatsEvery.
  ///
  /// In es, this message translates to:
  /// **'Al terminar, comenzará automáticamente otro periodo de {days} días.'**
  String onboardingRepeatsEvery(int days);

  /// No description provided for @onboardingShortMonthsNote.
  ///
  /// In es, this message translates to:
  /// **'Las fechas se ajustan solas en meses cortos.'**
  String get onboardingShortMonthsNote;

  /// No description provided for @onboardingBudgetQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto quieres gastar\nen este ciclo?'**
  String get onboardingBudgetQuestion;

  /// No description provided for @onboardingBudgetLater.
  ///
  /// In es, this message translates to:
  /// **'Puedes ponerlo después desde Inicio.'**
  String get onboardingBudgetLater;

  /// No description provided for @onboardingNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get onboardingNotNow;

  /// No description provided for @onboardingCashQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto efectivo\ntienes hoy?'**
  String get onboardingCashQuestion;

  /// No description provided for @onboardingCashOptional.
  ///
  /// In es, this message translates to:
  /// **'Déjalo vacío si prefieres contarlo después.'**
  String get onboardingCashOptional;

  /// No description provided for @onboardingCashIsBaseline.
  ///
  /// In es, this message translates to:
  /// **'Este será tu primer conteo, no un ingreso.'**
  String get onboardingCashIsBaseline;

  /// The last prologue line, once the character has moved in.
  ///
  /// In es, this message translates to:
  /// **'Dejó de llover. {name} se acomodó a tu lado.'**
  String onboardingSettledIn(String name);

  /// No description provided for @onboardingFirstQuests.
  ///
  /// In es, this message translates to:
  /// **'Tus primeras misiones'**
  String get onboardingFirstQuests;

  /// No description provided for @onboardingWaitingAtHome.
  ///
  /// In es, this message translates to:
  /// **'Te espera en casa'**
  String get onboardingWaitingAtHome;

  /// No description provided for @onboardingGoHome.
  ///
  /// In es, this message translates to:
  /// **'Ir a Inicio'**
  String get onboardingGoHome;

  /// No description provided for @onboardingPlanReady.
  ///
  /// In es, this message translates to:
  /// **'Tu plan está listo'**
  String get onboardingPlanReady;

  /// No description provided for @onboardingCanSpendToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy puedes gastar'**
  String get onboardingCanSpendToday;

  /// No description provided for @onboardingStepOf.
  ///
  /// In es, this message translates to:
  /// **'{step} de {total}'**
  String onboardingStepOf(int step, int total);

  /// No description provided for @progressPercent.
  ///
  /// In es, this message translates to:
  /// **'Progreso {percent} por ciento'**
  String progressPercent(int percent);

  /// No description provided for @stepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de {total}'**
  String stepOf(int step, int total);

  /// No description provided for @xpOfTarget.
  ///
  /// In es, this message translates to:
  /// **'{current} / {target} XP'**
  String xpOfTarget(int current, int target);

  /// No description provided for @xpCycleInGreenBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Cerraste las dos semanas en verde'**
  String get xpCycleInGreenBiweekly;

  /// No description provided for @onboardingCycleHelperBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Cada dos semanas, desde mi último pago.'**
  String get onboardingCycleHelperBiweekly;

  /// No description provided for @cycleLastPayday.
  ///
  /// In es, this message translates to:
  /// **'Último día de pago'**
  String get cycleLastPayday;

  /// No description provided for @onboardingWhenLastPaid.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo fue tu último pago?'**
  String get onboardingWhenLastPaid;

  /// No description provided for @onboardingBiweeklyNeedsDate.
  ///
  /// In es, this message translates to:
  /// **'Elige el día de tu último pago.'**
  String get onboardingBiweeklyNeedsDate;

  /// No description provided for @pickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get pickDate;

  /// Joins the two halves of a movement's second line, such as its category and how it was paid. A locale that reads right to left, or that separates the halves differently, changes this pattern rather than the code.
  ///
  /// In es, this message translates to:
  /// **'{first} · {second}'**
  String movementSubtitle(String first, String second);

  /// No description provided for @settingsSectionAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsSectionAbout;

  /// No description provided for @settingsReleaseNotes.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get settingsReleaseNotes;

  /// No description provided for @settingsVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get settingsVersion;

  /// Stands in the version column when the platform will not report the running build, such as in a test harness. A dash rather than a number, because a wrong version is worse here than none.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get settingsVersionUnknown;

  /// No description provided for @releaseNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get releaseNotesTitle;

  /// Tag on the card for the version the phone is running.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get releaseNotesCurrent;

  /// Footnote under the list, saying why older versions are not there.
  ///
  /// In es, this message translates to:
  /// **'Guardamos las últimas {count} versiones.'**
  String releaseNotesRetention(int count);

  /// No description provided for @releaseNote102Schnauzer.
  ///
  /// In es, this message translates to:
  /// **'Schnauzer ya está en la colección. Dos anuncios cortos y se queda contigo.'**
  String get releaseNote102Schnauzer;

  /// No description provided for @releaseNote102Rooms.
  ///
  /// In es, this message translates to:
  /// **'La casa puede ser un jardín o la playa, y ya puedes colocar un sillón, una lámpara y un reloj.'**
  String get releaseNote102Rooms;

  /// No description provided for @releaseNote102Missions.
  ///
  /// In es, this message translates to:
  /// **'Dos de las tres misiones del día cambian cada día, y las que piden un paso más dan más XP.'**
  String get releaseNote102Missions;

  /// No description provided for @releaseNote102Amounts.
  ///
  /// In es, this message translates to:
  /// **'Los pesos colombianos, argentinos y chilenos, los reales y el euro ahora se escriben con coma, como 1.234,56.'**
  String get releaseNote102Amounts;

  /// No description provided for @releaseNote101Currencies.
  ///
  /// In es, this message translates to:
  /// **'Ahora puedes etiquetar tu dinero en pesos colombianos, argentinos y chilenos, soles, libras o yenes.'**
  String get releaseNote101Currencies;

  /// No description provided for @releaseNote101Celebration.
  ///
  /// In es, this message translates to:
  /// **'La celebración ahora llena la tarjeta y termina su salto.'**
  String get releaseNote101Celebration;

  /// No description provided for @releaseNote100Launch.
  ///
  /// In es, this message translates to:
  /// **'Primera versión de Sobrita.'**
  String get releaseNote100Launch;

  /// Heading of the dialog shown on launch when Google Play has a newer build waiting.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In es, this message translates to:
  /// **'Actualiza para tener lo último de Sobrita.'**
  String get updateAvailableBody;

  /// Names the build in hand inside the update dialog. Only the running version is shown: Play reports the waiting build as a version code, which means nothing to a reader.
  ///
  /// In es, this message translates to:
  /// **'Tu versión: v{version}'**
  String updateCurrentVersion(String version);

  /// Opens the Sobrita listing on Google Play. It does not install anything itself.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get updateAction;

  /// No description provided for @updateLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get updateLater;

  /// No description provided for @updateBannerMessage.
  ///
  /// In es, this message translates to:
  /// **'Versión nueva disponible'**
  String get updateBannerMessage;

  /// Screen-reader label for the banner's close button.
  ///
  /// In es, this message translates to:
  /// **'Cerrar el aviso'**
  String get updateBannerDismiss;

  /// No description provided for @updateStoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Google Play.'**
  String get updateStoreFailed;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualización'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsCheckUpdateBusy.
  ///
  /// In es, this message translates to:
  /// **'Buscando…'**
  String get settingsCheckUpdateBusy;

  /// No description provided for @settingsCheckUpdateUpToDate.
  ///
  /// In es, this message translates to:
  /// **'Ya estás al día.'**
  String get settingsCheckUpdateUpToDate;

  /// Ajustes row that opens the app's Google Play listing so the user can leave a rating.
  ///
  /// In es, this message translates to:
  /// **'Calificar Sobrita'**
  String get settingsRateApp;

  /// Opens the full Novedades screen from the card shown after an update.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get releaseAnnouncementViewAll;

  /// No description provided for @releaseAnnouncementDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get releaseAnnouncementDone;

  /// Screen-reader label for the dot on the Novedades row. The dot is the only thing that carries this meaning visually.
  ///
  /// In es, this message translates to:
  /// **'Novedades sin leer'**
  String get settingsReleaseNotesUnread;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
