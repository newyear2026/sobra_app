import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/sobra_native_ad.dart';

import 'support/localizations.dart';

Future<void> _loadFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

/// Google's small template drawn with Sobra tokens, as in
/// native_ad_placement_test.dart.
class _SampleNativeBody extends StatelessWidget {
  const _SampleNativeBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.tealInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ANUNCIO',
                  style: pixelText(
                    size: 10,
                    bold: true,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'App de ahorro para tu quincena',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: pixelText(size: 13, bold: true),
                ),
                Text(
                  'Ejemplo de red',
                  style: pixelText(size: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(color: AppColors.teal),
            child: Text(
              'INSTALAR',
              style: pixelText(size: 11, bold: true, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

Future<SobraStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 15, 16));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  store.takePendingXpNotice();
  for (var i = 0; i < 3; i++) {
    await store.addExpense(
      amountCentavos: 4500 + i * 1800,
      category: ExpenseCategory.values[i],
      note: 'Gasto ${i + 1}',
      occurredAt: DateTime(2026, 9, 15, 9 + i),
      paymentMethod: PaymentMethod.cash,
    );
  }
  store.takePendingXpNotice();
  await store.setReducedMotion(true);
  return store;
}

typedef _Ads = ({NativeAds ledger, NativeAds budget});

Future<_Ads> _pumpApp(WidgetTester tester, SobraStore store) async {
  useSpanishDevice(tester);
  tester.view.physicalSize = const Size(520, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ledger = NativeAds(store: store, graceDays: 0)..setSdkReady(true);
  final budget = NativeAds(
    store: store,
    placement: NativeAdPlacement.budget,
    graceDays: 0,
  )..setSdkReady(true);
  await tester.pumpWidget(
    NativeAdPreviewScope(
      preview: const _SampleNativeBody(),
      child: SobraApp(store: store, nativeAds: ledger, budgetNativeAds: budget),
    ),
  );
  await tester.pump();
  return (ledger: ledger, budget: budget);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder get _budgetAd => find.byWidgetPredicate(
  (widget) =>
      widget is SobraNativeAd &&
      widget.controller.placement == NativeAdPlacement.budget,
);

void main() {
  testWidgets('Presupuesto has no slot until its tab is visited', (
    tester,
  ) async {
    final store = await _store();
    final ads = await _pumpApp(tester, store);

    expect(ads.budget.shouldPlace, isFalse);
    expect(_budgetAd, findsNothing);

    await _openTab(tester, 'Presup.');
    expect(ads.budget.shouldPlace, isTrue);
    expect(_budgetAd, findsOneWidget);
    // The ledger's visit is separate and has not started.
    expect(ads.ledger.shouldPlace, isFalse);
  });

  testWidgets('the slot sits under the last category', (tester) async {
    await _loadFonts();
    final store = await _store();
    await _pumpApp(tester, store);
    await _openTab(tester, 'Presup.');

    await tester.scrollUntilVisible(_budgetAd, 200);
    // Scroll to the end and let the "Misión lista" toast that opening
    // Presupuesto earns run out, so the photograph is the same every run.
    await tester.drag(
      find.byKey(const PageStorageKey('budget-scroll')),
      const Offset(0, -600),
    );
    // Opening Presupuesto completes a daily mission, and its XP toast floats
    // over the slot. Clear it so the photograph shows the ad itself.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    final ad = tester.getRect(_budgetAd);
    expect(tester.getRect(find.text('Otros')).bottom, lessThan(ad.top));

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../design/qa/native-ad-budget.png'),
    );
  });

  testWidgets('no slot on the prompt shown before a budget exists', (
    tester,
  ) async {
    // An owner who skipped the budget question, as in budget_unset_test.dart.
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
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 15, 16));
    await store.setReducedMotion(true);
    expect(store.hasBudget, isFalse);
    final ads = await _pumpApp(tester, store);
    await _openTab(tester, 'Presup.');

    expect(ads.budget.shouldPlace, isTrue);
    expect(_budgetAd, findsNothing);
  });

  testWidgets('leaving the tab ends the visit, and tapping it again does not '
      'start a new one', (tester) async {
    final store = await _store();
    final ads = await _pumpApp(tester, store);
    await _openTab(tester, 'Presup.');
    final first = ads.budget.visitId;

    await _openTab(tester, 'Presup.');
    expect(ads.budget.visitId, first);

    await _openTab(tester, 'Inicio');
    expect(ads.budget.shouldPlace, isFalse);
    expect(_budgetAd, findsNothing);

    await _openTab(tester, 'Presup.');
    expect(ads.budget.visitId, first + 1);
  });

  testWidgets('an impression in Movimientos holds Presupuesto for five '
      'minutes', (tester) async {
    final store = await _store();
    final ads = await _pumpApp(tester, store);

    await _openTab(tester, 'Movim.');
    ads.ledger.recordImpression();
    await tester.pump();

    await _openTab(tester, 'Presup.');
    expect(ads.budget.canOffer, isFalse);
    expect(ads.budget.shouldPlace, isFalse);
    expect(_budgetAd, findsNothing);
  });
}
