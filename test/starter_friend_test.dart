import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'support/localizations.dart';

void main() {
  late DateTime now;

  Future<SobraStore> onboardedWithMichi() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 20, 11);
    final store = await SobraStore.load(now: () => now);
    await store.chooseCharacter('michi');
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.takeLaunchGiftNotice();
    await store.setReducedMotion(true);
    return store;
  }

  Future<void> recordToday(SobraStore store) => store.addExpense(
    amountCentavos: 5000,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: now,
    paymentMethod: PaymentMethod.cash,
  );

  Future<void> pumpApp(WidgetTester tester, SobraStore store) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();
  }

  testWidgets('Inicio shows the other starter waiting at the door', (
    tester,
  ) async {
    final store = await onboardedWithMichi();
    await recordToday(store);
    store.takePendingXpNotice();
    await pumpApp(tester, store);

    expect(find.text('Miru espera en la puerta'), findsOneWidget);
    expect(find.text('Llega con 3 días con registros'), findsOneWidget);

    await tester.ensureVisible(find.text('Llamar ya con 2 anuncios · 0/2'));
    await tester.tap(find.text('Llamar ya con 2 anuncios · 0/2'));
    await tester.pumpAndSettle();

    // The collection opens Miru's card, which names both ways over.
    expect(
      find.text(
        '1/3 días con registros, o 0/2 anuncios. Lo que llegue primero.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the third recorded day brings Miru over and offers a switch', (
    tester,
  ) async {
    final store = await onboardedWithMichi();
    await recordToday(store);
    now = DateTime(2026, 10, 22, 11);
    await recordToday(store);
    store.takePendingXpNotice();
    await pumpApp(tester, store);
    expect(find.text('¡Miru se acercó!'), findsNothing);

    now = DateTime(2026, 10, 25, 11);
    await recordToday(store);
    await tester.pumpAndSettle();

    expect(find.text('¡Miru se acercó!'), findsOneWidget);
    expect(find.text('Seguir con Michi'), findsOneWidget);
    await tester.tap(find.text('Vivir con Miru'));
    await tester.pumpAndSettle();

    expect(store.characterId, 'poodle');
    expect(store.starterArrivalId, isNull);
    expect(find.text('Miru espera en la puerta'), findsNothing);
  });
}
