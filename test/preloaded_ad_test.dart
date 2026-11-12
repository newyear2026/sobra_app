import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/services/admob_rewarded_ad_port.dart';

void main() {
  late DateTime now;
  late List<String> disposed;
  late PreloadedAd<String> slot;

  setUp(() {
    now = DateTime(2026, 10, 15, 9);
    disposed = [];
    slot = PreloadedAd<String>(now: () => now, dispose: disposed.add);
  });

  test('an ad loaded moments ago is ready', () {
    slot.hold('ad');
    now = now.add(const Duration(minutes: 49));

    expect(slot.fresh, 'ad');
    expect(disposed, isEmpty);
  });

  // AdMob drops a loaded rewarded ad after an hour. The app preloads at
  // launch, so the first tap an hour later used to reach an ad that could no
  // longer be shown.
  test('an ad near the hour reads as absent and is disposed', () {
    slot.hold('ad');
    now = now.add(const Duration(minutes: 50));

    expect(slot.fresh, isNull);
    expect(disposed, ['ad']);
    expect(slot.take(), isNull);
    expect(disposed, ['ad'], reason: 'disposed once, not again on take');
  });

  test('a new ad starts its own clock', () {
    slot.hold('old');
    now = now.add(const Duration(hours: 2));
    expect(slot.fresh, isNull);

    slot.hold('new');
    now = now.add(const Duration(minutes: 10));

    expect(slot.fresh, 'new');
  });

  test('a fresh ad is handed over once', () {
    slot.hold('ad');

    expect(slot.take(), 'ad');
    expect(slot.fresh, isNull);
    expect(slot.take(), isNull);
    expect(
      disposed,
      isEmpty,
      reason: 'a shown ad is the SDK caller\'s to dispose',
    );
  });
}
