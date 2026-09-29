import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/services/sobra_quick_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.sobra.app/quick_entry');

  tearDown(() async {
    SobraQuickEntry.enabled.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('quick-entry copy uses the Android channel contract', () {
    const copy = SobraQuickEntryCopy(
      question: '¿Qué quieres registrar?',
      income: 'Ingreso',
      expense: 'Gasto',
    );

    expect(copy.toPlatformMap(), {
      'question': '¿Qué quieres registrar?',
      'income': 'Ingreso',
      'expense': 'Gasto',
    });
  });

  test(
    'initialization syncs copy and enabling reports the native state',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'getQuickEntryEnabled' => false,
              'setQuickEntryEnabled' => call.arguments as bool,
              'updateQuickEntryCopy' => null,
              _ => throw MissingPluginException(),
            };
          });

      const copy = SobraQuickEntryCopy(
        question: '¿Qué quieres registrar?',
        income: 'Ingreso',
        expense: 'Gasto',
      );
      SobraQuickEntry.copy = copy;

      await SobraQuickEntry.initialize();
      expect(SobraQuickEntry.enabled.value, isFalse);
      expect(calls.map((call) => call.method), [
        'getQuickEntryEnabled',
        'updateQuickEntryCopy',
      ]);
      expect(calls.last.arguments, copy.toPlatformMap());

      expect(await SobraQuickEntry.setEnabled(true), isTrue);
      expect(SobraQuickEntry.enabled.value, isTrue);
      expect(calls.last.method, 'setQuickEntryEnabled');
      expect(calls.last.arguments, isTrue);
    },
  );
}
