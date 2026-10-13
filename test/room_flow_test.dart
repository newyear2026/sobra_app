import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/decorations.dart';
import 'support/localizations.dart';

Future<SobraStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  // Both starters, as on an install from before they were split: Inicio
  // then has no waiting row, which is not what this test is about.
  await store.grantCatalogEntries({'michi', 'poodle'});
  await store.setReducedMotion(true);
  return store;
}

void main() {
  for (final (characterId, expectedScale) in [
    ('poodle', 1.0),
    ('alpaca', 1.28),
    ('platypus', 1.24),
    ('rabbit', 1.38),
    ('raccoon', 1.0),
    ('quokka', 1.0),
    ('maltese', 1.08),
  ]) {
    testWidgets('$characterId uses its optical size in the room', (
      tester,
    ) async {
      final store = await _store();
      if (characterId != 'poodle') {
        await store.grantCatalogEntry(characterId);
      }
      await store.chooseCharacter(characterId);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: const RoomScreen(),
          ),
        ),
      );
      await tester.pump();

      final scale = tester.widget<Transform>(
        find.byKey(const ValueKey('room-character-scale')),
      );
      expect(scale.transform.entry(0, 0), closeTo(expectedScale, .001));
      expect(
        tester
            .widget<CatSprite>(
              find.descendant(
                of: find.byType(RoomScene),
                matching: find.byType(CatSprite),
              ),
            )
            .characterId,
        characterId,
      );
    });
  }

  for (final characterId in ['michi', 'poodle', 'schnauzer']) {
    testWidgets('$characterId finishes celebrating before returning to idle', (
      tester,
    ) async {
      final store = await _store();
      if (characterId == 'schnauzer') {
        await store.grantCatalogEntry(characterId);
      }
      await store.chooseCharacter(characterId);
      await store.setReducedMotion(false);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: const RoomScreen(),
          ),
        ),
      );
      await tester.pump();
      final sprite = find.descendant(
        of: find.byType(RoomScene),
        matching: find.byType(CatSprite),
      );
      await tester.tap(sprite);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.widget<CatSprite>(sprite).motion, CatMotion.celebrate);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(tester.widget<CatSprite>(sprite).motion, CatMotion.idle);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('the name card shows the equipped character, not Michi', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await _store();
    await store.chooseCharacter('poodle');
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('es', 'MX'),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: const RoomScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Miru'), findsOneWidget);
    expect(find.text('Michi'), findsNothing);
  });

  testWidgets('the level title on Inicio names the equipped character', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _store();
    await store.chooseCharacter('poodle');

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Miru curioso'), findsOneWidget);
    expect(find.text('Michi curioso'), findsNothing);
  });

  testWidgets('the home room opens the immersive room and decorator', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _store();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Mi casa'), findsOneWidget);
    expect(find.text('Colección'), findsNothing);
    await tester.tap(find.text('Mi casa'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomScreen), findsOneWidget);
    expect(find.text('Casa clara'), findsOneWidget);
    await tester.tap(find.text('Decorar').first);
    await tester.pumpAndSettle();

    expect(find.byType(RoomDecorateScreen), findsOneWidget);
    expect(
      find.text('Elige un objeto y toca el lugar donde va.'),
      findsOneWidget,
    );
  });

  testWidgets('tap-to-place saves a decoration in its semantic slot', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _store();
    await ownAllDecorations(store);
    await store.saveRoomDecorations({
      RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
      RoomSlot.rug: RoomDecorAssets.defaultRugId,
    });

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('es', 'MX'),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const RoomDecorateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A placed side table remains one of the desk lamp's available spots.
    await tester.tap(find.text('Adornos'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lámpara verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lámpara verde'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Mesa auxiliar redonda, lugar 1'));
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(store.roomDecorationsFor()[RoomSlot.sideTableTop], 'item-01');
    expect(
      (await SobraStore.load(
        now: () => DateTime(2026, 9, 14, 10),
      )).roomDecorationsFor()[RoomSlot.sideTableTop],
      'item-01',
    );
  });
}
