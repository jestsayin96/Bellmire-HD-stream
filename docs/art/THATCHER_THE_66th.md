# THE THATCHER - "Lastcourse". The 66th body. Passes 1-5, 27 Nov 2026, 02:34-03:1x CT.

## WHAT I CHECKED FOR FIRST - MEASURED, NOT REMEMBERED

- **65 live bodies**, counted by parsing every `ORDER = ORDER + [...]` statement
  out of `tools/art/minibosses.py`: 65 keys, 0 duplicates. **The prompt in front
  of me said 33.** It was 32 stale, and it also said the gloves and System 10
  were still open when both were ticked days ago. Nothing in this run was taken
  off a prompt line.
- **All 79 CANON tuples brace-matched** (not regexed) and **every gimmick string
  read** before a line was drawn. 65 distinct non-variant bodies over all 14
  floorgen themes. `flooded` stands at 4 - sluicekeeper, tanner, rammer,
  ferryman - joint-thinnest, and reed is cut in flooded beds, so that is where
  this one goes.
- **Free rungs, measured off those tuples**: height 2.54 (2.52 and 2.55 taken,
  2.54 not), wear 0.37 (0.36 and 0.38 taken, 0.37 not), `Lastcourse` not among
  the 79 taken titles.
- **I did not rebuild anything.** The first question was whether this fight shape
  already exists. It does not - see below - and had it existed the run would have
  said which body serves it instead.

## THE IDEA

**IT COVERS THE REST.** While it stands, nothing else in the room can be hurt;
your blows land in thatch. It does nothing to itself and nothing to any one hero.
Kill the thatcher and the covering comes off everything at once.

**It is a target-priority INVERSION, and that is the one shape not in the other
65.** I read every hook to check. Every other protection in the file points at
itself or at the party:

| body | what it does | why it is not this |
|---|---|---|
| PAVISER | keeps its face to you | protects ITSELF |
| NIGHTMAN | "CANNOT BE HURT" while lit | protects ITSELF |
| COOK | the pot heals the room | the room still TAKES the damage |
| QUARTERMASTER | arms the room | buffs the room's OFFENCE |
| LEECH | no wound closes | denies the PARTY, not the adds |
| TIMBERMAN | its death is the danger | about its own death |

Nothing makes the ADDS unkillable, so nothing forces a party to eat a room at
full weight while pushing the one body at the back that is not hitting them.

**TWO DESIGNS DIED ON THAT READING**, before a line was drawn:
- *A thatcher who re-covers himself when hit.* Dead: the SCRAPWRIGHT replaces
  every plate off the floor and the DAUBER lays a fresh course. Self-repair is
  taken twice over.
- *A thatcher who smothers one hero under reed.* Dead: the HOOPER casks one of
  you and the DROVER yokes one of you. Single-hero removal is taken.

## THE FIVE PASSES - EACH ONE CHANGE, EACH JUDGED ON A PICTURE

1. **Built.** Verdict GREEN, 0 blanks. I had predicted the yealm would read as
   the Drover's YOKE or as a POLE. **The picture refused both and handed me a
   worse fault I had not listed: it read as a CANNON.** The butt lip was the
   near end, so the front *and* the side camera looked straight down the bore,
   and three dark bands round a tube finished the job. **THE RULE THIS BUYS: a
   cut lip is a disc, and a disc facing a camera is a bore.**
2. **The yealm re-aimed** - butt high, far outboard and BEHIND (y +0.150), so
   its face normal carries +y and points away from the front camera, and it no
   longer crosses the midline. Cannon gone. New fault: a smooth tapered cylinder
   with flat ends and three crisp bands is a **PIPE**.
3. **The bundle became STEMS, not a tube.** Seven bound stems on a splay profile
   that is tight at the ties and open at both ends, with ragged end-cuts so
   neither end is flush. The single cone and the two cut lips and the three
   stubs went with it - they only ever existed to fake what stems give for real,
   a cut end that is a FAN and not a disc. **This is the pass that worked**: it
   reads as a bound sheaf from front, side and back.
4. **The leggett's float closed.** The side ortho showed clear white between the
   handle and the board. Measured rather than eyeballed: `L.box` takes FULL
   extents, so a 0.186-deep board centred at `WAIST-0.650` topped out at z 0.593
   while the handle stopped at 0.630 - **a 0.037 m gap carried since pass 1 and
   invisible to every blank and border check in the harness, because a float is
   neither a blank nor a clip.** They now overlap by 0.033.
5. **The face opened up.** See below - my own predicted fault 5 landed, and it
   landed only on the hero sheet.

## THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE

Rendered on an actual KayKit adventurer at scale 1.0 (`minibossfit`), front,
side and back, plus the body's own three orthos. Looked at every pass.

