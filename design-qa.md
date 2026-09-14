# Collection Design QA

**Findings**

- No actionable P0, P1, or P2 differences remain for the agreed prototype scope.
- [P3] Final catalog artwork is intentionally deferred. The source mockup uses named character and room-item illustrations, while the implementation uses Michi's real sprite plus Material icon placeholders for undecided entries. This preserves the requested acquisition states and layout without prematurely fixing the lineup. Replace `CatalogVisual` placeholder rendering when the catalog art direction is approved.
- [P3] The reference shows illustrative level 4 content and four owned items. The implementation correctly renders the current saved player state (level 1, one owned item), so counts and level labels are expected to differ.

**Open Questions**

- Final character and item names, artwork, unlock levels, rewarded-ad targets, and store product IDs remain intentionally open.
- Real purchase and rewarded-ad providers are not connected in this prototype. Their buttons show an explanatory preview notice.

**Evidence**

- Source visual truth: `/Users/jaewook/dev_app/sobra_app/design/qa/collection-source-mockup.png`
- Browser-rendered implementation: `/Users/jaewook/dev_app/sobra_app/design/qa/collection-implementation.jpg`
- Combined comparison: `/Users/jaewook/dev_app/sobra_app/design/qa/collection-side-by-side.jpg`
- Comparison surface: `/Users/jaewook/dev_app/sobra_app/design/qa/collection-compare.html`
- Live implementation: `http://127.0.0.1:4173/`
- Source pixels: 1270 × 1239 at 1×. The selected right-hand item screen was cropped and normalized to 423 × 900 CSS pixels in the comparison surface.
- Implementation capture: 931 × 879 browser-rendered pixels at device scale factor 1. In the combined comparison, the Flutter app used a 520 × 960 CSS viewport scaled uniformly to 488 × 900 for height-aligned inspection.
- State: Spanish locale, item tab, level 1, one owned item; a separate focused interaction capture verified the item detail dialog and the transition from `OBTENIDO` to `EQUIPADO`.

**Required Fidelity Surfaces**

- Fonts and typography: Pixelify Sans is loaded in the running Flutter app and preserves the mockup's pixel-display hierarchy. Labels remain legible without truncation at 360 px phone width.
- Spacing and layout rhythm: 20 px page margins, a two-column grid, 10 px gutters, square card borders, compact status bars, and the header-to-tabs rhythm match the reference structure. The settings-pushed route adds a back control without crowding the title.
- Colors and visual tokens: the existing Sobra navy, cream, teal, cash, violet, and blue tokens consistently express selected, purchase, rewarded-ad, owned, and level-locked states.
- Image quality and asset fidelity: Michi and the room header use existing production raster assets with correct cropping. All undecided catalog entries use a consistent icon placeholder treatment by explicit scope decision; no fake final character art was introduced.
- Copy and content: Spanish, English, and Korean strings are localized. Price text is supplied by a price-source boundary and is not stored on static catalog entries.
- Responsiveness and accessibility: the screen was checked at 520 × 960 and 360 × 720. Tabs, cards, back navigation, details, and equip actions expose semantic button labels; no collection overflow was reported by the compact widget test.

**Full-view Comparison**

- The combined image shows the source item screen and the final Flutter item screen in one browser-rendered comparison surface. Major hierarchy, tabs, count/hint panels, two-column catalog, status colors, borders, and card density align with the mockup.

**Focused Region Comparison**

- The header, tabs, first two card rows, and their owned/ad/level-lock states are readable in the combined comparison. The dialog was inspected separately at full browser resolution because it is not present in the source mockup; its title, acquisition explanation, close/cancel controls, and equip action were all verified.

**Comparison History**

1. Pass 1 found a P2 hierarchy gap: the first implementation header lacked the mockup's room context and felt visually empty. The existing Casa clara room asset was added to the header and the XP strip was tightened.
2. Pass 2 compared the revised item state side by side. No P0/P1/P2 issue remained.
3. Final pass repeated the side-by-side comparison after moving entry from a sixth bottom-navigation tab to the existing `Mi Sobra` settings screen. The collection gained a back control, existing five-tab layouts remained intact, and no new P0/P1/P2 issue appeared.

**Primary Interactions Tested**

- `Mi Sobra` → `Colección` navigation and back affordance.
- `PERSONAJES / OBJETOS` switching.
- Character purchase, rewarded-ad, and owned/equipped states.
- Item level-lock, rewarded-ad, owned, detail-dialog, and equip transitions.
- Browser console checked during the implementation pass: no errors were present.

**Implementation Checklist**

- [x] Common static catalog model and separate user state.
- [x] Ten provisional character slots and ten provisional item slots.
- [x] Localized price-source boundary instead of prices on catalog entries.
- [x] Settings entry, two-column collection, details, and functional preview actions.
- [x] 360 px responsive test, static analysis, targeted tests, and browser inspection.
- [ ] Replace placeholder visuals and connect persistence/store/ad services in later phases.

final result: passed

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
