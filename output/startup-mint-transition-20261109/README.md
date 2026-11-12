# Mint startup transition — 2026-11-09

Android 12+ light and dark launch themes now use a transparent vector instead
of the round launcher icon. The system launch window and Flutter loading
screen retain the same mint background (`#CFEEEB`). `MainActivity` removes the
system splash overlay immediately when Android signals that it can exit,
avoiding a fade over the cat animation. No artificial startup delay was added.

## Validation

- `flutter build apk --debug --no-pub --target-platform android-arm64`: passed.
- `flutter test --no-pub test/startup_test.dart`: 10 passed.
- `git diff --check`: passed.
- Installed the new APK on `emulator-5556` (Android API 36).
- Light and dark launch recordings show a mint system window without the
  round icon, followed by the animated cat/jar loading screen and welcome.
- Dark mode was restored to the emulator's original setting (`no`).
- Inspected app logs contain no Flutter startup exception or fatal crash;
  existing emulator advertising service availability warnings remain.

The first build attempt ran out of disk space. Only rebuildable Android
intermediates (old profile outputs and partial debug native-library outputs)
were removed before the successful arm64 build. Source files and final release
artifacts were retained.

Debug emulator startup duration varied substantially. The first light recording
ended before transition; `light-full.mp4` captures the full transition, although
`am start -W` timed out waiting for its launch timing result in that run. The app
still reached welcome. The dark run completed normally (reported 3972 ms).
These recordings verify appearance and behavior, not release performance or
physical-device launch speed.

## Evidence

- `light-full.mp4`, `light-full-sequence.png`: complete light launch.
- `dark.mp4`, `dark-sequence.png`: dark launch.
- `light-after.png`: welcome screen after the first light launch.
- `light-logcat.txt`, `dark-logcat.txt`: app logs.

APK: `build/app/outputs/flutter-apk/app-debug.apk` (arm64 debug).