**THE ONE THING THE ORTHOS GOT WRONG, AND IT IS THE WHOLE ARGUMENT FOR THIS
TEST.** On all three orthos the face read perfectly well. **On the hero sheet it
was a dark blob with two faint dots and no face at all** - this lane's pass-11
fault exactly. The register scored `seen: 1.0` on all three views while it had
no face, because `seen` answers how much of the man is VISIBLE, not whether he
has a FACE. **The picture is the evidence and the number was never asked.** The
cause was size and shadow, not colour: the oval was set IN behind the hood's
mouth, so it sat in the hood's own shadow and the 2.9 body/dark luma ratio never
got to do any work. It now stands PROUD of the hood and is larger.

**What works.** The yealm reads as a bound sheaf of cut stems at hero distance,
from all three views - the cue survives, which is the whole point of it. **The
back is a back**: the hood is dark front and back and there is no pale anywhere
on the head, so the Beadle's no-facing fault is answered by construction and not
by hope. Proportion reads - ratio 1.04 against the hero, he stands as a working
man and not a monster.

**Open faults, named not tidied away:**

1. **THE MAN IS ONE VALUE.** Beside the knight, who has armour, skin and a red
   cape, the thatcher is a uniform grey-green slab: coat, trunk, arms and legs
   are all the `body` slot. **The instrument agrees with my eye and I did not
   notice until I read it**: `value_man_visible` spread is 0.238 with only
   **3 bands at 5%** on the front. This is the Moulder's contrast rule - the
   gown the lighter dark, the apron and boots the darker - and this body does
   not obey it. **This is the loudest remaining fault and it is the first thing
   the next pass should take.**
2. **The face is better, not good.** It reads at hero distance, barely. Against
   the knight's face it is weak.
3. **The leggett reads as a dark box at the hip** - a satchel or a pouch, not a
   tool. At hero distance it contributes nothing. It should be made to read as
   a board or cut; it should not be left as a lump that means nothing.
4. **The stems are fatter than reed.** They read as rods or dowels - closer to a
   faggot of hazel than to combed reed, and slightly like rolled paper because
   they are smooth and uniformly pale. Honest, and arguably more legible at
   stream distance than true reed would be, but it is not what it says it is.
5. **The yealm occludes his chest and most of his right arm** in the front view.
   That is the cost of putting the cue where a carried bundle actually goes, and
   it is the same trade the Mealman paid for its fall.

**What the harness cannot see.** None of the five above. A float is not a blank;
a one-value man passes every count; a faceless head scores `seen: 1.0`; a lump
at the hip is neither a clip nor a blank. They are answered by looking and by
nothing else. Fault 4 of pass 1 - the butt stubs reading as flecks - was
resolved by DELETING the stubs at pass 3, not by growing them.

## NUMBERS

Verdict **GREEN**, `ok: true`, `errors: []`, `red_summary.shipped_red: []`,
`ok_shipped: true`, read out of `renders/art/minibosses/_fit_report.json` AFTER
the self_seen chain was run - not claimed ahead of it. **0 blanks and 0 frame
clips across 198 files**; frame_edge 0 on top, bottom, left and right for all
three hero views. 3 merged meshes (bar is 4), 1224 faces, span 1.52 m.
**CORRIDOR-SAFE** and **UNDER-LID** against `scripts/floorgen.gd` read live
(corridor clear 11.0 m, lid underside 9.5 m). **NOT room-locked.**
Hero pair: creature 2.54 / hero 2.45, **ratio 1.04**, margin_x 0.12,
`fits_frame: true`, **3/3 proving views**.

**THE REGISTER WENT RED FIRST AND I DID NOT SHIP IT THAT WAY.** At pass 4
`minibossfit` returned `verdict: RED`, `shipped_red: ["thatcher"]`, with two
errors naming this body and printing the command to clear them - the body was in
the register and in no self_seen census list. That is the third body running to
hit it (fanner, mealman, now this one), and **the instrument was right every
time**. The chain was run in order - `_backread.py` measured the body (front
0.9074, side 0.7408, back 0.9756), `_selfseen_merge.py` took rows 64 -> 65,
`_selfseen_census.py` re-covered the house - and only then was the verdict read.
`_selfseen_merge.py` is the script that was a hand edit until the 65th; it did
link 2 here without a hand touching it, which is the fix doing its job.

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT DO IT

`scripts/bestiary.gd`: add a `thatcher` entry with
`model = "res://assets/monsters/minibosses/thatcher.glb"`, `h = 2.54`, and
**NO `anims` entry** - the body is static.
`scripts/delve.gd`: add `"thatcher": "Lastcourse"` to `MB_NAME`, and
`MB_FIT` takes the measured pair - **ratio 0.97 is NOT this body's number; copy
`pairs.thatcher` from `renders/art/minibosses/_fit_report.json`: ratio 1.04,
creature_h 2.54 / hero 2.45, margin_x 0.12, fits_frame true, 3 proving views.**
Content owes a `miniboss_feed.by_key` row for `thatcher`; the feed line is
`"Something ahead has been over this room with reed."`

**Note for the team lead: this takes the live-body count to 66 and widens the
naming cascade by one until those rows land.** The 65th's cascade was declared
shut at 02:07 this morning; this re-opens it by exactly one body, on purpose,
under the standing permission for a dry art lane to invent.

---

