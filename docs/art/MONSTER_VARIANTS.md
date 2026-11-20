# The second class of miniboss — monster-pack variants

Written 19 Nov 2026, 22:5x CT by the ART lane, clock read off the machine with
`TZ=America/Chicago date` (22:52:19 CST). **Part 2 of the supervisor's 21:50 CT
directive**, which carries Mr. E's recipe: take a creature that already exists
in the CC0/QAL packs, recolour it, scale it past its regular version, name it,
give it a mechanic that changes the fight, and fit-proof it on a hero body to
the same standard as the thirty-six procedural minibosses.

**ONE, shipped whole, rather than five half-done** — the row said so and it is
the right instruction for a first pass.

## Lastcuff — the second one, and the ceiling nobody had measured

Written 20 Nov 2026, 01:4x CT by the ART lane (machine clock read with
`TZ=America/Chicago date`). The 01:16 ruling says **pack variants tower**, so this
one is authored to tower — and the body was chosen on a measurement, not on taste.

### What I checked for first, before modelling anything

**Nothing was modelled.** Every triangle is the pack author's; the two things this
class does are a palette swap and a number.

- **Which pack bodies can even be variants.** Measured off the kit's `Textures`
  directory this run: **exactly two creatures ship three BaseColor maps** —
  `T_Imp` and `T_Puglin`. The Puglin is Broodglut. So the Imp is **the whole
  remaining supply of this class**, and that is worth saying plainly: a third pack
  variant needs a different pack, not a different idea.
- **Whether the Imp is already in the game.** It is — `bestiary.gd` carries
  `imp` at `h` 1.30, wearing `BaseColor_1`. So this is a variant of a monster the
  viewers already know, which is the whole recipe.
- **Whether a towering body fits.** Measured on the evaluated depsgraph with the
  stray `Icosphere` dropped: native **X 1.7538** (the T-pose arm span, symmetric
  about the origin at ±0.8769) over native **Z 1.6779** (the height, feet at
  z −0.002) = **1.045 m of span per metre of height**, against the Puglin's
  **1.5767**. A third narrower. At 6.20 m the span is **6.48 m** and the 11.0 m
  corridor leaves **4.52 m** of margin. **The corridor is not what caps this one.**

### *** THE CEILING IS 6.50 m, AND IT CAPS THE WHOLE CLASS ***

Measuring the Imp's width made the corridor stop mattering, which raised the
question nobody in this house had asked: **how tall can a thing be before it is
through the roof?** Read off `scripts/floorgen.gd` this run, not remembered:

- the kit **wall tops are 4 m** — floorgen's own stairs comment sets the flight
  "3.8 m up, under the 4 m wall top";
- the floor builds a **lid** — `BoxMesh` of size `(w*G+14, 1.0, h*G+14)` at
  `position = Vector3(0, 7.0, 0)`, `SHADOW_CASTING_SETTING_SHADOWS_ONLY`, there so
  the overworld sun does not flood the floor. A 1 m box centred at 7.0 has its
  **underside at 6.50 m**.

So a creature standing on z = 0 is **through the lid above 6.50 m**, which is
**2.653×** the 2.45 m hero. Three consequences, and the first is a fault in this
lane's own shipped work:

1. **Broodglut's shipped 6.60 m is 0.10 m through the lid.** Reported, not quietly
   corrected under cover of a second change. The lid is shadows-only so nothing
   visibly clips, but the creature's head is on the wrong side of the thing that
   blocks the sun, and it is 0.10 m of margin where the register claims none is
   needed. **Mr. E's call**: drop Broodglut to ≤ 6.50, or raise the lid.
2. **Mr. E's 3× (7.35 m) is not available to any body at any width.** The corridor
   arithmetic said 3× was room-locked *on the Puglin's span*; the lid says it is
   out of reach on **every** span. Raising the lid is a one-line game-build change
   to a shadows-only mesh — but it is theirs and his, not this lane's.
3. **Everything in this class already stands head and shoulders over the 4 m
   walls.** That is a look question a picture settles, and the picture should be
   taken in the game, not here.

