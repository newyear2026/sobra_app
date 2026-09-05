import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/gamification_preview_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSobraTheme(),
        home: const GamificationPreviewScreen(),
      ),
    );
  }

  testWidgets('lists every XP design surface without mutating app state', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.text('Vista previa XP'), findsOneWidget);
    expect(find.text('Inicio con nivel'), findsOneWidget);
    expect(find.text('Misiones'), findsOneWidget);
    expect(find.text('Cierre de ciclo'), findsOneWidget);
    expect(find.text('Progreso'), findsOneWidget);
    expect(find.textContaining('Todavía no entrega XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows weekly and cycle missions from the preview hub', (
    tester,
  ) async {
    await pumpPreview(tester);

    await tester.tap(find.text('Misiones'));
    await tester.pumpAndSettle();

    expect(find.text('De la semana'), findsOneWidget);
    expect(find.text('De tu ciclo'), findsOneWidget);
    expect(find.text('5 días bajo tu límite diario'), findsOneWidget);
    expect(find.text('Cierra el mes en verde'), findsOneWidget);
    expect(
      find.textContaining('Ninguna misión te pide gastar'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the preview from debug settings', (tester) async {
    tester.view.physicalSize = const Size(520, 1600);
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
    await tester.tap(find.text('Ajustes'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Vista previa XP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Inicio con nivel'), findsOneWidget);
    expect(find.text('Cierre de ciclo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