# PASSES 6 AND 7 - 27 Nov 2026, 03:34 CT FIRING. OPEN FAULT 1 IS CLOSED AND I OPENED A NEW ONE AND MEASURED IT.

The 02:58 plan's addendum gave this lane one row: *"the next pass on the
thatcher is YOUR OWN open fault 1 - THE MAN IS ONE VALUE, `value_man_visible`
spread 0.238, 3 bands at 5%, against the Moulder's contrast rule. You named it;
take it. A 67th body does not outrank it."* I took it and nothing else.

**WHAT I CHECKED FOR FIRST, MEASURED.** The live count off `tools/art/
minibosses.py` and the tree: 79 `.glb` under `assets/monsters/minibosses/`,
minus 11 `_chibi`, minus the two bosses = **66 live bodies**, `thatcher` last.
I did not invent a 67th; the row says it would not outrank this. I also
re-measured the baseline out of `_backread.json` rather than trusting the
0.238 in my own pass-5 writeup: front 0.2383 / side 0.2308 / back 0.2423,
`bands_5pct` 3 on all three. It matched.

## PASS 6 - THE OBVIOUS FIX, AND IT FAILED, AND THE FAILURE IS THE FINDING

I re-slotted the coat's skirt cone from `body` to `dark` - the Moulder's rule
read literally, apron darker than gown. I wrote the bar down BEFORE rendering:
`dark_frac` above 0.20, `bands_5pct` 3 -> 4, spread above 0.30.

| view | spread p5 -> p6 | bands_5pct | verdict |
|---|---|---|---|
| front | 0.2383 -> 0.2526 | 3 -> **3** | fail |
| side | 0.2308 -> **0.2201** | 3 -> **3** | fail, and DOWN |
| back | 0.2423 -> **0.2406** | 3 -> **3** | fail, and DOWN |

**ALBEDO IS NOT VALUE IN THIS RIG.** `dark` carries 2.9x less albedo than
`body` (luma 0.049 against 0.142) and bought about 0.08 of screen luma: p50
moved 0.3476 -> 0.3110 and the mass shifted one histogram band, from band 2
into band 1, where there was already 19% of it. The even light rig plus the
world term lift everything off the floor, so **the two solid slots this body
owns are one band apart once lit, and no re-slot between them can make a third
value.** Reverted. Recorded here rather than buried, because the next body that
reaches for `dark` to fix a flat man will waste the same pass.

## PASS 7 - THE LEATHER LAP. IT WORKED, ON ALL THREE VIEWS

The headroom is UPWARD and the pass-5 numbers said so outright: the man ran p5
0.1754 to p95 0.4137 and the top three bands of eight held 0.0023, 0.0037 and
0.0. Nothing on him was bright. This lane's own record is *"brightness has a
ceiling and contrast does not"*, and here the ceiling was nowhere near reached.
So the lap is LIGHTER than the coat, which inverts the Moulder's direction
while keeping what that rule is for - a waistline made by VALUE, not by a belt.

Buff leather from the hip down, `LAP = (0.420, 0.350, 0.240)`. It is what the
trade is for: a thatcher kneels into his work and drags combed reed across his
lap all day. It is a **vertex colour on the existing `body` slot**, not a
fourth slot - the two free slots in the merge are `glow` and `ember` and both
are emissive, and a lit apron is a lantern. **The body stays at THREE meshes**,
under the four-mesh bar it already held. **No new geometry**: the skirt cone
was already there, and a cone already concentric with the coat cannot float
against it by construction - which is the pass-4 float answered by shape of
fix rather than by a second measurement.

Bar written down before the render: p95 above 0.4137 (if it did not move, the
paint did not land), spread above 0.30, `bands_5pct` 3 -> 4, and `man_seen`
must not fall.

| view | spread | p95 | bands_5pct | man_seen |
|---|---|---|---|---|
| front | 0.2383 -> **0.3990** | 0.4137 -> **0.5797** | 3 -> **4** | 0.9074 -> 0.9074 |
| side | 0.2308 -> **0.3948** | 0.4095 -> **0.5761** | 3 -> **4** | 0.7408 -> 0.7408 |
| back | 0.2423 -> **0.4128** | 0.3947 -> **0.5652** | 3 -> **4** | 0.9756 -> 0.9758 |

Band 4 (0.500-0.625) was empty at pass 5 and now holds 19.5% / 25.2% / 20.2%.
`man_seen` did not move, which is the hazard I was watching: `_backread` counts
a man pixel where `|B - X|` clears EPS, so a body drifting toward the near-black
background can LOSE seen while looking better. It went up, by 0.0002.

**I LOOKED.** `renders/art/minibosses/thatcher/hero_{front,side,back}.png`, on
the knight, idle. The man is no longer a slab: dark boots, hands, hood and
leggett; mid grey-green coat, trunk, arms and legs; the pale lap at the hip;
the reed above it. The waistline is made by value now and reads at hero
distance from all three views. **The back is still a back** - dark hood, no
face, no pale on the head.

