# Sobrita

Sobrita is an offline-first, pixel-art budget companion for Mexico. The v1 app
uses MXN, a quincena budget cycle, manual expense entry, category limits, cash
reconciliation, and five original eight-frame cat animations.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

All personal budget data is stored locally with `shared_preferences`. The
settings screen can copy a JSON backup to the clipboard.

## Firebase (Android)

The Android app uses the shared Firebase project `cs-project-nuszgcho`
(`central-logging-monitoring`) alongside RandomFocus and LOOPET. Analytics and
Crashlytics are enabled in release builds; debug/profile builds default to no
collection. Web and iOS previews skip Firebase initialization.

Analytics records app/session information, the welcome/onboarding/recovery
screens, the five main tabs, completed onboarding (`tutorial_complete`), and
successful new entries from the register form (`expense_recorded`,
`income_recorded`). Custom events carry no financial amounts, notes, receipt
contents or user identifiers. Dart error reports contain the exception type and
stack, not the exception message. Flutter framework errors are non-fatal;
unhandled asynchronous errors are fatal. Native crashes are captured by the SDK.

For an emulator verification build, opt in explicitly:

```sh
adb shell setprop debug.firebase.analytics.app com.sobra.app.sobra_app
flutter run --dart-define=TELEMETRY_ENABLED=true
# After checking Analytics DebugView:
adb shell setprop debug.firebase.analytics.app .none.
```

Use the Firebase Crashlytics test-exception procedure to verify delivery on a
test device. Restart the app after a crash and allow several minutes for the
report to appear. Do not ship a forced-crash button. If Android releases later
use `--split-debug-info`/`--obfuscate`, upload those Flutter symbols to this
project's Android app as described in the Firebase guide.

Console: https://console.firebase.google.com/project/cs-project-nuszgcho/overview

Select **Sobrita Android** in Crashlytics. Analytics shares one property across
the apps, so filter reports by Sobrita's app/data stream when reviewing its
users, events and retention.

Before publishing the next release, publish the updated privacy policy and
update Play Console's Data safety answers for Analytics and Crashlytics. The
policy sources in `docs/` remain drafts with the existing identity placeholders.
Firebase's SDK disclosure reference:
https://firebase.google.com/docs/android/play-data-disclosure
