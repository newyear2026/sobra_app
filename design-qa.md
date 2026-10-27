# Owned-companion Halloween gift list (selected option 2)

final result: passed

## Visual target and evidence

- Selected reference: `design/seasonal/2026-halloween-dia-de-muertos/owned-gift-ui-concepts-v1/02-owned-costume-list.png` (977 x 1610).
- Current native capture: `design/seasonal/2026-halloween-dia-de-muertos/implementation/05-owned-gift-list-reference.png` (780 x 1288).
- Final shared comparison: `design/seasonal/2026-halloween-dia-de-muertos/owned-gift-ui-implementation/comparison-v3.png`.
- Enlarged row/action comparison: `design/seasonal/2026-halloween-dia-de-muertos/owned-gift-ui-implementation/rows-and-action-comparison.png`.
- State: Korean, unclaimed gift, owned Michi and Poodle/Miru only, no costumes selected, reduced motion.
- Viewport: 390 x 644 logical pixels, capture density 2. The generated reference has an effective density of 977/390 and an implied height of 643 logical pixels. It was proportionally normalized, never stretched, to compare the content at the same width.
- This is production Flutter work. Captures come from the real widget tree and bundled character assets, not a web recreation. Core interactions run in Flutter widget tests.
- The earlier room-stage QA report is preserved at `design/seasonal/2026-halloween-dia-de-muertos/owned-gift-ui-implementation/prior-design-qa.md`.

## Findings and iteration history

1. [P2, resolved] The first capture's primary button and permanent-ownership footer extended below the initial viewport. Explicit line heights improved v2, but the footer still required scrolling. V3 reduces unused header/row/section spacing; the action and complete footer are visible. A widget assertion guards the footer's bottom edge at 390 x 644.
2. [P2, resolved] Initial type hierarchy was smaller and looser than the reference, especially the Korean gift title and row costume names. The final layout increases gift/section headings and costume sizes and removes inherited body-line padding. V3 was reviewed beside the source, including the enlarged row/action detail.
3. [P3, accepted] Gift icons use the app's existing Material icon rather than the generated decorative present artwork. Production costume atlases, PixelifySans/SobraHangul, and canonical names Michi/Miru are retained. These differences preserve the actual product's assets and naming.

No unresolved P0, P1 or P2 visual findings remain. The final two-image comparison was inspected directly; this pass is not based solely on test results.

## Fidelity surfaces

- Fonts and typography: production PixelifySans and regular/bold SobraHangul fonts; final heading, outfit and helper hierarchy visually verified.
- Spacing and layout: two owned-friend rows with separators, a permanent-storage explanation, one teal claim action, and a complete footer. All fit in the reference-sized viewport; longer lists and enlarged text scroll naturally.
- Colors and tokens: use existing AppColors paperLight/ink/teal/cashInk/line values.
- Asset quality: use real costume atlases through CharacterSprite. Keep the existing Material gift icon and proper companion names, rather than the generated mock's illustrative gift and breed labels.
- Copy and content: owned previews are personalized; all 12 costumes remain free and permanently stored. Translations cover all seven locales.

## Verification

- Final functional pass: 55 targeted costume, ownership, release-note and gift-flow tests passed.
- Ownership fixtures cover one friend, two friends and all twelve friends, including 320 x 568 at text scale 1.6 in all seven locales.
- Full regression suite: 938 passed; 3 time-zone-specific cases skipped in the default zone were covered by a separate America/Chicago run (4 passed).
- Application and test static analysis: no issues found.
- No browser prototype was created: this request updates the existing native Flutter implementation. Device purchase, ad delivery and physical-device checks are outside this visual QA.

- Signed Android release bundle built and inspected: 1.0.16+26, 72 costume textures and layout match the workspace. Detailed results: `output/validation/owned-gift-ui-2026-10-27/report.json`.
