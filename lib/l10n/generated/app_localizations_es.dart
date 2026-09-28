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
  String get xpLevelTitle6 => 'Michi experto';

  @override
  String get xpLevelTitle7 => 'Michi estratega';

  @override
  String get xpLevelTitle8 => 'Michi próspero';

  @override
  String get xpLevelTitle9 => 'Michi sabio';

  @override
  String get xpLevelTitle10 => 'Michi leyenda';

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
  String xpLevelUpTitle(int level) {
    return '¡NIVEL $level!';
  }

  @override
  String get xpLevelUpContinue => 'Seguir';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count objetos nuevos desbloqueados!',
      one: '¡Nuevo objeto desbloqueado!',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => 'Misión de hoy';

  @override
  String get dailyMissionResetHint =>
      'Cambian cada medianoche. No se acumulan.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done de $total listas';
  }

  @override
  String get dailyMissionAllDone => '¡Listas!';

  @override
  String get dailyMissionRecordTitle => 'Registra un movimiento hoy';

  @override
  String get dailyMissionRecordHint => 'Un gasto o un ingreso';

  @override
  String get dailyMissionSameDayTitle => 'Anótalo el mismo día';

  @override
  String get dailyMissionSameDayHint => 'El gasto y el registro, hoy';

  @override
  String get dailyMissionBudgetTitle => 'Revisa tu presupuesto';

  @override
  String get dailyMissionBudgetHint => 'Abre la pestaña Presupuesto';

  @override
  String get dailyMissionNoteTitle => 'Agrega una nota';

  @override
  String get dailyMissionNoteHint => 'Un movimiento con nota';

  @override
  String get dailyMissionReceiptTitle => 'Guarda un recibo';

  @override
  String get dailyMissionReceiptHint => 'Adjunta la foto a un gasto';

  @override
  String get dailyMissionThreeTodayTitle => 'Registra tres hoy';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '$count movimientos con fecha de hoy';
  }

  @override
  String get dailyMissionDone => 'Completada';

  @override
  String get dailyMissionPending => 'Pendiente';

  @override
  String dailyMissionReadyAt(String time) {
    return 'Listo · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done de $total listas · +$earned XP de +$possible XP hoy';
  }

  @override
  String get dailyMissionXpDetail => 'Misión completada';

  @override
  String get xpRuleDailyMission =>
      'Una vez al día; a medianoche empieza de nuevo';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misiones listas',
      one: 'Misión lista',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => 'XP por el hábito de hoy.';

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
  String get tabSettings => 'Mi Sobrita';

  @override
  String get collectionTitle => 'Colección';

  @override
  String get collectionSettingsValue => 'Ver';

  @override
  String get collectionCharacters => 'Personajes';

  @override
  String get collectionGuineaPigName => 'Cobaya';

  @override
  String get collectionItems => 'Objetos';

  @override
  String collectionLevel(int level) {
    return 'NIVEL $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned de $total';
  }

  @override
  String get collectionCharactersHint => 'Reúne a quien te acompaña';

  @override
  String get collectionItemsHint => 'Reúne lo que va en tu espacio';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'Personaje $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'Objeto $number';
  }

  @override
  String get collectionEquipped => 'EQUIPADO';

  @override
  String get collectionOwned => 'OBTENIDO';

  @override
  String get collectionPlaceIt => 'Colocarlo';

  @override
  String get collectionBuy => 'COMPRAR';

  @override
  String get collectionWatchAd => 'VER ANUNCIO';

  @override
  String get collectionAdLoading => 'PREPARANDO';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'Mira anuncios de recompensa · $progress/$target · uno por día';
  }

  @override
  String get collectionAdUnavailable => 'SIN ANUNCIOS';

  @override
  String get collectionAdDailyCap => 'LÍMITE DE HOY';

  @override
  String get collectionAdTomorrow => 'SIGUE MAÑANA';

  @override
  String collectionUnlockedNotice(String name) {
    return '¡$name es tuyo!';
  }

  @override
  String get collectionAdDismissedNotice =>
      'Mira el anuncio completo para que cuente.';

  @override
  String get collectionPackOnly => 'PAQUETE';

  @override
  String get collectionPackDecoration => 'Estrella de Michi';

  @override
  String get collectionPackUnlock =>
      'Llega con Michi y sus amigos. No se vende por separado.';

  @override
  String collectionAdProgress(int progress, int target) {
    return 'ANUNCIO $progress/$target';
  }

  @override
  String get collectionHowToGet => 'CÓMO OBTENERLO';

  @override
  String get collectionAlreadyOwned => 'Ya forma parte de tu colección.';

  @override
  String get collectionIncludedUnlock => 'Incluido desde el inicio.';

  @override
  String collectionPurchaseUnlock(String price) {
    return 'Compra única · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'Mira anuncios de recompensa · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'Se desbloquea en el nivel $level.';
  }

  @override
  String get collectionStorePricePending => 'precio de la tienda';

  @override
  String get collectionPreviewActionNotice =>
      'La compra y los anuncios se conectarán en una etapa posterior.';

  @override
  String get roomTitle => 'Mi casa';

  @override
  String get roomOpen => 'Abrir mi casa';

  @override
  String get roomDecorate => 'Decorar';

  @override
  String get roomDecorateTitle => 'Decorar';

  @override
  String get roomDone => 'Listo';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => 'Casa jardín';

  @override
  String get roomThemeCasaDePlaya => 'Casa de playa';

  @override
  String get roomChooseTheme => 'Elige el ambiente de tu casa.';

  @override
  String get roomCatReaction => '¡Hoy lo hiciste muy bien!';

  @override
  String get roomInstruction => 'Elige un objeto y toca el lugar donde va.';

  @override
  String get roomCategoryRooms => 'Casa';

  @override
  String get roomCategoryFurniture => 'Muebles';

  @override
  String get roomCategoryWallFloor => 'Pared y piso';

  @override
  String get roomCategoryProps => 'Adornos';

  @override
  String get roomCategoryCharacters => 'Personajes';

  @override
  String get roomCharacterInstruction => 'Elige quién te acompaña.';

  @override
  String get roomMoreInCollection => 'Ver más en la colección';

  @override
  String get roomDefaultRug => 'Tapete lavanda';

  @override
  String get roomFloorLamp => 'Lámpara verde';

  @override
  String get roomTablePlant => 'Planta de mesa';

  @override
  String get roomWallFrame => 'Cuadro';

  @override
  String get roomRattanChair => 'Sillón de ratán';

  @override
  String get roomStandingLamp => 'Lámpara de pie';

  @override
  String get roomWallClock => 'Reloj de pared';

  @override
  String get roomLowCabinet => 'Aparador bajo';

  @override
  String get roomPetBed => 'Cama para mascota';

  @override
  String get roomSavingsJar => 'Frasco de ahorros';

  @override
  String get roomWallShelf => 'Repisa de pared';

  @override
  String get roomTerracottaPouf => 'Puf terracota';

  @override
  String get roomBlueCreamRug => 'Tapete azul y crema';

  @override
  String get roomSuggestCabinet =>
      'Ponlo junto a la pared izquierda. Toca el lugar marcado.';

  @override
  String get roomSuggestPetBed =>
      'Ponla a la izquierda de tu compañero. Toca el lugar marcado.';

  @override
  String get roomSuggestSavingsJar =>
      'Prueba la mesa o el rincón del piso. Toca un lugar marcado.';

  @override
  String get roomSuggestWallShelf =>
      'Cuélgala en una pared libre. Toca un lugar marcado.';

  @override
  String get roomSuggestPouf =>
      'Equilibra la sala a la derecha. Toca el lugar marcado.';

  @override
  String get roomSuggestBlueRug =>
      'Ponlo debajo de tu compañero. Toca el lugar marcado.';

  @override
  String get roomSaved => 'Tu casa quedó guardada.';

  @override
  String get roomPlaced => 'Colocado';

  @override
  String get roomSurfaceWall => 'Pared';

  @override
  String get roomSurfaceFloor => 'Piso';

  @override
  String get roomSurfaceTabletop => 'Mesa';

  @override
  String get roomSurfaceRug => 'Tapete';

  @override
  String roomSlotLabel(String surface, int number) {
    return '$surface, lugar $number';
  }

  @override
  String roomPickWall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count lugares en la pared. Toca dónde va.',
      one: 'Hay un lugar en la pared. Tócalo para colgarlo.',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count lugares en el piso. Toca dónde va.',
      one: 'Hay un lugar en el piso. Tócalo para ponerlo.',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count lugares en la mesa. Toca dónde va.',
      one: 'Hay un lugar en la mesa. Tócalo para ponerlo.',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count lugares para el tapete. Toca dónde va.',
      one: 'Hay un lugar para el tapete. Tócalo para ponerlo.',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count lugares donde puede ir. Toca dónde va.',
      one: 'Hay un lugar donde puede ir. Tócalo para ponerlo.',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove =>
      'Toca otro lugar para moverlo, o el suyo para quitarlo.';

  @override
  String get roomTapToRemove => 'Toca su lugar otra vez para quitarlo.';

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
  String get settingsTitle => 'Mi Sobrita';

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
  String get currencyRegionAmericas => 'América';

  @override
  String get currencyRegionEurope => 'Europa';

  @override
  String get currencyRegionAsiaPacific => 'Asia y Oceanía';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsBudgetCycle => 'Ciclo de presupuesto';

  @override
  String get settingsCountDay => 'Día de conteo';

  @override
  String get settingsReduceMotionHint =>
      'Se activa solo si tu teléfono ya lo pide.';

  @override
  String get settingsQuickEntry => 'Acceso rápido';

  @override
  String get settingsQuickEntryHint =>
      'Muestra Ingreso y Gasto en la pantalla bloqueada.';

  @override
  String get quickEntryQuestion => '¿Qué quieres registrar?';

  @override
  String get quickEntryDenied =>
      'Permite las notificaciones de Sobrita para activar el acceso rápido.';

  @override
  String get widgetTodayLeft => 'Hoy te queda';

  @override
  String get widgetCycleBalance => 'Saldo';

  @override
  String get widgetOpenApp => 'Abre Sobrita';

  @override
  String get widgetRegisterExpense => 'Registrar gasto';

  @override
  String get settingsBackup => 'Respaldo de datos';

  @override
  String get settingsCopy => 'Copiar';

  @override
  String get settingsBackupCopied => 'Respaldo copiado al portapapeles.';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsAccount => 'Cuenta de Google';

  @override
  String get settingsAccountConnect => 'Conectar';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get purchaseRestored => 'Listo. Tus compras volvieron.';

  @override
  String get purchaseFailureStoreUnavailable =>
      'La tienda no está disponible ahora. Inténtalo más tarde.';

  @override
  String get purchaseFailureRejected =>
      'No se pudo completar la compra. No se te cobró nada.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      'Tu compra llegó, pero no se pudo guardar. Se aplicará la próxima vez que abras Sobrita.';

  @override
  String get purchaseFailureNothingToRestore =>
      'No encontramos compras en esta cuenta.';

  @override
  String get collectionPurchasing => 'COMPRANDO…';

  @override
  String get settingsXpPreview => 'Vista previa XP';

  @override
  String get settingsDesign => 'Diseño';

  @override
  String get settingsStorageNote =>
      'Tus datos se guardan en este dispositivo. No se necesita una cuenta para usar Sobrita.';

  @override
  String get settingsSectionShop => 'Tienda';

  @override
  String get settingsRemoveAds => 'Quitar anuncios generales';

  @override
  String get settingsRemoveAdsHint =>
      'Quita los anuncios del historial. Los de recompensa siguen disponibles.';

  @override
  String get settingsPackName => 'Michi y sus amigos';

  @override
  String get settingsPackHint =>
      '3 personajes + la estrella de Michi. También quita los anuncios generales.';

  @override
  String get settingsOwned => 'Ya lo tienes';

  @override
  String get settingsShopRestoreNote =>
      'Las compras se guardan en tu cuenta de la tienda. Puedes recuperarlas al reinstalar.';

  @override
  String get settlementTitle => 'Cierre de este ciclo';

  @override
  String get settlementSpent => 'Gastado';

  @override
  String get settlementLeft => 'Sobrante';

  @override
  String get settlementOver => 'Pasaste';

  @override
  String get settlementAverage => 'Promedio diario';

  @override
  String get settlementContinue => 'Listo';

  @override
  String get settlementCtaTitle => 'Ir por un adorno especial';

  @override
  String get settlementCtaAction => 'Ver colección';

  @override
  String get settingsSectionBudget => 'Presupuesto';

  @override
  String get settingsSectionScreen => 'Pantalla';

  @override
  String get settingsSectionData => 'Datos';

  @override
  String get settingsSectionPrivacy => 'Privacidad';

  @override
  String get settingsAdPrivacy => 'Privacidad de anuncios';

  @override
  String get settingsAdPrivacyValue => 'Administrar';

  @override
  String get settingsAdPrivacyFailed =>
      'No se pudieron abrir las opciones de privacidad. Inténtalo de nuevo.';

  @override
  String get settingsSectionDesign => 'Diseño';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '$movements movimientos',
      one: '1 movimiento',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días con Sobrita',
      one: '1 día con Sobrita',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languageAutomaticHint => 'Sigue tu teléfono';

  @override
  String get transactionsTitle => 'Movimientos';

  @override
  String get dailySpendTitle => 'Gasto por día';

  @override
  String dailySpendLimit(String amount) {
    return 'Límite de $amount al día';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return 'Este ciclo $amount';
  }

  @override
  String get dailyIncomeTitle => 'Ingreso por día';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return 'Este ciclo $amount';
  }

  @override
  String get transactionsEmptyTitle => 'Aún no hay movimientos';

  @override
  String get transactionsEmptyMessage =>
      'Registra tu primer gasto y aquí verás el resumen del ciclo.';

  @override
  String get transactionsEmptyExpensesTitle => 'Aún no hay gastos';

  @override
  String get transactionsEmptyExpensesMessage =>
      'Registra un gasto y aquí verás el día a día.';

  @override
  String get transactionsEmptyIncomesTitle => 'Aún no hay ingresos';

  @override
  String get transactionsEmptyIncomesMessage =>
      'Registra un ingreso y aquí verás el día a día.';

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
  String get appName => 'Sobrita';

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
  String get homeFirstQuestLabel => 'Primera misión';

  @override
  String get homeBudgetQuestBody =>
      'Ponle un presupuesto y te digo cuánto puedes gastar cada día.';

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
  String get budgetNotSetTitle => 'Aún no hay presupuesto';

  @override
  String get budgetNotSetBody =>
      'Defínelo y calculamos cuánto puedes gastar cada día.';

  @override
  String get budgetSetAction => 'Definir presupuesto';

  @override
  String budgetTooLow(String allocated) {
    return 'El total debe ser mayor que los ingresos asignados al ciclo ($allocated).';
  }

  @override
  String budgetSpentShare(int percent) {
    return '$percent% del presupuesto';
  }

  @override
  String budgetRingSpent(String amount) {
    return 'Gastado $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return 'Queda $amount';
  }

  @override
  String budgetCategoryShare(int percent) {
    return '$percent%';
  }

  @override
  String get cycleHistoryTitle => 'Ciclos anteriores';

  @override
  String cycleHistorySummary(int green, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$green de $total ciclos en verde',
      one: '$green de $total ciclo en verde',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return 'Presupuesto $budget · Gastado $spent';
  }

  @override
  String get cycleHistoryEmpty => 'Aún no se ha cerrado ningún ciclo.';

  @override
  String cycleHistoryAverage(String amount) {
    return 'Promedio diario $amount';
  }

  @override
  String get cycleHistoryAveragePending => 'Promedio diario · reuniendo datos';

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
  String get receiptTitle => 'Ticket';

  @override
  String get receiptAdd => 'Agregar ticket';

  @override
  String get receiptCamera => 'Cámara';

  @override
  String get receiptGallery => 'Galería';

  @override
  String get receiptChange => 'Cambiar';

  @override
  String get receiptRemove => 'Quitar';

  @override
  String get receiptHint => 'Una foto para recordar qué fue este gasto.';

  @override
  String get receiptAttached => 'Ticket adjunto';

  @override
  String get receiptView => 'Ver ticket';

  @override
  String get receiptClose => 'Cerrar';

  @override
  String get receiptMissing => 'La foto ya no está en este dispositivo.';

  @override
  String get receiptFailed => 'No se pudo guardar la foto.';

  @override
  String get receiptBackupNote => 'La copia no incluye las fotos de tickets.';

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
  String get prologueRainNoEnd => 'La lluvia no daba señales de parar.';

  @override
  String get prologueRentPaid =>
      'La renta estaba pagada, y en la cuenta quedaba lo justo hasta el próximo pago.';

  @override
  String get prologueSoundAtDoor => 'Algo se movió junto a la puerta.';

  @override
  String get prologueGoLook => 'Ir a ver';

  @override
  String get prologueWetTracks =>
      'Dos hileras de huellas mojadas cruzaron el piso.';

  @override
  String get prologueShelter => 'Déjanos esperar a que pase.';

  @override
  String get prologueItSpoke => '…habló.';

  @override
  String get prologueReplySurprised => '¿Acabas de hablar?';

  @override
  String get prologueReplyTowel => '(traes una toalla sin decir nada)';

  @override
  String get prologueEarnKeep =>
      'Algo tengo que aportar. Yo llevo los números.';

  @override
  String get prologueAskSchedule => 'Primero: ¿cuándo entra el dinero?';

  @override
  String get prologueAskPayday =>
      '¿Qué día te pagan? Con el primero me basta; el resto lo cuento yo.';

  @override
  String prologueAskBudget(int days) {
    return 'Faltan $days días para el próximo pago. ¿Cuánto piensas gastar?';
  }

  @override
  String get prologueSkipIsFine => 'Puedes saltarlo. Te lo recuerdo en casa.';

  @override
  String get prologueSkip => 'Saltar';

  @override
  String get prologueDriedOff =>
      'Secos, los dos se calmaron. Afuera seguía lloviendo.';

  @override
  String get prologueWhoSits => '¿Quién se sienta contigo?';

  @override
  String get prologueMichiTrait => 'Callado.\nBueno con los números.';

  @override
  String get prologuePoodleName => 'Poodle';

  @override
  String get prologuePoodleTrait => 'Puro ánimo.\nMuy atento.';

  @override
  String get prologueSchnauzerName => 'Schnauzer';

  @override
  String get prologueSchnauzerTrait => 'Observador.\nSiempre atento.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'Puro ánimo.\nMuy atento.';

  @override
  String get prologueLockedSoon => 'Arte en camino';

  @override
  String get prologueOtherStays =>
      'El otro también se queda. Puedes cambiar de compañero más adelante.';

  @override
  String get prologueLiveTogether => 'Que se queden';

  @override
  String prologueGreeting(String name) {
    return 'Me llamo $name. Gracias por abrir.';
  }

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingTagline => 'Tu dinero, sin presión.';

  @override
  String get onboardingPromise => 'Te decimos cuánto puedes gastar hoy.';

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
  String get onboardingBudgetLater => 'Puedes ponerlo después desde Inicio.';

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
  String onboardingSettledIn(String name) {
    return 'Dejó de llover. $name se acomodó a tu lado.';
  }

  @override
  String get onboardingFirstQuests => 'Tus primeras misiones';

  @override
  String get onboardingWaitingAtHome => 'Te espera en casa';

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

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsReleaseNotes => 'Novedades';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => 'Novedades';

  @override
  String get releaseNotesCurrent => 'Actual';

  @override
  String releaseNotesRetention(int count) {
    return 'Guardamos las últimas $count versiones.';
  }

  @override
  String get releaseNote103GuineaPig =>
      'Cobaya ya está en la colección. Dos anuncios cortos y se queda contigo.';

  @override
  String get releaseNote103Widget =>
      'El widget de inicio muestra con quién vives, y el monto se escribe igual que en la app.';

  @override
  String get releaseNote102Schnauzer =>
      'Schnauzer ya está en la colección. Dos anuncios cortos y se queda contigo.';

  @override
  String get releaseNote102Rooms =>
      'La casa puede ser un jardín o la playa, y ya puedes colocar un sillón, una lámpara y un reloj.';

  @override
  String get releaseNote102Missions =>
      'Dos de las tres misiones del día cambian cada día, y las que piden un paso más dan más XP.';

  @override
  String get releaseNote102Amounts =>
      'Los pesos colombianos, argentinos y chilenos, los reales y el euro ahora se escriben con coma, como 1.234,56.';

  @override
  String get releaseNote101Currencies =>
      'Ahora puedes etiquetar tu dinero en pesos colombianos, argentinos y chilenos, soles, libras o yenes.';

  @override
  String get releaseNote101Celebration =>
      'La celebración ahora llena la tarjeta y termina su salto.';

  @override
  String get releaseNote100Launch => 'Primera versión de Sobrita.';

  @override
  String get updateAvailableTitle => 'Hay una versión nueva';

  @override
  String get updateAvailableBody =>
      'Actualiza para tener lo último de Sobrita.';

  @override
  String updateCurrentVersion(String version) {
    return 'Tu versión: v$version';
  }

  @override
  String get updateAction => 'Actualizar';

  @override
  String get updateLater => 'Ahora no';

  @override
  String get updateBannerMessage => 'Versión nueva disponible';

  @override
  String get updateBannerDismiss => 'Cerrar el aviso';

  @override
  String get updateStoreFailed => 'No se pudo abrir Google Play.';

  @override
  String get settingsCheckUpdate => 'Buscar actualización';

  @override
  String get settingsCheckUpdateBusy => 'Buscando…';

  @override
  String get settingsCheckUpdateUpToDate => 'Ya estás al día.';

  @override
  String get settingsRateApp => 'Calificar Sobrita';

  @override
  String get releaseAnnouncementViewAll => 'Ver todo';

  @override
  String get releaseAnnouncementDone => 'Listo';

  @override
  String get settingsReleaseNotesUnread => 'Novedades sin leer';
}
