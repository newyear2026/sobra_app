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

/// Google's small native template, drawn with Sobra tokens so a photograph
/// of the slot matches the live card's size, border and CTA colour.
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
                  style: pixelText(size: 10, bold: true, color: AppColors.muted),
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

Future<SobraStore> _storeWithExpenses(int count) async {
  SharedPreferences.setMockInitialValues({});
  final now = DateTime(2026, 9, 15, 16);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 800000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 200000,
  );
  await store.completeOnboarding();
  store.takePendingXpNotice();
  const categories = ExpenseCategory.values;
  for (var i = 0; i < count; i++) {
    await store.addExpense(
      amountCentavos: 3500 + (i * 700),
      category: categories[i % categories.length],
      note: 'Gasto ${i + 1}',
      occurredAt: DateTime(2026, 9, 15 - (i < 5 ? 1 : 0), 10 + i),
      paymentMethod: i.isEven ? PaymentMethod.cash : PaymentMethod.card,
    );
  }
  await store.setReducedMotion(true);
  return store;
}

void main() {
  testWidgets('two expense rows do not reserve a native slot', (tester) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await _storeWithExpenses(2);
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    await tester.pumpWidget(SobraApp(store: store, nativeAds: ads));
    await tester.pump();
    await tester.tap(find.text('Movim.'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(ads.shouldPlace, isTrue);
    expect(find.byType(SobraNativeAd), findsNothing);
  });

  testWidgets('the third expense row is followed by the native slot', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts();

    final store = await _storeWithExpenses(5);
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    await tester.pumpWidget(
      NativeAdPreviewScope(
        preview: const _SampleNativeBody(),
        child: SobraApp(store: store, nativeAds: ads),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Movim.'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SobraNativeAd), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(SobraNativeAd), 120);
    await tester.pumpAndSettle();

    expect(find.text('ANUNCIO'), findsOneWidget);
    expect(find.text('INSTALAR'), findsOneWidget);

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../design/qa/native-ad-ledger.png'),
    );
    await expectLater(
      find.byType(SobraNativeAd),
      matchesGoldenFile('../design/qa/native-ad-card.png'),
    );
  });
}