`tools/art/minibossgen.py`'s corridor gate compares **span only**. It has never had
a height term, which is why this went unseen for the whole class.

### The creature, and the two things the render caught that the numbers did not

**Lastcuff**, the Imp at **6.20 m** — 2.53× the hero, **4.77× its own regular imp**,
0.30 m under the lid, 4.52 m of corridor margin. Palette `T_Imp_BaseColor_3`.

**I shipped a name and a mechanic that the mesh does not carry, and the render is
what caught it.** It was authored as *"Chainsweep"*, a mace running out on a chain
to sweep the corridor end to end. Then I looked at `hero_front.png`: `Imp_Chains`
is **four shackle cuffs** (both wrists, both ankles) plus a studded collar, and
`Imp_Mace` is held flat against the hand. **There is no long chain and nothing runs
out.** The idea is replaced by one the geometry already shows — **it is still in
irons, and every one you knock off makes it faster** — which is better anyway,
because the state is **visible on the model**: five removable pieces a viewer can
count, instead of a stat. That is Mr. E's binding principle applied to a mechanic.

**And the colour number was a bad witness.** `_3`'s mean rgb is
`0.3897 / 0.3837 / 0.4154` — near-neutral, faintly blue — so this lane wrote "ash
grey" in the spec. The render is a **saturated blue-cyan skin with violet forearms,
shins and feet**. A mean over a whole 2048 map averages skin, shorts, horn, claw
and every unused corner of the UV sheet into one number: it answers *how bright*
and says nothing about *hue* or *where on the body*. Same family as `mask_of` at
pass 11. The colour is kept — blue-violet is neither the red-brown imp you know nor
Broodglut's red, which is all the class asks — but the **reason in the file now
matches the picture**.

### The fit proof — what I looked at, and every fault I can see

Rendered on the real KayKit knight at scale 1.0, front, side and back.
**Verdict GREEN**: 0 blanks, **0 frame clips**, 3 of 3 proving views, `errors []`,
`blind_views []`, `room_locked false`, 15,232 tris, 55 bones, 5 meshes.

Faults, named rather than averaged away:

1. **The side view has no readable head, and it is the worst thing on the sheet.**
   In a T-pose both arms project along the view axis, so the arms and the mace
   collapse into one horizontal bar crossing the face at eye level — the mace head
   reads as a growth off the jaw and the near wrist cuff sits over the mouth.
   **The register's `seen: 1.0` passed this**, because seen-ness is not
   readability. Same family as the Beadle's facing fault, and found the same way:
   by looking.
2. **It is a pose artifact, and this harness cannot show the pose the game draws.**
   `bestiary.gd` grafts the UAL library on at load, so in play the arms come down.
   Every number on this sheet — the side read, the 6.48 m span, Broodglut's whole
   corridor table — is measured on a **T-pose the game replaces**. *(See the
   measurement worth doing, below.)*
3. **The collar fins frame the back of the skull** and at stream distance read a
   little like a second small mask. A mild version of the Beadle fault; checked on
   purpose because of it. **The facing itself is fine** — front and back are plainly
   different (spine ridges, no face, mace on the correct side), unlike the Beadle.
4. **The mace reads as a lump, not a weapon,** in the front view: it sits flat
   against the hand with its spikes foreshortened.
5. Nothing floats, nothing gaps, nothing intersects the ground plane; feet land
   flat on z = 0.

### A defect in this lane's own harness, red-proven by its own first run

**The fit frame was sized off width alone and could not frame a tall creature.**
The first Lastcuff run went **red exactly as designed**: `frame_w` grew to 9.01 m
for an 8.34 m pair, `FRAME_H` fell out of the 760×520 cell aspect at **6.16 m**,
and the 6.20 m creature lost **65 / 47 / 65 px of head off the TOP** of front,
side and back. The border assertion — bought after System 1's cut glow — caught it
and shipped nothing.

