// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get categoryFood => 'Comida';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categoryHome => 'Casa';

  @override
  String get categoryServices => 'Contas';

  @override
  String get categoryHealth => 'Saúde';

  @override
  String get categoryEducation => 'Educação';

  @override
  String get categoryEntertainment => 'Lazer';

  @override
  String get categoryPets => 'Pets';

  @override
  String get categoryOther => 'Outros';

  @override
  String get incomeKindSalary => 'Meu pagamento de sempre';

  @override
  String get incomeKindExtra => 'Renda extra';

  @override
  String get incomeKindCash => 'Entrada em dinheiro';

  @override
  String get incomeKindRefund => 'Reembolso';

  @override
  String get incomeAllocationCycle => 'Este ciclo';

  @override
  String get incomeAllocationSavings => 'Poupança';

  @override
  String get payCycleSemiMonthly => 'Quinzenal';

  @override
  String get payCycleBiweekly => 'A cada 14 dias';

  @override
  String get payCycleMonthly => 'Mensal';

  @override
  String get payCycleWeekly => 'Semanal';

  @override
  String get payCycleIrregular => 'Sem data fixa';

  @override
  String get cashResolutionExpense => 'Gasto identificado';

  @override
  String get cashResolutionIncome => 'Entrada em dinheiro';

  @override
  String get cashResolutionTransfer => 'Movido entre contas';

  @override
  String get cashResolutionCorrection => 'Correção da contagem';

  @override
  String get cashResolutionPending => 'Diferença a identificar';

  @override
  String get paymentMethodCash => 'Dinheiro';

  @override
  String get paymentMethodCard => 'Cartão';

  @override
  String get movementPending => 'Pendente';

  @override
  String get movementCashCount => 'Contagem do dinheiro';

  @override
  String get xpCashCountTitle => 'Contagem do dinheiro';

  @override
  String get xpCashCountDetail => 'Primeira contagem com XP da semana';

  @override
  String get xpCycleInGreenSemiMonthly => 'Você fechou a quinzena no azul';

  @override
  String get xpCycleInGreenMonthly => 'Você fechou o mês no azul';

  @override
  String get xpCycleInGreenWeekly => 'Você fechou a semana no azul';

  @override
  String get xpCycleInGreenGeneric => 'Você fechou o ciclo no azul';

  @override
  String get xpCycleInGreenDetail => 'Resultado do orçamento no fechamento';

  @override
  String xpDaysUnderDailyLimitTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias abaixo do seu limite',
      one: '$count dia abaixo do seu limite',
      zero: '$count dias abaixo do seu limite',
    );
    return '$_temp0';
  }

  @override
  String get xpDaysUnderDailyLimitDetail =>
      'Calculado uma só vez, no fechamento';

  @override
  String get xpFirstSuccessfulCycleTitle => 'Primeiro ciclo no azul';

  @override
  String get xpFirstSuccessfulCycleDetail => 'Bônus único';

  @override
  String xpLevelTitle1(String name) {
    return '$name curioso';
  }

  @override
  String xpLevelTitle2(String name) {
    return '$name poupador';
  }

  @override
  String xpLevelTitle3(String name) {
    return '$name contador';
  }

  @override
  String xpLevelTitle4(String name) {
    return '$name guardião';
  }

  @override
  String xpLevelTitle5(String name) {
    return '$name mestre';
  }

  @override
  String xpLevelTitle6(String name) {
    return '$name especialista';
  }

  @override
  String xpLevelTitle7(String name) {
    return '$name estrategista';
  }

  @override
  String xpLevelTitle8(String name) {
    return '$name próspero';
  }

  @override
  String xpLevelTitle9(String name) {
    return '$name sábio';
  }

  @override
  String xpLevelTitle10(String name) {
    return '$name lendário';
  }

  @override
  String xpNoticeCyclesClosedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ciclos fechados',
      one: 'Ciclo fechado',
      zero: '$count ciclos fechados',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeCyclesClosedDetail => 'XP creditado automaticamente.';

  @override
  String get xpNoticeCashCountTitle => 'Contagem salva';

  @override
  String get xpNoticeCashCountDetail => 'Primeira contagem com XP da semana.';

  @override
  String xpLevelUpTitle(int level) {
    return 'NÍVEL $level!';
  }

  @override
  String get xpLevelUpContinue => 'Continuar';

  @override
  String xpLevelUpItemsUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens novos desbloqueados!',
      one: 'Novo item desbloqueado!',
      zero: '$count itens novos desbloqueados!',
    );
    return '$_temp0';
  }

  @override
  String get dailyMissionTitle => 'Missão de hoje';

  @override
  String get dailyMissionResetHint => 'Mudam à meia-noite. Não se acumulam.';

  @override
  String dailyMissionProgress(int done, int total) {
    return '$done de $total feitas';
  }

  @override
  String get dailyMissionAllDone => 'Tudo feito!';

  @override
  String get dailyMissionRecordTitle => 'Registre algo hoje';

  @override
  String get dailyMissionRecordHint => 'Um gasto ou uma entrada';

  @override
  String get dailyMissionSameDayTitle => 'Anote no mesmo dia';

  @override
  String get dailyMissionSameDayHint => 'O gasto e o registro, hoje';

  @override
  String get dailyMissionBudgetTitle => 'Confira seu orçamento';

  @override
  String get dailyMissionBudgetHint => 'Abra a aba Orçamento';

  @override
  String get dailyMissionNoteTitle => 'Adicione uma nota';

  @override
  String get dailyMissionNoteHint => 'Um registro com nota';

  @override
  String get dailyMissionReceiptTitle => 'Guarde um comprovante';

  @override
  String get dailyMissionReceiptHint => 'Anexe a foto a um gasto';

  @override
  String get dailyMissionThreeTodayTitle => 'Registre três hoje';

  @override
  String dailyMissionThreeTodayHint(int count) {
    return '$count registros com a data de hoje';
  }

  @override
  String get dailyMissionDone => 'Feita';

  @override
  String get dailyMissionPending => 'A fazer';

  @override
  String dailyMissionReadyAt(String time) {
    return 'Feita · $time';
  }

  @override
  String dailyMissionBoardSummary(
    int done,
    int total,
    int earned,
    int possible,
  ) {
    return '$done de $total feitas · +$earned XP de +$possible XP hoje';
  }

  @override
  String get dailyMissionXpDetail => 'Missão concluída';

  @override
  String get xpRuleDailyMission => 'Uma vez por dia; à meia-noite recomeça';

  @override
  String xpNoticeMissionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missões feitas',
      one: 'Missão feita',
      zero: '$count missões feitas',
    );
    return '$_temp0';
  }

  @override
  String get xpNoticeMissionDetail => 'XP pelo hábito de hoje.';

  @override
  String get storeFailureGeneric =>
      'Não conseguimos salvar a alteração. Tente de novo.';

  @override
  String get storeFailureBudgetBelowCycleIncome =>
      'O total precisa ser maior que as entradas já reservadas para este ciclo.';

  @override
  String get storeFailureFutureMovement =>
      'Não dá para registrar algo com data futura.';

  @override
  String get storeFailureRestoreFailed => 'Não conseguimos restaurar o backup.';

  @override
  String get storeFailureOriginalNotKept =>
      'Não conseguimos manter o arquivo original.';

  @override
  String get storeFailureBackupNotSaved => 'Não conseguimos salvar o backup.';

  @override
  String get storeFailureSaveFailed => 'Não conseguimos salvar seus dados.';

  @override
  String get monthAbbr1 => 'jan';

  @override
  String get monthAbbr2 => 'fev';

  @override
  String get monthAbbr3 => 'mar';

  @override
  String get monthAbbr4 => 'abr';

  @override
  String get monthAbbr5 => 'mai';

  @override
  String get monthAbbr6 => 'jun';

  @override
  String get monthAbbr7 => 'jul';

  @override
  String get monthAbbr8 => 'ago';

  @override
  String get monthAbbr9 => 'set';

  @override
  String get monthAbbr10 => 'out';

  @override
  String get monthAbbr11 => 'nov';

  @override
  String get monthAbbr12 => 'dez';

  @override
  String dateShort(String day, String month) {
    return '$day $month';
  }

  @override
  String dateFull(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String get back => 'Voltar';

  @override
  String get reduceMotion => 'Reduzir movimento';

  @override
  String get catMotionIdle => 'O gato descansa tranquilo';

  @override
  String get catMotionWalk => 'O gato está andando';

  @override
  String get catMotionCalculate => 'O gato está fazendo as contas';

  @override
  String get catMotionSaving => 'O gato guarda moedas no cofrinho';

  @override
  String get catMotionCelebrate => 'O gato está comemorando';

  @override
  String get catMotionConcern => 'O gato parece preocupado com o orçamento';

  @override
  String get characterRoleIdle => 'O personagem descansa tranquilo';

  @override
  String get characterRoleActivity => 'O personagem está se mexendo';

  @override
  String get characterRoleProcessing => 'O personagem está fazendo as contas';

  @override
  String get characterRolePositive =>
      'O personagem mostra uma mudança positiva';

  @override
  String get characterRoleSuccess => 'O personagem está comemorando';

  @override
  String get characterRoleWarning => 'O personagem parece preocupado';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tabHome => 'Início';

  @override
  String get tabMovements => 'Extrato';

  @override
  String get tabRegister => 'Anotar';

  @override
  String get tabBudget => 'Orçam.';

  @override
  String get tabSettings => 'Perfil';

  @override
  String get collectionTitle => 'Coleção';

  @override
  String get collectionSettingsValue => 'Ver';

  @override
  String get collectionCharacters => 'Personagens';

  @override
  String get collectionItems => 'Itens';

  @override
  String collectionLevel(int level) {
    return 'NÍVEL $level';
  }

  @override
  String collectionOwnedCount(int owned, int total) {
    return '$owned de $total';
  }

  @override
  String get collectionCharactersHint => 'Reúna quem te faz companhia';

  @override
  String get collectionItemsHint => 'Reúna o que vai no seu espaço';

  @override
  String collectionCharacterPlaceholder(int number) {
    return 'Personagem $number';
  }

  @override
  String collectionItemPlaceholder(int number) {
    return 'Item $number';
  }

  @override
  String get collectionEquipped => 'EM USO';

  @override
  String get collectionOwned => 'OBTIDO';

  @override
  String get collectionPlaceIt => 'Colocar';

  @override
  String get collectionBuy => 'COMPRAR';

  @override
  String get collectionWatchAd => 'VER ANÚNCIO';

  @override
  String get collectionAdLoading => 'CARREGANDO';

  @override
  String collectionAdProgressLine(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String collectionAdUnlockDaily(int progress, int target) {
    return 'Veja anúncios premiados · $progress/$target · um por dia';
  }

  @override
  String get collectionAdUnavailable => 'SEM ANÚNCIOS';

  @override
  String get collectionAdDailyCap => 'LIMITE DE HOJE';

  @override
  String get collectionAdTomorrow => 'CONTINUA AMANHÃ';

  @override
  String collectionUnlockedNotice(String name) {
    return '$name é seu!';
  }

  @override
  String get collectionAdDismissedNotice =>
      'Veja o anúncio inteiro para contar.';

  @override
  String get collectionPackOnly => 'PACOTE';

  @override
  String get collectionPackDecoration => 'Estrela do Michi';

  @override
  String get collectionPackUnlock =>
      'Vem com Michi e amigos. Não é vendido separadamente.';

  @override
  String get collectionGiftOnly => 'PRESENTE';

  @override
  String get collectionGiftUnlock => 'Um presente especial. Não está à venda.';

  @override
  String collectionAdProgress(int progress, int target) {
    return 'ANÚNCIO $progress/$target';
  }

  @override
  String get collectionHowToGet => 'COMO CONSEGUIR';

  @override
  String get collectionAlreadyOwned => 'Já faz parte da sua coleção.';

  @override
  String get collectionIncludedUnlock => 'Incluído desde o início.';

  @override
  String collectionPurchaseUnlock(String price) {
    return 'Compra única · $price';
  }

  @override
  String collectionAdUnlock(int progress, int target) {
    return 'Veja anúncios premiados · $progress/$target';
  }

  @override
  String collectionLevelUnlock(int level) {
    return 'Desbloqueia no nível $level.';
  }

  @override
  String get collectionStorePricePending => 'preço da loja';

  @override
  String get collectionPreviewActionNotice =>
      'Compras e anúncios serão conectados numa etapa futura.';

  @override
  String get roomTitle => 'Minha casa';

  @override
  String get roomOpen => 'Abrir minha casa';

  @override
  String get roomDecorate => 'Decorar';

  @override
  String get roomDecorateTitle => 'Decorar';

  @override
  String get roomDone => 'Pronto';

  @override
  String get roomThemeCasaClara => 'Casa clara';

  @override
  String get roomThemeCasaJardin => 'Casa com jardim';

  @override
  String get roomThemeCasaDePlaya => 'Casa de praia';

  @override
  String get roomChooseTheme => 'Escolha o clima da sua casa.';

  @override
  String get roomCatReaction => 'Você mandou muito bem hoje!';

  @override
  String get roomInstruction => 'Escolha um item e toque onde ele vai.';

  @override
  String get roomCategoryRooms => 'Casa';

  @override
  String get roomCategoryFurniture => 'Móveis';

  @override
  String get roomCategoryWallFloor => 'Parede e piso';

  @override
  String get roomCategoryProps => 'Enfeites';

  @override
  String get roomCategoryCharacters => 'Personagens';

  @override
  String get roomCharacterInstruction => 'Escolha quem te faz companhia.';

  @override
  String get roomMoreInCollection => 'Ver mais na coleção';

  @override
  String get roomDefaultRug => 'Tapete lavanda';

  @override
  String get roomFloorLamp => 'Luminária verde';

  @override
  String get roomTablePlant => 'Planta de mesa';

  @override
  String get roomWallFrame => 'Quadro';

  @override
  String get roomRattanChair => 'Poltrona de vime';

  @override
  String get roomStandingLamp => 'Luminária de chão';

  @override
  String get roomWallClock => 'Relógio de parede';

  @override
  String get roomLowCabinet => 'Aparador baixo';

  @override
  String get roomPetBed => 'Caminha de pet';

  @override
  String get roomSavingsJar => 'Pote de economias';

  @override
  String get roomWallShelf => 'Prateleira de parede';

  @override
  String get roomTerracottaPouf => 'Pufe terracota';

  @override
  String get roomBlueCreamRug => 'Tapete azul e creme';

  @override
  String get roomLaunchSofa => 'Sofá de veludo';

  @override
  String get roomLaunchTv => 'TV de histórias';

  @override
  String get launchGiftTitle => 'Seu presente de lançamento chegou!';

  @override
  String get launchGiftBody =>
      'Você começou a usar o Sobrita a tempo. O sofá e a TV são seus.';

  @override
  String get launchGiftGoToRoom => 'Colocar na minha casa';

  @override
  String get launchGiftLater => 'Depois';

  @override
  String get roomSuggestCabinet =>
      'Coloque junto à parede da esquerda. Toque no lugar marcado.';

  @override
  String get roomSuggestPetBed =>
      'Coloque à esquerda do seu companheiro. Toque no lugar marcado.';

  @override
  String get roomSuggestSavingsJar =>
      'Tente a mesa ou o cantinho do piso. Toque num lugar marcado.';

  @override
  String get roomSuggestWallShelf =>
      'Pendure numa parede livre. Toque num lugar marcado.';

  @override
  String get roomSuggestPouf =>
      'Equilibre a sala à direita. Toque no lugar marcado.';

  @override
  String get roomSuggestBlueRug =>
      'Coloque embaixo do seu companheiro. Toque no lugar marcado.';

  @override
  String get roomSaved => 'Sua casa foi salva.';

  @override
  String get roomPlaced => 'Colocado';

  @override
  String get roomSurfaceWall => 'Parede';

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
      other: 'Há $count lugares na parede. Toque onde vai.',
      one: 'Há um lugar na parede. Toque nele para pendurar.',
      zero: 'Há $count lugares na parede. Toque onde vai.',
    );
    return '$_temp0';
  }

  @override
  String roomPickFloor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count lugares no piso. Toque onde vai.',
      one: 'Há um lugar no piso. Toque nele para colocar.',
      zero: 'Há $count lugares no piso. Toque onde vai.',
    );
    return '$_temp0';
  }

  @override
  String roomPickTabletop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count lugares na mesa. Toque onde vai.',
      one: 'Há um lugar na mesa. Toque nele para colocar.',
      zero: 'Há $count lugares na mesa. Toque onde vai.',
    );
    return '$_temp0';
  }

  @override
  String roomPickRug(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count lugares para o tapete. Toque onde vai.',
      one: 'Há um lugar para o tapete. Toque nele para colocar.',
      zero: 'Há $count lugares para o tapete. Toque onde vai.',
    );
    return '$_temp0';
  }

  @override
  String roomPickAny(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count lugares onde ele cabe. Toque onde vai.',
      one: 'Há um lugar onde ele cabe. Toque nele para colocar.',
      zero: 'Há $count lugares onde ele cabe. Toque onde vai.',
    );
    return '$_temp0';
  }

  @override
  String get roomMoveOrRemove =>
      'Toque em outro lugar para mover, ou no dele para tirar.';

  @override
  String get roomTapToRemove => 'Toque no lugar dele de novo para tirar.';

  @override
  String get xpHistoryTitle => 'Seu progresso';

  @override
  String xpTotal(int count) {
    return '$count XP no total';
  }

  @override
  String get xpMaxLevel => 'Nível máximo';

  @override
  String xpRemaining(int count) {
    return 'Faltam $count XP';
  }

  @override
  String get xpHistoryHint =>
      'O XP é creditado automaticamente. Cada linha guarda o motivo e a conta, mesmo se você fechar o app.';

  @override
  String get xpHistoryEmptyTitle => 'Ainda sem XP';

  @override
  String get xpHistoryEmptyMessage =>
      'A primeira contagem do dinheiro da semana e o fechamento do seu ciclo vão aparecer aqui.';

  @override
  String xpAmount(int count) {
    return '+$count XP';
  }

  @override
  String get xpSeeCalculation => 'Ver a conta';

  @override
  String get xpCalculationTitle => 'Como foi calculado';

  @override
  String get xpDetailCycle => 'Ciclo';

  @override
  String get xpDetailBudget => 'Orçamento';

  @override
  String get xpDetailSpent => 'Gasto';

  @override
  String get xpDetailResult => 'Resultado';

  @override
  String get xpDetailRule => 'Regra';

  @override
  String get xpDetailCredited => 'XP creditado';

  @override
  String get xpRuleCashCount => 'No máximo uma vez por semana';

  @override
  String xpRuleCycleInGreen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recompensa ajustada a $count dias',
      one: 'Recompensa ajustada a $count dia',
      zero: 'Recompensa ajustada a $count dias',
    );
    return '$_temp0';
  }

  @override
  String xpRuleDaysUnderDailyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias × 5 XP',
      one: '$count dia × 5 XP',
      zero: '$count dias × 5 XP',
    );
    return '$_temp0';
  }

  @override
  String get xpRuleFirstSuccessfulCycle => 'Bônus único de 50 XP';

  @override
  String get recoveryNotYet => 'Ainda não conseguimos recuperar seus dados.';

  @override
  String get recoveryStartFreshQuestion => 'Começar de novo?';

  @override
  String get recoveryStartFreshBody =>
      'Vamos guardar uma cópia do arquivo original antes de criar dados novos.';

  @override
  String get recoveryStartFresh => 'Começar de novo';

  @override
  String get recoveryTitle => 'Não conseguimos ler seus dados';

  @override
  String get recoveryOriginalKept =>
      'O arquivo original continua salvo. Não substituímos nem apagamos nada.';

  @override
  String get recoveryOptions =>
      'Você pode tentar de novo, usar o backup ou exportar o arquivo para guardá-lo.';

  @override
  String get recoveryRetrying => 'Tentando de novo…';

  @override
  String get recoveryRetry => 'Tentar de novo';

  @override
  String get recoveryUseBackup => 'Usar backup';

  @override
  String get recoveryExport => 'Exportar arquivo';

  @override
  String get recoveryExported => 'Arquivo original copiado.';

  @override
  String get settingsTitle => 'Meu Sobrita';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String currencyChangeTitle(String code) {
    return 'Mudar para $code?';
  }

  @override
  String currencyChangeBody(String example, String converted) {
    return 'Seus valores não são convertidos: $example continua $converted. Só muda o rótulo.';
  }

  @override
  String get currencyChangeConfirm => 'Mudar rótulo';

  @override
  String get currencyRegionAmericas => 'Américas';

  @override
  String get currencyRegionEurope => 'Europa';

  @override
  String get currencyRegionAsiaPacific => 'Ásia e Oceania';

  @override
  String get settingsCurrency => 'Moeda';

  @override
  String get settingsBudgetCycle => 'Ciclo';

  @override
  String get settingsCountDay => 'Dia da contagem';

  @override
  String get settingsReduceMotionHint =>
      'Liga sozinho se o seu celular já pede isso.';

  @override
  String get settingsQuickEntry => 'Registro rápido';

  @override
  String get settingsQuickEntryHint =>
      'Mostra Entrada e Gasto na tela de bloqueio.';

  @override
  String get quickEntryQuestion => 'O que você quer anotar?';

  @override
  String get quickEntryDenied =>
      'Permita as notificações do Sobrita para ligar o registro rápido.';

  @override
  String get widgetTodayLeft => 'Resta hoje';

  @override
  String get widgetCycleBalance => 'Saldo';

  @override
  String get widgetOpenApp => 'Abrir Sobrita';

  @override
  String get widgetRegisterExpense => 'Anotar gasto';

  @override
  String get settingsBackup => 'Backup dos dados';

  @override
  String get settingsCopy => 'Copiar';

  @override
  String get settingsBackupCopied =>
      'Backup copiado para a área de transferência.';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsAccount => 'Conta Google';

  @override
  String get settingsAccountConnect => 'Conectar';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get purchaseRestored => 'Pronto. Suas compras voltaram.';

  @override
  String get purchaseFailureStoreUnavailable =>
      'A loja não está disponível agora. Tente mais tarde.';

  @override
  String get purchaseFailureRejected =>
      'Não foi possível concluir a compra. Nada foi cobrado.';

  @override
  String get purchaseFailureDeliveryNotSaved =>
      'Sua compra chegou, mas não foi possível salvá-la. Ela será aplicada na próxima vez que você abrir o Sobrita.';

  @override
  String get purchaseFailureNothingToRestore =>
      'Não encontramos compras nesta conta.';

  @override
  String get collectionPurchasing => 'COMPRANDO…';

  @override
  String get settingsXpPreview => 'Prévia de XP';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsStorageNote =>
      'Seus dados ficam neste aparelho. Você não precisa de conta para usar o Sobrita.';

  @override
  String get settingsSectionShop => 'Loja';

  @override
  String get settingsRemoveAds => 'Remover anúncios gerais';

  @override
  String get settingsRemoveAdsHint =>
      'Tira os anúncios do extrato. Os anúncios premiados continuam disponíveis.';

  @override
  String get settingsPackName => 'Michi e amigos';

  @override
  String get settingsPackHint =>
      '3 personagens + a estrela do Michi. Também remove os anúncios gerais.';

  @override
  String get settingsOwned => 'Você já tem';

  @override
  String get settingsShopRestoreNote =>
      'As compras ficam na sua conta da loja. Dá para recuperá-las ao reinstalar.';

  @override
  String get settlementTitle => 'Fechamento do ciclo';

  @override
  String get settlementSpent => 'Gasto';

  @override
  String get settlementLeft => 'Sobrou';

  @override
  String get settlementOver => 'Passou';

  @override
  String get settlementAverage => 'Média diária';

  @override
  String get settlementContinue => 'Pronto';

  @override
  String get settlementCtaTitle => 'Buscar um enfeite especial';

  @override
  String get settlementCtaAction => 'Ver coleção';

  @override
  String get settingsSectionBudget => 'Orçamento';

  @override
  String get settingsSectionScreen => 'Tela';

  @override
  String get settingsSectionData => 'Dados';

  @override
  String get settingsSectionPrivacy => 'Privacidade';

  @override
  String get settingsAdPrivacy => 'Privacidade de anúncios';

  @override
  String get settingsAdPrivacyValue => 'Gerenciar';

  @override
  String get settingsAdPrivacyFailed =>
      'Não foi possível abrir as opções de privacidade. Tente de novo.';

  @override
  String get settingsSectionDesign => 'Design';

  @override
  String settingsProfileStats(int movements, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      movements,
      locale: localeName,
      other: '$movements registros',
      one: '$movements registro',
      zero: '$movements registros',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias com o Sobrita',
      one: '$days dia com o Sobrita',
      zero: '$days dias com o Sobrita',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languageAutomaticHint => 'Segue o celular';

  @override
  String get transactionsTitle => 'Extrato';

  @override
  String get dailySpendTitle => 'Gasto por dia';

  @override
  String dailySpendLimit(String amount) {
    return '$amount por dia';
  }

  @override
  String dailySpendCycleTotal(String amount) {
    return 'Este ciclo $amount';
  }

  @override
  String get dailyIncomeTitle => 'Entrada por dia';

  @override
  String dailyIncomeCycleTotal(String amount) {
    return 'Este ciclo $amount';
  }

  @override
  String get transactionsEmptyTitle => 'Nada por aqui ainda';

  @override
  String get transactionsEmptyMessage =>
      'Anote seu primeiro gasto e o resumo do ciclo aparece aqui.';

  @override
  String get transactionsEmptyExpensesTitle => 'Ainda sem gastos';

  @override
  String get transactionsEmptyExpensesMessage =>
      'Anote um gasto e o dia a dia aparece aqui.';

  @override
  String get transactionsEmptyIncomesTitle => 'Ainda sem entradas';

  @override
  String get transactionsEmptyIncomesMessage =>
      'Anote uma entrada e o dia a dia aparece aqui.';

  @override
  String get transactionsExpensePinned =>
      'Este gasto veio de uma contagem do dinheiro. Conte de novo para corrigir.';

  @override
  String get transactionsIncomePinned =>
      'Esta entrada veio de uma contagem do dinheiro. Conte de novo para corrigir.';

  @override
  String get transactionsExpenseDeleted => 'Gasto apagado.';

  @override
  String get transactionsIncomeDeleted => 'Entrada apagada.';

  @override
  String get undo => 'Desfazer';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Apagar';

  @override
  String get identifyDifference => 'Identificar diferença';

  @override
  String get editMovement => 'Editar registro';

  @override
  String get amount => 'Valor';

  @override
  String get editPendingHint =>
      'O valor vem da sua contagem do dinheiro. Você ainda pode mudar a categoria e a nota.';

  @override
  String get category => 'Categoria';

  @override
  String get note => 'Nota';

  @override
  String get noteExample => 'Ex.: Pastel';

  @override
  String get replacesPendingHint =>
      'Isto substitui o ajuste pendente. Não soma outro gasto.';

  @override
  String get saveWithoutDuplicating => 'Salvar sem duplicar';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get save => 'Salvar';

  @override
  String get budget => 'Orçamento';

  @override
  String get spent => 'Gasto';

  @override
  String get appName => 'Sobrita';

  @override
  String get homeCycleBalance => 'Saldo do ciclo';

  @override
  String get homeTodayLeft => 'Hoje você ainda tem';

  @override
  String homeOverBudget(String budget) {
    return 'Você passou do orçamento de $budget deste ciclo';
  }

  @override
  String homeDailyLimit(String limit, String remaining) {
    return 'Limite de hoje $limit · Restam $remaining no ciclo';
  }

  @override
  String get homeFirstQuestLabel => 'Primeira missão';

  @override
  String get homeBudgetQuestBody =>
      'Defina um orçamento e eu calculo quanto você pode gastar por dia.';

  @override
  String get homeCycleProgress => 'Progresso do ciclo';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '$count dia',
      zero: '$count dias',
    );
    return '$_temp0';
  }

  @override
  String get homeCashEstimated => 'Dinheiro estimado';

  @override
  String get homeCashUnset => 'Dinheiro não configurado';

  @override
  String homeLastCount(String amount) {
    return 'Última contagem: $amount';
  }

  @override
  String get homeFirstCountHint => 'Faça uma primeira contagem para começar.';

  @override
  String get homeRecentMovements => 'Registros recentes';

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get homeGoingWell => 'Indo muito bem';

  @override
  String get homeAdjustCalmly => 'Vamos ajustar com calma';

  @override
  String get budgetTitle => 'Orçamento';

  @override
  String get budgetCycleTotal => 'Total do ciclo';

  @override
  String get budgetTotal => 'Orçamento total';

  @override
  String get budgetNotSetTitle => 'Ainda sem orçamento';

  @override
  String get budgetNotSetBody =>
      'Defina um e a gente calcula quanto você pode gastar por dia.';

  @override
  String get budgetSetAction => 'Definir orçamento';

  @override
  String budgetTooLow(String allocated) {
    return 'O total precisa ser maior que as entradas já reservadas para este ciclo ($allocated).';
  }

  @override
  String budgetSpentShare(int percent) {
    return '$percent% do orçamento';
  }

  @override
  String budgetRingSpent(String amount) {
    return 'Gasto $amount';
  }

  @override
  String budgetRingLeft(String amount) {
    return 'Restam $amount';
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
      other: '$green de $total ciclos no azul',
      one: '$green de $total ciclo no azul',
      zero: '$green de $total ciclos no azul',
    );
    return '$_temp0';
  }

  @override
  String cycleHistoryAmounts(String budget, String spent) {
    return 'Orçamento $budget · Gasto $spent';
  }

  @override
  String get cycleHistoryEmpty => 'Nenhum ciclo foi fechado ainda.';

  @override
  String cycleHistoryAverage(String amount) {
    return 'Média diária $amount';
  }

  @override
  String get cycleHistoryAveragePending => 'Média diária · juntando dados';

  @override
  String get budgetChangedTitle => 'Você mudou seu orçamento';

  @override
  String get budgetChangedBody =>
      'O que fazemos com os limites por categoria? Ajustando, cada um muda na mesma proporção e sua divisão continua sua.';

  @override
  String get budgetKeepLimits => 'Manter';

  @override
  String get budgetScaleLimits => 'Ajustar na mesma proporção';

  @override
  String get budgetByCategory => 'Orçamento por categoria';

  @override
  String budgetCategoryLimit(String category) {
    return 'Limite de $category';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetProjection => 'Projeção no fechamento';

  @override
  String get budgetEstimatedLeft => 'O que deve sobrar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get saving => 'Salvando…';

  @override
  String dayOfMonth(int day) {
    return 'Dia $day';
  }

  @override
  String get weekdayMonday => 'Segunda-feira';

  @override
  String get weekdayTuesday => 'Terça-feira';

  @override
  String get weekdayWednesday => 'Quarta-feira';

  @override
  String get weekdayThursday => 'Quinta-feira';

  @override
  String get weekdayFriday => 'Sexta-feira';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayShortMonday => 'Seg';

  @override
  String get weekdayShortTuesday => 'Ter';

  @override
  String get weekdayShortWednesday => 'Qua';

  @override
  String get weekdayShortThursday => 'Qui';

  @override
  String get weekdayShortFriday => 'Sex';

  @override
  String get weekdayShortSaturday => 'Sáb';

  @override
  String get weekdayShortSunday => 'Dom';

  @override
  String get registerTitle => 'Anotar';

  @override
  String get registerExpense => 'Gasto';

  @override
  String get registerIncome => 'Entrada';

  @override
  String get registerAmountAboveZero => 'Digite um valor maior que zero.';

  @override
  String get registerNoFutureMovements =>
      'Não dá para anotar nada com data futura.';

  @override
  String get registerDate => 'Data';

  @override
  String get registerNoteExpenseExample => 'Ex.: Padaria do Zé';

  @override
  String get registerNoteIncomeExample => 'Ex.: Gorjeta de sexta';

  @override
  String get receiptTitle => 'Comprovante';

  @override
  String get receiptAdd => 'Adicionar comprovante';

  @override
  String get receiptCamera => 'Câmera';

  @override
  String get receiptGallery => 'Galeria';

  @override
  String get receiptChange => 'Trocar';

  @override
  String get receiptRemove => 'Remover';

  @override
  String get receiptHint => 'Uma foto para lembrar o que foi este gasto.';

  @override
  String get receiptAttached => 'Comprovante anexado';

  @override
  String get receiptView => 'Ver comprovante';

  @override
  String get receiptClose => 'Fechar';

  @override
  String get receiptMissing => 'A foto não está mais neste aparelho.';

  @override
  String get receiptFailed => 'Não foi possível salvar a foto.';

  @override
  String get receiptBackupNote =>
      'O backup não inclui as fotos dos comprovantes.';

  @override
  String get registerPayment => 'Pagamento';

  @override
  String get registerPaymentHint => 'Dinheiro sai da sua contagem. Cartão não.';

  @override
  String get registerIncomeKind => 'Tipo de entrada';

  @override
  String get registerWhatToDo => 'O que você quer fazer?';

  @override
  String get registerThisCycle => 'Este ciclo';

  @override
  String get registerSaveIt => 'Guardar';

  @override
  String get registerReceivedIn => 'Você recebeu em';

  @override
  String get registerAccount => 'Conta';

  @override
  String get registerReconcileQuestion => 'Este gasto explica a diferença?';

  @override
  String registerReconcileBody(String amount) {
    return 'Você tem $amount pendente da última contagem. Se for o mesmo gasto, a gente junta sem contar duas vezes.';
  }

  @override
  String get registerReconcileNo => 'Não, é novo';

  @override
  String get registerReconcileYes => 'Sim, juntar';

  @override
  String get registerDifferenceReconciled => 'Diferença conciliada';

  @override
  String get registerExpenseSaved => 'Gasto salvo';

  @override
  String get registerIncomeSaved => 'Entrada salva';

  @override
  String get cashCountTitle => 'Contagem do dinheiro';

  @override
  String get cashCountPickWhatHappened =>
      'Escolha o que aconteceu com a diferença.';

  @override
  String get cashCountSavedWithoutDuplicates =>
      'Contagem salva sem duplicar nada.';

  @override
  String get cashCountPrompt => 'Conte só o dinheiro que você tem agora.';

  @override
  String get cashCountNoneYet => 'Ainda sem contagem';

  @override
  String get cashCountResultPending =>
      'O resultado aparece depois que você digitar a contagem.';

  @override
  String get cashCountBaselineHint =>
      'Este será seu ponto de partida. Não será registrado como entrada.';

  @override
  String get cashCountExpected => 'Esperávamos';

  @override
  String get cashCountCounted => 'Você contou';

  @override
  String get cashCountBalanced => 'Tudo bate';

  @override
  String cashCountShort(String amount) {
    return 'Faltam $amount';
  }

  @override
  String cashCountExtra(String amount) {
    return 'Sobram $amount';
  }

  @override
  String get cashCountWhatHappened => 'O que aconteceu?';

  @override
  String get cashCountHelperExpense =>
      'Foi um gasto que você não tinha anotado.';

  @override
  String get cashCountHelperIncome => 'Foi dinheiro novo que você recebeu.';

  @override
  String get cashCountHelperTransferOut =>
      'Você depositou ou passou para outra conta.';

  @override
  String get cashCountHelperTransferIn =>
      'Você sacou ou trouxe de outra conta.';

  @override
  String get cashCountHelperCorrection => 'A contagem anterior estava errada.';

  @override
  String get cashCountHelperPending => 'Decidir depois.';

  @override
  String get cashCountSingleExpenseHint =>
      'Isto cria um único gasto. Você não vai precisar anotá-lo de novo.';

  @override
  String get cashCountNoteTipExample => 'Ex.: Gorjeta';

  @override
  String get cashCountWhatToDoWithMoney => 'O que fazemos com este dinheiro?';

  @override
  String get cashCountSaveFirst => 'Salvar primeira contagem';

  @override
  String get cashCountSave => 'Salvar contagem';

  @override
  String get cycleTitle => 'Seu ciclo';

  @override
  String get cycleCurrent => 'Ciclo atual';

  @override
  String get cycleInProgress => 'Em andamento';

  @override
  String get cycleUnchanged => 'Não muda';

  @override
  String get cycleNewFrequency => 'Nova frequência';

  @override
  String get cycleFirstPay => 'Primeiro pagamento';

  @override
  String get cyclePayDay => 'Dia do pagamento';

  @override
  String get cycleNext => 'Próximo ciclo';

  @override
  String cycleChangeAppliesRepeating(int days) {
    return 'A mudança vale a partir do próximo ciclo e depois se renova a cada $days dias.';
  }

  @override
  String get cycleChangeApplies => 'A mudança vale a partir do próximo ciclo.';

  @override
  String get cycleSaveChange => 'Salvar mudança';

  @override
  String get onboardingBudgetAboveZero => 'Digite um orçamento maior que zero.';

  @override
  String get onboardingCashOrSkip =>
      'Digite o dinheiro ou escolha “Agora não”.';

  @override
  String get prologueRainNoEnd => 'A chuva não dava sinal de parar.';

  @override
  String get prologueRentPaid =>
      'O aluguel estava pago, e o que sobrava na conta tinha que durar até o próximo pagamento.';

  @override
  String get prologueSoundAtDoor => 'Algo se mexeu perto da porta.';

  @override
  String get prologueGoLook => 'Ir ver';

  @override
  String get prologueWetTracks =>
      'Duas fileiras de pegadas molhadas cruzaram o chão.';

  @override
  String get prologueShelter => 'Deixa a gente esperar a chuva passar.';

  @override
  String get prologueItSpoke => '…falou.';

  @override
  String get prologueReplySurprised => 'Você acabou de falar?';

  @override
  String get prologueReplyTowel => '(você pega uma toalha sem dizer nada)';

  @override
  String get prologueEarnKeep =>
      'Preciso ajudar de algum jeito. Eu cuido dos números.';

  @override
  String get prologueAskSchedule => 'Primeiro: quando o dinheiro entra?';

  @override
  String get prologueAskPayday =>
      'Que dia você recebe? Me diga o primeiro e eu conto o resto.';

  @override
  String prologueAskBudget(int days) {
    return 'Faltam $days dias para o próximo pagamento. Quanto você pensa gastar?';
  }

  @override
  String get prologueSkipIsFine =>
      'Pode pular. Eu pergunto de novo quando a gente chegar em casa.';

  @override
  String get prologueSkip => 'Pular';

  @override
  String get prologueDriedOff =>
      'Secos, os dois se acalmaram. Lá fora ainda chovia.';

  @override
  String get prologueWhoSits => 'Quem senta com você?';

  @override
  String get prologueMichiTrait => 'Quieto.\nBom com números.';

  @override
  String get prologuePoodleTrait => 'Pura energia.\nCuida de você.';

  @override
  String get prologueSchnauzerTrait => 'Observador.\nSempre atento.';

  @override
  String get prologueLockedName => '???';

  @override
  String get prologueLockedTrait => 'Pura energia.\nCuida de você.';

  @override
  String get prologueLockedSoon => 'Arte a caminho';

  @override
  String get prologueOtherStays =>
      'O outro também fica. Você pode trocar de companheiro depois.';

  @override
  String get prologueLiveTogether => 'Podem ficar';

  @override
  String prologueGreeting(String name) {
    return 'Eu sou $name. Obrigado por abrir a porta.';
  }

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingTagline => 'Seu dinheiro, sem pressão.';

  @override
  String get onboardingPromise =>
      'A gente te diz quanto você pode gastar hoje.';

  @override
  String get onboardingHowPaid => 'Como você recebe?';

  @override
  String get onboardingHowPaidHint => 'Isso define as datas do seu orçamento.';

  @override
  String get onboardingCycleHelperSemiMonthly =>
      'Dois pagamentos por mês: dia 15 e o último dia.';

  @override
  String get onboardingCycleHelperMonthly => 'Um pagamento por mês.';

  @override
  String get onboardingCycleHelperWeekly => 'Toda semana.';

  @override
  String get onboardingCycleHelperIrregular => 'Minha renda não tem data fixa.';

  @override
  String get onboardingPlanWithoutFixedDate => 'Planejar sem data fixa';

  @override
  String get onboardingWhichDayPaid => 'Que dia você recebe?';

  @override
  String get onboardingSecondPayEndOfMonth => 'Segundo pagamento · fim do mês';

  @override
  String get onboardingHowManyDays => 'Para quantos dias você quer planejar?';

  @override
  String get onboardingCyclePreview => 'Seu ciclo ficaria assim';

  @override
  String onboardingRepeatsEvery(int days) {
    return 'Quando terminar, outro período de $days dias começa sozinho.';
  }

  @override
  String get onboardingShortMonthsNote =>
      'As datas se ajustam sozinhas nos meses curtos.';

  @override
  String get onboardingBudgetQuestion =>
      'Quanto você quer gastar\nneste ciclo?';

  @override
  String get onboardingBudgetLater => 'Você pode definir depois pelo Início.';

  @override
  String get onboardingNotNow => 'Agora não';

  @override
  String get onboardingCashQuestion => 'Quanto dinheiro\nvocê tem hoje?';

  @override
  String get onboardingCashOptional => 'Deixe vazio se preferir contar depois.';

  @override
  String get onboardingCashIsBaseline =>
      'Esta será sua primeira contagem, não uma entrada.';

  @override
  String onboardingSettledIn(String name) {
    return 'A chuva parou. $name se acomodou ao seu lado.';
  }

  @override
  String get onboardingFirstQuests => 'Suas primeiras missões';

  @override
  String get onboardingWaitingAtHome => 'Te esperando em casa';

  @override
  String get onboardingGoHome => 'Ir para o Início';

  @override
  String get onboardingPlanReady => 'Seu plano está pronto';

  @override
  String get onboardingCanSpendToday => 'Hoje você pode gastar';

  @override
  String onboardingStepOf(int step, int total) {
    return '$step de $total';
  }

  @override
  String progressPercent(int percent) {
    return 'Progresso $percent por cento';
  }

  @override
  String stepOf(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String xpOfTarget(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get xpCycleInGreenBiweekly => 'Você fechou as duas semanas no azul';

  @override
  String get onboardingCycleHelperBiweekly =>
      'A cada duas semanas, desde meu último pagamento.';

  @override
  String get cycleLastPayday => 'Último pagamento';

  @override
  String get onboardingWhenLastPaid => 'Quando foi seu último pagamento?';

  @override
  String get onboardingBiweeklyNeedsDate =>
      'Escolha o dia do seu último pagamento.';

  @override
  String get pickDate => 'Escolher data';

  @override
  String movementSubtitle(String first, String second) {
    return '$first · $second';
  }

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsReleaseNotes => 'Novidades';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsVersionUnknown => '—';

  @override
  String get releaseNotesTitle => 'Novidades';

  @override
  String get releaseNotesCurrent => 'Atual';

  @override
  String releaseNotesRetention(int count) {
    return 'Guardamos as últimas $count versões.';
  }

  @override
  String get releaseNote104Fixed =>
      'Os gastos fixos ficam separados do gasto diário. Aparecem no Início e podem te avisar antes do vencimento.';

  @override
  String get releaseNote104Decor =>
      'A casa tem mais coisas para colocar: uma caminha, uma prateleira, um tapete, um aparador, um pote e um pufe.';

  @override
  String get releaseNote104Names =>
      'Miru, Yoshi e Cookie agora têm nome, e o título de nível leva o nome de quem te faz companhia.';

  @override
  String get releaseNote104Widget =>
      'O widget da tela inicial mostra o valor completo.';

  @override
  String get releaseNote104Languages =>
      'O Sobrita agora fala português, alemão, francês e japonês.';

  @override
  String get releaseNote103GuineaPig =>
      'O porquinho-da-índia chegou à coleção. Dois anúncios curtos e ele fica com você.';

  @override
  String get releaseNote103Widget =>
      'O widget da tela inicial mostra com quem você mora, e o valor é escrito igual ao app.';

  @override
  String get releaseNote102Schnauzer =>
      'O Schnauzer chegou à coleção. Dois anúncios curtos e ele fica com você.';

  @override
  String get releaseNote102Rooms =>
      'A casa pode ser um jardim ou uma praia, e já dá para colocar uma poltrona, uma luminária e um relógio.';

  @override
  String get releaseNote102Missions =>
      'Duas das três missões do dia mudam todo dia, e as que pedem um passo a mais dão mais XP.';

  @override
  String get releaseNote102Amounts =>
      'Pesos colombianos, argentinos e chilenos, reais e euros agora usam vírgula, como em 1.234,56.';

  @override
  String get releaseNote101Currencies =>
      'Agora dá para rotular seu dinheiro em pesos colombianos, argentinos e chilenos, soles, libras ou ienes.';

  @override
  String get releaseNote101Celebration =>
      'A comemoração agora preenche o cartão e termina o pulo.';

  @override
  String get releaseNote100Launch => 'A primeira versão do Sobrita.';

  @override
  String get updateAvailableTitle => 'Tem versão nova';

  @override
  String get updateAvailableBody => 'Atualize para ter o Sobrita mais recente.';

  @override
  String updateCurrentVersion(String version) {
    return 'Sua versão: v$version';
  }

  @override
  String get updateAction => 'Atualizar';

  @override
  String get updateLater => 'Agora não';

  @override
  String get updateBannerMessage => 'Nova versão disponível';

  @override
  String get updateBannerDismiss => 'Fechar o aviso';

  @override
  String get updateStoreFailed => 'Não foi possível abrir o Google Play.';

  @override
  String get settingsCheckUpdate => 'Procurar atualização';

  @override
  String get settingsCheckUpdateBusy => 'Procurando…';

  @override
  String get settingsCheckUpdateUpToDate => 'Você está em dia.';

  @override
  String get settingsRateApp => 'Avaliar o Sobrita';

  @override
  String get settingsOurApps => 'Apps recomendados';

  @override
  String get ourAppsIntro => 'Feitos pela equipe do Sobrita.';

  @override
  String get ourAppsOpen => 'Ver no Google Play';

  @override
  String get ourAppsLoopetKind => 'Rotinas';

  @override
  String get ourAppsLoopetBlurb =>
      'Seu dia inteiro em um círculo. Veja o que fazer agora e o que vem depois.';

  @override
  String get ourAppsRandomFocusKind => 'Foco';

  @override
  String get ourAppsRandomFocusBlurb =>
      'Gire a roleta, deixe ela escolher o tempo e foque sem pensar demais.';

  @override
  String get releaseAnnouncementViewAll => 'Ver tudo';

  @override
  String get releaseAnnouncementDone => 'Pronto';

  @override
  String get settingsReleaseNotesUnread => 'Novidades não lidas';

  @override
  String get fixedSectionTitle => 'Gastos fixos';

  @override
  String fixedSectionMonth(String month) {
    return '$month · separado do seu gasto diário';
  }

  @override
  String fixedPaidOfTotal(String paid, String total) {
    return 'Pago $paid de $total';
  }

  @override
  String get fixedAdd => 'Adicionar gasto fixo';

  @override
  String get fixedEmptyBody =>
      'Aluguel, celular, luz: anote uma vez e eu te lembro quando vencer. Eles não mudam seu gasto diário.';

  @override
  String get fixedFrequencyWeekly => 'Toda semana';

  @override
  String get fixedFrequencySemiMonthly => 'A cada quinzena';

  @override
  String get fixedFrequencyMonthly => 'Todo mês';

  @override
  String get fixedFrequencyBimonthly => 'A cada 2 meses';

  @override
  String get fixedStatusPaid => 'Pago';

  @override
  String get fixedStatusTomorrow => 'Amanhã';

  @override
  String get fixedStatusOverdue => 'Vencido';

  @override
  String fixedApprox(String amount) {
    return 'cerca de $amount';
  }

  @override
  String get fixedFormNewTitle => 'Novo gasto fixo';

  @override
  String get fixedFormEditTitle => 'Editar gasto fixo';

  @override
  String get fixedName => 'Nome';

  @override
  String get fixedNameHint => 'Aluguel, celular, luz…';

  @override
  String get fixedNameRequired => 'Dê um nome';

  @override
  String get fixedHowOften => 'Com que frequência?';

  @override
  String get fixedNextDue => 'Próximo pagamento';

  @override
  String fixedThenDates(String dates) {
    return 'Depois: $dates…';
  }

  @override
  String get fixedVariable => 'O valor muda a cada vez';

  @override
  String get fixedVariableHint =>
      'Uso o último valor que você pagou como estimativa.';

  @override
  String get fixedFormNote =>
      'Não muda seu gasto diário: seu orçamento é o que sobra depois dos fixos.';

  @override
  String get fixedSave => 'Salvar gasto fixo';

  @override
  String get fixedDelete => 'Apagar gasto fixo';

  @override
  String fixedDeleteTitle(String name) {
    return 'Apagar $name?';
  }

  @override
  String get fixedDeleteBody =>
      'Os pagamentos que você já anotou continuam no extrato.';

  @override
  String get fixedDueToday => 'Vence hoje';

  @override
  String get fixedDueTomorrow => 'Vence amanhã';

  @override
  String fixedDueOn(String date) {
    return 'Vence em $date';
  }

  @override
  String fixedWasDue(String date) {
    return 'Venceu em $date';
  }

  @override
  String get fixedHowMuch => 'Quanto você pagou?';

  @override
  String fixedLastTime(String amount) {
    return 'Da última vez: $amount';
  }

  @override
  String fixedTodayUnchanged(String amount) {
    return 'Seu valor de hoje continua $amount.';
  }

  @override
  String fixedCashChange(String from, String to) {
    return 'Dinheiro estimado: de $from para $to';
  }

  @override
  String fixedPaidWith(String method) {
    return 'Pago com $method';
  }

  @override
  String get fixedChange => 'Mudar';

  @override
  String get fixedMarkPaid => 'Já paguei';

  @override
  String get fixedNotYet => 'Ainda não';

  @override
  String get fixedBillOnly => 'Só chegou a conta';

  @override
  String fixedBillSaved(String amount) {
    return 'Certo, espero $amount.';
  }

  @override
  String fixedPaymentSaved(String name) {
    return '$name anotado.';
  }

  @override
  String get fixedHomeLabel => 'Gasto fixo';

  @override
  String fixedHomeMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamentos fixos para conferir',
      one: '$count pagamento fixo para conferir',
      zero: '$count pagamentos fixos para conferir',
    );
    return '$_temp0';
  }

  @override
  String get fixedHomeSee => 'Ver';

  @override
  String get fixedIntroTitle => 'Seu orçamento é para gastar, sem os fixos';

  @override
  String fixedIntroBody(String budget, String name) {
    return 'Gastos fixos não baixam seu valor diário. Se seus $budget já contavam com “$name”, vale baixar o orçamento.';
  }

  @override
  String get fixedIntroKeep => 'Está bom assim';

  @override
  String get fixedIntroAdjust => 'Ajustar orçamento';

  @override
  String get fixedBadge => 'Fixo';

  @override
  String get fixedNothingThisMonth => 'Nada vence este mês.';

  @override
  String get fixedReminderLabel => 'Lembrete';

  @override
  String get fixedReminderNone => 'Sem lembrete';

  @override
  String get fixedReminderSameDay => 'No dia';

  @override
  String get fixedReminderDayBefore => '1 dia antes';

  @override
  String get fixedReminderThreeDaysBefore => '3 dias antes';

  @override
  String get fixedReminderHint => 'Eu te aviso às 9:00 da manhã.';

  @override
  String get fixedReminderBlocked =>
      'As notificações do Sobrita estão desligadas, então não consigo te avisar.';

  @override
  String fixedReminderTitleToday(String name) {
    return '$name vence hoje';
  }

  @override
  String fixedReminderTitleTomorrow(String name) {
    return '$name vence amanhã';
  }

  @override
  String fixedReminderTitleInDays(String name, int days) {
    return '$name vence em $days dias';
  }

  @override
  String fixedReminderBody(String amount, String method) {
    return '$amount · $method. Quando pagar, anote no Sobrita.';
  }
}
