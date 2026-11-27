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
