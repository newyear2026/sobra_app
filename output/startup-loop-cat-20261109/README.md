# Repeating cat startup — 2026-11-09

This version's direct restart was subsequently replaced with a coin-retrieval
transition. See `../startup-seamless-cat-20261109/README.md` for the current loop.

The same approved 12 poses now repeat every 2500ms until initialization finishes.
Each cycle includes the original 640ms proud pause before the next coin deposit.
Android's native AnimatedVectorDrawable and the Flutter fallback both repeat;
Flutter resumes the current cycle using the native start time modulo 2500ms.
Neither the cycle nor its final pose delays navigation. Initialization failures
still expose the retry UI. The cat's existing size and position are unchanged.

## Verification

- `flutter test --no-pub test/startup_test.dart test/welcome_test.dart`: 19 passed.
- Focused `flutter analyze --no-pub`: no issues.
- `flutter build apk --debug --no-pub --target-platform android-arm64`: passed.
- Generated XML validated: all 12 animators use the same duration, infinite
  repeat count and restart mode. `git diff --check` passed.
- Android API 36 emulator: multiple visible deposit/nod cycles followed by the
  normal destination. This fresh installation routes to welcome.
- Native system animation-off setting: a still cat followed by welcome.
  Original animation scale restored after verification.
- Widget coverage includes poses recurring after multiple cycles, continued
  animation while pending, immediate disposal when ready, retry, and reduced
  motion. No additional startup delay was introduced.

## Evidence

- `native-launch.mp4`: untrimmed emulator recording, including time before launch.
- `cat-loop.mp4`: the same recording from 5.75 seconds onward, showing the cat
  cycles and destination at original speed.
- `native-poses.png`: sampled poses from the recording.
- `after-launch.png`: destination after launch.
- `motion-off.mp4`, `motion-off-poses.png`: system animation-off verification.
- `sobrita-loop-startup-arm64-debug.apk`: verified debug build.

Recordings verify behavior, not release startup performance. No physical-device
or iOS runtime check was performed for this change.

Implementation references: [Flutter repeat](https://api.flutter.dev/flutter/animation/AnimationController/repeat.html)
and [Android animation resources](https://developer.android.com/guide/topics/resources/animation-resource).
