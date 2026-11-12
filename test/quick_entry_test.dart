import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('on by default, once', () {
    late List<MethodCall> calls;

    void android({required bool needsPermission, bool granted = true}) {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'needsQuickEntryPermission' => needsPermission,
              'setQuickEntryEnabled' => (call.arguments as bool) && granted,
              _ => throw MissingPluginException(),
            };
          });
    }

    Iterable<String> sets() => calls
        .where((call) => call.method == 'setQuickEntryEnabled')
        .map((call) => '${call.arguments}');

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('turns on where no permission is needed', () async {
      android(needsPermission: false);

      await SobraQuickEntry.applyDefaultOnce();

      expect(SobraQuickEntry.enabled.value, isTrue);
      expect(sets(), ['true']);
    });

    test('never again, so turning it off in Ajustes sticks', () async {
      android(needsPermission: false);
      await SobraQuickEntry.applyDefaultOnce();
      await SobraQuickEntry.setEnabled(false);

      await SobraQuickEntry.applyDefaultOnce();
      await SobraQuickEntry.offerAfterRecord();

      expect(SobraQuickEntry.enabled.value, isFalse);
      expect(sets(), ['true', 'false']);
    });

    test('waits for a saved record before asking for permission', () async {
      android(needsPermission: true);

      await SobraQuickEntry.applyDefaultOnce();
      expect(sets(), isEmpty, reason: 'no permission prompt at launch');

      await SobraQuickEntry.offerAfterRecord();
      expect(sets(), ['true']);
      expect(SobraQuickEntry.enabled.value, isTrue);
    });

    test('asks only once, even when the answer is no', () async {
      android(needsPermission: true, granted: false);
      await SobraQuickEntry.applyDefaultOnce();

      await SobraQuickEntry.offerAfterRecord();
      await SobraQuickEntry.offerAfterRecord();

      expect(sets(), ['true']);
      expect(SobraQuickEntry.enabled.value, isFalse);
    });

    test('a record before the default is applied asks nothing', () async {
      android(needsPermission: true);

      await SobraQuickEntry.offerAfterRecord();

      expect(calls, isEmpty);
    });

    test('without an Android host it stays off quietly', () async {
      await SobraQuickEntry.applyDefaultOnce();
      await SobraQuickEntry.offerAfterRecord();

      expect(SobraQuickEntry.enabled.value, isFalse);
    });
  });
}
