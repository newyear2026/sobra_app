import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/xp_history_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/localizations.dart';

Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

/// Onboards eleven days before "today" so the profile card has history to
/// show: two movements and a days-with-Sobra figure bigger than one.
Future<SobraStore> _buildStore() async {
  SharedPreferences.setMockInitialValues({});
  var now = DateTime(2026, 8, 29, 10);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  now = DateTime(2026, 8, 30, 14);
  await store.addExpense(
    amountCentavos: 23000,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: DateTime(2026, 8, 30, 13),
    paymentMethod: PaymentMethod.cash,
  );
  now = DateTime(2026, 9, 8, 10);
  await store.addExpense(
    amountCentavos: 4500,
    category: ExpenseCategory.transport,
    note: '',
    occurredAt: DateTime(2026, 9, 8, 9),
    paymentMethod: PaymentMethod.card,
  );
  await store.setReducedMotion(true);
  store.takePendingXpNotice();
  return store;
}

void main() {
  testWidgets('settings leads with the Michi profile card and its sections', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();
    // The real plugin channel is absent here, so Acerca de would render its
    // dash. This image is a design reference as much as a regression guard,
    // and a dash where the version goes teaches the wrong thing — so answer
    // the way a phone would, through the same call the app makes.
    PackageInfo.setMockInitialValues(
      appName: 'Sobra',
      packageName: 'com.sobra.app.sobra_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    final store = await _buildStore();
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    await tester.tap(find.text('Mi Sobra'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => precacheImage(
        AssetImage(CatMotion.idle.asset),
        tester.element(find.byType(CatSprite)),
      ),
    );
    await tester.pump();

    // The card carries the level, the light history line, and the sections
    // sit under their headers.
    expect(find.text('Michi curioso'), findsOneWidget);
    expect(find.text('2 movimientos · 11 días con Sobra'), findsOneWidget);
    expect(find.text('PRESUPUESTO'), findsOneWidget);
    expect(find.text('PANTALLA'), findsOneWidget);
    expect(find.text('DATOS'), findsOneWidget);
    // Acerca de reports the running build rather than guessing at one.
    expect(find.text('ACERCA DE'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    // The design gallery has a section of its own: it is not data, and
    // sitting beside the backup row read as though it were.
    expect(find.text('DISEÑO'), findsOneWidget);
    final design = tester.getTopLeft(find.text('DISEÑO')).dy;
    final about = tester.getTopLeft(find.text('ACERCA DE')).dy;
    expect(
      tester.getTopLeft(find.text('DATOS')).dy,
      lessThan(about),
      reason: 'Acerca de follows the data section',
    );
    expect(
      about,
      lessThan(design),
      reason: 'the debug section comes last, so Acerca de ends a release build',
    );
    expect(
      tester.getTopLeft(find.text('Vista previa XP')).dy,
      greaterThan(design),
    );
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        '../design/settings/sobra-settings-profile-applied.png',
      ),
    );
  });

  testWidgets('the profile card opens the XP screen', (tester) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await _buildStore();
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    await tester.tap(find.text('Mi Sobra'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Michi curioso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(XpHistoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
