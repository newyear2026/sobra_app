# Sobra hybrid room theme guide

A room is an empty, finished pixel-art stage — walls, floor, window, light —
that the user furnishes with items they earn. Every room shares the same
stage geometry, so one item sprite fits every room, and the room itself never
contains the character or anything the user can place.

Status: surfaces, slots, and three selectable themes are live. Casa jardín
and Casa de playa use empty backgrounds with a separate default rug and floor
plant. Host furniture, the empty Casa clara background, and furniture as
items remain planned below.

## The shared stage

Every room is drawn on the same stage. Only materials, the view outside the
window and the room's own identity pieces change between rooms.

| Stage line | Portrait (1024×1536) | Notes |
| --- | --- | --- |
| Top of baseboard | y = 750 | Wall ends here |
| Floor starts | y = 782 | Floor items stand below this line |
| Window with curtains | x 352–748, y 108–530 | Same opening in every room |
| Character | x 358–666, y 815–1161 | Keep the floor clear here |
| Light | from the upper left | Diagonal beams across wall and floor |

`design/rooms/generation/room-stage-guide.png` draws these lines over the
empty Casa clara reference. Check every new background against it; a few
pixels of drift are fine.

Mi casa shows the portrait's full height and crops its sides, to about
x 63–961 on a common phone. Decorate is wide and short, so it crops top and
bottom instead, holding the floor line two thirds of the way down: roughly
y 260–1050. Keep what matters inside both bands.

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
  clock uses a wall slot. Their shared transparent sprites work in all themes.
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

- Casa clara, Casa jardín and Casa de playa are selectable in Decorate → Room.
  Switching keeps each room's saved arrangement. All three are currently
  included; they are not catalog purchases or level rewards.
- Planned: rooms become catalog entries, owned and unlocked like characters
  and items. Casa jardín would unlock at level 3 and Casa de playa at level 5.
  Each would share its level with the item reward already there.
- Level rewards are derived from the current level, never stored. Moving an
  existing reward to a *higher* level takes it away from people already past
  the old one, so rewards only move down or are added alongside.

## Starting out *(planned)*

- New users: an empty Casa clara with a rug and a small plant on the floor.
- Existing users: a one-time migration grants the furniture that used to be
  painted into Casa clara and places it where it was drawn, so the room looks
  the same after the update. A lamp saved on the floor already moves to the
  table on load.

## Required assets for a new room

1. A 2:3 portrait background, 1024×1536, empty, on the shared stage.
2. A landscape preview for Home, the same room, empty. The Home card is 2:1;
   a 3:2 source is center-cropped by the app.
3. A small thumbnail for the room picker.
4. Transparent PNGs for any furniture the room introduces, with no baked-in
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
3. Add its name to the three ARB files.

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