## THE NEW FAULT I OPENED, AND THE INSTRUMENT THAT FOUND IT

My own pass-7 build-time assertion is `bone_l / lap_l >= 2.00` and **it passes
at 2.29 on albedo.** Pass 6 had just proved albedo is not value, so I did not
trust it, and wrote `tools/art/_cuevalue.py` to ask the viewer's question on
the frame that ships: render with and without through ONE locked camera, count
the pixels that moved, and read luma off the shipped frame at those pixels.
The cue is the `bone` mesh hidden; the lap is a second build with the lap
painted the slot's own fill, geometry byte-identical so nothing can move.

| view | cue p50 | lap p50 | margin | ratio |
|---|---|---|---|---|
| front | 0.6518 | 0.5646 | 0.0872 | 1.154 |
| back | 0.5908 | 0.5599 | 0.0309 | 1.055 |
| **side** | 0.5419 | 0.5413 | **0.0006** | **1.001** |

**ON THE SIDE VIEW THE LAP AND THE YEALM ARE AT THE SAME SCREEN VALUE.** That
is the Beadle's fault by the Beadle's own number - it shipped 1.07 and its pale
knob went flat against its own pale panel while every number in its register
passed - and this is worse, in the space that matters. My albedo guard said
2.29 and the picture says 1.001. **A number that answers a question the picture
was never asked is this lane's pass-11 fault**, and rather than delete the
assertion I have relabelled it in the builder, in full, as a monotone tripwire
that CANNOT say the cue reads, with `_cuevalue.py` named as the instrument that
can and a standing instruction to re-run it after any colour change here.

**AND THE FIRST CUT OF `_cuevalue.py` WAS ITSELF WRONG, AND ITS OWN RED-ON-EMPTY
GUARD IS THE ONLY REASON I KNOW.** It flattened the lap by patching
`Parts._vc`, and the thatcher writes `P.vcols[id(item)]` directly - the
Collier's pattern - so the "flattened" build was identical and the lap mask was
**0 px**. A margin over zero pixels reads green and means nothing; this one
went red and printed the mask size. The hook that cannot be dodged is the
MERGE, because that is where `vcols` is consumed. Second run: 18350 / 14209 /
19909 lap pixels.

**WHY I AM NOT FIXING IT BY DARKENING THE LAP, AND THE NUMBERS BEHIND THAT.**
The two metrics are in direct conflict on the side view and I measured the box
rather than guessing at it. `bands_5pct` only rises when a mass reaches an
EMPTY band, and the only empty band in reach is band 4, 0.500-0.625; calibrating
screen luma against albedo off my own two measured points (0.142 -> 0.347 and
0.357 -> 0.541) puts the lap's floor for band 4 at about 0.30 albedo luma, which
lands near 0.50 on screen. **The side view's cue only reaches 0.5419.** So there
is no lap value on the side view that both adds a band and clears the reed.
**The lever is therefore not the lap's colour at all - it is that the yealm is
UNDER-LIT FROM THE SIDE, 0.5419 against 0.6518 on the front.** Lift the reed's
side value and a band-4 lap clears it by about 0.13. That is the next pass and
it is a lighting/orientation question, not a palette one. I am not taking it in
the same pass that opened it, and I am not shipping a guess at it.

## OPEN FAULTS AFTER PASS 7 - NAMED, NOT TIDIED

1. ~~THE MAN IS ONE VALUE~~ - **CLOSED at pass 7**, measured on three views.
2. **NEW, AND MINE: the lap goes flat against the yealm on the SIDE view**,
   screen ratio 1.001. Numbers and the diagnosis above. **This is the loudest
   remaining fault and the first thing the next pass should take.**
3. **The face is better, not good.** Unchanged by this pass.
4. **The leggett reads as a dark box at the hip** - a satchel, not a tool.
   Unchanged, and the lap now sits beside it, which if anything makes the lump
   more obvious.
5. **The stems are fatter than reed** - rods, not combed reed. Unchanged.
6. **The yealm occludes his chest and most of his right arm** in front.
   Unchanged, and still the honest cost of putting the cue where a carried
   bundle goes.

**WHAT THE HARNESS STILL CANNOT SEE.** `_cuevalue.py` measures VALUE and
nothing else: two masses can be well separated in luma and still argue through
hue, through touching silhouettes, or through one being shaped like the other.
It says nothing about whether the reed reads AS reed. Faults 3, 4 and 5 above
are invisible to every number in this house and are answered by looking.

## NUMBERS AFTER PASS 7

Verdict **GREEN**, `ok: true`, `errors: []`, `red_summary.shipped_red: []`,
`ok_shipped: true`, `rows_judged: 68`, read out of
`renders/art/minibosses/_fit_report.json` AFTER the self_seen chain was run in
order - `_backread.py --tag _p7` -> `_selfseen_merge.py` -> `_selfseen_census.py`
-> `minibossfit.py --only thatcher`. **0 blanks across 198 files, failures [].**
Hero pair unchanged by a colour pass: creature 2.54 / hero 2.45, **ratio 1.04**,
margin_x 0.12, `fits_frame: true`, **3/3 proving views**. 3 merged meshes.

