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
