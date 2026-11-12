# Exit confirmation: automatic native template selection

final result: layout/SDK verification passed; shared native_exit unit connected

This result now includes real Google Mobile Ads platform views on Android 16.
Both native template sizes loaded, rendered and reported SDK impressions on an
isolated, read-only `Sobra_Fresh_Test` emulator. The earlier shared-emulator
verification gap is resolved. `device-*.png` files are raw adb screenshots;
the older `small.png` / `medium.png` remain explicitly labeled fixture renders.

## Shared-unit emulator retest — 2026-11-08

- Fresh release QA APK and isolated read-only Android 16 emulator. Evidence:
  `design/ads/exit-popup-implemented/shared-unit-retest-2026-11-08/`.
- Existing `native_exit` (`…/3965250332`) rendered medium video at 320×350 dp,
  reported an impression and passed the SDK validator. Capture: `medium.png`.
- Six actual small requests to the same publisher ID returned video. Every
  response was rejected before presentation, with no native view or impression.
  `video-skipped.png` shows the ad-free popup. All 16 app accessibility-node
  bounds matched the follow-up dump; exit returned to the Android launcher.
- A small image response from the publisher ID was **not obtained in this run**.
  To check the current code's image path, a separate release QA build used
  Google's native-image test unit (`…/2247696110`). It rendered at 320×100 dp,
  reported an impression and passed the SDK validator. Capture:
  `small-image-test-clean.png`. This image is supplemental evidence, not a
  publisher-unit image capture.
- The publisher-unit APK was restored and its ID verified afterward. Production
  source configuration was not changed. Build hashes, units, actual SDK events,
  geometry checks and the precise verification limits are in `validation.json`.

## Shared native_exit unit — 2026-11-08

- Both sizes use the existing `native_exit` unit (`…/3965250332`) through one
  configuration getter. The common build override applies to both sizes.
  No separate small unit or additional ID is required.
- Small accepts non-video creatives and disposes video before presentation,
  producing an ad-free dialog. Medium renders either image or video content.
  The previously verified native factory and MediaView behavior are unchanged.
- Preloading, immediate ad-free fallback and frozen dialog/button geometry
  remain intact. Debug/profile still use Google's sample unit.
- The captures below document this shared-unit SDK behavior. They remain
  historical device evidence; this reconnection changes unit routing only.
- Follow-up bug review added regressions for rapid cancel taps during the
  closing animation and an SDK load exception while an ad-free dialog is open.
  Both preserve navigation and dialog geometry.
- After reconnecting the shared unit, all 14 exit regression tests and targeted
  static analysis passed. The requested subsequent emulator retest is documented
  above; the 2026-11-07 captures below remain historical evidence.

## Publisher native_exit unit verification — 2026-11-07

- Evidence directory: `design/ads/exit-popup-implemented/native-exit-3965250332/`.
- A release QA build used the actual default unit `ca-app-pub-2706404530136726/3965250332`, without overriding that default. The SDK confirmed test-device mode. This is the actual AppShell and production ad loader with seeded in-memory data, not a production rollout or a live paid-serving test.
- Final captures: `small.png` and `medium-final.png`. Both show real SDK responses prefixed `Test Ad`. Small is 320×100 dp; medium is 320×350 dp. Sizes were selected automatically from the available screen.
- Both reported SDK impressions and `No implementation issues found`. Validator evidence: `small-validator-pass.png` and `medium-validator-pass.png`.
- Initial testing found a real issue: the stock small template displayed a video creative without a MediaView. Details are preserved in `small-validator-issue.png` and `small-sdk-before-fix.log`.
- Added an Android small-template factory that checks the loaded creative before it becomes ready. Video is disposed without binding or presenting it, producing the existing ad-free fallback. Non-video uses the same Google small template and Dart styling. Medium continues to render media normally. Request cleanup also handles timeout and engine teardown.
- Verified the rejection path with Google's official native-video test unit (`…/1044960115`): real video loaded, native guard rejected it, no ad view or impression appeared, and the ad-free dialog stayed unchanged. `video-skip.png` and `video-skip-after.png` are byte-identical; `video-skip-sdk.log` records the real SDK result. This separate rejection test did not use the publisher unit.
- Paired XML dumps confirmed identical native slot and cancel/exit bounds. Tapping exit returned to the Android launcher; cancel closed the dialog. Exact evidence and UTC SDK event times are in `validation.json`.
- All 12 exit regression tests passed, targeted static analysis passed, and the release QA APK built successfully. Its SHA-256 is saved in `apk-sha256.txt`.
- The separate preview entrypoint requires an explicit release-QA flag and expected-unit check. It is not the entrypoint used to publish the app.

