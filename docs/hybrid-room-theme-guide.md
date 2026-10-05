# Sobra hybrid room theme guide

A room is an empty, finished pixel-art stage — walls, floor, window, light —
that the user furnishes with items they earn. Every room shares the same floor
and character geometry, so one item sprite fits every room. Window geometry
may differ, and the room itself never contains the character or anything the
user can place.

Status: surfaces, slots, and six selectable themes are live. Casa jardín,
Casa de playa, Casa torre, Casa montaña, and Casa invernadero use empty
backgrounds with a separate default rug. Every room, Casa clara included,
starts with only the rug. The table plant is withheld for now
(`RoomDecorAssets.withheldIds`): not offered, not saveable, and hidden where an
older save placed it, so it can come back later as a reward. The last three
rooms have wide windows, so they offer floor and furniture-supported tabletop
slots but no wall slots. A placed cabinet or side table supplies its own
tabletop slot.

## The shared stage

Every room is drawn on the same stage. Only materials, the view outside the
window and the room's own identity pieces change between rooms.

| Stage line | Portrait (1024×1536) | Notes |
| --- | --- | --- |
| Top of baseboard | y = 750 | Wall ends here |
| Floor starts | y = 782 | Floor items stand below this line |
| Window with curtains | x 352–748, y 108–530 | First three rooms; Casa torre, Casa montaña, and Casa invernadero use wider windows |
| Character | x 358–666, y 815–1161 | Keep the floor clear here |
| Light | from the upper left | First three rooms use separate diagonal beams; the three scenic rooms use daylight painted into their backgrounds |

`design/rooms/generation/room-stage-guide.png` draws these lines over the
empty Casa clara reference. Check the floor and character space in every new
background against it; window shape may change.

Mi casa shows the portrait's full height and crops its sides, to about
x 63–961 on a common phone. Decorate is wide and short, so it crops top and
bottom instead. Its floor focus shifts with the viewport height to leave
enough floor for foreground seats and the character.

Floor contact and viewport fitting use each sprite's opaque outline rather
than its transparent canvas. Secondary chairs, poufs and side tables move
forward when a sofa or cabinet occupies the back row. Bookcases leave space
for a lamp beside them. The rug follows the character's paws, and the pet bed
sits to their left. Short views may pull foreground items back into view;
tabletop props and placement previews follow the resulting furniture frame.

The ivory sofa and bronze lantern lamp are separate transparent sprites,
available as included furniture in every room. The sofa uses `floorSofa`;
the lantern uses either `floorLeft` or `floorRight`. Its night light follows
the hanging shade to the right of the stem. Art prompts and opaque bounds
are recorded in `design/rooms/furniture-concepts/casa-torre-asset-generation.json`.

**Scale.** The stage is about 300 px to the metre at the wall: Casa clara's
painted armchair, some 85 cm tall, is 250 px. Size items to it — a chair
about 255 px, a floor lamp about 430 px, a wall clock about 100 px across.

## Fixed in the background

- Wall, floor, baseboard, window, curtains and their rod
- Lighting that defines the room
- Identity pieces that are not furniture: a garland, a tiled wall band

Not in the background: the character, speech, reactions, and anything that is
furniture — chairs, tables, plants, pictures, shelves, rugs. *(Planned: Casa
clara's armchair, side table, plants, picture and shelf are still painted in
and become items when its empty background lands.)*

## Surfaces and slots

An item names the surfaces it can go on. A room names its places (slots), each
on one surface. In Decorate, choosing an item lights only the slots of its
surfaces, each with a faint preview of the item.

| Surface | Holds | Anchored at |
| --- | --- | --- |
| `wall` | Pictures, clocks, wall objects | Slot centre |
| `floor` | Freestanding furniture, floor plants | Slot bottom centre |
| `tabletop` | Lamps, small plants, ornaments | Slot bottom centre |
| `rug` | Rugs and floor textiles | Fills its slot, under the character |

- An item may allow several surfaces. The small plant goes on the floor or on
  a table; the desk lamp only on a table, because a desk lamp on the floor is
  what started this.
- The included rattan chair and floor lamp use floor slots; the included wall
  clock needs a wall slot and therefore does not appear in Casa torre,
  Casa montaña, or Casa invernadero.
- Within one room an item is in one place at a time; placing it elsewhere
  moves it, and tapping its own place takes it out.
- Across rooms an item is independent: the same picture can hang in every
  room the user owns.
- Items are drawn at their own size on the stage, not stretched to the slot,
  so a small plant stays small on a floor slot sized for an armchair.
- In the empty rooms, furniture stands at the wall (feet at y 840) and wall
  slots hang at about 1.5 m (centre y 335), clear of a floor lamp's shade.
  Casa clara still places furniture mid-floor, in front of what is painted
  in; its rects move to the wall when its empty background lands.

