# Login Design QA

**Findings**

- [P2] A persistent same-input comparison capture could not be produced.
  Location: final visual QA evidence.
  Evidence: the selected source mockup rendered from `design/login/sobra-google-login-selected.png`, and the implementation rendered correctly in the Codex in-app Browser at 390 × 844. The browser surface does not expose its screenshot as a filesystem path, the live Flutter view did not render inside the local comparison iframe, and browser security policy rejected a data-URL comparison surface.
  Impact: the implementation can be inspected and interacted with, but the blocking side-by-side artifact required for a formal Product Design QA pass is unavailable.
  Fix: attach a screenshot of the open 390 × 844 preview so it can be saved and compared with the selected source in one image.

**Open Questions**

- Google OAuth, account persistence, and cloud synchronization are intentionally not connected in this visual prototype. The Google action demonstrates loading and continues into the existing onboarding or app state.
- The Korean copy uses the device's available Korean sans-serif fallback while the Sobra wordmark and Latin text retain Pixelify Sans. This is intentional because the bundled Pixelify Sans font does not contain Korean glyphs.

**Evidence**

- Source visual truth: `/Users/jaewook/dev_app/sobra_app/design/login/sobra-google-login-selected.png`
- Implementation screenshot path: unavailable from the Codex in-app Browser capture surface.
- Live implementation: `http://127.0.0.1:4173/?locale=ko`
- Attempted comparison surface: `/Users/jaewook/dev_app/sobra_app/design/qa/login-compare.html`
- Source pixels: 853 × 1844, normalized visually to 390 × 844.
- Implementation pixels: 390 × 844 CSS pixels at browser device scale factor 1.
- State: Korean locale, signed out, Google button idle; loading and post-login states were also tested.

**Required Fidelity Surfaces**

- Fonts and typography: the source and implementation share Pixelify Sans for the brand and Latin fragments. Korean copy uses explicit Noto/Apple system fallbacks with 700 weight for the heading and CTA so it remains readable and visually strong.
- Spacing and layout rhythm: the hero occupies the same upper 43% of the 390 × 844 frame. The heading, body, Google button, privacy strip, and guest action align to the source's vertical sequence and 24 px side inset.
- Colors and visual tokens: the implementation uses Sobra's existing paper, surface, navy ink, teal, cash-soft, and cash-ink tokens, with square borders and a teal pixel offset shadow.
- Image quality and asset fidelity: the selected mockup's exact hero region and Google G raster were extracted into project assets, preserving the chosen Michi/device composition without placeholder art or code-drawn substitutes.
- Copy and content: Korean source copy is preserved. English and Spanish equivalents are included for the app's supported locales.
- Responsiveness and accessibility: the login screen fits 390 × 844 without clipping, scrolls on shorter displays, exposes semantic labels, and uses 48 px or larger action targets.

**Full-view Comparison**

- Separate visual inspection at 390 × 844 found no remaining actionable layout mismatch after the Korean heading weight was strengthened.
- A same-input source-plus-implementation comparison was attempted through the saved comparison surface, but the live Flutter iframe did not provide stable rendered pixels. Formal comparison remains blocked.

**Focused Region Comparison**

- The hero crop, headline block, Google CTA, privacy strip, and guest action were each inspected in the browser at full mobile scale.
- A persistent focused comparison image was not produced for the same capture limitation, so this cannot satisfy the blocking evidence requirement.

**Comparison History**

1. The first browser render at 390 × 844 showed that Korean fallback glyphs were too light relative to the selected source. Explicit Korean font fallbacks and weights were added; the revised browser render corrected the hierarchy.
2. The first final-state console check exposed an unrelated StoreKit channel error from purchase initialization on web. Purchase startup was limited to Android and iOS; the final browser reload had no warnings or errors.
3. The Google CTA was pressed in the browser. Its loading label and spinner appeared, the guest action disabled during the transition, and the app continued to the existing Sobra state after 650 ms.
4. The final same-input comparison export was blocked by the browser surface and security policy, so no pass can be issued.

**Primary Interactions Tested**

- Google CTA idle → loading state → existing app transition.
- Guest action disabled while Google login is loading.
- Browser console checked after the platform guard: no errors or warnings.
- Widget test verifies the Google login flow continues into onboarding for a new Korean-locale user.

**Implementation Checklist**

- [x] Selected option 3 translated into the Flutter app.
- [x] Existing Sobra tokens, square controls, and pixel-shadow interaction reused.
- [x] Korean, Spanish, and English login copy included.
- [x] Google and guest actions wired for prototype behavior.
- [x] Static analysis and targeted widget tests passed.
- [ ] Attach/export one browser screenshot and complete the required same-input comparison.

**Follow-up Polish**

- [P3] Replace the prototype transition with real Google OAuth and persisted account state when backend scope is approved.

final result: blocked

