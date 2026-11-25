# THE TIMBERMAN (Deadfall) - the 61st miniboss, and I blamed the wrong arm for two passes

**Lane:** art. **Built:** 25 Nov 2026, 01:34-02:0x CT. **Branch:** `art`.
**Plan row:** the 00:58 CT 25 Nov TAKE THIS NEXT block - *"ART - the 60th is
TICKED ... You are the one lane allowed to invent, so build the 61st, and
measure the count off `tools/art/minibosses.py` or the fit register, never off a
number in a prompt."*

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

| measured | where | value |
|---|---|---|
| `ORDER` | `minibosses.py`, initial literal + every `ORDER = ORDER + [...]`, parsed with `ast` | **60 entries, 60 distinct**, last `crimp` |
| `BUILDERS` | initial dict + every `.update({...})` | **74 keys** - 60 bases, 2 variants (`drillmaster_tall`, `drillmaster_chibi_tall`), 12 chibi |
| the 60 `idea` strings | `CANON`, read in full before designing | see NOT-THIS below |
| packs on disk | `C:\hd adventure\_packs`, walked | **49 packs / 10,172 files** |

So this is the **sixty-first base**. Two prompt lines are stale and are corrected
by the measurement, not by argument: my own prompt says "THIRTY-THREE already
exist" (stale by twenty-seven) and "40 PACKS" (**there are 49**).

**THE PACKS RULE WAS APPLIED, NOT SKIPPED.** The walk found 448 timber-ish
candidates - KayKit ResourceBits `Wood_Plank_A/B/C`, `Wood_Log_A/B`, the Castle
pillar family. None was used, for two reasons that are about this body and not
about taste. First, every one of them is **straight**, and the single clearest
sentence this model has to say is that the prop is **bowed under load**; a
dressed plank imported at full fidelity says the opposite thing very
convincingly. Second, a pit prop is a round trunk, not sawn stock, and the
three spares have to merge into this file's four-material budget rather than
arrive with their own.

## THE IDEA, AND WHY IT IS NOT A RE-SKIN

**ITS DEATH IS THE DANGER.** It is the one prop under a cracked gallery roof.
In all sixty of the other `idea` strings **killing it ends the threat**; this is
the only body in the house where killing it *is* the threat. Put it down before
its three spares are set and the roof comes down on everyone in the room. The
answer is on the model twice - **drive the three spare props home**, or **knock
the two folding wedges at its foot** so the prop goes slack and it quits.

**THE NEAREST NEIGHBOUR IS A DESIGN THIS FILE ALREADY KILLED, AND I AM NAMING
IT RATHER THAN QUIETLY RE-PROPOSING IT.** The Tither's docstring (45th) records:
*"a timberman drawing the props so the roof comes down on a count: the
SLUICEKEEPER already winds its hazard open A STEP AT A TIME. An escalating room
clock is one fight shape, not two. Dead."* That judgement was right and it does
not reach this one, because **there is no count here**. Nothing ticks, the roof
is stable for as long as the fight lasts, and it falls only on an event the
*party* chooses to cause. The dead design made the room a timer; this one makes
the kill a decision. The full NOT-THIS list - sexton, pledgeman, stopper,
pitman, dauber, rammer, stackman, comfitmaker - is in the builder docstring.

## FIVE PASSES, AND WHAT EACH ONE WAS FOR

Every pass rendered GREEN with zero blanks and zero errors. Every fault below
was found by **looking at the picture**, not by reading the report.

- **Pass 1** - built. `ok true`, 0 blanks, 0 errors, and on both orthos **this
  body had no arms**. The high fist sat 0.02 m from its own shoulder inside a
  torso sphere of radius 0.318 and rendered as a lump on his chest; the low arm
  ran from the far shoulder across the belly and was swallowed whole. "Both
  hands on the timber" existed only in the docstring. The head tree read as a
  **giant mallet**, the three spares as **one leaning board**, and the wedges as
  two pale nubs four pixels across.
- **Pass 2** - six separable fixes, each judged on its own in the same render:
  head tree lengthened and given three crosswise lagging boards (A beam with
  nothing on it is carried; a beam with boards across it is held up); crown
  cheeks moved from 'bone' to 'dark' so the one pale cue is not competing with a
  white carton; the spares **fanned** onto three different rakes out of one
  plane; wedges to 0.42 m; bow 0.085 -> 0.125; high arm given a real reach. Five
  of the six worked. The new low arm came back a **four-sided plank** out of his
  chest.
- **Pass 3** - rebuilt the low arm. **I had blamed the wrong arm.** The angular
  shape lying across his face on the side ortho survived untouched, which is how
  I learned it was the HIGH arm all along: its elbow sat at y -0.230 against a
  jaw at y -0.212, so on a camera that projects (y, z) it passed 0.018 m in
  front of his face. The pass-3 fix was still worth having - the low arm really
  was a plank on the front - but **the thing I said it would fix, it did not
  fix**, and the only reason I know that is that I looked at the same view again
  instead of reading the green report.
