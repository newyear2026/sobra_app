// Captures real Spanish widgets, entering three expenses through their form.
// Uses isolated preferences; no app source or real user data is changed.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/register_screen.dart';
import 'package:sobra_app/screens/transactions_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import '../test/support/localizations.dart';

const output = 'design/marketing/three-expenses-es/source';
const previewOnly = bool.fromEnvironment('PROMO_PREVIEW');

void main() {
  testWidgets('capture coffee, taxi and snack with a verified 160 MXN total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);

    final pixel = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([pixel.load(), icons.load()]);
    SharedPreferences.setMockInitialValues({});
    // Count the opening cash before the first purchase, not at its timestamp.
    var now = DateTime(2026, 10, 6, 8);
    final store = await SobraStore.load(now: () => now);
    await store.setLanguageCode('es');
    await store.configureOnboarding(
      budgetCentavos: null,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 50000,
    );
    await store.completeOnboarding();
    await store.takeLaunchGiftNotice();

    final boundaryKey = GlobalKey();
    final frames = Directory('$output/${previewOnly ? 'preview' : 'frames'}')
      ..createSync(recursive: true);
    var number = 0;
    var mounted = 0;
    var saved = 0;
    final clips = <Map<String, Object>>[];
    final taps = <Map<String, Object>>[];

    Future<void> mount(Widget page) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: SobraScope(
            store: store,
            child: MaterialApp(
              key: ValueKey(mounted++),
              locale: const Locale('es', 'MX'),
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              theme: buildSobraTheme(),
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: page),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      if (mounted == 1) {
        await tester.runAsync(() async {
          for (final path in [
            'assets/characters/michi/idle-8.png',
            'assets/characters/michi/activity-12.png',
          ]) {
            await precacheImage(AssetImage(path), boundaryKey.currentContext!);
          }
        });
        await tester.pump();
      }
    }

    Future<void> record(String label, int count) async {
      clips.add({'name': label, 'start': number, 'count': count});
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(microseconds: 33333));
        if (!previewOnly || i == 0 || i == count - 1) {
          final boundary = boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 3);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('${frames.path}/${number.toString().padLeft(5, '0')}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(tester.takeException(), isNull);
        number++;
      }
    }

    Future<void> touch(Finder finder) async {
      expect(finder, findsOneWidget);
      final at = tester.getCenter(finder);
      taps.add({'frame': number, 'x': at.dx * 3, 'y': at.dy * 3});
      await tester.tap(finder);
      await tester.pump();
    }

    final entries = [
      ('coffee', '45', 'Café', 'Comida', 9),
      ('taxi', '80', 'Taxi', 'Transporte', 13),
      ('snack', '35', 'Antojo', 'Comida', 17),
    ];
    for (var i = 0; i < entries.length; i++) {
      final (id, amount, note, category, hour) = entries[i];
      now = DateTime(2026, 10, 6, hour);
      await mount(RegisterScreen(onSaved: () => saved++));
      await record('$id-empty', 6);
      await tester.enterText(find.byType(TextFormField).first, amount[0]);
      await record('$id-digit', 6);
      await tester.enterText(find.byType(TextFormField).first, amount);
      await touch(find.text(category));
      await record('$id-amount', 18);

      final notes = find.byType(TextFormField).at(1);
      await tester.ensureVisible(notes);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(notes, note);
      FocusManager.instance.primaryFocus?.unfocus();
      await record('$id-note', 12);
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pump(const Duration(milliseconds: 200));
      await record('$id-ready', 12);
      await touch(find.text('Guardar'));
      await record('$id-saved', 50);
      expect(saved, i + 1);
      expect(store.transactions, hasLength(i + 1));
      expect(store.transactions.first.note, note);
      print('Captured $id: $number frames');
    }

    expect(store.spentTodayCentavos, 16000);
    expect(store.totalSpentCentavos, 16000);
    expect(store.expectedCashCentavos, 34000);
    await mount(const TransactionsScreen());
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Este ciclo \$160'), findsOneWidget);
    for (final label in ['Café', 'Taxi', 'Antojo']) {
      expect(find.text(label), findsOneWidget);
    }
    await record('summary', 60);
    File('$output/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'fps': 30,
        'width': 1080,
        'height': 2160,
        'frame_count': number,
        'locale': 'es-MX',
        'demo_date': '2026-10-06',
        'today_spent_centavos': store.spentTodayCentavos,
        'transactions': store.transactions.map((e) => e.toJson()).toList(),
        'clips': clips,
        'taps': taps,
      }),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
    print('Captured $number frames; verified total MXN 160.');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
