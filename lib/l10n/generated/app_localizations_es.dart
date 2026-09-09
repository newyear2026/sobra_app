// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get categoryFood => 'Comida';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categoryHome => 'Hogar';

  @override
  String get categoryServices => 'Servicios';

  @override
  String get categoryHealth => 'Salud';

  @override
  String get categoryEducation => 'Educación';

  @override
  String get categoryEntertainment => 'Ocio';

  @override
  String get categoryPets => 'Mascotas';

  @override
  String get categoryOther => 'Otros';

  @override
  String get incomeKindSalary => 'Mi pago de siempre';

  @override
  String get incomeKindExtra => 'Ingreso extra';

  @override
  String get incomeKindCash => 'Ingreso en efectivo';

  @override
  String get incomeKindRefund => 'Devolución';

  @override
  String get incomeAllocationCycle => 'Este ciclo';

  @override
  String get incomeAllocationSavings => 'Ahorro';

  @override
  String get payCycleSemiMonthly => 'Quincenal';

  @override
  String get payCycleBiweekly => 'Cada 14 días';

  @override
  String get payCycleMonthly => 'Mensual';

  @override
  String get payCycleWeekly => 'Semanal';

  @override
  String get payCycleIrregular => 'Sin fecha fija';

  @override
  String get cashResolutionExpense => 'Gasto identificado';

  @override
  String get cashResolutionIncome => 'Ingreso en efectivo';

  @override
  String get cashResolutionTransfer => 'Movimiento entre cuentas';

  @override
  String get cashResolutionCorrection => 'Corrección del conteo';

  @override
  String get cashResolutionPending => 'Diferencia por identificar';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodCard => 'Tarjeta';

  @override
  String get movementPending => 'Pendiente';

  @override
  String get movementCashCount => 'Conteo de efectivo';

  @override
  String get xpCashCountTitle => 'Conteo de efectivo';

  @override
  String get xpCashCountDetail => 'Primer conteo con XP de la semana';

  @override
  String get xpCycleInGreenSemiMonthly => 'Cerraste la quincena en verde';

  @override
  String get xpCycleInGreenMonthly => 'Cerraste el mes en verde';

  @override
  String get xpCycleInGreenWeekly => 'Cerraste la semana en verde';

  @override
  String get xpCycleInGreenGeneric => 'Cerraste el ciclo en verde';

  @override
  String get xpCycleInGreenDetail => 'Resultado del presupuesto al cerrar';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días bajo tu límite',
      one: '$count día bajo tu límite',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail => 'Calculado una sola vez al cerrar';

  @override
  String get xpFirstSuccessfulCycleTitle => 'Primer ciclo en verde';

  @override
  String get xpFirstSuccessfulCycleDetail => 'Bono de una sola vez';

  @override
  String get xpLevelTitle1 => 'Michi curioso';

  @override
  String get xpLevelTitle2 => 'Michi ahorrador';

  @override
  String get xpLevelTitle3 => 'Michi contador';

  @override
  String get xpLevelTitle4 => 'Michi guardián';

  @override
  String get xpLevelTitle5 => 'Michi maestro';

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ciclos cerrados',
      one: 'Ciclo cerrado',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP acreditados automáticamente.';

  @override
  String get xpNoticeCashCountTitle => 'Conteo de efectivo guardado';

  @override
  String get xpNoticeCashCountDetail => 'Primer conteo con XP de la semana.';

  @override
  String get storeFailureGeneric =>
      'No pudimos guardar el cambio. Vuelve a intentarlo.';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      'El total debe ser mayor que los ingresos asignados al ciclo.';

  @override
  String get storeFailureFutureMovement =>
      'No se permiten movimientos futuros.';

  @override
  String get storeFailureRestoreFailed => 'No se pudo restaurar el respaldo.';

  @override
  String get storeFailureOriginalNotKept =>
      'No se pudo conservar el archivo original.';

  @override
  String get storeFailureBackupNotSaved => 'No se pudo guardar el respaldo.';

  @override
  String get storeFailureSaveFailed => 'No se pudieron guardar los datos.';

  @override
  String get monthAbbr1 => 'ene';

  @override
  String get monthAbbr2 => 'feb';

  @override
  String get monthAbbr3 => 'mar';

  @override
  String get monthAbbr4 => 'abr';

  @override
  String get monthAbbr5 => 'may';

  @override
  String get monthAbbr6 => 'jun';

  @override
  String get monthAbbr7 => 'jul';

  @override
  String get monthAbbr8 => 'ago';

  @override
  String get monthAbbr9 => 'sep';

  @override
  String get monthAbbr10 => 'oct';

  @override
  String get monthAbbr11 => 'nov';

  @override
  String get monthAbbr12 => 'dic';

  @override
  String get back => 'Volver';

  @override
  String get reduceMotion => 'Reducir movimiento';

  @override
  String get catMotionIdle => 'El gato descansa tranquilo';

  @override
  String get catMotionWalk => 'El gato camina';

  @override
  String get catMotionCalculate => 'El gato hace cuentas';

  @override
  String get catMotionSaving => 'El gato guarda monedas en la alcancía';

  @override
  String get catMotionCelebrate => 'El gato celebra contento';

  @override
  String get catMotionConcern =>
      'El gato muestra preocupación por el presupuesto';

  @override
  String get characterRoleIdle => 'El personaje descansa tranquilo';

  @override
  String get characterRoleActivity => 'El personaje está en movimiento';

  @override
  String get characterRoleProcessing => 'El personaje está haciendo cuentas';

  @override
  String get characterRolePositive => 'El personaje muestra un cambio positivo';

  @override
  String get characterRoleSuccess => 'El personaje celebra un logro';

  @override
  String get characterRoleWarning => 'El personaje muestra preocupación';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabMovements => 'Movim.';

  @override
  String get tabRegister => 'Registrar';

  @override
  String get tabBudget => 'Presup.';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get xpHistoryTitle => 'Tu progreso';

  @override
  String xpTotal(int count) {
    return '$count XP totales';
  }

  @override
  String get xpMaxLevel => 'Nivel máximo';

  @override
  String xpRemaining(int count) {
    return 'Faltan $count XP';
  }

  @override
  String get xpHistoryHint =>
      'El XP se acredita automáticamente. Cada fila conserva la razón y el cálculo, aunque cierres la app.';

  @override
  String get xpHistoryEmptyTitle => 'Aún no hay XP';

  @override
  String get xpHistoryEmptyMessage =>
      'El primer conteo de efectivo de la semana y el cierre de tu ciclo aparecerán aquí.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => 'Ver cálculo';

  @override
  String get xpCalculationTitle => 'Cómo se calculó';

  @override
  String get xpDetailCycle => 'Ciclo';

  @override
  String get xpDetailBudget => 'Presupuesto';

  @override
  String get xpDetailSpent => 'Gastado';

  @override
  String get xpDetailResult => 'Resultado';

  @override
  String get xpDetailRule => 'Regla';

  @override
  String get xpDetailCredited => 'XP acreditado';

  @override
  String get xpRuleCashCount => 'Máximo una vez por semana';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recompensa normalizada por $count días',
      one: 'Recompensa normalizada por $count día',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días × 5 XP',
      one: '$count día × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => 'Bono único de 50 XP';

  @override
  String get recoveryNotYet => 'No pudimos recuperar los datos todavía.';

  @override
  String get recoveryStartFreshQuestion => '¿Empezar de nuevo?';

  @override
  String get recoveryStartFreshBody =>
      'Conservaremos una copia del archivo original antes de crear datos nuevos.';

  @override
  String get recoveryStartFresh => 'Empezar de nuevo';

  @override
  String get recoveryTitle => 'No pudimos leer tus datos';

  @override
  String get recoveryOriginalKept =>
      'El archivo original sigue guardado. No lo reemplazamos ni borramos.';

  @override
  String get recoveryOptions =>
      'Puedes reintentar, usar el respaldo o exportar el archivo para conservarlo.';

  @override
  String get recoveryRetrying => 'Reintentando…';

  @override
  String get recoveryRetry => 'Reintentar';

  @override
  String get recoveryUseBackup => 'Usar respaldo';

  @override
  String get recoveryExport => 'Exportar archivo';

  @override
  String get recoveryExported => 'Archivo original copiado.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String currencyChangeTitle(String code) {
    return '¿Cambiar a $code?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return 'Tus montos no se convierten: $example seguirá siendo $converted. Solo cambia la etiqueta.';
  }

  @override
  String get currencyChangeConfirm => 'Cambiar etiqueta';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsBudgetCycle => 'Ciclo de presupuesto';

  @override
  String get settingsCountDay => 'Día de conteo';

  @override
  String get settingsCountDaySunday => 'Domingo';

  @override
  String get settingsReduceMotionHint =>
      'Se activa solo si tu teléfono ya lo pide.';

  @override
  String get settingsBackup => 'Respaldo de datos';

  @override
  String get settingsCopy => 'Copiar';

  @override
  String get settingsBackupCopied => 'Respaldo copiado al portapapeles.';

  @override
  String get settingsXpPreview => 'Vista previa XP';

  @override
  String get settingsDesign => 'Diseño';

  @override
  String get settingsStorageNote =>
      'Tus datos se guardan en este dispositivo. No se necesita una cuenta para usar Sobra.';

  @override
  String get settingsFixedInV1 => 'Esta opción queda fija en la versión 1.';

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languageAutomaticHint => 'Sigue tu teléfono';

  @override
  String get transactionsTitle => 'Movimientos';

  @override
  String get transactionsEmptyTitle => 'Aún no hay movimientos';

  @override
  String get transactionsEmptyMessage =>
      'Registra tu primer gasto y aquí verás el resumen del ciclo.';

  @override
  String get transactionsExpensePinned =>
      'Este gasto viene de un conteo de efectivo. Vuelve a contar para corregirlo.';

  @override
  String get transactionsIncomePinned =>
      'Este ingreso viene de un conteo de efectivo. Vuelve a contar para corregirlo.';

  @override
  String get transactionsExpenseDeleted => 'Movimiento eliminado.';

  @override
  String get transactionsIncomeDeleted => 'Ingreso eliminado.';

  @override
  String get undo => 'Deshacer';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get identifyDifference => 'Identificar diferencia';

  @override
  String get editMovement => 'Editar movimiento';

  @override
  String get amount => 'Monto';

  @override
  String get editPendingHint =>
      'El monto viene de tu conteo de efectivo. Puedes cambiar la categoría y la nota.';

  @override
  String get category => 'Categoría';

  @override
  String get note => 'Nota';

  @override
  String get noteExample => 'Ej. Tacos';

  @override
  String get replacesPendingHint =>
      'Esto reemplaza el ajuste pendiente. No suma otro gasto.';

  @override
  String get saveWithoutDuplicating => 'Guardar sin duplicar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get save => 'Guardar';

  @override
  String get budget => 'Presupuesto';

  @override
  String get spent => 'Gastado';

  @override
  String get appName => 'Sobra';

  @override
  String get homeCycleBalance => 'Saldo del ciclo';

  @override
  String get homeTodayLeft => 'Hoy te queda';

  @override
  String homeOverBudget(String budget) {
    return 'Te pasaste del presupuesto de $budget de este ciclo';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return 'Límite de hoy $limit · Quedan $remaining en el ciclo';
  }

  @override
  String get homeCycleProgress => 'Avance del ciclo';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => 'Efectivo estimado';

  @override
  String get homeCashUnset => 'Efectivo sin configurar';

  @override
  String homeLastCount(String amount) {
    return 'Último conteo: $amount';
  }

  @override
  String get homeFirstCountHint => 'Haz un primer conteo para empezar.';

  @override
  String get homeRecentMovements => 'Movimientos recientes';

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get homeGoingWell => 'Vas muy bien';

  @override
  String get homeAdjustCalmly => 'Ajustemos con calma';

  @override
  String get budgetTitle => 'Presupuesto';

  @override
  String get budgetCycleTotal => 'Total del ciclo';

  @override
  String get budgetTotal => 'Presupuesto total';

  @override
  String budgetTooLow(String allocated) {
    return 'El total debe ser mayor que los ingresos asignados al ciclo ($allocated).';
  }

  @override
  String get budgetChangedTitle => 'Cambiaste tu presupuesto';

  @override
  String get budgetChangedBody =>
      '¿Qué hacemos con los límites por categoría? Al ajustarlos, cada uno cambia en la misma proporción y conservas tu reparto.';

  @override
  String get budgetKeepLimits => 'Conservarlos';

  @override
  String get budgetScaleLimits => 'Ajustarlos proporcionalmente';

  @override
  String get budgetByCategory => 'Presupuesto por categoría';

  @override
  String budgetCategoryLimit(String category) {
    return 'Límite de $category';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => 'Proyección al cierre';

  @override
  String get budgetEstimatedLeft => 'Estimado que te quedará';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get saving => 'Guardando…';

  @override
  String dayOfMonth(int day) {
    return 'Día $day';
  }

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayShortMonday => 'Lun';

  @override
  String get weekdayShortTuesday => 'Mar';

  @override
  String get weekdayShortWednesday => 'Mié';

  @override
  String get weekdayShortThursday => 'Jue';

  @override
  String get weekdayShortFriday => 'Vie';

  @override
  String get weekdayShortSaturday => 'Sáb';

  @override
  String get weekdayShortSunday => 'Dom';

  @override
  String get registerTitle => 'Registrar';

  @override
  String get registerExpense => 'Gasto';

  @override
  String get registerIncome => 'Ingreso';

  @override
  String get registerAmountAboveZero => 'Ingresa un monto mayor a cero.';

  @override
  String get registerNoFutureMovements =>
      'No puedes registrar movimientos futuros.';

  @override
  String get registerDate => 'Fecha';

  @override
  String get registerNoteExpenseExample => 'Ej. Taquería El Faro';

  @override
  String get registerNoteIncomeExample => 'Ej. Propina del viernes';

  @override
  String get registerPayment => 'Pago';

  @override
  String get registerPaymentHint =>
      'El efectivo se descuenta de tu conteo. La tarjeta no.';

  @override
  String get registerIncomeKind => 'Tipo de ingreso';

  @override
  String get registerWhatToDo => '¿Qué quieres hacer?';

  @override
  String get registerThisCycle => 'Este ciclo';

  @override
  String get registerSaveIt => 'Guardarlo';

  @override
  String get registerReceivedIn => 'Lo recibiste en';

  @override
  String get registerAccount => 'Cuenta';

  @override
  String get registerReconcileQuestion => '¿Este gasto explica la diferencia?';

  @override
  String registerReconcileBody(String amount) {
    return 'Tienes $amount pendiente del último conteo. Si es el mismo gasto, lo identificaremos sin sumarlo otra vez.';
  }

  @override
  String get registerReconcileNo => 'No, es nuevo';

  @override
  String get registerReconcileYes => 'Sí, conciliar';

  @override
  String get registerDifferenceReconciled => 'Diferencia conciliada';

  @override
  String get registerExpenseSaved => 'Gasto guardado';

  @override
  String get registerIncomeSaved => 'Ingreso guardado';

  @override
  String get cashCountTitle => 'Conteo de efectivo';

  @override
  String get cashCountPickWhatHappened => 'Elige qué pasó con la diferencia.';

  @override
  String get cashCountSavedWithoutDuplicates =>
      'Conteo guardado sin duplicar movimientos.';

  @override
  String get cashCountPrompt => 'Cuenta solo el efectivo que tienes ahora.';

  @override
  String get cashCountNoneYet => 'Sin conteo todavía';

  @override
  String get cashCountResultPending =>
      'El resultado aparecerá después de escribir el conteo.';

  @override
  String get cashCountBaselineHint =>
      'Este será tu punto de partida. No se registrará como ingreso.';

  @override
  String get cashCountExpected => 'Esperábamos';

  @override
  String get cashCountCounted => 'Contaste';

  @override
  String get cashCountBalanced => 'Todo cuadra';

  @override
  String cashCountShort(String amount) {
    return 'Faltan $amount';
  }

  @override
  String cashCountExtra(String amount) {
    return 'Hay $amount de más';
  }

  @override
  String get cashCountWhatHappened => '¿Qué pasó?';

  @override
  String get cashCountHelperExpense => 'Fue un gasto que no habías registrado.';

  @override
  String get cashCountHelperIncome => 'Fue dinero nuevo que recibiste.';

  @override
  String get cashCountHelperTransferOut =>
      'Lo depositaste o lo moviste a otra cuenta.';

  @override
  String get cashCountHelperTransferIn =>
      'Lo retiraste o lo moviste desde otra cuenta.';

  @override
  String get cashCountHelperCorrection =>
      'El conteo anterior estaba equivocado.';

  @override
  String get cashCountHelperPending => 'Decídelo después.';

  @override
  String get cashCountSingleExpenseHint =>
      'Esto crea un solo gasto. No tendrás que registrarlo otra vez.';

  @override
  String get cashCountNoteTipExample => 'Ej. Propina';

  @override
  String get cashCountWhatToDoWithMoney => '¿Qué hacemos con este dinero?';

  @override
  String get cashCountSaveFirst => 'Guardar primer conteo';

  @override
  String get cashCountSave => 'Guardar conteo';

  @override
  String get cycleTitle => 'Tu ciclo';

  @override
  String get cycleCurrent => 'Ciclo actual';

  @override
  String get cycleInProgress => 'En curso';

  @override
  String get cycleUnchanged => 'No cambiará';

  @override
  String get cycleNewFrequency => 'Nueva frecuencia';

  @override
  String get cycleFirstPay => 'Primer pago';

  @override
  String get cyclePayDay => 'Día de pago';

  @override
  String get cycleNext => 'Próximo ciclo';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return 'El cambio se aplicará al siguiente ciclo y después se renovará cada $days días.';
  }

  @override
  String get cycleChangeApplies => 'El cambio se aplicará al siguiente ciclo.';

  @override
  String get cycleSaveChange => 'Guardar cambio';

  @override
  String get onboardingBudgetAboveZero =>
      'Ingresa un presupuesto mayor a cero.';

  @override
  String get onboardingCashOrSkip => 'Ingresa el efectivo o elige “Ahora no”.';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingTagline => 'Tu dinero, sin presión.';

  @override
  String get onboardingPromise => 'Te decimos cuánto puedes gastar hoy.';

  @override
  String get onboardingNoAccount => 'Sin cuenta. Tus datos se quedan contigo.';

  @override
  String get onboardingHowPaid => '¿Cómo recibes tus ingresos?';

  @override
  String get onboardingHowPaidHint =>
      'Esto define las fechas de tu presupuesto.';

  @override
  String get onboardingCycleHelperSemiMonthly =>
      'Dos pagos al mes: el 15 y el fin de mes.';

  @override
  String get onboardingCycleHelperMonthly => 'Un pago al mes.';

  @override
  String get onboardingCycleHelperWeekly => 'Cada semana.';

  @override
  String get onboardingCycleHelperIrregular =>
      'Mis ingresos no tienen fecha fija.';

  @override
  String get onboardingPlanWithoutFixedDate => 'Planea sin una fecha fija';

  @override
  String get onboardingWhichDayPaid => '¿Qué día recibes dinero?';

  @override
  String get onboardingSecondPayEndOfMonth => 'Segundo pago · fin de mes';

  @override
  String get onboardingHowManyDays => '¿Para cuántos días quieres planear?';

  @override
  String get onboardingCyclePreview => 'Tu ciclo quedaría así';

  @override
  String onboardingRepeatsEvery(int days) {
    return 'Al terminar, comenzará automáticamente otro periodo de $days días.';
  }

  @override
  String get onboardingShortMonthsNote =>
      'Las fechas se ajustan solas en meses cortos.';

  @override
  String get onboardingBudgetQuestion =>
      '¿Cuánto quieres gastar\nen este ciclo?';

  @override
  String get onboardingNotNow => 'Ahora no';

  @override
  String get onboardingCashQuestion => '¿Cuánto efectivo\ntienes hoy?';

  @override
  String get onboardingCashOptional =>
      'Déjalo vacío si prefieres contarlo después.';

  @override
  String get onboardingCashIsBaseline =>
      'Este será tu primer conteo, no un ingreso.';

  @override
  String get onboardingGoHome => 'Ir a Inicio';

  @override
  String get onboardingPlanReady => 'Tu plan está listo';

  @override
  String get onboardingCanSpendToday => 'Hoy puedes gastar';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step de $total';
  }

  @override
  String progressPercent(int percent) {
    return 'Progreso $percent por ciento';
  }

  @override
  String stepOf(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly => 'Cerraste las dos semanas en verde';

  @override
  String get onboardingCycleHelperBiweekly =>
      'Cada dos semanas, desde mi último pago.';

  @override
  String get cycleLastPayday => 'Último día de pago';

  @override
  String get onboardingWhenLastPaid => '¿Cuándo fue tu último pago?';

  @override
  String get onboardingBiweeklyNeedsDate => 'Elige el día de tu último pago.';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }
}