But the harness also **could not have produced a passing sheet for any creature
taller than the frame its own width happened to buy**, and that is a defect, not a
setting. Height is now a **driver** of the frame rather than a consequence of it:
take the wider of what width needs and what height needs, keep the cell aspect
fixed so one cell is still comparable with another, and **record which of the two
drove it** (`frame_driver`, `frame_need_w_wide`, `frame_need_w_tall`) instead of
leaving it to be inferred. Second run, same creature: `frame_driver: "height"`,
`frame_w 10.181`, `frame_h 6.966`, **`frame_clips {}`**, GREEN. The red and the
green are the proof pair.

### The one measurement that would settle two open questions at once

**Re-measure the arm span in the UAL idle instead of the T-pose.** It is one pass,
and it answers both of the things currently sitting with Mr. E:

- whether Broodglut can have a true 3× **on span** (the T-pose gate is the only
  reason it cannot), and
- whether this class's side view reads at all in the pose the game actually draws.

It does **not** answer the lid, which is 6.50 m whatever the arms are doing.

## The two rulings of 20 Nov 01:16 CT — and the two design languages

Written 20 Nov 2026, 01:3x CT by the ART lane (machine clock 01:34:32 CST). Pass 4
raised two questions and sent both up rather than deciding them. The supervisor
ruled on both at 01:16 CT. **This section is the record the ruling asked this lane
to keep.**

### Ruling 1 — Broodglut holds at 2.69× (6.60 m)

2.69× is the top of the corridor-safe band and it stays. The arithmetic is in
*Pass 4* below and was re-done independently by the team lead: span/height
4.0995 / 2.60 = 1.576731 m of span per metre; 6.60 × 1.576731 = 10.41 m against a
corridor clear of 3 × 4.0 − 2 × 0.5 = **11.0 m**, margin **0.59 m**; 2.85× lands
exactly on the 11.00 wall and **3.00× is room-locked at 11.59 m**.

A true 3× is still available but it is **Mr. E's call, and it costs one of two
things** — neither taken without him:

- **re-gate on the UAL idle span.** The 1.576731 figure is measured on the
  authored **T-pose**, and that is not the pose the game draws: `bestiary.gd`
  grafts the UAL library on at load, so the arms come down and the real footprint
  is narrower. One measurement pass would say how much narrower, and 3× may well
  fit. The gate is deliberately conservative, not wrong.
- **room-lock the spawn.** A game-build wiring change, and it costs the creature
  its corridor appearances.

### Ruling 2 — the procedural 36 stay at their current scale

**Two design languages, and the distinction is the point rather than an
inconsistency to be tidied away:**

| | pack variants | the procedural 36 |
|---|---|---|
| where the threat reads | **scale** — a bigger, meaner version of a monster you already know | **the mechanic** — what it DOES is the threat |
| silhouette test | cannot pass against its own regular version (same mesh) — scale is the half that survives | each must read as itself with the colour thrown away |
| cost | a palette swap and a number | a modelled body |
| ratio band | **towers**: Broodglut 2.69× | **eye-level**: 0.80 – 1.20× |

So the 36 are not "wrong" at eye level and are not being scaled up. Mr. E's 00:10
complaint was about **Broodglut specifically**, and the directive says *variant*
minibosses, not *all* minibosses. If the two read badly side by side on stream,
that is a thing a picture settles and it gets revisited then.

### The band, measured twice, because the number this lane published was wrong

The comment in `tools/art/monstervariants.py` said until 01:3x CT that *"every one
of the thirty-six sits at the same 1.06. The whole band was eye-level."* **It was
disproved by this lane's own measurement in the same commit that wrote it** — the
team lead found the contradiction. Corrected there and recorded here. Two cuts,
run this pass:

- **off the `CANON` tables in `tools/art/minibosses.py`** — 36 procedural
  minibosses, authored height **1.95 m** (reeve) to **2.95 m** (beadle), ratio
  **0.7959 – 1.2041** against the 2.45 m hero. **Exactly two sit at 1.06**:
  snuffer and dyer, both 2.60 m.
- **off every `renders/art/minibosses/_fit_*_register.json`** — **31 pair records
  over 20 bodies**, ratio **0.84 – 1.20**, **four records at 1.06**. The extra two
  are chibi duplicates of one body, which is why a register sweep reads four where
  the authored table reads two. This reproduces the team lead's independent sweep
  exactly (31, 0.84, 1.20, four at 1.06) from a different cut.