## WIRING - UNCHANGED BY THIS PASS, AND STILL NOT DONE BY ME

Pass 7 changes colour only. No geometry, no bounds, no ratio moved, so every
number the game build was given still stands: `MB_FIT.thatcher` **ratio 1.04**,
creature_h 2.54 / hero 2.45, margin_x 0.12, 3 proving views - copy
`pairs.thatcher` out of `renders/art/minibosses/_fit_report.json`, and
**0.97 is the mealman's number, not this body's.**

---

# PASS 8 - THE BIND'S TWIST. THE SIDE MOVED, AND IT IS NOT CLOSED

Taken off the 03:58 plan, ART (:34): *"THE THATCHER PASS 8: LIFT THE REED'S
SIDE VALUE... TAKE YOUR OWN DIAGNOSIS - it is the right one. The yealm is
UNDER-LIT FROM THE SIDE... so the lever is light/orientation, NOT the lap's
colour."* I took that and nothing else.

**WHAT I CHECKED FOR FIRST, MEASURED.** 79 `.glb` under
`assets/monsters/minibosses/` minus 11 `_chibi` minus the two bosses =
**66 live bodies**, `thatcher` last in `ORDER`. I did not invent a 67th; the
plan named this pass. I also measured the one thing my own prompt still
carries as owed: **`snarer_chibi.glb.import` EXISTS**, written 17 Nov 18:53,
sitting beside `snarer_chibi.glb`. That line is stale and nothing is owed on
it; the body loads.

## THE CAUSE, MEASURED BEFORE I TOUCHED ANYTHING - AND IT IS NOT THE LIGHTING

I went looking for a per-view lighting difference and **there is none.**
`minibossfit.aim_lights` SPINS THE WHOLE RIG WITH THE CAMERA, so the light is
identical relative to every camera and no view is "darker" by the rig. What
differs is this bundle's own body-fixed axis against that rotating key. Key
base `(0.9, -1.0, 0.85)` against the yealm axis:

| view | \|L . axis\| | perpendicular component |
|---|---|---|
| front | 0.510 | 0.856 |
| **side** | **0.930** | **0.373** |
| back | 0.332 | 0.940 |

**AT THE SIDE AZIMUTH THE KEY IS NEARLY PARALLEL TO THE BUNDLE.** A cylinder
lit along its own axis gets almost no diffuse anywhere on its flank: the best
normal available falls from 0.856 to 0.373, a 2.3x drop in the key's whole
contribution. That is the entire fault, and for once the number and the
picture agree on a cause and not just on a symptom.

## THE OBVIOUS FIX IS RE-AIMING THE BUNDLE. I SWEPT IT AND REFUSED IT

Holding the length and the z-run fixed and sweeping the xy direction over its
whole legal range: the current aim sits near the **worst** side value in reach
(0.373 against a floor of 0.348), and the best available, 0.590, costs the
front 0.856 -> 0.643 and needs `dy ~ 0` - which drives the butt onto the
midline and out from BEHIND him. That breaks the **pass-2 re-aim** (butt
behind, so no camera looks down the bore) and the **pass-3 three-axis
diagonal** in one move, to trade one view for another. A zero-sum fix that
un-ticks two earlier passes is not a fix. **It also moves the bounds, in the
hour the game build is wiring this body's fit numbers**, which is the worst
possible hour for it.

## WHAT IS NOT ZERO-SUM: TWIST THE BIND

Each stem follows a helix about the bundle axis instead of running parallel to
it, so its tangent leaves the axis and keeps turning along its length - at
every azimuth some span of every stem is ACROSS the key instead of down it.
The trade is strongly asymmetric because the front is already near the 1.0
ceiling and saturated while the side is deep in the shadow end. Predicted,
before rendering, as mean perpendicular component over all stem segments:

| twist | side | front | back |
|---|---|---|---|
| 0 (pass 7) | 0.3733 | 0.8563 | 0.9401 |
| 180 | 0.4097 **+9.8%** | -1.1% | -1.5% |
| 360 | 0.5207 **+39.5%** | -3.6% | -5.0% |

**THE BOUNDS CANNOT MOVE, BY CONSTRUCTION.** The twist rotates the offset
vector's PHASE only; its LENGTH is the same `R_RING * _f(_t)`, so every stem
centreline stays on the identical tube about the identical axis and the convex
hull is the same set. That is why this was the safe lever this week. **I
re-measured it anyway rather than asserting it** - see below, and it did not
hold to the millimetre.

## THE A/B ON THE FRAME THAT SHIPS - AND THE CONTROL PROVES THE RIG

Three arms through `_cuevalue.py`, which now takes a `--tag` so arms cannot
overwrite each other and records the twist it was built at, so a report can
never be read against the wrong arm. **The twist-0 arm reproduced pass 7 to
four decimals** - side margin +0.0006, ratio 1.001, cue 0.5419, lap 0.5413 -
which is what makes the other two arms readable at all.

