import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

void main() {
  testWidgets('budget overrun shows the concern animation final pose', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();

    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 4, 10);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 800000,
      category: ExpenseCategory.transport,
      note: 'Transporte',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );
    store.takePendingXpNotice();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          const AssetImage(RoomThemes.casaClaraPreviewAsset),
          tester.element(find.byType(RoomScene)),
        ),
        precacheImage(
          AssetImage(CatMotion.concern.asset),
          tester.element(find.byType(CatSprite)),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        '../design/animations/budget-overrun-concern-applied.png',
      ),
    );
  });
}
