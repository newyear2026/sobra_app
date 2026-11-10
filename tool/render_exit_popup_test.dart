import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/services/admob_consent_service.dart';
import 'package:sobra_app/services/exit_native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

const _directory = 'design/ads/exit-popup-implemented';

/// An official template reference image in the real, measured ad slot.
/// This deterministic capture is NOT a live SDK impression.
class _ReferenceAd implements ExitAdCreative {
  _ReferenceAd(this.size, this.bytes);
  @override
  final ExitAdSize size;
  final Uint8List bytes;
  @override
  Widget buildWidget() => ColoredBox(
    color: Colors.white,
    child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
  );
  @override
  void dispose() {}
}

class _Consent extends AdMobConsentController {
  @override
  bool get canRequestAds => true;
}

void main() {
  for (final (name, viewport, withAd) in [
    ('medium', const Size(390, 844), true),
    ('small', const Size(360, 580), true),
    ('without-ad', const Size(390, 844), false),
  ]) {
    testWidgets('capture implemented exit dialog: $name', (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final (family, paths) in [
        ('PixelifySans', ['assets/fonts/PixelifySans.ttf']),
        (
          'SobraHangul',
          ['assets/fonts/SobraHangul.ttf', 'assets/fonts/SobraHangul-Bold.ttf'],
        ),
        ('SobraJapanese', ['assets/fonts/SobraJapanese.ttf']),
        ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
      ]) {
        final font = FontLoader(family);
        for (final path in paths) {
          font.addFont(rootBundle.load(path));
        }
        await font.load();
      }
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 11, 7, 10);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        cashCentavos: 150000,
        schedule: const PaySchedule.semiMonthly(),
      );
      await store.completeOnboarding();
      await store.takeLaunchGiftNotice();
      await store.addExpense(
        amountCentavos: 13500,
        category: ExpenseCategory.food,
        note: '점심 식사',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );
      store.takePendingXpNotice();
      await store.setLanguageCode('ko');
      await store.setReducedMotion(true);
      final bytes = withAd
          ? File('$_directory/google-$name-reference.png').readAsBytesSync()
          : Uint8List(0);
      final ads = ExitNativeAds(
        load: (size, _) async => withAd ? _ReferenceAd(size, bytes) : null,
        onImpression: () {},
      );
      addTearDown(ads.dispose);
      final consent = _Consent();
      addTearDown(consent.dispose);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: SobraScope(
            store: store,
            child: AdMobConsentScope(
              consent: consent,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildSobraTheme(),
                locale: const Locale('ko'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: AppShell(exitAds: ads),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      // This file runs with flutter test; it lives under tool/ so ordinary
      // test runs do not rewrite visual evidence.
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      if (withAd) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('exit-native-ad-slot'))),
          Size(320, name == 'medium' ? 350 : 100),
        );
      }
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$_directory/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      ads.dispose();
    });
  }
}
