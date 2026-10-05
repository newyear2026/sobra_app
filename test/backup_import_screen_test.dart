import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/backup_import_screen.dart';
import 'package:sobra_app/screens/recovery_screen.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';
import 'package:sobra_app/widgets/store_refresh_button.dart';

import 'support/fake_purchase_backend.dart';
import 'support/localizations.dart';

void main() {
  _settingsCopyTests();
  late SobraStore store;
  late String backup;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 10, 4, 12));
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    final data = jsonDecode(store.exportJson()) as Map<String, dynamic>;
    data['baseBudgetCentavos'] = 450000;
    backup = jsonEncode(data);
  });

  Future<void> pumpScreen(WidgetTester tester, {String locale = 'es'}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          locale: Locale(locale),
          theme: buildSobraTheme(),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BackupImportScreen(),
                  ),
                ),
                child: const Text('Open import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open import'));
    await tester.pumpAndSettle();
  }

  testWidgets('preview leaves data intact, then explicit restore applies it', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('backup-json')), backup);
    await tester.tap(find.text('Revisar respaldo'));
    await tester.pumpAndSettle();
    expect(store.baseBudgetCentavos, 600000);
    expect(find.text('0 gastos · 0 ingresos · 0 gastos fijos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Restaurar este respaldo'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Restaurar este respaldo'));
    await tester.pumpAndSettle();
    expect(store.baseBudgetCentavos, 450000);
    expect(find.byType(BackupImportScreen), findsNothing);
    expect(find.text('Respaldo restaurado.'), findsOneWidget);
  });

  testWidgets('pasting an invalid backup clears an earlier valid preview', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('backup-json')), backup);
    await tester.tap(find.text('Revisar respaldo'));
    await tester.pumpAndSettle();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': '{bad'};
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.ensureVisible(find.text('Pegar respaldo'));
    await tester.tap(find.text('Pegar respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurar este respaldo'), findsNothing);
    expect(store.baseBudgetCentavos, 600000);
    expect(find.textContaining('No es un respaldo válido'), findsOneWidget);
  });

  testWidgets(
    'recovery offers JSON import and preserves the damaged original',
    (tester) async {
      await (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await SharedPreferences.getInstance();
      const broken = '{damaged';
      await prefs.setString('sobra_state_v2', broken);
      store = await SobraStore.load(now: () => DateTime(2026, 10, 4, 12));
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(RecoveryScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Importar respaldo'));
      await tester.tap(find.text('Importar respaldo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('backup-json')), backup);
      await tester.tap(find.text('Revisar respaldo'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Restaurar este respaldo'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Restaurar este respaldo'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(store.hasStorageError, isFalse);
      expect(store.baseBudgetCentavos, 450000);
      expect(find.byType(RecoveryScreen), findsNothing);
      expect(prefs.getString('sobra_state_corrupt_v2'), broken);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['es', 'ko', 'de', 'fr', 'en', 'ja', 'pt']) {
    testWidgets('backup preview fits a narrow $locale screen', (tester) async {
      await pumpScreen(tester, locale: locale);
      final l10n = lookupAppLocalizations(Locale(locale));
      await tester.enterText(find.byKey(const ValueKey('backup-json')), backup);
      await tester.tap(find.text(l10n.backupPreview));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l10n.backupRestore),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the shop retry control recovers unavailable prices', (
    tester,
  ) async {
    final backend = FakeBackend()..available = false;
    final purchases = SobraPurchases(backend: backend, store: store);
    addTearDown(purchases.dispose);
    addTearDown(backend.close);
    await purchases.start();
    await tester.pumpWidget(
      PurchaseScope(
        purchases: purchases,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: const Scaffold(body: StoreRefreshButton()),
        ),
      ),
    );
    backend.available = true;
    backend.catalogue = [productFor('sobra.character.platypus', 'MX 39')];
    await tester.tap(find.text('Volver a cargar precios'));
    await tester.pumpAndSettle();
    expect(purchases.localizedPriceFor('sobra.character.platypus'), 'MX 39');
    expect(find.text('Precios actualizados.'), findsOneWidget);
  });
}

void _settingsCopyTests() {
  for (final fails in [false, true]) {
    testWidgets(
      fails
          ? 'a backup Android will not copy says so'
          : 'a copied backup says it was copied',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = await tester.runAsync(
          () => SobraStore.load(now: () => DateTime(2026, 10, 4, 12)),
        );
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method != 'Clipboard.setData') return null;
            if (fails) throw PlatformException(code: 'error');
            copied = (call.arguments as Map)['text'] as String;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          SobraScope(
            store: store!,
            child: MaterialApp(
              locale: const Locale('es'),
              theme: buildSobraTheme(),
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SettingsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Respaldo de datos'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        // The row is a PixelCard, and only the card takes a tap.
        final row = find
            .ancestor(
              of: find.text('Respaldo de datos'),
              matching: find.byType(PixelCard),
            )
            .first;
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(
          find.text(
            fails
                ? 'No se pudo copiar el respaldo. Vuelve a intentarlo.'
                : 'Respaldo copiado al portapapeles.',
          ),
          findsOneWidget,
        );
        expect(copied == null, fails);
      },
    );
  }
}
