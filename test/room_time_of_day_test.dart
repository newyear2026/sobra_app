import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/room_time_of_day.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/room_lighting.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  test('room phases use the device-local wall clock at their boundaries', () {
    RoomTimeOfDay at(int hour, int minute) =>
        RoomTimeOfDay.fromLocal(DateTime(2026, 10, 1, hour, minute));

    expect(at(5, 29), RoomTimeOfDay.night);
    expect(at(5, 30), RoomTimeOfDay.dawn);
    expect(at(8, 0), RoomTimeOfDay.day);
    expect(at(17, 29), RoomTimeOfDay.day);
    expect(at(17, 30), RoomTimeOfDay.sunset);
    expect(at(20, 0), RoomTimeOfDay.night);
  });

  test('the next change is the next phase start on the wall clock', () {
    DateTime after(int hour, int minute) =>
        RoomTimeOfDay.nextChangeAfter(DateTime(2026, 10, 1, hour, minute));

    expect(after(3, 0), DateTime(2026, 10, 1, 5, 30));
    expect(after(5, 30), DateTime(2026, 10, 1, 8));
    expect(after(12, 0), DateTime(2026, 10, 1, 17, 30));
    expect(after(17, 30), DateTime(2026, 10, 1, 20));
    expect(after(21, 0), DateTime(2026, 10, 2, 5, 30));
    // Every answer is a moment where the phase really does change.
    for (var hour = 0; hour < 24; hour++) {
      final now = DateTime(2026, 10, 1, hour, 15);
      final next = RoomTimeOfDay.nextChangeAfter(now);
      expect(
        RoomTimeOfDay.fromLocal(next),
        isNot(
          RoomTimeOfDay.fromLocal(next.subtract(const Duration(minutes: 1))),
        ),
      );
    }
  });

  testWidgets('all room themes select their own night and sunset art', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 21));
    await store.setReducedMotion(true);
    Future<void> show(
      String roomId,
      Map<RoomSlot, String> placements, {
      RoomTimeOfDay phase = RoomTimeOfDay.night,
    }) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 600,
                child: RoomScene(
                  variant: RoomSceneVariant.immersive,
                  roomId: roomId,
                  placements: placements,
                  message: '',
                  timeOfDay: phase,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await show(RoomThemes.casaClaraId, {
      RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
    });
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/rooms/casa_clara/background_portrait_night_unlit.png',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CustomPaint>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint && widget.painter is RoomLampGlow,
            ),
          )
          .painter,
      isA<RoomLampGlow>().having(
        (painter) => painter.floorLamps.length,
        'placed floor lamps',
        1,
      ),
    );

    await show(RoomThemes.casaClaraId, {});
    final unlit = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is RoomLampGlow,
      ),
    );
    expect((unlit.painter! as RoomLampGlow).floorLamps, isEmpty);

    for (final (roomId, directory) in [
      (RoomThemes.casaJardinId, 'casa_jardin'),
      (RoomThemes.casaDePlayaId, 'casa_de_playa'),
      (RoomThemes.casaTorreId, 'casa_torre'),
      (RoomThemes.casaMontanaId, 'casa_montana'),
      (RoomThemes.casaInvernaderoId, 'casa_invernadero'),
    ]) {
      await show(roomId, {RoomSlot.floorLeft: RoomDecorAssets.floorLampId});
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/rooms/$directory/background_portrait_night_unlit.png',
        ),
        findsOneWidget,
      );
      final glow = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is RoomLampGlow,
        ),
      );
      expect((glow.painter! as RoomLampGlow).floorLamps, hasLength(1));

      await show(roomId, {}, phase: RoomTimeOfDay.sunset);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/rooms/$directory/background_portrait_sunset_unlit.png',
        ),
        findsOneWidget,
      );
    }
  });

  test('at night furniture and the character stay lighter than the room', () {
    final room = roomShade(RoomTimeOfDay.night)!;
    final subject = roomSubjectShade(RoomTimeOfDay.night)!;
    expect(subject.r, greaterThan(room.r));
    expect(subject.g, greaterThan(room.g));
    expect(subject.b, greaterThan(room.b));
    expect(roomShade(RoomTimeOfDay.day), isNull);
  });

  testWidgets(
    'bronze lantern lights its shade and warms the ivory sofa at night',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 10, 2, 21));
      await store.setReducedMotion(true);
      Future<void> show({required bool lamp}) async {
        await tester.pumpWidget(
          SobraScope(
            store: store,
            child: MaterialApp(
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              home: SizedBox(
                width: 360,
                height: 560,
                child: RoomScene(
                  variant: RoomSceneVariant.immersive,
                  roomId: RoomThemes.casaTorreId,
                  timeOfDay: RoomTimeOfDay.night,
                  placements: {
                    RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
                    if (lamp)
                      RoomSlot.floorLeft: RoomDecorAssets.bronzeLanternLampId,
                  },
                  message: '',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      final sofa = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  RoomDecorAssets.ivorySofa,
        ),
        matching: find.byType(RoomSubjectLight),
      );
      await show(lamp: true);
      final glow =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint &&
                          widget.painter is RoomLampGlow,
                    ),
                  )
                  .painter!
              as RoomLampGlow;
      expect(glow.bronzeLamps, hasLength(1));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is RoomLampShades,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sofa, matching: find.byType(ShaderMask)),
        findsOneWidget,
      );
      final light = tester.widget<RoomSubjectLight>(sofa).lamps.single;
      final lamp = glow.bronzeLamps.single;
      // The hanging paper lantern is right of the stem, well above the base.
      expect(light.dx, greaterThan(lamp.center.dx));
      expect(
        light.dy,
        inExclusiveRange(
          lamp.top + lamp.height * .12,
          lamp.top + lamp.height * .28,
        ),
      );
      await show(lamp: false);
      expect(
        find.descendant(of: sofa, matching: find.byType(ShaderMask)),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is RoomLampShades,
        ),
        findsNothing,
      );
    },
  );

  testWidgets('a placed lamp warms nearby furniture; without one it is flat', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 21));
    await store.setReducedMotion(true);
    Future<void> show(Map<RoomSlot, String> placements) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 600,
                child: RoomScene(
                  variant: RoomSceneVariant.immersive,
                  placements: placements,
                  message: '',
                  timeOfDay: RoomTimeOfDay.night,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    final sofa = find.ancestor(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                RoomDecorAssets.launchSofa,
      ),
      matching: find.byType(RoomSubjectLight),
    );

    await show({
      RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
      RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
    });
    expect(
      find.descendant(of: sofa, matching: find.byType(ShaderMask)),
      findsOneWidget,
    );

    await show({RoomSlot.floorSofa: RoomDecorAssets.launchSofaId});
    expect(
      find.descendant(of: sofa, matching: find.byType(ShaderMask)),
      findsNothing,
    );
    expect(
      find.descendant(of: sofa, matching: find.byType(ColorFiltered)),
      findsOneWidget,
    );
  });

  testWidgets('room uses the app clock on entry and after resume', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var currentMoment = DateTime(2026, 10, 1, 12);
    final store = await SobraStore.load(now: () => currentMoment);
    await store.setReducedMotion(true);
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
    bool shows(String asset) => find
        .byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        )
        .evaluate()
        .isNotEmpty;
    expect(
      shows('assets/rooms/casa_clara/background_portrait_unlit.png'),
      isTrue,
    );
    currentMoment = DateTime(2026, 10, 1, 21);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      shows('assets/rooms/casa_clara/background_portrait_night_unlit.png'),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('room-time-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day').last);
    await tester.pumpAndSettle();
    expect(
      shows('assets/rooms/casa_clara/background_portrait_unlit.png'),
      isTrue,
    );
  });

  // Inicio's card opens the room, so it shows the same light the room and
  // Decorate do. It used to stay on the plain daytime art at every hour.
  testWidgets('the Home room follows the clock like the room it opens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var currentMoment = DateTime(2026, 10, 1, 17, 29);
    final store = await SobraStore.load(now: () => currentMoment);
    await store.setReducedMotion(true);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.grantCatalogEntries({'michi', 'poodle'});
    await store.takeLaunchGiftNotice();
    store.takePendingXpNotice();
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    RoomTimeOfDay? homePhase() => tester
        .widget<RoomScene>(
          find.byWidgetPredicate(
            (widget) =>
                widget is RoomScene &&
                widget.variant == RoomSceneVariant.preview,
          ),
        )
        .timeOfDay;
    expect(homePhase(), RoomTimeOfDay.day);

    // Left open across a boundary, the card turns on its own.
    currentMoment = DateTime(2026, 10, 1, 17, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(homePhase(), RoomTimeOfDay.sunset);

    // Back from the background hours later, it reads the clock again.
    currentMoment = DateTime(2026, 10, 1, 22);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(homePhase(), RoomTimeOfDay.night);

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: const RoomDecorateScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).timeOfDay,
      RoomTimeOfDay.night,
    );
  });
}
