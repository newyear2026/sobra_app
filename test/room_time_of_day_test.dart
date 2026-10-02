import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/room_time_of_day.dart';
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
}
