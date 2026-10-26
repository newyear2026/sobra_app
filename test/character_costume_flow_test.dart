import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import 'package:sobra_app/widgets/seasonal_costume_gift.dart';

import 'support/localizations.dart';

Future<SobraStore> _store({bool claim = true}) async {
  final store = await SobraStore.load(now: () => DateTime(2026, 10, 24, 12));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'poodle', 'schnauzer'});
  await store.setReducedMotion(true);
  if (claim) await store.claimSeasonalCostumes();
  return store;
}

Future<void> _pump(
  WidgetTester tester,
  SobraStore store, {
  bool gift = false,
  Locale locale = const Locale('es'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: RepaintBoundary(
        key: const ValueKey('costume-capture'),
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
          home: gift
              ? const Scaffold(
                  body: SingleChildScrollView(
                    child: SeasonalCostumeGiftBanner(),
                  ),
                )
              : Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const RoomDecorateScreen(
                              initialCategory: RoomDecorCategory.characters,
                            ),
                          ),
                        ),
                        child: const Text('open'),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (!gift) {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('COSTUME_SCREENSHOTS')) return;
  // pumpAndSettle drains animation frames, not real asset I/O. Resolve every
  // visible texture before a screenshot so an empty loading frame cannot pass
  // for the implemented screen.
  final context = tester.element(find.byType(Navigator).first);
  final providers = <ImageProvider>[
    ...tester
        .widgetList<Image>(find.byType(Image))
        .map((widget) => widget.image),
    ...tester
        .widgetList<CharacterSprite>(find.byType(CharacterSprite))
        .map(
          (sprite) => sprite.costume == null
              ? AssetImage(sprite.asset)
              : ResizeImage(AssetImage(sprite.asset), width: 1024),
        ),
  ];
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('costume-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(
      'design/seasonal/2026-halloween-dia-de-muertos/implementation',
    );
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png').writeAsBytes(
      data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    image.dispose();
  });
}

Future<void> _chooseDracula(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('change-character-costume')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('costume-option-autumn-2026-michi')),
  );
  await tester.tap(find.byKey(const ValueKey('apply-costume')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final entry in {
      'PixelifySans': 'assets/fonts/PixelifySans.ttf',
      'SobraHangul': 'assets/fonts/SobraHangul.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'one character card each; only selected Michi appears in the outfit sheet',
    (tester) async {
      final store = await _store();
      await store.equipCharacterCostume('michi', 'autumn-2026-michi');
      await _pump(tester, store, locale: const Locale('ko'));
      final charactersTab = tester.getRect(
        find.text(
          lookupAppLocalizations(const Locale('ko')).roomCategoryCharacters,
        ),
      );
      expect(charactersTab.left, greaterThanOrEqualTo(12));
      expect(charactersTab.right, lessThanOrEqualTo(378));
      for (final id in ['michi', 'poodle', 'schnauzer']) {
        expect(
          find.byKey(ValueKey('decorate-character-scale-$id')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('costume-option-base')), findsNothing);
      await _capture(tester, '01-character-list');
      await tester.tap(find.byKey(const ValueKey('change-character-costume')));
      await tester.pumpAndSettle();
      final sheetSprites = tester.widgetList<CharacterSprite>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(CharacterSprite),
        ),
      );
      expect(sheetSprites, hasLength(2));
      expect(sheetSprites.map((sprite) => sprite.characterId).toSet(), {
        'michi',
      });
      expect(sheetSprites.map((sprite) => sprite.costumeId).toSet(), {
        null,
        'autumn-2026-michi',
      });
      await _capture(tester, '02-outfit-sheet');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preview and undo stage the outfit; Done persists it with the room',
    (tester) async {
      final store = await _store();
      await _pump(tester, store);
      await _chooseDracula(tester);
      expect(store.equippedCostumeFor('michi'), isNull);
      expect(
        tester.widget<RoomScene>(find.byType(RoomScene)).costumeId,
        'autumn-2026-michi',
      );
      expect(
        find.byKey(const ValueKey('decorate-character-scale-michi')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RoomScene>(find.byType(RoomScene)).costumeId,
        isNull,
      );
      await _chooseDracula(tester);
      await tester.tap(
        find.text(lookupAppLocalizations(const Locale('es')).roomDone),
      );
      await tester.pumpAndSettle();
      expect(store.equippedCostumeFor('michi'), 'autumn-2026-michi');
      final reopened = await SobraStore.load(now: () => DateTime(2026, 12, 1));
      expect(reopened.equippedCostumeFor('michi'), 'autumn-2026-michi');
    },
  );

  testWidgets('leaving Decorate without Done discards the appearance preview', (
    tester,
  ) async {
    final store = await _store();
    await _pump(tester, store);
    await _chooseDracula(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(store.equippedCostumeFor('michi'), isNull);
    expect(store.ownedCostumeIds, hasLength(12));
  });

  testWidgets(
    'claim disappears from home and continues to the wardrobe after receiving',
    (tester) async {
      final store = await _store(claim: false);
      final before = store.ownedCatalogIds.toSet();
      await _pump(tester, store, gift: true, locale: const Locale('ko'));
      await tester.tap(find.byKey(const ValueKey('seasonal-costume-gift')));
      await tester.pumpAndSettle();
      await _capture(tester, '03-event-gift');
      final claim = find.byKey(const ValueKey('claim-seasonal-costumes'));
      await tester.ensureVisible(claim);
      await tester.tap(claim);
      await tester.pumpAndSettle();
      expect(store.ownedCostumeIds, hasLength(12));
      expect(store.ownedCatalogIds, before);
      expect(find.byKey(const ValueKey('seasonal-costume-gift')), findsNothing);
      await _capture(tester, '04-gift-received');
      await tester.tap(claim);
      await tester.pumpAndSettle();
      expect(find.byType(RoomDecorateScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('change-character-costume')),
        findsOneWidget,
      );
    },
  );

  for (final locale in [const Locale('ko'), const Locale('de')]) {
    testWidgets(
      '${locale.languageCode} compact screen and large text keep the costume sheet usable',
      (tester) async {
        final store = await _store();
        await _pump(
          tester,
          store,
          locale: locale,
          size: const Size(320, 568),
          textScale: 1.6,
        );
        await tester.tap(
          find.byKey(const ValueKey('change-character-costume')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('apply-costume')));
        await tester.tap(find.byKey(const ValueKey('apply-costume')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
