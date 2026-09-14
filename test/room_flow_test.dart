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
  await store.setReducedMotion(true);
  return store;
}

void main() {
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

    await tester.tap(find.bySemanticsLabel('Lámpara verde'));
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(store.roomDecorationsFor()[RoomSlot.floorRight], 'item-01');
    expect(
      (await SobraStore.load(
        now: () => DateTime(2026, 9, 14, 10),
      )).roomDecorationsFor()[RoomSlot.floorRight],
      'item-01',
    );
  });
}
