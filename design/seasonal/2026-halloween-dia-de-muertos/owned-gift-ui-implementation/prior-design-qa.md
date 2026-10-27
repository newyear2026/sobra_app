# Shared room stage and square Home card

final result: passed

## Visual target and evidence

- Selected target: `design/rooms/shared-stage-target.png` (the third displayed image, 854 × 1842 pixels).
- Flutter Home capture: `design/rooms/shared-stage-home.png` (426 × 919 pixels).
- Flutter Decorate capture: `design/rooms/shared-stage-decorate.png` (426 × 919 pixels).
- Full comparison: `design/qa/shared-stage-comparison.html`, opened and visually reviewed in the in-app browser. It places all three images together at 426 logical pixels wide, preserving their aspect ratios. The target consequently renders at about 426 × 919 pixels; Flutter captures use device pixel ratio 1.
- State: Spanish, Casa clara, Miru, ivory sofa, launch TV, floor lamp, sill plant and default rug; budget $857.14 remaining today, reduced motion enabled. The fixtures use the same date and budget as the visual reference. User data and saved furniture were not changed.
- Full-size room and lighting references were also rendered in the existing room visual tests. All six themes are covered by geometry tests across square, short and tall areas.

This is an update to the existing native Flutter application, not a new web prototype. The browser comparison contains actual Flutter-rendered screenshots. Native navigation, saving, placement and animation are verified by Flutter widget tests. The full comparison retains readable 426-pixel-wide screens, and the room regions were also inspected directly at native resolution; a separate enlarged crop was not needed.

## Comparison history

1. Initial native capture: the enlarged Home image covered the card's side/bottom border, while some Decorate drawer images had not finished loading in the visual fixture. Added a foreground border to the Home viewport and explicitly precached the visible drawer providers before capturing.
2. Post-fix captures: a complete square border surrounds the room, all drawer artwork is present, and the level/mission block follows the room above the fixed bottom navigation. Compared the final target, Home and Decorate together in the browser. No actionable P0/P1/P2 findings remain.

## Fidelity review

- **Fonts and typography:** retained the app's PixelifySans and language fallbacks, existing amount hierarchy, labels and navigation sizes. Text remains live and localized.
- **Spacing and layout:** Home's scene is 1:1 with the original header and section gaps. Budget remains above the room; level/missions remain below; lower content scrolls. Short room areas contain the complete scene, and tall areas reveal more of the portrait instead of repositioning furniture.
- **Colors and tokens:** existing cream, indigo and teal tokens and square borders are retained. No new palette, corner radius or elevation system.
- **Image quality and fidelity:** existing portrait backgrounds, transparent furniture sprites and animated characters are reused. TV, lamp and sofa remain behind the character and rug. Relative coordinates, sizes and paint order match across the five tested viewport shapes, with three furniture arrangements in every theme.
- **Copy and content:** existing app copy is retained. The source mock incorrectly says “Michi curioso” under Miru; the implementation correctly resolves “Miru curioso” from the equipped character. The fixture's poses and exact sprite pixels differ from the generated mock because the production animation assets are retained.

## Verification

- `flutter test --no-pub`: **779 passed, 3 skipped**. Updated only visual baselines affected by the shared renderer and Home height change.
- Added strict stage-normalized position, size and paint-order assertions for every placed item and the character. Former foreground-item exceptions were removed.
- Checked opaque furniture bounds, rug/paw contact, room navigation, slot selection, saving, undo, per-room placements and time-of-day lighting.
- Static analysis of all 12 changed Dart files: **no issues**.
- Whole-repository analysis still reports 18 pre-existing lint/warning entries in the two unrelated `tool/render_promo_video*_test.dart` scripts.
- `git diff --check`: passed.

## Accepted differences and follow-up polish

- Preserve the app's existing font metrics and real assets instead of tracing the generated mock's typography, poses or speech-bubble artwork.
- Outside the square-to-portrait aspect range, the room is centered with surrounding app surface visible. This deliberately preserves the full arrangement on short or very tall viewports.
- No physical-device or release-build validation was performed in this pass.

## Implementation checklist

- [x] Square Home room with visible perimeter border.
- [x] One portrait background, coordinate map and furniture scale for every surface.
- [x] Fixed stage anchors for character, pet bed and rug.
- [x] Viewport-independent furniture bounds and matching placement targets.
- [x] Refresh preload, geometry tests, visual baselines and room documentation.
- [x] Review actual Home and Decorate captures against the selected target.