## Live SDK verification — 2026-11-07

- Actual captures: `design/ads/exit-popup-implemented/device-small.png` and `device-medium.png`.
- Medium screen: 1080×2400 px at density 2.625. Native template bounds: `[120,740][960,1659]`, equivalent to 320×350 dp after integer-pixel rounding.
- Small screen: 945×1523 px at density 2.625. Native template bounds: `[53,606][893,869]`, equivalent to 320×100 dp after rounding. Template selection followed available screen size, without forcing an enum in the preview.
- Both show `Test Ad : Google Ads`, the Ad badge, icon, rating and teal INSTALL action; medium additionally renders its media and body text. Both app actions fit and are separate from the ad.
- Observed medium SDK impression at device time 16:52:02.997; final small impression at 16:59:08.063. Small raw events are saved in `device-sdk-events.log`.
- Paired before/after UI Automator dumps prove identical cancel and exit button bounds in each size. Measured results: `device-validation.json`.
- Small SDK validator reported `No implementation issues found`; screenshot: `device-small-validator.png`. The informational validator overlay was dismissed before the final clean capture.
- Tapping the actual exit button returned to `com.google.android.apps.nexuslauncher/.NexusLauncherActivity`.
- No production layout change was necessary. The debug preview only gained request/impression diagnostic logging; its targeted static analysis passed.
- This used Google's test unit and seeded in-memory ledger. Ad destination clicks and production serving were not exercised.

## Visual target and evidence

### Actual-device late-load verification — 2026-11-07

- Evidence directory: `design/ads/exit-popup-implemented/late-load/`.
- The debug preview held only the SDK request start. The production cache,
  back handler and dialog were unchanged. After opening the dialog, the request
  was released and a real Google test ad loaded successfully.
- `before.png`: request held, zero impressions, no native ad slot. The dialog
  was observed 117.5 ms after sending system back, including adb/RPC overhead
  (this measures widget presence, not the end of the normal fade animation).
- Real request: 23:32:49.572719 UTC; real completion: 23:32:52.502255 UTC.
- `after.png`: SDK ready, still zero impressions and no ad slot. Seven geometry
  samples during loading and the final snapshot all matched the initial frame
  and both button rectangles exactly. Dialog size stayed 368×177 logical pixels.
- Independently captured before/after PNGs have the same SHA-256:
  `bf1c59c3492ee6b147ee6720950743608326f9b7778eaae4129c1254cd4bf998`.
- After cancel/reopen, the cached medium ad occupied 320×350 dp and the real SDK
  impression callback fired. Evidence: `reopened-with-ad.png` and `sdk-events.log`.
- `sequence.mp4` is a raw Android screen recording of the initial ad-free dialog
  remaining unchanged while loading finishes. `validation.json` contains exact
  frame/button rectangles, timestamps, all samples and SDK events.
- Reproduce with the debug APK built using
  `--dart-define=SOBRA_EXIT_PREVIEW_HOLD_AD_REQUEST=true`, then run
  `python3 -B tool/capture_exit_late_load.py` against the isolated emulator.
- Preview static analysis passed. No production behavior changes were needed.

### Original visual targets

