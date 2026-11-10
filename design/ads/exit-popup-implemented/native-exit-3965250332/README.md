# native_exit: actual emulator verification

Date: 2026-11-07. Android 16, isolated read-only `Sobra_Fresh_Test`, serial
`emulator-5592`. Screenshots are raw adb captures, not design mockups.

2026-11-08 update: both sizes use the same `native_exit` ID again. Small rejects
video before presentation and medium supports both media types, matching the
SDK behavior captured here. No separate small-unit ID is required.

## Final publisher-unit result

Release QA entrypoint: `tool/preview_exit_popup.dart`. The app used the actual
release default `ca-app-pub-2706404530136726/3965250332`. No unit override was
passed for these captures. The SDK confirmed test-device requests. Test data
was seeded in memory; this does not validate paid production serving or policy
approval, and this preview APK must not be published.

- `small.png`: 945×1523 px screen, 320×100 dp ad; actual non-video creative.
- `medium-final.png`: 1080×2400 px screen, 320×350 dp ad; actual image creative.
- `medium.png`: earlier successful medium video creative, before the small fix.
- `small-validator-pass.png` / `medium-validator-pass.png`: SDK validator says
  `No implementation issues found` for both final sizes.
- `small-sdk.log` / `medium-final-sdk.log`: release configuration, unit ID,
  request, load completion, test-device detection and impression callbacks.
- `validation.json`: exact native-view/button bounds, events, checks and APK hash.
- `exit-action.txt`: tapping the app's exit action returned to Android launcher.

## Issue found and fixed

The original Google small template displayed a video response without a
MediaView. `small-before-fix.png`, `small-validator-issue.png` and
`small-sdk-before-fix.log` preserve the failure.

The Android small factory now checks the real creative before making it ready.
Video responses are disposed before binding/presentation and use the existing
ad-free fallback. Compatible creatives still use Google's small layout and
the app's styling. Medium keeps its MediaView.

For a deterministic rejection test, a separate QA APK used Google's official
native-video test unit `ca-app-pub-3940256099942544/1044960115` via build override.
`video-skip-sdk.log` proves actual video was rejected. `video-skip.png` and
`video-skip-after.png` are identical, with no native ad view or impression.
This rejection test is separate from the publisher-unit captures above.

## Reproduce

On an Android test emulator only:

```sh
flutter build apk --release --no-pub -t tool/preview_exit_popup.dart \
  --target-platform android-arm64 \
  --dart-define=SOBRA_EXIT_PREVIEW_ALLOW_RELEASE=true \
  --dart-define=SOBRA_EXIT_PREVIEW_EXPECTED_UNIT_ID=ca-app-pub-2706404530136726/3965250332
```

Use 1080×2400 px / density 420 for medium; 945×1523 px at the same density for
small. Restart the preview for each case because it uses a fixed clock and
respects the production impression interval. Wait for `EXIT_PREVIEW ... ready`,
then use Android back. Dismiss only the SDK validator overlay before capturing;
do not tap the ad destination.

For deterministic video rejection on the current code, set both
`SOBRA_EXIT_PREVIEW_EXPECTED_UNIT_ID` and `SOBRA_EXIT_NATIVE_AD_UNIT_ID`
to the official native-video test ID above.
The final build output from this session is a QA preview, not a publishing APK.

Validation: 12 exit regression tests passed, targeted Dart analysis passed,
both release QA builds succeeded, and both actual SDK layouts passed the
validator. Official test-unit reference:
[Google AdMob test ads](https://developers.google.com/admob/android/test-ads).
