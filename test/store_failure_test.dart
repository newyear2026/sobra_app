import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

/// A preferences store whose writes can be switched off mid-test.
///
/// A save that fails is the one thing `guardStoreWrite` exists for, and
/// nothing reachable from the UI can provoke one on its own: every other
/// refusal the store raises is pre-checked by the screen that would trigger
/// it, so the disk has to be broken from underneath.
class _BreakableStore extends InMemorySharedPreferencesStore {
  _BreakableStore.empty() : super.empty();

  bool writesFail = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      writesFail
      ? Future<bool>.value(false)
      : super.setValue(valueType, key, value);
}

Future<ScaffoldMessengerState> _pumpMessenger(WidgetTester tester) async {
  final key = GlobalKey<ScaffoldMessengerState>();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: sobraLocalizationsDelegates,
      supportedLocales: sobraSupportedLocales,
      scaffoldMessengerKey: key,
      home: const Scaffold(),
    ),
  );
  return key.currentState!;
}

final l10n = lookupAppLocalizations(const Locale('es'));

void main() {
  const fallback = 'No pudimos guardar el cambio. Vuelve a intentarlo.';

  group('describeStoreFailure', () {
    test('words every refusal the store can raise', () {
      for (final failure in StoreFailure.values) {
        expect(
          describeStoreFailure(l10n, SobraStoreException(failure)),
          isNot(fallback),
          reason: '\$failure',
        );
      }
      expect(
        describeStoreFailure(
          l10n,
          const SobraStoreException(StoreFailure.saveFailed),
        ),
        'No se pudieron guardar los datos.',
      );
    });

    // A raw Dart exception says nothing a user can act on, and repeating its
    // message at them leaks whatever wording the framework happened to use.
    test('falls back to one plain line for anything else', () {
      expect(
        describeStoreFailure(l10n, ArgumentError.value(-1, 'centavos')),
        fallback,
      );
      expect(describeStoreFailure(l10n, Exception('boom')), fallback);
      expect(describeStoreFailure(l10n, StateError('internals')), fallback);
    });
  });

  testWidgets('guardStoreWrite stays quiet when the write lands', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final messenger = await _pumpMessenger(tester);
    final landed = await guardStoreWrite(messenger, l10n, () async {});
    await tester.pump();

    expect(landed, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('guardStoreWrite reports a write that threw', (tester) async {
    useSpanishDevice(tester);
    final messenger = await _pumpMessenger(tester);
    final landed = await guardStoreWrite(
      messenger,
      l10n,
      () async => throw const SobraStoreException(StoreFailure.saveFailed),
    );
    await tester.pump();

    expect(landed, isFalse);
    expect(find.text('No se pudieron guardar los datos.'), findsOneWidget);

    messenger.removeCurrentSnackBar();
    await tester.pumpAndSettle();
  });

  testWidgets('a save that never reached the disk says so and keeps the form', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = _BreakableStore.empty();
    SharedPreferencesStorePlatform.instance = preferences;
    SharedPreferences.resetStatic();
    addTearDown(SharedPreferences.resetStatic);

    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '180');
    await tester.pump();

    preferences.writesFail = true;

    await tester.dragUntilVisible(
      find.text('Guardar'),
      find.byType(SingleChildScrollView),
      const Offset(0, -120),
    );
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    // Not pumpAndSettle: the cat on Inicio loops forever, so nothing settles.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The backup copy is the first thing a save writes, so on a disk that
    // refuses everything this is the refusal that reaches the user. What
    // matters is that one of them does, in their own language, on screen.
    expect(find.text('No se pudo guardar el respaldo.'), findsOneWidget);
    expect(
      find.byType(Dialog),
      findsNothing,
      reason: 'there is nothing to celebrate',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      '180',
      reason: 'the amount is still there to retry with',
    );

    final persisted =
        jsonDecode(
              (await preferences.getAll())['flutter.sobra_state_v2']! as String,
            )
            as Map<String, dynamic>;
    expect(
      persisted['transactions'],
      isEmpty,
      reason: 'the message is true: nothing reached the disk',
    );

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).removeCurrentSnackBar();
    await tester.pump(const Duration(milliseconds: 400));
  });
}
