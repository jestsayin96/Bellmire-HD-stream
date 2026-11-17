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
