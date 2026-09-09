import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/character_room.dart';

Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

Future<SobraStore> _buildStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 8, 10));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  await store.setReducedMotion(true);
  return store;
}

void main() {
  testWidgets('home layers Casa clara behind Michi and the status copy', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();

    final store = await _buildStore();
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          CharacterRoom.backgroundProvider(
            tester.element(find.byType(CharacterRoom)),
          ),
          tester.element(find.byType(CharacterRoom)),
        ),
        precacheImage(
          AssetImage(CatMotion.idle.asset),
          tester.element(find.byType(CatSprite)),
        ),
      ]),
    );
    await tester.pump();

    expect(find.byType(CharacterRoom), findsOneWidget);
    expect(find.byKey(CharacterRoom.backgroundKey), findsOneWidget);
    expect(find.text('Vas muy bien'), findsOneWidget);
    expect(find.byType(CatSprite), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../design/rooms/sobra-home-casa-clara-applied.png'),
    );
  });

  testWidgets('Casa clara keeps the character room valid at compact width', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        theme: buildSobraTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: CharacterRoom(
                message: 'Ajustemos con calma',
                characterBuilder: (width) => CatSprite(
                  motion: CatMotion.concern,
                  width: width,
                  animate: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          CharacterRoom.backgroundProvider(
            tester.element(find.byType(CharacterRoom)),
          ),
          tester.element(find.byType(CharacterRoom)),
        ),
        precacheImage(
          AssetImage(CatMotion.concern.asset),
          tester.element(find.byType(CatSprite)),
        ),
      ]),
    );
    await tester.pump();

    expect(find.byType(CharacterRoom), findsOneWidget);
    expect(find.text('Ajustemos con calma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