Saved data stores only the room id, slot name and item id. Slot names never
change once shipped (`rug`, `floorRight`, `wallCenter` and `tabletop` predate
surfaces). A slot the user emptied is stored as cleared so the room's default
does not come back.

Slot positions are fractions of the background image, so an item stays on its
patch of wall however the screen crops the room. The rug is the exception: it
is the character's mat and follows the character.

## Host furniture *(planned)*

A table or shelf is an item that brings its own places.

- A tabletop place exists only while a table stands in the room, and sits on
  the table's top edge wherever the table stands.
- Moving the table carries what is on it.
- Removing the table sends what was on it back to the drawer. Undo restores
  both.
- With no table, a tabletop-only item lights no place and the hint asks for a
  table first.
- Saving refuses, and loading repairs, anything on a table that is not there.
- Start with one table per room; shelves reuse the same rule later.

## Rooms and unlocking

- Rooms are catalog entries (`CatalogPreviewData.rooms`, kind `room`) with a
  tab of their own in the collection. Casa clara, Casa jardín and Casa de
  playa are included. Casa montaña and Casa invernadero unlock for good after
  two rewarded ads each. Casa torre is a non-consumable, `sobra.room.torre`,
  at **MX$19 in Mexico**; the price shown comes from the store.
- Decorate → Room lists only owned rooms, then a tile that opens the
  collection on its rooms tab. A locked room left equipped opens as Casa
  clara, and a refunded Casa torre falls back the same way.
- Installs that finished onboarding while all six were free keep all six
  through the `keepsEveryRoom` flag, never as owned ids: the launch
  revocation would take a free Casa torre back as a refund. A backup carries
  the two ad rooms over; Casa torre stays with the install that has it.
- Items, as of launch: the rattan chair and wall clock are included. Levels
  give one piece each, in the order a room fills: floor lamp at 2, savings jar
  at 3, low cabinet at 4, pet bed at 5, round side table at 6, terracotta pouf
  at 7, blue and cream rug at 8, slim bookcase at 9, ivory sofa at 10. One
  rewarded ad gives the desk lamp, the frame, the bronze lantern lamp or the
  wall shelf. Items are never sold on their own.
- Installs that finished onboarding while every drawn decoration was free keep
  those pieces (`CatalogPreviewData.formerlyFreeItemIds`); the save marks
  `decorRewards` once that and the room flag above have been applied.
- A placed item the user does not own is left out of the room, and the room's
  default takes its slot back. The placement stays saved for when it is
  theirs again.
- Level rewards are derived from the current level, never stored. Moving an
  existing reward to a *higher* level takes it away from people already past
  the old one, so rewards only move down or are added alongside.

## Starting out *(planned)*

- New users: an empty Casa clara with a rug.
- Existing users: a one-time migration grants the furniture that used to be
  painted into Casa clara and places it where it was drawn, so the room looks
  the same after the update. A lamp saved on the floor already moves to the
  table on load.

## Required assets for a new room

1. A 2:3 portrait background, 1024×1536, empty, on the shared stage.
2. A landscape preview for Home, the same room, empty. The Home card is 2:1;
   a 3:2 source is center-cropped by the app.
3. Transparent PNGs for any furniture the room introduces, with no baked-in
   floor and their own soft shadow, cropped to the object with a couple of
   pixels to spare. A wide transparent margin under an item makes it float
   above the floor line by that margin.

Generating with ChatGPT: attach the empty reference
(`design/rooms/generation/casa-clara-empty-reference.png`) and ask for an
edit that keeps the window, baseboard, floor line and light identical and
changes only materials and the view. Never attach the stage guide itself; the
lines get painted in.

## Adding a room in code

1. Add a `RoomTheme` in `lib/models/room_design.dart`: id, both assets and
   their pixel sizes, the slots it offers, and default placements.
2. Add its layout in `lib/widgets/room_scene.dart`. On the shared stage an
   empty room reuses the empty-theme rects as they are.
3. Add its name to all seven ARB files and regenerate localization code.

## Layer order

1. Room background
2. Rug
3. Wall, tabletop and floor decorations, lower on screen drawn in front
4. Character
5. Speech bubble and reaction effects
6. Placement targets, shown only in Decorate while an item is chosen

## Acceptance checklist

- The stage lines match the guide within a few pixels.
- The preview and portrait views unmistakably depict the same room.
- The empty room still looks finished, just unfurnished.
- The character remains readable over every rug and floor treatment.
- Every item has a transparent edge with no baked-in room background.
- Every item looks right on every surface it allows, in every room.
- Changing rooms preserves each room's last saved arrangement.
- Text, UI controls and reactions are never painted into room artwork.