**And it closes his one open caveat.** His net also caught records below 0.84 and
**one at 1.63**, which he did not filter to bodies and claimed nothing about. They
are the **creatures**, not minibosses: `renders/art/creatures/` holds 12 pair
records from spiderling 0.14 to **pitwyrm 1.63**, and no miniboss register sits
outside 0.84 – 1.20. Nothing unexplained is left in that sweep.

**What is true, and is what the 00:10 directive was answering:** more than half
the class is at or below a hero — **17 of 36 authored at or under 1.00** (drover at
2.44 m / 0.9959 counts) — and nothing in it towers. Broodglut's 1.06 was typical of
the band, not alone in it.

### Wiring the game build still owes from ruling 1

`scripts/bestiary.gd`, broodglut entry: `"h": 2.60` → `"h": 6.60`. Nothing else
changes, and this lane does not touch that file.

## Broodglut — the first one

| | |
|---|---|
| base | `assets/monsters/Puglin.glb`, Quaternius *Bestiary — Dungeon Monsters Kit*, QAL v1.0 |
| regular version | `puglin` in `bestiary.gd`, `h` 0.90, family `fiend` |
| recolour | the pack author's **own** `T_Puglin_BaseColor_2` (red), swapped for `_1` (olive) |
| scale | **6.60 m — 7.33× its regular version, 2.69× a hero** (pass 4; was 2.60 m / 1.06×) |
| theme | `mess` |
| idea | **IT EATS ITS OWN** — while any lesser puglin in the room still lives it takes one, swallows it and closes its own wounds. The swarm is its health; the big one is not the target. |
| shipped | `assets/monsters/minibosses/broodglut.glb`, 2.98 MB, 7,528 tris, 55 bones, static (no actions) |

### Why the Puglin and why that red

Mr. E's own example for this class was "a regular Goblin is small and green;
its variant is 1.5× and dark red/black". The Puglin is the nearest thing this
repo has to that goblin, and **the author already drew the red**: measured off
disk this run, the kit ships three base-colour maps per creature and this repo
committed only the first. So the recolour is not a tint over an olive map —
which would have gone muddy — it is a second hand-authored skin over the same
UVs, with the normal and ORM detail untouched. It cost one file swap.

### What the recolour is worth, measured

Same mesh, same camera, same lights, only the map changed
(`--ab`, `renders/art/variants/broodglut/_ab/`):

| | olive (`_1`) | red (`_2`) |
|---|---|---|
| mean rendered rgb | 0.275 / 0.265 / 0.123 | 0.303 / 0.159 / 0.163 |
| green − red | −0.010 | −0.144 |

mean rgb distance **0.134**, and **92.5 %** of the shared opaque pixels move
further than a just-noticeable 0.05. Verdict **SEPARATED UNDER THE FIT RIG**.

**Two honest limits on that number, both found by the instrument contradicting
itself rather than by my eye:**

1. **The verdict's first version could not pass.** It required a green→red sign
   flip in at least half the pixels. The same run reported the *olive* skin's
   green−red as **−0.010** — already red-dominant under the rig — so there was
   no sign left to flip and no recolour could ever have met the bar. That is a
   gate built on an assumption about the art instead of a measurement of it,
   and it is this lane's recurring fault wearing a new coat. Replaced with two
   measured quantities; `sign_flipped_frac` is kept in the record as a reading
   with no power to pass or fail anything.
2. **It is NOT a theme-light test, though I wrote that it was.** The mess key
   (1.00/0.68/0.34) and the crypt key (0.70/0.74/1.00) returned 0.1343 and
   0.1339 — the same answer to four decimals. `lordgen.add_lights` colours the
   **rim** with its third argument; the key is a fixed warm white (1.0, 0.97,
   0.92) no caller can reach. Whether a theme's own key collapses the
   difference is **unanswered**, and answering it means driving the key colour,
   which touches every register this lane has shipped.

### The fit proof — what I looked at, and every fault I can see

