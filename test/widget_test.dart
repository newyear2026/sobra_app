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

  testWidgets('settings offers the collection destination', (tester) async {
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

    await tester.tap(find.text('Mi Sobra'));
    await tester.pumpAndSettle();
    expect(find.text('Colección'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
  });

  testWidgets('opens the interactive collection preview', (tester) async {
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
    await tester.tap(find.text('Mi Sobra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colección'));
    await tester.pumpAndSettle();

    expect(find.text('Colección'), findsOneWidget);
    expect(find.text('PERSONAJES'), findsOneWidget);
    expect(find.text('Personaje 2'), findsOneWidget);
    expect(find.text('EQUIPADO'), findsOneWidget);

    await tester.tap(find.text('OBJETOS'));
    await tester.pump();
    expect(find.text('Objeto 1'), findsOneWidget);
    expect(find.text('NIVEL 5'), findsOneWidget);
    expect(find.text('NIVEL 8'), findsOneWidget);

    await tester.tap(find.text('Objeto 1'));
    await tester.pump();
    expect(find.text('CÓMO OBTENERLO'), findsOneWidget);
    expect(find.text('Ya forma parte de tu colección.'), findsOneWidget);

    await tester.tap(find.text('EQUIPAR'));
    await tester.pump();
    expect(find.text('EQUIPADO'), findsOneWidget);
  });

  testWidgets('collection fits a compact phone width', (tester) async {
    useSpanishDevice(tester);
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.tap(find.text('Mi Sobra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colección'));
    await tester.pumpAndSettle();

    expect(find.text('Colección'), findsOneWidget);
    expect(find.text('Personaje 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
