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

## THE PLACEMENT NUMBER: `base_dz_m` - AND IT IS SIGNED
**CORRECTED 20 Nov 08:4x CT. The sentence that stood here was wrong and the team
lead caught it at 07:58.** It read "how far a model reaches BELOW its own pivot"
and then counted a list built with `abs(base_dz_m) > 0.05`, so files that reach
*above* their pivot were published inside a count the prose called sinkers. Of
the 22 named in `assets/props` + `assets/dungeon`, **20 sink and 2 float**
(`Lantern_Wall.gltf` +0.0818, `Workbench_Drawers.gltf` +0.8842); in
`assets/nature` 29 sink and **1 floats** (`Plant_7.gltf` +0.0791). Across all
173 files under `assets/`: **50 sink, 3 float, 120 flush.** The numbers in the
manifest were right the whole time; the prose over them was not.

`base_dz_m` is the SIGNED distance from the pivot to the lowest vertex.
**NEGATIVE** means the mesh reaches below the pivot and that much goes through
the floor when a spawner puts the pivot at y=0. **POSITIVE** means it floats
that far above the pivot, which is a wall-mount or modular-origin tell, not a
fault. **A single-sign shift over the abs() list fixes every sinker and buries
every floater**, which is why the manifest now publishes two SIGNED lists -
`sinks_below_pivot` and `floats_above_pivot` - plus `n_sink` / `n_float` and a
per-row `base_dir` of `sink` / `float` / `flush`. `needs_base_offset` is kept
because the game build already reads it, and it still mixes the signs; act on
the signed lists.

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

---

# PASS 2 - THE PACKS, 20 NOV 2026 08:3x-09:0x CT
Manifest: `renders/art/worldfit/_packs_manifest.json` (SEPARATE from
`_manifest.json`, which the game build is reading for System 47's 114-model
batch row - that file is untouched). Picture:
`renders/art/worldfit/_pack_base_offsets.png` (+ `_pack_base_offsets.json`).
Instrument: `tools/art/worldfit.py` with `label=ABSOLUTE\PATH` dirs and
`--recurse`; sheet: `tools/art/_worldfit_packshot.py`.

## THE ROW
Team lead, 07:58 CT: worldfit had measured five directories under `assets/`,
but Systems 15 (town buildings) and 68 (nature) are Tier 1 and their models are
**still in the extracted packs, not in `assets/`**. Point the same instrument at
the rest of them, same two terms, same stamp, same `base_dz_m`, and carry the
SIGN into the table.

## MEASURED: 669 FILES, 0 UNREADABLE, 0 UNIT-FLAGGED
floorgeom read from the SHIPPING tree and stamped: **AGREES WITH origin/main**
(`scripts/floorgen.gd` sha `bc3a603f` on both sides, ref `2c0b1b9b`), cell 4.0 m,
corridor clear 11.0 m, lid underside 9.5 m, drift `[]`.

| directory | system | scope | files | tallest | widest | cells | over-corridor | over-lid |
|---|---|---|---|---|---|---|---|---|
| KayKit Dungeon Pack `Models/gltf` | 47 | **dungeon (binding)** | 185 | 5.1 m | 6.05 m | ≤2 | **0** | **0** |
| Medieval Village MegaKit `glTF` | 15 | world | 176 | 7.3608 m | 15.7059 m | ≤4 | 6 (FYI) | 0 |
| Kenney Fantasy Town Kit `GLB format` | 15 | world | 167 | 3.1132 m | 3.1132 m | 1 | 0 (FYI) | 0 |
| KayKit Forest Nature `Assets/gltf` | 68 | world | 105 | 10.774 m | 6.6913 m | ≤2 | 0 (FYI) | 1 (FYI) |
| Ultimate Stylized Nature `glTF` | 68 | world | 36 | 7.5705 m | 8.9796 m | ≤3 | 0 (FYI) | 0 (FYI) |

## THE HEADLINE: ALL 185 KAYKIT DUNGEON MODELS CLEAR BOTH TERMS
**0 ROOM-LOCKED, 0 THROUGH-LID, measured, not assumed.** The tallest thing in
the pack is 5.1 m under a 9.5 m lid and the widest is 6.05 m in an 11.0 m
corridor; nothing eats more than 2 of the 4.0 m cells. That is a second whole
directory the game build can batch-wire as dungeon props **with no size gate at
all**, the same shape as the 114 it was handed at 07:58.

The world-scope rows are INFORMATIONAL, as they were for `assets/nature`: a
15.7 m roof section is not ROOM-LOCKED, it is a roof and it lives on a building.
The six over-corridor files are all `Roof_RoundTiles_*`, and the single
over-lid file is `Tree_4_C_Color1.gltf` at 10.774 m.