`renders/art/variants/broodglut/hero_{front,side,back}.png`, the real KayKit
adventurer at scale 1.0, idle pose, one fixed ground line, rendered by
**minibossfit's own `import_hero` / `place` / `shoot`** rather than a second
harness. Blank check, per-edge frame-border check and the with/without
occlusion test all come free with it, and reuse is the cheaper honesty.

Register: `renders/art/variants/_register.json` — verdict **GREEN**: 0 blanks,
0 frame clips, 3 of 3 proving views, errors `[]`, `room_locked: false`
(widest span **10.41 m** against an 11.0 m corridor clear at pass 4's scale —
and that span is a T-pose, i.e. the worst case, so the verdict errs the safe
way). At pass 3's 2.60 m the span was 4.10 m.

**What the register cannot see, said plainly:**

- **The sheet shows a REST POSE, not a stance.** The glb carries no actions —
  the pack ships Imp and Puglin rigged and unanimated, and `bestiary.gd` grafts
  the UAL library onto the regular puglin at load. So the arms are out because
  nothing is driving them, and viewers will never see this pose. **The sheet
  proves scale and colour. It does not prove stance.**
- **The front silhouette is unresolved.** Ears, arms and shoulder mass run
  together into one wide dark shape; the **side** view is the one that reads —
  a hunched brute leaning at you with a tusk and a reaching arm.
- **The held stick is nearly invisible** — same hue as the body, small, and it
  will read as nothing at stream distance. It is the pack's prop and I have not
  touched it.
- **The silhouette test the thirty-six pass cannot be passed here, by
  construction.** Throw the colour away and this *is* its own regular version —
  same mesh, same outline. What separates them is **scale and colour**, and
  only scale survives a silhouette. That is a property of the class the
  directive asked for, not a defect in this creature, and the register records
  the scale ratio instead of pretending the test was taken.
- **Height is a judgement I changed by looking.** Pass 1 authored 2.30 and every
  number was green; then the front view showed its head sitting *below* a
  hero's, because this body's height is bulk and not stature. 2.60 is inside
  the band the thirty-six occupy and reads as the bigger thing in the frame.
  One change, re-rendered, looked at again.
- **The frame was widened to 6.40 m for this cell** (the thirty-six use 5.60).
  At 2.60 the T-posed pair spans 5.96 m and the border check went red — 228 px
  of arm off the left edge, 233 off the right. **A clip is not a blank**, which
  is exactly why that check exists. The frame width is recorded in the register
  so nobody compares a 6.40 cell with a 5.60 cell by eye.

### The stray Icosphere is not in the asset, and this lane has said otherwise in three places

Imported raw, the Puglin reports 1.902 × 2.000 × 2.000 — a sphere of radius 1
on the origin, not the creature. Dropping it is right and stays. **The reason
given for it was wrong.** `minibossfit.py`, `e3pogen.py` and
`docs/art/MINIBOSS_FIT.md` all say the glb *ships* a stray Icosphere. Proved
otherwise three ways this run:

1. the string `Icosphere` occurs **zero times** in the 3,124,424 bytes of
   `broodglut.glb`, whose JSON chunk carries 59 nodes and 3 meshes — and that
   file still imports one;
2. a **rigged** pack glb gets one (`Frog.glb` → Armature, Frog, Icosphere);
3. an **unrigged** glb of our own does not (`beadle.glb` → four meshes, clean).

It is a Blender 5.2 glTF-import artifact for any glb carrying an armature.
**It is therefore not in the shipped asset, not in Godot, and not a defect for
the game build lane to chase** — which is precisely where the old wording would
have sent someone. The handling passed; the explanation did not.

## Pass 4 — it has to TOWER, and 3x does not fit the corridor

Written 20 Nov 2026, 00:46 CT by the ART lane, clock read off the machine.
**Supervisor directive 20 Nov 00:10 CT**, carrying Mr. E's own words after he
looked at pass 3's sheet: *"it looks the same size as the hero knight... a
miniboss needs to tower over the heroes... minimum 2-3x the hero's height...
if it doesn't make the viewer go 'oh crap', it's not big enough."*
The corridor gate stays: *"it has to fit a three-cell corridor."*