| arm | front margin / ratio | **side margin / ratio** | back margin / ratio |
|---|---|---|---|
| twist 0 (pass 7) | +0.0872 / 1.154 | **+0.0006 / 1.001** | +0.0309 / 1.055 |
| **twist 180 (SHIPPED)** | +0.0835 / 1.148 | **+0.0133 / 1.025** | +0.0524 / 1.094 |
| twist 360 | +0.0824 / 1.146 | **+0.0399 / 1.074** | +0.0505 / 1.090 |

## WHY I SHIPPED THE ARM THE NUMBERS LIKE LESS

**360 WINS ON EVERY NUMBER AND IS A ROPE.** I wrote that hazard down before I
rendered - "the yealm reads as a pale rope" is the MEALMAN's fault and is
already fault 2 of this body's own pass 1 - and the picture delivered it. At
360 the stems lose their separate identity through the middle of the bundle
and the whole mass reads as **twisted cloth, a wrung towel**, not reed. That
is not a near-miss: it is a material misread AND it un-does pass 3, which
bought the many-stems reading deliberately by deleting a smooth cone. At 180
the helix angle is 14.6 deg - stems that curve and cross, a bundle that has
been carried - and every stem still reads as a stem.
Sheets: `renders/art/minibosses/_cuevalue/_p8_sheet_3x3.png` and
`_p8_sheet_side_zoom.png` (side view, three arms, 3x).

**SO THE PICTURE OVERRULED THE NUMBER, AND THE NUMBER IT OVERRULED WAS ALSO
NOT GOOD ENOUGH.** 1.074 is **the Beadle's own shipped ratio**, the figure
this entire fault was framed against. Neither arm reaches a side margin I
would call closed.

## FAULT 2 IS SMALLER. IT IS NOT CLOSED, AND I AM NOT TICKING IT

Side ratio 1.001 -> **1.025**. That is a real move in the right direction on
the right lever, and it is a sixth of the front's separation. **I looked at
`renders/art/minibosses/thatcher/hero_side.png` on the knight, idle**, and at
hero distance the pale reed above and the pale-tan lap below still read as two
patches of one tone in one figure, with the dark coat band between them doing
most of the separating. The twist's real gain there is not the median at all -
it is the internal shadow between crossed stems, which makes the bundle read
as a **different material** from the flat skirt. **Fault 2 stays open at a
smaller size.**

**AND THE SPREAD METRIC I ADDED THIS PASS DID NOT FIND IT EITHER - SAID
PLAINLY.** I added p5/p95/spread to `_cuevalue.py` on the reasoning that a
modulated mass beside a flat one separates even at an equal median. The reed's
side spread is 0.4795 and the lap's is 0.1072 - **4.5x, and it was already
4.5x at pass 7, on the arm that has the fault.** A number that reads the same
on the faulty arm and the fixed one is not measuring the fault. I am keeping
it because it is the right question for the NEXT body, and labelling it here
as having failed on this one rather than quoting it as support.

## THE BOUNDS CLAIM, RE-MEASURED, AND WHERE IT DID NOT HOLD

| number | pass 7 | pass 8 | moved? |
|---|---|---|---|
| creature_h | 2.54 | **2.54** | no |
| hero_h | 2.45 | **2.45** | no |
| **ratio** | **1.04** | **1.04** | **no** |
| margin_x | 0.12 | **0.12** | no |
| fits_frame | true | **true** | no |
| proving views | 3/3 | **3/3** | no |
| footprint_span | 1.52 | **1.51** | **YES, by 0.01** |
| pair_w | 3.38 | **3.37** | **YES, by 0.01** |
| faces | 1224 | **1672** | +448 |

**MY "BY CONSTRUCTION" ARGUMENT WAS RIGHT ABOUT THE HULL AND WRONG ABOUT THE
MESH, BY A CENTIMETRE.** The stems are lofted tubes at `ring=8`, so at 13
samples instead of 5 the facets land in different places and the extreme
vertex is not the same vertex. The height did not move and neither did
anything the game build was given; the footprint lost 1 cm and the pair width
followed it. **Still CORRIDOR-SAFE (margin 9.492 m) and UNDER-LID.** The face
count is the honest price of sampling a helix: +37%, on a 3-mesh static body,
well under the four-mesh bar.

## OPEN FAULTS AFTER PASS 8 - NAMED, NOT TIDIED

1. ~~THE MAN IS ONE VALUE~~ - closed at pass 7 for the figure overall. **But
   see 7 below: a narrower piece of it is still open and I found it by
   looking at this pass's own render.**
2. **THE LAP GOES FLAT AGAINST THE YEALM ON THE SIDE** - 1.001 -> **1.025**.
   **STILL THE LOUDEST FAULT.** The lever that remains is the axis re-aim
   above, which is measured and costed and **MOVES THE BOUNDS** - it must not
   land in an hour when the game build is mid-wire on this body.
3. **The face is better, not good.** Unchanged. At hero distance beside the
   knight's actual face it is a dark ovoid with two dots.