## THE SIGN, WHICH IS THE POINT OF THIS PASS
**180 sink, 22 float, 467 flush** across the 669.

- **Medieval Village is where the sign bites: 63 sink and 19 FLOAT.** These are
  MODULAR building parts whose pivot is the building's own origin, not the
  piece's base - `Roof_Log.gltf` **+3.8487 m**, `Corner_Exterior_TopOnly.gltf`
  +2.8832, `Window_Roof_Thin.gltf` +1.3382. Shift that directory by one sign and
  nineteen roofs go into the ground.
- Worst sinker in the whole pass is the dungeon pack's `banner.gltf.glb`
  **-2.5303 m** - the same wall-mount story as `Banner_1_Cloth` in `assets/props`,
  a different pack making the identical choice.
- `tileSpikes.gltf.glb` reads [2.0, 2.0, 2.0] with `base_dz_m` **-1.000**: the
  pivot is the tile's CENTRE, so half the trap is below the floor by design.
- Kenney's town kit is the cleanest of the five: 158 of 167 flush.
- **315 of 669 are `needs_centring`** - the footprint centre is off the pivot in
  x/y, so a prop centred by pivot sits off-centre in its cell.

## THE PICTURE, AND WHAT I CAN SEE WRONG IN IT
Five models off the manifest **by rank, not by eye** (worst float, two worst
sinkers, the probe suspect, a flush control), each with its PIVOT AT y=0 on the
floor slab, side-on, orthographic, 1.80 m bar, **every model labelled with its
name and signed offset**. Checks: not blank, `props_border_frac` 0.0,
`props_opaque_frac` 0.0245, and **all 6 labels verified individually** in their
own camera-space boxes.

Honest faults still in the sheet:
- **`tileSpikes` shows no spikes** - from the side it is a dark box. The name
  promises a shape the picture cannot confirm, and the harness measures BOUNDS,
  not shape, so neither of us can see it. Treat the 2.0 m cube as a bound.
- The 1.80 m bar is a stick. It gives scale; it does not look like a person.
- The right-hand models are dimly lit - the key light is to the left.
- **There is no picture of the corridor or lid verdict at all.** The 185-model
  "0 ROOM-LOCKED" claim rests on arithmetic against floorgeom's two terms and on
  the stamp, not on a rendered corridor. That is the biggest thing this run's
  evidence does not cover.

## THREE FAULTS IN MY OWN INSTRUMENTS THIS RUN
1. **The floor slab was HALF the width I wrote.** `primitive_cube_add(size=1)` is
   a UNIT cube spanning -0.5..+0.5, so a scale of `s` gives a width of `s`, not
   `2s`. Both sheets divided by two on top of that. The first render left the
   1.80 m bar and the worst FLOATER with no floor line under them - the one model
   whose entire finding is that it floats. I looked, extended the extent, looked
   again, saw it had barely moved, and only then found the arithmetic. **The
   picture was right twice and the number was the suspect twice.**
   `_worldfit_baseshot.py` carries the same halving and its sheet should be
   re-rendered next pass.
2. **The Icosphere probe produced three suspects and all three are FALSE.**
   `ASSET_SOURCES.md` records a Blender 5.2 glTF-import artifact that gives any
   rigged glb a stray radius-1 sphere. Three files matched the signature
   (all axes ≥ 2.0 m, `base_dz_m` within 2 cm of -1.0): `Rock_3_K_Color1`,
   `tileSpikes`, `tileSpikes_large`. The sheet settles it - `tileSpikes` renders
   as a solid slab with **no sphere anywhere in frame**. They are unrigged props
   whose pivot sits at their centre. A signature is not a diagnosis.
3. The labels needed their own arm. A caption that silently failed to render
   would make the sheet MORE misleading than no caption, and a labels-only alpha
   TOTAL would go green with one glyph missing - so each label is read in its own
   camera-space box, and the arm goes RED ON EMPTY.

## FOR THE GAME BUILD LANE (I do not wire it)
- **System 47, next batch: `_packs/kaykit_dungeon_pack_CC0/Models/gltf` - all
  185.** 0 ROOM-LOCKED, 0 THROUGH-LID, no size gate. CC0, licence read on disk.
- **System 15:** Medieval Village MegaKit (176) + Kenney Fantasy Town Kit (167),
  town-placed, corridor/lid terms do not bind.
- **System 68:** KayKit Forest Nature (105) + Ultimate Stylized Nature (36).
- **Read `sinks_below_pivot` and `floats_above_pivot`, not `needs_base_offset`.**
  The last list mixes signs. Medieval Village's 19 floaters are modular parts
  whose pivot is the building origin - a blanket shift buries them.
- Licences for all five directories are on the ledger in
  `docs/art/ASSET_SOURCES.md`, each read off the pack's own file this run.