- Source small: `/Users/jaewook/.codex/generated_images/01a1b710-9145-73e1-8a6f-c94844e64e69/exec-4fb1ae36-8480-41ae-824f-79a66fbb0408.png`.
- Source medium: `/Users/jaewook/.codex/generated_images/01a1b710-9145-73e1-8a6f-c94844e64e69/exec-96f7b427-1875-4d4b-a73d-d2251e48e3ea.png`.
- Implementation: `design/ads/exit-popup-implemented/small.png`, `medium.png`, `without-ad.png`.
- Source images: 852 × 1846. Medium/no-ad capture: 780 × 1688, from 390 × 844 logical pixels at density 2. Small capture: 720 × 1160, from 360 × 580 at density 2.
- Comparison: source and implementation opened together in one multi-image input. Composition compared at equal logical width (source factor 390/852). The short viewport deliberately differs to exercise automatic selection. This is a visual comparison, not a pixel-diff claim.
- State: Korean, light theme, completed onboarding, reduced motion, seeded ledger, root system-back exit dialog. Background amounts and room progression differ from the earlier illustrative mock.
- Focused review: full-size captures make title, copy, ad separation and both actions readable; additional cropped regions are unnecessary.
- Prior unrelated QA preserved at `design/ads/exit-popup-implemented/prior-design-qa.md`.

## Findings and comparison history

No actionable P0/P1/P2 dialog findings. First rendered comparison passed without
visual changes to the production dialog.

Accepted implementation constraints:

- Slots are exactly 320 × 100 / 320 × 350 logical pixels. Medium is taller than the illustrative mock's ad region because the native SDK template is 350 dp.
- The dialog is centered. A short screen selects the compact template before loading, rather than shrinking a medium template.
- Typography uses the actual bundled app fonts rather than generated letterforms. Buttons have a 52 dp minimum height.
- Divider uses the existing subtle `AppColors.line` token; exit remains teal with a dark border. A 32 dp gap precedes the divider.
- Reference creative has blue CTA/embedded artwork and letterboxing. Production SDK receives teal CTA styling. Reference pixels cannot verify platform text/media scaling, AdChoices or click registration.

## Fidelity surfaces

- Fonts: PixelifySans, regular/bold SobraHangul and Japanese fallback loaded. Heading/body/action hierarchy is legible with no clipping.
- Layout: square frame, fixed padding, equal actions, separated ad and exit controls. Controls fit both captured viewports. Narrow screens and large text omit ads; extremely constrained content can scroll.
- Colors: production cream, dark ink, muted copy and teal tokens. Dimmed home remains visible and button contrast is preserved.
- Assets: real AppShell and bundled room/character art. Ad fixtures are Google's native-template reference images, explicitly disclosed.
- Copy: Korean exit confirmation and farewell, plus all seven locale translations with existing localized cancel text.

## Verification

- 37 targeted tests passed: exit state machine/layout/back behavior, existing native ad rules/placement and startup regression checks.
- 3 actual-widget capture checks passed: medium, small and no-ad.
- Late fill never inserts an ad into an open dialog; its frame and button rectangles remain identical. Consent revocation hides content while keeping its space.
- Entitlement, cache expiry, template changes, stale async results, shared 5-minute impression interval, detail-route back, cancel and confirmed Android exit covered.
- Targeted static analysis passed for app code, exit tests and preview/capture tools.
- Android debug APK built; both native SDK template sizes were verified on the independent emulator as documented above.

## Reproduce

`flutter test --no-pub tool/render_exit_popup_test.dart` writes the three images.

`flutter run --no-pub -d <android-device> -t tool/preview_exit_popup.dart --debug`
uses Google's test unit and an in-memory ledger. Wait for `EXIT_PREVIEW ...: ready`,
then press system back. This QA entry point is separate from `lib/main.dart`
and does not overwrite the installed ledger's preferences.

Publisher-unit emulator QA uses `flutter build apk --release --no-pub -t tool/preview_exit_popup.dart --target-platform android-arm64 --dart-define=SOBRA_EXIT_PREVIEW_ALLOW_RELEASE=true --dart-define=SOBRA_EXIT_PREVIEW_EXPECTED_UNIT_ID=ca-app-pub-2706404530136726/3965250332`.
Run only on an Android test emulator. Do not publish the preview APK.

