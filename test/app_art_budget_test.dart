import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // PNG rooms and characters were 140 MB and pushed the release APK past
  // Play's 200 MB download cap. Originals live in design/png-sources/ and ship
  // as q90 WebP through tool/package_app_art.py.
  test('room and character art ships as WebP within the size budget', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final art = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/rooms/') ||
              path.startsWith('assets/characters/') ||
              path.startsWith('assets/costumes/'),
        )
        .toList();
    expect(art.where((path) => path.endsWith('.png')), isEmpty);
    var totalBytes = 0;
    for (final path in art) {
      totalBytes += (await rootBundle.load(path)).lengthInBytes;
    }
    // About 54 MB on 2026-10-26: rooms 5 MB, characters 17 MB, costumes 32 MB.
    expect(totalBytes, lessThan(70 * 1000 * 1000));
  });
}
