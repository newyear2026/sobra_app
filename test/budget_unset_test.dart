import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/models/money_movement.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/screens/budget_screen.dart';
import 'package:sobra_app/screens/transactions_screen.dart';
import 'package:sobra_app/services/sobra_widget_sync.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

String _label(MoneyMovement movement) =>
    movementTitle(lookupAppLocalizations(const Locale('es')), movement);

/// A store whose owner skipped the budget question.
///
/// Written as saved state because that is the only producer of the unset flag
/// until onboarding grows its own "not yet" answer.
Future<SobraStore> _unbudgeted() {
  SharedPreferences.setMockInitialValues({
    'sobra_state_v2': jsonEncode({
      'transactions': <Object?>[],
      'totalBudgetCentavos': 600000,
      'hasBudget': false,
      'countedCashCentavos': 0,
      'expectedCashCentavos': 0,
      'hasCompletedOnboarding': true,
    }),
  });
  return SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
}

void main() {
  Future<void> pump(WidgetTester tester, SobraStore store) async {
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(body: BudgetScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Presupuesto asks for a budget instead of charting one', (
    tester,
  ) async {
    final store = await _unbudgeted();
    await pump(tester, store);

    expect(find.text('Aún no hay presupuesto'), findsOneWidget);
    // The ring, the projection and the category limits are all shares of a
    // number nobody chose, so none of them are on screen.
    expect(find.text('Total del ciclo'), findsNothing);
    expect(find.byType(CategoryRing), findsNothing);
  });

  testWidgets('the prompt is a way out, not a dead end', (tester) async {
    final store = await _unbudgeted();
    await pump(tester, store);

    await tester.tap(find.text('Definir presupuesto'));
    await tester.pumpAndSettle();

    expect(find.text('Presupuesto total'), findsOneWidget);
  });

  testWidgets('a budget set here brings the rest of the screen back', (
    tester,
  ) async {
    final store = await _unbudgeted();
    await pump(tester, store);

    await tester.tap(find.text('Definir presupuesto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4500');
    await tester.tap(find.text('Guardar'));
    // The budget companion keeps a quiet idle loop after its saving reaction,
    // so this screen intentionally never reaches pumpAndSettle's idle state.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(store.hasBudget, isTrue);
    expect(store.totalBudgetCentavos, 450000);
    expect(find.text('Aún no hay presupuesto'), findsNothing);
    expect(find.text('Total del ciclo'), findsOneWidget);
  });

  testWidgets('the daily chart draws no limit line it cannot justify', (
    tester,
  ) async {
    final store = await _unbudgeted();
    await store.setReducedMotion(true);
    await store.addExpense(
      amountCentavos: 1800,
      category: ExpenseCategory.transport,
      note: 'Metro',
      occurredAt: DateTime(2026, 9, 5, 12),
      paymentMethod: PaymentMethod.card,
    );
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(body: TransactionsScreen()),
        ),
      ),
    );
    await tester.pump();

    // "Límite de X al día" would name a daily share of a budget that was
    // never set. The caption reports what was spent instead.
    expect(find.textContaining('Límite de'), findsNothing);
    expect(find.text('Este ciclo \$18'), findsOneWidget);
  });

  group('Inicio without a budget', () {
    Future<void> pumpApp(WidgetTester tester, SobraStore store) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await store.setReducedMotion(true);
      // This walks the prologue, not the account offer that now precedes it.
      // Answering it here keeps the test on its own subject.
      await store.answerLoginOffer();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();
    }

    testWidgets('keeps the figure\'s place and offers a way to fill it', (
      tester,
    ) async {
      await pumpApp(tester, await _unbudgeted());

      // The label stays, so the screen still reads as the one it always was.
      expect(find.text('Hoy te queda'), findsOneWidget);
      expect(find.text(emDash), findsOneWidget);
      expect(find.text('Primera misión'), findsOneWidget);
      expect(find.text('Definir presupuesto'), findsOneWidget);
    });

    testWidgets('draws no progress bar over a budget that does not exist', (
      tester,
    ) async {
      await pumpApp(tester, await _unbudgeted());

      // Both figures are Text.rich, so they need findRichText. The budget
      // one is gone with the bar; SegmentedProgress itself is not a useful
      // finder here, since the XP and mission strips draw their own.
      expect(
        find.textContaining('Presupuesto', findRichText: true),
        findsNothing,
      );
      // What was spent, and how much of the cycle is left, are true either
      // way and stay.
      expect(
        find.textContaining('Gastado', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Avance del ciclo'), findsOneWidget);
    });

    testWidgets('the quest leads to Presupuesto, which asks the same thing', (
      tester,
    ) async {
      await pumpApp(tester, await _unbudgeted());

      await tester.tap(find.text('Definir presupuesto'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay presupuesto'), findsOneWidget);
    });

    testWidgets('the cat does not counsel restraint about an unset limit', (
      tester,
    ) async {
      final store = await _unbudgeted();
      await store.addExpense(
        amountCentavos: 90000,
        category: ExpenseCategory.food,
        note: 'Mercado',
        occurredAt: DateTime(2026, 9, 5, 12),
        paymentMethod: PaymentMethod.card,
      );
      await pumpApp(tester, store);

      // The daily allowance reads zero with no budget, so measuring the day
      // against it would have the cat reacting to an overrun of nothing.
      expect(find.text('Ajustemos con calma'), findsNothing);
      expect(find.text('Vas muy bien'), findsOneWidget);
    });
  });

  group('walking the prologue', () {
    Future<void> Function(String) walker(WidgetTester tester) =>
        (String label) async {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        };

    Future<SobraStore> start(WidgetTester tester) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
      await store.setReducedMotion(true);
      // This walks the prologue, not the account offer that now precedes it.
      // Answering it here keeps the test on its own subject.
      await store.answerLoginOffer();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('the budget can be left unanswered and still finish', (
      tester,
    ) async {
      final store = await start(tester);
      final tap = walker(tester);

      await tap('Ir a ver');
      await tap('¿Acabas de hablar?'); // either answer reaches the same page
      await tap('Que se queden');
      expect(store.characterId, 'michi');

      await tap('Continuar'); // how you are paid
      await tap('Continuar'); // which day

      // The budget page used to be the one page onboarding could not pass
      // without an answer.
      await tap('Ahora no');

      expect(store.hasBudget, isFalse);
      expect(find.text('Tus primeras misiones'), findsOneWidget);
      expect(find.text(emDash), findsOneWidget);
      expect(find.text('Puedes ponerlo después desde Inicio.'), findsOneWidget);

      await tap('Ir a Inicio');

      expect(find.text('Primera misión'), findsOneWidget);
      expect(find.text('Definir presupuesto'), findsOneWidget);
    });

    testWidgets('Poodle can be chosen and stays active on the next page', (
      tester,
    ) async {
      final store = await start(tester);
      final tap = walker(tester);

      await tap('Ir a ver');
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Opacity && widget.opacity == 0.24,
        ),
        findsNothing,
      );
      await tap('¿Acabas de hablar?');
      await tap('Poodle');
      await tap('Que se queden');

      expect(store.characterId, 'poodle');
      expect(
        tester
            .widgetList<CharacterSprite>(find.byType(CharacterSprite))
            .map((sprite) => sprite.characterId),
        contains('poodle'),
      );
    });

    testWidgets('onboarding offers only Michi and Poodle', (tester) async {
      final store = await start(tester);
      final tap = walker(tester);

      await tap('Ir a ver');
      await tap('¿Acabas de hablar?');
      expect(find.text('Schnauzer'), findsNothing);
      expect(find.text('Poodle'), findsOneWidget);
      await tap('Que se queden');

      expect(store.characterId, 'michi');
      expect(
        tester
            .widgetList<CharacterSprite>(find.byType(CharacterSprite))
            .map((sprite) => sprite.characterId),
        isNot(contains('schnauzer')),
      );
    });

    testWidgets('answering it carries the figure through to Inicio', (
      tester,
    ) async {
      final store = await start(tester);
      final tap = walker(tester);

      await tap('Ir a ver');
      await tap('(traes una toalla sin decir nada)');
      await tap('Que se queden');
      await tap('Continuar');
      await tap('Continuar');
      await tester.enterText(find.byType(TextField), '4500');
      await tap('Continuar');

      expect(store.hasBudget, isTrue);
      expect(store.totalBudgetCentavos, 450000);
      expect(find.text(emDash), findsNothing);

      // Reproduce the compact Android viewport from the overflow report.
      tester.view.physicalSize = const Size(360, 720);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ir a Inicio').hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('Conteo de efectivo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(520, 2200);
      await tester.pumpAndSettle();

      await tap('Ir a Inicio');
      expect(find.text('Primera misión'), findsNothing);
    });

    testWidgets('the cash count is left for home, where it is worth XP', (
      tester,
    ) async {
      final store = await start(tester);
      final tap = walker(tester);

      await tap('Ir a ver');
      await tap('¿Acabas de hablar?');
      await tap('Que se queden');
      await tap('Continuar');
      await tap('Continuar');
      await tap('Ahora no');

      // Onboarding no longer asks. The award is gated on onboarding being
      // over, so counting inside it would have thrown the 25 XP away.
      expect(store.hasCashBaseline, isFalse);
      expect(find.text('Conteo de efectivo'), findsOneWidget);

      await tap('Ir a Inicio');
      expect(find.text('Efectivo sin configurar'), findsOneWidget);
    });
  });

  test(
    'the home widget shows no figure rather than a confident zero',
    () async {
      final store = await _unbudgeted();
      final payload = SobraWidgetSnapshot.fromStore(
        store,
        _label,
      ).toPlatformMap();

      expect(payload['hasBudget'], isFalse);
      expect(payload['todayRemainingCentavos'], 0);
      // Nothing was overrun: there was nothing to stay under.
      expect(payload['overCycleBudget'], isFalse);
      expect(payload['progressSegments'], 0);
    },
  );
}