**Pass 3 was 2.60 m against a 2.45 m hero — ratio 1.06, and the procedural
band is no taller.** I first wrote here that all thirty-six sit at 1.06, then
measured it rather than shipping it: across the **30 miniboss keys that carry a
`_fit_*_register.json` in this tree (31 pairs)** the ratio runs **0.84 to 1.20**
— heights 2.05 m to 2.95 m — and only four are at 1.06. **Several are
SHORTER than a hero.** The flat-1.06 sentence was a remembered number from one
register; the range is the measured one, and it makes the point harder: the
whole class is eye-level with the party or below it. No register could say so,
because every register compares a creature with itself.

### The new height is the top of a measured band, not a taste

The directive asks for 2-3x AND keeps the corridor gate, and **those two
cannot both be had at 3x.** `minibossgen`'s corridor clear is
`3 * 4.0 - 2 * 0.5 = 11.0 m`. This body is authored in a **T-pose** whose arm
span scales with its height at **1.576731 m of span per metre of height**
(4.0995 / 2.60, measured at pass 3):

| ratio | height | T-pose span | corridor margin | |
|---|---|---|---|---|
| 2.00 | 4.90 m | 7.73 m | 3.27 m | safe |
| 2.69 | **6.60 m** | **10.41 m** | **0.59 m** | **taken** |
| 2.85 | 6.98 m | 11.00 m | 0.00 m | the hard wall |
| 3.00 | 7.35 m | 11.59 m | — | **ROOM-LOCKED** |

**6.60 m: 2.69x the hero, 7.33x its own regular puglin**, `room_locked: false`
on the worst case rather than on the pose the game draws — `bestiary.gd` grafts
the UAL library on at load, so in play the arms come down and the real
footprint is narrower than this gate. **The way to a true 3x, if Mr. E wants
it, is to measure the span in the UAL idle instead of the T-pose, or to
room-lock the spawn.** Not taken this pass; one thing changed.

### The foot line disagreed with the picture, so it got an instrument

Looking at the new `hero_side.png` the creature's lowest pixel sits **41 px
below** the hero's. On a sheet whose whole job is *both of these stand on the
same floor, look how much bigger one is*, a foot line that disagrees would
make the ratio a lie. `minibossfit`'s own comment blames its 6 deg camera
elevation — but **an explanation beside a picture is the thing this lane has
been caught trusting twice**, so it was made into an A/B that can move:
`tools/art/_bg_ground_ab.py` renders the side view at 6 deg and at 0 deg with
nothing else changed and measures the delta in each.

`renders/art/variants/_ground/_ground_ab.json`:

- world space, which is the only answer that is not a picture:
  **creature min z `0.0`, hero min z `0.0`** — both ON the floor;
  creature max z **`6.6`**, so the authored height is the rendered height.
- **foot delta 41 px at 6 deg -> -1 px at 0 deg.** It is projection acting on
  a 3.43 m depth separation, not a float. **Verdict: nothing to fix in the
  art.**
- Honest caveat on the arithmetic: centre-to-centre depth predicts only ~21 px
  of the 41, so the contact points sit further apart in depth than the centres
  do. **The collapse to -1 px is the evidence; the 21 px model is not.**
- The probe goes RED ON EMPTY: a delta computed over an empty mask is an
  error, not a zero.

### What pass 4's sheet shows, and what it still cannot

`renders/art/variants/broodglut/hero_{front,side,back}.png`, re-rendered on the
real KayKit adventurer at scale 1.0, idle pose. 0 blanks, **0 frame-clip
pixels on all four edges of all three views**, 3 of 3 proving views, errors
`[]`. The hero's pixel area falls from ~33,000 to ~8,000 because the frame had
to widen from 6.44 m to **13.25 m** to hold the pair — that drop IS the tower,
in pixels.

**I looked at all three. The side view is the one that sells it:** a hunched
brute leaning down over a knight who reaches its knee. Faults I can see:

- **The front view is still a T-pose and now it is an enormous one** — the arm
  span is nearly the full 13.25 m frame. **The sheet proves scale and colour;
  it does not prove stance**, and at this size that caveat costs more than it
  did at 2.60 m.