---

# Quick Entry Notification Design QA

**Findings**

- No actionable P0, P1, or P2 mismatches remain in the app-owned notification surface.
- Android 16 owns the outer notification card, lock-screen wallpaper, header, expansion affordance, and default collapsed/expanded behavior. Those expected system differences are not implementation defects.

**Evidence**

- Selected source visual: `/Users/jaewook/dev_app/sobra_app/design/quick-entry/sobra-lockscreen-retro-source.png`
- Secure lock-screen capture: `/Users/jaewook/dev_app/sobra_app/design/quick-entry/sobra-lockscreen-retro-implementation-final.png`
- Expanded secure-notification capture: `/Users/jaewook/dev_app/sobra_app/design/quick-entry/sobra-notification-retro-expanded-final.png`
- Full three-state comparison: `/Users/jaewook/dev_app/sobra_app/design/quick-entry/sobra-retro-comparison.png`
- Focused source-to-implementation comparison: `/Users/jaewook/dev_app/sobra_app/design/quick-entry/sobra-retro-focused-comparison.png`
- Source pixels: 852 × 1846.
- Implementation pixels: 1080 × 2160 on the Android 16 emulator.

**Required Fidelity Surfaces**

- Composition: the app-owned panel preserves the source's cat-first question row, horizontal divider, and balanced Income/Expense action row.
- Colors and visual language: cream paper, navy outline and copy, teal inner border, teal plus signs, and the selected pixel cat all match the chosen direction.
- Typography: the app uses Pixelify Sans where Android RemoteViews permits it. Android 16 renders notification text with its host typography for consistency and accessibility.
- Copy: Spanish and English labels are supplied by the app localization currently selected by the user.
- Accessibility: the cat has a content description; Income and Expense expose individual accessible names and full-width clickable targets.

**Full-view Comparison**

- The combined comparison places the selected source, the secure lock-screen result, and the expanded secure notification together at normalized height.
- The implemented notification is intentionally nested inside Android's native card. Its internal palette, content order, scale, border contrast, and action balance retain the source hierarchy.

**Focused Region Comparison**

- The focused comparison confirms the cream panel, double navy/teal outline, pixel-cat framing, divider, teal plus signs, navy labels, and 50/50 action split.
- The source's decorative notched corners and pixel action font are simplified by Android RemoteViews/SystemUI constraints; the resulting square retro panel remains visually coherent and has no readability or interaction regression.

**Comparison History**

1. The first custom layout used generic `View` separators, which Android 16 rejected during RemoteViews inflation. They were replaced with supported `ImageView` separators; the notification then rendered normally.
2. The first successful render duplicated Sobra's title and large icon inside Android's native header, narrowing and truncating the question. The duplicate title/large icon were removed and the internal spacing compacted.
3. The first retro action pass colored the entire label teal. The final pass uses teal only for the plus signs and navy for the action names, matching the selected source.
4. Final Android logs contain no notification inflation or RemoteViews rendering errors.

**Primary Interactions Tested**

- Secure lock screen shows the notification's public copy and does not open Sobra without unlock.
- Income action survives the lock/login gate and opens the income registration mode with the amount keyboard focused.
- Expense action opens the expense registration mode with the amount keyboard focused.
- Expanding the notification reveals both full-width actions without clipping.

**Implementation Checklist**

- [x] Selected option 2 translated into Android RemoteViews.
- [x] Existing Sobra pixel cat and Pixelify Sans resource reused.
- [x] Spanish and English copy supported.
- [x] Income and Expense actions wired and manually verified.
- [x] Secure lock-screen behavior verified with a temporary emulator PIN; the PIN was removed after testing.
- [x] Source and implementation compared together at full view and focused notification view.
- [x] Debug APK builds successfully and notification logs are clean.

**Follow-up Polish**

- [P3] Device makers can render custom notifications differently. A final spot-check on the target Samsung device is worthwhile before release, especially for expanded-by-default behavior and font substitution.

final result: passed

---

# Hybrid Room Flow Design QA

**Findings**

- No actionable P0, P1, or P2 differences remain for the agreed hybrid-room scope.
- [P3] The reference decorator shows a dense sample inventory in one category. The implementation deliberately exposes the real catalog by slot category, so the initial Furniture tab contains the owned lamp while rug, tabletop, and wall items live in their matching tabs. Add more catalog art later without changing the room compositor.
- [P3] The reference previews the selected lamp above its target. The implementation instead highlights the compatible target and renders the item in place after a tap; the instruction, selection border, undo action, and saved result keep the placement model explicit.

**Evidence**

