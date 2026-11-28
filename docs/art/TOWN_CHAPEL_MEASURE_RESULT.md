# The chapel measurement pass - RUN AT LAST, AND IT WAS RED ON EMPTY FIRST

**28 Nov 2026, 10:35-11:0x CST. Art lane.** The Blender bridge returned after a
nine-run outage, so the pass that `TOWN_CHAPEL_LADDER_PLAN.md` left at
`[ ] Measurement run - BLOCKED, bridge down` has now been run. It did not work
first time, and the reason is worth more than the table.

## 1. ROOT CAUSE: THE PACK PATH CONTAINED A GLOB CHARACTER CLASS

First run returned, cleanly and with rc 0:

    CHAPELMEASURE {"n_modules": 0, "n_walls_shot": 0,
      "errors": ["NO MODULES MATCHED - patterns or pack paths are wrong"]}

The error text blamed the paths. **The paths were perfectly correct.** The pack
directory is literally named

    Medieval Village MegaKit[Standard]

and `glob` reads `[Standard]` as a CHARACTER CLASS matching ONE character from
{S,t,a,n,d,r}. No such directory exists, so every pattern matched nothing.

PROVEN BEFORE FIXING, not assumed - same directory, same pattern:

    naive   glob.glob(os.path.join(pk, "Wall_*.gltf"))              -> 0 hits
    escaped glob.glob(os.path.join(glob.escape(pk), "Wall_*.gltf")) -> 20 hits

Fix: `glob.escape()` the DIRECTORY only; the pattern itself must stay live.
After the fix: **143 modules measured, 46 walls shot** (was 0 and 0).

**This is the third instrument fault this lane has red-proved in two days, and
it is the same family as the others: the message named the wrong suspect.** An
error string that confidently blames your input is still only a guess.

## 2. A SECOND DEFECT THE FIRST ERROR WAS HIDING

The old check only errored when EVERY pack came back empty, so one silently dead
pack read as a clean run. Added **red-on-empty PER PACK**. It fired immediately:

    PACK CONTRIBUTED ZERO MODULES - C:\hd adventure\_packs\Castle

## 3. CASTLE IS REMOVED - ON LICENCE, NOT ON PATH

Castle's 11 models do exist, nested one level deeper at
`_packs\Castle\Castle\Castle_Building_Blocks\*.FBX`, and three of them
(`Cathedral_Window`, `Cornice`, `Pillar_*`) are the best chapel vocabulary on
this disk. **They are still unusable.** `docs/art/ASSET_SOURCES.md` (~line 643)
records **NO LICENCE FILE FOUND**: no licence, readme, terms, credit or URL in
the tree or the zip, and an empty FBX author field. Status: NOT CLEARED, import
GATED.

**Making the scan recursive would have "fixed" the zero-module error by feeding
UNLICENSED geometry into a shipping ladder.** The pack is deleted from `PACKS`
with that reason written at the line, so no later run re-chases it as a bug.

**THE CLEARED CHAPEL SOURCE IS `Church1_blend`** - Blendswap 75990 "Medieval
Church" by Daniel74, **CC0 1.0**, licence HTML read off disk (ASSET_SOURCES.md
~line 369). It is a monolithic `.blend`/`.dae`, not a module kit, so it needs a
Collada/blend load path rather than this glTF one. That is the next step.

## 4. THE TABLE - AND THE LATTICE IS NOW A NUMBER, NOT A NAME

16 of 46 wall-like modules measure effectively solid (hole_frac < 0.02).
The holey end, which is where the Hall's defect came from:

    DoorFrame_Round_WoodDark         0.7194
    Wall_Arch                        0.7072
    DoorFrame_Flat_WoodDark          0.6964
    DoorFrame_Round_Brick            0.6554
    DoorFrame_Flat_Brick             0.6455
    WindowShutters_Thin_Round_Open   0.5516
    WindowShutters_Thin_Flat_Open    0.5300
    Window_Roof_Wide                 0.5282
    WindowShutters_Wide_Round_Open   0.5097
    Window_Roof_Thin                 0.5081
    WindowShutters_Wide_Flat_Open    0.5076
    Wall_UnevenBrick_Door_Round      0.4903

**`Wall_Plaster_WoodGrid` = 0.2943.** That is the module the Hall chose off its
NAME ("timber-framed") and shipped as a tier-1 wall you could see straight
through. Every gate in the house passed it. It is now caught by a measured
number before anything is built.

## 5. I LOOKED AT IT, AND THE PICTURE AGREES WITH THE NUMBER

`renders/art/town/_chapel_wall_solidity_4up.png` - four modules flattened onto
mid-grey so holes read as grey instead of as a transparency checker.

| module | hole_frac | opaque px | border alpha | what I see |
|---|---|---|---|---|
| Wall_Plaster_Straight | 0.0000 | 444,882 | 0 | solid plaster panel, timber frame |
| Wall_UnevenBrick_Straight | 0.0000 | 446,545 | 0 | solid stone wall |
| Wall_Plaster_WoodGrid | 0.2943 | 315,128 | 0 | **a mullioned WINDOW LATTICE** - 56 open squares, grey showing through every one |
| Wall_Arch | 0.7072 | 136,237 | 0 | an open archway, mostly void |

Blank check: 0 blanks, all four 136k-446k opaque px. Border check: max border
alpha **0** on all four - nothing clipped by the frame.

`Wall_Plaster_WoodGrid` is not a "timber-framed wall" in any sense. It is a
window grid. The name is the whole trap.

## 6. WHAT THIS GATE CANNOT SEE - READ THIS BEFORE PICKING TIER MATERIALS

- **THE PROBE SHOTS ARE UNDERLIT.** All 46 render dim. `solidity` is an ALPHA
  measurement so dimness cannot corrupt it, but it means **these shots cannot
  settle colour, material or condition** - and Mr. E's rule 2 says the chapel's
  three tiers must separate by MATERIAL AND WEAR, not by scale. Do not pick tier
  materials off this sheet. A lit material pass is owed before `chapelgen.py`.
- **`hole_frac` is blind to gable triangles**, which sit at the silhouette edge
  and read as background. The Hall shipped that hole on two tiers. Still assume
  the chapel has it and close it in the builder.
- **A module measuring 0.0000 is solid FACE-ON only.** Azimuth and elevation are
  both 0 by design (an angled shot fills a lattice's own gaps); that same choice
  means a module open at its TOP or SIDE reads solid here.

## 7. STATUS

- [x] Measurement run - **DONE**, 143 modules, 46 wall shots, 0 blanks, 0 clips
- [x] Root cause of the empty first run found, proven and fixed
- [x] Per-pack red-on-empty added, and it fired on its first run
- [x] Castle gated out on licence, with the reason written at the line
- [x] Looked at the 4-up sheet; picture and numbers agree
- [ ] Lit material pass - OWED, blocks tier material choice
- [ ] `Church1_blend` Collada/blend load path - the cleared chapel source
- [ ] Pivot confirmed on a built tier
- [ ] `chapelgen.py`, three tiers, side-by-side sheet, looked at
