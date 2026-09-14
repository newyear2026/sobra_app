import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('Google login continues into onboarding', (tester) async {
    tester.platformDispatcher
      ..localeTestValue = const Locale('ko')
      ..localesTestValue = const <Locale>[Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.setReducedMotion(true);

    // A fresh store has not answered the account offer, which is what puts
    // the login screen first. The app no longer takes a flag for it: the
    // stored answer is the only thing that decides.
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('내 기록,\n어디서든 그대로'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.text('계정 없이 시작하기'), findsOneWidget);

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pump();
    expect(find.text('Google에 연결하는 중…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sobra'), findsOneWidget);
    expect(find.text('나가 본다'), findsOneWidget);
  });

  testWidgets('shows onboarding for a new user', (tester) async {
    useSpanishDevice(tester);
    // A phone rather than the 800x600 default: the prologue carries art and
    // prose, and the 600 the harness assumes is shorter than any handset.
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    // The sprites loop, so nothing would ever settle otherwise.
    await store.setReducedMotion(true);
    // Past the account offer, which now opens the app. The test above covers
    // that screen; this one is about what follows it.
    await store.answerLoginOffer();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tu dinero, sin presión.'), findsOneWidget);
    expect(find.text('La lluvia no daba señales de parar.'), findsOneWidget);
    expect(find.text('Ir a ver'), findsOneWidget);

    await tester.tap(find.text('Ir a ver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // The prologue, not the first question: the questions start once the
    // companion has been chosen.
    expect(find.text('…habló.'), findsOneWidget);
    expect(find.text('¿Acabas de hablar?'), findsOneWidget);
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
