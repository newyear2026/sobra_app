import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

DateTime _now() => DateTime(2026, 9, 14, 11);

Future<SobraStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: _now);
  await store.setReducedMotion(true);
  return store;
}

/// Rewrites the saved room as an older build would have left it.
Future<SobraStore> _reloadWithSavedRoom(Map<String, String> placements) async {
  final preferences = await SharedPreferences.getInstance();
  final state =
      jsonDecode(preferences.getString('sobra_state_v2')!)
          as Map<String, dynamic>;
  state['roomPlacementsByRoom'] = {RoomThemes.casaClaraId: placements};
  await preferences.setString('sobra_state_v2', jsonEncode(state));
  return SobraStore.load(now: _now);
}

/// Opens the decorator over a blank page, so Done has somewhere to return to.
Future<void> _pumpDecorator(WidgetTester tester, SobraStore store) async {
  tester.view.physicalSize = const Size(520, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  useSpanishDevice(tester);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        navigatorKey: navigator,
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        theme: buildSobraTheme(),
        home: const Scaffold(),
      ),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const RoomDecorateScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('saved rooms', () {
    // The lamp is a desk lamp. It used to be saved on the floor by the
    // window, which is exactly what looked wrong; it now belongs on the table.
    test('a lamp saved on the floor moves onto the table', () async {
      await _store();
      final store = await _reloadWithSavedRoom({
        'rug': RoomDecorAssets.defaultRugId,
        'floorRight': 'item-01',
        'tabletop': RoomDecorAssets.defaultTablePlantId,
      });

      final room = store.roomDecorationsFor();
      expect(room[RoomSlot.tabletop], 'item-01');
      expect(room[RoomSlot.floorRight], isNull);
      expect(room[RoomSlot.rug], RoomDecorAssets.defaultRugId);
    });

    test('an emptied default slot stays empty after a reload', () async {
      final store = await _store();
      await store.saveRoomDecorations({
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
      });

      expect(store.roomDecorationsFor()[RoomSlot.tabletop], isNull);
      expect(
        (await SobraStore.load(
          now: _now,
        )).roomDecorationsFor()[RoomSlot.tabletop],
        isNull,
      );
    });

    test('an item cannot be saved on the wrong surface or twice', () async {
      final store = await _store();
      await store.grantCatalogEntry('item-05');

      expect(
        () => store.saveRoomDecorations({RoomSlot.floorRight: 'item-01'}),
        throwsArgumentError,
      );
      expect(
        () => store.saveRoomDecorations({
          RoomSlot.wallLeft: 'item-05',
          RoomSlot.wallCenter: 'item-05',
        }),
        throwsArgumentError,
      );
    });

    test('switching themes keeps each room arrangement after reload', () async {
      final store = await _store();
      await store.saveRoomSelection(
        roomId: RoomThemes.casaJardinId,
        placementsByRoom: {
          RoomThemes.casaJardinId: {
            RoomSlot.rug: RoomDecorAssets.defaultRugId,
            RoomSlot.floorRight: RoomDecorAssets.defaultTablePlantId,
          },
        },
      );
      await store.saveRoomSelection(
        roomId: RoomThemes.casaDePlayaId,
        placementsByRoom: {
          RoomThemes.casaDePlayaId: {
            RoomSlot.rug: RoomDecorAssets.defaultRugId,
            RoomSlot.floorLeft: RoomDecorAssets.defaultTablePlantId,
          },
        },
      );

      final reloaded = await SobraStore.load(now: _now);
      expect(reloaded.equippedRoomId, RoomThemes.casaDePlayaId);
      expect(
        reloaded.roomDecorationsFor(
          RoomThemes.casaJardinId,
        )[RoomSlot.floorRight],
        RoomDecorAssets.defaultTablePlantId,
      );
      expect(
        reloaded.roomDecorationsFor(
          RoomThemes.casaDePlayaId,
        )[RoomSlot.floorLeft],
        RoomDecorAssets.defaultTablePlantId,
      );
    });
  });

  group('decorating by surface', () {
    testWidgets('only the places of the chosen item\'s surface are lit', (
      tester,
    ) async {
      final store = await _store();
      await store.grantCatalogEntry('item-05');
      await _pumpDecorator(tester, store);

      // Nothing is chosen yet, so no place is lit.
      expect(find.bySemanticsLabel(RegExp(r', lugar \d$')), findsNothing);

      // A desk lamp has one place: the side table.
      await _tapAndSettle(tester, find.text('Lámpara verde'));
      expect(find.bySemanticsLabel('Mesa, lugar 1'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Pared, lugar')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Piso, lugar')), findsNothing);

      await _tapAndSettle(tester, find.text('Pared y piso'));
      await _tapAndSettle(tester, find.text('Cuadro'));

      expect(find.bySemanticsLabel('Pared, lugar 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Pared, lugar 2'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Mesa, lugar')), findsNothing);
      expect(
        find.text('Hay 2 lugares en la pared. Toca dónde va.'),
        findsOneWidget,
      );
    });

    testWidgets('placing again moves the item, and its own place removes it', (
      tester,
    ) async {
      final store = await _store();
      await store.grantCatalogEntry('item-05');
      await _pumpDecorator(tester, store);
      await _tapAndSettle(tester, find.text('Pared y piso'));
      await _tapAndSettle(tester, find.text('Cuadro'));

      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 1'));
      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 2'));
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor()[RoomSlot.wallLeft], isNull);
      expect(store.roomDecorationsFor()[RoomSlot.wallCenter], 'item-05');

      await _pumpDecorator(tester, store);
      await _tapAndSettle(tester, find.text('Pared y piso'));
      await _tapAndSettle(tester, find.text('Cuadro'));
      expect(
        find.text('Toca otro lugar para moverlo, o el suyo para quitarlo.'),
        findsOneWidget,
      );
      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 2'));
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor().containsValue('item-05'), isFalse);
    });

    // A room without a table still needs somewhere for the starter plant.
    testWidgets('the small plant can go on the table or the floor', (
      tester,
    ) async {
      final store = await _store();
      await _pumpDecorator(tester, store);
      await _tapAndSettle(tester, find.text('Adornos'));
      await _tapAndSettle(tester, find.text('Planta de mesa'));

      expect(find.bySemanticsLabel('Mesa, lugar 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Piso, lugar 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Piso, lugar 2'), findsOneWidget);

      await _tapAndSettle(tester, find.bySemanticsLabel('Piso, lugar 2'));
      await _tapAndSettle(tester, find.text('Listo'));

      final room = (await SobraStore.load(now: _now)).roomDecorationsFor();
      expect(room[RoomSlot.floorRight], RoomDecorAssets.defaultTablePlantId);
      expect(room[RoomSlot.tabletop], isNull);
    });

    testWidgets('the lamp takes the table from the default plant', (
      tester,
    ) async {
      final store = await _store();
      await _pumpDecorator(tester, store);

      await _tapAndSettle(tester, find.text('Lámpara verde'));
      await _tapAndSettle(tester, find.bySemanticsLabel('Mesa, lugar 1'));
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor()[RoomSlot.tabletop], 'item-01');
      expect(
        store.roomDecorationsFor().containsValue(
          RoomDecorAssets.defaultTablePlantId,
        ),
        isFalse,
      );
    });
  });
}