## Savings goal cycle popup implementation — 2026-11-09

final result: passed

This section evaluates the approved savings-goal popups only. Earlier exit-ad QA above is retained unchanged.

### Visual target and rendered evidence

- Source truth: `output/sobrita-goal-popup-ko-20261109/01-existing-goal-ko.png`, `02-no-goal-ko.png`, `03-goal-achieved-ko.png`.
- Actual Flutter widget renders: `output/sobrita-goal-popup-implemented-20261109/active-ko.png`, `empty-ko.png`, `completed-ko.png`.
- Logical viewport 390×844; renders are 780×1688 at 2×. Active/completed source is 853×1844, with essentially the same aspect ratio. Source image was compared at equal logical width without stretching. Empty source is 977×1610: its generated outer-screen aspect ratio is inconsistent, so only modal content/order and preserved home structure are comparable there.
- Source and render pairs were opened together in the same comparison tool input. `comparison.html` in the implementation evidence folder retains all three paired views for review.
- Full-view evidence covers the home, character room, modal and compact goal card. All modal copy and goal totals are legible in the supplied full-resolution views; no extra crop was necessary to assess those regions.
- The source uses illustrative future budget amounts; actual captures use a closed weekly cycle (100,000 KRW budget, 80,000 spent, 20,000 left) and a real next-cycle calculation. This is an intentional data difference, not an arithmetic regression.

### Comparison history and fixes

1. Initial renders are preserved in `before-layout-adjustment/`. [P2] Vertically centered dialogs covered the kitten's face in existing/completed states, unlike the approved compositions.
2. Reduced dialog width to 320 logical pixels, moved alignment to (0, -0.4), reduced the success icon and removed redundant currency code from the large completion amount. The room itself was never moved or resized.
3. Re-rendered all three states and re-opened each with its reference. The kitten's face and compact card are visible; the dialogs scroll on constrained screens, and all actions remain accessible. No actionable P0/P1/P2 findings remain.

### Required fidelity surfaces

- Typography: actual PixelifySans and SobraHangul fonts, existing regular/bold styles, readable hierarchy, no truncation of key actions. Generic goal-name completion copy replaces the one-off ‘1억’ headline so product and other money goals also work.
- Layout: square navy frame and offset shadow, cream panel, teal main action, lower-priority later/change actions. Slightly higher placement preserves the character. The full square room's size and bounds are asserted equal before/after each popup.
- Colors: existing surface, ink, muted and teal tokens; navy scrim keeps background recognizable. Currency values are emphasized without relying only on color for state.
- Assets: original bundled room/kitten/logo art is retained. Existing Material check/verified icons communicate completion; the mock's small decorative sparkles are not a required functional asset. No new raster placeholders or generated art replace the actual character.
- Copy/content: existing goal, no goal and achieved states match the approved actions. ‘이번 주기’ supports weekly, semimonthly and other schedules. Currency follows the user's configured currency. Explicit no-transfer copy remains on the allocation confirmation.

### Functional evidence and limits

- New domain tests cover cycle allocation, idempotency, same-cycle edits, no ledger/budget/cash/XP mutations, persistence/backup/rollback, past-spend correction, completion acknowledgement and next-goal archive.
- Dialog tests cover full/partial allocation, invalid values, dismissal, goal creation then separate confirmation, completion once, and Korean/English 320×640 at 1.3× text. Capture tests passed for all three states.
- AppShell tests cover automatic once-per-cycle display across rebuild/reload, no-goal cancellation, reaching the goal by allocation or savings income, returning from a goal editor, and XP/gift queue ordering.
- Existing settlement/history/level-up/announcement/update/gift/review regressions were checked. One old level-up test was updated from a full settlement-screen expectation to the newly approved positive-leftover popup.
- This is a Flutter production-code implementation verified with actual widget rendering, not a browser prototype. Native-device installation and OS keyboard behavior were not exercised in this QA pass.

### Follow-up polish

- P3: optional celebratory sparkle motion can be added later. The current implementation favors existing app assets and reduced-motion consistency.
