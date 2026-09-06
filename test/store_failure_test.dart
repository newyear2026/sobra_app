import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

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
    MaterialApp(scaffoldMessengerKey: key, home: const Scaffold()),
  );
  return key.currentState!;
}

void main() {
  const fallback = 'No pudimos guardar el cambio. Vuelve a intentarlo.';

  group('describeStoreFailure', () {
    test('repeats a refusal the store worded itself', () {
      expect(
        describeStoreFailure(StateError('No se pudieron guardar los datos.')),
        'No se pudieron guardar los datos.',
      );
      expect(
        describeStoreFailure(
          ArgumentError.value(100, 'centavos', 'El total debe ser mayor.'),
        ),
        'El total debe ser mayor.',
      );
    });

    test('falls back to one plain line for anything else', () {
      // ArgumentError.value carries no sentence a user could read.
      expect(
        describeStoreFailure(ArgumentError.value(-1, 'centavos')),
        fallback,
      );
      expect(describeStoreFailure(Exception('boom')), fallback);
    });
  });

  testWidgets('guardStoreWrite stays quiet when the write lands', (
    tester,
  ) async {
    final messenger = await _pumpMessenger(tester);
    final landed = await guardStoreWrite(messenger, () async {});
    await tester.pump();

    expect(landed, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('guardStoreWrite reports a write that threw', (tester) async {
    final messenger = await _pumpMessenger(tester);
    final landed = await guardStoreWrite(
      messenger,
      () async => throw StateError('No se pudieron guardar los datos.'),
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
