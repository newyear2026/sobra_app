# One animated cat startup — 2026-11-09

This records the original single-play implementation. The subsequent repeating
motion update and its verification are in `../startup-loop-cat-20261109/README.md`.

The Android 12+ system launch surface now plays the approved coin-deposit poses
before Flutter starts. The same surface remains visible during initialization
and is removed after Flutter builds its destination (or its retry UI). There is
no second large logo / tagline / progress-bar screen and no minimum splash delay.
Normal routing is preserved: existing onboarded users reach the ledger, while
new installs reach welcome/onboarding.

The cat is centered at 144dp in Flutter. Android uses the same art scale inside
its system icon area. The native bridge also supplies the actual icon position,
size and start time to Flutter, accommodating system insets/density and avoiding
a restart of the animation underneath the native surface.

## Assets

`tool/build_startup_drawables.py` converts the approved original sprite into a
shared palette atlas and an Android AnimatedVectorDrawable. The conversion uses
181px cells and 96 palette colors; no character or pose is newly drawn.
The twelve original timings total 2500ms; the final pose holds until ready.
Invisible poses are kept outside the viewport. A stepped native interpolator
selects complete poses, avoiding partial frames caused by render-thread
interpolation of offscreen positions.

Regenerate with `python3 tool/build_startup_drawables.py` (Pillow required).

Android 7–11 use the matching static launch frame, then the centered Flutter
animation. Animation during the system launch stage requires Android 12+.
iOS launch animation was not changed or runtime-tested.

## Verification

- `flutter test --no-pub test/startup_test.dart test/welcome_test.dart`: 18 passed.
- Focused `flutter analyze --no-pub`: no issues.
- `flutter build apk --debug --no-pub --target-platform android-arm64`: passed.
- `git diff --check` and generated XML parsing: passed.
- Android API 36 emulator: native deposit motion, nod, fixed position/scale,
  and successful welcome transition observed.
- Native system animation-off setting shows a still final pose. Dark-mode
  launch keeps the same mint background. Emulator settings restored afterward.
- Automated tests cover native release only after ready/error layout, retry,
  zero-size first window, saved language, reduced motion, and small/landscape/
  tablet layouts.

No Flutter startup exceptions or fatal app crashes were found in inspected
logs. Existing emulator advertising-service availability warnings are unrelated
to this startup flow. Debug launch recordings are not release performance tests.

## Evidence

- `complete.mp4`, `complete-motion-detail.png`: final discrete pose playback.
  The clip ends before the destination; the following screenshot records it.
- `complete-after.png`: destination after startup on this fresh test install.
- `verified-motion-off.mp4`: native reduced-motion check.
- `flutter-startup.png`: actual Flutter fallback layout.
- `complete-logcat.txt`: inspected app log.

Earlier recordings in this directory are intermediate verification artifacts.
`interrupted-external-app.mp4` and its sequence image are excluded from startup
verification: a separate diagnostic app interrupted that recording on the shared
emulator. Use `complete.mp4` and `complete-after.png` for the verified result.

APK: `sobrita-unified-startup-arm64-debug.apk` (arm64 debug, copied from the
verified 2026-11-09 15:46 build).

References: [Android splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen),
[Flutter launch integration](https://docs.flutter.dev/platform-integration/android/splash-screen).
