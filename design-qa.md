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
