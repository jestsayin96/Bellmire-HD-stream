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
span **2.96 m, CORRIDOR-SAFE** against the 11.0 m three-cell clear span -
ratio **0.80** beside the posed 2.45 m KayKit Knight, pair_w 4.83,
fits_frame true. Procedural, no pack geometry (`pack_used` false).
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