- **Pass 4** - the high elbow swings out in X and stays behind the face plane:
  the face is clear on both orthos. The four-point low arm held its y in front
  of the belly as designed and the side ortho returned **a closed rectangle** -
  shoulder, down, across, back, torso filling the middle. An arm with two square
  corners is not an arm.
- **Pass 5** - **the left arm gives up and hangs, and that is the answer.**
  Three arrangements of that limb have now been measured on the same two
  cameras (back to a spare: a plank over the face; across the belly: invisible;
  four-point: a rectangle). The readable one is the plain one. Nothing a viewer
  could see was lost: the sentence is HIS SHOULDER AND ONE HAND ARE UNDER THAT
  TIMBER, and the shoulder pad and the high arm say it. A second hand on the
  same stick was my tidiness, not the viewer's information, and it cost three
  passes.

## THE NUMBERS, MEASURED ON THE SHIPPED BUILD

`minibossgen --only timberman`: `ok true`, errors `[]`, blank `[]`, **4 meshes /
1,691 faces**, span **2.01 m CORRIDOR-SAFE**, **UNDER-LID**, third tallest body
in the house at **3.05 m** behind stiltman 3.20 and iceman 3.12.

`minibossfit --only timberman`: **verdict GREEN, ok true, 63 rows, errors `[]`**,
`blind_views []`, `unproved_cells []`, `stale_margin []`, `red_summary.rows []`.
For this row: `creature_h` 3.05, `hero_h` 2.45, **ratio 1.24**, `pair_w` 3.87,
`air_x` 1.727, `fits_frame` true, **3 proving views**, `seen` 1.0 for creature
and hero on all three, and **every `frame_edge` and `frame_edge_disk` zero on
front, side and back**. `air_px_min` **113**, tightest view `front`.

`_backread --keys timberman` (the viewer's question: render with and without the
man through one camera and count the pixels that MOVED) - **man_seen front
0.9858, side 0.8563, back 0.8456**, against the house bar of 0.75, errors `[]`.
The row is merged into `_selfseen_all.json` with its own `measured_at`
`2026-11-25T02:01:12-0600`; the census was re-run first and now covers 63 rows
with **0 pairs in no list**.

**TWO GATES WENT RED BEFORE THEY WENT GREEN AND BOTH WERE RIGHT TO.** The fit
report refused the body twice - first because the self-seen census had been
taken over 62 register rows and was being read against 63 ("it describes a
different house"), then because timberman was MEASURABLE and carried no
self_seen cell ("an unasked instrument is RED, not green"). Neither was worked
around. The census was re-run and the measurement was taken.

**`_selfseen_all.json` `ok` is false, and that is NOT this body.** It was false
before this run on `panner: the man span merged to no object` - verified against
`HEAD:` rather than asserted. My merge added one row and changed nothing else.

## WHAT I CAN SEE THAT IS STILL WRONG

The honest list, from looking at the hero sheet at hero scale:

1. **The wedges are the weak half of the answer.** At hero scale they are two
   small pale chips at the prop's foot, and from the BACK view they read as a
   rag or a bone rather than as two driven wedges. The spares carry the read;
   the wedges are a close-up cue. If the game build wires only one affordance,
   wire the spares.
2. **The side view loses one spare.** Three are countable from the front and the
   back; from the side the nearest two hide the third. The count is a
   front-and-back cue by construction, and the register's own side `man_seen`
   0.856 is the same fact from the other end.
3. **The hanging left arm is nearly invisible from the side** - it sits inside
   the torso's own outline on that camera. Normal for a hanging arm, but it
   means the side view carries one arm, not two.
4. **The raised arm merges with the prop on the side view.** There is a sliver
   of sky between them and no more.
5. **The bow is subtle at hero scale.** It reads as a slightly kinked timber
   rather than a loaded bend at pane distance; it is clear on the full-size
   ortho.
6. **The crown is a heavy dark mass** - shoe, cheeks, beam and three lagging
   boards are all in the dark slot, so the top of the frame is one dark cluster.
   It reads as rock overhead, which is what it is, but it is the least
   articulated part of the body.

No clip, no float and no bad anchor that I can see: the legs and the three
spares are all seated with `seat()`, the prop stands on its own sole plate,
nothing ends in mid air, and both figures carry their own ground shadow.

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT TOUCH ANY OF IT

- `scripts/bestiary.gd` - add a row for `timberman` with `model:
  "res://assets/monsters/minibosses/timberman.glb"` and **NO `anims` entry**:
  this body is static and has no armature. `h` 3.05 is the authored height and
  is what the fit sheet's 1.24 ratio was measured at.
- `scripts/delve.gd` - `Delve.MB_NAME["timberman"] = "Deadfall"`.
- `data/lore_lines.json` - `miniboss_feed.by_key.timberman`: *"Something in here
  is holding the roof up."*
- `data/commands.json` - the `miniboss` short/what counts move when the engine
  side does.
- **It is CORRIDOR-SAFE at 2.01 m clear span and UNDER-LID at 3.05 m**, so it is
  NOT room-locked and needs no spawn gate on size.
