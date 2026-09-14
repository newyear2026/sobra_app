# Sobra hybrid room theme guide

Every room is a finished pixel-art space, but it must leave the same small set
of places open for personalisation. A room theme is therefore delivered as a
fixed background plus transparent decoration layers, never as one flattened
image containing the cat or every replaceable item.

## Fixed in the background

- Wall, floor, windows and curtains
- Architecture and lighting that define the room
- A small number of identity-defining furnishings
- Background plants or shelves that are not offered as replaceable items

The fixed layer must not contain the cat, speech bubbles, reactions, the rug,
the floor-right item, the wall-centre item or the tabletop item.

## Replaceable slots

Every theme supports these semantic slots, even when their coordinates differ:

| Slot | Intended content | Casa clara default |
| --- | --- | --- |
| `rug` | Rugs and floor textiles | Lavender rug |
| `floorRight` | Lamps, beds and freestanding objects | Empty |
| `wallCenter` | Pictures and small wall objects | Empty |
| `tabletop` | Plants and small tabletop objects | Potted plant |

An item belongs to exactly one slot. Room-specific coordinates live in the
scene layout; saved user data stores only the room id, slot and item id.

## Required assets for a new theme

1. A 2:1 landscape preview used on Home.
2. A 2:3 portrait background used in My Room and Decorate.
3. Transparent PNGs for every included replaceable decoration.
4. A small room thumbnail for the room picker when more themes are added.

Both backgrounds must show the same fixed furniture and palette. Keep the
centre floor clear for the character, preserve quiet wall space for speech,
and avoid placing fixed art inside the four replaceable slots.

## Layer order

1. Fixed room background
2. Rug
3. Wall, tabletop and floor-right decorations
4. Character
5. Speech bubble and reaction effects
6. Editing targets, shown only in Decorate mode

## Acceptance checklist

- The preview and portrait views unmistakably depict the same room.
- Removing every replaceable layer still leaves a complete-looking room.
- No fixed object overlaps a replaceable slot.
- The character remains readable over every rug and floor treatment.
- Every item has a transparent edge with no baked-in room background.
- Changing themes preserves each theme's last saved arrangement.
- Text, UI controls and reactions are never painted into room artwork.
