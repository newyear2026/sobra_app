import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/decorations.dart';
import 'support/localizations.dart';

DateTime _now() => DateTime(2026, 9, 14, 11);

Future<SobraStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: _now);
  await store.setReducedMotion(true);
  await ownAllDecorations(store);
  await ownAllRooms(store);
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

/// Taps the drawer tile named [label], scrolling to it first: the grid
/// builds lazily, so a tile further down is not there yet.
Future<void> _tapTile(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    150,
    scrollable: find.byType(Scrollable).last,
  );
  await _tapAndSettle(tester, find.text(label));
}

void main() {
  group('saved rooms', () {
    test(
      'ivory sofa and bronze lamp stay placed after reload in all rooms',
      () async {
        final store = await _store();
        for (final room in RoomThemes.all) {
          await store.saveRoomSelection(
            roomId: room.id,
            placementsByRoom: {
              room.id: {
                RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
                RoomSlot.floorLeft: RoomDecorAssets.bronzeLanternLampId,
              },
            },
          );
        }
        final reloaded = await SobraStore.load(now: _now);
        for (final room in RoomThemes.all) {
          expect(
            reloaded.roomDecorationsFor(room.id),
            containsPair(RoomSlot.floorSofa, RoomDecorAssets.ivorySofaId),
          );
          expect(
            reloaded.roomDecorationsFor(room.id),
            containsPair(
              RoomSlot.floorLeft,
              RoomDecorAssets.bronzeLanternLampId,
            ),
          );
        }
      },
    );

    test('launch sofa and TV can stand together in every room', () async {
      final store = await _store();
      await store.grantCatalogEntries({
        RoomDecorAssets.launchSofaId,
        RoomDecorAssets.launchTvId,
      });
      for (final theme in RoomThemes.all) {
        expect(theme.slotsForItem(RoomDecorAssets.launchSofaId), [
          RoomSlot.floorSofa,
        ]);
        expect(theme.slotsForItem(RoomDecorAssets.launchTvId), [
          RoomSlot.floorCabinet,
        ]);
        final placements = {
          RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
          RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
        };
        await store.saveRoomSelection(
          roomId: theme.id,
          placementsByRoom: {theme.id: placements},
        );
        expect(
          store.roomDecorationsFor(theme.id),
          containsPair(RoomSlot.floorSofa, RoomDecorAssets.launchSofaId),
        );
        expect(
          store.roomDecorationsFor(theme.id),
          containsPair(RoomSlot.floorCabinet, RoomDecorAssets.launchTvId),
        );
      }
    });

    test('scenic rooms keep their views clear of wall decorations', () {
      for (final room in [
        RoomThemes.casaTorre,
        RoomThemes.casaMontana,
        RoomThemes.casaInvernadero,
      ]) {
        expect(room.slotsFor(RoomSurface.wall), isEmpty);
        expect(room.slotsForItem(RoomDecorAssets.wallClockId), isEmpty);
        expect(room.slotsForItem(RoomDecorAssets.floorLampId), [
          RoomSlot.floorLeft,
          RoomSlot.floorRight,
        ]);
      }
    });

    test('six new decorations have distinct places in an empty room', () async {
      final store = await _store();
      final garden = RoomThemes.casaJardin;
      final placements = <RoomSlot, String>{
        RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        RoomSlot.floorCenter: RoomDecorAssets.petBedId,
        RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
        RoomSlot.wallLeft: RoomDecorAssets.wallShelfId,
        RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
        RoomSlot.rug: RoomDecorAssets.blueCreamRugId,
      };

      for (final placement in placements.entries) {
        expect(garden.slotsForItem(placement.value), contains(placement.key));
        expect(RoomDecorAssets.assetFor(placement.value), isNotNull);
      }
      expect(garden.slotsForItem(RoomDecorAssets.savingsJarId), [
        RoomSlot.cabinetTop,
        RoomSlot.sideTableTop,
        RoomSlot.wallShelfTopLeft,
        RoomSlot.wallShelfTopRight,
      ]);
      expect(RoomThemes.casaClara.slotsForItem(RoomDecorAssets.savingsJarId), [
        RoomSlot.cabinetTop,
        RoomSlot.sideTableTop,
        RoomSlot.wallShelfTopLeft,
        RoomSlot.wallShelfTopRight,
      ]);
      expect(
        garden.slotsForItem(RoomDecorAssets.savingsJarId, placements: {}),
        isEmpty,
      );
      expect(
        garden.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: {},
        ),
        isEmpty,
      );
      expect(
        garden.slotsForItem(
          RoomDecorAssets.savingsJarId,
          placements: placements,
        ),
        [
          RoomSlot.cabinetTop,
          RoomSlot.wallShelfTopLeft,
          RoomSlot.wallShelfTopRight,
        ],
      );
      expect(
        garden.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: placements,
        ),
        [
          RoomSlot.cabinetTopRight,
          RoomSlot.wallShelfTopRight,
          RoomSlot.wallShelfTopLeft,
        ],
      );

      await store.saveRoomSelection(
        roomId: garden.id,
        placementsByRoom: {garden.id: placements},
      );
      expect(
        (await SobraStore.load(now: _now)).roomDecorationsFor(),
        equals(placements),
      );
    });

    test('the plant never goes on Casa clara\'s windowsill', () {
      final clara = RoomThemes.casaClara;

      expect(
        clara.slotsForItem(RoomDecorAssets.defaultTablePlantId, placements: {}),
        isEmpty,
      );
      expect(
        clara.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: {RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId},
        ),
        [RoomSlot.cabinetTopRight],
      );
      // Nothing else does either: the sill is part of the painted window.
      expect(
        clara.slotsForItem(RoomDecorAssets.savingsJarId, placements: {}),
        isNot(contains(RoomSlot.tabletop)),
      );
    });

    test('bookcase and side table support separate movable props', () async {
      final store = await _store();
      final room = RoomThemes.casaJardin;
      final placements = <RoomSlot, String>{
        RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
        RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
        RoomSlot.sideTableTop: RoomDecorAssets.savingsJarId,
      };
      expect(room.slotsForItem(RoomDecorAssets.slimBookcaseId), [
        RoomSlot.floorCabinet,
      ]);
      expect(room.slotsForItem(RoomDecorAssets.roundSideTableId), [
        RoomSlot.floorRight,
      ]);
      expect(
        room.slotsForItem(RoomDecorAssets.savingsJarId, placements: placements),
        [RoomSlot.cabinetTop, RoomSlot.sideTableTop],
      );
      expect(
        room.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: placements,
        ),
        [RoomSlot.cabinetTopRight, RoomSlot.sideTableTop],
      );
      await store.saveRoomSelection(
        roomId: room.id,
        placementsByRoom: {room.id: placements},
      );
      expect(
        store.roomDecorationsFor(room.id),
        containsPair(RoomSlot.sideTableTop, RoomDecorAssets.savingsJarId),
      );
      // The plant goes on the bookcase beside the jar on the table.
      await store.saveRoomSelection(
        roomId: room.id,
        placementsByRoom: {
          room.id: {
            ...placements,
            RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
          },
        },
      );
      expect(
        store.roomDecorationsFor(room.id),
        containsPair(
          RoomSlot.cabinetTopRight,
          RoomDecorAssets.defaultTablePlantId,
        ),
      );
      await expectLater(
        store.saveRoomSelection(
          roomId: room.id,
          placementsByRoom: {
            room.id: {
              ...placements,
              RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
            },
          },
        ),
        throwsArgumentError,
      );
    });

    test(
      'books and trailing plant fit both the cabinet and bookcase',
      () async {
        final store = await _store();
        for (final supportId in [
          RoomDecorAssets.lowCabinetId,
          RoomDecorAssets.slimBookcaseId,
        ]) {
          final placements = {
            RoomSlot.floorCabinet: supportId,
            RoomSlot.cabinetTop: RoomDecorAssets.shelfBooksId,
            RoomSlot.cabinetTopRight: RoomDecorAssets.trailingPlantId,
          };
          expect(
            RoomThemes.casaClara.slotsForItem(
              RoomDecorAssets.shelfBooksId,
              placements: placements,
            ),
            [RoomSlot.cabinetTop, RoomSlot.cabinetTopRight],
          );
          expect(
            RoomThemes.casaClara.slotsForItem(
              RoomDecorAssets.trailingPlantId,
              placements: placements,
            ),
            [RoomSlot.cabinetTopRight, RoomSlot.cabinetTop],
          );
          await store.saveRoomDecorations(placements);
          expect(
            (await SobraStore.load(now: _now)).roomDecorationsFor(),
            containsPair(RoomSlot.cabinetTop, RoomDecorAssets.shelfBooksId),
          );
          expect(
            store.roomDecorationsFor(),
            containsPair(
              RoomSlot.cabinetTopRight,
              RoomDecorAssets.trailingPlantId,
            ),
          );
        }
      },
    );

    test('wall shelf supports two props at either wall position', () async {
      final store = await _store();
      final room = RoomThemes.casaClara;
      for (final wallSlot in [RoomSlot.wallLeft, RoomSlot.wallCenter]) {
        final placements = <RoomSlot, String>{
          wallSlot: RoomDecorAssets.wallShelfId,
          RoomSlot.wallShelfTopLeft: RoomDecorAssets.shelfBooksId,
          RoomSlot.wallShelfTopRight: RoomDecorAssets.trailingPlantId,
        };
        expect(
          room.slotsForItem(
            RoomDecorAssets.shelfBooksId,
            placements: placements,
          ),
          [RoomSlot.wallShelfTopLeft, RoomSlot.wallShelfTopRight],
        );
        expect(
          room.slotsForItem(
            RoomDecorAssets.trailingPlantId,
            placements: placements,
          ),
          [RoomSlot.wallShelfTopRight, RoomSlot.wallShelfTopLeft],
        );
        await store.saveRoomDecorations(placements);
        expect(
          (await SobraStore.load(now: _now)).roomDecorationsFor(),
          containsPair(
            RoomSlot.wallShelfTopRight,
            RoomDecorAssets.trailingPlantId,
          ),
        );
      }
      await expectLater(
        store.saveRoomDecorations({
          RoomSlot.wallShelfTopLeft: RoomDecorAssets.shelfBooksId,
        }),
        throwsArgumentError,
      );
    });

    test(
      'the jar needs a cabinet and an old floor jar moves onto it',
      () async {
        final store = await _store();
        await expectLater(
          store.saveRoomSelection(
            roomId: RoomThemes.casaJardinId,
            placementsByRoom: {
              RoomThemes.casaJardinId: {
                RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
              },
            },
          ),
          throwsArgumentError,
        );

        final migrated = await _reloadWithSavedRoom({
          'floorCabinet': RoomDecorAssets.lowCabinetId,
          'floorAccent': RoomDecorAssets.savingsJarId,
        });
        final room = migrated.roomDecorationsFor();
        expect(room[RoomSlot.floorAccent], isNull);
        expect(room[RoomSlot.cabinetTop], RoomDecorAssets.savingsJarId);
        expect(room[RoomSlot.floorCabinet], RoomDecorAssets.lowCabinetId);
      },
    );

    test('old sill props move to furniture when it supports them', () async {
      await _store();
      final store = await _reloadWithSavedRoom({
        'rug': RoomDecorAssets.defaultRugId,
        'floorRight': RoomDecorAssets.roundSideTableId,
        'tabletop': 'item-01',
      });

      final room = store.roomDecorationsFor();
      expect(room[RoomSlot.tabletop], isNull);
      expect(room[RoomSlot.sideTableTop], 'item-01');
      expect(room[RoomSlot.floorRight], RoomDecorAssets.roundSideTableId);
      expect(room[RoomSlot.rug], RoomDecorAssets.defaultRugId);
    });

    test(
      'green lamp can move from the side table to supported shelves',
      () async {
        final store = await _store();
        final room = RoomThemes.casaClara;
        expect(room.slotsForItem('item-01', placements: {}), isEmpty);

        for (final support in [
          RoomDecorAssets.lowCabinetId,
          RoomDecorAssets.slimBookcaseId,
        ]) {
          final placements = {RoomSlot.floorCabinet: support};
          expect(room.slotsForItem('item-01', placements: placements), [
            RoomSlot.cabinetTopRight,
            RoomSlot.cabinetTop,
          ]);
          await store.saveRoomDecorations({
            ...placements,
            RoomSlot.cabinetTopRight: 'item-01',
          });
          expect(
            (await SobraStore.load(now: _now)).roomDecorationsFor(),
            containsPair(RoomSlot.cabinetTopRight, 'item-01'),
          );
        }

        for (final wallSlot in [RoomSlot.wallLeft, RoomSlot.wallCenter]) {
          final placements = {wallSlot: RoomDecorAssets.wallShelfId};
          expect(room.slotsForItem('item-01', placements: placements), [
            RoomSlot.wallShelfTopLeft,
            RoomSlot.wallShelfTopRight,
          ]);
          await store.saveRoomDecorations({
            ...placements,
            RoomSlot.wallShelfTopLeft: 'item-01',
          });
          expect(
            (await SobraStore.load(now: _now)).roomDecorationsFor(),
            containsPair(RoomSlot.wallShelfTopLeft, 'item-01'),
          );
        }
      },
    );

    test('a jar saved on the sill leaves the window clear', () async {
      await _store();
      final store = await _reloadWithSavedRoom({
        'tabletop': RoomDecorAssets.savingsJarId,
      });
      expect(store.roomDecorationsFor()[RoomSlot.tabletop], isNull);
    });

    // Rewards were free once, so a tester may have placed one they now have
    // to earn. The room leaves it out and the default takes the slot back;
    // the placement is kept for when the item is theirs again.
    test('a placed item that is not owned stays out of the room', () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = await SobraStore.load(now: _now);
      await fresh.setReducedMotion(true);
      final store = await _reloadWithSavedRoom({
        'rug': RoomDecorAssets.blueCreamRugId,
        'floorCenter': RoomDecorAssets.petBedId,
      });

      var room = store.roomDecorationsFor();
      expect(room[RoomSlot.rug], RoomDecorAssets.defaultRugId);
      expect(room[RoomSlot.floorCenter], isNull);
      expect(room.containsValue(RoomDecorAssets.petBedId), isFalse);

      await store.grantCatalogEntry(RoomDecorAssets.blueCreamRugId);
      room = store.roomDecorationsFor();
      expect(room[RoomSlot.rug], RoomDecorAssets.blueCreamRugId);
      expect(room[RoomSlot.floorCenter], isNull);
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

    test('a plant saved on the sill leaves the window clear', () async {
      await _store();
      final store = await _reloadWithSavedRoom({
        'tabletop': RoomDecorAssets.defaultTablePlantId,
      });
      expect(store.roomDecorationsFor()[RoomSlot.tabletop], isNull);
      expect(
        RoomThemes.casaClara.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: store.roomDecorationsFor(),
        ),
        isEmpty,
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
          RoomSlot.floorLeft: RoomDecorAssets.defaultTablePlantId,
        }),
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
            RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
            RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
          },
        },
      );
      await store.saveRoomSelection(
        roomId: RoomThemes.casaDePlayaId,
        placementsByRoom: {
          RoomThemes.casaDePlayaId: {
            RoomSlot.rug: RoomDecorAssets.defaultRugId,
            RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
            RoomSlot.wallLeft: RoomDecorAssets.wallShelfId,
          },
        },
      );

      final reloaded = await SobraStore.load(now: _now);
      expect(reloaded.equippedRoomId, RoomThemes.casaDePlayaId);
      expect(
        reloaded.roomDecorationsFor(
          RoomThemes.casaJardinId,
        )[RoomSlot.floorRight],
        RoomDecorAssets.terracottaPoufId,
      );
      expect(
        reloaded.roomDecorationsFor(
          RoomThemes.casaDePlayaId,
        )[RoomSlot.wallLeft],
        RoomDecorAssets.wallShelfId,
      );
    });
  });

  group('decorating by surface', () {
    testWidgets('tower furniture is selectable and saved from the drawer', (
      tester,
    ) async {
      final store = await _store();
      await store.saveRoomSelection(
        roomId: RoomThemes.casaTorreId,
        placementsByRoom: const {},
      );
      await _pumpDecorator(tester, store);

      Future<void> select(String name) async {
        await tester.scrollUntilVisible(
          find.text(name),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await _tapAndSettle(tester, find.text(name));
      }

      await select('Sofá marfil');
      expect(find.bySemanticsLabel('Piso, lugar 6'), findsOneWidget);
      await _tapAndSettle(tester, find.bySemanticsLabel('Piso, lugar 6'));
      await select('Lámpara de bronce');
      expect(find.bySemanticsLabel('Piso, lugar 2'), findsOneWidget);
      await _tapAndSettle(tester, find.bySemanticsLabel('Piso, lugar 1'));
      await _tapAndSettle(tester, find.text('Listo'));
      final reloaded = await SobraStore.load(now: _now);
      expect(
        reloaded.roomDecorationsFor(RoomThemes.casaTorreId),
        containsPair(RoomSlot.floorSofa, RoomDecorAssets.ivorySofaId),
      );
      expect(
        reloaded.roomDecorationsFor(RoomThemes.casaTorreId),
        containsPair(RoomSlot.floorLeft, RoomDecorAssets.bronzeLanternLampId),
      );
    });

    testWidgets('only the places of the chosen item\'s surface are lit', (
      tester,
    ) async {
      final store = await _store();
      await store.grantCatalogEntry('item-05');
      await _pumpDecorator(tester, store);

      // Nothing is chosen yet, so no place is lit.
      expect(find.bySemanticsLabel(RegExp(r', lugar \d$')), findsNothing);

      // Without a side table the desk lamp has no place.
      await _tapAndSettle(tester, find.text('Adornos'));
      await _tapAndSettle(tester, find.text('Lámpara verde'));
      expect(find.bySemanticsLabel('Mesa, lugar 1'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Pared, lugar')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Piso, lugar')), findsNothing);

      await _tapAndSettle(tester, find.text('Pared y piso'));
      await _tapTile(tester, 'Cuadro');

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
      await _tapTile(tester, 'Cuadro');

      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 1'));
      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 2'));
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor()[RoomSlot.wallLeft], isNull);
      expect(store.roomDecorationsFor()[RoomSlot.wallCenter], 'item-05');

      // Let the save's snackbar leave: it covers the drawer's second row.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _pumpDecorator(tester, store);
      await _tapAndSettle(tester, find.text('Pared y piso'));
      await _tapTile(tester, 'Cuadro');
      expect(
        find.text('Toca otro lugar para moverlo, o el suyo para quitarlo.'),
        findsOneWidget,
      );
      await _tapAndSettle(tester, find.bySemanticsLabel('Pared, lugar 2'));
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor().containsValue('item-05'), isFalse);
    });

    testWidgets('the table plant needs furniture instead of the window', (
      tester,
    ) async {
      final store = await _store();
      await _pumpDecorator(tester, store);
      await _tapAndSettle(tester, find.text('Adornos'));

      expect(find.bySemanticsLabel('Mesa, lugar 1'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Piso, lugar')), findsNothing);
      expect(store.roomDecorationsFor()[RoomSlot.tabletop], isNull);
    });

    testWidgets('the lamp goes on a placed side table', (tester) async {
      final store = await _store();
      await store.saveRoomDecorations({
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
        RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
      });
      await _pumpDecorator(tester, store);

      await _tapAndSettle(tester, find.text('Adornos'));
      await _tapAndSettle(tester, find.text('Lámpara verde'));
      await _tapAndSettle(
        tester,
        find.bySemanticsLabel('Mesa auxiliar redonda, lugar 1'),
      );
      await _tapAndSettle(tester, find.text('Listo'));

      expect(store.roomDecorationsFor()[RoomSlot.tabletop], isNull);
      expect(store.roomDecorationsFor()[RoomSlot.sideTableTop], 'item-01');
      expect(
        store.roomDecorationsFor().containsValue(
          RoomDecorAssets.defaultTablePlantId,
        ),
        isFalse,
      );
    });
  });
}
