# THE MINIBOSSES - four set pieces the art lane invented outright

Built 16 Nov under Mr. E's standing permission of 15 Nov 17:43: *"you can always
add mini bosses as well. that dont have to be lore mentioned"*. No canon entry,
no bestiary row written here, no `lore_lines`, no content-lane dependency. A
line in the feed when one appears is enough, and if one turns out to be a
favourite its lore can be written later - earned, not assigned.

**The bar, and the only bar: ONE IDEA THAT CHANGES THE FIGHT.** Not a normal
monster with more hit points. Each of these four is named for what it does.

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `drillmaster` | The Drillmaster | 2.20 | barracks | **IT SUMMONS** - beats the muster gong and the garrison forms up | 0.15 |
| `scrapwright` | The Scrapwright | 2.00 | workshop | **IT ARMOURS ITSELF** - every plate knocked off is replaced from the floor | 0.30 |
| `gaoler` | The Gaoler | 2.35 | prison | **IT DRAGS** - the hook takes one hero out of the line and reels them in | 0.80 |
| `snuffer` | The Snuffer | 2.60 | shrine | **IT TAKES THE LIGHT** - it puts out the lamps one at a time | 0.90 |

`assets/monsters/minibosses/<key>.glb` - **975-1816 faces, four meshes each**
(merged by material: built part-by-part they run to 60-200 objects, i.e. that
many draw calls for one set piece). Static meshes, **no armature**. Authored
with feet on z=0 at the height in the table.

Generators: `tools/art/minibosses.py` (geometry) and `tools/art/minibossgen.py`
(headless driver). The driver reuses D75's render rig whole - the same measured
clip range and the same blank-pixel assertion.

## Why these four, and why the silhouette decides it

`dungeon_hd.gd` already has the slot: the set-piece roll includes `"miniboss"`
at weight 15 on a normal floor, **35 on barracks and workshop**, 10 on shrine
and crypt, and it is gated to floor 4 and deeper. The slot was built and
under-used; it wanted better things to put in it. Two of these four are built
for the barracks/workshop weight because that is where the roll actually lands.

The acceptance test is `renders/art/minibosses/_silhouettes.png`, not the colour
render: colour thrown away, each must read as itself and none may read as a
hero. **Three of the four failed that test on the first pass and were rebuilt
after looking at the sheet** - which is the whole argument for looking:

- **Drillmaster.** Pass 1 hung the gong flat across his spine and the disc ATE
  HIM - a balloon on two legs with a crumb on top. You could not tell there was
  a man there, or that the disc was a gong rather than a shield. The gong moved
  off to his right and down, he stepped forward and turned a quarter, and the
  mallet became a long clear diagonal with a heavy head. Reads now as MAN, DISC
  BEHIND HIM, HAMMER UP.
- **Scrapwright.** Took two more passes. Pass 1 stacked nine flat plates in
  horizontal courses and produced a symmetrical pagoda - no mass, no lean, no
  read. Pass 2 gave it one dominant lopsided lump but sank the plates inside it
  and it came back a smooth boulder, so **the idea was invisible before the
  fight started**. Pass 3 lays each plate ON the lump, tangent to its surface
  along its own outward normal, over a dark core - which is also how a thing
  that patched itself would actually do it.
- **Gaoler.** The chain coil on the floor read beautifully from the first pass -
  a horizontal ring nothing else in the dungeon has. The HOOK, which is the
  entire mechanic, came out a hairline and vanished. The arm is now heavier and
  half a metre longer, swung clear of the body, and the hook is a C of iron
  0.70 m across you can read at pane distance.
- **Snuffer** passed first time and was not touched.

## Wear is a variable, not a style

These are not viewer gear, so the receipt argument does not apply - but they
must not all be equally rotten, and the `wear` column above is justified by what
each thing IS, not scattered for variety. `wear` drives materials only (rougher,
less metallic, colour pulled toward the dark as it rises); it never changes
geometry.

- **0.15 Drillmaster** - a working man keeps his instrument. The gong is the
  brightest object in this file; his coat and boots are dun.
- **0.30 Scrapwright** - freshly torn plate, still bright, bolted onto an
  ancient dark core. The contrast IS the creature.
- **0.80 Gaoler** - old greased iron and leather, used daily for a long time.
- **0.90 Snuffer** - it has been down there longest. Soot and dead wax.

## Corridors: measured, not hoped

A creature that cannot fit a corridor must be **room-locked by construction**,
never by hoping it fails to fit. `floorgen.gd` uses `G = 4.0` m per cell and
`WALL_IN = 0.5` m (a wall reaches that far into its cell), and D91 widens
corridors to three cells. So the clear span of a three-cell corridor is
**11.0 m**, and the driver compares every measured footprint against it:

| key | w x d x h (m) | footprint span | verdict |
|---|---|---|---|
| `drillmaster` | 1.39 x 0.71 x 2.20 | 1.39 | CORRIDOR-SAFE |
| `scrapwright` | 2.76 x 2.03 x 2.00 | 2.76 | CORRIDOR-SAFE |
| `gaoler` | 3.72 x 2.37 x 2.35 | 3.72 | CORRIDOR-SAFE |
| `snuffer` | 1.51 x 1.20 x 2.60 | 1.51 | CORRIDOR-SAFE |

**None of the four is room-locked.** The Gaoler's 3.72 m is the chain coil lying
on the floor, not his body - worth knowing if the spawn clearance test uses the
mesh bounds rather than a body radius, because the coil is scenery he stands
beside and nothing should be pushed out of the way for it.

## Verification

`renders/art/minibosses/_report.json`. Blank check **12 files, 0 failures** -
every PNG re-opened and its opaque pixel count asserted, because a wrong clip
range renders an empty transparent frame and reports success. Engine
`BLENDER_EEVEE` (there is no `BLENDER_EEVEE_NEXT` on 5.2). Contact sheet and
silhouette sheet both viewed before committing; the three rebuilds above are
what viewing them bought.

## For the game build worker - what the art lane cannot do

The art lane never runs Godot, so the in-game half is open and is not claimed
here. What is needed:

1. **A `model` path, same pattern as the lords and the twelve.** These are
   static meshes with no armature, so existing `anims` entries do not apply.
   Idle motion is a rig job and belongs with D74.
2. **The set-piece roll should prefer the theme-matched one.** The def that
   `dungeon_hd.gd` writes at build time is `Bestiary.pick(floor_no, theme)`; a
   miniboss set piece on a barracks floor should be able to pick the
   Drillmaster, on a workshop floor the Scrapwright, prison the Gaoler, shrine
   or crypt the Snuffer, rather than an elite ordinary creature.
