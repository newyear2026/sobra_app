import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/localizations.dart';

Future<void> _loadFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

Future<SobraStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
  await store.setReducedMotion(true);
  return store;
}

Future<void> _pump(WidgetTester tester, SobraStore store, Widget screen) async {
  // Matches the supplied 852 px-wide phone mockups at 2× density.
  tester.view.physicalSize = const Size(426, 919);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  useSpanishDevice(tester);
  await _loadFonts();
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        locale: const Locale('es', 'MX'),
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        theme: buildSobraTheme(),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
    () => Future.wait([
      precacheImage(
        const AssetImage(RoomThemes.casaClaraPortraitAsset),
        tester.element(find.byType(screen.runtimeType)),
      ),
      precacheImage(
        const AssetImage(RoomDecorAssets.rug),
        tester.element(find.byType(screen.runtimeType)),
      ),
      precacheImage(
        const AssetImage(RoomDecorAssets.tablePlant),
        tester.element(find.byType(screen.runtimeType)),
      ),
      precacheImage(
        const AssetImage(RoomDecorAssets.lamp),
        tester.element(find.byType(screen.runtimeType)),
      ),
      precacheImage(
        AssetImage(CatMotion.idle.asset),
        tester.element(find.byType(screen.runtimeType)),
      ),
    ]),
  );
  await tester.pump();
}

void main() {
  testWidgets('immersive room visual', (tester) async {
    final store = await _store();
    await _pump(tester, store, const RoomScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-room-immersive-applied.png'),
    );
  });

  testWidgets('hybrid decorator visual', (tester) async {
    final store = await _store();
    await _pump(tester, store, const RoomDecorateScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-room-decorator-applied.png'),
    );
  });
}
