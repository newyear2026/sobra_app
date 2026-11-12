import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/services/goal_product_import.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/goal_product_thumbnail.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import 'package:sobra_app/widgets/savings_goal_card.dart';

import 'support/localizations.dart';

const _capture = bool.fromEnvironment('CAPTURE_GOAL_UI');
const _captureKey = ValueKey('goal-ui-capture');
const _output = 'output/sobrita-goal-amount-20261109';

Future<SobraStore> _store({
  String locale = 'en',
  Currency currency = Currency.mxn,
}) async {
  final store = await SobraStore.load(now: () => DateTime(2026, 11, 9, 10));
  await store.setCurrency(currency);
  await store.configureOnboarding(
    budgetCentavos: currency == Currency.krw ? 200000000 : 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: currency == Currency.krw ? 124000000 : 124000,
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'michi', 'poodle'});
  await store.setReducedMotion(true);
  await store.setLanguageCode(locale);
  await store.claimSeasonalCostumes();
  await store.takeLaunchGiftNotice();
  store.takePendingXpNotice();
  return store;
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpCard(
  WidgetTester tester,
  SobraStore store, {
  GoalProductLoader? importer,
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('en'),
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
                  if (importer != null)
                    TextButton(
                      key: const ValueKey('open-import-editor'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              SavingsGoalScreen(importProduct: importer),
                        ),
                      ),
                      child: const Text('Open import editor'),
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
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

String _fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

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

Future<void> _warmVisibleArt(WidgetTester tester) async {
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

Future<void> _captureScreen(WidgetTester tester, String filename) async {
  if (!_capture) return;
  await _warmVisibleArt(tester);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_output).create(recursive: true);
    await File('$_output/$filename').writeAsBytes(
      data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    image.dispose();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('empty card creates a manual goal and returns to progress', (
    tester,
  ) async {
    final store = await _store();
    await _pumpCard(tester, store);
    expect(find.text('What would you like to save for?'), findsOneWidget);
    expect(find.byKey(const ValueKey('savings-goal-active')), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
    expect(find.byType(SavingsGoalScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-name')), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
    await _enter(tester, 'goal-name', 'New sneakers');
    await _enter(tester, 'goal-target', '1499');
    await _enter(tester, 'goal-starting', '300');
    await _tap(tester, find.byKey(const ValueKey('goal-save')));

    expect(store.activeSavingsGoal?.name, 'New sneakers');
    expect(store.activeSavingsGoal?.targetCentavos, 149900);
    expect(store.savingsGoalProgressCentavos, 30000);
    expect(find.byType(SavingsGoalScreen), findsNothing);
    expect(find.byKey(const ValueKey('savings-goal-empty')), findsNothing);
    expect(find.byKey(const ValueKey('savings-goal-active')), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid target amount cannot create a goal', (tester) async {
    final store = await _store();
    await _pumpCard(tester, store);
    await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
    await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
    await _enter(tester, 'goal-name', 'New sneakers');
    await _enter(tester, 'goal-target', '0');
    await _tap(tester, find.byKey(const ValueKey('goal-save')));

    expect(store.activeSavingsGoal, isNull);
    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(find.byType(SavingsGoalScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hundred million won goal needs no product or link', (
    tester,
  ) async {
    final store = await _store(locale: 'ko', currency: Currency.krw);
    await _pumpCard(tester, store, locale: const Locale('ko'));
    await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
    expect(find.byKey(const ValueKey('goal-type-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-type-product')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
    expect(find.byKey(const ValueKey('goal-link')), findsNothing);
    expect(find.byType(GoalProductThumbnail), findsNothing);
    await _enter(tester, 'goal-name', '1억 모으기');
    await _enter(tester, 'goal-target', '100000000');
    await _enter(tester, 'goal-starting', '10000000');
    await _tap(tester, find.byKey(const ValueKey('goal-save')));

    final goal = store.activeSavingsGoal!;
    expect(goal.kind, SavingsGoalKind.amount);
    expect(goal.name, '1억 모으기');
    expect(goal.targetCentavos, 10000000000);
    expect(goal.startingCentavos, 1000000000);
    expect(goal.productUrl, isNull);
    expect(goal.imageUrl, isNull);
    expect(goal.merchantName, isNull);
    expect(store.currency, Currency.krw);
    expect(find.text('10%'), findsOneWidget);
    expect(
      tester
          .widget<GoalProductThumbnail>(find.byType(GoalProductThumbnail))
          .url,
      isNull,
    );
    await _tap(tester, find.byKey(const ValueKey('savings-goal-active')));
    expect(find.byKey(const ValueKey('goal-link')), findsNothing);
    expect(_fieldText(tester, 'goal-target'), '100,000,000');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a manually entered product retains its type without a link', (
    tester,
  ) async {
    final store = await _store();
    await _pumpCard(tester, store);
    await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
    await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
    await _tap(tester, find.byKey(const ValueKey('goal-manual')));
    await _enter(tester, 'goal-name', 'New sneakers');
    await _enter(tester, 'goal-target', '1499');
    await _tap(tester, find.byKey(const ValueKey('goal-save')));
    expect(store.activeSavingsGoal!.kind, SavingsGoalKind.product);
    expect(store.activeSavingsGoal!.productUrl, isNull);

    await _tap(tester, find.byKey(const ValueKey('savings-goal-active')));
    expect(find.byKey(const ValueKey('goal-link')), findsOneWidget);
    expect(_fieldText(tester, 'goal-name'), 'New sneakers');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching an imported product to an amount goal clears product metadata',
    (tester) async {
      final store = await _store();
      await _pumpCard(
        tester,
        store,
        importer: (_, _) async => const GoalProductImport(
          sourceUrl: 'https://www.example.com/airpods',
          title: 'AirPods 4',
          imageUrl: 'https://images.example.com/airpods.png',
          merchantName: 'Example store',
          priceCentavos: 149900,
          currencyCode: 'MXN',
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('open-import-editor')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
      await _enter(tester, 'goal-link', 'https://www.example.com/airpods');
      await _tap(tester, find.text('Get details from link'));
      expect(_fieldText(tester, 'goal-target'), '1,499');
      await _tap(tester, find.byKey(const ValueKey('goal-change-type')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
      expect(find.byKey(const ValueKey('goal-link')), findsNothing);
      expect(find.byType(GoalProductThumbnail), findsNothing);
      expect(_fieldText(tester, 'goal-target'), '1,499');
      await _enter(tester, 'goal-name', 'Emergency fund');
      await _tap(tester, find.byKey(const ValueKey('goal-save')));

      final goal = store.activeSavingsGoal!;
      expect(goal.kind, SavingsGoalKind.amount);
      expect(goal.name, 'Emergency fund');
      expect(goal.targetCentavos, 149900);
      expect(goal.productUrl, isNull);
      expect(goal.imageUrl, isNull);
      expect(goal.merchantName, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'imported data stays a draft until the user confirms its amount',
    (tester) async {
      final store = await _store();
      final requested = <String>[];
      const photo = 'https://images.example.com/airpods.png';
      await _pumpCard(
        tester,
        store,
        importer: (_, url) async {
          requested.add(url);
          return const GoalProductImport(
            sourceUrl: 'https://www.walmart.com.mx/product/airpods',
            title: 'AirPods 4',
            imageUrl: photo,
            priceCentavos: 149900,
            currencyCode: 'MXN',
            merchantName: 'Walmart México',
          );
        },
      );
      await _tap(tester, find.byKey(const ValueKey('open-import-editor')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
      await _enter(
        tester,
        'goal-link',
        'https://www.walmart.com.mx/product/airpods',
      );
      await _tap(tester, find.text('Get details from link'));

      expect(requested, ['https://www.walmart.com.mx/product/airpods']);
      expect(store.activeSavingsGoal, isNull);
      expect(_fieldText(tester, 'goal-name'), 'AirPods 4');
      expect(_fieldText(tester, 'goal-target'), '1,499');
      expect(
        tester
            .widget<GoalProductThumbnail>(find.byType(GoalProductThumbnail))
            .url,
        photo,
      );
      await _enter(tester, 'goal-target', '1600');
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(store.activeSavingsGoal?.targetCentavos, 160000);
      expect(store.activeSavingsGoal?.imageUrl, photo);
      expect(store.activeSavingsGoal?.name, 'AirPods 4');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing the product link clears stale imported name and price',
    (tester) async {
      final store = await _store();
      await _pumpCard(
        tester,
        store,
        importer: (_, _) async => const GoalProductImport(
          sourceUrl: 'https://www.example.com/product-a',
          title: 'Product A',
          imageUrl: 'https://images.example.com/product-a.png',
          priceCentavos: 149900,
          currencyCode: 'MXN',
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('open-import-editor')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
      await _enter(tester, 'goal-link', 'https://www.example.com/product-a');
      await _tap(tester, find.text('Get details from link'));
      expect(_fieldText(tester, 'goal-target'), '1,499');

      await _enter(tester, 'goal-link', 'https://www.example.com/product-b');
      expect(_fieldText(tester, 'goal-name'), isEmpty);
      expect(_fieldText(tester, 'goal-target'), isEmpty);
      expect(find.byType(GoalProductThumbnail), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(store.activeSavingsGoal, isNull);

      await _enter(tester, 'goal-name', 'Product B');
      await _enter(tester, 'goal-target', '2000');
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(
        store.activeSavingsGoal?.productUrl,
        'https://www.example.com/product-b',
      );
      expect(store.activeSavingsGoal?.targetCentavos, 200000);
      expect(store.activeSavingsGoal?.imageUrl, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a different imported currency requires a manually chosen amount',
    (tester) async {
      final store = await _store();
      await _pumpCard(
        tester,
        store,
        importer: (_, _) async => const GoalProductImport(
          sourceUrl: 'https://www.example.com/sneakers',
          title: 'Sneakers',
          priceCentavos: 7999,
          currencyCode: 'USD',
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('open-import-editor')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
      await _enter(tester, 'goal-link', 'https://www.example.com/sneakers');
      await _tap(tester, find.text('Get details from link'));

      expect(_fieldText(tester, 'goal-target'), isEmpty);
      expect(
        find.textContaining('The product price is in USD.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(store.activeSavingsGoal, isNull);
      await _enter(tester, 'goal-target', '1500');
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(store.activeSavingsGoal?.targetCentavos, 150000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deleting requires confirmation and returns to the empty card', (
    tester,
  ) async {
    final store = await _store();
    await store.saveSavingsGoal(
      name: 'New sneakers',
      targetCentavos: 149900,
      startingCentavos: 30000,
    );
    await _pumpCard(tester, store);
    await _tap(tester, find.byKey(const ValueKey('savings-goal-active')));
    await _tap(tester, find.text('Delete goal'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await _tap(tester, find.text('Cancel'));
    expect(store.activeSavingsGoal, isNotNull);

    await _tap(tester, find.text('Delete goal'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete goal'),
      ),
    );
    expect(store.activeSavingsGoal, isNull);
    expect(find.byType(SavingsGoalScreen), findsNothing);
    expect(find.byKey(const ValueKey('savings-goal-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['en', 'ko']) {
    testWidgets('goal card and editor fit 320dp with large $locale text', (
      tester,
    ) async {
      final store = await _store(locale: locale);
      await _pumpCard(
        tester,
        store,
        size: const Size(320, 780),
        textScale: 1.6,
        locale: Locale(locale),
      );
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
      expect(find.byKey(const ValueKey('goal-type-amount')), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-type-product')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('goal-type-product')));
      expect(find.byKey(const ValueKey('goal-link')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('goal-change-type')));
      await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
      await _enter(
        tester,
        'goal-name',
        'A very long goal name that needs truncating in the home card',
      );
      await _enter(tester, 'goal-target', '123456789');
      await _tap(tester, find.byKey(const ValueKey('goal-save')));
      expect(store.activeSavingsGoal, isNotNull);
      expect(find.byKey(const ValueKey('savings-goal-active')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home keeps its room and five tabs when the goal changes', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final store = await _store(locale: 'ko', currency: Currency.krw);
    if (_capture) await _loadCaptureFonts();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: SobraApp(store: store),
      ),
    );
    await _warmVisibleArt(tester);

    final roomFinder = find.byType(RoomScene).first;
    final roomBefore = tester.getRect(roomFinder);
    expect(roomBefore.width, closeTo(roomBefore.height, .01));
    expect(find.byKey(const ValueKey('savings-goal-empty')), findsOneWidget);
    final emptyTop = tester.getTopLeft(
      find.byKey(const ValueKey('savings-goal-empty')),
    );
    expect(emptyTop.dy, greaterThan(roomBefore.bottom));
    expect(find.byType(PixelBottomNavigation), findsOneWidget);
    await _captureScreen(tester, '01-home-empty-ko.png');

    await _tap(tester, find.byKey(const ValueKey('savings-goal-empty')));
    await _captureScreen(tester, '02-goal-type-choice-ko.png');
    await _tap(tester, find.byKey(const ValueKey('goal-type-amount')));
    await _enter(tester, 'goal-name', '1억 모으기');
    await _enter(tester, 'goal-target', '100000000');
    await _enter(tester, 'goal-starting', '10000000');
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final editorScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SavingsGoalScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    editorScroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    await _captureScreen(tester, '03-amount-goal-editor-ko.png');
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();
    await store.saveSavingsGoal(
      kind: SavingsGoalKind.amount,
      name: '1억 모으기',
      targetCentavos: 10000000000,
      startingCentavos: 1000000000,
    );
    await tester.pumpAndSettle();
    // Revealing the card may scroll the home. Reset to its opening position
    // before comparing the unchanged character scene and capturing it.
    final homeScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    homeScroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.getRect(roomFinder), roomBefore);
    expect(find.byKey(const ValueKey('savings-goal-active')), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    await _captureScreen(tester, '04-home-amount-goal-ko.png');
    expect(tester.takeException(), isNull);
    // SobraApp and the room schedule clock-boundary timers while mounted.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