- Source home: `/var/folders/1d/f_54vtrd34b966kbj7vfrncc0000gn/T/codex-clipboard-aa4228bd-37f8-430c-a34e-91a2e4fe8db0.png`
- Source room: `/var/folders/1d/f_54vtrd34b966kbj7vfrncc0000gn/T/codex-clipboard-102e4d70-9909-4d68-b5e3-df8d0973a863.png`
- Source decorator: `/var/folders/1d/f_54vtrd34b966kbj7vfrncc0000gn/T/codex-clipboard-d26de793-cb2c-4c4c-970d-a8804cc23f13.png`
- Implementation home: `/Users/jaewook/dev_app/sobra_app/design/rooms/sobra-home-room-hybrid-applied.png`
- Implementation room: `/Users/jaewook/dev_app/sobra_app/design/rooms/sobra-room-immersive-applied.png`
- Implementation decorator: `/Users/jaewook/dev_app/sobra_app/design/rooms/sobra-room-decorator-applied.png`
- Full-view comparisons: `/Users/jaewook/dev_app/sobra_app/design/qa/hybrid-room-home-side-by-side.png`, `/Users/jaewook/dev_app/sobra_app/design/qa/hybrid-room-immersive-side-by-side.png`, and `/Users/jaewook/dev_app/sobra_app/design/qa/hybrid-room-decorator-side-by-side.png`
- Focused decorator comparison: `/Users/jaewook/dev_app/sobra_app/design/qa/hybrid-room-decorator-focused-side-by-side.png`
- Live implementation: `http://127.0.0.1:4174/`
- Source pixels: 853 × 1844 at 2× reference density, normalized to 426 × 922.
- Implementation pixels: 426 × 919 at device scale factor 1. The three-pixel height difference is bottom padding only; width and visual scale are aligned.
- State: Korean browser interaction pass; Spanish deterministic comparison captures; level 1; Casa clara; default rug and tabletop plant; lamp selected for the empty floor-right slot.

**Required Fidelity Surfaces**

- Composition: the room now sits directly under the amount summary, the immersive route gives the room most of the screen, and the decorator preserves a large scene above a bottom inventory drawer.
- Hybrid layering: wall, floor, window, curtains, chair, shelf, and large plants stay in the fixed background. Rug, floor-right, wall, and tabletop slots render independently. Cat, speech, and reaction motion sit above both.
- Visual language: the existing cream, navy, teal, square borders, pixel shadows, Pixelify type, and Michi sprite are preserved across all three screens.
- Interaction and persistence: the whole home card opens the room; the cat reacts; owned items support item-first then compatible-slot placement; Undo restores the previous draft; Done persists the room through reload.
- Responsiveness and accessibility: the exact-aspect 426 × 919 captures show no clipping or overflow. Room entry, cat, slots, categories, items, back, undo, and done expose localized semantics.

**Full-view Comparison**

- The home comparison confirms the requested hierarchy: amount → room and cat → level/mission. Unlike a cropped teaser, the room art remains complete and the header clearly communicates entry and decoration.
- The immersive comparison confirms the room-first canvas, restrained top actions, tappable cat, and compact identity/action bar.
- The decorator comparison confirms the top save/undo controls, visible compatible slots, instructional strip, category drawer, owned state, and asset-based item preview.

**Focused Region Comparison**

- The room-and-slots crop confirms that fixed art remains visually complete while only the four semantic placement regions receive overlays. Occupied unselected slots have no outline; empty or selected slots remain discoverable only during editing.
- The cat and speech bubble remain independent foreground layers, so reaction motion and copy do not require regenerating a background.

**Comparison History**

1. The first decorator capture outlined every occupied slot, making the finished room look like an editor even before a target was selected. Occupied unselected outlines were removed.
2. The first portrait anchor put the tabletop plant too low and the wall slot across the chair. The tabletop anchor was moved onto the table and the wall target moved to open right-wall space.
3. The short decorator canvas initially clipped Michi's feet and the speech box lacked a directional tail. Michi was raised and the existing pixel speech-tail treatment was applied.
4. The final browser pass verified placement, undo, save, reload persistence, and zero console warnings/errors.

**Primary Interactions Tested**

- Home room card → immersive My Room.
- Michi tap → localized positive reaction and celebration motion.
- Decorate → owned lamp → floor-right slot.
- Undo → empty slot restored.
- Re-place → Done → immersive room with lamp.
- Browser reload → home preview retains the lamp.
- Existing Collection entry still opens and continues to own acquisition/equip states.

**Implementation Checklist**

- [x] Three-screen flow implemented.
- [x] Four semantic replaceable slots implemented.
- [x] Fixed background, replaceable decor, cat, speech, and effects separated.
- [x] Saved-state migration and per-room placement persistence implemented.
- [x] English, Spanish, and Korean labels included.
- [x] Future-theme production guide added.
- [x] Static analysis, room-flow tests, compact-width tests, deterministic visual captures, and browser interaction pass completed.

**Follow-up Polish**

- [P3] Add more transparent item assets to each existing slot category before making additional placement regions.

final result: passed
