import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('renders the category picker preview', (tester) async {
    useSpanishDevice(tester);
    final pixelFont = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([pixelFont.load(), materialIcons.load()]);

    tester.view.physicalSize = const Size(520, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text('Hogar'));
    await tester.pump();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        '../design/category-icons/sobra-category-icons-app-screen.png',
      ),
    );
  });
}
