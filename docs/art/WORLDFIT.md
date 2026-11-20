# WORLDFIT - WHAT THE GAME BUILD CAN WIRE, AND THE NUMBER THAT PLACES IT
20 Nov 2026, 07:5x-08:2x CT. Art lane. Instrument: `tools/art/worldfit.py`.
Manifest: `renders/art/worldfit/_manifest.json`. Picture:
`renders/art/worldfit/_base_offsets.png` (+ `_base_offsets.json`).

## THE ROW
Mr. E, 07:24 CT: wire an ENTIRE PACK DIRECTORY per cycle, 10-20 assets, and
Tier 1 is the world-placed systems - town buildings (15), dungeon props (47),
nature (68). Art's job on a pack it did not model is not to re-model it. It is
to hand the game build the numbers that decide placement, and to name the files
that cannot be placed as they stand.

## MEASURED: 173 FILES, 0 UNREADABLE
Bounds off the EVALUATED depsgraph, metres, floorgeom read from the SHIPPING
tree and stamped (`floorgeom AGREES WITH origin/main: tree C:\hd adventure\jests-hd-medieval-adventure (branch laptop) scripts/floorgen.gd sha bc3a603f vs 4cf65e30d70edd7cda3c9e91c09b9e6e8d4297c4 sha bc3a603f`): cell 4.0 m, corridor clear 11.0 m, lid
underside 9.5 m, drift none.

| directory | scope | files | tallest | widest | ROOM-LOCKED | THROUGH-LID |
|---|---|---|---|---|---|---|
| `assets/props` | dungeon | 94 | 2.6318 m | 3.0205 m | **0** | **0** |
| `assets/dungeon` | dungeon | 20 | 5.8548 m | 4.1044 m | **0** | **0** |
| `assets/nature` | world | 42 | 18.9492 m | 13.5158 m | 3 (FYI) | 10 (FYI) |
| `assets/buildings` | world | 12 | 22.4109 m | 21.952 m | 6 (FYI) | 10 (FYI) |
| `assets/mkprops` | world | 5 | 7.3608 m | 5.6505 m | 0 (FYI) | 0 (FYI) |

**ALL 114 DUNGEON-PLACED MODELS CLEAR BOTH TERMS.** The whole of `assets/props`
and `assets/dungeon` can be batch-wired as dungeon props with no size gating at
all - the tallest thing in either is 2.6318 m under a 9.5 m lid.

A corridor verdict on a town tree would be a misleading number, so the tool
takes `--dungeon-dir`: everything else gets the same two terms marked
INFORMATIONAL (`wider_than_a_corridor_FYI`). An 18.9 m DeadTree is not
ROOM-LOCKED; it is a tree, and it lives outdoors. If nature or buildings are
ever placed underground, those lists become binding and are already measured.

## THE PLACEMENT NUMBER: `base_dz_m`
How far a model reaches BELOW ITS OWN PIVOT. Put the pivot at floor level and
that much goes through the floor. 18 of `assets/props`, 4 of
`assets/dungeon` and 30 of `assets/nature` are past the 5 cm line.

Worst, and the picture shows all four through one camera with a 1.80 m bar:

- **`Banner_1_Cloth.gltf` -2.2464 m** - the pivot is the banner's WALL MOUNT, so
  the entire cloth hangs below it. Spawned at floor level the whole banner is
  under the floor and the player sees nothing. Its top is at exactly 0.000 m.
- **`Fence_Straight_Modular.glb` -0.9991 m** - a post meant to be sunk; placed
  at floor level only a 0.29 m stub shows.
- **`Workbench_Drawers.gltf` +0.8842 m** - floats, correctly: it is a wall-hung
  drawer unit, not a floor piece. A positive `base_dz_m` is a WALL-MOUNT TELL.
- **`Barrel.gltf` +0.0034 m** - the control. Pivot at the base, sits on the slab.

So `base_dz_m` is not a defect list. It is the offset a spawner must apply, and
its SIGN says what the piece is for: strongly negative = hangs from above or is
sunk; strongly positive = wall-mounted; near zero = stands on the floor.

## TWO FAULTS IN THIS INSTRUMENT, FOUND AND FIXED IN THE SAME RUN
Both were caught because the number and the thing disagreed.

1. **The unit flag cried wolf on a FLAT object.** It read `dz < 1 cm` and called
   `Table_Fork.gltf` (0.0505 x 0.2626 x 0.0062 m) a cm/m mix-up. That is a
   correctly authored 26 cm fork lying flat. A unit mix-up shrinks ALL THREE
   axes, so only the LARGEST dimension can carry the test. After the fix: **0
   unit-flagged files in 173** - the first run's two flags were both false.
2. **The border arm read the floor, not the props.** `border_hot_frac` came back
   **1.0** on a perfectly good sheet, because the floor slab is MEANT to run off
   both edges of a side view. "Is anything bright at the edge" is not the
   viewer's question; "is a PROP cut by the frame" is. The props are now
   re-rendered ALONE on transparent and the border is read off that alpha:
   props_border_frac 0.0, props_opaque_frac 0.068, and the arm goes red on an
   empty mask rather than calling an invisible sheet clean.

The base-offset threshold moved with the same logic: at 1 cm it listed
Pedestal2's 15 mm of modelling noise beside the banner's 2.25 m. At 5 cm the
lists are 18/4/30 instead of 32/12/38, and every entry is a
placement instruction.

## WHAT I CAN SEE WRONG IN THE PICTURE, HONESTLY
- The floor slab is edge-on and 0.12 m thick, so it reads as a pale LINE rather
  than a floor. The verdict is legible but the sheet would be clearer with a
  thicker slab or a shallow camera tilt.
- **Nothing is labelled.** Four props and a bar, and you have to read the JSON to
  know which is which. The next version should caption them.
- The workbench reads as "floating art" until you know it is wall-hung. The
  sheet shows no wall.

## FOR THE GAME BUILD LANE (I do not wire it)
- Wire `assets/props` (94) and `assets/dungeon` (20) as dungeon props. No size
  gate is needed: 0 ROOM-LOCKED, 0 THROUGH-LID, measured.
- When placing, subtract `base_dz_m` from the spawn height, or anchor on the
  model's measured minimum rather than its pivot. The 18+4 files past
  5 cm are listed per directory in `_manifest.json` under `needs_base_offset`,
  each with a `base_note` saying sinks/floats/pivot-at-the-base.
- `needs_centring` is there for cell placement: it says the footprint centre is
  off the pivot in x/y, so a prop centred by pivot sits off-centre in its cell.
