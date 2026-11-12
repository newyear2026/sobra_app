import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import 'package:sobra_app/widgets/savings_goal_card.dart';
import 'package:sobra_app/widgets/savings_goal_dialog.dart';

import 'support/localizations.dart';

const _capture = bool.fromEnvironment('CAPTURE_GOAL_DIALOG_UI');
const _captureKey = ValueKey('goal-dialog-capture');
const _output = 'output/sobrita-goal-popup-implemented-20261109';
const _cycleStart = '2026-11-02';
const _leftover = 2000000; // KRW 20,000 in app minor units.
const _target = 10000000000; // KRW 100,000,000.
const _starting = 1000000000; // KRW 10,000,000.

Future<SobraStore> _closedCycle({
  bool withGoal = true,
  int starting = _starting,
  String locale = 'ko',
}) async {
  var now = DateTime(2026, 11, 2, 10);
  final store = await SobraStore.load(now: () => now);
  await store.setCurrency(Currency.krw);
  await store.setLanguageCode(locale);
  await store.configureOnboarding(
    budgetCentavos: 10000000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 10000000,
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'michi', 'poodle'});
  await store.setReducedMotion(true);
  await store.claimSeasonalCostumes();
  await store.takeLaunchGiftNotice();
  if (withGoal) {
    await store.saveSavingsGoal(
      kind: SavingsGoalKind.amount,
      name: '1억 모으기',
      targetCentavos: _target,
      startingCentavos: starting,
    );
  }
  await store.addExpense(
    amountCentavos: 8000000,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: now,
    paymentMethod: PaymentMethod.cash,
  );
  now = DateTime(2026, 11, 9, 10);
  await store.settleCycles();
  store.takePendingXpNotice();
  expect(store.cycleRecords.single.start, DateTime.parse(_cycleStart));
  expect(store.cycleRecords.single.resultCentavos, _leftover);
  return store;
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpHarness(
  WidgetTester tester,
  SobraStore store, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('ko'),
}) async {
  _viewport(tester, size);
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildSobraTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SavingsGoalCard(),
                  TextButton(
                    key: const ValueKey('open-allocation'),
                    onPressed: () => unawaited(
                      showCycleGoalAllocation(
                        context,
                        cycleStart: DateTime.parse(_cycleStart),
                      ),
                    ),
                    child: const Text('Open allocation'),
                  ),
                  TextButton(
                    key: const ValueKey('open-completion'),
                    onPressed: () =>
                        unawaited(showSavingsGoalCompletion(context)),
                    child: const Text('Open completion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

Future<void> _loadCaptureFonts() async {
  final pixel = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final korean = FontLoader('SobraHangul')
    ..addFont(rootBundle.load('assets/fonts/SobraHangul.ttf'))
    ..addFont(rootBundle.load('assets/fonts/SobraHangul-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixel.load(), korean.load(), icons.load()]);
}

Future<void> _warmArt(WidgetTester tester) async {
  final context = tester.element(find.byType(Navigator).first);
  final providers = <ImageProvider>[
    ...tester.widgetList<Image>(find.byType(Image)).map((image) => image.image),
    ...tester
        .widgetList<CharacterSprite>(find.byType(CharacterSprite))
        .map((sprite) => AssetImage(sprite.asset)),
  ];
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _captureScreen(WidgetTester tester, String name) async {
  await _warmArt(tester);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_output).create(recursive: true);
    await File('$_output/$name').writeAsBytes(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    image.dispose();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(SharedPreferences.resetStatic);

  testWidgets('whole leftover is recorded once without new income', (
    tester,
  ) async {
    final store = await _closedCycle();
    final incomeCount = store.incomes.length;
    final cash = store.expectedCashCentavos;
    final budget = store.totalBudgetCentavos;
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-allocation');
    expect(
      find.byKey(const ValueKey('goal-allocation-dialog')),
      findsOneWidget,
    );
    expect(store.savingsGoalProgressCentavos, _starting);
    await _tap(tester, 'goal-allocation-confirm');
    expect(store.savingsGoalProgressCentavos, _starting + _leftover);
    expect(
      store.goalAllocationForCycle(DateTime.parse(_cycleStart)),
      _leftover,
    );
    expect(store.incomes.length, incomeCount);
    expect(store.expectedCashCentavos, cash);
    expect(store.totalBudgetCentavos, budget);

    await _tap(tester, 'open-allocation');
    await _tap(tester, 'goal-allocation-confirm');
    expect(store.savingsGoalProgressCentavos, _starting + _leftover);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'partial allocation edits the same cycle instead of adding twice',
    (tester) async {
      final store = await _closedCycle();
      await _pumpHarness(tester, store);
      await _tap(tester, 'open-allocation');
      await _tap(tester, 'goal-allocation-change-amount');
      await _enter(tester, 'goal-allocation-amount', '10000');
      await _hideKeyboard(tester);
      await _tap(tester, 'goal-allocation-confirm');
      expect(store.savingsGoalProgressCentavos, _starting + 1000000);

      await _tap(tester, 'open-allocation');
      await _tap(tester, 'goal-allocation-change-amount');
      await _enter(tester, 'goal-allocation-amount', '5000');
      await _hideKeyboard(tester);
      await _tap(tester, 'goal-allocation-confirm');
      expect(store.savingsGoalProgressCentavos, _starting + 500000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero and an amount beyond the cycle leftover cannot be saved', (
    tester,
  ) async {
    final store = await _closedCycle();
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-allocation');
    await _tap(tester, 'goal-allocation-change-amount');
    for (final value in ['0', '20001']) {
      await _enter(tester, 'goal-allocation-amount', value);
      await _hideKeyboard(tester);
      await _tap(tester, 'goal-allocation-confirm');
      expect(store.savingsGoalProgressCentavos, _starting);
      expect(
        find.byKey(const ValueKey('goal-allocation-dialog')),
        findsOneWidget,
      );
      expect(find.textContaining('0보다 크고'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('later keeps the goal and cycle money unchanged', (tester) async {
    final store = await _closedCycle();
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-allocation');
    await _tap(tester, 'goal-allocation-later');
    expect(store.savingsGoalProgressCentavos, _starting);
    expect(store.goalAllocationForCycle(DateTime.parse(_cycleStart)), 0);
    expect(store.cycleRecords.single.resultCentavos, _leftover);
    expect(find.byKey(const ValueKey('goal-allocation-dialog')), findsNothing);
  });

  testWidgets('no-goal setup returns to confirmation before allocating', (
    tester,
  ) async {
    final store = await _closedCycle(withGoal: false);
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-allocation');
    expect(
      find.byKey(const ValueKey('goal-allocation-create')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('goal-allocation-confirm')), findsNothing);
    await _tap(tester, 'goal-allocation-create');
    expect(find.byType(SavingsGoalScreen), findsOneWidget);
    await _tap(tester, 'goal-type-amount');
    await _enter(tester, 'goal-name', '비상금');
    await _enter(tester, 'goal-target', '100000');
    final startingField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('goal-starting')),
        matching: find.byType(EditableText),
      ),
    );
    expect(startingField.controller.text, '0');
    await _enter(tester, 'goal-starting', '5000');
    await _hideKeyboard(tester);
    await _tap(tester, 'goal-save');
    expect(store.activeSavingsGoal?.name, '비상금');
    expect(store.activeSavingsGoal?.startingCentavos, 500000);
    expect(store.savingsGoalProgressCentavos, 500000);
    expect(
      find.byKey(const ValueKey('goal-allocation-confirm')),
      findsOneWidget,
    );
    await _tap(tester, 'goal-allocation-confirm');
    expect(store.savingsGoalProgressCentavos, 500000 + _leftover);
    expect(store.incomes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling setup leaves no goal or allocation', (tester) async {
    final store = await _closedCycle(withGoal: false);
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-allocation');
    await _tap(tester, 'goal-allocation-create');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(store.activeSavingsGoal, isNull);
    expect(store.goalAllocationForCycle(DateTime.parse(_cycleStart)), 0);
    expect(store.cycleRecords.single.resultCentavos, _leftover);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completion is acknowledged once and leaves a completed home card',
    (tester) async {
      final store = await _closedCycle(starting: _target);
      await _pumpHarness(tester, store);
      await _tap(tester, 'open-completion');
      expect(
        find.byKey(const ValueKey('goal-completion-dialog')),
        findsOneWidget,
      );
      await _tap(tester, 'goal-completion-confirm');
      expect(store.pendingSavingsGoalCompletionId, isNull);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('달성 완료'), findsOneWidget);
      await _tap(tester, 'open-completion');
      expect(
        find.byKey(const ValueKey('goal-completion-dialog')),
        findsNothing,
      );
      expect(store.activeSavingsGoal, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new goal archives the completed goal only after saving', (
    tester,
  ) async {
    final store = await _closedCycle(starting: _target);
    final oldGoalId = store.activeSavingsGoal!.id;
    await _pumpHarness(tester, store);
    await _tap(tester, 'open-completion');
    await _tap(tester, 'goal-completion-new-goal');
    expect(find.byType(SavingsGoalScreen), findsOneWidget);
    expect(store.activeSavingsGoal!.id, oldGoalId);
    expect(store.completedSavingsGoals, isEmpty);
    await _tap(tester, 'goal-type-amount');
    await _enter(tester, 'goal-name', '여행');
    await _enter(tester, 'goal-target', '500000');
    await _enter(tester, 'goal-starting', '0');
    await _hideKeyboard(tester);
    await _tap(tester, 'goal-save');
    expect(store.activeSavingsGoal!.name, '여행');
    expect(store.activeSavingsGoal!.id, isNot(oldGoalId));
    expect(store.savingsGoalProgressCentavos, 0);
    expect(store.completedSavingsGoals, hasLength(1));
    expect(store.completedSavingsGoals.single.goal.id, oldGoalId);
    expect(store.completedSavingsGoals.single.progressCentavos, _target);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['ko', 'en']) {
    for (final state in ['active', 'empty', 'completed']) {
      testWidgets('$state popup fits 320x640 at 1.3x $locale text', (
        tester,
      ) async {
        final store = await _closedCycle(
          withGoal: state != 'empty',
          starting: state == 'completed' ? _target : _starting,
          locale: locale,
        );
        await _pumpHarness(
          tester,
          store,
          size: const Size(320, 640),
          textScale: 1.3,
          locale: Locale(locale),
        );
        await _tap(
          tester,
          state == 'completed' ? 'open-completion' : 'open-allocation',
        );
        expect(tester.takeException(), isNull);
        await _tap(
          tester,
          state == 'completed'
              ? 'goal-completion-confirm'
              : 'goal-allocation-later',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  if (_capture) {
    for (final state in ['active', 'empty', 'completed']) {
      testWidgets('capture Korean $state popup above unchanged room', (
        tester,
      ) async {
        _viewport(tester, const Size(390, 844));
        await _loadCaptureFonts();
        final store = await _closedCycle(
          withGoal: state != 'empty',
          starting: state == 'completed' ? _target - _leftover : _starting,
        );
        await store.acknowledgeSavingsGoalCyclePrompt(
          DateTime.parse(_cycleStart),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: _captureKey,
            child: SobraApp(store: store),
          ),
        );
        await _warmArt(tester);
        final room = find.byType(RoomScene).first;
        final originalRoomRect = tester.getRect(room);
        expect(originalRoomRect.width, closeTo(originalRoomRect.height, .01));
        final context = tester.element(find.byType(SavingsGoalCard).first);
        if (state == 'completed') {
          await store.allocateCycleToSavingsGoal(
            cycleStart: DateTime.parse(_cycleStart),
            goalId: store.activeSavingsGoal!.id,
            amountCentavos: _leftover,
          );
          await tester.pumpAndSettle();
          if (find
              .byKey(const ValueKey('goal-completion-dialog'))
              .evaluate()
              .isEmpty) {
            unawaited(showSavingsGoalCompletion(context));
          }
        } else {
          unawaited(
            showCycleGoalAllocation(
              context,
              cycleStart: DateTime.parse(_cycleStart),
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.getRect(room), originalRoomRect);
        await _captureScreen(tester, '$state-ko.png');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}