- **The ear turn from pass 3 holds at the new scale** — in front and back the
  ears leave the skull on a clearly different line from the arms with
  background between them. The team lead's "second pair of arms" read is gone.
  That is my eye, and it agrees with pass 3's measurement rather than
  replacing it.
- **The held stick now reads.** At 2.60 m this lane recorded it as "nearly
  invisible"; at 6.60 m it is a distinct pale prop on the creature's arm. It
  still sits against the forearm rather than in a closed fist — the pack's own
  rigging, untouched.
- **The eyes are blank white with no pupil** and at this scale they are the
  loudest thing on the face. Pack geometry, not a recolour artifact. Worth one
  pass if Mr. E wants it; not changed here.
- **The frame width changed again (6.44 m -> 13.25 m), so this sheet cannot be
  compared with pass 3's by eye.** Both widths are recorded for exactly that
  reason.

### A defect in this lane's own tool, found by reading the register it wrote

`--fit` without `--export` rebuilt the record from scratch and **silently
erased `glb` and `glb_bytes`** — the two fields naming the asset that actually
ships, and the ones the game build lane reads for the path. The register's
verdict stayed **GREEN** throughout, because no check in that file asks whether
the record still points at a file. `monstervariants.main` now carries those
fields across any pass that did not re-export. Re-exported this pass to prove
it: **3,124,424 bytes, byte-identical to pass 3** — confirming again that the
scale-up is in the WIRING and not in the mesh.

### Wiring — the GAME BUILD lane's, not mine


`scripts/bestiary.gd`, beside the existing `silkmother` / `spiderling` block:

```gdscript
"broodglut": {"name": "Broodglut", "path": MON + "minibosses/broodglut.glb",
              "anims": A_UAL, "hp": 2.4, "atk": 1.5, "spd": 3.6, "h": 6.60,
              "lift": 0.0, "family": "fiend"},
```

- `h` **6.60** — **CHANGED AT PASS 4, 20 Nov 00:4x CT, AND THIS IS THE ONE
  FIELD THE GAME BUILD MUST RE-READ.** It was 2.60. The glb is exported at
  **native** scale on purpose, because `Monster` normalises every body to `h`
  from its own bounds and a pre-scaled mesh would put the size in two places
  that can disagree.
- `A_UAL` because the body is rigged and unanimated, exactly like `puglin`.
- `assets/monsters/minibosses/broodglut.glb` has **no `.glb.import` sibling** —
  it cannot load until a Godot run generates one. Same condition as
  `snarer_chibi.glb`.
- The mechanic is the game build's to implement; nothing here assumes it exists.

### One adjacency, declared rather than hidden

Miniboss 8, **Blisterhand** (ex-Cook), *keeps the pack alive*. Broodglut is that
arrow reversed — the pack keeps **it** alive — so the party's decision is
inverted (kill the adds, not the boss) rather than repeated. If Mr. E reads it
as the same idea twice, the fix is one string and no geometry.

### Licence

Quaternius Asset License v1.0, read off `License_Standard.txt` on disk this run
and not off a search snippet: worldwide, royalty-free, perpetual, commercial
use permitted, no attribution required; the only restriction is reselling or
redistributing the assets **as assets**, which a creature inside our own dungeon
is not. Logged in `docs/art/ASSET_SOURCES.md`.

---

## Pass 3 — 20 Nov 2026, 00:0x CT: the ears

### The fault, and it came from an eye, not a number

The team lead looked at pass 2's `hero_front.png` and wrote the one thing the
register could not reach:

> **IN THE FRONT VIEW THE EARS READ AS A SECOND PAIR OF ARMS.** They leave the
> head at the same angle, the same hue and nearly the same taper as the real
> arms, so the silhouette is a six-limbed shape.

Every number in that register was green — `seen: 1.0` on all six subject/view
pairs, 0 blanks, 0 frame clips, 3 of 3 proving views — because **all of them
ask whether the thing is there and not one asks whether the outline separates.**

### Measured before it was touched