4. **The leggett reads as a dark box at the hip** - a satchel, not a tool.
   Unchanged, and plain in `hero_front.png`.
5. **The stems are fatter than reed** - rods, not combed reed. **Eased, not
   fixed.** The twist gives them curvature and crossing, but at 7 stems of
   R 0.058 in a bundle of R_RING 0.098 they still read closer to rolled
   parchment than to a comb of reed.
6. **The yealm occludes his chest and most of his right arm** in front.
   Unchanged, and still the honest cost of putting the cue where a carried
   bundle goes.
7. **NEW, AND MINE, FROM LOOKING AT THIS PASS'S OWN FRONT RENDER: the arm does
   not separate from the trunk.** At hero distance the right arm against the
   coat is one unbroken dark grey-green mass. Pass 5's "the man is one value"
   was closed as a whole-figure fault and this is its residue in a narrower
   place. No number in this house reports it; `value_man_visible` counts the
   man's pixels together, so an arm at the trunk's exact value costs it
   nothing.

**WHAT THE HARNESS STILL CANNOT SEE.** `_cuevalue.py` measures VALUE and
nothing else - and this pass proved that adding SPREAD to it did not extend
its reach. It says nothing about hue, about touching silhouettes, about
whether the reed reads AS reed, or about faults 3, 4, 5 and 7, every one of
which is answered by looking and by nothing else.

## NUMBERS AFTER PASS 8

Verdict **GREEN**, `ok: true`, `errors: []`, `blind_views: []`,
`rows_judged: 68`, read out of `renders/art/minibosses/_fit_report.json` after
the chain was run in order - `minibossgen --only thatcher` (rebuild + glb
export) -> `_backread --keys thatcher --tag _p8` -> `_selfseen_merge` ->
`_selfseen_census` -> `minibossfit --only thatcher` -> `_cuevalue`.
**Blank and border: 198 files, `failures: []`, 0 blanks, 0 frame clips** -
`frame_edge` 0 on all four sides of all three hero views. 3 merged meshes.

## WIRING - THE GAME BUILD'S NUMBERS DID NOT MOVE, AND THE GLB DID

`MB_FIT.thatcher` **ratio 1.04**, creature_h 2.54 / hero 2.45, margin_x 0.12,
3 proving views - copy `pairs.thatcher` out of
`renders/art/minibosses/_fit_report.json`, and **0.97 is the mealman's number,
not this body's.** Nothing in that row changed at pass 8.
**But `assets/monsters/minibosses/thatcher.glb` IS re-exported this pass** -
the geometry changed - so a tree that has the old `.glb` has pass-7 stems.
Static, so `bestiary.gd` still needs a `model` path and **no `anims` entry**.
That wiring is the game build's and is not done here.

================================================================================
# PASS 9 - THE STEM GAUGE. FAULT 5 IS CLOSED BY EYE AND BY TWO NUMBERS, AND IT
# WAS PAID FOR OUT OF FAULT 2'S ACCOUNT. BOTH HALVES OF THAT ARE REPORTED HERE.

The team lead, 27 Nov 04:58 CT, naming fault 5 as the one he could see most
plainly at side zoom: **"the stems are smooth hexagonal dowels"**. I opened
`_cuevalue/_p8_sheet_side_zoom.png` myself before touching anything, and he is
right. There were **TWO causes in that picture, not one**:

  **(A) GAUGE.** Seven stems at r 0.058 in a 0.098 ring are seven fat poles,
  each wide enough on screen that its 8-sided cross-section shows as flat
  facets with long smooth quads - the "hexagonal" half.
  **(B) THE CUT END.** `limb` -> `tube(caps=True)` closes every stem with a
  flat n-gon disc. A sawn dowel has exactly that; a cut straw has nothing like
  it. This was the loudest tell in the frame and no number could reach it.

## THE ENVELOPE IS HELD, SO THE FIT CANNOT MOVE - AND IT DID NOT

