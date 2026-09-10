import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('shows onboarding for a new user', (tester) async {
    useSpanishDevice(tester);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tu dinero, sin presión.'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('1 de 4'), findsOneWidget);
    expect(find.text('¿Cómo recibes tus ingresos?'), findsOneWidget);
  });

  testWidgets('shows the five v1 destinations', (tester) async {
    useSpanishDevice(tester);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sobra'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movim.'), findsOneWidget);
    expect(find.text('Presup.'), findsOneWidget);
    expect(find.text('Mi Sobra'), findsOneWidget);
    // The centre tile carries the add glyph instead of a text label.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('opens the expense form from bottom navigation', (tester) async {
    useSpanishDevice(tester);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Registrar'), findsWidgets);
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Hogar'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Salud'), findsOneWidget);
    expect(find.text('Educación'), findsOneWidget);
    expect(find.text('Ocio'), findsOneWidget);
    expect(find.text('Mascotas'), findsOneWidget);
  });
}