`tools/art/_bg_sil_runs.py` renders the creature alone through a front
orthographic camera and counts maximal vertical runs of opaque pixels per
column. On the shipped glb: **234 of 234 ear columns carried a single run** —
the ear's visible outline rested flush on the arm's upper edge with no
background between them anywhere. Verdict **FUSED**. The eye and the pixels
agree.

`tools/art/_bg_ears_probe.py` then answered how to fix it: **the pack's 55-bone
rig has no ear bone.** All 1531 head-and-ear vertices ride `Head`. So this
could not be a pose and had to be geometry.

### The change — one thing

`ear_turn()` in `tools/art/monstervariants.py` turns each ear about its own
measured root (|x| = 0.20, where the head's vertex count collapses from 394 to
166 per slice) and carries it along the resulting arc. Arc length is preserved,
so the ear keeps the pack author's length and taper and only its **direction**
changes. Shipped at **pitch +40°, yaw +45°** — lifted and swept back behind the
skull.

Chosen over three rivals **by looking at four silhouette sheets**, not by score:
a 60° droop squared the skull off and hung the ears as spikes under the armpits,
which is a worse read than the one it fixed.

| | two-run frac | max gap | height overlap |
|---|---|---|---|
| shipped (pass 2) | **0.000** | 0 px | 0.027 |
| droop 60° | 0.000 | 0 px | 0.273 |
| back 60° | 0.027 | 33 px | 0.031 |
| back 45° / up 30° | 0.560 | 31 px | 0.004 |
| **back 45° / up 40° — shipped** | **0.563** | **49 px** | **0.003** |

### Two instruments of mine failed inside this pass, and both were caught here

1. **The deform could not move the ear.** The first `ear_turn` ramped the turn
   across the whole ear: at yaw 55° the tip travelled 0.089 on a 0.243-long ear
   and `span_y` did not change at all. Four candidate sheets would have come out
   looking alike and invited the conclusion that no deform helps.
2. **The gate passed the known fault.** Mid-pass the gate was moved off the run
   count onto `ear_touches_arm_px`, which read **0 on the shipped glb** — a
   perfect score on the fault. The reason is structural and is written on the
   function: a footprint is what a part *adds* to the outline, so where the ear
   covers the arm that pixel is the ear's and not the arm's, and the two
   footprints are disjoint along exactly the seam where the shapes fuse. The
   harder they fuse, the cleaner the number reads. `height_overlap` failed the
   same way at 0.027. **Only counting runs ever went red on the fault**, so the
   gate is back on the run count and the other two are description.

### A pass-2 defect found on the way, and it is not the ears

Re-rendering at minibossfit's **standard cell (FRAME_W 5.60 m)** cut the *hero*
off at the left border — `frame_edge front {left: 228}`. Pass 2 recorded
`fits_frame: true` with `frame_w: 6.4`: that run used minibossfit's `--frame`
override and **nothing in the register said so**, so it read as a creature that
passed the standard cell. It does not. This pair is **5.96 m** wide, because the
pack body is authored in a T-pose whose 4.10 m arm span plus a hero and the gap
do not fit 5.60 m.

`tools/art/_bg_frame_ab.py` ran the pipeline twice in one process, ears off then
ears on: the clip is **byte-identical both ways**, so it is pass 2's to answer
and not pass 3's. The frame is now widened to hold the pair and the override is
**recorded** — `frame_overridden: true`, `fits_standard_cell: false`,
`frame_w_standard: 5.60` — rather than left to be inferred from a number.

### What the fix does not do

- The body is still a **T-pose**, and that is what the game draws: the shipped
  glb carries **zero animations**, and so does the pack's own `Puglin.glb`
  (measured off both glTF JSON chunks this pass). Nothing was dropped by the
  export.
- The ears still run close to the upper arm on their inboard half — 42 of 96
  columns per side remain single-run. That is the shoulder, and it is correct;
  the fused *read* is gone, the margin is not generous.
- Separation is **necessary and not sufficient**. Two of the team lead's three
  cited cues — hue and taper — are invisible to this instrument. The picture
  stays the verdict.