3. **Each idea is a behaviour, and the behaviour is the point.** Shipping these
   as reskins with 2x hp and +20% atk (today's miniboss scaling) wastes them -
   the mesh is the promise that something different is about to happen. The
   summon, the re-plating, the hook-drag and the snuff are four small pieces of
   delve-side logic, and each is a better stream beat than a bigger health bar.
4. **The feed line** for each is in `minibosses.CANON` and in
   `renders/art/minibosses/_report.json` (`feed_line`) - one plain sentence, no
   lore attached: *"Someone is beating the muster." / "It is wearing the
   workshop." / "A chain is paying out in the dark." / "The nearest lamp has
   gone out."*

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`. No
third-party asset is read by any of it. Quaternius Bestiary / QAL is forbidden
on this project, which is why these are generated and not bought.

---

# SECOND SET - 16 Nov 2026: crypt, keep, treasury, mess

The first four were built for the two themes where `dungeon_hd.gd` rolls the
miniboss set piece at **35** (barracks, workshop). The four below cover the
themes where it rolls at **15** (keep, treasury, mess) and **10** (crypt) and
had nothing theme-matched to put in the slot, so it fell back to
`Bestiary.pick()` returning an ordinary creature with doubled hit points -
exactly the thing Mr. E's bar forbids.

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `sexton`   | The Sexton   | 2.45 | crypt    | **IT WILL NOT STAY DOWN** - it carries its own graves; four lit niches are four risings | 0.85 | 2.14 |
| `porter`   | The Porter   | 2.30 | keep     | **IT BARS THE WAY** - a leaf across the chamber mouth: no retreat, no reinforcement | 0.45 | 3.52 |
| `tallyman` | The Tallyman | 2.15 | treasury | **IT TAKES AND LEAVES** - it lifts gear off the party, wears it, and withdraws | 0.20 | 1.89 |
| `cook`     | The Cook     | 2.05 | mess     | **IT KEEPS THE PACK ALIVE** - the pot heals the room; spill the pot | 0.60 | 2.39 |

All four: four meshes merged by material, 1094-1722 faces, static, feet on z=0,
and **CORRIDOR-SAFE** against the 11.0 m clear span of a D91 three-cell corridor
(`floorgen.gd` G = 4.0, WALL_IN = 0.5). **None of the eight is room-locked.**

## Two of these are countable from the doorway, on purpose

The Sexton's four **lit** niches are his remaining risings and the viewer can
count them without being told; the Tallyman wears what it has already taken,
where the viewer who paid for that helm can see it. Mr. E's receipt rule cuts
both ways - a mechanic the stream can read off the model is worth more than the
same mechanic in a number.

## WEAR across the whole eight, lowest to highest

`tallyman 0.20` (the treasury is kept and this is the only bright thing in the
file) → `drillmaster 0.15` gong aside, `scrapwright 0.30` → `porter 0.45` (the
keep is maintained; sound oak, greased iron) → `cook 0.60` (greasy, long-used,
but the pot rim is scoured bright because a cook keeps his pot) → `gaoler 0.80`
→ `sexton 0.85` → `snuffer 0.90`. Nothing in the set shares a value.

## What the pictures overruled - again, three times

The blank check passed on every bad version. Only looking caught these:

1. **Sexton, twice.** Twelve flush cells fused into one banded slab - the thing
   you are meant to COUNT was invisible, and at pane distance he was the Porter.
   Rebuilt at nine bigger cells with air between them; that came back *worse*,
   a bigger solid slab, because each empty niche had a dark back plate closing
   it. An empty grave has to be **a hole you see through**. Back plates deleted,
   lit plugs pushed 0.16 proud, spade haft thickened.
2. **Porter.** A 1.02 m leaf directly behind him ate the far half of the
   drawbar from three-quarters, so "the widest horizontal in the dungeon" came
   out a stub and what remained read as the Sexton. Leaf narrowed and raised,
   bar lengthened to 2.84 m, pushed forward of the leaf and raked so both iron
   shoes clear the body from any angle.
3. **Tallyman.** The stolen kit hung on short cords inside the body's own
   width and fused with the torso - the receipt was not in the outline at all.
   A 1.86 m spreader bar now carries all five pieces wide of the body on long
   cords with air around each.
4. **Cook** (colour sheet, not silhouette). The pot was built from the body
   material and came back **a wooden tub**; and three thin glow tapers meant as
   steam read as pale spikes. The cauldron is black iron now with a scoured
   bright rim, the heat is a lit surface inside the rim, and the modelled steam
   is gone - geometry cannot do steam at this silhouette weight, so the delve's
   own particles can carry it.

## Handed to the GAME BUILD worker

Same four points as the first set, extended:

- `assets/monsters/minibosses/{sexton,porter,tallyman,cook}.glb`, static, no
  armature.
- The set-piece roll can now cover **crypt, keep, treasury, mess** with a
  theme-matched piece instead of an elite ordinary creature. Note `dungeon_hd.gd`
  currently lumps **shrine and crypt** into one weight row - the Snuffer was
  built for shrine and the Sexton for crypt, and the two should split.
- Feed lines: *"A spade is working somewhere in the dark." / "A bar has dropped
  behind you." / "Something is counting what you carry." / "The pot is on."*
- **The Porter's idea needs a door to exist.** It is the one of the eight whose
  behaviour touches the floor rather than the party: it wants the chamber mouth
  sealed for the duration. If that is expensive, the cheap honest version is
  "no fleeing this set piece and no wandering spawns join it" - the mesh already
  promises that much and no more.

---

# THIRD SET - 16 Nov 2026: flooded, grassland, wood, firepit, fogbound, confection

The first eight covered the themes `dungeon_hd.gd` names in its set-piece weight
table (barracks, workshop, prison, shrine, crypt, keep, treasury, mess). These
six cover the **six remaining `floorgen.gd` themes**, which fall through to the
default row `{"ambush": 45, "prisoner": 20, "shrine": 20, "miniboss": 15}` and
had nothing theme-matched to put in the slot. **All fourteen themes now have
one.**

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `sluicekeeper` | The Sluicekeeper | 2.50 | flooded | **IT RAISES THE WATER** - winds the gate open a notch at a time and the floor you are standing on goes under | 0.95 | 2.66 |
| `sower` | The Sower | 2.25 | grassland | **IT PLANTS THE GROUND AGAINST YOU** - what it casts stands up as thorn and closes the open field | 0.40 | 3.43 |
| `snarer` | The Snarer | 2.30 | wood | **IT HAS ALREADY SET THE ROOM** - it does not chase, it beats you onto its own lines | 0.55 | 3.25 |
| `stoker` | The Stoker | 2.40 | firepit | **IT IS ONLY AS BIG AS THE FIRE** - starve the pit and it starves | 0.70 | 3.00 |
| `bellman` | The Bellman | 2.70 | fogbound | **IT RINGS FROM WHERE IT IS NOT** - the sound comes from the wrong place | 0.65 | 2.72 |
| `boiler` | The Boiler | 2.10 | confection | **IT POURS AND IT SETS** - the floor hardens around your feet | 0.25 | 3.46 |

Four meshes merged by material, 842-1529 faces, static, no armature, feet on
z=0. All **CORRIDOR-SAFE** against the 11.0 m clear span of a D91 three-cell
corridor. **None of the fourteen is room-locked.** Blank check **42 files, 0
failures**; `_report.json` now carries all fourteen (see the regression below).

## What the pictures overruled in this set

**The Snarer was the Tallyman.** Pass 1 hung five snare loops off a spreader
bar across his shoulders - which is, exactly, the Tallyman's outline, two cells
away on the same sheet. A mechanic that reads as *another miniboss* is no
better than one that reads as nothing. The snares are now rooted where a real
snare is rooted: **three bent springpoles standing out of the floor**, arcing
over at three heights with a noose at each tip. Pass 2 made them too thick and
bent them at a sharp elbow, so they came back as scaffold girders; seven arc
points and a whippy taper made them curves. **They are the only curved lines in
the fourteen**, against a file of bars and discs.

**The Boiler was a round table, three times.** The pan, the pour and the set
pool on the floor kept stacking into tabletop, pedestal and base - and the pour
is the entire creature. Pass 1 tipped the pan forward, so the stream fell
toward the camera and foreshortened to a dot on its own centre line. Pass 2
rolled the pan hard sideways, which moved the stream clear but turned the dish
away so we read its blank underside and it ate his torso. Pass 3 is the real
fix: a dish **1.18 m -> 0.80 m across and higher**, so nothing falling off it
lands inside its own footprint, and the stream travels 0.9 m sideways before it
reaches the floor. Pass 4 thickened the stream and pushed the whole trunnion
further out to put air between the man and the pan. It is still the weakest
silhouette of the fourteen and that is said plainly below, not hidden.

**The sheet itself was broken.** `draw_text` advances 6*scale px per character,
so a cell fits 27 characters at scale 2 - and this set's hooks are longer than
that. "IT PLANTS THE GROUND AGAINST YOU" ran straight over "IT HAS ALREADY SET
THE ROOM", and the firepit hook was cut off by the sheet edge. The hook is the
one line that says what the thing DOES, so it now **wraps to two lines** rather
than shrinking, and the label band grew 54 -> 74 px.

## A regression in the report, found and closed

A `--sheet`-only pass started from an empty report and overwrote
`_report.json`, so the previous run shipped `"minibosses": {}` - every span,
face count, engine and corridor verdict for all fourteen, gone, while `"ok":
true` sat on top of it. The report file is now read back and merged before a
pass writes it. The blank-pixel assertion was never affected; this was the
bookkeeping around it, which is exactly where a silent loss hides.

## THE HONEST FAULT LIST - every one of these is visible on the sheets

**Sluicekeeper.** The lit pool at his feet reads as a white spotlight disc, not
water. The gate board's under-lip glow is hidden behind the frame, so the one
lit thing that says "water is coming" is invisible from the front. At wear 0.95
- the highest in the file - he is still among the palest; the wear number is
not legible on the model. The drag-board under his far arm fuses with the torso
from the front view.

**Sower.** The thorn shoots are the same pale wood colour as his hat and read
as loose sticks rather than something that grew. The cast seed is four small
spheres that will vanish at pane distance. His wide hat is the second wide cone
in the file after the Snuffer's, though the posture separates them.

**Snarer.** The left-hand noose overlaps his hat and shoulder from
three-quarter. The two right-hand poles cross near their roots and read as one
forked pole from that angle. The beating pole passes through his left forearm.
The pole roots are flat-cut and sit slightly proud of the floor. His hunch is
the same posture as the Sower's - hat and poles are what separate them, not the
body.

**Stoker.** The strongest of the six: dark soot body, lit firebox grate on the
chest, long rake down to the floor. But the rake head nearly leaves the cell at
bottom right; his head is lost against the dark body; and the chimney's lit cap
is the brightest thing on him, pulling the eye **above** the grate, which is
the actual idea.

**Bellman.** Unique in the file - the only full-skirted silhouette, and the two
bells sell "from where it is not". But the robe is a smooth cone with almost no
value break, and at wear 0.65 it reads clean and new, which contradicts its own
number. The offset second bell overlaps the hem. He has no feet by
construction; the cone runs to the floor.

**Boiler.** The pour now reads. The pan still overlaps his right shoulder from
three-quarter with no clean air gap; the near trunnion post crosses in front of
his right leg; the lit inner surface of the pan reads as a pale loaf sitting in
the dish rather than molten sugar; the stream's top emerges from behind the rim
instead of visibly over a lip; and at wear 0.25 the figure, apron, pan and
stream are all within a narrow value range - the stream only separates because
it is lit.

## WIRING - THE ART LANE DOES NOT DO THIS

`scripts/bestiary.gd` and `scripts/dungeon_hd.gd` belong to the game build
lane. **All fourteen miniboss meshes are still completely unwired**:
`bestiary.gd` contains no reference to `minibosses` at all, so every miniboss
set piece in the game today is still an ordinary creature with 2x hp.

1. **`scripts/bestiary.gd`** - add fourteen entries with
   `model = "res://assets/monsters/minibosses/<key>.glb"` and **no `anims`
   entry** (static meshes, no armature; idle motion is a rig job and belongs
   with D74).
2. **`scripts/dungeon_hd.gd` (~line 655)** - the weight table has rows for
   `prison`, `shrine`/`crypt` and `barracks`/`workshop` only; the other six
   themes fall through to the default and `Bestiary.pick(floor_no, theme)`
   returns an ordinary creature. A theme -> miniboss map is now possible for
   **every** theme: barracks/drillmaster, workshop/scrapwright,
   prison/gaoler, shrine/snuffer, crypt/sexton, keep/porter,
   treasury/tallyman, mess/cook, flooded/sluicekeeper, grassland/sower,
   wood/snarer, firepit/stoker, fogbound/bellman, confection/boiler.
   Note `shrine` and `crypt` still share one weight row and should split -
   the Snuffer was built for shrine and the Sexton for crypt.
3. **Each idea is a behaviour.** Shipping these as reskins with 2x hp and
   +20% atk wastes them; the mesh is the promise that something different is
   about to happen.
4. **Feed lines**, in `minibosses.CANON` and in `_report.json` (`feed_line`):
   *"The water is coming up." / "Something is broadcasting seed." / "The lines
   were here before you." / "The pit has been fed." / "A bell, and not where
   you thought." / "Something is pouring."*
5. **The Stoker's idea touches the room, like the Porter's.** "It is only as
   big as the fire" wants the firepit floor's own light sources to be
   damageable, or the cheap honest version: it loses attack as the floor's
   braziers are put out. The mesh promises that much and no more.

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`. No
third-party asset is read by any of it.

---

# FIFTEENTH, 17 Nov 2026 - THE JOINTER (workshop, the second one)

Taken because the team lead's 04:58 CT row says the art lane is dry and names
art as the one lane the freeze lets invent. Nothing else in this run was built.

## Why a second workshop miniboss and not a fifteenth theme

MEASURED THIS RUN, not remembered. `floorgen.gd` THEMES holds **14 keys** and
the set already has **14 minibosses, one per theme** - so there is no theme
without a body and the "missing theme" framing is wrong. What IS missing is a
second creature on the themes that actually fire the slot. From
`dungeon_hd.gd:737-743`:

| theme | miniboss weight | minibosses it can pick |
|---|---|---|
| barracks, workshop | **35** | one each |
| normal floor | 15 | one |
| prison | 15 | one |
| shrine, crypt | 10 | one |

The two themes that roll a miniboss **more than twice as often as any other**
are the two that have always shown the viewer the same creature. The Jointer is
the workshop's second.

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `jointer` | The Jointer | 2.25 | workshop | **IT COMES APART AND BOTH HALVES KEEP WORKING** - one pin holds two half-bodies; drive it or break it and there are two | 0.35 |

Not a normal monster with more hit points, and **the idea is visible before the
fight starts** (the Scrapwright lesson): real air down the middle, the pin
standing 0.30 m proud either side, two lamps at two different heights, and one
leg each on its own trestle block. Three arms - mallet, saw, and a spare hung
on a peg - because an odd arm count is the cheapest way to stop a silhouette
reading as a man. Wear 0.35 was the unused value in the set's 0.15-0.95 spread
and is justified by what it is: a workshop thing in daily use, bright worked
steel on timber gone dark with grease.

Feed line: *"It is pinned together."*

## Six passes, and what each one bought

Changed ONE thing at a time, rendered, looked, measured. The instrument is
`tools/art/_j_gap.py` - it windows on the seam, asserts the border, and **goes
RED on an empty band**, because a metric over zero rows reads green and means
nothing.

| pass | change | front open_frac | 3/4 open_frac |
|---|---|---|---|
| 1 | first build | 0.767 | - |
| 2 | rope turns wrap each half instead of crossing the seam | **0.885** | - |
| 3 | the halves lean apart (V, not a parallel slot) | 0.885 | - |
| 4 | clamp -> saw, spare arm moved outboard, warmer timber | 0.887 | 0.316 |
| 5 | teeth bedded on the blade, arm hung on a modelled peg, seam light tied to the pin | 0.896 | - |
| 6 | whole body yawed 20 deg into the sheet's view | 0.858 | **0.895** |

**THE INSTRUMENT WAS WRONG FIRST AND THE PICTURE CAUGHT IT.** Its first version
took the widest transparent run on each row and scored **0.90 open on a seam I
could see was shut** - the widest gap on those rows is between the hanging
mallet and the body, not the seam. It was rewritten to window on the figure's
own centre of mass before any pass-2 number was believed. Had I trusted it, the
rope fix would have looked unnecessary and the creature would have shipped with
its one idea closed up.

**TWO THINGS THAT DID NOT MOVE, SAID PLAINLY.** Pass 3's lean is clearly in the
picture and is NOT in the number (0.8853 -> 0.8853): the hole is pinched at the
plank corners beside the pin, so widening it above there does not move a mean
of per-row maxima. And pass 4's warmer tint moved hue but not luminance spread
(0.3328 -> 0.3331) - `bone` and `body` land within about 0.05 luminance under
`minibossgen.build_miniboss`'s shared material maths, which I did NOT change
because fourteen shipped bodies use it.

**THE SIDE VIEW CANNOT TEST THIS CREATURE AT ALL** - `open_frac` 0.000 from the
side is one half hiding the other, not a shut seam. That is a blindness, same
shape as the gloves' side column, and no conclusion rests on it.

## Fit - rendered on a body and looked at

`renders/art/minibosses/jointer/hero_front.png`, `hero_side.png`, `hero_back.png`:
the Jointer beside the **posed KayKit Knight at scale 1.0**, one ortho scale and
one ground line. **Ratio 0.92 of the hero's 2.45 m**, pair width 4.04 m, frame
fits. In `renders/art/minibosses/_fit_report.json` under `pairs.jointer`.

Measured: 4 meshes, 1005 faces, 2.18 m footprint span - **CORRIDOR-SAFE**
against the 11.0 m three-cell clear span. Blank check 15 files, 0 failures;
border check 0 opaque px in the outer ring on every view.

## THE FAULT LIST - nine, and the first two matter

1. **It reads THIN beside the hero.** The KayKit chibi body is heavy and this
   creature's timber columns are narrow against it; at pane distance it can
   read as a trestle frame rather than a creature. The biggest remaining fault.
2. **The lamp eyes are 2-3 px on the hero frame** and will not read on stream.
3. From the **side** it is a stick with a mallet and a toothed comb - it is thin
   front-to-back and the seam is invisible from there.
4. The near half's cap block **overhangs its torso** to the left like a brim.
5. The two lamps **do not match in brightness** front-on - the near pair reads
   as dim diamonds, the far pair as bright circles. A facing artefact.
6. **The pin is not materially separated from the timber** (see above - shared
   material maths, deliberately not changed).
7. The far half's upper arm **crosses in front of its own lamp block**.
8. The two trestle feet **nearly touch at centre bottom**, which slightly
   undercuts "two feet wide apart".
9. The mallet head reads as a **plain dark drum** at small size.

## For the game build lane - the art lane does NOT wire this

Nothing here touches `bestiary.gd`, `delve.gd` or any `.gd` outside `tools/art/`.
What the game build needs to do, when its own queue allows:

1. `assets/monsters/minibosses/jointer.glb` - static, no armature, so a `model`
   path and NO `anims` entry, same as the other fourteen.
2. `scripts/delve.gd` `MB_FIT`: add `"jointer": 0.92` - MEASURED, from
   `_fit_report.json`, not re-derived.
3. The workshop set piece can now pick between the Scrapwright and the Jointer.
4. The idea is a BEHAVIOUR. Shipped as a reskin with 2x hp it is wasted: the
   split body is a promise to the viewer that this thing becomes two things.

---

# 16. THE QUARTERMASTER - the second BARRACKS set piece, 17 Nov 2026

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `quartermaster` | The Quartermaster | 2.35 | barracks | **IT ARMS THE ROOM** - everything else in here takes a weapon off its sheaf | 0.50 |

`assets/monsters/minibosses/quartermaster.glb` - 4 meshes, **2,804 faces**,
static, no armature. Register row in `renders/art/minibosses/_fit_report.json`.

## WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED

1. **The plan, not this list.** `origin/main:docs/WORK_PLAN.md`, the 05:58 CT
   TAKE THIS NEXT block: the art lane is dry, D94 gloves is TICKED (do not
   re-shoot, do not touch `tools/art/icons.py` - I did not), the Jointer is
   verified, and the row is "a sixteenth is welcome on the same terms".
2. **What already exists**, counted off the tree: `assets/monsters/minibosses/`
   holds 26 `.glb` (15 bodies + 11 chibi conversions) and
   `assets/monsters/creatures/` holds 12. I built nothing that was already
   there. The gap I picked is the one the Jointer's own comment names and does
   not close: **the miniboss roll is weight 35 on BARRACKS and WORKSHOP**;
   workshop got its second body last hour, barracks still had exactly one.
3. **The packs, before modelling a single shaft.** `C:\hd adventure\_packs\`
   listed by directory this run: **56 entries**, the Ultimate Monsters,
   Bestiary Dungeon Monsters Kit, KayKit and Quaternius sets among them. And
   closer to hand, `assets/gear/` - 30 CC0 KayKit dungeon-bit models already in
   this repo and already logged in ASSET_SOURCES.md.

## IT USES THE PACK, AND THAT IS THE POINT OF THE CREATURE

**The spears and shields on this body are REAL `assets/gear/` geometry**
(`spear_A.gltf`, `shield_A.gltf`), not procedural cones - the same models
`gearmodels.py` hands to the heroes for D95. A quartermaster that issues the
exact weapons the party carries is the one case where "use what is on disk"
pays twice: it is cheaper AND it is the fiction.

- `minibosses._gear_mesh()` imports the glTF, harvests the evaluated mesh,
  normalises it to unit length about the grip and **deletes the imported
  objects**. Nothing is re-exported as an asset; the geometry rides inside our
  own glb, which the CC0 licence permits.
- **It falls back to procedural geometry if the file will not load, and SAYS
  SO**: `_report.json` carries `pack_used`. A silent fallback is the same fault
  class as a lying gate. This run: `pack_used: true`.
- **A DECIMATE ON IMPORT, because pass 1 cost 12,470 faces** against a set that
  runs 842-2,623. Collapse to ~120 faces per pack part brought it to **2,804**
  with the silhouette intact. The number is in the report, not asserted here.

## THE IDEA, AND WHY IT IS NOT A SIXTEENTH COAT OF AN EXISTING ONE

It does not fight you well and it calls nobody in. It **hands out what is
already in the room**: every ordinary creature on the floor takes a spear or a
shield off its sheaf and fights better until the sheaf is empty. Empty the
sheaf or kill the issuer - leave it alone and the trash stops being trash.

Checked against all fifteen: the Drillmaster **summons** bodies that were not
there, the Tallyman **takes your** gear and withdraws, the Scrapwright armours
**itself**, the Cook **heals**. This one upgrades what is already standing and
arms nothing of its own.

Silhouette collisions checked and avoided: no disc (Drillmaster's gong), the
offered spear is a **diagonal and never level** (Porter's drawbar), every shaft
is **dead straight** (the Snarer owns the only curves in the file), and nothing
hangs off a crossbar (Tallyman).

**WEAR 0.50 - the one unused value left in the set.** Used across the other
fifteen: .15 .20 .25 .30 .35 .40 .45 .55 .60 .65 .70 .80 .85 .90 .95. Right for
a barracks store in daily use: issued steel kept bright, canvas and timber not.

## THE FIT PROOF - ON A BODY, AND EVERY FAULT I CAN SEE

`renders/art/minibosses/quartermaster/hero_front|side|back.png`, each beside the
real posed KayKit `Knight.glb` at scale 1.0 (measured 2.45 m), one ortho scale
and one ground line shared with the other fifteen. **I looked at all three.**

Register: **verdict GREEN, errors [], asked 16 measured 16, blank_check 16
files 0 failures.** `pairs.quartermaster`: creature_h 2.35, hero_h 2.45,
**ratio 0.96**, pair_w 4.83, fits_frame true. Footprint span **2.97 m against
the 11.0 m three-cell clear span - CORRIDOR-SAFE**, not room-locked.

THREE PASSES, and each pass fixed a named fault rather than several at once:
- **Pass 1** read as a FEATHER CROWN on a robot: the spear heads were most of
  each spear, the shield stack was taller than the torso and lay on the floor
  like a dropped kite, the two spare shafts ran THROUGH the shields, and the
  offered spear sat **behind the legs** - the one thing the body is for, hidden.
- **Pass 2** lengthened and re-rooted the sheaf, shrank the shields, put a hand
  (fist + thumb) on each arm instead of a blunt ball, and swung the offering arm
  forward onto a measured midpoint. The shafts STILL cut the shields.
- **Pass 3** mirrored the offering arm to **-X, the near side of the
  three_quarter camera** - pass 2's mechanic was behind its own torso in the
  very cell that goes on the contact sheet - swapped the ground store to +X and
  moved the shafts a measured 0.76 m clear of the nearest shield face.

**WHAT IS STILL WRONG, and it is nine things:**
1. **The head still reads as a FACE.** The hatch, brim and two close-set lamps
   come out as a letterbox with eyes. The brief said no head; it has one.
2. **The body is a SLAB from the side** - thin front-to-back, the Sexton's
   known fault repeated. The side view earns less than the front.
3. **The sheaf collapses to two or three shafts from the side** and loses the
   fan entirely; the fan only exists front and back.
4. **The shield stack foreshortens into an unreadable grey lump** on the hero
   front shot, and on the back shot it reads as one blob with a shaft in it.
5. **The offering arm is a dead-straight thin diagonal with no elbow mass** -
   it reads mechanical, closer to a crane jib than an arm.
6. **The tally brand reads as a floating pearl** beside the head from the front
   and the side; its shaft is hidden behind the hatch, so it is not visibly
   rooted in the quiver it grows out of.
7. **The two spare shafts on the floor read as clutter**, not as stock.
8. **The spear heads are still large for the body** - normalising the whole
   thing to 2.35 m means the sheaf, not the torso, sets the scale.
9. **The lamp eyes are a few px on the hero frame** and will not read on stream
   - the same fault the Jointer carries, and it is a set-wide one.

## For the game build lane - the art lane does NOT wire this

Nothing here touches `bestiary.gd`, `delve.gd`, `dungeon_hd.gd` or any `.gd`
outside `tools/art/`. What the game build needs, when its own queue allows:

1. `assets/monsters/minibosses/quartermaster.glb` - static, no armature, so a
   `model` path and **NO `anims` entry**, same as the other fifteen.
2. `scripts/delve.gd` `MB_FIT`: add `"quartermaster": 0.96` - **MEASURED**,
   from `renders/art/minibosses/_fit_report.json` `pairs.quartermaster.ratio`.
   Do not re-derive it. (This is the same shape as the `"jointer": 0.92` and
   `"snarer_chibi": 1.00` rows already owed on that lane's row.)
3. The barracks set piece can now pick between the Drillmaster and the
   Quartermaster, which is the whole reason it was built.
4. **The idea is a BEHAVIOUR.** Shipped as a reskin with 2x hp it is wasted:
   the sheaf is a promise that killing this thing stops the room getting worse.
5. Feed line, if one is wanted: *"Something is handing out arms."*
6. As with every other body in this directory, there is **no `.glb.import`
   sibling** - the art lane never runs Godot. An import run writes it, and
   `delve.gd:377` already falls back safely until then.

================================================================================
## 17 - THE LOADER. Mess hall. 2026-11-17 07:55 CT.

**IT WEIGHS YOU DOWN.** It takes nothing off you and calls nobody in: it puts a
load ON you. A hero it reaches is carrying something and keeps carrying it
until they spend the time to drop it. Nothing is stolen and nothing dies
faster - the party just gets slower while it works.

### WHY THE MESS HALL, MEASURED BEFORE A VERTEX WAS WRITTEN
`dungeon_hd.gd:737-743`: the miniboss roll is **35 on barracks and workshop**,
**15 on prison and every unlisted theme**, **10 on shrine and crypt**. Both 35s
now carry two bodies (the Jointer last hour, the Quartermaster this morning).
Ten themes tie at 15 with exactly one body each. `floorgen.gd THEMES` decides
between them: the mess hall's own clusters are `feast`, `feast`, `kegs`,
`shelf_stock` - it is the one 15-weight floor **already full of crates and
kegs**, so a creature built out of the room's own stores needs no new prop to
explain itself. Its one body, the Cook, HEALS the room and shares nothing with
this mechanic.

### ENCUMBRANCE IS A MECHANIC CLASS NOTHING ELSE IN THE SET USES
Checked against all sixteen. The two near neighbours, named: the **Tallyman**
takes gear OFF a hero and withdraws with it; the **Quartermaster** hands
weapons to the other monsters. This one gives something to the HEROES and it is
a penalty. The sixteen summon, armour, drag, darken, revive, bar, steal, heal,
flood, plant, trap, depend on fuel, misdirect, set the floor, split and arm the
room - **not one of them touches what a hero can carry**.

### THE NUMBERS
height 2.65 m (unused in the set) | wear **0.75** (the one value left unused in
the .15-.95 ladder) | theme mess | 4 meshes | 1,208 faces | footprint span
2.39 m, **CORRIDOR-SAFE** against the 11.0 m three-cell clear span | ratio vs a
2.45 m posed KayKit Knight **1.08** | pair_w 4.26 m, fits_frame true | verdict
GREEN, blank+border check 51 files 0 failures, errors [].

### PACKS BEFORE GEOMETRY, AND WHERE THAT RULE STOPPED PAYING
The crate being handed over, the keg and the sack are **real KayKit Dungeon
Pack (CC0) geometry** out of `_packs/`, at 300/160/140 faces. Pass 1 built all
six stacked crates the same way at 90 faces each, because six at usable
fidelity would have blown the set's face budget - and **the decimate ate the
lids and corners, so every one came back as an open crumpled tray**. A pack
mesh is only worth loading where its detail can be afforded. The stack is now
closed banded boxes, which was the silhouette intent anyway.

### WHAT THE GAME BUILD MUST DO - NOT MINE, I TOUCHED NO .gd OUTSIDE tools/art/
1. `assets/monsters/minibosses/loader.glb` - **static, no armature**: a `model`
   path and **NO `anims` entry**, same as the other sixteen.
2. `scripts/delve.gd` `MB_FIT`: add `"loader": 1.08` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json` `pairs.loader.ratio`. Do not
   re-derive it. (Same shape as the `"quartermaster": 0.96` row already owed.)
3. No `.glb.import` sibling - the art lane never runs Godot. One import run
   covers this and `quartermaster.glb`; `delve.gd:377` falls back until then.
4. Feed line, if one is wanted: *"Something is putting a load on you."*
5. **The idea is a BEHAVIOUR.** Shipped as a reskin with more hit points it is
   wasted: the crate on the hook is a promise that this thing makes the party
   slower until it is dealt with.

### THE FIT PROOF - I LOOKED, AND HERE IS WHAT IS WRONG WITH IT
On a body, front/side/back, beside the posed Knight at one ground line:
1. **From the side the body barely reads as a body** - a lump under a column.
   The hump and the eyes are hidden behind the boom shoulder at 90 degrees.
2. **The lashing rope reads as a stick**, not a rope: a straight tube with no
   sag and no wrap around anything.
3. **The keg on the floor reads as a wicker basket** and **the sack reads as a
   dark rock** - both are pack meshes at the small end of their useful size.
4. **The iron bands on the crates vanish at hero scale** - at the pair framing
   the column is a stepped grey tower and the bands are one pixel.
5. **The signal lamp is a white dot** at hero scale; it only works in the
   creature's own three views.
6. From the front the eyes under the brim read as **a visored face**, which is
   nearer a head than the brief wants, though the body is bent and headless.
7. The hanging crate slightly **overlaps the body outline** on the side view.
8. Fixed on the way, both found by looking: pass 4's rope and lamp sat INSIDE
   the column's footprint and **could not be seen in any view** - a part the
   camera cannot see is not a part; and pass 4's load sat behind the leaning
   body with **open air between them** on the side view.

### A HARNESS FAULT FOUND AND FIXED IN THE SAME RUN
`minibossfit.py`'s blank check **only ever opened `hero_front.png`**. Each key
writes three views, so two of the three went into the register unchecked - an
instrument that can return GREEN over renders it never opened. It now opens all
three and a missing one fails the run: the count went **1 -> 51 files** for the
same seventeen keys, 0 failures.

---

## 18. THE HURDLEMAN - *IT CUTS THE ROOM IN TWO*
`hurdleman` - grassland - h 2.55 - wear **1.00** - 4 meshes, 1,418 faces -
span 3.10 m, **CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **1.04** beside the posed 2.45 m Knight, pair_w 4.96, fits_frame true.
Procedural, no pack geometry (`pack_used` false).

### WHY THIS ONE, MEASURED OFF THE SET AND OFF THE GAME - NOT REMEMBERED
- **Seventeen ideas existed and NOT ONE DIVIDES THE PARTY.** Parsed out of
  `minibosses.py` CANON, not recalled: summon, self-armour, drag a hero out,
  douse the lamps, will-not-stay-down, bar the door, steal gear, heal the pack,
  raise the water, plant the ground, pre-set the room, scale with the fire,
  ring from elsewhere, set the floor, come apart in two, arm the room, weigh
  you down. Party division is a mechanic class the set does not have.
- **It is NOT the Porter.** Being shut in is not the same fight as being cut in
  half: the Porter drops a leaf across the DOOR (no retreat, no help from
  outside), this one plants a panel through the MIDDLE OF YOUR OWN LINE, so the
  front rank and the healer behind it become two fights until a panel is broken.
- **Theme, counted off the game's files.** `floorgen.gd` THEMES + BIOMES = 14
  themes; `dungeon_hd.gd:737-743` weights them. Barracks 2 bodies, workshop 2,
  mess 2, every other theme 1. Grassland sits at weight 15 with one body (the
  Sower) and its clusters are overgrowth/stores/collapse - a sunken meadow is
  the one room where a hurdle needs no explaining, because a hurdle is what you
  pen a meadow with.
- **Wear 1.00 EXTENDS the ladder rather than repeating a step.** The .15-.95
  ladder is full: seventeen creatures, seventeen steps of 0.05, every one
  checked. Split grey hurdles that have stood out in a wet meadow for years are
  the most worn thing in the set and should read that way.
- Height 2.55 was the free gap in a 2.00-2.70 set.

### WHAT THE GAME BUILD MUST DO - NOT MINE, I TOUCHED NO .gd OUTSIDE tools/art/
1. `assets/monsters/minibosses/hurdleman.glb` - **static, no armature**: a
   `model` path and **NO `anims` entry**, same as the seventeen before it.
2. `scripts/delve.gd` `MB_FIT`: add `"hurdleman": 1.04` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json` `pairs.hurdleman.ratio`. Do not
   re-derive it. Same one-line shape as `"loader": 1.08` and
   `"quartermaster": 0.96`, both still owed.
3. No `.glb.import` sibling - the art lane never runs Godot. One import run
   covers this, `loader.glb` and `quartermaster.glb`; `delve.gd:377` falls back
   to the base body until then.
4. Feed line, if one is wanted: *"A hurdle just went down between you."*
5. **The idea is a BEHAVIOUR.** Shipped as a reskin with more hit points it is
   wasted: the whole of it is that the party stops being one party.

### THE FIT PROOF - SIX PASSES, ONE CHANGE EACH, EVERY ONE DRIVEN BY A PICTURE
1. **The harness went RED on its own author, and it was right.** Pass 1
   measured a **4.89 m footprint - the widest of the eighteen by 1.2 m** (the
   Gaoler's chain coil is 3.72) and the pair blew the fixed 5.60 m fit frame at
   6.75. The composition was spread, not the idea.
2. Pass 2 trimmed and still missed at 5.64 against 5.60. **A 40 mm miss is a
   miss**, and the measurement corrected me on WHERE: the left edge was the
   spare fan, not the stakes I had just pulled in. 3.10 m now.
3. **The spares read as one solid grey billboard** - the biggest mass in the
   silhouette, reading as a door or a shield, which is the exact opposite of
   what a hurdle is. Rebuilt as OPEN LATTICES, like the one already standing.
4. **The side view had no creature in it.** At the body's own depth the hurdle
   eclipsed the man entirely at 90 degrees - and a 34 degree yaw is no help,
   because 34 off the front camera is 56 off the side one. The hurdle went a
   metre FORWARD: it now stands between the camera and the creature, which is
   the mechanic drawn rather than a compromise.
5. **The beetle head read as a barrel lying on the floor** - a 10-sided cone
   inside the hurdle's own plane with the haft lost behind the lattice. A
   squared block, in front of the panel where the haft can be seen reaching it.
6. **From behind it read TWO-HEADED**: a pale shoulder sphere sat beside the
   withy head at the same tone. Smaller, and in the dark slot.

### PASSES 7-10: THE THREE WORST OF THE EIGHT, FIXED AND MEASURED
The team lead's 08:58 row named three of the eight faults below and said:
re-measure with the same method, state the number, do not assert the change.
So each of the three got AN INSTRUMENT BEFORE IT GOT A FIX -
`tools/art/_hurdle_probe.py`, which renders each part group of the body ON ITS
OWN through one camera off index spans the builder now records, and **reports
RED on an empty mask**, because a metric computed over nothing reads green and
means nothing.

| what the written fault says | the number for it | before | after |
|---|---|---|---|
| "the posts splay and cross at odd angles" | spread between the three panels' own screen axes, back view | **13.63 deg** (97.74 / 92.25 / 84.11) | **10.07 deg**, and an EVEN step (95.11 / 90.06 / 85.04) |
| " " | each panel's share buried behind another | 0.667 / 0.587 / 0.603 | 0.531 / **0.769** / 0.540 |
| "the standing hurdle covers the body from the chest down" | share of the man's own pixels behind the hurdle, three-quarter | **0.4662** | **0.3781** |
| " " | the same below his chest line | 0.5305 | 0.5309 |
| "the withy head still reads as a helmet with a visor band" | worst weave row's coverage minus the median row's, front | **0.5618** | **0.1379** |
| " " | the two lit eyes: pixels / row span / column span | 251 / 13 / 39 | 156 / 10 / 30 |

WHAT WAS ACTUALLY CHANGED, one lever at a time:
1. **The fan.** The panels sat at three different heights with an uneven yaw
   step and nothing tying them - so every post ended somewhere of its own.
   Now: one height, an even step, a wider step sideways, and a STRAP across
   the fan and over the shoulder, which is what makes a bundle read as carried.
2. **The hurdle.** 1.78 m to 1.40 m. The lever is height, not place - moving it
   would undo pass 4, which put it forward so the side view has a creature in
   it. A real sheep hurdle is chest-high on a man anyway.
3. **The head.** The three rings ran y, x AND **z** - and a ring on z is a
   horizontal hoop round the skull, i.e. a visor, whatever it is made of. Every
   hoop is now a MERIDIAN through the crown, so the dark runs top to bottom like
   the rods of a hurdle; one binding hoop stays, dropped to the neck. The eyes
   come off the brow line, down into the weave, smaller and closer.

### AND THREE THINGS THE INSTRUMENT AND THE PICTURE DISAGREED ABOUT. BOTH WERE USEFUL.
- **The first instrument did not measure the fault.** Edge-orientation
  concentration came back 0.8993 on the pass the eye calls a jumble, and the
  component count came back 1. Both true, neither about splay. Rebuilt to render
  the panels one at a time and ask the written question.
- **The picture vetoed a winning number.** A 0.20 m lateral step levelled all
  three overlaps at 0.387 - the best reading I got - and made the FRONT and
  THREE-QUARTER views worse than what I started with: the fan reached past both
  shoulders and read as a second fence, a man penned between two hurdles. Step
  back to 0.12 m, overlap back up to 0.769 on the middle panel, and I am not
  going to dress that up: it is a back-view measure and the written fault it was
  built for is fixed by the even yaw step, which survived.
- **The number caught a change my eye called an improvement.** Lying the panels
  back (pitch 0.26 -> 0.38) to get their tops under his shoulders took the splay
  to **24.34 deg - worse than the 13.63 I started from**. Pitch and yaw are not
  independent on screen. The tops came down by TRANSLATION instead (dz 1.00 ->
  0.84), which cannot rotate a projected axis.

### WHAT IS STILL WRONG WITH IT - I LOOKED AT THE NEW RENDERS, AND THIS IS THE HONEST LIST
1. **From the back the man is still mostly behind his own gear**, and this pass
   made it slightly worse, not better: 0.3944 of him hidden by the spares before,
   **0.4209 now**. The fan is wider and deeper than it was. That is the price of
   the three panels reading as three panels and I paid it knowingly.
2. **In the three-quarter view he is still a man among fences** - hurdle in
   front, fan behind. He is now the tallest and most central thing in the frame,
   which the lowered hurdle bought, but the enclosure is still there.
3. **Below his chest the hurdle hides as much as it ever did** (0.5309 against
   0.5305). Height could not move that number and nothing but moving the hurdle
   sideways will - which pass 4 forbids, because that is what gives the side
   view a creature.
4. **The head now has no face at all.** The visor read is gone, and so are the
   eyes: 156 px of glow, invisible at pair scale from the front. "Eyes deep
   inside the weave" is honest to the intent and reads as a blank basket.
5. **The strap does not read.** It is dark withy on dark withy behind an open
   lattice. It did its job in the geometry and none of it on screen.
6. **The maul is still invisible in the back view** and its haft is still lost
   behind the lattice from the front; only the side view shows the whole tool.
   Unchanged, and still fault 6 of the original eight.
7. **The withy coil on the floor still reads as a dark tyre**, and **the stakes
   still read as flat planks** - the points are gone at hero scale. Unchanged.
8. **Everything is still one tone.** At wear 1.00 the body, the hurdle and the
   spares sit in one narrow grey-green band. Unchanged, and still the thing I
   would change next.

### PASS 11, 2026-11-17 10:46 CT: THE TWO I NAMED AS MADE WORSE ARE CLOSED -
### AND THE SECOND ONE WAS NEVER MEASURED AT ALL
The team lead's 09:58 row said: settle the two faults you named as made worse
before a nineteenth, either by fixing them with the same before/after method or
by writing down that you accept them and why. I fixed both. The hour went on
the second one, because finding it meant finding that MY OWN INSTRUMENT COULD
NOT SEE IT, twice.

| the regression I named | metric | shipped (113a278) | now |
|---|---|---|---|
| "from the back the man is still mostly behind his own gear - 0.3944 before, **0.4209** now" | share of the man's own pixels behind the spares, back view | **0.4209** | **0.3691** - and better than the 0.3944 that started it |
| " " | the three panels buried behind each other | 0.531 / **0.769** / 0.540 | 0.579 / **0.640** / 0.580 |
| " " | spread between the panels' own screen axes | 10.07 deg | **9.44 deg** |
| "the head now has no face at all - 156 px of glow, invisible at pair scale" | glow pixels that SURVIVE the body in front of them, front view | **0** | **329** |
| " " | the visor band it must not bring back | 0.1379 | **0.1333** |

**I LOOKED AT THE PAIR RENDER BEFORE I TOUCHED A DIAL, AND THE NUMBER WAS
KINDER THAN THE PICTURE.** From behind, what I shipped has no creature in the
frame at all - a woven head and two shoulder knobs over a wall of fence. 0.4209
does not say that; the picture does. That is the whole reason the rule is look
at it.

WHAT WAS CHANGED, ONE LEVER AT A TIME, EACH MEASURED ON ITS OWN:
1. **The spare panels shrank**, 0.86 x 1.22 m to 0.78 of that. Measured, not
   guessed: the fan was 1.10 m across on SHOULDERS THAT MEASURE 0.52. He was
   carrying a bundle twice his own width, which is why he vanished behind it
   and why the front view read as a man penned between two fences. Spares are
   carried, so they are smaller than the one already standing. 0.4209 -> 0.3310.
2. **The lateral step went 0.12 -> 0.15**, on its own and measured on its own,
   because step 1 cost overlap (0.769 -> 0.844, three panels showing as two).
   The 0.20 m step the PICTURE vetoed at pass 7 was vetoed at 0.86 m panels; at
   0.67 m there is width back to spend. Overlap 0.844 -> 0.640, and the man
   hidden goes back up 0.3310 -> 0.3691. I took that trade deliberately: it
   still beats what I shipped on BOTH numbers.
3. **The eyes came out to the weave line** - 0.110 forward to 0.168, radius
   0.021 to 0.027, still below the equator and still close together so the
   visor read stays dead (0.1379 -> 0.1333).

### THE INSTRUMENT WAS GREEN OVER A FAULT IT COULD NOT SEE, AND THEN MY FIX TO IT WAS WRONG THE SAME WAY
This is the part worth keeping, and it is the second time this harness has been
green over nothing.
- **What I shipped said `head_glow_px: 156` beside the sentence "the head now
  has no face at all".** Both were true at once, and that should have been the
  tell. `mask_of` renders a group ALONE with everything else hidden - right for
  asking how big a thing is, useless for asking whether it can be SEEN. The
  eyes sat at y 0.110 inside a skull whose surface at that height is 0.152.
  **The honest number for what I shipped is not 156. It is 0.** Not dim. None.
- **Then my first fix to the instrument was wrong in the same family.** I
  rendered the body without the eyes and counted glow pixels falling outside
  its ALPHA. That asks whether the glow sticks out past the whole silhouette,
  and it answers 0 for every face ever drawn, because a face sits INSIDE the
  head's outline. It still read 0 after I had moved the eyes 58 mm clear of the
  skull - a metric that could not come out any other way. An alpha mask carries
  no depth.
- **The test that works asks the viewer's own question**: render the creature
  with the eyes and without them through one camera and count the pixels that
  MOVED. The renderer does the depth. 329 px, and the share exceeds 1.0 of the
  glow's own area because an emissive sphere also lights the weave around it -
  which is part of what is seen, so it counts.
- **And it now goes RED on a face that cannot be seen.** Re-run against the
  shipped geometry it reports RED with `head_glow_visible_px: 0`. The harness
  that passed my own blindness now fails it.
- **One more thing the run proved by accident**: shrinking the spare panels
  moved `head_glow_px` 156 -> 178 with no dial on the head touched, because the
  camera's ortho scale comes off the whole body's bounds. Raw pixel counts are
  not comparable across a pass that changes the silhouette. The share of the
  head's own weave is the scale-free form and is now reported beside it.

### WHAT IS STILL WRONG AFTER PASS 11 - I LOOKED, AND THIS IS THE HONEST LIST
1. **From behind he is still largely his own gear.** Better, and still not a
   creature from that angle: most of what now covers him is the STANDING
   HURDLE, not the spares, and that is the one thing pass 4 forbids moving.
2. **In the three-quarter he is still a man among fences** - 0.3775 against
   0.3781, i.e. unchanged. Accepted, not fixed.
3. **Below his chest the hurdle hides as much as ever** (0.5295 / 0.5309).
   Unchanged and accepted for the same reason.
4. **The eyes read as two pale dots at close framing** - at the creature's own
   three-quarter distance they are nearer to spectacles than to eyes. At PAIR
   scale, which is where the game sees him, they read as a face. I would rather
   have a face that is slightly odd up close than no face at all, but it is not
   the last word on the head.
5. **The strap still does not read** - dark withy on dark withy. Unchanged.
6. **The maul is still invisible from behind** and its haft still lost in front.
   Unchanged, and still fault 6 of the original eight.
7. **The coil still reads as a tyre and the stakes as flat planks.** Unchanged.
8. **Everything is still one tone.** At wear 1.00 the body, the hurdle and the
   spares sit in one narrow grey-green band, and at pair scale that is the
   single biggest thing standing between this creature and reading as a
   creature. Unchanged, and still the thing I would change next.

### THE NUMBERS AFTER PASS 11, SAME METHOD AS BEFORE
4 meshes, **1,790 faces** (unchanged - both levers are scale and placement),
span **2.98 m CORRIDOR-SAFE** against the 11.0 m three-cell clear span (3.07
before), **ratio 1.04 UNCHANGED** - so the game build's `MB_FIT` one-liner is
still the right number and must not be re-derived - pair_w **4.84** (4.93
before), fits_frame true. Register verdict **GREEN**, asked 18 / measured 18,
blank and border check **54 files, 0 failures**, errors [].

### THE NUMBERS AFTER, SAME METHOD AS BEFORE
4 meshes, **1,790 faces** (1,418 before - the meridional weave and the strap),
span **3.07 m CORRIDOR-SAFE** against the 11.0 m three-cell clear span,
**ratio 1.04 UNCHANGED** - so the game build's one-line `MB_FIT` entry is still
the right number and does not need re-deriving - pair_w **4.93** (4.96 before),
fits_frame true. Register verdict **GREEN**, asked 18 / measured 18, blank and
border check **54 files, 0 failures**, errors [].

================================================================================
## 19. THE TANNER - *IT WILL NOT TAKE THE SAME BLOW TWICE*
`tanner` - flooded - h 2.75 - wear **0.10** - 4 meshes, 1,284 faces -
span **2.50 m, CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **1.12** beside the posed 2.45 m Knight, pair_w 4.36, fits_frame true.
Procedural, no pack geometry (`pack_used` null). Five passes, 17 Nov 2026.

### WHY THIS ONE, MEASURED - NOT REMEMBERED
- **EIGHTEEN IDEAS EXIST AND NOT ONE CLOSES A DOOR ON A WEAPON.** Parsed out of
  `minibosses.py` CANON, not recalled: summon, self-armour, drag a hero out,
  douse the lamps, will-not-stay-down, bar the door, steal gear, heal the pack,
  raise the water, plant the ground, pre-set the room, scale with the fire,
  ring from elsewhere, set the floor, come apart in two, arm the room, weigh
  you down, cut the room in two. **Adaptive resistance is a mechanic class the
  set does not have.**
- **IT IS NOT THE SCRAPWRIGHT, AND THAT IS THE ONE IT HAD TO BE CHECKED
  AGAINST.** The Scrapwright replaces plates you knocked off and the fight is
  unchanged - hit it again, harder. The Tanner never heals a point. It takes
  one of your ANSWERS away and leaves the rest, so the party that brought one
  weapon is in trouble and the party that brought three is not. A decision,
  not a damage sponge.
- **THEME `flooded`,** off `dungeon_hd.gd:737-743`: the miniboss roll is 35 on
  barracks/workshop, 10 on shrine/crypt, 15 on prison and every unlisted theme.
  `flooded` is unlisted, so it rolls at **15 with exactly ONE body behind it**
  (the Sluicekeeper) - every miniboss a flooded floor has ever shown is the
  same creature. Same argument the Loader used for the mess hall. A tan-pit is
  standing water nobody wants to be near; the room explains the trade.
- **WEAR 0.10 EXTENDS THE BOTTOM OF A FULL LADDER.** All eighteen checked:
  0.15 to 1.00 in steps of 0.05 is full (the Hurdleman took 1.00 to extend the
  top). 0.10 is honest rather than a repeat because **freshness is this
  creature's mechanic** - it is the one thing down there never allowed to get
  old, wearing skins it dressed this hour. Mr. E's rule 2: condition is the
  receipt, and this receipt reads *newly covered*.
- **HEIGHT 2.75** likewise extends a full ladder (2.00-2.70 in 0.05s, all
  taken). It is the FRAME that is 2.75, not the man: stooped over a beam he
  reads shorter than the Bellman he is taller than.

### THE FIVE PASSES, AND WHAT THE PICTURE SAID THAT NO NUMBER DID
Every pass was GREEN on the register harness. The harness was never wrong - it
measures scale, blanks, frame and corridor, and none of those was ever the
fault. **Everything below was found by looking.**
1. **PASS 1 FAILED OUTRIGHT.** Three tapered panels hung UNDER the rails with
   rigid triangular leg-flaps came back as **three paper sacks on a gibbet** -
   a post-and-lintel frame with bags swinging off it. Gothic flourish is the
   one register Bellmire does not have, and it was not even the trade: a tenter
   STRETCHES a skin, it does not hang one.
2. **PASS 2** stretched the skins across the bays, cut the crown rail so the
   uprights top out as two bare poles, left one bay empty for daylight, and
   shrank the beam. The gallows read died. The man then read as **seated at a
   bench hugging a plank**, because a beam at 0.74 crosses a standing man at
   the hip.
3. **PASS 3** took the beam to working height (0.96), lengthened the stoop so
   the shoulders sit ahead of the hips, halved the hide bow (two matched
   bolsters had read as pillows), and rebuilt the arms. **The arm fault had the
   wrong cause for two passes**: the grips were always 0.46 m below the
   shoulders, but the forearms ran TOWARD THE CAMERA and a limb pointing at the
   lens is foreshortened to nothing, so the front view only ever showed the
   upper arms splaying out of a dark shoulder knob. Height was never the
   problem; the plane was.
4. **PASS 4, one change.** The beam's left end was buried behind the apron, so
   its trestle leg stood out alone as **a pale post with daylight round it
   holding up nothing**. The LOG was in the wrong place, not the leg - shifted
   0.30 m right and shortened. Span 2.92 -> 2.65.
5. **PASS 5, one number.** At yaw 31 the rack is 31 degrees off square to the
   front camera and 59 to the side one, and the side shot squeezed both skins
   into strips - the rack, which IS the read, nearly vanished in one of the
   three views the register demands. **45 degrees is the only yaw that treats
   front and side the same.** Span 2.65 -> 2.50.

### WHAT IS STILL WRONG, AND I AM NOT HIDING IT
Looked at on `hero_front.png`, `hero_side.png`, `hero_back.png` and
`three_quarter.png` after pass 5:
1. **SIDE VIEW: the rack's two uprights cross the man and he is largely behind
   them.** The man and the rack are separated in X, so the 90-degree camera
   stacks them. Pass 5 traded a thin rack for an occluded man and I think that
   was the right trade - the rack is the read - but it is a real fault and the
   next pass on this body should move the rack BACK in Y rather than turn it.
2. **FRONT VIEW: the upper arms still splay** and read as half-raised. Three
   passes improved it and none killed it; the forearms foreshorten by nature at
   this pose.
3. **The fleshing knife only reads in the three-quarter.** Front and side it is
   under the arms and behind the beam.
4. **The beam's left end is a bare cone cap** - a pale disc pointing at the
   viewer in three-quarter, reading as a pipe end rather than a sawn log.
5. **The hides' bottom corners scallop upward** (the ragged-edge sine), which
   at pair scale reads slightly like the mouth of a bag rather than a trimmed
   skin.
6. **The spare skin over his left shoulder does not read at all** at pair scale
   - it merges into the shoulder mass.
7. In three-quarter the head and the beam's near end nearly touch.

### WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT
1. `assets/monsters/minibosses/tanner.glb` - **static, no armature**: a `model`
   path and **no `anims` entry**. As with every other body here there is **no
   `.glb.import` sibling** (this lane never runs Godot); an import run writes
   it and `delve.gd:377` already falls back safely until then.
2. `scripts/delve.gd` `MB_FIT`: add `"tanner": 1.12` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json` `pairs.tanner.ratio`. Do not
   re-derive it. Same one-line shape as `"hurdleman": 1.04` and
   `"loader": 1.08`.
3. The `flooded` set piece can now pick between the Sluicekeeper and the
   Tanner, which is the whole reason this one was built for that theme.
4. **The idea is a BEHAVIOUR.** Shipped as a reskin with extra hit points it is
   wasted: the rack is a promise that every answer you spend is an answer you
   do not get back.
5. Feed line, if one is wanted: *"It is pegging up a fresh hide."*

================================================================================
## 20. THE REEVE - *IT TAKES THE HAUL*
`reeve` - keep - h **1.95** - wear **0.05** - 4 meshes, 1,420 faces -
span **3.26 m, CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **0.80** beside the posed 2.45 m KayKit Knight, pair_w **5.12**,
fits_frame true.
*(RECONCILED 18 Nov 18:4x CT, asked for by the team lead. This header used to
read span 2.96 and pair_w 4.83. THE REPORT WAS RIGHT AND THE HEADER WAS STALE:
the 17:40 anchor-spike fix removed 170 mm of buried cone from the height that
canon-height normalisation was scaling, so the VISIBLE body grew ~10% and the
footprint with it - 2.96 -> 3.26 m, and the pair 4.83 -> 5.12 m. That number is
in `_report.json` and in the fix commit's own message; only this line was never
updated. Both re-measured from today's rebuild, not copied.)* Procedural, no pack geometry (`pack_used` false).
Five passes, 17 Nov 2026.

### WHY THIS ONE - MEASURED, NOT REMEMBERED
- **NINETEEN IDEAS EXIST AND NOT ONE OF THEM TOUCHES WHAT THE FLOOR PAYS.**
  Parsed out of `minibosses.py` CANON this run rather than recalled: summon,
  self-armour, drag a hero out, douse the lamps, will-not-stay-down, bar the
  door, steal worn gear, heal the pack, raise the water, plant the ground,
  pre-set the room, scale with the fire, ring from elsewhere, set the floor,
  come apart in two, arm the room, weigh you down, cut the room in two,
  adaptive resistance. Every one is about the FIGHT. None is about the TAKE.
- **AND THE TAKE IS A REAL RESOURCE IN THE CODE, not something I invented for
  the creature.** `delve.gd:34` carries `haul = {ore, stone, gear, potion}`
  and `_loot()` at `:2014` adds gold at `:2038` and ore/stone at `:2066-7`.
  A creature standing between the party and that dictionary needs no new
  system behind it.
- **IT IS NOT THE TALLYMAN, AND THAT IS THE ONE IT HAD TO BE CHECKED
  AGAINST.** The Tallyman lifts gear OFF A HERO, wears it and WITHDRAWS -
  theft from a body, and it leaves. The Reeve never touches a hero and never
  leaves: it is chained to its own box by construction, and what it takes is
  the floor's take, which nobody is carrying yet. One is a pickpocket, the
  other is a toll. The pressure differs too: the Tallyman makes you CHASE, the
  Reeve makes you HURRY. It is a shot clock on your wages.
- **THEME `keep`,** off `dungeon_hd.gd:737-743`: the miniboss roll is 35 on
  barracks and workshop, 10 on shrine and crypt, 15 on prison and every
  unlisted theme. `keep` is unlisted, so it rolls at **15 with exactly ONE
  body behind it** (the Porter) - the same single-body case the Loader and the
  Tanner were built for. `floorgen.gd:183` makes the room argue for it without
  a word of lore: the inner keep is the only theme with blue banners, `feast`
  and `shelf_stock` clusters and decorated pillars. The lord's own hall is
  where a share is rendered.
- **HEIGHT 1.95 EXTENDS THE BOTTOM OF A FULL LADDER.** All nineteen checked by
  parsing CANON: 2.00-2.75 in 0.05s is full (the Tanner took 2.75 to extend
  the top). 1.95 is honest rather than a repeat, and it is the right number -
  **THE BOX IS THE CREATURE** and the man beside it is small on purpose. At
  0.80x a hero this is the smallest body in the set.
- **WEAR 0.05 EXTENDS THE BOTTOM TOO, for a different reason than the Tanner's
  0.10** - the only other value down there. The Tanner is fresh because of a
  PROCESS: it re-covers itself hourly. The Reeve is fresh because NOTHING IT
  OWNS IS EVER USED - a strongbox that is only filled, never opened and never
  fought with has no scars on it. Mr. E's rule 2: condition is the receipt,
  and this receipt reads UNTOUCHED.

### FIVE PASSES, ONE NAMED FAULT EACH, AND THE BIG ONE A NUMBER COULD NOT SEE
1. **PASS 1 built it and the SIDE VIEW HAD NO CREATURE IN IT.** Man at x
   -0.64, box at +0.48, and the side camera looks along X - so at azimuth 90
   the box stood in front of the man and the frame was chest, spike, nothing
   else. **The blank check cannot see this**: that frame is full of opaque
   pixels, they are just all box. Same fault class as the Tanner's pass 5 and
   as `minibossfit`'s own hero offset, which separates the pair in BOTH axes
   for exactly this reason.
2. **PASS 2, one change: the man moved 0.72 m FORWARD of the box** (a clear
   0.37 m in front of its near face), so front/back separate him in X and the
   side view separates him in Y. He is in all three views now.
3. **PASS 3, one part - and it is the part the mechanic rests on.** The hands
   were flat plates whose broad face pointed at the CEILING, so the front
   camera only ever saw their 0.05 m edge: the taking hand read as **A BLADE**
   and in profile the two lined up into ONE LONG PLANK from his chest to the
   far side of the box. A creature built around an open palm read as a man
   with a cleaver. The palm is now tipped up to face the room (1.18 rad, not
   0.34) with fingers and a thumb; the lid hand lost its plate for a knuckled
   lump, because that plate was the other half of the plank.
4. **PASS 4, one part: the lit throat.** Pass 3's glow was a solid cone 0.49 m
   across filling the mouth edge to edge, and it came back as **A LUMP OF
   DOUGH** - the creature read as a hopper full of batter, which is the
   Boiler's trade and not this one. Light reads as light when it is a thin
   SOURCE against a dark interior, never when it is a solid the size of the
   opening. Now: a lit ring just inside the rim and a small plug far down the
   throat. The camera gets a dark square hole with its edge alight.
5. **PASS 5, one thing: the man's MASS.** On the hero pair shot the box held
   up - bands, lock and feet all read - and the man came back **a stick
   figure** beside a KayKit adventurer measured here at 2.45 m tall and 1.32 m
   across. A 0.086 m shin next to that is a wire. Nothing moved and nothing
   was added: the same skeleton at honest thickness, so the improvement is
   mass and not a new part.

### THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE
On `hero_front.png`, `hero_side.png`, `hero_back.png` (the posed 2.45 m Knight
at one ground line and one ortho scale) and on `three_quarter.png`:
1. **The coat is a FRONT-ONLY panel.** From behind the man is a plain pale
   torso tube with no garment on it - the thing that makes him read as an
   officer rather than a small hero exists in two views out of four.
2. **In profile both arms collapse into one horizontal bar** - the two hands
   sit at nearly the same height, so the side view shows a single beam across
   him. Better than pass 3's plank, still one line where there are two arms.
3. **The legs merge into one column in profile** (the stance is in X only).
4. **The lit throat does not read as LIGHT at pair distance** - it reads as a
   pale liner inside a dark opening. The opening reads; the fire in it does
   not. If this matters it is an emission-strength pass, not a geometry one.
5. **In silhouette the hopper's mouth fills in solid** - the far wall of the
   funnel closes the hole, so the opening survives only as the funnel's
   outline. The one shape the creature is named for is the one the silhouette
   test cannot show.
6. **The chain reads as a floating hook from the front**: its ring is on the
   far (+X) face and hidden behind the box, so at the front camera a bent iron
   line and a spike stand beside the chest attached to nothing visible.
7. **The spill lumps and the belt seal are 2-4 px dots at pair scale** and
   only work in the creature's own three views - the Loader's known fault
   repeated, and I did not fix it here either.
8. **The fingers read as a small fork or comb** at pair scale, front and back.
9. The man's head is a bare pale sphere under the cap; it reads as a face with
   two eyes. The brief prefers no face, and three bodies in this set have the
   same note. It does NOT read as a visor - the cap band stays above the
   equator, which was the specific fault being avoided.

### THE INSTRUMENT, AND WHAT IT STILL CANNOT SEE
`minibossgen` 60 files blank+border checked, 0 failures, errors []; 4 meshes
(the bar is four), 1,420 faces. `minibossfit` verdict **GREEN**, asked
`["reeve"]`, measured `["reeve"]` - not an empty register - hero measured at
2.45 m posed true, blank check 3 files 0 failures.
**NEITHER OF THEM COULD HAVE CAUGHT PASS 1'S FAULT**, and that is worth
writing down rather than filing a green verdict quietly: a view in which one
of the two masses completely occludes the other is a full frame of opaque
pixels inside the border, which is exactly what both harnesses measure. The
only instrument that caught it was looking at the picture.

### WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT, AND I TOUCHED NO .gd
1. `assets/monsters/minibosses/reeve.glb` - **static, no armature**: a `model`
   path and **NO `anims` entry**, same as the other nineteen. As with all of
   them there is no `.glb.import` sibling (this lane never runs Godot); an
   import run writes it and `delve.gd:377` falls back safely until then.
2. `scripts/delve.gd` `MB_FIT`: add `"reeve": 0.80` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json` `pairs.reeve.ratio`. Do not
   re-derive it. Same one-line shape as `"tanner": 1.12` and `"loader": 1.08`.
3. The `keep` set piece can now pick between the Porter and the Reeve, which
   is the whole reason this one was built for that theme.
4. **The idea is a BEHAVIOUR, and this one is an ECONOMY behaviour** - it wants
   `haul`/gold, not damage. Shipped as a reskin with extra hit points it is
   wasted: the box is a promise that a cleared floor can still pay you nothing.
5. Feed line, if one is wanted: *"It is here for the lord's share."*

================================================================================
## 21 - THE TAPSTER. IT DRINKS WHAT YOU BROUGHT.
*17 Nov 2026, art lane. Five passes. Theme `firepit`, height 2.80 m, wear 0.22.*

**THE IDEA.** It does not hit hard, it does not call anybody and it never
touches a hero's back. It stands over a tun with the tap open, and every brew
raised in this room goes down that tun instead of down the hero who raised it.
The counter is to spend NOTHING and kill it dry. Leave it standing and the
satchel empties - and `delve.gd`'s own flee rule does the rest. **The fight is
a siege of your own supply: this one does not kill the party, it breaks the
line.**

### WHAT I CHECKED FOR FIRST - MEASURED, NOT REMEMBERED
- **The twenty were parsed out of `CANON` this run**, not recalled: summon,
  self-armour, drag a hero out, douse the lamps, will-not-stay-down, bar the
  door, steal worn gear, heal its own pack, raise the water, plant the ground,
  pre-set the room, scale with the fire, ring from elsewhere, set the floor,
  come apart in two, arm the room, weigh you down, cut the room in two,
  adaptive resistance, take the haul. Every one is about the FIGHT, the ROOM or
  the TAKE. **None is about the SATCHEL.**
- **The resource is real and wired three deep**, grepped out of `scripts/`:
  `roster.gd:1108` `brew_count`, `:1113` `add_brew`, `:1125` `brews_line`;
  `delve.gd:3273` `roster.add_brew(h, key, -1)` is the actual swallow; and
  `delve.gd:1287` `if frac < FLEE_AT and not _has_heal_brew(h)` means a hero
  with nothing left to drink **turns and walks out of the floor**. No new
  system is invented to hang this creature on.
- **It is not the Cook.** The Cook heals EVERYTHING ELSE IN THE ROOM - a buff
  on the pack, countered by spilling the pot. The Tapster heals nothing of its
  own; it denies YOUR healing. One adds hit points to the enemy, the other
  subtracts the only thing you brought.
- **It is not the Tallyman.** That one lifts WORN GEAR off a body and
  WITHDRAWS. This one takes a CONSUMABLE at the moment of use and never leaves
  its tun. A pickpocket, a toll and a landlord are three different creatures.
- **It is not the Snuffer, and that was the near miss.** Bellmire's word
  "flask" means LAMP OIL in half the code (`delve.gd:28, :80, :159`,
  `roster.gd:564`), so a creature that drank the OIL would be IT TAKES THE
  LIGHT with a barrel in front of it. It takes BREWS - a separate dictionary
  with a separate reader. The oil is left alone.
- **Theme `firepit`**, one body behind it (the Stoker). `mess` is where a
  tapster would stand in life and was **rejected on purpose**: the Cook is
  already in `mess`, and a healing-denier in the one room that holds the
  healing-giver is how a new body gets read as a re-skin of an old one.
- **Height 2.80 extends a FULL ladder.** All twenty parsed: 1.95-2.75 in steps
  of 0.05, no gap. **Wear 0.22 sits BETWEEN two rungs** because the 0.05 wear
  ladder is also full, 0.05-1.00, all twenty occupied. 0.22 is between the
  Tallyman's 0.20 and the Boiler's 0.25 and the reason is the trade: a tapster
  scours his tun - sour wood is a ruined cellar - but nothing replaces the
  hoops. Pale clean staves, old iron. The receipt reads KEPT, NOT NEW.
- **Nothing new was modelled that was already on disk.** `assets/props/` (309
  files, CC0 Fantasy Props MegaKit) supplies the cask, the hung flasks and the
  jack. Logged in ASSET_SOURCES.md, which did not list that pack before today.

### THE FIVE PASSES - EACH ONE THING, EACH JUDGED BY LOOKING
1. Built. The read was there: hooped tun, rail of flasks, man with a jack.
2. **The pack models were being eaten by the decimate.** Face counts read off
   the `.gltf` accessors, not guessed: Barrel 824 tris, SmallBottle 130, Mug
   268, all capped at 110. Loaded whole, the flasks stopped being grey slabs
   and the jack got its handle. Paid for by taking the four hoops from 20-gon
   to 14-gon - same radius, same 0.044 thickness, nothing visible changed.
3. **PASS 2 WAS ONLY HALF RIGHT AND THE CASK SAID SO WHILE THE REPORT STAYED
   GREEN.** The staves were still torn shards. Probing the file instead of
   guessing twice: `Barrel` is ONE object with TWO material slots - 0 the
   wooden cask at radius 0.348, 1 the pack's own hoops at radius 0.349. **One
   millimetre. It was Z-FIGHTING**, which no decimate ratio was ever going to
   change. Slot 1 dropped; this body draws its own heavier hoops anyway.
4. **The tap came out of the face and was therefore not in the picture.** It
   pointed -Y, straight at the front camera, and a 0.26 m spout foreshortened
   to four pixels lost against the staves - so the right hand read as a palm
   laid flat on a barrel and **the only organ the mechanic has was invisible**.
   That is the Tanner's pass-3 and the Reeve's pass-3 finding, quoted in this
   creature's own docstring and then violated in the one place it mattered.
   The tap now runs out of the **-X flank, across the front camera**, at full
   length, with a vertical handle no camera can foreshorten.
5. **The apron stopped being a sandwich board.** A flat 0.47 m plate, wider
   than his own torso and 0.03 m proud of it, erased chest, shoulder line and
   neck, and both arms appeared to spring from the board's corners. It is now
   narrower than he is (0.33 against 0.45), bibbed to a strap at the top, and
   bowed round him. The body shows down both sides.

### THE FIT PROOF - LOOKED AT, NOT ASSERTED
`renders/art/minibosses/tapster/hero_front.png`, `hero_side.png`,
`hero_back.png`: the Tapster beside a real posed KayKit Knight at scale 1.0,
one fixed frame, one ground line.
- **ratio 1.14** (creature 2.80 m / hero measured 2.45 m posed), pair width
  4.90 m inside the 5.60 m frame.
- **The side view separates them, first time.** This is the Reeve's pass-1
  fault answered before it happened rather than after: the man stands a clear
  0.36 m FORWARD of the tun's near face, because azimuth 90 looks along X and
  X separation does nothing there.
- Front and back both read as **a man in a cellar apron at an open tap on a
  hooped tun, with other people's flasks hung above it**.

### THE FAULTS I CAN SEE. NINE, NONE SWEPT.
1. **The man is a WIRE beside the knight.** Same fault the Reeve named at its
   pass 5 and I did not get to it here: KayKit bodies are chibi and chunky
   (2.45 m tall, 1.32 m across) and this torso, neck and limbs are
   adult-proportioned and read thin at pair distance. **This is the top row for
   the next seat on this body.**
2. **The head is small** for the same reason - KayKit heads are enormous.
3. **The right hand does not visibly grip the tap handle.** Its three finger
   cones point -Y, at the lens, and foreshorten to a blob; the arm reads as a
   bent stump ending in air. Pass 4 fixed the tap and left the hand behind.
4. **The side view loses the tap entirely** - the cask is between it and the
   camera. ROOM-LOCKED BY CONSTRUCTION in the same sense: a tap faces one way,
   and it faces the way the front view reads. Named, not hidden.
5. **The side view collapses the rail and all five flasks into one post and
   one blob.** The top of the creature - the row of pendants that is its whole
   silhouette claim - does not survive a 90-degree turn. A plan-angled rail
   would fix it and is not in this pass.
6. **The rail post reads as a pump handle** from the side, which is the wrong
   trade entirely.
7. **The glow does almost nothing against the render's white background.** The
   falling stream and the puddle read; the one half-full flask on the rail does
   not read as lit at all. It may well read on a dark floor - **I have not
   proved that, so it is a fault and not a note.**
8. **The hung flasks read as small tins or canisters**, not glass, at pair
   scale. They carry "a row of vessels" and not much more.
9. **The apron's neck straps end at the shoulder blades attached to nothing**
   in the back view, and the man leans slightly forward over his toes.

### THE INSTRUMENT, AND WHAT IT STILL CANNOT SEE
`minibossgen`: ok true, errors `[]`, blank+border check 0 failures, **4 meshes**
(the bar is four), **2,479 faces**, footprint span 3.04 m, **CORRIDOR-SAFE**
against the 11.0 m three-cell clear span, `pack_used: true`.
`minibossfit --only tapster`: verdict **GREEN**, asked `["tapster"]`, measured
`["tapster"]` - not an empty register - hero 2.45 m `posed: true`, blank check
3 files 0 failures, `unproved_cells: []`, **proving_views 3 of 3** with
`seen: 1.0` for both subjects in all three views.
**THE PORTED OCCLUSION TEST EARNED ITS KEEP AND STILL DID NOT CATCH PASSES 2-4.**
It would have caught a man standing behind his own tun, and that is exactly
what it was built for. It could not see a barrel rendering as torn shards, a
bottle rendering as a slab, or a tap foreshortened to four pixels - every one
of those frames is full of opaque pixels inside its border with both subjects
plainly visible. **Three faults, three passes, found only by looking.**

### WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT, AND I TOUCHED NO .gd
1. `assets/monsters/minibosses/tapster.glb` - **static, no armature**: a
   `model` path and **NO `anims` entry**, same as the other twenty. As with all
   of them there is no `.glb.import` sibling (this lane never runs Godot); an
   import run writes it and `delve.gd:377` falls back safely until then.
2. `scripts/delve.gd` `MB_FIT`: add `"tapster": 1.14` - **MEASURED**, from
   `renders/art/minibosses/_fit_tapster_register.json` `pairs.tapster.ratio`.
   **Do not re-derive it.** Same one-line shape as `"tanner": 1.12`,
   `"loader": 1.08`, `"reeve": 0.80`.
3. The `firepit` set piece can now pick between the Stoker and the Tapster.
4. **The idea is a BEHAVIOUR and this one is a SUPPLY behaviour** - it wants
   `roster.add_brew(h, key, -1)` to land in the creature instead of in the
   hero, not a damage number. Shipped as a re-skin with extra hit points it is
   wasted: the whole promise is a party that cannot heal through it and whose
   own flee rule then takes the floor away from them.
5. Feed line, if one is wanted: *"Something in here is drinking."*

## 22. THE PRESSMAN - *IT PRESSES YOUR FALLEN*
`pressman` - prison - h 2.85 - wear **0.88** - 4 meshes, 1,439 faces -
span **2.61 m, CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **1.16** beside the posed 2.45 m Knight, pair_w 4.47, fits_frame true,
three proving views, every `seen` 1.000. Procedural, no pack geometry
(`pack_used` false). Five passes, 17 Nov 2026, 17:35-19:00 CT.

### WHY THIS ONE, MEASURED THIS RUN - NOT REMEMBERED
- **TWENTY-ONE IDEAS EXIST AND NOT ONE CHANGES WHO IS ON WHICH SIDE.** Parsed
  out of `minibosses.py` CANON by regex, not recalled: summon, self-armour,
  drag a hero out, douse the lamps, will-not-stay-down, bar the door, steal
  gear, heal the pack, raise the water, plant the ground, pre-set the room,
  scale with the fire, ring from elsewhere, set the floor, come apart in two,
  arm the room, weigh you down, cut the room in two, refuse the same blow
  twice, take the haul, drink what you brought. **Conversion - a casualty of
  yours becoming a body of theirs - is a mechanic class the set does not
  have.** The fight gets harder at exactly the rate you are losing it, and the
  counter is a decision (get them up, or break the yoke) rather than more
  damage.
- **THE THREE NEAR NEIGHBOURS, NAMED RATHER THAN WAVED AT.** The DRILLMASTER
  summons, but what arrives is ITS garrison - reinforcement from outside the
  fight. The GAOLER drags a STANDING hero across the floor: a position change,
  and the hero stays yours. The SEXTON will not stay down - that is its own
  body, not yours.
- **THEME `prison`,** off `dungeon_hd.gd:737-743`: the miniboss roll is 35 on
  barracks/workshop, 10 on shrine/crypt, **15 on prison** and every unlisted
  theme. Prison has **exactly ONE body** behind it (the Gaoler), so every
  miniboss a prison floor has ever shown is the same creature. Same argument
  the Loader used for the mess hall and the Tanner for the flooded floor.
- **HEIGHT 2.85 EXTENDS THE TOP OF A FULL LADDER** (1.95-2.80 was taken, in
  0.05s). It is the FRAME that is 2.85 and not the man: the mass is the yoke
  riding above his head, and the man under it is ordinary.
- **WEAR 0.88** sits between the Snuffer's 0.90 and the Gaoler's 0.80, and it
  is the IRONS that justify it, not the coat - the oldest fixed kit on the
  floor and never once out of service. Mr. E's rule 2: condition is the
  receipt, and this one reads USED, CONSTANTLY, BY SOMEBODY ELSE.

### THE FIVE PASSES. EVERY FAULT BELOW WAS FOUND BY LOOKING, NOT BY A NUMBER
The generator reported `ok: true`, 4 meshes, 0 blanks and CORRIDOR-SAFE on
**every one of the five passes, including pass 1**, which was the worst body
this lane has built. The register was never wrong and never useful here: it
measures scale, blanks, frame, corridor and occlusion, and not one of those was
ever the fault.
1. **PASS 1 NAMED ITSELF WRONG.** The far arm ran straight up to a long bar
   with squared ends held overhead, and the creature read as **A MAN PRESSING
   A BARBELL**. For a thing called the Pressman that is not a near miss. The
   arm now comes down onto the chain of the one it has already collared, which
   ties man to yoke the same way and says the mechanic as well.
2. **THE FACE WAS IN A CAGE.** The two yoke uprights stood either side of the
   head with one crossing the chin - a man looking out through bars, which is
   the wrong creature's idea entirely. Outboard to 0.40 and back to y +0.17.
3. **FOUR COLLARS BECAME FOUR STICKS FROM THE SIDE.** I had applied the
   Reeve's pass-2 lesson to the wrong half of the problem: staggering the
   collars 0.14 m in Y separates them *from each other* side-on, but every
   ring was still hung in the front plane, so each one was **edge-on** at
   azimuth 90. A ring is only a ring from a camera that can see into it.
   `_open_ring` now takes a **yaw**, and each collar is turned 38-58 degrees
   off the front plane: an ellipse from both cameras rather than a circle from
   one and a line from the other.
4. **THE SAME FAULT IN TWO COSTUMES - A RING AT THE END OF A LINE IS A TOOL.**
   The already-taken collar was laid flat with a lit plate inside it and read
   as **a frying pan**; stood on edge at the end of a taut chain it became **a
   wheel on a stick - a scooter**. Both times the geometry was an O joined to
   a line. It is now lying on the floor, half behind the boot, with the chain
   falling to the ground first and running along it.
5. **THE COAT TOOK THREE PASSES BECAUSE I KEPT ASKING HOW BIG INSTEAD OF
   WHY.** A 0.40 m cone read as a tub at his hips; narrowed to 0.285 it still
   read as a churn; shortened it still read as a bucket. The fault was never
   the size - **a cone that tapers INWARD with a flat bottom is the shape of a
   vessel**, and cloth does the opposite. Flared (0.270 to 0.355) and falling
   to mid-shin, it is a coat. Pass 3's shortening also fixed a real clip the
   side view had shown: the near shin coming through the coat's front panel at
   the knee.

### THE FIT PROOF - ON A BODY, AND EVERY FAULT I CAN STILL SEE
`renders/art/minibosses/pressman/hero_front.png`, `hero_side.png`,
`hero_back.png`, beside the posed KayKit Knight at 2.45 m. I looked at all
three. He stands a head and a half over the knight, the yoke rides clear above
both, and front and back both count collars. **Eight faults, none of them
hidden:**
1. **THE FLOOR IRON IS NEARLY INVISIBLE FROM THE FRONT** at pair distance - a
   small dark hook shape at the boot. Fixing the scooter read cost it its
   legibility, and that trade is not yet paid for. It reads correctly from
   behind, which is where it is least needed.
2. **THE ONE LIT THING ON THE BODY CANNOT BE SEEN.** The glow ring inside that
   iron is sub-pixel on the pair shot. A body with a glow slot that nobody can
   see has, in practice, no glow.
3. **ONLY THREE OF THE FOUR HANGING COLLARS ARE COUNTABLE FROM THE FRONT** -
   the fourth sits behind the head and the bar.
4. **THE TALLY BOARD IS A BLANK WHITE CARD** at pair distance; its four struck
   lines do not survive. It also reads brighter than anything else on him.
5. **HE IS GREY NEXT TO A GREY KNIGHT.** At wear 0.88 the tint is pulled
   almost neutral, so the body carries no colour of its own against hero
   armour. The Tanner and the Tapster both keep a tint at lower wear; this is
   the cost of the top of the ladder and I am naming it rather than quietly
   lowering the wear.
6. **THE CHAIN HAND IS LOST** against the coat from the front - the hand that
   holds the chain is legible only from the side.
7. **THE LEFTMOST COLLAR OVERLAPS THE BAR'S END BRACKET**, so from the front
   its top arc merges into the ironwork.
8. **THE CAP READS AS A DISC** - a flat lid on a small head, and the head is
   small for the shoulders.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
- `assets/monsters/minibosses/pressman.glb` is committed. **STATIC** - a
  `model` path and **NO `anims` entry**.
- **`scripts/delve.gd` MB_FIT: add `"pressman": 1.16`.** Measured, not
  derived: `renders/art/minibosses/_fit_report.json` pairs.pressman.ratio,
  hero = the posed KayKit knight at 2.45 m. Verdict GREEN, 3 proving views,
  errors [], blind_views [], blank check 3 files 0 failures.
- **MB_FIT is missing three bodies that already shipped**, measured against the
  same file this run: `"tanner": 1.12`, `"reeve": 0.80`, `"tapster": 1.14`.
  `snuffer_chibi` (1.06) is also absent while its sibling chibis are present.
- **CORRIDOR-SAFE at 2.61 m** against the 11.0 m three-cell clear span. No
  spawn gate needed.
- Theme `prison`, feed line "Irons just came off the yoke."
- **NO ROTATION IS HANDED OVER with this body**, so the frame question does not
  arise here. When one is, it will be named as solved in Blender's bone frame.

================================================================================
## 23. THE STRICKLER - treasury, h 2.55, wear 0.12 (2026-11-17, art lane)
### IT STRIKES YOU LEVEL

A strickle is the straight-edged stick a market officer draws across the rim of
a grain measure so that a bushel sold is a bushel and not a bushel and a
handful. This one does it to a party: while it stands, the best hero in the
room is scraped down to the measure of the worst. Your strongest is no answer.
You get your weakest off the floor, or you break the beam he measures against.

**WHY IT IS NOT ONE OF THE TWENTY-TWO - CHECKED BY PARSING `CANON`, NOT BY
MEMORY.** 36 entries, 22 distinct bodies. The set summons, re-plates itself,
drags, douses the lamps, rises from its own graves, bars the door, steals gear,
heals the room, floods it, sows thorns, pre-sets traps, scales with the fire,
throws its voice, sets the floor, splits in two, arms the other monsters, loads
you down, cuts the party in half, learns the blow you used, takes the haul,
drinks the brews and collars your fallen. **Not one of them touches the heroes
RELATIVE TO EACH OTHER.** The Loader weighs everyone down; this one flattens
the DIFFERENCE between them, which inverts who in the party matters. Theme
`treasury`, which had one creature (the Tallyman) against the Prison's three.

### THE SIDE VIEW IS THE POINT OF THIS ONE, AND IT IS MEASURED, NOT CLAIMED
The lead's note on the Pressman was the brief: its trade reads from the front
and collapses to a narrow post from the side. A horizontal element can only be
read from the camera it is NOT pointing at, so one horizontal can never carry
both views. This creature carries **TWO, AT RIGHT ANGLES**:

| element | axis | carries |
|---|---|---|
| **THE STRICKLE** - 1.48 m straight-edge across the measure's rim, both hands | model **X** | the FRONT |
| **THE BEAM** - 2.00 m balance on one standard, pan hanging fore, weights aft | model **Y** | the SIDE |

`tools/art/_trade_read.py` (new, this run) answers the viewer's question the
only way that works: it renders the creature **through one fixed camera** with
a group present and again with it removed and counts the pixels that MOVED.
The framing is computed ONCE from the whole creature and never recomputed - a
re-derived camera would shift the frame and read every pixel as moved. This is
the same correction that caught the Reeve's `head_glow_px: 156` standing beside
the sentence "the head has no face at all": `mask_of` renders a group ALONE and
so answers how BIG it is, never whether it can be SEEN.

**TRADE SHARE OF THE SILHOUETTE, three creatures, same instrument, same run:**

| creature | front | side | **side / front** | back |
|---|---|---|---|---|
| **STRICKLER** | 0.603 | **0.675** | **1.12** | 0.381 |
| TAPSTER | 0.713 | 0.755 | 1.06 | 0.705 |
| PRESSMAN | 0.415 | 0.332 | **0.80** | 0.485 |

The lead's eye and the instrument agree: the Pressman's side carries a fifth
less of its trade than its front. The Strickler's side carries **more** than its
front, which is what the row asked for. Per group, side view: beam 0.369, pan
0.102, weights 0.090, measure 0.081, strickle 0.033 - the strickle all but
vanishes from the side and the beam pays for it, exactly as designed.

**WHAT THIS NUMBER CANNOT SEE, SAID BEFORE THE NUMBER IS BELIEVED.** It
measures how much of the outline the trade geometry OWNS. It does not and
cannot measure whether a viewer NAMES the shape correctly - a derrick and a
balance can own the same share. Only the picture answers that, and I looked at
all six.

**THE INSTRUMENT IS PROVED ABLE TO GO RED**, which is this lane's own standing
rule after measuring a ratio over zero pairs and calling it green. Run against
`drillmaster,nosuchthing` it returned `ok: false` with
`"drillmaster: builder exposes NO spans - nothing to measure"` and
`"nosuchthing: no builder"`. It also fails on a silhouette under 400 px, on an
empty span, and reports any trade group that moves nothing in every view.

### THE BARREL LESSON APPLIED, NOT JUST RECORDED
The measure is `Bucket_Wooden_1` and the weights are three `Pouch_Large`, both
CC0 Fantasy Props MegaKit meshes already on disk. They go through a NEW
`_prop_mesh_m`, which reads the **primitive and triangle counts off the .gltf
JSON before anything is imported** (`Bucket_Wooden_1` 976 tris / 2 prims,
`Pouch_Large` 730 / 2) and caps by the model and its placed size, refusing any
budget that would drive a single primitive below `PRIM_FLOOR = 72`. Both
therefore shipped at full density. That is the whole of the 17:42 finding: the
Barrel tore because OUR fixed 110-face cap is a 0.1335 collapse on an
824-triangle two-primitive cask, not because the model was built badly.
`_prop_mesh_m` is a SEPARATE function and not an edit to `_prop_mesh`, so the
Tapster's shipped mesh does not move while the rule changes under it.

### THE FIT PROOF - I LOOKED AT ALL SIX RENDERS
`renders/art/minibosses/strickler/` - `front`, `side`, `three_quarter`,
`hero_front`, `hero_side`, `hero_back`.
`MINIBOSSFIT_REPORT` **verdict GREEN**, `ok: true`, ratio **1.04** beside the
posed 2.45 m KayKit Knight, pair_w **3.67**, `fits_frame: true`, **3 proving
views**, `errors: []`, `blind_views: []`, blank check **3 files / 0 failures**.
`MINIBOSSGEN_REPORT` `ok: true`, blanks `[]`, **span 2.99 m CORRIDOR-SAFE**
against the 11.0 m three-cell clear span, 4 meshes, **3,642 faces**.

### EVERY FAULT I CAN SEE. NINE, AND THE FIRST THREE ARE REAL
1. **FROM THE FRONT THE BALANCE READS AS A DERRICK, NOT A BALANCE.** The beam
   foreshortens to a stub and what is left is a post with two trays stacked
   above each other. It is apparatus; it is not legibly a pair of scales. This
   is the designed trade-off (the front is the strickle's view) but it is a
   cost and the instrument cannot see it - only my eyes can.
2. **THE HEAP IS INVISIBLE FROM THE FRONT.** The handful of grain standing
   proud of the far rim - the thing about to be struck off, and the clearest
   statement of the mechanic - sits behind the strickle from the front camera
   and behind the measure's near wall from the side. It is readable in the
   three-quarter only. Measure share is 0.096 front / 0.081 side and the heap
   is a small part of that.
3. **THE STANDARD STILL READS PART-FREE-STANDING** from the side despite the
   shoulder strut and the belt collar added in pass 2. Its own foot plate on
   the floor beside his boots is what does it.
4. **THE RIGHT ARM IS LARGELY OCCLUDED** from the front by the post and pans.
5. **THE STRICKLE'S RIGHT THIRD PASSES BEHIND THE POST** - occlusion, not a
   clip; its end grip re-emerges past the ironwork.
6. **THE LIT TRUE LINE IS WEAK.** The glow strip along the strickle's underside
   reads as a pale edge rather than a lit line at any distance.
7. **THE BACK IS THE WEAK VIEW AND I AM NOT HIDING IT** - trade share 0.381,
   half of it the beam. The measure is carried in front of the body and owns
   0.007 of the back silhouette, i.e. nothing.
8. **THE SEAL AT THE LEFT HIP READS AS A SMALL LADLE** from the front.
9. **3,642 FACES IS THE HEAVIEST BODY IN THE FILE** (next is the Quartermaster
   at 2,804), and the cause is my own new cap rule shipping four pack meshes
   whole rather than tearing them. I would rather carry the faces than the
   shards, and I am naming the number instead of quietly decimating.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
- `assets/monsters/minibosses/strickler.glb` is committed. **STATIC** - a
  `model` path and **NO `anims` entry**.
- **`scripts/delve.gd` MB_FIT: add `"strickler": 1.04`.** Measured, not
  derived: `renders/art/minibosses/_fit_report.json` `ratios.strickler[0]`,
  hero = the posed KayKit knight at 2.45 m.
- **STILL MISSING FROM MB_FIT, re-measured off the same file this run:**
  `"tanner": 1.12`, `"reeve": 0.80`, `"pressman": 1.16`. `"tapster": 1.14` was
  wired at S23. `"snuffer_chibi": 1.06` - see the answer below.
- **FOUR .glb FILES HAVE NO `.glb.import` SIBLING**: `strickler`, `pressman`,
  `reeve`, `tapster`. They cannot load until a Godot run generates one. The
  game build's own runs have generated every previous one (snarer_chibi now has
  its sibling), so this is a note, not a block.
- **CORRIDOR-SAFE at 2.99 m** against the 11.0 m clear span. No spawn gate.
- Theme `treasury`, feed line "Something in here is taking the heap off."
- **FRAMES.** No rotation is handed over with this body. Every number in the
  builder is in **Blender's world frame as written into the .glb** - front is
  model **-Y**, the strickle lies along model **X**, the beam along model **Y**,
  up is **+Z**. That is NOT the engine's slot frame; nothing here should be
  pasted into a Godot rotation without converting it.

### THE TWO ONE-SENTENCE ANSWERS THE LEAD HAS ASKED FOR FIVE HOURS
**(1) `snuffer_chibi.glb` - MEANT TO BE WIRED, AND IT ALREADY IS.** I read
`delve.gd:379` rather than guessing: `miniboss_model()` walks
`[key + "_chibi", key]` and returns the first that exists, so `snuffer_chibi.glb`
- which is on disk WITH its `.glb.import` - is already loaded in preference to
the base body; the only thing missing is an `MB_FIT` entry, and because
`miniboss_ratio` falls back to `MB_FIT["snuffer"] = 1.06` and art's measured
`snuffer_chibi` ratio is also 1.06, the number it gets today is right **by
coincidence rather than by design**, so adding `"snuffer_chibi": 1.06` makes it
deliberate. Nothing is blocked either way.

**(2) THE TANNER OBSERVATION - THE LEAD IS RIGHT, AND I AM DECLINING THE
REDESIGN.** The Tanner's body does read as a knight and its trade does live in
the prop beside it; I accept that as true rather than arguing it. I am not
re-cutting a shipped, ticked, wired body for silhouette share under the freeze -
what the observation is worth is the RULE it produced, which is now in force on
every new body: the trade must OWN the outline rather than stand next to it, and
that claim is measured per view by `_trade_read.py` before anything ships.

---

## 24. THE DYER - *IT MARKS ONE OF YOU AND HUNTS ONLY THE MARK*
*17 Nov 2026, art lane. Seven passes. Theme `workshop`, height 2.60 m, wear 0.30
(split - see below). `assets/monsters/minibosses/dyer.glb`, 4 meshes, 2,294 faces.*

### THE BRIEF, AND I MEASURED IT BEFORE I AGREED WITH IT
The team lead, 18:58 CT: *"the strickler is the most MUTED thing in the
twenty-three ... if a twenty-fourth can carry its trade in COLOUR as well as
silhouette, that is worth more to me than a twenty-fifth."*

A tint table cannot answer that, so I did not use one. **HSV saturation of every
opaque lit pixel of each of the 23 distinct bodies' own shipped `front.png`,
chroma-weighted hue:**

| | |
|---|---|
| median satMean | **0.087** |
| maximum | **0.207 - the DRILLMASTER, the first one ever made** |
| the STRICKLER | **0.052 - RANK 1 OF 23, the least saturated body in the file** |
| hue 0-60 deg | 14 bodies |
| hue 60-110 | 2 |
| hue 110-190 | **ZERO** |
| hue 190-260 | 7 |
| hue 260-360 | **ZERO** |

He is right, and right by the measurement rather than by impression. Half the
hue wheel is empty across twenty-three bodies, and the register's colour has
been going DOWN, not up: of the nine most recent bodies not one exceeds 0.36 in
the tint table or 0.151 in the render.

**AND THE TINT TABLE DISAGREES WITH THE PICTURES, WHICH IS THE REAL FINDING.**
`CANON` gives the Tallyman HSV saturation **0.66**; its shipped render measures
**0.136**. Anyone judging this register's colour off `CANON` is judging the
wrong number.

### THE STRUCTURAL CAUSE IS A DEFECT IN MY OWN GENERATOR
`minibossgen.build_miniboss` derived **all four materials from one tint**: body
is the tint mixed with the aura, `dark` is 0.16 x body, `bone` is the tint pushed
toward white, `glow` is the aura normalised. **Every body in this file was
monochrome BY CONSTRUCTION.** No builder in twenty-three could have carried two
hues even if it had wanted to. That is not a taste problem, it is a pipeline
problem with my name on it.

`minibosses.OVERRIDE` + `apply_overrides()` let a key declare its own per-slot
materials. It is **asserted empty for every pre-existing key** (the assertion is
in `build_miniboss`, so the run fails loudly if anyone ever points it at a
shipped body), so the twenty-three render exactly as before. The four-mesh cap
is untouched: four slots, four materials, four meshes. `_trade_read.py` and
`_colour_read.py` both call it, so all three harnesses measure the materials
that actually ship.

### THE IDEA, AND WHY IT IS NOT ONE OF THE TWENTY-THREE
**IT MARKS ONE OF YOU AND HUNTS ONLY THE MARK.** It slings the vat. While the
stain is wet it walks past the tank, past the healer and past whoever is hitting
it hardest to reach the one wearing the mark - and the stain is **passed hero to
hero by touch.** The party is not choosing how to kill it; it is choosing who
carries the mark, for how long, and who is standing close enough to take it next.

Checked by **parsing `CANON`**, not by remembering it: 38 entries, 23 distinct
bodies. They summon, re-plate, drag one out of the line, douse the lamps, rise
from their graves, bar the door, steal gear, heal the room, flood it, sow
thorns, pre-set traps, scale with the fire, throw a voice, set the floor, split
in two, arm the other monsters, load you down, cut the party in half, learn the
blow you used, take the haul, drink the brews, collar your fallen and strike the
party level. **Two touch targeting and neither is this.** The Gaoler takes a
choice away - it hooks who *it* picks. The Hurdleman divides the room by
geometry. This one hands the choice **to** the party and makes them keep making
it. It is the only mechanic in the file the players themselves operate.

### THE COLOUR IS THE TRADE - NOTHING HERE IS DECORATED
A dyer is the one working man in a town whose **job** is colour. Woad is blue,
madder is red, weld is yellow. They are on the frame because that is what a
dye-house hangs out to dry; on his arms because that is what the work does to a
man to the elbow; and the vat is emissive because an open vat of hot dye over a
fire genuinely gives off light. If this creature were grey it would be a man
standing **next to** a trade instead of wearing it - which is the rule the
Tanner observation produced.

### THE READ: **A MAN AT A VAT UNDER THREE HANGING SHEETS**
Nothing in the other twenty-three has a broad hanging plane in it at all.

The frame is **turned 28 degrees about Z on purpose**, and that is the
Strickler's right-angle lesson applied to a worse case. A horizontal can only be
read from the camera it is not pointing at; **a flat sheet is a LINE from one
side.** Rather than hang six sheets, the frame is rotated so neither camera is
normal or tangent to it, and each sheet is **bowed in Y with the bow growing
toward the hem**, because a wet sheet hangs heavy and swings out. Measured, not
asserted.

### WEAR 0.30, AND IT IS SPLIT - THE REGISTER HAS NOT DONE THAT BEFORE
The frame, the vat staves and the man are worked and wet; that is what 0.30 buys
through the roughness and metal terms. **The cloth is not worn at all** - the
sheets, the apron and the skeins take their colour from `OVERRIDE` and skip the
dulling entirely. Mr. E's second rule read as he wrote it: a dyer's goods are the
one thing in his yard that must look **new**, because they are what he is
selling. The receipt and the man disagree, which is true of every tradesman who
ever lived.

### THE SEVEN PASSES, AND WHAT EACH ONE BOUGHT
| pass | change | what the picture showed |
|---|---|---|
| 1 | first build | **I had capped my own vat** - a `dark` disc lid over the `glow` surface, and at 2 deg camera pitch a surface sunk inside a 0.80 m rim is invisible from any eye-level camera anyway. `ok:true, 0 blanks, 0 clips` - a hidden thing is not a blank one. **This lane's own trap 5, committed again.** |
| 2 | the vat brims | Fixed by making it **true** rather than by moving the camera: a working vat stands proud of the rim and goes over the side. |
| 3 | A weld hue; B vat 0.60->0.52; C man out of the sheets, shoulders 0.155->0.115; D paddle off his face; E skeins to the hip | A: at emissive strength 2.30 the weld came back **cream** - an emissive that clips to white is a white hole, not a third hue. C: he had read as **two heads**. |
| 4 | F braces rake back; G both hands put ON the shaft | **G was a float I shipped into the pass-3 picture** - the paddle started in clear air 0.38 m from his head while both arms hung at his sides. The shaft is now one line defined by two points and the hands are placed **on it by parameter**, so the grip cannot drift again. |
| 5 | H paddle Y travel restored; I belt; J near brace deleted; K vat 0.52->0.45 | **H was a regression I introduced at pass 4** - rewriting the shaft gave it 1.86 m of X travel and **six centimetres of Y**, so from the side the one long diagonal was a vertical post: the exact Pressman fault. |
| 6 | L man steps 0.40 m forward | Only the side camera could show it: the drum covered him **to the chest**. |
| 7 | **the eyes** | See below. |

### *** PASS 7: A FAULT THAT GOT PAST EVERY CHECK THIS LANE HAS ***
Two `glow` spheres sat at y -1.66 against a face whose front surface is at
y -1.43 - **the eyes were floating 23 cm in front of his head.** I had passed the
head's own forward offset in `loc` *and* passed `fwd` on top of it.

- the **front** camera put them on the face by projection and they looked perfect
- the **blank** check saw opaque pixels and passed
- the **border** check saw nothing at the frame edge and passed

**A FLOATING PIECE IS NEITHER BLANK NOR CLIPPED**, so no instrument this lane
owns could ever have caught it. It was found by connected-component analysis of
the side silhouette: one stray 52-px component, mean RGB (0.79, 0.70, 0.46).
I then tested it against the removal of **every** trade span - it survived all
five, so it was not the skein I had assumed - and only then named it.

`_colour_read.detached()` now counts silhouette components on every view and goes
RED on any stray over 12 px. Intentional detachment (a thrown thing, a chain
link) is allowed but must be **named**, because the whole fault was that nobody
was told. The Dyer is now **1 component in all three views.**

**AND IT IMMEDIATELY FOUND TWO FAULTS IN SHIPPED, TICKED BODIES** (controls in
the same run, not sought out):

- **THE DRILLMASTER** - `808 px` detached, front and side. **I looked at the
  render: it is the baton in his left hand, hanging in clear air below the
  fist.** This is the first miniboss ever made, it is wired and in the game
  (D96), and nobody has ever reported it.
- **THE TANNER** - `96-102 px` detached in all three views; from the bounding
  box it is a rivet off the rack frame. Small, but the same class.

**I HAVE NOT RE-CUT EITHER.** Both are shipped, ticked and wired, and the
Strickler precedent holds: I do not re-cut a ticked body under the freeze on my
own say-so. Both are one-line fixes and I will take them the moment the lead
says so. **Neither is a reason to re-open D96.**

### THE COLOUR PROOF - `tools/art/_colour_read.py`
Renders through the **shipping materials** and measures pixels; nothing in it
reads `CANON` for a colour. It goes RED on a silhouette under 400 px, on zero
chroma pixels (BLIND), on a band computed over an empty population, and on any
detached component. **The bar is the register's own measured maximum**, so the
test is "more colourful than anything we have", not "has a colour". It also
fails the whole run if **every control passes**, because a bar that
discriminates nothing makes no PASS in that run evidence.

```
COLOUR_READ   bar sat_mean > 0.207, bands_held >= 2
  dyer          PASS   sat 0.4576 > 0.207 ; bands 2 >= 2      (judged)
  drillmaster   FAIL   sat 0.2456 > 0.207 ; bands 1 < 2       (control)
  tanner        FAIL   sat 0.1051 <= 0.207; bands 1 < 2       (control)
  strickler     FAIL   BLIND - zero chroma pixels, all 3 views (control)
```

| view | sat_mean | sat_p90 | blue | red_orange | components |
|---|---|---|---|---|---|
| front | **0.4576** | 0.734 | 0.624 | 0.374 | 1 |
| side | 0.3216 | 0.662 | 0.707 | 0.293 | 1 |
| back | 0.5224 | 0.827 | 0.721 | 0.277 | 1 |

**5.3x the median of the twenty-three, and 2.2x the most colourful body in the
file** - and the Strickler, the body the lead called the most muted, does not
merely score low, it **cannot be measured**: its maximum chroma over the whole
silhouette is 0.0353, under the 0.04 threshold at which a pixel counts as
coloured at all. That reading was checked against an **independent reader** (PIL
on the Linux side, sRGB bytes) before it was believed, because it disagreed with
my own earlier census - the two agree to four decimal places.

**ONE HONEST QUALIFICATION.** The body carries three hues *by eye* - woad,
madder, weld - but the instrument's 60-degree band cut puts **madder (~8 deg)
and weld (~40 deg) in the same band**. So it is **two bands, three hues**, and
the `bands >= 2` pass is the weaker of the two claims. The `blue` band at 0.62 is
the one that is new: before this body, seven bodies held hue 190-260 and every
one of them was a desaturated grey-blue.

### THE TRADE PROOF - `tools/art/_trade_read.py`
Does the trade own the outline, per view, measured by rendering with and without
each group through one fixed camera and counting the pixels that **moved**.
`ok: true, errors [], blind []`.

| | front | side | back |
|---|---|---|---|
| **dyer** trade share | **0.748** | **0.580** | 0.724 |
| strickler | 0.603 | 0.675 | 0.381 |
| pressman | 0.415 | 0.332 | 0.485 |

The Dyer's trade owns **three quarters of the front silhouette** - the highest
of the three in the front and the back, and its *side* share alone is higher
than the Pressman's *front*. **It does NOT beat the Strickler on side-to-front
balance** (0.775 vs 1.12) and I am not going to claim it does; the Strickler is
still the body that reads most equally from both sides. This one wins on
absolute share in every view, which is a different thing.

Per-group front shares: sheets 0.494, vat 0.151, skeins 0.050, paddle 0.043,
splashes 0.011. No group is blind in any view.

### THE FIT PROOF - ON A REAL BODY, AND EVERY FAULT I CAN SEE
`minibossfit.py`, posed **KayKit Knight.glb at scale 1.0**, `_fit_dyer_register.json`:

```
MINIBOSSFIT verdict GREEN, ok true, errors [], blind_views []
  ratio 1.06   (creature 2.60 m / hero 2.45 m)   pair_w 4.69 m   fits_frame true
  proving views 3 of 3   front/side/back, each: creature seen 1.000, hero seen 1.000
  blank check: 3 files, 0 failures
  footprint 3.39 m against the 11.0 m three-cell clear span - CORRIDOR-SAFE
```

**I LOOKED AT ALL THREE.** `renders/art/minibosses/dyer/hero_front.png`,
`hero_side.png`, `hero_back.png`. The faults I can see, and there are eight:

1. From the side the creature reads as **two groups with a metre of air between
   them** - man-and-vat, then the frame. It is depth and it is physically right,
   but it reads as a gap and I am naming it rather than explaining it away.
2. His dark torso **merges with the dark vat** where they overlap at his knee.
3. Only **two of the three skeins read** at hero scale - the woad one sits on
   the woad apron and disappears into it.
4. The paddle **blade is inside the vat** and is never visible. Intended - a
   paddle in use has its blade in the dye - but it means the paddle reads as a
   pole, not as a paddle.
5. The red floor splash sits **partly under his boots** in the front view.
6. From the **back** the man is almost entirely behind the sheets; the back view
   is the frame's view, not his.
7. The single far-side brace **extends the side footprint** to 3.39 m. Safe
   against 11.0 m, but it is the widest thing on the body and it carries no
   meaning.
8. At hero scale his **head is a few pixels**; the cap and one glow eye carry
   the whole figure. It works, but there is no margin in it.

### FRAMES
Every number in the builder is in **Blender's world frame as written into the
.glb** - front is model **-Y**, up is **+Z**, the crossbar lies along the frame's
own rotated X, the paddle runs from (-1.62, -1.30, 2.06) to the vat. **That is
not the engine's slot frame** and nothing here should be pasted into a Godot
rotation without converting it.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
1. `assets/monsters/minibosses/dyer.glb` is committed **with no `.glb.import`
   sibling** - it cannot load until a Godot run generates one. The same is true
   of `pressman.glb`, `reeve.glb`, `strickler.glb` and `tapster.glb`: **five
   bodies, measured this run, not remembered.**
2. `scripts/delve.gd`, `MB_FIT`: add `"dyer": 1.06`. Measured by art
   (`_fit_dyer_register.json` -> `pairs.dyer.ratio`), **copy it, do not
   re-derive it.** Still outstanding from previous hours and re-issued here:
   `"pressman": 1.16` and `"strickler": 1.04`.
3. `scripts/bestiary.gd`: **static** - a `model` path and **no `anims` entry.**
4. Theme `workshop`, the third body on that theme. **It cannot spawn today** -
   the `THEME_MINIBOSS` gate in `dungeon_hd.gd` has all fourteen themes taken.
   That is engine work and a design call, it sits with the supervisor, and this
   body is queued work like the other nine.
5. Feed line for content: *"Something back there just marked one of you."*

### LICENCE
100% original procedural geometry (`bmesh`-free raw vertex maths via `lordlib`).
No pack asset is read by this body. `used_pack: false`.

---

## 25. THE GREENER - the twenty-fifth, and the trade is ON THE BODY
*Built 17 Nov 2026, 20:35-21:05 CT, on the team lead's 20:14 row.*

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `greener` | The Greener | 2.50 | workshop | **IT GREENS YOUR IRON** - every blow landed on it eats the weapon a little more, and a bitten weapon bites less; a hero can stop and scrape it clean, which costs them the swings they would have taken | 0.55 |

**THE ROW, in his words:** *"If a twenty-fifth can put the trade ON THE BODY
rather than on the furniture around it, that is worth more to me than a
twenty-fifth with better props."* His read of the Dyer was that the frame and
the tun carried the trade and the man beside them was a dark armature.

**WHY A GREENER AND NOT A PRETTIER TRADE.** `_colour_read`'s own hue histogram
over the register: 0-60 deg **14 bodies**, 60-110 **2**, 110-190 **ZERO**,
190-260 **7** (the Dyer's woad), 260-360 **ZERO**. A beekeeper was the first
candidate and was dropped *because honey is 0-60*, where fourteen bodies already
sit - a new body in an old colour. Verdigris is the one working-class trade
whose **product** is green: copper hung over vinegar and scraped off as pigment,
and a man who has done it twenty years is green to the elbow. **This is the
first body in the register to hold 110-190.**

### THE NUMBERS, AND ONE OF THEM OVERTURNED MY OWN PICTURE
`_trade_read` renders the body through one fixed camera with a group present and
again with it removed, and counts the pixels that **moved**.

| pass | crust (ON HIM) | plates | brazier | scraper | taken | front total |
|---|---|---|---|---|---|---|
| 7 | **0.0439** | 0.1518 | 0.1809 | 0.1316 | 0.0455 | 0.6666 |
| 9 (shipped) | **0.1889** | 0.1526 | 0.2003 | 0.1290 | 0.0426 | 0.7134 |

At pass 7 I was looking at the picture and calling the row delivered. **The
instrument said the yard was carrying 44% of the silhouette and the trade on the
man was carrying four per cent** - exactly the fault this body exists to fix.
`minibossfit` went RED in the same run (`pair_w` 5.61 against a 5.60 m frame):
one cause, two reports. Pass 8 **deleted the crocks**, pulled the fire in, and
grew the crust; crust 0.0439 -> 0.1889, footprint 3.75 -> 2.71 m, fit GREEN.

**SHIPPED:** `_fit_greener_register.json` ok true, verdict **GREEN**, creature_h
2.50 / hero_h 2.45, **ratio 1.02**, pair_w 4.57, fits_frame true, three proving
views at seen 1.000, errors [], blind_views [], blank check 3 files 0 failures.
Footprint **2.71 m, CORRIDOR-SAFE** against 11.0 m. **Four meshes, 5,743 faces** -
the heaviest body in the file, and the crust is why.
`_colour_read`: **green_teal 0.464 / red_orange 0.535** front, two bands held in
all three views, sat_mean 0.271 against the 0.207 bar.

### WHAT I GOT WRONG, IN ORDER, BECAUSE THE PATTERN IS THE FINDING
**I hid my own emissive FOUR TIMES in one body.** Pass 2 put the charcoal bed
*under* the crocks - invisible. Pass 3 made it hotter and wider - a peach
puddle. Pass 4 made it lumps on open floor - eleven salmon balls a viewer names
as fruit. Pass 5 gave it a dark pan and **the pan's own rim closed over it** at
this 2-degree camera pitch, which is the Dyer's cone lid wearing a new shape.
**The thing I kept getting wrong was not colour, strength, size or contrast: it
was HEIGHT.** An eye-level camera cannot see *into* anything lying on the floor
plane, so no floor-level emissive in this register can be seen however it is
dressed. Pass 6 put the fire in a basket on legs at hip height and it read at
once. That is a standing lesson for the next body, not a note about this one.

**And `_colour_read` caught a float I could not see:** a 435 px detached
component at mid-height in the side view. The arithmetic said why - a crust
nodule offset 0.72 x its run radius sits 0.09 m off the limb axis while the
smallest nodules are 0.078 m across, so the thin end of a run could clear the
member it is supposed to be growing on. Offset cut to 0.52; the component is
gone. Same check that caught the Dyer's eyes hanging in front of its face.

### THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE
`renders/art/minibosses/greener/{front,side,three_quarter}.png` and the register
pair in `renders/art/minibosses/_pair_greener.png`.
1. **The copper leaves still read as brown planks**, not metal. Three separate
   changes at it (E, J, pass 5) and the hue, roughness and metalness all moved;
   the stack still reads as timber or cardboard at a glance. **Open fault, not
   fixed, and it is the weakest thing on the body.**
2. **The coals read as bread rolls.** They read as *hot* and they are clearly
   fire in an iron basket, but the lumps are too round and too pale to be
   unmistakably charcoal.
3. **The crust is clumpy on the arms** after pass 8 - both forearms read as one
   continuous green mass that merges into the chest. It carries the trade, which
   was the row, but it has overshot toward bubble-wrap.
4. **From the BACK the trade nearly vanishes**: crust 0.0609 against plates
   0.3293 - the rack of leaves covers the shoulder-blade crust I added at pass 3
   for exactly that view. The back view is the stock's view, not the man's.
5. **The silhouette is in 3-4 pieces** in every view. These are the floor pieces
   by construction - the greened sword (2,172 px), the axe head, and the two
   curls of scraped green off the blade (197 px each). Named, not swept; the
   shipped Drillmaster fails the same check for the same reason.
6. The apron is **mostly behind the crust** now and barely reads as leather.
7. The scraper's blade ends **among the brazier's legs** in the front view.

### FRAMES
Blender's world frame as written into the .glb - front is model **-Y**, up is
**+Z**; the scraper runs (MX-1.18, MY-1.02, 2.26) to (MX+0.86, MY+0.52, 0.42).
**Not the engine's slot frame.**

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
1. `assets/monsters/minibosses/greener.glb` is committed **with no `.glb.import`
   sibling** - it cannot load until a Godot run generates one. Same as
   `dyer.glb`, `pressman.glb`, `reeve.glb`, `strickler.glb`, `tapster.glb`.
2. `scripts/delve.gd`, `MB_FIT`: add `"greener": 1.02`. Measured by art
   (`_fit_greener_register.json` -> `pairs.greener.ratio`) - **copy it, do not
   re-derive it.** Still outstanding and re-issued: `"dyer": 1.06`,
   `"pressman": 1.16`, `"strickler": 1.04`.
3. `scripts/bestiary.gd`: **static** - a `model` path and **no `anims` entry.**
4. Theme `workshop`, the fourth body on that theme. **It cannot spawn today** -
   `dungeon_hd.gd`'s `THEME_MINIBOSS` gate has all fourteen themes taken. Engine
   work plus a design call; this body is queued work like the others.
5. Feed line for content: *"Your edge came back green."*
6. **THE MECHANIC IS NOT BUILT AND NOTHING HERE BUILDS IT.** Weapon wear plus a
   scrape action is a new mechanic, and the standing rule from D97's forty shape
   lines holds: skew and flavour are honoured, a trick waits for a feature item
   that does not exist. Two adjacencies named rather than denied - the **Tanner**
   also answers your blows but changes *itself*, and the **Scrapwright** degrades
   its *own* shell. This is the only one whose arithmetic lands on the hero's
   side of the fight, and the only one a hero can undo by spending time.

### LICENCE
100% original procedural geometry via `lordlib` raw vertex maths. No pack asset
is read by this body. `used_pack: false`.

---

## THE DYER'S SIDE VIEW - the one line the team lead asked for at 20:14
*"do the dyer's hung cloths survive the SIDE view, or do flat planes disappear
edge-on? The register says three views prove at seen 1.000, so I expect yes - I
am asking because I only looked at one."*

**THEY SURVIVE, AT 60% OF THEIR FRONT STRENGTH.** Measured, not expected -
`_trade_read` on `dyer`, which had never been run on it:

| view | sheets | vat | paddle | skeins | splashes | trade total |
|---|---|---|---|---|---|---|
| front | **0.4942** | 0.1510 | 0.0426 | 0.0499 | 0.0105 | 0.7482 |
| side | **0.2947** | 0.2064 | 0.0357 | 0.0316 | 0.0116 | 0.5800 |
| back | **0.5761** | 0.1123 | 0.0285 | 0.0025 | 0.0044 | 0.7238 |

The sheets move **29.5% of the side silhouette** - not a line, not a sliver, and
not a collapse. The 28-degree turn on the frame and the Y bow in `_cloth` (which
grows toward the hem) are doing what they were built to do. **Side/front on the
whole trade is 0.775**, and the vat picks up part of what the sheets lose
(0.2064 side against 0.1510 front), which is the frame turn working in reverse
for the near object.

### FAULT 1 (the copper leaves) - PASSES 8 AND 9, 17 Nov. STILL OPEN, HALF FIXED.
The leaves do not yet read as copper and this is not a tick. What changed:
  - THE CAUSE WAS FORM, NOT MATERIAL. At w 0.46 on a 0.095 pitch the five
    leaves overlapped by ~80% and read as ONE SOLID PANEL with seams - a crate
    side. Pass 8 spreads the pitch to 0.175, varies each leaf's width and
    height and staggers the tops, so they read as five sheets in a rack.
  - THE MATERIAL DIAL THE LANE KEPT USING WAS BACKWARDS. A metallic lobe is
    tinted by the base colour and this rig's world is near black, so every step
    toward "more metal" made a dead plate. Pass 9 goes dielectric instead -
    metal 0.52 -> 0.06, specular level 0.92, roughness 0.13 -> 0.44. Hue is
    untouched; it was never the fault.
  - Measured against the CC0 KayKit dungeon weapons as an outside bar, all
    three views moved from at-or-below a matte-oak control to above it
    (front -0.15 -> +0.159, side -0.15 -> +0.203, back -> +0.035; artist metal
    = 1.00). The verdict line still reads TIMBER.
  - Full working, the two abandoned metrics and the named next change are in
    docs/art/METAL_READ.md. Fit unchanged: GREEN, ratio 1.02, pair_w 4.57,
    three proving views, errors [], footprint 2.71 m CORRIDOR-SAFE.

## 26. THE MOULDER - *IT TAKES YOUR SHAPE* (2026-11-18, art lane)

| key | title | h | theme | the one idea | wear |
|---|---|---|---|---|---|
| `moulder` | The Moulder | 2.90 | firepit | **IT TAKES YOUR SHAPE** - it presses one of your heroes into its sand bed and pours, and what stands up out of the box fights with that hero's reach and that hero's swing | 0.26 |

Feed line: *"It took a copy of one of you."*

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED
The plan's 00:58 CT row says twenty minibosses exist. **It is twenty-five**, counted
off the tree: `assets/monsters/minibosses/` holds 25 base `.glb` (plus 11 `_chibi`).
I parsed all 25 idea strings out of `CANON` rather than trusting a list, and grepped
this file for *reflect / returns the blow / takes your shape / copy*: **zero hits**.
The spent mechanic classes are summoning, self-defence, positioning, your gear,
perception, scaling, targeting, the fallen, splitting itself, and healing the room.

**NOTHING IN THE SET MAKES THE PARTY FIGHT ITSELF.** That is the empty class and it is
the one where the threat is AUTHORED BY THE PLAYERS: bring your heavy hitter and you
will be fighting your heavy hitter. It is **not** the Drillmaster or the Quartermaster
- those call or arm the room's own monsters and the party has no say in what turns up.
It is **not** the Jointer - the Jointer halves *itself*, and neither half is anybody's
hero. The counter is to decide who it is allowed to read, and to break the mould before
the metal sets.

### SEVEN PASSES, ONE CHANGE EACH, EVERY ONE DRIVEN BY A PICTURE
1. **Build.** 4 meshes, span 1.95 m, CORRIDOR-SAFE, 0 blanks. Looked at it: every
   emissive element - pour, seam, crucible mouth, the man's eyes - read as **pale tan
   sticks**. Wood, not metal at heat.
2. **Glow material.** See the A/B below. (1.000, 0.425, 0.105) @1.60 -> (1.000, 0.120,
   0.012) @0.80.
3. **Five form changes**, measured only as a group and labelled as such: the blade's
   thin axis swapped (the side camera looks along X and was getting the blade's broad
   face - a pale slab hiding the cast); the parting seam moved from the chest centre,
   where it read as a strap, to the two side edges where a cope-and-drag flask actually
   splits; the man's eyes from r 0.030 to 0.048 with a brow, because he had no face at
   all - the Greener's fault, shipped a third time; the hung castings put on real pegs
   (they read as keyholes); the floor sprue broken in two (it read as a spoon).
4. **THE CAST REBUILT TO THE HERO'S OWN PROPORTIONS.** Only the on-body render could
   find this: `_moulder_register.png` put the cast beside a posed KayKit adventurer and
   **the hero is a chibi and my cast was not**. A creature whose one idea is IT TAKES
   YOUR SHAPE had taken a shape that is not yours. Every gate passed it.
   `tools/art/_moulder_chibi_probe.py` measures the body through
   `minibossfit.import_hero`: head block **55.3%** of h, body 37.4%, legs 21.3%, widest
   head 1.14, arm span 1.32. Every z and width in the cast is now that table mapped
   through `z = FEET + (z_hero/2.45)*HC`.
5. **The copy made hero-sized.** At pass 4 its head broke the dashed hero rule - the
   copy was taller than the hero it copies. `HC` is now the hero's measured 2.45 m
   exactly; its feet sit at 0.45, buried, which is why it still rides higher on the
   sheet. FEET + HC = 2.90, so the idea sets this body's height and the blade no longer
   does.
6. **The flask dropped 0.28.** A chibi head is as deep as it is wide (1.14 x 1.017), so
   from the side, with only 0.32 m of shoulder clearing the bed, the cast read as a
   **giant pale egg**. The bed is lower; the cast did not move.
7. **The pour arm brought down, and the sword arm brought forward 0.30.** At pass 5 the
   crucible sat at z 2.02 against a head centred at 2.22 and from the side the shank ran
   *into* the head - two objects on the same screen line are one object, and the side
   camera looks down the only axis that separated them. The sword arm now comes forward
   as well as out so the elbow and blade break the ovoid.

### THE GLOW A/B - AN AUTHORED sat 0.895 WAS RENDERING AT 0.349
`tools/art/_moulder_glow_ab.py`, measured on the pour's own pixels:

| strength | authored rgb | measured sat | kept |
|---|---|---|---|
| 1.60 | (1.000, 0.425, 0.105) | 0.349 | 39% |
| 1.45 | (1.000, 0.265, 0.035) | 0.510 | 53% |
| 1.30 | (1.000, 0.210, 0.025) | 0.577 | 59% |
| 1.10 | (1.000, 0.180, 0.020) | 0.648 | 66% |
| **0.80** | **(1.000, 0.120, 0.012)** | **0.792** | **80%** |

Saturation is monotone in strength: **an emissive pushed up the view transform's
shoulder buys brightness by spending colour**, because white is where every hue ends.
That is the Dyer's cream weld and the Greener's beige coals said as a curve. 0.80 is
taken, and I looked at the 1.10 and 0.80 renders before choosing. Shipped body now
measures **sat 0.798 / 0.791 / 0.787** at hue 19 across front, side and three-quarter,
against pass 1's 0.349 at hue 28.

**THE GUARD I WROTE WAS THE WRONG GUARD, AND I AM RECORDING IT RATHER THAN THE NUMBER
IT GAVE.** `share_in_frame_top1pct` asks whether the pour is the brightest thing by
LUMINANCE, which is weighted 0.72 toward green, so a deep red-orange scores near zero
against pale sand however hot it looks. It fell 0.92 -> 0.00 between 1.60 and 1.45
while `val` went *up*, 0.851 -> 0.861. A guard that moves opposite to the quantity it
guards is not a guard. Had I obeyed it I would have shipped the tan.

### TWO INSTRUMENT FAULTS I FOUND IN MY OWN HARNESS THIS RUN
Both were caught by the number being impossible, not by the code looking wrong.
1. **`_moulder_read` v1 measured what the pour LIGHTS, not the pour.** It counted every
   pixel that moved at all between the lit and unlit arms: 181,928 px of 686,000 - a
   quarter of the frame - for four tubes about 2 cm across, and reported sat 0.0775,
   the colour of a dimly warmed dark body. The two are now separated: `lit_px` is the
   illuminated footprint, `moved_px` is the emissive surface above a 0.25 threshold,
   and only the surface is asked what colour it is.
2. **The A/B's first version differenced a SIDE view against a FRONT view.**
   `render_views` leaves the camera on the last view it shot, and the B arm was rendered
   straight after it. All six arms came back identical to three decimals -
   **a sweep in which the independent variable changes nothing is not a flat result, it
   is an instrument measuring something else**, and that is the only reason it was
   caught.

### WEAR 0.26 IS DERIVED, NOT CHOSEN
This is a split body: the man is old (burnt leather, soot, iron handled daily - 0.80),
and the mould furniture and the castings are remade for every cast, so they are nearly
new (0.10) - Mr. E's second rule, the goods must not read second-hand even when the man
does. `tools/art/_moulder_wear.py` sums polygon area per material off the merged mesh
that ships: man 7.73, new 26.88, area-weighted mean **0.2564 -> 0.26**. Nobody picked it.

### THE FIT PROOF - ON A BODY, AND EVERY FAULT I CAN SEE
`renders/art/minibosses/_moulder_register.png`, against a real posed `Knight.glb` at
scale 1.0 (hero h **2.45 m**, measured, not assumed). **VERDICT GREEN**: ratio 1.18,
pair span 4.20, fits_frame true, **3 of 3 proving views**, 0 blind views, 0 unproved
cells, blank check 3 files 0 failures. Generator: 4 meshes, 1,971 faces, span **2.34 m**
against the 11.0 m three-cell corridor - **CORRIDOR-SAFE**, not room-locked. Border
check clean, 0 frame clips.

**WHAT IS STILL WRONG - ten, and the first one is the real one:**
1. **The side view is the weakest of the three and the egg is not cured.** At 55% head
   the cast is head-dominated from a camera that cannot see either arm's spread. Pass 7
   broke the outline with the forward arm; it did not fix the proportion, and nothing
   short of giving the cast a cape or a crest will. The front and three-quarter views
   carry the idea; the side carries it weakly.
2. **The copy's head rides above the dashed hero rule.** True and explained - its feet
   are buried at 0.45 - but a viewer at a glance may read the copy as *bigger* than the
   hero rather than *standing in a box*.
3. **The pour is nearly invisible from the side**: 1,336 moved px against 3,611 at the
   front. Only the seams carry the heat in that view.
4. **The forearm reads as a pale wedge across the cast's chest** from the side - pass
   7 bought the outline break at that cost.
5. **The sword is a plain grey paddle** at register distance, not a blade.
6. **The hung castings read as a row of white teeth** along the box face.
7. **The rammer is lost** against the dark box edge in every view.
8. **The crucible reads as a banded pail**; its orange rim reads as paint, not contents.
9. **The sand bed's lumps read as potatoes.**
10. **The box is the largest and brightest mass** in the frame and competes with the
    cast for the eye.

**AND ONE THING NO INSTRUMENT HERE COULD HAVE CAUGHT.** The occlusion test passed all
three views at pass 5 while the crucible was visually welded to the cast's head, because
it asks whether the hero can see the creature and the creature the hero - never whether
one PART of a creature has eaten another. The picture caught it. The number could not.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
- `assets/monsters/minibosses/moulder.glb` - **static**, so `bestiary.gd` needs a
  `model` path and **no `anims` entry**. Height **2.90** (`BOSS_DEFS`/bestiary `h`);
  art's measured number, do not re-derive it - `renders/art/minibosses/_report.json`
  and `_fit_moulder_register.json` carry span, ratio and face count.
- Theme **firepit** for the set-piece roll (joins the Stoker and the Tapster).
- **CORRIDOR-SAFE at 2.34 m** - no spawn gate needed.
- The mechanic, at its cheapest honest version, needs **no hero-clone**: on spawn, mark
  the hero that lands the first blow; after a fixed pour, spawn one minion that carries
  that hero's weapon reach and damage, with the Moulder's own hp. Breaking the flask
  before the pour completes cancels it. The art carries the read either way.

### LICENCE
All geometry is original vertex maths through `lordlib`. No pack asset is used in this
body and nothing is re-exported. The KayKit adventurer is loaded read-only by the fit
harness as the measuring stick, as it is for every other creature in this register.

---

## 27. THE RATCATCHER - *IT IS PAID BY THE TAIL* (2026-11-18, art lane)

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `ratcatcher` | The Ratcatcher | 2.62 | crypt | **IT IS PAID BY THE TAIL** - everything else that dies in this room goes into the cage on its hip and it is stronger for every bay it fills; the party is not choosing how to kill it but whether to clear the room at all | 0.68 | 3.73 |

Generated by `tools/art/minibosses.py:ratcatcher()`, rendered by
`tools/art/minibossgen.py`, measured by `tools/art/minibossfit.py` and by a new
instrument, `tools/art/_rat_tally.py`.

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED

I parsed `CANON` out of `minibosses.py` rather than trusting the prompt's
count, and the prompt was stale: it said twenty exist. **Twenty-six exist**,
and `assets/monsters/minibosses/` holds 26 base bodies plus 11 `_chibi`
variants. Theme coverage, counted the same way:

| themes with TWO OR MORE | themes with ONE |
|---|---|
| barracks, workshop (4), firepit (3), flooded, grassland, keep, mess, prison, treasury | **confection, crypt, fogbound, shrine, wood** |

So the twenty-seventh went to one of the five thin themes. **CRYPT.**

### WHY IT IS NOT A RE-SKIN - THE TWO NEIGHBOURS, NAMED

- **THE SCRAPWRIGHT** (workshop, 2.00) also GROWS. But off the room's loose
  plate, on its own schedule, with **no dial the party's hand is on.** This one
  grows only when the party swings, and a party that leaves the lesser things
  standing starves it completely. Same word, opposite decision.
- **THE PRESSMAN** (prison, 2.85) also USES THE DEAD. But your **fallen
  heroes** - so it punishes losing. This one eats your **kills** - so it
  punishes winning fast. Nothing else in the register takes the party's own
  successes as its feed.
- **THE SEXTON** shares the crypt and is the theme's wired primary. Its idea is
  IT WILL NOT STAY DOWN: its own risings, its own graves. This one never rises
  and never dies twice. They share a room and share no mechanic.

### WEAR 0.68 - A STATED CHOICE, AND I AM NOT DRESSING IT AS A MEASUREMENT

The Moulder's 0.26 was a surface-area-weighted mean of two populations,
measured by `tools/art/_moulder_wear.py`. **I did not run that here.** Three
populations, argued: the man's leather and the greased iron pole are OLD and
handled daily (0.85); the willow cage is **relashed as it rots**, so it is the
youngest thing on the body (0.45) and a cage that is this creature's receipt
must not read as refuse; the tally is today's (0.10). 0.68 is taken, toward the
man-and-iron end because they carry most of the mass and all of the
silhouette's lower half.

### THE INSTRUMENT, AND IT IS WRITTEN AGAINST MY OWN PASS-11 FAULT

The whole idea is a NUMBER - five of twelve - so the acceptance test is whether
a viewer can **see and count** the catch. At the Moulder's pass 11 I shipped
`head_glow_px: 156` beside my own sentence "the head now has no face at all",
because a mask render of a group ALONE answers how BIG a thing is, never
whether it can be SEEN.

`_rat_tally.py` asks the viewer's question instead: render the body **with and
without** the `occupants` span through ONE camera and count the pixels that
**moved**, letting the renderer do the depth. Two numbers, because one is not
enough: `moved_px` (how much of the frame the catch owns) and **`components`**
(how many separate moved blobs - five bundles that merge into one mass read as
one thing, and `moved_px` alone would call that a pass).

Three ways it could lie, and what stops each - all three are asserted, not hoped:

1. **The camera moving between A and B.** `render_views` derives the camera
   from world bounds; deleting geometry that touches them re-frames the shot
   and every pixel "moves" - the fault that made the Moulder's first glow sweep
   report 129,023 px where the honest figure was 5,700. The occupants are
   interior, so the camera **must** be identical; it is compared and the run
   goes RED if it is not.
2. **The height normaliser moving.** Asserted equal to 1e-6.
3. **Reading green on empty.** A view with zero moved pixels or zero components
   is RED. A metric computed over nothing reads clean and means nothing.

A fourth was caught while writing it: the three 'bone' bars that bow under a
loaded bay were inside the `occupants` span, so the instrument would have
counted **its own scaffolding** as tally pixels. They were moved out of the
span before the first measurement.

### THREE PASSES, ONE CHANGE EACH, AND EVERY ONE DRIVEN BY A PICTURE

| pass | change | front moved / comps | 3/4 | side |
|---|---|---|---|---|
| 1 | first build, all five occupants in one plane | 11,050 / **9** | 11,281 / 12 | 4,167 / 6 |
| 2 | occupants staggered 0.24 m across the cage's depth | 10,141 / **7** | 11,382 / 10 | **9,192** / 6 |
| 3 | the man rebuilt at CHIBI proportion | 10,093 / **7** | 10,705 / 9 | 8,690 / **4** |

- **PASS 1 SHIPPED THE IDEA IN TWO VIEWS OUT OF THREE AND THE PICTURE SAID SO
  FIRST.** Front: five components of ~2,000 px each - the count reads exactly.
  Side: one of 2,692 and one of 833, five bundles collapsing into two masses,
  because a row laid across X projects onto itself in a side camera. The cage
  read as an **empty frame** from the side. For a creature whose whole idea is
  a fraction, that is most of the idea gone.
- **PASS 2 BOUGHT THE SIDE BACK: 4,167 -> 9,192 moved px, +121%.** A basket is
  deep; staggering the columns across its 0.62 m of depth is what a loaded
  basket actually looks like, and depth is the only thing a side camera can
  separate them by. 0.24 m of column pitch against a 0.236 m bundle diameter -
  deliberately just over touching. The front could not move and did not: it is
  an orthographic +Y camera and no x or z changed.
- **PASS 3 IS THE FIT RENDER'S, AND IT IS THE MOULDER'S PASS-5 FAULT REPEATED
  A DAY LATER.** Passes 1-2 built the man at REAL human proportion - thin
  limbs, long shins, a head 14% of his own height. The three solo views never
  showed anything wrong, **because there was nothing in frame to compare him
  to.** Beside a posed KayKit Knight he read as a stick figure next to a toy:
  the hero is a chibi, head about 40% of its height. The register's own ratio,
  **1.07**, is a HEIGHT ratio and **cannot see this at all** - it was green
  through all three passes. Head to ~29% of his own height, limbs ~55%
  thicker, shins shortened, shoulders widened. The cage still wins the
  silhouette (0.92 m across against his 0.49 m head), which was the trade I
  was worried about; the fit sheet says it holds. The side gained again as a
  side effect: 2 legible masses -> **3** (4,351 / 2,986 / 1,217).

### WHAT THE SIDE VIEW STILL CANNOT DO, AND IT IS A CONSTRUCTION FACT

**The side carries the catch's PRESENCE, not its NUMBER.** Three masses where
there are five. To count five from the side the bays would have to stack in Z -
a 1-wide, 12-tall column - and that would destroy the 3 x 4 grid that makes the
front and the 3/4 read as a fraction at a glance. I took the front and the 3/4
and paid for them in the side. That is a trade, not an oversight, and it is
measured rather than argued.

### THE FIT PROOF - ON A BODY, AND EVERY FAULT I CAN SEE

`minibossfit.py`, posed KayKit `Knight.glb` at scale 1.0, three views,
`_fit_ratcatcher_register.json`: **GREEN**, hero 2.45 m measured not assumed,
ratio **1.07**, pair span 5.59 m, 3 views proved, 0 blind views, 0 blanks,
errors `[]`. `minibossgen` blank-and-border check: **0 blanks, 0 failures**,
4 meshes, 1,510 faces, size 3.73 x 1.33 x 2.62 m, footprint span 3.73 m,
**CORRIDOR-SAFE** against the measured 11.0 m clear of a three-cell corridor.

I looked at all six renders. The faults:

1. **THE CAGE FLOATS.** Nothing supports its bottom edge. The yoke bar is the
   only connection and it meets the cage at the TOP corner, so at hero scale
   it reads as a free-standing rack the man happens to be standing beside
   rather than a thing slung on his hip. **The worst fault on the body** and
   the first thing a pass 4 should take: either feet under it or a hip strap.
2. **THE SEVEN VACANCY HOOKS AND THE FIVE TAILS ARE THE SAME MARK** - thin
   dark squiggles. At a glance the cage carries twelve similar strokes and only
   the five BALLS carry the count. The vacancy half of the idea is weaker than
   the filled half.
3. **THE WILLOW READS GREY, NOT BUFF.** Authored (0.690, 0.588, 0.414); on the
   frame it reads as whitewashed timber. **Stated as seen, NOT measured** - I
   did not run `_colour_read` on this body and will not imply a number I do
   not have.
4. **THE NEAR ARM DISAPPEARS INTO THE TORSO** on the front view. Only the pole
   shows where it goes.
5. **THE POLE'S IRON BUTT IS HIDDEN** behind that same arm in every view that
   has it, so the tool reads as a stick with one end.
6. **THE SHOULDER BAR READS AS A PLANK** across the chest at some angles.
7. **THE HEAD HAS NO FACE** past two eye dots, and the cap sits flush on it
   with no brow gap.
8. **hero_side IS TIGHTLY FRAMED AT THE BOTTOM** - the creature's boot sits on
   the frame's bottom edge. The border check passed, so this is a note, not a
   failure.
9. **THE LAMP IS SMALL AT HERO SCALE.** Legible, barely. It is the one lit
   thing and it lights the tally, which is what it is for.

### WIRING - THE ART LANE DOES NOT DO THIS

`assets/monsters/minibosses/ratcatcher.glb` is committed. **STATIC** - no
animation, so `bestiary.gd` needs a `model` path and **no `anims` entry**.
Suggested row: `h` 2.62 (the authored height; `Monster` normalises to it),
theme `crypt`. `dungeon_hd.gd`'s `THEME_MINIBOSS` maps one key per theme and
`crypt` currently maps to `sexton`; a second-per-theme pick is the game build's
call, not art's. Feed line: *"It is paid by the tail."*

### LICENCE

100% original procedural geometry (`bmesh`-free raw vertex maths via
`lordlib`). No pack asset is read by this body. Nothing to log in
`ASSET_SOURCES.md`.

## 28 - THE DROVER. IT YOKES ONE OF YOU. wood, the second one.
2026-11-18, 03:35-04:20 CT, the art lane.

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED
I parsed `CANON` out of `tools/art/minibosses.py` rather than recalling the set:
**41 mechanic strings, 27 distinct bodies.** The occupied classes are summon,
self-armour, drag-a-hero, douse the lamps, will-not-stay-down, bar the door,
take-and-wear, heal-the-pack, raise the water, plant thorn, pre-set the room,
fire-scaled, mislocated sound, pour-and-set, come-apart-in-two, arm the room,
encumber, bisect the room, adaptive resistance, take the haul, drink the brews,
press the fallen, strike you level, mark-and-hunt, green your iron, take your
shape, paid by the tail.

**NOTHING IN THE REGISTER SHARES HARM WITH THE PARTY.** That is this one.

Bodies per theme, from the same parse: `wood` carried ONE (the Snarer) and was
one of the four thinnest themes with fogbound, shrine and confection. The
Snarer's idea is IT HAS ALREADY SET THE ROOM - lines laid before you arrive.
This one lays nothing: it joins itself to you. Same room, no shared mechanic.

### THE PACKS WERE CHECKED BEFORE A VERTEX WAS WRITTEN, AND THE NUMBER IS MEASURED
I walked `C:\hd adventure\_packs` and grepped every filename for
yoke / oxbow / ox_bow / collar / chain / coil / shackle / goad / harness / cart
/ plough / plow. **2,025 files walked. ZERO hits on all twelve terms.**
(The walk log is `_drover_packgrep.log` at the worktree root, which
`.gitignore` excludes - so the counts above are the record, not the file.) Nothing on disk serves a yoke, a chain, a collar
or a goad, so procedural is the right call and not a preference.

ONE CORRECTION TO A NUMBER THIS LANE HAS BEEN REPEATING: the walk found
**8 top-level pack directories** holding those 2,025 files, not 40. The file
count matches what was measured on 17 Nov; the "40 packs" figure does not match
the top level of that tree. Named so the next run measures rather than inherits.

### THE IDEA, AND WHY IT IS NOT A 28TH COAT OF AN EXISTING ONE
IT YOKES ONE OF YOU. It closes a bow of its own yoke on a hero, and after that
the harm you do it travels the chain: while the collar holds, every blow landed
on the Drover is paid half by the one wearing it. The party is not choosing how
hard to hit but **whether to hit at all**. Cut the chain and the yoke comes free
to take the next - and the second bow hangs open to tell you it can.

Checked against all 27: the Gaoler *moves* a hero (drag), the Dyer *marks* one
(targeting), the Tanner *resists* what hurt it once, the Greener *copies* a
hero's shape, the Ratcatcher *feeds* on other deaths. None of them makes your
own damage the party's problem. This is a harm-routing mechanic and it is new.

### WEAR 0.74 - AN ARGUED CHOICE, AND I DID NOT MEASURE IT
I did not run `_moulder_wear.py` and I am not implying I did. Four populations:
the ash beam, handled every day of a working life, 0.85; the chain and collars,
greased iron older than the man, 0.90; the leather, daily, 0.80; **the goad, cut
this week - the only young thing on the body, 0.15**. 0.74 is taken toward the
beam-and-iron end because they carry the mass and the whole upper silhouette.
0.74 is free in the register: 0.70 and 0.75 are taken, nothing shares a value.

### SIX PASSES, ONE NAMED FAULT EACH, EVERY ONE DRIVEN BY A PICTURE
**Two faults were caught by READING a helper before rendering, not after:**
- `_open_ring`'s own docstring says a yaw-0 ring is **edge-on from the side**,
  and the Pressman shipped four collars that became four sticks that way. All
  three rings were turned to yaw 0.78 before pass 1 ever rendered.
- `creatures.eyes()` **defaults to `slot='glow'`**. My palette comment claimed
  "no geometry in the glow slot" while calling it. The comment was the thing
  that was wrong and the comment is what got corrected - the body has no lamp,
  no flame and no pour, and exactly two emissive eye pinpoints of r 0.042.

**Pass 2 - THE CHAIN WAS NOT A CHAIN.** Pass 1 drew it as separate boxes spaced
along the run. front.png shows what that actually is: a scatter of loose cubes
climbing through empty air, and the coil a pile of gravel. The creature's idea
is that harm *travels the chain*, so a chain that does not read as one connected
thing is the mechanic gone. Links now overlap at 1.10 * r and alternate 90
degrees - links passing through links, and visibly cuttable, which is the
party's way out. *(Same pass, a defect not a judgement: the goad's iron point
had detached from its shaft - side.png shows daylight between them - because a
rotation about Y swung it off the shaft's own line. Placed along the shaft's
last leg instead.)*

**Pass 3 - THE BEAM ATE THE TOP OF BOTH BOWS.** A shut bow is an **O** and an
open one is a **C**: that is the entire count. The beam, 0.09 thick and cambered
forward over them, covered the top arc of both, so both rendered as C's and a
viewer could not have read the idea from any camera. Bows dropped to clear air
on visible straps. *(3b: the collar sat inside the bow and the pair read as one
knot - it now hangs clear below it. 3c: the floor coil alternated flat and
upright rings and read as a bed of spiked cartwheels; a coil lying down is seen
from above by every one of these cameras, so it is flat rings only.)*

**Pass 4 - THE SAME FAULT WITH A DIFFERENT OCCLUDER.** Clear of the beam, both
bows still rendered as C's: at x -0.60 / +0.62 they hang straight through the
MAN, whose shoulders are 0.82 across. Moved outboard to +/-0.84, just inside the
beam's ends, so the whole circle of each is against background. **I spent two
passes learning one thing: THE COUNT MUST HANG IN CLEAR AIR.** Writing it down
because the Ratcatcher's cage learned the same lesson about depth and this lane
keeps paying for it twice.

**Pass 5 - MINIBOSSFIT WENT RED ON MY OWN CREATURE AND IT WAS RIGHT.**
`"drover: pair does not fit the fixed frame"`, pair width 6.12 m against a
register whose widest body before this was the Gaoler at 3.72. **I could have
widened the frame. I did not, and I want that on the record:** the frame is
shared by 26 bodies that all fit it, so a frame edited to admit mine would be an
instrument edited to pass its author's work - the exact fault class this lane
keeps catching in its own gates. The creature was what was wrong. The two widest
things on it were the two least load-bearing - the coil's sprawl and the goad's
reach - so the coil came in 0.28 and tightened 0.07 and the goad shortened 0.12
to just inside the beam's own end. **The BEAM now sets the width, which is
correct, because the beam is the idea.** Footprint 4.26 -> 3.59 m.

**Pass 6 - THE SIDE VIEW LOST THE COUNT, AND I HAD NAMED THE RISK IN THE
DOCSTRING BEFORE PASS 1 RENDERED.** A beam across X is exactly the shape the
"separate everything in X" rule cannot save. hero_side.png showed ONE bow: the
other sat directly behind the man. 0.30 of authored Y between them was not depth
separation, it was a rounding error. They now sit 0.80 apart in Y - the taken
one well forward of the chest, the empty one well behind the back, which is also
what a real ox-yoke does. The front and three-quarter cameras are orthographic
along Y and no x or z moved, so nothing those views read could change.

### THE NUMBERS
| | |
|---|---|
| height | 2.44 m (hero 2.45 m, ratio 1.00) |
| footprint | **3.59 m — CORRIDOR-SAFE** (three-cell clear span is 11.0 m) |
| meshes | 4 (body / bone / dark / glow), 5,053 faces |
| minibossgen | `ok: true`, errors `[]`, **blanks `[]`**, border/frame clean |
| minibossfit | **verdict GREEN**, errors `[]`, `blind_views: []`, pair 5.45 m |
| visibility | `proving: 3` — all three views proved by the moved-pixel test |

### THE FIT PROOF - I LOOKED AT IT ON A POSED KNIGHT, AND HERE IS EVERY FAULT I SEE
Rendered on the real KayKit Knight in the idle pose, front / side / back, and I
looked at all three. The scale is right and **the man does NOT read as a stick
figure beside the chibi hero** - the Ratcatcher's pass-3 lesson applied first
time rather than rediscovered. The honest list:

1. **The goad reads as a crutch, not a goad.** It meets the floor at a shallow
   angle with its point ON the ground, so it reads as a prop holding him up. A
   goad is carried. This is the worst remaining fault and it is a pose problem.
2. **The collar and the chain's top links make a knot** on the left side. Noted
   at pass 3, improved, not solved.
3. **The man is a flat dark mass.** At hero-comparison size his torso, arms and
   legs merge into one shadow against the Knight's readable plates. This is the
   price of the dark-body / pale-furniture choice and it is higher than I
   expected when I took it.
4. **The beam foreshortens to a pale lump in the side view** - it reads as a
   sack on his shoulders. The camber bought less than I hoped. The count
   survives there (pass 6) but the *beam* does not.
5. The head sits very low between the shoulders, with almost no neck, and the
   beam passes close behind it in value.
6. The far arm reads as a stub raised toward the beam; the hand does not
   clearly grip anything.
7. The beam's right end passes behind the open C and slightly muddles its top.

### WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT, AND I TOUCHED NO .gd OUTSIDE tools/art/
1. `scripts/bestiary.gd` - add a `drover` entry with
   `model = "res://assets/monsters/minibosses/drover.glb"` and **NO `anims`
   entry**: this body is STATIC, like the twelve creatures of System 10.
2. `scripts/dungeon_hd.gd` - the `miniboss` set-piece slot can prefer it on the
   **`wood`** theme, which until now had only the Snarer.
3. The mechanic itself is a damage-routing rule and it is the game build's: a
   collar on one hero, a share of the damage dealt to the Drover paid by that
   hero, and a cuttable chain that ends it. The art promises a **count of two**
   and an **openable second bow** - if only one hero can ever be yoked, the open
   bow is a promise the fight does not keep.

---

## 29. THE PAVISER - *IT KEEPS ITS FACE TO YOU* (2026-11-18, art lane)
`paviser` - **keep** - h **2.68** - wear **0.78** - 4 meshes, **731 faces**
(pass 8, was 743) - span **3.43 m**, **CORRIDOR-SAFE** against the 11.0 m
three-cell clear span - ratio **1.09** beside the posed 2.45 m Knight, pair_w
**5.3**, fits_frame true. Gate read on the shipped `front.png`: **0 bar
columns of 240**, longest run **0.2837** (pass 8). **Procedural, no pack geometry** (`pack_used` false - see below, I looked
first).

Feed line: *"A board came round to face you."*

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED
1. **The plan, not a list in my prompt.** `origin/main:docs/WORK_PLAN.md`, the
   04:07 CT TAKE THIS NEXT block. My row: the Drover is ticked, twenty-eight
   exist, and the 29th is mine if I am dry. Plus one second row - the Drover's
   browner back - which is answered separately below.
2. **What already exists, counted off the tree, not recalled.** The last
   numbered heading in this file is 28, `assets/monsters/minibosses/` holds 69
   files, and I parsed all 42 CANON entries out of `minibosses.py` with their
   heights, wears and ideas rather than trusting any of the three lists in my
   prompt.
3. **THE PACKS, BEFORE A VERTEX WAS WRITTEN.** `C:\hd adventure\_packs\`
   listed from the directory itself: 56 entries. I searched every pack for
   `pavis`, `mantlet`, `screen`, `barricade`, `board`, `plank`, `wheel` and
   `cart` - **zero hits on all eight**. There ARE six shields (KayKit dungeon
   common/uncommon/rare, Quaternius heater/round/celtic) and they are the wrong
   object: hand shields 0.5 m across, and the Quartermaster already carries
   that exact geometry. A 1.3 m standing board is not on this disk, so this one
   is generated. That is the rule working, not the rule skipped.
4. **The wear ladder.** 0.15-1.00 in 0.05 steps is **FULL** - 26 distinct
   values occupied. 0.78 is free, between the Loader's 0.75 and the Gaoler's
   0.80. Height 2.68 is free between the Loader's 2.65 and the Bellman's 2.70.

### THE IDEA, AND WHY IT IS NOT A 29TH COAT OF ONE OF THE TWENTY-EIGHT
**NOT ONE OF THE TWENTY-EIGHT IDEAS IS POSITIONAL.** Parsed out of CANON, not
recalled: summon, self-armour, drag a hero out, douse the lamps,
will-not-stay-down, bar the door, steal gear, heal the pack, raise the water,
plant the ground, pre-set the room, scale with the fire, ring from elsewhere,
set the floor, come apart in two, arm the room, weigh you down, cut the party
in two, adapt to the damage type, take the haul, drink your stores, use your
fallen, mark one of you, trade on the body, copy your shape, be paid by the
tail, yoke one of you. Every one of them is answered by deciding **what to
do**. This one is answered only by deciding **where to stand**.

It carries a pavise on a hinge post and swings it onto whoever is hurting it
most. A blow into the board does nothing at all. So the party cannot win this
by standing still and hitting harder: one of you has to get round the post
while another holds its attention, and the moment you two swap sides the board
comes back round.

**IT IS NOT THE PORTER AND IT IS NOT THE HURDLEMAN**, and the difference is not
a quibble:
- the **Porter** drops a leaf across the chamber MOUTH. It is a wall, it does
  not move, and what it takes from you is retreat.
- the **Hurdleman** plants a panel through the middle of YOUR OWN LINE. Also
  static, and what it takes from you is each other.
- this one's board is **on the creature and it tracks**. Nothing is taken from
  you. What changes is that the creature now has a front and a back, and your
  damage depends on which one you are standing at.

**THE SOLID BILLBOARD WAS A FREE SILHOUETTE AND THE HURDLEMAN IS WHY.** Its
pass 3 found that its spare panels "read as one solid grey billboard - the
biggest mass in the silhouette, reading as a door or a shield" and rebuilt them
as open lattices, because a hurdle is not solid. So that outline was vacated by
the one body that could not use it. A pavise **is** a door-sized shield, so the
read the Hurdleman had to throw away is the exact read this body needs.

### KEEP, AND THE THEME WAS COUNTED
`dungeon_hd.gd` rolls `miniboss` at 35 on barracks and workshop (2 bodies
each), 15 on keep, treasury and mess, 10 on shrine and crypt. **Keep had
exactly one body - the Porter.** A pavise is a siege object and a keep is where
one lives, so the weight-15 theme with the thinnest bench gets the body that
belongs there anyway.

### THE FIT PROOF - SEVEN PASSES, AND SIX OF THEM CAME OFF A PICTURE
Rendered on a real posed KayKit Knight, front AND side AND back, and I looked
at every one. `renders/art/minibosses/paviser/hero_*.png`.

1. **Pass 1 was a fence.** Nine separate plank boxes on the arc; the arched
   tops opened notches between them and `front.png` read as a **palisade** -
   the one thing a shield must not be.
2. **And the side view was worse, in the exact way my own docstring said it
   would not be.** I had written that the deep camber would make the board read
   as an ARC edge-on instead of a stick. `side.png`: nine boxes spread over
   0.20 m of depth came apart into **six detached pale sticks**. The camber did
   not save the side view - it supplied the spread that destroyed it.
3. **Pass 2 made the board ONE CLOSED CURVED SHELL.** Continuous front, back
   and ends; the plank seams drawn ON the face so they can never touch the
   outline. The side view was fixed by this and has stayed fixed.
4. **Pass 2 then read as a CASK ON END.** 0.92 wide by 1.18 tall, arched top,
   deep belly, two iron hoops. Worse than the fence, because a fence at least
   had an edge. **Pass 3** moved five numbers toward tall-and-flat (1.65:1 from
   1.28:1) and **deleted the centre rib**, which was my own fault and the
   nastiest one: the rib was the same dark tube at the same weight as the hinge
   post, so the front view had two identical verticals and the board sat in a
   frame between them - **a gate**, which is precisely the read the docstring
   said this body must not have, written by the line that caused it.
5. **Pass 3 then swallowed its own creature.** The taller, narrower board was
   the right board and `front.png` showed a board, a fist and **one eye**.
   **Pass 4**: top edge to the chin, board 0.08 further out. Head, helm, both
   eyes, shoulder and arm all back against background.
6. **Pass 5 killed the barrel for good, and it was the hoops, not the
   proportions.** Each band had run the full width and round onto the ends, so
   the dark line met the pale outline on both sides and closed behind it. A
   hoop is a cask and no change of proportion was ever going to beat two of
   them. They stop at 0.30 now, ends against the pale field, and the board's
   outline is unbroken pale top to bottom.
7. **The six bolt stubs were spiking the side silhouette.** At 0.135 long they
   became a row of horizontal spines down the left edge and the creature read
   as a **spiked post**, a different animal. The border check cannot see this -
   nothing is clipped and no frame is blank, so it is green while the body is
   wrong. Shortened to 0.055 and sunk, all inboard of |u| 0.28.
8. **PASS 6 WAS A FIX THAT MADE THINGS WORSE AND IT IS REVERTED, NOT SHIPPED.**
   See the live fault list below.
9. **PASS 7 KILLED THE GATE, AND THE GATE WAS MY OWN PASS 3.** Pass 3 deleted
   the centre rib because the front view had *"two identical dark verticals and
   the board sat in a frame between them - a gate"* - and the same pass added
   **two plank seams, which are two identical dark verticals running 96% of the
   board's height**. The rib was deleted and its read was rebuilt out of the
   replacement in the same breath. I did not get this from the comments; I
   looked at `front.png` and the pale board reads as a portcullis. **One
   variable** (`PAVISER_SEAMH`, the seams' height), swept 1.00 / 0.50 / 0.00
   and **measured by a new instrument that asks the viewer's question**,
   `tools/art/_gateread.py`: a BAR is a dark run crossing >= 50% of the board's
   height with pale above and below it in the same column, so a bolt stub is
   not a bar and the man, who is not enclosed by the board, cannot be charged.

   | SEAMH | bar columns | bar share | longest run | p90 run |
   |---|---|---|---|---|
   | 1.00 (shipped before) | 18 | 0.0750 | **0.956** | 0.3773 |
   | 0.50 | 7 | 0.0292 | 0.5179 | 0.3773 |
   | **0.00 (shipped)** | **7** | **0.0292** | **0.5179** | **0.0956** |

   **0.50 is worse than 0.00 in the picture and the number cannot see why** -
   it scores the same bar count, but five short verticals read as more damage,
   not less grille. The picture decided; the number only ranked 1.00 last.
   The instrument **goes RED ON EMPTY and that arm has been fired**: a fully
   transparent frame returns `ok: false`, `VOID: only 0 board columns`
   (`renders/art/_sweep/_gateread_redarm.json`). The sweep renders are kept at
   `renders/art/_sweep/paviser_seam*/`.
   **WHAT THE INSTRUMENT CANNOT SEE**, written down because this lane shipped
   `head_glow_px: 156` beside "the head has no face at all" on 17 Nov: a pale
   bar on a pale field; a dark mark that reaches the board's outline (not
   enclosed, so not counted); and anything at all about the post, the prop, the
   legs or the floor.

   **PASS 8 (21 Nov, 08:4x CT) - THE SPLITS, AND THE INSTRUMENT COULD NOT TELL
   THE TWO CANDIDATES APART.** Pass 7 said the gate was REDUCED, NOT CURED:
   three dark splits still made a faint grid with the two straps and the
   longest ran 0.5179 of its column, over the 0.50 bar line. Two things could
   be causing that, so there are two hooks and they were swept APART:

   - `PAVISER_SPLITH` - the splits' height, scaled about each split's own
     centre.
   - `PAVISER_SPLITC` - the splits TRANSLATED in z into the clear band between
     the two straps, **heights untouched**, so the column's longest run cannot
     move and anything that changes in the picture is the JOIN and only the
     join. Every shipped split crossed a strap (straps 0.372-0.428 and
     1.122-1.178; splits 0.62-1.24, 0.30-0.76, 0.86-1.26), giving the face six
     closed cells.

   | variable | bar columns | bar share | longest run | p90 run |
   |---|---|---|---|---|
   | SPLITH 1.00 (shipped before) | 7 | 0.0292 | 0.5179 | 0.0956 |
   | **SPLITH 0.55 (shipped)** | **0** | **0.0** | **0.2837** | **0.0956** |
   | SPLITH 0.00 | 0 | 0.0 | 0.0981 | 0.0554 |
   | SPLITC 1.00 (rejected) | 7 | 0.0292 | 0.5179 | 0.0956 |

   **THE FINDING OF THIS PASS IS THAT MY OWN HYPOTHESIS WAS WRONG AND THE
   PICTURE IS WHAT SAID SO.** I went in believing the JOIN was the cause - I
   could see the six cells in `front.png`. Lifting the three splits clear of
   the straps made it **worse**: three equal verticals stacked tidily between
   two rails is a grille drawn from life. And `_gateread` reported
   `cols=240 bars=7 share=0.0292 max=0.5179` for that body - **byte-for-byte
   the shipped numbers**, by construction, because translating a run does not
   change its length. **A pass that had trusted the instrument alone would
   have shipped the worse board on an unchanged green line.** That is the
   blind spot named in advance by the "what this cannot see" list and now
   demonstrated rather than asserted.

   0.00 also clears the bar and is the cleanest face of the three, and it was
   **not** taken: the splits are the wear RECEIPT on a board whose entire
   purpose is to be hit (Mr. E's rule 2), so 0.00 buys the gate with the thing
   the board is for. 0.55 keeps three short checks, none of which reaches a
   second rail. Sweep renders at `renders/art/_sweep/paviser_split*/`,
   readings at `renders/art/_sweep/_gateread_splith.json` and
   `_gateread_splitc.json`, shipped reading at
   `renders/art/minibosses/_gateread_paviser.json`.

### THE HONEST FAULT LIST - EVERY ONE OF THESE IS VISIBLE ON THE SHEETS
1. **The back of the board is a dead blank pale rectangle.** `hero_back.png`
   carries half this creature's idea - the board is gone, you are looking at
   the man, which is the party's answer drawn - and there is not one mark on
   it. Pass 6 put two iron battens across the back, which is how a boarded
   pavise is actually braced. The result: **the man occludes the entire back of
   the board**, so all that appeared were the two batten ENDS poking past his
   torso, reading as two loose pegs. Worse than the blank. Reverted. **The
   cause is the man, not the board** - anything placed on that back face is
   behind him by construction - so the next pass must put the detail on HIS
   back. Written down so the next run does not spend a pass rediscovering it.
2. **The man's back is a featureless dark block.** Same view, same problem,
   and it is the other half of fault 1.
3. **The board's grey is the same value as the Knight's armour.** On
   `hero_front.png` the creature's largest mass and the hero's plate sit at
   nearly the same lightness. The limewash is meant to be warm; it is reading
   as slate.
4. **The strikes dissolve at pane distance.** On the hero sheet they are faint
   marks. The "six countable hits" claim is TRUE at render distance and FALSE
   on stream, and I am not going to pretend otherwise. (The seams are gone as
   of pass 7, so they are no longer part of this fault.)
5. **The strikes and the three splits are not distinguishable from each other**
   even up close - two kinds of damage reading as one kind of speckle.
5b. **THE GATE IS REDUCED, NOT CURED, AND THE SPLITS ARE WHY.** With the two
   seams gone the face still carries **three dark verticals** (the splits at
   u -0.22 / +0.10 / +0.29) crossed by the two iron straps, and the longest of
   them still runs **0.52 of the board's height**. On `front.png` they still
   make a faint grid with the straps. That is the next pass's one variable and
   it is NOT done; pass 7 moved one thing and stopped.
6. **The near arm is invisible from the front** (behind the board). Only the
   far arm and fist read, so he looks one-armed.
7. **From the side the fist and forearm cross his own helm and take one eye.**
8. **The man's torso and legs merge into one dark mass** from the side - no
   separation at the hip.
9. **The board floats** - its bottom edge is 0.24 m off the floor, where a
   standing pavise rests on the ground.
10. **pair_w 5.43 against a 5.60 frame is 0.17 m of headroom.** It passes, and
    it is the second-widest pair in the register. The prop leg is what spends
    it.
11. **The prop and the post read as two unrelated verticals** from the back -
    their join at the top is hidden behind the post.

### THE BLANK AND BORDER CHECK
`minibossgen` 0 blanks across the batch, errors `[]`. `minibossfit` verdict
**GREEN**, errors `[]`, blank 3 files 0 failures, `blind_views` empty. The
three-render occlusion test proves on all three cells (`proving: 3`); `seen`
is 1.0 for both bodies in all three views, which is the correct answer for a
pair placed clear of each other and NOT an instrument reading the same number
twice - the team lead audited exactly that shape on the Drover at 04:07 and
found it sound.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
1. `assets/monsters/minibosses/paviser.glb` - **static, no armature**: a
   `model` path and **NO `anims` entry**, same as the twenty-eight before it.
2. `scripts/delve.gd` `MB_FIT`: add `"paviser": 1.09` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json` `pairs.paviser.ratio`. Do not
   re-derive it.
3. The **keep** set piece can now pick between the Porter and the Paviser.
4. **The idea is a BEHAVIOUR and this one is worth more than most as a
   behaviour**, because the body is cheap (743 faces, the lowest in the
   register) and the whole of it is a facing rule. Shipped as a reskin with 2x
   hp it is nothing at all; shipped with "blows into the board do nothing, the
   board turns to the biggest threat" it is the only fight in the set that is
   about where people stand.
5. No `.glb.import` sibling - the art lane never runs Godot.

### LICENCE
Entirely procedural. No third-party geometry, no texture, nothing to record in
`docs/art/ASSET_SOURCES.md`. The packs were searched first and had no pavise.

## 30. THE FENMAN - *IT TAKES WHAT STIRS* (2026-11-18, art lane)
`fenman` - **fogbound** - h **2.52** - wear **0.92** - 4 meshes, **948 faces** -
span **2.48 m**, **CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **1.03** beside the posed 2.45 m KayKit Knight, pair_w **4.35**,
fits_frame true, three proving views, 0 blind views. **Procedural, no pack
geometry** - see below, I looked first and the packs do not carry this.

Feed line: *"Something out there is listening."*

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED
1. **The plan, not the list in my prompt.** `origin/main:docs/WORK_PLAN.md`,
   the **04:58 CT block** (which supersedes the 04:07 one my prompt's row
   numbers came from). The ART row: the Paviser is ticked, *"ART IS ON 29 AND
   IS THE ONE LANE PERMITTED TO INVENT MINIBOSSES WHEN DRY. THE 30th IS
   YOURS."* That is this.
2. **What already exists, parsed not recalled.** `CANON` out of
   `tools/art/minibosses.py` by literal-eval: **43 entries, 29 distinct
   bodies**, and the 29 `.glb` on disk agree with it one for one. The occupied
   mechanic classes are listed in the builder docstring.
3. **THE PACKS, BEFORE A VERTEX WAS WRITTEN, AND THE PROMPT'S NUMBER IS
   LOOSER THAN IT SOUNDS.** `C:\hd adventure\_packs` is **1,716.7 MB** across
   **55 top-level entries** - which is where "40 packs, 1.7 GB" comes from -
   but only **8 of those are EXTRACTED DIRECTORIES** (2,025 files). The other
   **42 are still .zip** plus a few .7z and a loose .blend. I did not take that
   as "nothing there": I read the **namelists of all 42 zips without extracting
   them** (10,246 names) against 35 keywords for a marsh/fen worker - hood,
   cloak, net, pole, reed, swamp, marsh, fog, wader, basket, punt, lantern and
   the rest. **NOTHING SERVES THIS BODY.** The nearest hits are three KayKit
   `staff_*` (a wizard's staff with a head on it, not a quant pole), a
   Quaternius `Monk`, and architectural `poles.fbx`/`structure-pole` from the
   Kenney kits. So this one is procedural, and it is procedural *because it was
   looked for and is not there*, not by default.
4. **The wear ladder.** Every 0.05 step from 0.05 to 1.00 is occupied, measured
   off CANON. 0.92 is free; the split that argues it is in the palette comment.
5. **Which theme is thinnest.** Bodies per theme from the same parse: barracks
   5, workshop 4, keep 4, firepit 4, prison/crypt/treasury/mess/flooded/
   grassland/wood 3, shrine 2, confection 2, **fogbound 1**. `dungeon_hd.gd`
   rolls the miniboss slot at 15 on every unlisted theme, fogbound among them,
   so that slot has been firing with one candidate and no choice.

### THE IDEA, AND WHY IT IS NOT A 30TH COAT OF ONE OF THE TWENTY-NINE
It is hooded blind and it hunts by disturbance, so it comes for **whoever moved
last**. Swing, step, drink - you are the one it wants. A hero who stands
perfectly still is not there as far as it is concerned, and a hero who stands
perfectly still is also doing nothing. The party cannot all fight and cannot
all hide.

**NOT ONE OF THE TWENTY-NINE IS TRIGGERED BY THE PARTY'S OWN ACTING.** Every
one of them is answered by deciding WHAT to do, WHERE to stand, or WHAT to
spend. This is answered by deciding **whether to act at all this beat, and by
whom**. The three nearest and why they are not it:
- the **DYER** marks one of you and hunts the mark - but THE CREATURE CHOOSES
  and the party can only react. Here the party chooses the target every beat,
  by moving, and can hand it to somebody else on purpose. The decision has
  changed hands.
- the **BELLMAN** (the other fogbound body) mislocates the SOUND: it lies to
  your ears about where IT is. This one is honest and blind and reads where YOU
  are. One deceives your senses, one reads yours. And it cannot be confused
  with the Bellman in any view: that is a PALE SHROUD CONE reaching the floor,
  cool grey-blue, wear 0.65; this is a dark stooped man with one pale
  instrument and five cold lights.
- the **GAOLER** and the **DROVER** both TAKE a hero. Nothing is taken here.
  The party keeps every hero and loses the freedom to all swing at once.

### SEVEN PASSES, AND SIX OF THEM CAME OFF A PICTURE
1. **Pass 1's count did not survive the side view - the exact thing I designed
   it to survive.** I hung the five weights at deliberately scattered heights
   on the theory that a scatter is harder to confuse than a ramp. `side.png`
   put two pairs 0.12 and 0.14 apart in z against a weight 0.148 tall: the
   bottom two FUSED INTO A FIGURE-8 and I counted four blobs, not five. **The
   fix was the opposite of my instinct** - an EVEN RAMP at 0.26 per step.
   Ordered was never the risk; CLOSE was the risk.
2. **The spare withies were spiking through his shoulders.** Pass 1 ran them
   x -0.52..0.48 against a torso only +/-0.37 across, at a y that grazed his
   back - so they read as five broken arrows through the man. Now inside his
   own outline in x and clear behind in y: invisible from the front, which is
   the correct answer for a thing on a man's back.
3. **The head was three stacked domes with a bar across the face.** A dome is
   the most occupied head shape in this register and I had built a fourth by
   reflex. A hood is a CONE falling backward plus an OPENING.
4. **Pass 3's cone was too small and I put a 0.70-wide mantle plate under it.**
   The upper body became a HORIZONTAL BAR with a little cone on it like a hat
   on a shelf, and the plate ate the face. Traded one bad read for another.
   Pass 4 made the cone the head AND the shoulders - 0.63 across at the base,
   wider than the shoulders box - and deleted the plate and the inner head
   sphere, which inside a closed cone was geometry nobody could ever see.
5. **The top of the body was still a plank, and the tell-arm read as a stair
   banister.** A dead-straight arm with five evenly spaced things on it is a
   handrail - and pass 2's count fix is what made the spacing even, so the fix
   and the new fault arrived together. The count stayed; the straightness went
   (the arm sags 0.09 at its middle, which is what a laden rod does), the
   shoulders narrowed under the hood, the near arm dropped to a diagonal, and
   the lines took three different thicknesses.
6. **The withy tips were still crossing the top of the front view.** Pass 2
   took them out of the middle and left them beside his head for four passes.
7. **PASS 6 WAS A FIX THAT MADE THINGS WORSE AND IT IS REVERTED, NOT SHIPPED.**
   The complaint was real - at hero scale the face had gone. My fix treated the
   symptom's size: void from 0.152 to 0.225 wide against a cowl 0.33 across,
   plus a brow ridge. The render: the void swallowed the front of the cone, the
   head became a dark BLOCK with two horns, and the pointed hood - the one
   thing pass 4 bought - was gone. **What I actually learned is not a geometry
   finding:** a near-black void on a dark-grey cowl has almost no VALUE
   contrast, so at distance it does not darken anything, it removes shape, and
   making it bigger removes more. The answer is a palette answer and I am not
   taking it in the same pass I found it. It is fault 1 below.

### THE FIT PROOF - ON A POSED KNIGHT, AND EVERY FAULT I CAN SEE
`hero_front.png`, `hero_side.png`, `hero_back.png`, all three looked at.
MINIBOSSFIT verdict **GREEN**, errors [], blind_views [], ratio 1.03,
pair_w 4.35, fits_frame true, blank check 3 files / 0 failures.

1. **NO FACE AT PANE DISTANCE, AND IT IS THE FAULT I WAS WARNED ABOUT.** On
   `hero_front.png` the head is a plain grey cone with a faint dark band. At
   creature scale the hood opening reads; at the size a viewer meets this thing
   beside a Knight it does not. This is the 17 Nov pass-11 finding in a new
   coat, found by looking rather than by a number, and pass 6's attempt at it
   is written up above as a failure. **LIVE, NOT DONE.** The next pass is a
   palette pass: lighten the cowl so the opening has something to be dark
   against.
2. **THE SIDE VIEW DOES NOT READ AS A CREATURE.** `hero_side.png` is an
   abstract pile of grey plates with five white dots down the middle - no man,
   no hood point, no pole, no silhouette. The arms, the outrigger and the
   mantle all project to plates in that camera. **This is the worst view and
   the worst fault on the body.** The one thing that does survive it is the
   count, which is what I designed for and the only part I will defend.
3. **The five weights do not read as LIT.** They are pale grey ovals, not
   lights, in every view. `glow` at 2.6 is not carrying through the view
   transform at this value.
4. **The man is still mostly a flat dark mass** below the hood - the Paviser's
   fault 2 and the Drover's fault 3, reduced by the body/dark split but not
   closed. Two values where three are wanted.
5. **The outrigger still reads as a handrail**, less than at pass 4 but it is
   still the most architectural thing on a creature in this register.
6. **The legs disappear from the front.** Black waders against a dark torso
   with two grey boards under them: he reads as a figure standing on blocks.
7. **The far hand is a dark knob**, not the open waiting hand the pose is for.
   At hero scale it reads as a stump or a cannon.
8. **The near hand's grip on the pole is marginal at hero scale** - derived
   correctly off the pole's own line (x -0.688 at z 0.848) and it reads at
   creature scale, but at hero scale the arm is a thick tube ending near a
   stick rather than holding it.
9. **The withies read a little like a ribcage** from the back. I am calling
   this the least of the nine; the back carries, which is the view the Paviser
   shipped blank.

### THE BLANK AND BORDER CHECK
MINIBOSSGEN: `ok: true`, **errors [] , blank []**, 41 keys, every PNG re-opened
and its opaque pixel count asserted. MINIBOSSFIT: blank 3 files, 0 failures,
and `blind_views` empty - no view of this creature is occluded to nothing.
Footprint 2.48 m against the 11.0 m three-cell clear span: **CORRIDOR-SAFE**,
**not room-locked**, so the game build does not have to gate its spawn.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
1. `assets/monsters/minibosses/fenman.glb` - **static, no armature**: a
   `bestiary.gd` entry wants a `model` path and **NO `anims` entry**.
2. `scripts/delve.gd` `MB_FIT`: add `"fenman": 1.03` - **MEASURED**, from
   `renders/art/minibosses/_fit_report.json`, not re-derived.
3. The **fogbound** set piece can now pick between the Bellman and the Fenman.
   It is the thinnest theme in the register and it had one candidate.
4. **The idea is a BEHAVIOUR and it is the game build's, not art's**: target
   the hero who acted most recently; a hero who takes no action this beat is
   not a valid target. If that is too expensive, the cheap version is "target
   the last hero to deal damage" and it keeps most of the fight.
5. No `.glb.import` sibling - the art lane never runs Godot.

### LICENCE
Procedural. Original generated geometry, no pack asset loaded.

---

## 31. THE COMFITMAKER - *IT GIVES YOU THE ONLY THING THAT CUTS IT* (2026-11-18, art lane)

| key | title | h | theme | THE IDEA | wear | span |
| --- | --- | --- | --- | --- | --- | --- |
| `comfitmaker` | The Comfitmaker | 2.28 | confection | **IT GIVES YOU THE ONLY THING THAT CUTS IT** - its shell is sugar-hard and nothing the party carries marks it, but it hands out comfits as it fights and a comfit is the one thing that does. Take one and you can hurt it; the sugar also gums the hand that took it, so that hero swings slower for as long as they hold it | 0.08 | 1.83 |

`comfitmaker` - confection - h **2.28** - wear **0.08** - 4 meshes, **2,626 faces** -
footprint span **1.83 m** against an 11.0 m three-cell corridor: **CORRIDOR-SAFE**,
and the second-narrowest body in the register after the Drillmaster.

### WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED

1. **Thirty bodies, counted off the committed `.glb` files, not off CANON.**
   CANON holds 44 rows; 12 are `_chibi` and three more are Drillmaster probe
   variants (`drillmaster_tall`, `drillmaster_chibi`, `drillmaster_chibi_tall`)
   that are not bodies. Counting rows inflates barracks from 2 to 4.
2. **Which theme is actually thinnest.** Bodies per theme off those files:
   workshop 4, keep 3, firepit 3, barracks 2, crypt 2, flooded 2, fogbound 2,
   grassland 2, mess 2, prison 2, treasury 2, wood 2 - and **confection 1** and
   **shrine 1**. `dungeon_hd.gd:737-743` rolls the miniboss slot at 35 on
   barracks/workshop, 10 on shrine/crypt, 15 on prison and every unlisted
   theme. Confection is unlisted, so it fires at **15 with one candidate**;
   shrine fires at 10 with one. Confection is the thinner by how often the slot
   actually fires - half again as often - so that is where the body goes.
3. **I am correcting the Fenman's note, not contradicting it.** Section 30 says
   "confection 2"; that parse counted CANON rows and `boiler_chibi` is a row.
   Counted as committed bodies, confection has only ever had the Boiler.
4. **The thirty existing ideas, parsed out of CANON.** Every one of them either
   TAKES something from the party or DOES something to the room. Not one of
   them GIVES the party anything. That is the gap this creature fills.
5. **The packs, listed rather than recalled.** `C:\hd adventure\_packs` now
   holds **56 entries**, up from the 40 the standing brief claims. Nothing in
   them is a tiered sweetmeat stand or a pair of comfit nippers, and both are
   trivially procedural, so this body is bmesh throughout. No pack geometry.

### WHY IT IS NOT A 31ST COAT OF ONE OF THE THIRTY

- the **TAPSTER** drinks what you brought - consumables flow party -> creature.
  Here they flow the other way, which is the whole point.
- the **QUARTERMASTER** arms the room; it hands weapons to ITS side. This one
  hands them to YOURS, and that is why it is dangerous.
- the **GREENER** eats your weapon as you land blows, so your damage decays.
  Here your weapon never works at all and a borrowed one does.

### AND THE BOILER IS THE SHAPE I HAD TO BUILD AWAY FROM

The Boiler is the other confection body: a **round pan** carried high with a
**pour** off it, h 2.10, wear 0.25. My first design was a **panning bowl** -
comfits really are made by rotating a core in a pan - and that is the same
object on the same theme. **It was dropped before a vertex was written.** What
replaced it is a tall narrow **tiered stand**: vertical where the pan is round,
stepped where the pour is continuous, and the instrument is the pale thing
rather than the hot one.

### SIX PASSES, AND WHAT EACH ONE BOUGHT

1. Built: man, nippers, three-tier stand, 4+3+2 lit shells.
2. **THE SIDE VIEW CAUGHT ME MAKING THE MISTAKE I WROTE A PARAGRAPH ABOUT.**
   Pass 1 put the stand outboard **in x only**. The side camera throws x away,
   so post and all three tiers landed on top of the torso and the creature read
   as **one column - a hat on a stack of plates, no man in it**. The stand also
   comes forward 0.60 in y. *A thing that must stand clear has to be clear in
   BOTH horizontal axes, because each camera discards one of them.*
3. Tried to make the nine shells read by making them **brighter** (glow 2.4 ->
   7.0). The render barely moved.
4. **SO I MEASURED THE RENDER INSTEAD OF GUESSING A THIRD TIME, AND PASS 3 WAS
   THE WRONG FIX FOR THE RIGHT FAULT.** In front.png a shell sampled
   (245.6, 232.2, 213.0) and the plate under it (238.8, 225.9, 207.1) - **four
   levels apart out of 255**. The eye, the same glow material, sampled
   (245.8, 232.2, 213.0), identical, so the material was applied and uniform:
   **the emitter is clamped at display white.** 2.4 and 7.0 land on the same
   pixels; 70 would have too. The dish had to get darker because the sweet
   could not get brighter - `bone` dropped from (0.880, 0.840, 0.720) to
   (0.300, 0.268, 0.206). *Brightness has a ceiling and contrast does not.*
5. **THE FIT RENDER FOUND THE REAL FAULT, WHICH IS WHY IT EXISTS.** Beside the
   posed KayKit knight the creature read as a **thin stick figure** - the
   Ratcatcher's pass-2 fault, which I quoted in my own docstring while shipping
   it. **My prose was the unchecked number**: the docstring claimed "head ~0.27
   of his own height" and the geometry gave it 0.14. I measured the knight off
   the fit render rather than guessing a target - alpha width as a fraction of
   each figure's own height from the top:

   | from top | 0.05 | 0.12 | 0.20 | 0.30 | 0.40 | 0.55 |
   | --- | --- | --- | --- | --- | --- | --- |
   | KNIGHT | 113 | 129 | **139** | **146** | **147** | 125 |
   | PASS 4 | 86 | 65 | **62** | 125 | 152 | 117 |

   The knight is **widest at the top** and stays wide through 0.40 - its head
   is the whole upper third. Pass 4 narrowed toward the top. Rebuilt to those
   numbers: head half-width 0.46 (0.40 of body height across, against the
   knight's 0.44), head on the top 0.35, legs cut to 0.28 and thickened.
6. The head was then a **straight drum wider at the crown than at the jaw**, so
   it read as a barrel with a lid and the cap became the lid. Flipping the two
   radii (0.470 jaw, 0.385 crown) was the whole fix. Size untouched.

### FIT - RENDERED ON A BODY AND LOOKED AT

`renders/art/minibosses/_fit_comfitmaker_register.json`, verdict **GREEN**:
ratio **0.93**, pair_w **3.69**, `fits_frame` true, hero measured and posed
(h 2.45, the KayKit knight, 8 parts), errors **[]**, blind_views **[]**,
blank 3 files / 0 failures. Contact views: 0 blanks, 0 frame clips.
I looked at `hero_front.png`, `hero_side.png`, `hero_back.png`, `front.png`
and `side.png`.

### THE HONEST FAULT LIST - ELEVEN, AND THE FIRST THREE MATTER

1. **THE NIPPERS DO NOT READ AS NIPPERS.** From the front the two open legs
   plus the two handles above the pivot make a **tripod** - a surveyor's easel
   or a walking stick. This is the weakest object on the body and I did not
   fix it; six passes went on the stand, the shells and the proportions. It is
   the first thing I would take another pass at.
2. **THE WHOLE CREATURE IS MONOCHROME GREY-TAUPE.** Confection does not read
   as a theme from the colour, and **wear 0.08 does not read at all** - a
   "fresh, scoured, prosperous" body looks like every other grey one in the
   register. The warm values are in `OVERRIDE` and the view transform eats
   them; this lane measured AgX taking 56% of a copper on 17 Nov. The receipt
   Mr. E asks for is not being paid by this body's colour.
3. **THE EYES ARE THE SAME GLOW MATERIAL AS THE COMFITS**, so his eyes are
   exactly the colour of the gift - measured identical, (245.8, 232.2, 213.0)
   against (245.6, 232.2, 213.0). That dilutes the one claim the creature
   makes, which is that the lit things are what it hands you. I kept the eyes
   on purpose (the Fenman shipped a faceless hood and its own list calls it a
   no-face read at pane distance) but the dilution is real and is mine.
4. **The count is a FRONT-VIEW read only.** The side camera throws x away, so
   a tier cannot be counted from the side; what survives is the three-tier
   structure, 0.44 apart in z against a 0.15-tall shell. Stated rather than
   claimed away - this is a narrower claim than the Fenman's five weights.
5. **The left arm reads as a flat slab**, not an arm, in the front view.
6. **The right forearm crosses in front of the middle tier** and partly hides
   one shell in the front view.
7. **The apron and the legs are both near-black and merge** into one mass
   below the waist. The apron does not read as an apron.
8. **From the side the head overhangs the torso backward** and the figure
   reads slightly top-heavy.
9. **The head is still the plainest in the set** - a tapered drum with two
   dots, no mouth or brow. It is a head, not a bucket, which is pass 6's win,
   but it is not better than that.
10. **Ratio 0.93 - it is SHORTER than the hero.** For a miniboss that is small;
    the stand, not the man, is what gives it presence. Deliberate (a short
    broad tradesman) but worth Mr. E's eye.
11. **The bottom tier's shells slightly overlap the plate rim** in the front.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS

I touched no `.gd` outside `tools/art/`. To put it in the game:

- **`scripts/bestiary.gd`** - add a row keyed `comfitmaker` with
  `model` = `res://assets/monsters/minibosses/comfitmaker.glb` and
  **`h` = 2.28**, which is art's measured number - do not re-derive it.
  **IT IS STATIC - there is no armature - so it takes NO `anims` entry.**
- **It ships with no `.glb.import` sibling**, because this lane never runs
  Godot. One Godot run generates it. Same state the Fenman shipped in.
- **`dungeon_hd.gd`'s `THEME_MINIBOSS`** maps one key per theme and
  `confection` currently maps to `boiler`. A second-per-theme pick is the game
  build's call, not mine; until one exists this body will not spawn, exactly
  as the Greener and the Dyer sat on `workshop`.
- **CORRIDOR-SAFE at 1.83 m** against the 11.0 m three-cell clear span. It is
  not room-locked and needs no spawn gate.

### LICENCE

Procedural bmesh + numpy, original to this repo. No pack geometry, no imported
mesh, nothing to record in `docs/art/ASSET_SOURCES.md`.

## 32. THE LEECH - *IT WILL NOT LET A WOUND CLOSE* (2026-11-18, art lane)

A stooped man in an undyed wool gown and a bound linen coif, bent over a brass
basin on a three-leg stand, a fleam in the working hand over the rim, and a
roll of five cupping horns hanging at the thigh. `shrine`, h 2.32, wear 0.82,
4 meshes, 986 faces, footprint 2.26 m - CORRIDOR-SAFE against the 11.0 m clear
span of a three-cell corridor.

**THE IDEA.** While it stands, nothing in this room mends. Every point of
healing the party spends is drawn off into the basin at its side, and the Leech
spends what the basin holds on itself - so the level in that basin is the
mending you paid for. Tip the basin and it has nothing to mend with and your
own healing comes back; leave it standing and your healer is carrying water in
a sieve.

### WHY IT IS NOT A 32ND COAT OF ONE OF THE THIRTY-ONE - PARSED, NOT RECALLED
I parsed the hooks out of `CANON` this run: 31 rows, 31 distinct ideas. Then I
grepped the whole file for heal/mend/cure. **The set has exactly one creature
that touches healing and it points the other way**: the Cook KEEPS THE PACK
ALIVE - its pot heals ITS side and you spill the pot. *Nothing in the
thirty-one touches the party's healing at all.* A room where no wound closes is
a class the set does not have, and it is the one class that turns a whole hero
- the healer - into a passenger until the party does something about it.

The three it stands nearest, and none of the differences is a quibble:

- **The REEVE**: `while it stands the floor pays its box and not you`. Same
  grammar, different resource - and that matters, because loot is settled
  AFTER the fight and mending is spent DURING it. One changes what you get;
  this one changes how you fight.
- **The RATCATCHER** is `paid by the tail` - a visible gauge that grows, and so
  is this basin. I am saying so plainly rather than pretending the shapes are
  unrelated. The difference is whose the gauge is: the Ratcatcher's tally is
  fed by other monsters dying and the party cannot touch it, while this basin
  is filled with the party's OWN spent healing and emptying it is the
  counter-play. A gauge you can empty is a different fight from one you can
  only outrun.
- **The GREENER** `greens your iron` - it degrades the thing you brought. This
  touches your kit not at all; it makes one ACTION worthless.

And it is not the **SNUFFER**, shrine's other body, which TAKES THE LIGHT: that
removes something the ROOM provides, this removes something the PARTY provides.

### WHY SHRINE - COUNTED OFF THE TREE, NOT REMEMBERED
Bodies per theme counted off `assets/monsters/minibosses/*.glb`, excluding
`_chibi` and counting committed files rather than `CANON` rows: workshop 4,
keep 3, firepit 3, barracks 2, confection 2, crypt 2, flooded 2, fogbound 2,
grassland 2, mess 2, prison 2, treasury 2, wood 2 - and **shrine 1**. With the
Comfitmaker closing confection an hour ago, shrine was the last one-candidate
theme. `dungeon_hd.gd` rolls the slot at 10 on shrine, the rarest weight in the
table, which is the argument FOR the second body and not against it: when it
does fire, a viewer has until now seen the same creature every time.

### WEAR 0.82 - A FREE RUNG, AND NOW THE LADDER IS FULL 0.80-0.85
All 31 wear values parsed this run, 0.05 (Reeve) to 1.00 (Hurdleman). 0.82 sits
between the Gaoler's 0.80 and the Sexton's 0.85. The receipt it reads as: an
old trade practised a long time in a wet place - verdigrised brass, a gown
washed grey, a strop black with use. **The fleam is the one thing on him that
is not worn**, because a blade that will not cut is no use to anybody and the
man who owns it knows that better than he knows anything.

### EIGHT PASSES, EACH ONE THING, EVERY ONE DRIVEN BY A PICTURE OR A NUMBER
1. **Built.** 4 meshes, 980 faces, 0 blanks.
2. **The head was the whole creature.** Measured off front.png rather than
   guessed: the head spanned x 215..500 of a 700-wide frame against a body span
   of 237..520 - *it was as wide as the whole man*, and the crest sat level
   with it so the two merged into one pale mass. front.png read as a barrel
   with a lid (the Comfitmaker's pass-6 fault); side.png read as a mushroom.
   Head cut to 0.60 across and the top quarter, crest dropped behind and below
   it, lean pulled back - at y -0.60 the skull overhung the far rim of its own
   basin, so the man was not bent over the bowl, he was lying on it.
3. **The coif band was a brim**, which is the one thing I had written that it
   must not be: it sat ON the crown and wider than the skull. Moved to the brow
   and inside the skull's width, where it adds nothing to the silhouette.
4. **The glow came down 7.0 -> 1.9** on the theory that the fill was clipping.
5. **THE FILL WAS NOT IN THE FRAME AT ALL, AND ONLY THE A/B INSTRUMENT KNEW.**
   See below. This is the run's real finding.
6. **The colour was chosen off the sweep**, not off my eye.
7. **The five horns were a claw.** Hung at z 0.98 with their bases where the
   right arm ENDS, five pale tapered cones radiating off an arm is a HAND OF
   CLAWS, and that is what the render showed - the creature had a bare left arm
   and a talon on the right. Pass 6's move (down to 0.80 and back in y) was the
   right diagnosis and too small: 0.18 of gap is not a gap once the arm is in
   front of the roll. Pass 7 put the roll on the THIGH, 0.36 below the hand.
8. **The height was wrong and the fit render overturned my own argument.**

### THE FINDING: `fill_px: 0` - I HAD BEEN LOOKING AT THE BOWL, NOT THE BLOOD
Passes 1-3 tuned the basin's colour by eye off front.png. Sampled off that
render, the fill read (193,126,105) and the brass around it (168,132,110) -
twenty-five levels apart in red and five in blue, which is the Comfitmaker's
pass-3 fault in a new coat, and I had written that body's lesson into this
one's override and then broken it by choosing BRASS, the same hue as blood.

So I built `tools/art/_leech_glow_ab.py` - the lane's proven with/without
instrument (render lit, zero the emission, render the SAME camera again, count
the pixels that MOVED) because `mask_of` renders a group alone and answers how
BIG a thing is, never whether it can be SEEN. **All six arms came back
`fill_px: 0` while the eyes moved 1,215 px.** The lit surface was not in the
frame: `L.cone(..., cap=True)` is a SOLID, so a fill placed inside the bowl and
below its rim was buried in brass. The salmon disc I had looked at three times
and twice tried to colour-correct was *the bowl's own lit interior*.

That is the pass-11 fault of 17 Nov exactly - a number beside a picture that
disagreed with it - caught this time by the instrument that fault bought.
Worth saying precisely: the harness did not go green on nothing. It reported
RED on empty, by construction, which is the only reason the zero was a finding
rather than a silence.

With the fill moved onto the solid's top face, inside the rolled rim, the sweep
could finally see (`renders/art/minibosses/_leech_glow_ab.json`):

| arm | strength | fill rgb255 | sat | dish sat | gap | verdict |
|---|---|---|---|---|---|---|
| a (pass 1) | 7.00 | 250.8, 205.9, 197.9 | 0.211 | 0.260 | **-0.049** | FAIL |
| b (pass 3) | 1.90 | 230.6, 145.2, 129.2 | 0.440 | 0.272 | 0.168 | FAIL |
| c | 1.10 | 217.2, 98.2, 74.9 | 0.655 | 0.277 | 0.378 | PASS |
| d | 0.85 | 207.8, 72.1, 45.7 | 0.780 | 0.284 | 0.496 | PASS |
| **e (shipped)** | **0.60** | **190.0, 45.7, 8.5** | **0.955** | 0.287 | **0.668** | PASS |

**Read arm a again: at pass 1's setting the fill was LESS SATURATED THAN THE
BRASS BOWL IT SITS IN.** I would have shipped a basin whose contents read as a
paler brass and called the mechanic visible. Arm e's value is 0.745 against the
dish's 0.534, so it is still the brightest thing in its zone - the guard
against winning saturation by turning the light off.

**THE RULE I WANT ON THE RECORD BESIDE THE COMFITMAKER'S.** That body needed
strength 7.0 to separate amber from cream; this one needed 0.60. Both are
right. *Brightness buys separation and costs saturation*: raise it when a lit
thing must beat a pale neighbour, lower it when the lit thing's COLOUR is the
information.

### THE FIT PROOF - ON A BODY, AND THE RENDER OVERTURNED THE HEIGHT
`minibossfit`, verdict **GREEN**: ratio **0.95**, pair_w 4.12 m, fits_frame
true, 3 of 3 proving views, blind_views [], blank failures []. Hero measured at
h 2.45 (raw KayKit glb at scale 1.0 - `townsfolk.gd` leaves hero bodies alone).
Numbers in `renders/art/minibosses/_fit_leech_register.json`, written from the
harness's own report rather than retyped.

I first authored this at **h 1.90**, argued off the ladder: the 0.05 rungs
1.95-2.90 are all occupied, so the only free space was below the Reeve's 1.95,
and a bent height reads honest for the one creature in the set that stoops. The
argument was sound and the number was wrong. `hero_front.png` put it beside the
knight at **ratio 0.78** and it read as a squat stump - visibly shorter than the
hero it is supposed to be a set piece against, where the rest of the set sits
near or above (the Comfitmaker, last hour, 0.96). **A miniboss a viewer reads as
smaller than their own man is not a miniboss.** 2.32 is off-rung, as the
Comfitmaker's 2.28 and the Fenman's 2.52 are, and it also makes the claim true
in the picture instead of in the prose: standing up straight this one would be
the tallest thing in the set. *The ladder is bookkeeping. Fit is the acceptance
test, and when they disagree the render wins.*

**BLANK AND BORDER.** 0 blanks across all six views; border alpha asserted this
run - **0 opaque pixels touching any frame edge** on front, side, three_quarter,
hero_front, hero_side, hero_back (opaque counts 256,152 / 293,895 / 220,775 /
104,201 / 82,869 / 106,103).

**THE SILHOUETTE**, colour thrown away, reads: a hunched figure bent over a
stand with a bowl, one arm down into it, a fan hanging at the hip. It does not
read as a hero, and the stoop - a back crest that is the high point with the
head BELOW it - is a shape no other body in the file has.

### THE FAULT LIST - EVERY ONE OF THESE IS VISIBLE IN THE SHIPPED RENDERS
1. **In pure silhouette from three-quarter the head cannot be found.** It
   merges with the back crest, so the creature reads as a hunched mass with no
   head at all. The front and side silhouettes are fine. This is the one fault
   I would fix next.
2. **The gown is not as cool as the override claims.** I wrote "it is grey, not
   brown, on purpose" and the lit side renders a warm salmon under the key
   light. The claim is half delivered; the shadow side is grey.
3. **Below the waist is one black mass from both front and side** - apron,
   legs, horn roll and boots merge. Only the boot soles break it.
4. **The fleam is nearly invisible at hero distance.** At pane distance it is a
   dark nub over the rim. It reads at full size and not at the size the viewer
   will see.
5. **The left arm merges into the torso silhouette from the side**, so the
   gesture of reaching into the bowl is a front/three-quarter read only.
6. **The head is a plain drum with a band and two dots** - the least
   characterful head in the set. It is not wrong, it is empty.
7. **The basin's front tripod leg crosses the creature's left boot** in the
   front view - a tangency, not an intersection.
8. **The dark horn roll merges with the dark apron** from the front; only the
   five pale horns separate.
9. **The crest reads as a second pale hat from the front** at small size.

### FOR THE GAME BUILD LANE - THE ART LANE DOES NOT WIRE THIS
I touched no `.gd` outside `tools/art/`. What this needs, named exactly:

1. `scripts/bestiary.gd` - add a `leech` entry with
   `model = "res://assets/monsters/minibosses/leech.glb"` and **NO `anims`
   entry**: this body is STATIC, like the twelve creatures of System 10.
   Use `h = 2.32` and the ratio 0.95 from
   `renders/art/minibosses/_fit_leech_register.json` - **do not re-derive the
   scale**, it is measured off the posed hero.
2. The miniboss slot in `dungeon_hd.gd` can now prefer `leech` on the `shrine`
   theme, which until this commit had the Snuffer as its only candidate.
3. The mechanic, if and when it is implemented, is a room-scoped healing
   redirect plus a breakable prop: while the Leech lives, healing applied in
   the room is zeroed and added to a counter; the Leech spends that counter to
   heal itself; the basin is a destructible that empties the counter. **None of
   that is mine and none of it is implied to be queued** - the body stands up
   and reads without it.
4. `assets/monsters/minibosses/leech.glb` is committed **with no `.glb.import`
   sibling**, like `snarer_chibi.glb` before it: a Godot run must generate one
   before the body can load.

### LICENCE
Entirely original procedural geometry (bmesh/numpy, raw vertex maths via
`lordlib`). No third-party asset is read by this builder. Nothing to add to
`docs/art/ASSET_SOURCES.md`.

---

## 33. THE BEADLE - *IT CALLS THE ORDER* (2026-11-18, art lane)

`beadle` | shrine | h **2.95** | wear **0.18** | span **1.86 m** | 4 meshes, 666 faces,
static, no armature, feet on z=0 | **CORRIDOR-SAFE** against the 11.0 m clear span.

> **IT CALLS THE ORDER** - while it stands the party does not choose who acts. The
> Beadle calls, and it calls the same hero again and again while the rest hold their
> ground and watch; the four brass pegs on the board it holds overhead are the calls
> it has left and you can count them from the door. Knock the board off its arm and
> the order comes back to you.

Feed line: *"It says who speaks, and it is not you."*

### WHY THIS ONE - MEASURED THIS RUN, NOT REMEMBERED

**THIRTY-TWO IDEAS EXIST AND NOT ONE OF THEM TOUCHES WHO ACTS.** I parsed the hooks
out of `CANON` rather than recalling them - 32 bodies, 32 distinct hooks - and
grepped every hook for the words that would mean a turn:

| word | hits | what they were |
|---|---|---|
| turn, order, act, acts, initiative, wait, first, last, speak, call, who, queue, haste | **0 each** | - |
| slow | 1 | the **Loader**: *it loads you, and you fight slower until you drop it* |
| time | 2 | the **Snuffer** (*one at a time*) and the **Sluicekeeper** (*a step at a time*) - both the creature's own pacing, not the party's |

Every one of the thirty-two is answered by deciding **what** to do - damage, healing,
gear, gold, stores, light, ground, position, facing, movement. This one takes the
decision itself away from everyone but one hero. That is a mechanic class the set
does not have at all.

**THE THREE IT IS NEAREST TO, AND THE DIFFERENCES ARE NOT QUIBBLES:**

- the **LOADER** is the closest and it is a **stat**. Slower is a number on a hero
  that still takes its own turn. The Beadle changes nothing's speed; it changes
  whose turn it is.
- the **DYER** *marks one of you and hunts only the mark* - same shape of sentence,
  opposite direction. The Dyer chooses **its** target. The Beadle chooses **your**
  action.
- the **DROVER** *yokes one of you* and the **HURDLEMAN** *cuts the room in two* -
  both take the party's **formation**. Nobody loses a turn to either.

**WEAR 0.18 IS A FREE RUNG, MEASURED OFF THE REGISTER.** The thirty-two hold 0.05,
0.08, 0.10, 0.12, 0.15, 0.20, 0.22, 0.25, 0.26, 0.30 ... 1.00. 0.18 is the one gap in
that low cluster. It is also the honest number for the thing: the staff and the board
**are** the office, so a beadle keeps them - but the coat is parish issue and has been
to every moot for years. **HEIGHT 2.95** extends a full 1.95-2.90 ladder by one step,
and it is the right read: a beadle out-tops the people he is calling.

### NINE PASSES, ONE CHANGE EACH, AND EVERY ONE DRIVEN BY A PICTURE

**PASS 2 - THE HAT WAS WEARING ANOTHER BODY'S SILHOUETTE.** Pass 1's brim was 0.700
against a 0.385 crown, wider than the shoulders, and `side.png` read the whole
creature as **a lamp**: shade on top, bell-shaped base under it. That is the
**Snuffer's** own claimed outline ("a lamp-stand that walks"). Brim to 0.465.

**PASS 3 - THE BOARD WAS EDGE-ON AND THE HAND WAS NOT ON IT.** Two faults, measured in
two different views. *Side:* the board sat square across x, the side camera threw x
away, and the four pegs read as **the teeth of a saw blade**. A yaw of 0.38 rad gives
that camera 0.37 of the board's own length - the Paviser's camber argument, applied to
yaw. *Front:* the forearm went up **behind** the hat and ended in a stub, so the board
**floated** over a bent pipe. Elbow forward to y -0.42, mitt onto the board's
underside. The board also went from 1.34x0.085 to 1.06x0.14 because it read as an
**aluminium tray**, and the dark under-rail came off because it made it a **scaffold
plank on a trestle**.

**PASS 4 - I MADE THE DYER'S MISTAKE AFTER QUOTING IT IN THE COMMENT ABOVE IT.** I
wrote *"strength 1.35 and not higher: the Dyer's pass 3 measured an emissive at 2.30
coming back CREAM"* directly above a value that still clips: 1.35 x (1.000, 0.735,
0.255) is (1.35, 0.99, 0.34), so **red and green both reach 1.0**. The pegs rendered
cream - the exact colour of the oak board behind them - and a gauge the same value as
its own backing is a gauge you cannot read. 1.10 x (1.000, 0.600, 0.075) clips red
only, so what reaches the film is amber. The staff finial was also a **candle flame**
(a tall lit cone on a dark stick is a candle in every view) and is now a knob.

**PASS 5 - FIVE THINGS MOVED AND THEY ARE ONE CHANGE: THE HEAD STOPPED BEING A
MACHINE.** A dark drum for a skull with a pale rectangle pasted on the front, two round
lit eyes in it and a slot under them read as **a television** from the front and **a
robot** from three-quarter - the one thing Bellmire's register cannot carry. `side.png`
had the other half of the same fault: a dark skull under a dark crown of nearly the
same width with a pale band between is **a bucket with a lid**, the Comfitmaker's
pass-6 fault arrived at from the other direction. Both are the same mistake - drawing
**features on** a head instead of making the head itself the readable object. The skull
becomes the pale mass, the hat the dark one, the plate is deleted, and the eyes go dark,
which leaves the amber to the gauge and the staff alone.

**PASS 6 - A FIX THAT STOPPED BEING A FIX WHEN THE THING AROUND IT CHANGED.** The
tippet was put on pale to keep a **dark** head off a **dark** torso. Pass 5 inverted the
head and I left the tippet alone, so a pale collar sat directly under a pale skull of
almost the same width (0.455 jaw against 0.470 tippet): `front.png` read head and tippet
as one pale trapezoid and `side.png` as a single pale cone - **a wimple, not a man in a
coat**. The honest move was to delete its colour, not to invent a third value.

**PASS 7 - THE FIT RENDER FOUND BOTH OF THESE, WHICH IS WHY THE FIT RENDER EXISTS.**
Standing the body beside a posed KayKit knight said two things my own three views had
not. *One:* the head was **a bell** - 0.455 at the jaw against 0.370 at the crown is a
23% taper and `hero_side.png` read it as a lampshade next to the knight's near-round
helm. I had the Comfitmaker's *"a head tapers up"* in hand and **overshot it**; the
lesson was that a head must not flare out at the **crown**, not that it should flare at
the **jaw**. 0.420 to 0.395 is 6%. *Two:* at r 0.046 the eyes **vanished at hero
scale** - `hero_front.png` read the face as a pale blank with a smudge on it. And one
thing I measured rather than eyeballed: the chin bar sat at y -0.405 where the skull's
own radius at that height is **0.414**, so it was **inside the head and could never
have rendered at all**.

**PASS 8 - THE HAND WAS A PEARL, AND THE WHOLE IDEA DEPENDS ON THE BOARD BEING HELD.**
`hero_front.png` showed a white **ball** sitting under the plank's edge. A ball near a
thing is not a hand on a thing - and *"knock the board off its arm"* is the party's
answer to this creature, so the one join that had to be legible was exactly the one
left as a sphere. A grip is **two** objects: a palm wrapping under and a thumb across
the top edge. Both are now placed off the board's own axes, like the pegs, because
pass 7's mitt had been typed in world coordinates while the board had been yawed and
raised under it twice.

**PASS 9 - THE SILHOUETTE SHEET CONDEMNED WHAT COLOUR HAD BEEN HIDING.** With value
thrown away the front cell read as **one lump with a comb on top**: the elbow sat at
x -0.520 against a brim of radius 0.545, so the whole upper arm lay **inside the hat's
own outline**. The dark sleeve against the dark brim was legible only because they are
different darks, and the silhouette test exists precisely to take that crutch away.
Elbow out to -0.720, clear of the brim by 0.175.

### THE FIT PROOF - ON A BODY, AND I LOOKED AT IT

`minibossfit --only beadle` against the real `Knight.glb` at scale 1.0, posed:
**verdict GREEN**, `blind_views []`, **3 of 3 views proving** (front / side / back),
each view showing both subjects at `seen 1.000`. Hero measured **2.45 m**, creature
**2.95 m**, **ratio 1.20**, `pair_w` **3.73 m**, `fits_frame true`.

**THE INSTRUMENT IS PROVED ABLE TO GO RED.** The same gate run with `--prove-red`
(hero stood **on** the creature) returns **RED** - *"only 0 of 3 views show BOTH
subjects"*, creature `seen 0.000 vis 0` in all three - while the blank check and the
border check **pass it**. A gate that has never been seen to fail is not known to be
able to. Recorded in `renders/art/minibosses/_fit_beadle_red.json`.

**AND A TRAP THE RED PATH SETS FOR WHOEVER RUNS IT NEXT:** `--prove-red` with the same
`--only` **overwrites the register's shipped hero renders** with its creature-less
cell. I looked at `hero_front.png` straight after the red run, saw a knight alone in an
empty frame, and very nearly wrote that the creature had failed to render. It had not -
I was looking at the proof's own output. The green pass must be re-run after any red
proof, and it was.

**BLANK AND BORDER: 99 files checked across the whole register, 0 failures.** Border
alpha measured on all six of this body's PNGs (`front`, `three_quarter`, `side`,
`hero_front`, `hero_side`, `hero_back`): **max border alpha 0.0000 on every one, no
frame clip.** minibossgen's own check is opaque-pixel only and cannot see a clipped
creature, so this was measured separately - a clipped icon is not a blank one.

### WHAT IS STILL WRONG WITH IT - I LOOKED, AND THIS IS THE HONEST LIST

1. **The staff does not exist in the side silhouette.** With colour thrown away it
   lies entirely inside the body mass. The front and three-quarter cells carry it;
   the side cell does not.
2. **The side silhouette merges the raised arm into the hat.** Pass 9 opened daylight
   in front and three-quarter, where the brim was the obstruction. From the side the
   arm passes behind the crown and there is no gap to open without moving the board.
3. **The two spent sockets are not countable at fit scale.** They read at 700x980 in
   `front.png` and `three_quarter.png` as two dark discs; at hero scale only the four
   pegs survive. The honest claim is split: **the four pegs are countable from the
   door, the sockets are not.**
4. **The grip says "held" but not "hand".** The palm and thumb read as a pale wedge
   on the plank's edge; there are no fingers at this budget.
5. **The staff hand is still a pearl.** I fixed the board hand at pass 8 and left the
   staff hand a sphere on a shaft. It is the same fault, uncorrected, and I am naming
   it rather than hoping nobody looks.
6. **The head is a pale cylinder with a straight dark brow** - stern and readable, but
   it has no crown shape and no ears. At hero scale it is a canister with eyes.
7. **The coat is a featureless dark trapezoid** and nothing on it shows wear 0.18. The
   condition argument is carried entirely by the brightness of the brass.
8. **The board's near end touches the forearm** in the front cell, and the hat overlaps
   the board's near end in the three-quarter cell.
9. **The elbow is a hard angular corner** in every view - a tube bent at a point, not a
   joint.

### WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT, AND I TOUCHED NO .gd OUTSIDE tools/art/

1. **`scripts/bestiary.gd`** - add a row for the Beadle with `model` =
   `res://assets/monsters/minibosses/beadle.glb` and **NO `anims` entry**: this body is
   **static**, four meshes merged by material, no armature. `h` = **2.95** - that is the
   authored height the fit sheet was measured at and the `ratio 1.20` above is the
   argument for it.
2. **`scripts/dungeon_hd.gd`** - the miniboss set-piece roll on theme `shrine`. The
   Beadle is the **third** shrine piece (with the Snuffer and the Leech); it is not
   room-locked, so no spawn gate is needed - footprint span **1.86 m** against the
   11.0 m clear span of a D91 three-cell corridor.
3. **The mechanic itself is the game build's**, not mine: turn order is held by the
   creature while it stands, the four pegs are a destructible gauge, and breaking the
   board returns the order to the party. The art carries the gauge; the rules do not
   exist yet anywhere.

### LICENCE

**100% procedural.** Raw vertex maths only (`lordlib` primitives, `creatures.limb`,
`creatures.eyes`) - no pack geometry is read by this body and `pack_used` is null. The
only third-party asset in any render here is the CC0 KayKit adventurer `Knight.glb`
used as the measuring stick in the fit sheet, already logged in
`docs/art/ASSET_SOURCES.md`.

---

## THE RAMMER (34th) - LIVE FAULT, FOUND 2026-11-18 12:39 CT BY MY OWN SILHOUETTE SHEET

The body shipped GREEN at a8a85a6 (ratio 1.12, 3/3 proving views, 0 blind, blank
check 3 files 0 failures) and that verdict stands. This is a fault **the register
is structurally incapable of seeing**, because every number it computes is about
hero-vs-creature occlusion and this is a creature occluding **itself**.

**THE CLAIM IN MY OWN PASS 5, IN THE SOURCE:** the monkey hangs 0.33 m below the
head so there is "a visible gap of rope, so it reads as HANGING and not as part
of the frame".

**MEASURED, on `renders/art/minibosses/rammer/_rammer_silhouette.png`, walking the
image column through the head cap's centre (3.31 mm/px at sheet scale):**

| view | black run from cap | first white |
|---|---|---|
| front | **831 px, unbroken, cap to floor** | **none** |
| three-quarter | 323 px | 107 px |
| side | 408 px | 247 px |

**In the front view the gap is not small. It is not there.**

**AND THE CAUSE IS NOT THE ROPE.** I assumed the rope before I measured the width,
and the width says otherwise: through that band the run grows **52 -> 89 px** as it
descends. A 44 mm rope is 13 px. That is the **two front legs**, which by z 2.3-2.5
have converged to about ±0.17 of centre and overlap the centre line in a front
orthographic view. Pass 5 fixed the monkey's width against the legs at z 1.93 and
never checked the band **above** the monkey, where the legs are tighter.

**SCOPE, HONESTLY:** in colour it reads - pale wet oak legs against dark iron cap
and monkey, plain on `hero_front.png`. This is a **hue-free read fault only**. But
pass 5's own argument is that the telegraph must survive without hue, so by the
body's own standard it is a fault, and it is the Beadle's family: every number
green, the shape saying less than the numbers claim.

**NOT FIXED.** The cheap fix is to rake the two front legs ~0.06 wider where they
meet the head so they pass outside the cap's footprint - one pass, one re-render,
one re-prove. Not taken inside a row that asked for a write-up.

**ALSO OPEN ON THIS BODY, FROM LOOKING AT THE THREE ON-BODY VIEWS:** the raked back
leg shares a line with the hauler in the side view (reads as impalement for a
moment; nothing clips); the frame collapses to a pole from the side; the pile is
the weakest read in the back view and its shaft shows below the floor plane; and
the hauler's faceting is coarser than the chibi knight's (its proportion is right
after pass 6 - it is segment count, not head-height).

### CORRECTION 2026-11-18 12:46 CT - THE CAUSE ABOVE WAS A GUESS; HERE IS THE MEASUREMENT

`tools/art/_rammer_yaw_ab.py` renders the shipped glb through one ortho camera at
yaw 0/8/16/24/40 and counts daylight in the cap-to-monkey band across the cap's
full width. **Zero at every angle** (denominator 8778 -> 6498, so the instrument
is live). A height profile of the yaw-0 alpha: **0 mm of daylight from z 2.50
down to z 1.90**, first opening at z 1.80 (134 mm) and widening below.

So the band is not "the two front legs" and is not a projection accident - it is
**the tripod converging at its own apex**, which is what a tripod is, plus the
rope. **Raking the legs would do nothing, and no camera angle opens it.** Lowering
the monkey under z 1.80 to find daylight would delete the telegraph it serves.

**What holds:** pass 5's other half - the monkey stands proud of the legs at its
own height, so the tower bulges where the block is. The telegraph is that bulge,
the chalk ring **on the head of the pile**, and the oak/iron colour split. The
source comment claiming "a visible gap of rope" is what is wrong, not the model.

### CORRECTION, 18 Nov 14:3x-15:0x CT - I PUT THE CHALK RING ON THE FLOOR AND IT IS NOT ON THE FLOOR

The team lead went looking for it in `hero_front.png` and `hero_back.png`, could
not find it, and asked whether it had ever been modelled. **It is modelled, and
the sentence above was the fault** - the same class as "a visible gap of rope",
and in the same write-up.

I parsed the glb's own glTF JSON chunk rather than re-rendering: `rammer_glow`
spans y 0.399..1.335. The ring is `_ring(P, (HX, HY, 0.415), 0.20, 'z', 'glow',
0.016, 18)` - a horizontal annulus, radius 0.20, laid on the **broomed head of
the pile at z 0.415**, which is 0.4 **above** the floor plane. Nothing in this
body lies flat on the floor. The generator's own comment said "on the pile head"
and "it is on the floor" in one sentence; both it and this file now say the one
true thing.

**AND I THEN TALKED MYSELF INTO A SECOND WRONG ANSWER, WHICH THE RENDER KILLED.**
From the geometry alone I reasoned that the broomed collar beneath the ring
(a cone r 0.255 -> 0.215 over z 0.335..0.410) is **wider** than the ring's 0.20
and must therefore hide it from any camera at or below its own height. That is
a tidy argument and it is false. `tools/art/_rammer_ring_ab.py` renders the body
with and without the ring through one camera and counts the pixels that MOVED,
sweeping elevation:

| elevation | 0 | 10 | 20 | 30 | 45 | 60 |
|---|---|---|---|---|---|---|
| moved px (yaw 0) | 594 | 1022 | 1232 | 1458 | 1818 | 2088 |
| moved px (yaw 40) | 592 | 908 | 1193 | 1427 | 1730 | 2060 |

**Visible at every elevation including eye level, and it grows with height.**
The real reason nobody could see it is framing, not occlusion: the fit views
frame a 3.87 m hero-and-creature pair, and a 0.4 m chalk mark on a knee-high
stump is a handful of pixels there. It is plainly visible once the camera is
framed on the pile head, and it is visible as a pale sliver in the yaw-90
silhouette too.

**A THIRD THING THE SAME PARSE FOUND, AND IT IS A DEFECT IN MY OWN COMMENT:**
"the ONE glow in the body" is false. `eyes()` in `creatures.py` defaults to
`slot='glow'`, so the hauler's two eye pinpoints are in this material - 352 of
`rammer_glow`'s 870 verts. The emissive strength 1.55 was reasoned for a chalk
mark on wet oak and is also driving a face. Not changed - one change per pass,
and the eyes read correctly at 1.55 - but it is named rather than hidden.

### PASS 7, ONE CHANGE: THE HEAD CAP - AND IT WAS THE DEPTH, NOT THE WIDTH

My own row said "narrow the head cap so the monkey is the widest thing in the
upper frame by a clear margin at every angle". The team lead then looked at the
three silhouettes and said the FRONT already passes, the SIDE is about equal,
and **the three-quarter is the view that fails**. I built the instrument instead
of picking between us: `tools/art/_rammer_cap_ab.py` renders the shipped glb
through one camera at seven yaws and measures **each part's own read** - the
pixels that move when that part alone is stripped out of its mesh.

It says **we were both wrong about which view**, and the side is the one:

| yaw | 0 | 15 | 30 | 45 | 60 | 75 | 90 |
|---|---|---|---|---|---|---|---|
| cap own width, before | 0.403 | 0.474 | 0.518 | 0.525 | 0.496 | 0.435 | 0.341 |
| monkey own width | 0.624 | 0.700 | 0.729 | 0.710 | 0.641 | 0.528 | 0.381 |
| margin, before | +0.221 | +0.226 | **+0.211** | +0.184 | +0.145 | +0.093 | **+0.039** |
| margin, after | +0.221 | +0.241 | +0.246 | +0.233 | +0.206 | +0.162 | **+0.106** |

The three-quarter was never close to failing. **The side was**, by 39 mm, and
the arithmetic is obvious once the number exists: in pure side view the cap
reads its DEPTH, 0.34, against the monkey's strap depth of 0.38. So "narrow the
cap", which plainly means narrow it in x and is what I would have done, would
have cost the block its seat on the three leg tops and **moved the failing
number not at all**. The change is 0.34 -> 0.27 in y only, and the proof that it
was one change is that yaw 0 is identical to four decimal places, 0.403 before
and after.

**I ALSO HAD TO FIX THE INSTRUMENT BEFORE I COULD TRUST IT, AND THE FIRST
VERSION WAS GREEN EVERYWHERE.** Pass 1 measured the whole silhouette's extent
per band and passed all seven yaws. I did not believe it, because one number was
too big: the monkey band read 0.867 at yaw 0 when the block and its straps are
0.62. The extra 0.25 is **the side stay rope** crossing that band on its way to
the hauler's grip. A band margin can be green because the ROPE is wide, which
says nothing about the block - the same family as `head_glow_px: 156` beside
"the head has no face". Both numbers are now reported separately and the
acceptance test is the part's own read.

**WHAT THE NUMBER PASSES AND THE PICTURE STILL ONLY HALF-SAYS, SAID PLAINLY:**
I looked at both yaw-90 silhouettes. The cap is visibly narrower and nothing
else moved. But at that angle the monkey's winning margin is carried by **two
thin strap tabs peeking past the mast**, while the cap is a solid slab - so the
eye still reads them as comparable masses even at +0.106. If the side is ever to
read like the front, the next change on this body is the **monkey's depth**,
0.38 -> ~0.46, not more off the cap. One change per pass; I have made mine.

### THE FIT PROOF FOR PASS 7, AND EVERY FAULT I CAN SEE IN IT

Re-rendered on the posed KayKit knight, front / side / back, and I looked at all
three. Register `_fit_rammer_register.json` GREEN, errors [], blank check 3
files 0 failures, border clean on all seven cap-sweep frames.
**creature_h 2.75, ratio 1.12, pair_w 3.87 - all three UNCHANGED**, because the
change was in y only. The side silhouette moved 31343 -> 31043 px, which is the
cap's lost depth and nothing else. **No downstream number changes; the game
build's MB_FIT 1.12 stands and needs no re-derivation.**

A note on the register itself: `--only rammer` alone writes `_fit_report.json`,
NOT the named register, so my first fit run left `_fit_rammer_register.json` at
its 17:53 content and the visibility numbers came back byte-identical to the
pre-change run. I nearly reported those. **Identical numbers after a change you
know you made are a reason to check the file's mtime, not a clean sheet.** The
named register needs `--name _rammer_register` and has been re-run with it.

**Faults I can see in the three views, honestly listed:**

1. **THE PILE SHAFT STILL PROTRUDES BELOW THE FLOOR PLANE** the tripod feet
   stand on - clearly visible as a thin cylinder under the stump in
   `hero_back.png`. I found this at pass 6, the team lead seconded it by eye,
   and it is **unchanged** because I did not touch it this pass. Still owed.
2. **THE PILE READS AS A STOOL OR A BUCKET**, not as a driven pile. It is
   knee-high, visually detached from the frame, and in the side view it sits
   outside the tripod's foot. The broomed head wear does not read at pair
   framing at all.
3. **SIDE VIEW READS AS A LADDER OR A SIGNPOST.** Edge-on, the monkey is a thin
   slab clamped to a mast and the "it is up, so it is coming down" telegraph is
   at its weakest. This is the same fault the +0.106 margin passes on a
   technicality; see the monkey-depth note above.
4. **THE SIDE STAY READS AS A RIGID BEAM, NOT A ROPE** in the side view - it is
   straight, thick and structural there, though it reads correctly as rope from
   front and back.
5. In the side view the hauler's **hooded head overlaps the diagonal stay**, so
   the beam appears to pass through him. Occlusion only, no interpenetration in
   the geometry, but it reads badly at that one angle.
6. **WHAT IS NOT WRONG, CHECKED BECAUSE THE BEADLE WAS:** the hauler **has a
   facing**. The pale band and the two eye pinpoints are on the front of the
   hood only - `hero_front.png` shows the eyes, `hero_back.png` does not. This
   body does not have the Beadle's no-facing fault and I checked rather than
   assuming the lesson transferred.
7. The monkey is the widest upper mass in front and back view by an easy margin,
   and the rope gap between its top and the cap is visible in both. The pass-5
   telegraph holds.

### PASS 8, 18 Nov 15:3x-16:0x CT - MY OWN "PILE SHAFT BELOW THE FLOOR" FAULT IS FALSE, AND MEASURING IT FOUND A REAL ONE I HAD NOT NAMED

The 12:39 row in this file says, in my own words, "the pile is the weakest read
in the back view **and its shaft shows below the floor plane**", and the team
lead confirmed that by eye at 13:1x. Two of us looked and agreed. **It is still
wrong, and this is the third time on this body that my premise died the moment
I built something that could measure it.**

**WHAT THE SOURCE SAYS.** The pile is `aim(L.cone(0.205, 0.185, 0.36, 14),
(HX, HY, 0.0), (0,0,1))`. `lordlib.cone` is documented "base at z=0" and `aim`
only translates, so the pile's base is at z=0.0 and its top at 0.36. **Nothing
of the pile is below z=0 and nothing ever was.**

**WHAT HANGS LOWEST, MEASURED IN THE PICTURE.** Walking the alpha of
`hero_back.png` column by column for the lowest opaque row:

| what | x band | lowest row |
|---|---|---|
| hauler's feet | 117-216 | 497 |
| front leg, far | 350-400 | 493 |
| **the raked back leg** | **240-330** | **506** |

The lowest thing in the back view is **the back leg's foot**, 13 px under the
front feet. In the back view that leg stands at y +0.94 - **nearest the
camera** - and projects onto the pile's own column, so it reads as one
continuous shaft running through the pile head and out of the bottom. **We both
read a leg as a pile.** Perspective putting the nearest foot lowest is the
camera telling the truth about depth, not a model fault.

### AND HERE IS THE REAL FAULT, WHICH NEITHER OF US NAMED: THE THREE FEET WERE NOT ON ONE PLANE

`tools/art/_rammer_floor.py` compares the declared feet against the body's
global minimum z, because `minibossgen` grounds the merged body on **that**
(`ob.location.z - mn.z`), not on z=0. It found:

```
  global min z         : -0.0249   <- minibossgen grounds HERE
  tripod foot plane    : -0.0249
  pile base            : +0.0000   (+0.0249 under the feet)
```

**The pile was not below the floor. It was 24.9 mm ABOVE it** - the exact
opposite of the fault I wrote down. The cause is `limb()`: it sweeps a ring
**perpendicular to the polyline**, so a raked leg's bottom ring is tilted and
its lowest vertex sits `r*sin(tilt)` under the point the builder declared -
20.9 mm on the two front legs (13.73 deg, r 0.088) and 24.9 mm on the back one
(17.65 deg, r 0.082). The deepest of those became the floor and lifted
everything else off it, the pile included. **A driven pile floating off the
ground is the one thing this creature must not do**, because the pile is the
WHERE of the entire fight.

**THE FIX, ONE CHANGE:** raise each leg's start point by its own dip, so every
foot's lowest vertex and the pile's base land on z=0 together. Re-measured:
float **24.9 mm -> 0.4 mm**, parts below the feet 0.

**AND IT IS INVISIBLE IN THE RENDER, WHICH I SAY RATHER THAN LET THE FIX TAKE
CREDIT IT HAS NOT EARNED.** Lowest opaque row of the central column is **506
before and 506 after - zero pixels.** 24.9 mm on a 2.75 m body is ~3 px at
sheet scale and it sat behind the nearer leg anyway. This is a correctness fix
in the model, not a visual one; it will show against a real floor at a low
camera, and it is not a thing a viewer will notice today.

Fit re-run after the change: verdict **GREEN**, errors `[]`, blank check 3
files 0 failures, 3 proving views, 0 blind, **ratio 1.12 unchanged** - the
downstream number did not move, which is the proof the change was local.
Corridor: span 2.03, CORRIDOR-SAFE, 4 meshes, 1046 faces.

### THE LADDER READ FROM THE SIDE - JUDGED, AND STRUCK

The team lead seconded my own listed fault that "the frame collapses to a pole
from the side" and reads as a ladder or A-frame, and left the judgement to me.
**I strike it, and the reason is a proof rather than a preference.**

Project the two front legs along x and the polylines are **identical**:

```
  leg -x : (-0.66, 0.04, 0) -> (-0.34, 0.00, 1.32) -> (0, -0.10, 2.52)
  leg +x : ( 0.66, 0.04, 0) -> ( 0.34, 0.00, 1.32) -> (0, -0.10, 2.52)
  both, in (y, z) :  (0.04, 0) -> (0.00, 1.32) -> (-0.10, 2.52)
```

They are mirror images in x and **agree in y and z at every point**, so edge-on
they are exactly coincident - zero daylight, at any distance, from any
elevation. No render was needed to know that and no render can change it.

So the side view is **not failing to show the frame; it is correctly showing
what the frame is**: an A-frame with one back prop. Plainness is the voice, and
a pile gantry seen down its own axis does look like a pole with a stay. Both
things the fight turns on still read in that view - the dark monkey stands
against pale oak on `hero_side.png`, and the broomed pile head is visible at
the foot. **A fault correctly struck is as good as one fixed.**

If it is ever wanted open from every angle the remedy is one line - split the
two front legs in y by about +-0.12 so they stop sharing a plane - and the cost
is the frame's symmetry. **Not taken: nothing is broken and the symmetry is
worth more than the third line.**

### THE SAME FAULT ACROSS THE SET - MEASURED, 12 OF 31, AND ONLY MINE IS FIXED

If `limb()`'s tilted end ring lifted the Rammer, it can lift anything with a
raked leg. `tools/art/_foot_plane_audit.py` walks all 34 builders in `ORDER`
and asks the narrow question: **does this body declare a contact at z=0.0 -
geometry a builder deliberately put on the ground - and is something else
below it?** Only then does the declared contact float.

```
  bodies 34   declare a contact at z=0: 31   bar 5 mm
    quartermaster  -0.3172 -> 317.2 mm      moulder       -0.0300 ->  30.0 mm
    reeve          -0.1700 -> 170.0 mm      pressman      -0.0256 ->  25.6 mm
    stoker         -0.0836 ->  83.6 mm      scrapwright   -0.0205 ->  20.5 mm
    sexton         -0.0720 ->  72.0 mm      sluicekeeper  -0.0130 ->  13.0 mm
    sower          -0.0374 ->  37.4 mm      boiler        -0.0120 ->  12.0 mm
                                            snarer        -0.0083 ->   8.3 mm
                                            hurdleman     -0.0060 ->   6.0 mm
  OVER THE BAR : 12 of 31 judged     seated : 19     not judged : 3
```

**AS OF 18 Nov 17:1x CT the Quartermaster is out of this list** - 317.2 mm ->
2.5 mm, under the bar. The run below says how. The table above is kept as it
stood so the fix has something to be measured against; the live table is:

```
  bodies 34   declare a contact at z=0: 31   bar 5 mm
    reeve          -0.1700 -> 170.0 mm      pressman      -0.0256 ->  25.6 mm
    stoker         -0.0836 ->  83.6 mm      scrapwright   -0.0205 ->  20.5 mm
    sexton         -0.0720 ->  72.0 mm      sluicekeeper  -0.0130 ->  13.0 mm
    sower          -0.0374 ->  37.4 mm      boiler        -0.0120 ->  12.0 mm
    moulder        -0.0300 ->  30.0 mm      snarer        -0.0083 ->   8.3 mm
                                            hurdleman     -0.0060 ->   6.0 mm
  OVER THE BAR : 11 of 31 judged     seated : 20     not judged : 3
```

**MY FIRST VERSION OF THIS AUDIT WAS WRONG AND I REWROTE IT BEFORE TRUSTING
IT.** It reported "lowest vertex below z=0" and called that the float, which
flagged the Quartermaster at 317 mm purely because it loads real pack geometry
around the pack's own origin. A body authored entirely below z=0 grounds on its
own true lowest point with **nothing** floating. The instrument now requires
**both** conditions and leaves the 3 bodies that declare no contact unjudged,
and it goes **red on empty** rather than printing a tidy zero.

**I LOOKED AT THE WORST ONE** rather than shipping a table. `quartermaster/
hero_front.png`: its two foot blocks plainly sit above the dropped halberd
lying in front of it. Some of that is the same perspective that fooled us on
the Rammer - the weapon is nearer the camera - but the model number stands on
its own, and so does the argument: **the feet and a weapon lying on the ground
both want to touch the floor, and they are on two different planes 317 mm
apart. Whichever one is right, they cannot both be.** That holds for all 12.

**ONLY THE RAMMER IS FIXED.** The other 11 are named, not touched: one change
at a time, each needs its own look, and in several the low part may be a prop
whose placement is deliberate even if its plane is not. This is a defect in
already-shipped work that I learned about this hour, which the freeze expressly
allows me to fix - it is not a new item and I have written no plan row for it.

### THE QUARTERMASTER, 18 Nov 17:1x CT - 317.2 mm TO 2.5 mm, AND IT WAS ONE BUG WEARING FOUR FAULTS

**WHAT I CHECKED FIRST, MEASURED AND NOT REMEMBERED.** I re-ran the audit in my
own `--background --factory-startup` Blender and reproduced the table above
exactly - 34 bodies, 31 judged, 12 over the bar, the Quartermaster worst at
317.2 mm. Then, because *an audit says how far and never says what*, I wrote
`tools/art/_fp_locate.py`: it wraps every `Parts.add`/`Parts.raw` and records
the line of `minibosses.py` that made each item, so the report names source
lines instead of anonymous indices. It goes **red on empty** and red when it
resolves no caller at all - a probe that attributes nothing must not read clean.

It named the part in one run:

```
  quartermaster - 35 items, global min z -0.3172
    zmin -0.3172  zmax +0.3109  bone 195v  minibosses.py:4338   x3   <- the three shields
    zmin -0.1912  zmax +1.2995  bone 460v  minibosses.py:4338        <- the offered spear
  ITEMS DECLARING CONTACT: 2   (both boot blocks, at exactly 0.0000)
```

Line 4338 is `_lay`, which carries pack geometry. So I measured the pack parts
in their own unit space, and there it was:

```
  spear_A    z  min -0.3289  max +0.6711      shield_A   z  min -0.5713  max +0.4287
```

**`_gear_mesh` scaled to unit length and never re-origined.** Its docstring
claimed "about the grip" and `_lay`'s claimed "carry a unit-length part to
`butt`", and **neither was true**: `_lay` was putting the pack's arbitrary
mid-mesh origin on the point every call site had named as the butt. Each part
was therefore sunk 0.33-0.57 of its own length backwards along its own
direction. That single error was producing four separate faults, three of which
no number in any register could see:

1. **the floor.** The three ground shields were buried past their centres,
   dragging the global minimum to -0.3172 and lifting the body's two declared
   boot blocks 317.2 mm into the air - the worst float in the set;
2. **the feather crown.** Two thirds of each sheaf shaft sat inside the torso,
   so only the heads showed. That is *the exact fault pass 2 was written to
   fix*, and pass 2's note says it was fixed. It never was - the fix was
   correct and the loader undid it;
3. **the offered spear.** Pass 2 computed the shaft's midpoint to three
   decimals and put the hand there. The arithmetic was right and the geometry
   it described was 0.66 m away, so the fist closed near the butt end;
4. **the two floor spares.** Pass 3 measured them clear of the shield faces,
   "a clear 0.76 m of floor". They still ran through the stack.

**THE FIX IS ONE LINE IN THE LOADER, NOT FOUR HAND-TUNED NUMBERS.** `_gear_mesh`
now subtracts the scaled minimum z, so a pack part's butt is at its own origin
and `_lay`'s documented contract is true. Both docstrings are corrected to say
what the code does. Blast radius measured before touching it: `_lay` and
`_gear_mesh` are called **only** by `quartermaster()` - four call sites, one
body. The procedural fallback `_spear_proc` already produced butt-at-zero
geometry, which is further evidence of which convention was intended.

**AFTER:** global min -0.0025, float 2.5 mm, under the 5 mm bar. The set goes
12 over the bar to **11**, seated 19 to **20**. `minibossgen` GREEN, 45 bodies,
0 errors, 0 blanks, quartermaster span 2.62 CORRIDOR-SAFE; `minibossfit` GREEN,
0 blanks, 3 views proved, hero ratio 0.96.

**I LOOKED AT ALL THREE VIEWS AND HERE IS EVERYTHING I CAN SEE, GOOD AND BAD.**
Fixed in the picture and not just in the number: the boots now land on the
hero's own floor line in `hero_front.png` and `hero_side.png`; the three
shields **stand** against the near leg and read as a stack of shields instead
of the sunken grey blob they were; the two spares lie on open floor in front of
them with daylight between; and the fist closes on the **middle** of the
offered shaft, so the body finally does on screen the one thing it is for.

Still wrong, named and not hidden:

- **the sheaf reads as a crown from dead-on front, and only from there.** With
  the shafts finally out of the torso the fan is now a symmetric six-spoke
  splay centred behind the head. In `three_quarter.png` and `hero_side.png` it
  reads correctly - spears standing in a quiver, raking up and back. **This is
  a one-view read and I did not chase it this run**: every change that would
  break the symmetry head-on also moves the two views where the sheaf is
  already right, and that is its own pass with its own look.
- **the quiver root is hidden.** The shafts appear to come from behind the head
  rather than out of a block, because the quiver sits inside the torso outline.
- **the tally brand's pale knob** crosses the sheaf shafts in 3/4 - the same
  family as the Beadle's pale-knob-on-pale-panel, though here it still reads.
- **the hatch with two lit dots still reads as a letterbox face** at pane
  distance, which is what pass 2 set out to kill and did not fully.
- the near boot clips the bottom corner of the nearest shield by a few mm.

**WHAT THIS COSTS THE OTHER TEN.** Nothing - the bug was in a loader only this
body uses. The other ten floats have other causes and still need their own
looks, one at a time.

### THE REEVE, 18 Nov 17:4x CT - 170.0 mm TO 4.2 mm, AND THE FLOAT WAS HIDING A 10% UNDERSIZE

**WHAT I CHECKED FIRST, MEASURED AND NOT REMEMBERED.** I re-ran
`_foot_plane_audit.py` in my own `--background --factory-startup` Blender
before touching anything: 34 bodies, 31 declare a contact at z=0, **ELEVEN over
the 5 mm bar**, not the twelve the 16:0x plan block carries and not the ten the
17:4x block carries - the Quartermaster's fix had already dropped it out of the
list and nobody had re-run it since. **THE QUARTERMASTER IS NOT IN THE OVER-BAR
LIST AND THE 317.2 mm FIGURE ON MY ROW IS DEAD.** I did not start where the row
pointed me; I started at the top of the table I measured, which is the Reeve at
170.0 mm - more than double the next (Stoker, 83.6 mm).

**THE INSTRUMENT NAMED THE LINE BEFORE I TOUCHED GEOMETRY.** `_fp_locate.py
-- reeve`: 60 items, and exactly ONE reaches below the floor by more than a
millimetre -

    zmin -0.1700  zmax +0.1700  dark  9v  minibosses.py:5642
      P.add(L.cone(0.070, 0.0, 0.34, 8), 'dark', loc=(BX+0.96, BY+0.42, 0.17),
            rot=(math.pi, 0.0, 0.0))

the chain's floor anchor. `L.cone` **bases at z=0 and tips at +h**; `rot=pi`
about X flips it point-DOWN about the item's own origin, so the correct `loc.z`
is the FULL height, not half of it. At 0.17 the point reached **170 mm below
z=0** - and `minibossgen` grounds the merged body on its GLOBAL minimum, so one
nine-vertex spike became the floor.

**WHAT IT LIFTED.** Six items declare contact at exactly 0.0 and every one of
them was in the air: the strongbox's four feet (`minibosses.py:5513`) and the
man's two boots (`:809`). The box and the officer both hovered 17 cm.

**THE FIX IS ONE NUMBER.** `loc.z` 0.17 -> 0.34, so the point lands AT z=0 and
the head sits 0.34 above it: a stake driven flush. Nothing else moved. After:
global min **-0.0042** (the spill lumps, which are spheres seated at `r*0.60`
and are MEANT to settle into the floor plane), the Reeve is off the over-bar
list, and the set is **10 of 31 over the bar, 21 seated**.

**THE FLOAT WAS WEARING A SECOND FAULT NOBODY HAD NAMED.** `minibossgen`
normalises each body to its CANON height, and the old z-span included 170 mm of
buried spike - so the part a viewer can actually see was being scaled down to
fit a height that was 170 mm of nothing. Fixing the anchor made the creature
**10% bigger on the floor**: `_report.json` footprint 2.96 m -> **3.26 m**, size
2.96x1.71x1.95 -> **3.26x1.88x1.95**. Still **CORRIDOR-SAFE** (three-cell clear
span 11.0 m), so no spawn gate changes - but any lane holding 2.96 should hold
3.26 now.

**THE FIT PROOF - I LOOKED AT ALL THREE, AND AT THE BEFORE.** `minibossfit
--only reeve`, KayKit Knight at scale 1.0, ratio 0.80, pair width 5.12 m,
verdict GREEN, blank check 3 files 0 failures, 3 of 3 proving views, border
intact. Front/side/back at `renders/art/minibosses/reeve/`.
- **BEFORE** (`hero_front.png` at 42b9156): the box feet, the boots and the
  spill all sit a clear band ABOVE the knight's soles and the spike is the only
  thing touching the floor line. The float is visible by eye, not just by
  number - about 23 px at this frame.
- **AFTER**: feet, boots and spill all land on the knight's sole line in all
  three views. Nothing clipped, nothing floating, no new gap.

**FAULTS I CAN STILL SEE, AND THE HARNESS CANNOT.**
- **the anchor does not read as a stake.** At stream distance it is a dark
  comma from the front and a thin triangle from the side - "the chain ends in a
  mark on the floor" rather than "driven in". It is correct geometry and poor
  reading. NOT fixed this pass: one thing at a time, and it is a shape question,
  not a plane question.
- the spill lumps are pale on pale and only just carry; they read in all three
  views but they are the first thing that would be lost to a dark floor tile.
- back and front are close in mass - the strongbox, hopper and man all mirror.
  The facing cues are real but small: the lock plate and the man's two pale eyes
  are front-only. Less dangerous than the Beadle's no-facing fault, but the same
  family, and I am writing it down rather than calling the body clean.
- the chain ring on the box's side reads as a handle or a keyhole in the side
  view, not as a ring the chain passes through.

**WHAT THIS COSTS THE OTHER TEN.** Nothing. This bug was one call site. The
Stoker is next at 83.6 mm and needs its own look.

### THE STOKER, 18 Nov 17:5x CT - 83.6 mm TO 0.0 mm, AND IT WAS TWO CAUSES, MEASURED ONE AT A TIME

Second body of this pass. `_fp_locate.py -- stoker` before any geometry moved:
37 items, and the floor was being set by the RAKE -

    zmin -0.0836  zmax +0.1103  dark  7v x4  minibosses.py:1050
      P.raw(aim(L.cone(0.030, 0.0, 0.20, 6), (X+1.64+k*0.14, -0.78, 0.10),
                (0.42, -0.10, -1.0)), 'dark')

four teeth, 0.20 long, aimed with unit z -0.9181 from a base at z=0.10. The
comment says **"four short teeth, biting the floor"** and the intent is right -
but the arithmetic made it **42% of every tooth BURIED**, the head's low corner
9.7 mm under with it, and the only two items this builder declares at 0.0 - the
man's two boots - lifted **83.6 mm** off the rendered floor. A tooth that passes
through the floor is not biting, and in game nothing below z=0 is ever seen, so
there was nothing to weigh against the boots. **FIXED, NOT STRUCK.**

**CHANGE 1, MEASURED ALONE: `RAKE_Z = 0.0836`** lifts haft end, head and teeth
TOGETHER, so the tips land exactly at z=0 and the three cannot drift apart.
Result on its own: **83.6 mm -> 26.4 mm**, teeth `zmin -0.0000`.

**CHANGE 2, MEASURED ALONE AFTER IT: `BASKET_Z = 0.0264`.** The lift exposed a
SECOND cause the first number was hiding - the fuel basket at `:1054` is
deliberately LEANING, `aim(..., (0.0, 0.08, 1.0))`, and a tilted base circle
does not sit on its own z: its low edge hung 26.4 mm under. The lean is the
make-do read and I kept it; the low edge now rests ON the floor. Result:
**26.4 mm -> 0.0 mm**, global min `-0.0000`, seven items declaring contact.

I report both numbers separately because one render pass carried both changes.
**THE SET IS NOW 9 OF 31 OVER THE BAR, 22 SEATED** (was 11 at the top of this
run, 12 in the 16:0x plan block).

**THE FIT PROOF - LOOKED AT, WITH THE BEFORE.** `minibossfit --only stoker`,
Knight at 1.0, verdict GREEN, blank check 3 files 0 failures, 3 of 3 proving
views. Before: boots a clear band above the knight's soles, rake head and teeth
hanging below everything. After: boots, basket and rake teeth all land on the
knight's sole line, front/side/back. No new clip, no new gap.

**FAULTS I CAN STILL SEE, AND THE HARNESS CANNOT.**
- **THE SIDE VIEW LOSES THE FIRE.** The grate is on the chest facing front, so
  at azimuth 90 the Stoker reads as "a figure with a pipe and a rake" and the
  one thing it is named for is not in the picture. Same family as the Beadle's
  no-facing fault, inverted: facing is TOO strong here, carried by one panel.
  Not touched this pass - it is a shape question and this pass was a plane one.
- the rake head box is edge-on to the front camera, so the teeth look like they
  grow straight off the haft; the rake reads as a fork rather than a rake.
- the legs are thin against a KayKit body, as the Reeve's officer is.

================================================================================
## FOOT-PLANE PASS 3 - SEXTON, SOWER, MOULDER - 18 Nov 2026, 18:3x-18:5x CT

The team lead's 18:0x row: *"YOUR NEXT ITEM IS THE REMAINING FOOT-PLANE BODIES,
unchanged and still first."* The audit at the top of this run read **9 of 31
over the 5 mm bar, 22 seated**. It now reads **6 of 31 over the bar, 25 seated**.
Nothing here was remembered: `_foot_plane_audit.py` for the set, `_fp_locate.py`
for the cause, re-run between every single change.

### THE SEXTON - 72.0 mm -> 0.0 mm, two causes, measured one at a time
**CAUSE 1, ALONE: the spade digs past the floor.** `:496/:497` - blade box and
point cone are both aimed `(0.36, -0.06, 1.0)`, 20 deg off vertical, and a
tilted box or cone does NOT sit on its own `loc.z`: the blade's low corner sat
66.0 mm and the point's base circle **72.0 mm** below z=0. `minibossgen` grounds
the merged body on its global minimum, so that buried depth became the floor and
lifted the only things this builder declares at 0.0 - the man's two boots at
`:421` - 72.0 mm into the air. **`SPADE_Z = 0.0720`** lifts blade and point
together (one lift, so they cannot drift apart; the haft above only gains
overlap, never a gap). Alone: **72.0 -> 66.0 mm**, point `zmin +0.0000`.

**CAUSE 2, MEASURED ONLY AFTER CAUSE 1: the spoil heap was buried.** `:508` -
each lump is an ellipsoid of z half-height `r*0.42` sitting at `loc.z r*0.20`,
so **0.22r of every lump was under the floor**, 66.0 mm on the big one. With the
spade seated this became the new global minimum. `loc.z = r*0.42` rests each
lump ON the ground and keeps the flattened spill read. Result: **66.0 -> 0.0 mm**,
global min `+0.0000`, six items declaring contact.

### THE SOWER - 37.4 mm -> 0.0 mm, one cause, fixed BY DERIVATION
`:984` - the three shoots are raked stems, and `limb()` sweeps each ring
PERPENDICULAR to the polyline, so a leaning stem's bottom ring tilts and its
lowest vertex sits `r0*sin(tilt)` below the 0.0 the builder wrote: **37.4, 33.8
and 23.4 mm** on the three. The deepest became the floor and lifted the man's
two boots (`:853`) 37.4 mm.

**NO CONSTANT WAS DIALLED IN.** The lift is computed from each stem's OWN first
segment, so re-bending or adding a shoot cannot re-open the float. That is now
`seat(pts, r0)` in `minibosses.py`, next to `TAU`, with the fault written in its
docstring - **the general answer to the Rammer's pass-8 finding**, which until
today was being fixed body by body with hand-measured numbers. Result: all three
stems `zmin -0.0000`.

### THE MOULDER - 30.0 mm -> 0.0 mm, THREE causes, each measured after the last
1. **The man's own legs** (`:8442/:8444`), raked forward, dipped 30.0 and 19.9
   mm. Invisible - the boots cover the leg ends - but the deeper one WAS the
   floor. `seat()`; the ends stay well inside the boots. **30.0 -> 21.7 mm.**
2. **The trestle's four splayed legs** (`:8305`), same class, 21.7 mm each, and
   only visible as the floor once the man's legs were fixed. `seat()`.
   **21.7 -> 8.0 mm.**
3. **The sand-and-sprue spill** (`:8515`), 0.034 half in z sitting at 0.026, so
   8.0 mm of every lump was under. Seated at its own half-height.
   **8.0 -> 0.0 mm.**

### THE FIT PROOF - RENDERED ON A BODY AND LOOKED AT
`minibossgen` rebuilt the three glb (0 blanks, 0 errors, heights and footprints
unchanged: sexton 2.20 m, sower 3.50 m, moulder 2.36 m, all CORRIDOR-SAFE
against the 11.0 m three-cell span). `minibossfit --only sexton,sower,moulder,
reeve,stoker` against a posed KayKit Knight at scale 1.0: **verdict GREEN**,
blank check **15 files, 0 failures**, **3 of 3 proving views on every one**,
ratios sexton 1.00, sower 0.92, moulder 1.18, reeve 0.80, stoker 0.98.

**WHAT I SAW IN THE PICTURES.** Sexton front/side/back: boots flat, the spade
point touching, the three spoil domes resting on the ground, nothing floating.
Sower: boots flat and all three stems planted - in the side view their bases are
now IN THE PICTURE (see the next section). Moulder: boots, the four trestle feet
and the row of spill lumps all on one line.

### *** AND THE HARNESS COULD NOT SEE A CUT. I FOUND IT BY MEASURING. ***
Looking at the sower's side render I thought the hero and the creature were not
standing on the same line, so I measured the lowest opaque row of each subject
in every hero view rather than trusting my eye. **Two findings, and the second
is the serious one.**

**(1) THREE HERO SIDE RENDERS WERE CLIPPED AT THE BOTTOM EDGE - sower, reeve and
stoker, the last two ticked only hours ago.** Content sat on row 519 of 520.
`minibossfit`'s checks on the hero views were **BLANK ONLY**: `minibossgen`
asserts border alpha, this file never did, so a creature with its feet cut off
by the frame returned GREEN. `fits_frame: true` sitting beside it is computed
from pair WIDTH and was never answering the question. **A clipped render is not
a blank one** - same family as pass 11's `head_glow_px: 156`.
FIXED, AND IT IMMEDIATELY EARNED ITS KEEP: the border check is now in
`minibossfit` per edge and goes RED by name. My first camera fix had the sign
backwards and the new check went red on three MORE views within the minute -
raising the aim point raises what the frame covers and pushes the subjects DOWN.
The cause is that the camera is elevated 6 deg, so a separation in DEPTH becomes
one in IMAGE HEIGHT; the aim point now drops by `sin(6deg) * half the pair's
depth span`. Re-run: **0 edge contacts on all 15 views.**

**(2) NOT FIXED, AND THE LEAD SHOULD KNOW BECAUSE IT IS HOW WE ALL READ THESE
SHEETS: "one fixed ground line" is true of the WORLD, not of the PICTURE.**
Hero bottom row minus creature bottom row, after the fix: front +21..+25 px,
back +29..+41 px, side **-40..-59 px** (0.15-0.43 m at this scale), on all five
bodies including both ticked ones. The world plane is shared; the projection of
it is not, because the two subjects sit at different depths under a tilted
camera. **Comparing one body's own parts across a view is sound** - which is
what the lead did on the stoker and the reeve, and those readings stand - **but
comparing the hero's bottom to the creature's bottom in these pictures will show
a float that is not there, or hide one that is.** I have not touched it: it
changes the framing of every render in the set and belongs in a pass of its own.

### FAULTS I CAN STILL SEE AND DID NOT FIX (this was a plane pass)
- **THE SEXTON HAS NO BACK.** From behind, the hod grid hides the man entirely:
  it reads as a board on two legs, no head, no facing. Same family as the Beadle
  and the Reeve, and worse than either because the grid is the whole silhouette.
- **THE SEXTON'S MECHANIC IS NOT COUNTABLE FROM THE DOORWAY, WHICH IS THE ONE
  THING IT IS FOR.** The docstring says twelve pigeonholes, five plugged and
  LIT; the render shows a **3x3 = nine** cell frame and the plugs read as pale
  grey slabs on pale grey with no light in them. The geometry and the idea
  disagree - that is a content fault in my own shipped work and it is named here
  rather than quietly fixed in the same pass that moved the floor.
- The sexton's spade reads as a stick with a small blade; at stream distance it
  will not say "spade".
- **THE SOWER HAS NO FACE from the side** - the hat disc covers the head
  completely - and the casting arm is a flat plank, not an arm.
- The sower's thorns vanish edge-on in the side view, so the three shoots read
  as plain poles.
- **THE MOULDER'S CAST reads as a pale mannequin egg** with a visor band, and
  its arm is the same plank shape as the sower's.
- The moulder's six spill lumps are evenly spaced and now sit proud of the
  floor; in a row they read as coins rather than spill.

================================================================================
## THE REEVE'S FACING FROM BEHIND - ANSWERING THE TEAM LEAD, 18 Nov 18:5x CT

Asked: *"THE REEVE HAS WEAK FACING FROM BEHIND ... Look at it and tell me
whether you agree; if you do not, say so with the geometry and I will take that
answer."*

**I AGREE, AND THE GEOMETRY SAYS WHY.** I looked at `reeve/hero_back.png`
again, not at the register. Nothing on that body is back-only. The hat is a
flat disc with no brim asymmetry, so it has the same outline from either side.
The arms are out roughly symmetrically. The apron slab is applied to a round
torso, so its edges show from behind as a pale panel and it reads as a front.
The boots and legs are mirrored. The only asymmetries in the whole figure -
the hand on the box rim and the slung tally sticks - are SIDE features, not
back ones, and both are nearly edge-on at azimuth 180.

**AND THE REGISTER CANNOT EVER CATCH THIS.** `seen: 1.0` measures how much of
the creature a viewer can SEE past the hero. A body with no facing is fully
visible. The number is right and the question is not in it.

**NOT FIXED THIS RUN, AND I WILL NOT PRETEND IT IS SMALL.** The honest fix is
one back-only mass that cannot be mistaken for a front - a slung coil, a strap
across one shoulder, a tally board on the back - plus a brim that is deeper at
the front than the back, so the hat's outline itself says which way he faces.
Both change the silhouette, so they want their own pass with a before/after
pair, not a corner of a foot-plane run. **THE SEXTON IS WORSE AND IS IN THE
SAME QUEUE** (see the pass-3 faults above: from behind the hod grid hides the
man completely).

## THE DAUBER - "Wetwall", the 37th (20 Nov 2026, 10:3x-11:0x CT)

**MY OWN COUNT, MEASURED OFF `tools/art/minibosses.py` BY AST WALK, NOT QUOTED
FROM A PROMPT.** `CANON` and `BUILDERS` each carry **50 keys and agree exactly**
- no builder without a canon row, no canon row without a builder. **14 of those
are VARIANT BODIES** (`_chibi` x12, `_tall`, `_chibi_tall`), so the distinct
miniboss count before this one is **THIRTY-SIX**. My prompt says 33, which was
true on 18 Nov. The Dauber is the **37th**.

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `dauber` | Wetwall | 2.58 | keep | **IT WALLS YOU IN** - it lays a fresh course every time you hurt it and the floor you have left to fight on gets smaller. The course goes up WET and can be broken by anything; once it sets, nothing the party carries will open it. The choice expires while you argue about it. | 0.42 |

**WHY A WALL.** I read all 36 existing idea lines before designing, because a
re-skin is the one failure this slot cannot absorb. Nothing in the set TAKES THE
ROOM AWAY A COURSE AT A TIME: the Hurdleman divides the floor once, the
Sluicekeeper floods it, neither SHRINKS it and neither puts a **perishable
window** on the answer. That window is the new verb - wet breaks, set does not.

**MEASURED, GEN PASS 5:** 4 meshes, 1,300 faces, size 1.65 x 1.56 x 2.58 m,
footprint span **1.65 m** against the 11.0 m three-cell corridor -
**CORRIDOR-SAFE, margin 9.35 m, NOT room-locked.** **UNDER-LID.** Blank check 3
files, 0 failures; 0 frame clips.
**FIT, ON A REAL POSED KayKit Knight (2.45 m, 8 parts):** verdict **GREEN**,
ratio **1.05**, pair span 3.52, fits_frame true, 3 of 3 proving views, 0 blind
views, blank 3 files / 0 failures.

### THE FAULTS I CAN SEE, AND THE FIRST ONE IS THE RUN'S BEST FINDING

1. **PASS 2 SHIPPED A FLIGHT OF STAIRS AND EVERY NUMBER WAS GREEN.** Pass 1
   stepped five blocks up and out along the pole while leaving each block
   AXIS-ALIGNED. Blanks 0, border 0, span 1.87 m, GREEN fit, five blocks
   countable - and `front.png` is unmistakably a staircase coming off a mason's
   shoulder. A stepped run of level slabs IS a staircase; that is what the shape
   means. Fixed by rotating the blocks onto the pole's own axis.
2. **AND THEN IT WAS A LADDER - AT ONE SIZE ONLY, WHICH IS WHY NOTHING CAUGHT
   IT.** At 700 px the hod reads as five mortared blocks on a shaft. **Shrunk to
   the hero-scale cell - roughly what a viewer gets from across a room, the only
   distance that matters for a set piece - the stone loses its solidity, the
   four joints become rungs and the thing is a ladder.** All instruments stayed
   green through three passes of it. A ladder needs TWO STILES: pass 4 removed
   one (the second trough board) and the read survived, because the pole's
   overhang ABOVE the stack and the full-length board were still a pair. Pass 5
   cut both - the shaft now stops INSIDE the load and the board is a lip under
   the bottom two courses. **THE LESSON, WRITTEN DOWN: A SILHOUETTE THAT IS
   CORRECT AT RENDER SIZE CAN BE WRONG AT PANE SIZE, AND NO ASSERTION IN THIS
   HARNESS LOOKS AT PANE SIZE.** Judge the fit sheet's cell, not the body shot.
3. **A COLLISION THAT EXISTED ONLY IN PROJECTION.** Pass 1's plumb bob (x +0.46)
   and the lime bag (x -0.40) are 0.86 m apart and never touch. In `side.png`
   the camera looks ALONG X, that separation collapses, and the spike is driven
   clean through the sack. No intersection test would ever have reported it.
4. **I SHIPPED A MONOCHROME BODY BY AVOIDING A MONOCHROME HUE.** Pass 1 put the
   smock at (0.112,0.118,0.126) against a dark slot at (0.070,0.068,0.062) -
   0.04 apart in value. Smock, apron, boots and hod frame read as ONE dark mass.
   The register's defect arrived from the other direction: one VALUE, not one
   hue. Lifted to (0.173,0.186,0.208) at pass 2.
5. **THE SIDE VIEW IS STILL THE WEAKEST OF THE THREE** - same honest verdict the
   Moulder's write-up gave its own. Edge-on, the four joints show their full
   faces as a stepped run of dark bars; the stiles are gone so it is no longer a
   ladder, but it is the least legible of the three cameras.
6. **THE TROWEL IS MOSTLY HIDDEN BEHIND THE PAIL IN THE FRONT VIEW**, and edge-on
   in the side view it still reads as a flat paddle rather than a trowel. It is
   the verb of the whole body and it is the quietest object on it.
7. **THE LOWEST BLOCK PASSES CLOSE BEHIND THE HEAD.** It does not occlude the
   eyes or the face panel in any of the three views, but the margin is small and
   a camera between front and three-quarter could eat the face. The Moulder's
   crucible welded itself to a head exactly this way and the occlusion test
   passed, because that test asks whether the HERO can see the CREATURE, never
   whether one part of a creature has eaten another.
8. **THE LAID COURSE ON THE FLOOR IS A DETACHED ISLAND IN THE SIDE VIEW** - it
   sits clear of the body silhouette with daylight around it. Deliberate (it is
   the wall he has already laid, in front of his own feet) but it is the same
   shape `_colour_read` flags as a floating fragment on other bodies.
9. **THE PALE SLOT IS CARRIED ALMOST ENTIRELY BY THE UNLAID STOCK.** The wet
   daub itself - the bed joint, the pail's dome, the squeeze-out, the smear on
   the blade - is four small objects. The material pair reads; the WETNESS is
   argued by roughness 0.44 and by nothing else.
10. **NOTHING HERE PROVES THE COUNT IS FIVE AT PANE SIZE.** I can count five in
    the 700 px panes and I believe five in the hero cell, but no assertion
    measures the joint separations after downscale. That is the instrument this
    body wants next and it does not exist.

### FOR THE GAME BUILD LANE - I TOUCHED NO `.gd` OUTSIDE `tools/art/`

- `scripts/bestiary.gd`: `assets/monsters/minibosses/dauber.glb`, **STATIC** - a
  `model` path and **NO `anims` entry**. `h = 2.58`, art's measured number; do
  not re-derive it.
- theme **`keep`** for the set-piece roll (joins the Porter, the Paviser and the
  Reeve).
- **CORRIDOR-SAFE at 1.65 m. No spawn gate needed, not room-locked.**
- Cheapest honest version of the mechanic: on each Nth point of damage, spawn one
  wall segment across a random chord of the room with a `wet` timer; while wet it
  takes damage from anything and breaks; when the timer expires it becomes
  collision that nothing removes. Five segments total, matched to the five blocks
  the art shows. The art carries the read whether or not the floor actually
  shrinks.
- **A note on provenance, not a blocker:** `minibossgen` ran with
  `floorgeom_stale: true` - this worktree's `scripts/floorgen.gd` still has
  `lid_y 7.0 / underside 6.5` where `origin/main` has `10.0 / 9.5`. The verdict
  is **conservative either way** (clear 3.92 m under the LOWER lid), but the
  harness is right to go red on a gate it cannot prove current.

---

## 44 - THE PITMAN ("Underfoot"), crypt. PASS 3.

**IT TAKES THE FLOOR.** It does not wound and it does not grab. Every beat it
opens a pit under whoever is standing where it wants them not to be; that
delver spends their next beat climbing out on the ladder it leaves them, and
**the pit stays** - the room the party finishes in is not the room they
started in. The count is not a count of heroes, it is a count of ground.

Built this run, 20 Nov, the 20:34 CT firing, in three passes.

`minibossgen`: **ok true, 0 errors, 0 blanks**, span **3.10 m -
CORRIDOR-SAFE, UNDER-LID** against floorgen's own 11.0 m clear / 9.5 m
underside, **3 merged meshes, 932 tris**. **NOT ROOM-LOCKED** - no spawn
gate needed.

`minibossfit --evenlight`: **GREEN**, `errors []`, `blind_views []`,
creature_h **2.30** / hero 2.45 = ratio **0.94**, pair_w **4.96**,
`fits_frame` true, **3 proving views**, `blank_check` 3 files / 0 failures,
and every `frame_edge` count is **0** on all three views. Register at
`renders/art/minibosses/_fit_pitman_register.json`.

### WHAT I LOOKED AT AND WHAT IS STILL WRONG

All three hero views, opened full size, both passes. Three views are three
different pictures: front is the boarded ring with the ladder out of it, side
is the ladder in profile with the man over his mattock, back is the spoil
heap with the ring behind it.

**PASS 1 -> PASS 2 changed two things, judged separately:**

1. **THE MAN'S VALUE (worked).** I wrote the rule "the pale things are the pit
   and the ladder, everything else gets out of their way" directly above the
   function and then built the man out of the PALE material - in the same run
   in which I wrote up the Tanner's pale-on-pale hides. Head-on he was a stack
   of pale blobs against a pale ladder and did not read as a man. Dark now; he
   reads in all three views.
2. **THE LADDER'S PLANE (worked).** My own written prediction was that the flat
   pit would collapse head-on and the ladder would save it. The pit survived
   head-on. **The ladder failed, side-on** - its plane was exactly edge-on, so
   all six rungs vanished and the one tall object read as a plain prop. Yawed
   40 deg; the side view now shows six rungs.

3. **THE SPOIL HEAP (pass 3, worked, and it went RED on the way).** It was
   three smooth spheres: boulders, not dug earth; it stood directly behind the
   man and took his legs away side-on; and from the back it hid the kerb
   completely. Now five broken angular clods with two pale shoring timbers in
   them, moved off his line and kept below the kerb. His legs read side-on and
   the ring of boards reads from behind. **My first attempt gave the heap a
   metre more room and the frame-edge assertion went RED** - span 2.85 -> 3.85,
   pair_w 5.71, front cut 50 px left, back cut 48 px right. The guard caught
   something I would have called generosity.

**STILL WRONG AFTER PASS 3, AND THE REGISTER IS GREEN ON ALL OF IT:**

- **The mouth does not read as a hole.** The sunk drum has a lit top face and
  no depth, so it reads as a dark lid or a tarpaulin laid over the ring. A
  hole has to be darkest at its centre. Untouched this run.
- **Pass 3 put a new fault in while removing two.** The pale shoring timbers
  in the heap are the kerb boards' own value, so the floor line is now a busy
  band of similar pale fragments and the kerb reads as part of the rubble
  rather than as a ring. Fewer timbers, or darker ones, or none.
- **The mattock head does not read as being in the ground** - dark on dark;
  only the pale upper haft reads.
- **The man is still dark-on-dark against the mouth head-on**, though the
  spoil fix gave him his legs back in the side view.

Next pass is the mouth and then the pale count at floor level. Not done this
run and not claimed as done.

### FOR THE GAME BUILD LANE - I TOUCHED NO `.gd` OUTSIDE `tools/art/`

- `scripts/bestiary.gd`: `assets/monsters/minibosses/pitman.glb`, **STATIC** -
  a `model` path and **NO `anims` entry**. `h = 2.30`, art's measured number;
  do not re-derive it.
- theme **`crypt`** for the set-piece roll (joins the Sexton and the Scraper).
- **CORRIDOR-SAFE at 3.10 m, UNDER-LID. No spawn gate needed, not
  room-locked.**
- `MB_FIT["pitman"]`: ratio **0.94**, tag **"crypt"**, 3 proving views -
  **copy it from the register, do not re-derive it.**
- **HOLD `MB_NAME["pitman"]` until content writes `by_key.pitman`**, the same
  way the Winder is held. The canon name is **"Underfoot"**.
- Cheapest honest version of the mechanic if displacement exists: on each Nth
  point of damage, mark one occupied cell impassable and cost its occupant one
  beat. **If the engine has no cell-removal mechanic, say so plainly and do
  not invent one** - the body, the fit and the draw are the item.

---

# 45 THE TITHER - "Tenthpart", theme `prison`. 21 Nov 2026, 11:4x-12:4x CT.

**IT WILL BE PAID.** It does not come to kill you and it cannot be driven off.
It steps into the way with its balance up and one hand out flat and asks for
the tenth of what this floor has paid you so far. **Pay it and it stands aside
that same beat** - no blows, no losses, the set piece is simply over. Refuse it
and the hand closes and it is the hardest thing on the floor, and whatever it
puts down it takes the whole purse off.

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `tither` | Tenthpart | 2.42 | prison | **IT WILL BE PAID** - a tenth of the haul and it stands aside; refuse and it is the hardest thing here | 0.30 | 2.39 |

## WHAT I CHECKED BEFORE I BUILT IT, AND THE THREE DESIGNS IT KILLED

The bar is ONE IDEA THAT CHANGES THE FIGHT, so the first work of the run was
reading **all 44 existing gimmick strings out of `minibosses.py`** - not the
prompt's summary of them, which was nine bodies out of date and said 33.
**`ast.parse` gives ORDER 44 entries, 44 unique**, and I read every `IT ...`
string in the file. Three designs died on that reading and one died before it
was drawn:

- **a bellows that blows the line back down the corridor.** The **WINDER**
  already takes GROUND: *"every turn of the drum drags whoever is hooked back
  toward the mouth of the chamber"*. Same effect, different machine. Dead.
- **a capstan that re-orders the party.** The **RELIEF** already heaves a
  quarter turn and brings the whole line round one place. Dead.
- **a timberman drawing the props so the roof comes down on a count.** The
  **SLUICEKEEPER** already winds its hazard open *"a step at a time"*. An
  escalating room clock is one fight shape, not two. Dead.
- **a strongbox silhouette** was dead before it was drawn: the **REEVE**
  carries one (`_strongbox`), and the **TALLYMAN** already owns counting.

**What is NOT in the other 44 is an EXIT CONDITION.** Every one of them ends
when it dies. This one has a second door, and the party - on a stream, the
chat - chooses which. The verb is new, not the monster. That is the whole
claim being made for it and it is the only one.

## THE FIVE PASSES, AND WHICH OF MY OWN PREDICTIONS WERE REFUTED

I wrote four predicted faults into the builder docstring **before** rendering,
so the picture could refute me rather than confirm me. Two were wrong:

- **REFUTED - "the cords will not read."** Three tubes per pan at r 0.016 read
  cleanly in every view, including at hero-sheet size.
- **REFUTED - "the beam will be edge-on in the side view"** (the Pitman's
  ladder fault). The 34 deg yaw answered it at pass 1 and it never recurred.
- **CONFIRMED - "the open palm will not read as a hand."** Still true after
  five passes. See the open faults below.
- **CONFIRMED - "the balance eats the height budget."** The man reads shorter
  than a 2.42 m figure because the instrument is inside the bounds.

| pass | change | what the picture said |
|---|---|---|
| 1 | first build | balance reads; **the beam cut straight across the hood in BOTH views** and the low pan hid the asking hand |
| 2 | A: balance out on a straight arm; B: hump shrunk; C: legs shortened, torso thickened | front **clear**; **side still had the beam across the head** - a fix aimed at one camera is not a fix |
| 3 | E: balance dropped to chest height; F: eyes enlarged and moved forward | both views **clear**; eyes read head-on for the first time, **but pass 3 put them proud of the cowl and from the side they read as two pale lumps on the rim** |
| 4 | G: eyes pulled back to the mouth of the void | the fault **pass 3 itself introduced**, corrected |
| 5 | H: every radius up, stance wider | **only the hero-beside render could show this one** - see below |

**THE FIT RENDER EARNED ITS KEEP AT PASS 5.** Beside the real posed KayKit
Knight the body was **SPINDLY**: the heroes in this game are chibi - thick
limbs, heavy boots, big head - and a realistically-proportioned figure next to
one reads as a different art language rather than as a monster. Nothing in the
body-only sheet showed it; the pair did. Pass 5 raises every radius and widens
the stance. It is **closer** to the register now, not identical, and the
figure is still the leaner of the two on purpose.

## THE NUMBERS, AND WHAT THEY DO NOT SAY

- `minibossgen`: **ok true, blank [], errors [], frame-edge clean.** Span
  **2.39 m CORRIDOR-SAFE**, **UNDER-LID**, **4 meshes / 1230 faces**.
- `minibossfit`: **verdict GREEN, ok true, errors []**. `pairs.tither`
  creature_h 2.42, hero_h 2.45, **ratio 0.99**, pair_w 4.27, fits_frame true,
  all three views `proves: true`, `seen: 1.0`.
- `_backlamp_guard`: **GREEN, audited 45, red [], calibration pair still
  splits** (bad 0.20386 / good 0.06788, so the red arm fired and the verdict
  is earned). **Tither back distance 0.08541** against the 0.1550 cap, side
  0.01869, min ground 3537 px - **rank 7 of 45, and the worst body is still
  the boiler at 0.11890, not this one.** Nothing emissive was put on the back
  of this body on purpose, which is the decision that number is measuring.
- **A NOTE ON THAT GUARD, WHICH IS MINE FROM THE 10:4x RUN:** it imports PIL
  at module scope, so **it cannot be run through the Blender bridge** -
  Blender has numpy and no PIL, and cruzader has no system python. It runs
  fine under `python3` on the Linux bridge, which is how it was run here. Not
  a wrong answer, but a seat that reaches for it from the Windows side will
  get `ModuleNotFoundError` and should not read that as a failed audit.

**AND `seen: 1.0` ON EVERY VIEW STILL DOES NOT SAY THE BODY READS**, which is
why the faults below come off the pictures and not off the register.

## STILL WRONG AFTER PASS 5 - WRITTEN DOWN RATHER THAN HIDDEN

Every number above is green for all of these.

- **THE OPEN HAND DOES NOT READ AS A HAND.** It reads as a small tray or a
  bracket stuck to his left hip with two discs on it. This is half the pose -
  the half that says *transaction* rather than *threat* - and it is the one
  predicted fault that five passes did not fix. It wants fingers, or a
  forearm turned so the palm faces the camera, or to be dropped for a
  different asking gesture.
- **THE HEAD READS AS A MASK, NOT A COWL.** A dark dome with two pale discs
  in a dark void. It carries at distance and it gives the body its facing,
  but the hood's silhouette is not distinguishable from a helmet.
- **A DARK WEDGE ON THE LOWER TORSO.** Visible front and side; it is the dark
  satchel plus the body's own self-shadow, and in the side view it reads as a
  hole in him rather than as a bag. I have not proved which of the two
  dominates and I am not asserting it.
- **THE BACK HUMP IS AMBIGUOUS.** From behind it reads as a lumpy shoulder
  bag rather than as a stooped cloak.
- **THE ARMS ARE SHORT** relative to the pass-5 body, and the balance ring now
  sits very close to the end of the right arm.

**THE FACING TEST PASSES**, which is the thing the Beadle failed: from behind
there are no eyes, no face, no pale band wrapping the head - a plain dome, the
hump, the satchel and the balance seen from the rear. Front and back are not
the same picture.

### FOR THE GAME BUILD LANE - I TOUCHED NO `.gd` OUTSIDE `tools/art/`

- `scripts/bestiary.gd`: `assets/monsters/minibosses/tither.glb`, **STATIC** -
  a `model` path and **NO `anims` entry**. `h = 2.42`, art's measured number;
  do not re-derive it.
- theme **`prison`** for the set-piece roll (joins the Gaoler; prison was the
  thinnest of the fourteen themes at two bodies, and is now three).
- **CORRIDOR-SAFE at 2.39 m, UNDER-LID. No spawn gate needed, not
  room-locked.**
- `MB_FIT["tither"]`: ratio **0.99**, tag **"prison"**, 3 proving views -
  **copy it from the register, do not re-derive it.**
- **HOLD `MB_NAME["tither"]`** until content writes `by_key.tither`, the same
  way the Winder and the Pitman are held. The canon name is **"Tenthpart"**.
- **THE MECHANIC NEEDS A CHOICE, NOT A STAT**, and it is the only miniboss
  that does. Cheapest honest version: when the set piece resolves, offer the
  party one extra option - *pay the tenth* - priced off the floor's haul so
  far; taking it ends the encounter with no combat round and no loss, and
  declining it applies whatever "hardest thing on the floor" means in the
  engine already. **If there is no way to end a set piece other than by
  killing it, say so plainly and do not invent one** - the body, the fit and
  the draw are the item, and the second door can wait for an engine that has
  one.

---

## 46 THE BLOWER - "Deadair" - 21 Nov 2026, 12:3x-12:5x CT

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `blower` | Deadair | 2.48 | fogbound | **IT TAKES THE AIR** - it works the bellows backwards and draws the room empty a stroke at a time; the party acts slower each stroke and nothing done to the man slows the count. Hole the bag and the count stops. | 0.48 | 1.88 |

### WHAT I CHECKED FOR BEFORE DESIGNING IT, MEASURED NOT REMEMBERED

`ORDER` was parsed out of `tools/art/minibosses.py` - every `ORDER = ORDER +
[...]` evaluated and concatenated, not grepped - and it carried **45 keys**. I
then read all 45 idea strings out of `CANON` before writing a word of this
one. **Nothing in the set is a clock.** The four nearest and why each is a
different fight are written into the file above the `CANON.update` so the
argument travels with the code: the Stoker starves a resource OUTSIDE itself,
the Rammer is ONE telegraphed blow on a beat, the Snuffer takes what you see
by rather than what you act with, and the Tither is an exit condition the
party chooses. This is the first body in the file whose fight has a running
cost per beat, and the cost is on its own body where a viewer can watch it.

### THE FIVE PASSES - ONE CHANGE EACH, EACH JUDGED ON A PICTURE

| pass | the ONE thing changed | what the render then showed |
|---|---|---|
| 1 | first build | **A DARK LUMP WITH A BUCKLER.** The bag was X-squashed into a wedge narrower than the man's own shoulders, so the FRONT view - the view a viewer watches the fight from - showed no bag, no ribs and no clock at all. |
| 2 | the bag's squash axis: flatten DEPTH, widen to 0.520 (shoulders are 0.330) | Pale ribbing now stands clear on both flanks from the front. The clock is visible. The nozzle became the worst thing in the frame. |
| 3 | the nozzle alone - swung down and outboard, shrunk | The buckler read is **gone**. It was aimed straight down the front camera's axis, which gave a perfect pale ring with a black disc in it at chest height; the body was saying IT BLOCKS, which is the Paviser's fight. |
| 4 | the rib proportion: 36/28/36 instead of equal bands | Reads as a bellows rather than a striped barrel, and the dark groove no longer merges with the lid into one black block at the crown. |
| 5 | the stance - feet planted under/behind the hips, torso forward | The man no longer reads as toppling backwards, which is what feet-forward plus all the mass behind must look like. |

### THE FIT PROOF - I LOOKED AT ALL SIX RENDERS

`renders/art/minibosses/blower/` - `front` / `side` / `three_quarter`, and
`hero_front` / `hero_side` / `hero_back` beside a real KayKit adventurer at
scale 1.0.

- **blank-and-border: CLEAN.** 3 files, 0 blank failures; border alpha
  measured myself on all six PNGs, 1px edge and 2px band, **max alpha 0 on
  every edge of every view**. *I had read a frame clip off the pass-1 side
  render by eye and the measurement refuted me* - the lid board ends about
  55px short of the right edge. Recorded because the lane's standing rule is
  that the picture beats the number, and this is the case where it did not.
- **fit register GREEN**, `ok true`, `errors []`, `unproved_cells []`,
  `blind_views []`. `blower` ratio **1.01**, margin 3.31, `fits_frame true`,
  3 proving views, 48 rows judged.
- **BACK-LAMP GUARD GREEN, audited 46** (the new body included): even light on
  all three views and a real floor under it.
- **THE FACING TEST PASSES.** Back view: the pale ribbed lung fills the frame,
  two patches on it, the lid across the top, dark legs below, **no eyes, no
  mouth-void, nothing emissive anywhere.** Front and back are not the same
  picture and neither is the side.

### WHAT IS STILL WRONG WITH IT - I CAN SEE ALL OF THIS

- **THE NOZZLE IS CRUDE.** From the side it is a megaphone jutting forward at
  hip height and you cannot see where it comes from; the run from the bag's
  foot is hidden behind the thigh. Pass 3 removed the *wrong* read; it did not
  make it a good one.
- **THE MAN IS A DARK PILLAR.** From the side after pass 5 both legs align
  into one column and the torso is an undifferentiated mass with a head on it.
  The stance fix cost the figure some legibility and I am not hiding that.
- **THE LID OVERHANGS THE BAG** on both sides in the back view and reads as a
  plank laid across rather than a board clamped onto leather.
- **THE SPARS READ AS KNOBS.** From the front and from behind the two handle
  tops are little dark stubs beside the head - they read as ears or antennae,
  not as the two handles a man is working.
- **AT HERO SCALE THE FLANKING RIBS READ AS A FRILL** rather than as one lung
  seen past a body, and the figure is narrow and long-legged next to the
  stocky KayKit knight.
- **THE BAG'S TAPER TO THE HIP IS ABRUPT** and the lowest two bands crowd.
- **ONLY TWO OF THE THREE PATCHES ARE VISIBLE** in the back view; the third is
  on the near flank and is easy to miss from the front.

### FOR THE GAME BUILD LANE - I TOUCHED NO `.gd` OUTSIDE `tools/art/`

- `scripts/bestiary.gd`: `assets/monsters/minibosses/blower.glb`, **STATIC** -
  a `model` path and **NO `anims` entry**. `h = 2.48`, art's measured number;
  do not re-derive it.
- theme **`fogbound`** for the set-piece roll (joins the Bellman, Fenman and
  Fuller; fogbound was three bodies and is now four).
- **CORRIDOR-SAFE at 1.88 m, UNDER-LID. No spawn gate needed, not
  room-locked.** 1868 faces.
- `MB_FIT["blower"]`: ratio **1.01**, tag **"fogbound"**, 3 proving views -
  **copy it from the register, do not re-derive it.**
- **HOLD `MB_NAME["blower"]`** until content writes `by_key.blower`, the same
  way the Winder, the Pitman and the Tither were held. The canon name is
  **"Deadair"**.
- **THE MECHANIC IS A PER-BEAT COST, NOT A STAT**, and the cheapest honest
  version is a stacking initiative or action-delay penalty on every delver in
  the room that grows one step per round while the body lives, cleared the
  moment it dies. The "whoever carries the most gives out first" half is a
  nicety - **if encumbrance is not already a term in the engine, drop that
  half and say so rather than inventing one.**

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `almoner` | The Almoner | 2.52 | shrine | **IT DEALS YOUR KIT OUT AGAIN** - the party's weapon dice are dealt back to the wrong hands; the total is unchanged and every role is wrong | 0.35 | 2.48 |

See docs/art/ALMONER_THE_50TH.md - four passes, and pass 1 shipped the shield its own docstring forbade.

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `panner` | Onceround | 2.26 | confection | **IT IS SHUT UNTIL THE PAN COMES ROUND** - not armoured and not immune: for most of the fight there is nothing of it to hit. The one opening swings past once a turn, blows on the shut wall do nothing at all, and the party's job inverts from dealing damage to withholding it | 0.14 | 1.73 |

See docs/art/PANNER_THE_51ST.md - four passes, and the pass that moved NOTHING
is the finding (a byte-identical re-render proved the object I changed was not
the object in the picture; `lordlib.cone` caps BOTH ends by default and my "lip
ring" was a solid 1.28 m plate over the mouth).
- `MB_FIT["panner"]`: ratio **0.92**, creature_h 2.26 against a hero measured
  at 2.45, 3 proving views, `fits_frame true`, `frame_edge` all zero - **copy
  it from `renders/art/minibosses/_fit_report.json`, do not re-derive it.**
- **CORRIDOR-SAFE at 1.73 m, UNDER-LID. No spawn gate needed, not
  room-locked.** 822 faces, two material meshes, **no emissive at all** - this
  one is machinery, so there is nothing for the back-lamp guard to find.
- theme **`confection`** for the set-piece roll, which was the thinnest theme
  in the set at two bodies.
- **HOLD `MB_NAME["panner"]`** until content writes `by_key.panner`. The canon
  name is **"Onceround"**.
- **PASS 5 (24 Nov 08:4x CT) BROKE THE RING AND TWO OF THE THREE FAULTS ARE
  CLOSED.** The lip is no longer a closed loop: `panner()` samples 57 points,
  drops the 11 that fall behind the HOPPER CONE in front projection (its own
  silhouette plus a 0.085 margin - derived, not a hand-picked angle) and sweeps
  the remaining arc. The hopper now passes through a gap cut for it instead of
  notching a closed ring, and an interrupted lip is a pan with a feed gap
  rather than a porthole. **FAULT 3 CLOSED, FAULT 5 CLOSED.**
  The blame correction from 07:34 stands and is why this is the fix: it was the
  HOPPER CONE, not the chute, that cut the rim - the chute's two ends both fall
  inside the opening's projected ellipse and never touch the annulus - and
  nothing that feeds a mouth canted up and forward can miss that top arc, so
  **"move the chute" was never a fix.** The feed could not move; the lip could.
  **A/B at `panner_p4ring/` (closed) against `panner_p5ring/` (broken)**, three
  views each: pale 6,724 -> 6,340 px, coverage 321 -> 308 deg, largest gap
  39 -> 52 deg, creature bbox IDENTICAL. **THOSE NUMBERS CANNOT TELL A NOTCH
  FROM A GAP** - both shapes show a gap at the top - so the picture decided it
  and I opened it: in A the pale runs up to the hopper's edge and resumes, in B
  the cut ends stand clear of the feed. `PAN_RING=closed` reproduces pass 4.
  **STILL STANDING: FAULT 4** - the comfits are dark beads on a dark floor and
  read as RIVETS, so the front reads as a bolted drum face and nothing says
  sugar. **NEW FAULT 7, PRE-EXISTING AND NOT INTRODUCED HERE:** in the side
  view the two near legs eclipse the two far legs along X, so the frame reads
  as a SINGLE post and the body as a dish on a stand. Same family as the man's
  pass-3 eclipse. Recorded, not fixed.
  **THE BODY ON DISK CHANGED THIS HOUR**: `panner.glb` 92,472 -> 107,164 bytes,
  822 -> 958 faces, span 1.73 -> 1.74 m, still 2 materials, still CORRIDOR-SAFE
  and UNDER-LID, fit GREEN, 0 blanks, frame_edge zero in all three views.
  See docs/art/PANNER_THE_51ST.md for the pass-5 section and the arithmetic.


| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `stiltman` | Downfast | 3.20 | fogbound | **IT IS QUICKER FOR EVERY LEG YOU TAKE** - four stilts, all breakable in plain sight. Breaking one WORKS: it drops, its reach over your line shortens, and it is faster. Leave them and it strikes down past your front rank. The party owns the decision and both ways cost | 0.62 | 1.34 |

**THE 52nd IS BUILT AND IT DOES NOT READ YET - NOT READY TO WIRE.** Three
passes on 24 Nov 08:4x-08:5x CT. Gate GREEN, ratio 1.31 (3.20 m, the TALLEST
body in the set), span 1.34 m, CORRIDOR-SAFE, UNDER-LID, 602 faces, 0 blanks,
frame_edge zero on all three views - and none of that is the point: at hero
scale it reads as a SURVEYOR'S TRIPOD WITH A LAMP ON TOP, and the lost leg that
the whole mechanic is staked on is invisible at that distance. It is committed
rather than left in the worktree (the Beadle and the Panner were both caught
that way) but `scripts/bestiary.gd` and `Delve.MB_NAME` must NOT take it yet.
See docs/art/STILTMAN_THE_52ND.md - the fault list is five long and the next
change is named: a fen cloak that makes the trunk read as a person, because the
tripod read is fault 1 and everything else is smaller than it.


| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `shearman` | Cutloose | 2.51 | workshop | **IT CUTS WHAT JOINS YOU** - it does not pick a hero and takes nothing off anybody. It cuts the lines BETWEEN them: no heal, no shield thrown over a neighbour, no covering a man who is down, no aura, no shared guard. Every one of you is at full strength and completely alone, four people fighting in the same room instead of one party | 0.30 | 1.60 |

**THE 69th READS AS A PAIR OF OPEN SHEARS AT HERO SCALE - PASS 3 CLOSED IT.**
Three passes, 27 Nov 12:35-13:08 CT. Gate GREEN, ratio **1.02** (2.51 m against
a hero at 2.45), 3 proving views, `seen` 1.0 on all three, `fits_frame` true,
`frame_edge` zero on all four sides of all three views, blank check 0 failures
over 207 files, 811 faces, 4 meshes, span 1.50, CORRIDOR-SAFE and UNDER-LID.
**THAT SAME GREEN SHEET WAS TRUE OF PASS 1 AND PASS 2 AND BOTH OF THOSE WERE
WRONG** - pass 1 read as two parallel poles, pass 2 as a sword with an ornate
guard. The register cannot see what a thing looks like; the pictures decided
all three times. Pass 3 put the whole instrument above the shoulder line so
BOTH blades are drawn against air instead of one against the torso, and at hero
scale it is now plainly a pair of open shears.
The **Beadle test passes** - front carries the face oval and a 0.42 x 0.74 MID
apron mass, the back has neither plus the cord bundle on the right hip.
**ONE STANDING FAULT AND IT IS THE WORST KIND:** the cord in the jaws reads as
a HOOK, which is the Gaoler's cue. Next change is one thing - straighten both
cord pieces across the jaw so the GAP is what the eye lands on, or take the jaw
cord off entirely (the two pieces on the floor already say it and they read).
See docs/art/SHEARMAN_THE_69th.md.