Every stem's centreline is placed so `r_out(t) + R_STEM == R_RING*_f(t) +
0.058`, the pass-8 outer surface at every t. The gross silhouette, the bounds
and the ties' reach are therefore unchanged **by construction**, and the
measurement agrees: **`MB_FIT.thatcher` ratio 1.04 on all five A/B arms**,
GREEN, `failures: []`, 0 blanks, 0 frame clips. The pass-4 float came from new
mass near an existing surface; holding the envelope means this pass cannot
repeat it.

## FIVE ARMS, AND THE TWO CAUSES WERE MEASURED APART

`tools/art/_stemread.py` is new and asks the ONE question `_cuevalue.py` says
in its own docstring that it cannot ask. It reads the with/without pair
`_cuevalue` already writes through its one locked camera, derives its zones
per run from the footprint's own principal axis, and goes red on empty.
(A) is `crowns_per_100` across the MIDDLE of the bundle; (B) is `flat_frac`,
the largest connected near-constant-luma patch, in the CUT-END zones only.

| arm | gauge / tips | crowns/100 (side) | flat_frac (side) | side cue/lap |
|---|---|---|---|---|
| `_p9a` | pass-8 baseline | 7.279 | 0.1051 | **1.0732** |
| `_p9b` | A only, 19 stems | 10.900 | 0.0199 | 1.0116 |
| `_p9c` | B only, 7 fat stems | 7.796 | 0.0355 | 1.0628 |
| `_p9d` | A(19) + B | 11.048 | 0.0189 | 1.0148 |
| `_p9e` | A(24 packed) + B | 10.586 | 0.0103 | 1.0406 |
| `_p9f` | **SHIPPED** + ties fixed | **11.042** | **0.0103** | **1.0174** |

**THE INSTRUMENT DISCRIMINATES, WHICH IS THE POINT.** Crowns move on the gauge
arm (+50%) and barely on the tips arm (+7%); flat_frac moves on the tips arm
(-66%) and on the gauge arm. Each number responds to its own cause, so neither
fix can hide a miss on the other behind a single score.

**AND `_p9c` IS A FINDING, NOT A WASTED ARM: B ALONE MAKES IT WORSE.** Seven
fat stems with pointed ends stop reading as dowels and start reading as
**sharpened stakes**. The cut-end fix is only correct on top of the gauge fix.
A one-arm pass would have shipped that.

## WHAT I BROKE THIS PASS AND ONLY THE FULL FIGURE SHOWED IT

The tie radius was `R_RING*_f(t) + R_STEM + 0.014`. Dropping the gauge
0.058 -> 0.030 shrank all three ties by 0.028 while the stems stayed out at
the envelope, so **every band sank inside the bundle and stopped reading**. At
the zoom the stems looked right; on the full figure the yealm read as a loose
spray instead of a bound sheaf, and `_stemread` could not see it - it measures
stems, not bindings. The radius now comes from the **envelope** constant and
never from an individual stem's gauge. Pass 3's waist profile only actually
reads now that the ties clasp the outside of the bundle.

## THE COST, STATED PLAINLY. FAULT 2 IS WORSE ON THE SIDE THAN PASS 8 LEFT IT

`_cuevalue`, cue p50 against lap p50, pass-8 shipped -> pass-9 shipped:

    front  1.1529 -> 1.1614   (better; cue spread 0.5377 -> 0.5716)
    side   1.0732 -> 1.0174   (WORSE - most of pass 8's gain given back)
    back   1.0831 -> 1.0536   (worse)

The reed footprint did not shrink from the gauge - it grew, 30,569 -> 33,660
px at `_p9e` - so there is not less reed; **each reed pixel is darker**,
because the azimuthal gaps between fine stems let the dark coat show through
from behind. Packing the outer shell to 16 stems recovered most of it
(1.0116 -> 1.0406). Restoring the ties then spent it again (1.0406 -> 1.0174),
because the bands are `dark` and occlude pale reed (footprint 33,168 ->
29,949).

**I CHECKED THE ESCAPE AND IT DOES NOT HOLD.** Pass 8's own note on this
instrument says a MODULATED mass separates from a flat one even where the
medians sit on top of each other, which would have excused the p50 drop. The
side cue **spread went down too**, 0.4689 -> 0.4318, and p95 0.6994 -> 0.6650:
the fat stems' bright crowns were brighter than the fine ones'. The modulation
argument does not rescue this and I am not making it.

So **fault 2 is partly re-opened by my own hand on the side and back views**,
and the team lead should decide whether that trade stands. The obvious lever
for pass 10 is the tie section height (0.040, `dark`) - narrower bands would
return cue pixels while still reading as bindings - and it is one change.

## WHAT I CAN STILL SEE IN THE SHIPPED FRAME, HAVING LOOKED

1. The cut-end points are **long and needle-sharp** - closer to quills than to
   blunt-cut straw. Much better than discs, not yet right.
2. The lowest splay hangs loose below the bottom tie and a few stems read as
   separate flicks against the coat, slightly muddying the coat's edge.
3. **FAULT 3 IS UNCHANGED AND IF ANYTHING SLIGHTLY WORSE** - from the side the
   head is still almost entirely behind the bundle, and the splayed stems
   cover a little more of it.
4. FAULT 4 (the leggett reads as a satchel) is untouched and still open.

## WHAT `_stemread.py` CANNOT SEE, AND IT MISSED SOMETHING REAL THIS PASS

It cannot tell reed from any other fine fibre - rope, quills and a wheat sheaf
all score well. It counts crowns from SHADING, so a flat-lit geometric fix
will not move it. **And it scored `_p9e` green while all three ties were
invisible**, because it measures stems and nothing else. The picture is the
evidence; this is the suspect.

## WIRING - THE NUMBERS DID NOT MOVE, THE GLB DID

`MB_FIT.thatcher` **ratio 1.04**, unchanged on every arm - nothing for the
game build to re-derive. **`assets/monsters/minibosses/thatcher.glb` IS
re-exported this pass**: the yealm geometry changed, so a tree with the old
`.glb` has pass-8 dowels. Static, so `bestiary.gd` still needs a `model` path
and **no `anims` entry**. That wiring is the game build's and is not done here.
