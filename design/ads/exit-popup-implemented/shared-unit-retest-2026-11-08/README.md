# Shared native_exit emulator retest

Test date: 2026-11-08, America/Mexico_City. SDK event timestamps use UTC
(2026-11-09). Android 16, read-only `Sobra_Fresh_Test`, serial `emulator-5592`.
All screenshots are raw adb captures of the current release QA build. App
content uses the preview's seeded in-memory ledger; ads are real SDK test-device
responses. No production-source advertising IDs or AdMob console settings changed.

## Existing publisher ID

Unit: `ca-app-pub-2706404530136726/3965250332`.
No unit override was supplied for the publisher APK. `build.json` records its
SHA-256, entrypoint and build configuration.

- `medium.png`: actual medium video, 320×350 dp, with a real SDK impression.
  `medium-validator.png` shows `No implementation issues found`.
- `video-skipped.png`: actual video returned to a small request and rejected
  by the Android factory before binding/presentation. No ad slot or impression.
- `video-skipped-after.png` and the paired XML prove all 16 app node bounds
  stayed unchanged. The actual exit button returned to the Android launcher;
  see `exit-action.txt`.
- Six small publisher-unit requests returned video. These include a request
  after clearing only the isolated preview app's data and a final request after
  restoring the publisher-unit APK. The image-response case could not be
  captured from this ID in this session. This is a limit of the captured evidence,
  not a claim about the unit's console configuration or future inventory.

## Supplemental small-image test

Unit: Google's official native test unit
`ca-app-pub-3940256099942544/2247696110`.

- `small-image-test-clean.png`: the same current code displaying a real non-video
  test ad at 320×100 dp. SDK load/impression events are in `small-image-test-sdk.log`.
- `small-image-test-validator.png`: `No implementation issues found`.
- The ad slot and both button bounds match before and after dismissing the
  validator. `image-test-build.json` records this separate QA build and override.
- This screenshot must not be labeled as a response from the publisher's ID.
  Afterward the original publisher-ID APK was reinstalled and verified, as
  recorded in `small-restored-publisher-sdk.log`.

`validation.json` combines the checks, exact bounds, unit IDs and SDK events.
The captures do not establish live paid serving or policy approval.

## Reproduce

On an Android test emulator only, build the publisher QA entrypoint:

```sh
flutter build apk --release --no-pub -t tool/preview_exit_popup.dart \
  --target-platform android-arm64 --build-number=2019 \
  --dart-define=SOBRA_EXIT_PREVIEW_ALLOW_RELEASE=true \
  --dart-define=SOBRA_EXIT_PREVIEW_EXPECTED_UNIT_ID=ca-app-pub-2706404530136726/3965250332
```

Use density 420 and 1080×2400 px for medium or 945×1523 px for small. The helper
`capture_case.py` records the SDK outcome and screenshots; it is configured for
the isolated serial above. Restart the preview between cases because its fixed
clock still respects the production impression interval. Actual creative type
is chosen by AdMob and cannot be inferred from template size.

For supplemental image-path QA only, set both expected-unit and
`SOBRA_EXIT_NATIVE_AD_UNIT_ID` to Google's test unit. Do not publish either
preview APK. The last standard build output in this session is the supplemental
QA preview; the publisher QA APK was restored only to the isolated emulator.
