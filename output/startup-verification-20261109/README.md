# Startup verification — 2026-11-09

Verified the current working tree, including the approved mint loading screen
and `assets/startup/coin-deposit.webp` animation.

- `flutter test --no-pub test/startup_test.dart test/welcome_test.dart test/receipt_test.dart test/l10n_parity_test.dart test/font_coverage_test.dart`: **49 passed**.
- `flutter analyze --no-pub lib/main.dart lib/startup.dart lib/screens/startup_screen.dart lib/widgets/coin_loading_animation.dart test/startup_test.dart`: **no issues**.
- `flutter build apk --debug --no-pub`: **passed**.
- `git diff --check`: **passed**.
- Installed the fresh debug APK on the previously empty `emulator-5556` and recorded first launch and relaunch. Both reached the welcome screen. The mint cat/jar loading screen rendered, and the animation advanced to the smiling pose. No Flutter exceptions, render overflow, or fatal app crash appeared in the inspected first-launch app log.

## Observations

Android displays its native icon splash before the Flutter loading screen.
The 2.5-second character animation does not delay initialization completion:
the app opens as soon as ready, so every pose is not guaranteed to be visible.
The first debug launch showed mainly the final pose; relaunch visibly advanced
from the deposit/sparkle portion to the smile. These recordings are functional
checks, not release startup performance measurements.

Existing Google Play services / advertising consent availability warnings
appeared in the emulator log, but did not prevent startup or screen transition.
Saved Korean copy, reduced motion, zero-size initial window, responsive layouts,
initialization failure and retry were covered by automated tests.

No application source changes were needed during this verification. Physical
devices and iOS were not runtime-tested.

## Evidence

- `android-cold-start.mp4`: first launch after installation.
- `android-relaunch.mp4`: subsequent launch.
- `android-after-startup.png`: actual destination screen.
- `android-logcat.txt`: first-launch app log.
- `android-sequence.png`, `android-motion-sequence.png`, `android-relaunch-sequence.png`: sampled recording frames for inspection.
