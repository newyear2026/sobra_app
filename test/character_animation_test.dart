import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import 'support/localizations.dart';

/// The character is the one thing on Inicio that has to keep moving, and
/// nothing else on screen would show it if it stopped. These pin the two ways
/// it could quietly die: the sprite itself, and the sprite as the home screen
/// actually builds it.
void main() {
  testWidgets('the sprite advances its own frames', (tester) async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        home: const Scaffold(
          body: Center(child: CatSprite(motion: CatMotion.idle, width: 112)),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<State>(find.byType(CharacterSprite));
    // ignore: avoid_dynamic_calls
    final v0 = (state as dynamic).debugControllerValue;
    await tester.pump(const Duration(milliseconds: 300));
    // ignore: avoid_dynamic_calls
    final v1 = (state as dynamic).debugControllerValue;
    expect(v1, isNot(v0), reason: 'the controller must advance');
  });

  testWidgets('Inicio builds it running, not frozen', (tester) async {
    useSpanishDevice(tester);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 15, 12));
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();

    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    expect(find.byType(RoomScene), findsOneWidget);
    final sprite = tester.widget<CharacterSprite>(find.byType(CharacterSprite));

    final state = tester.state<State>(find.byType(CharacterSprite));
    // ignore: avoid_dynamic_calls
    final v0 = (state as dynamic).debugControllerValue;
    await tester.pump(const Duration(milliseconds: 300));
    // ignore: avoid_dynamic_calls
    final v1 = (state as dynamic).debugControllerValue;
    expect(
      sprite.animate,
      isTrue,
      reason: 'a user who asked for no reduced motion must get motion',
    );
    expect(
      sprite.effectiveLoop,
      isTrue,
      reason: 'idle loops; only the over-budget pose plays once and holds',
    );
    expect(v1, isNot(v0));
  });
}
