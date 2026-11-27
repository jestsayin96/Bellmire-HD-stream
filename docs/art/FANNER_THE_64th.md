# 64 - THE FANNER. IT BURNS AS HARD AS YOU CROWD IT. firepit, the fourth one.
2026-11-26, 21:35-22:5x CT, the art lane.

## WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED

I parsed `ORDER` out of `tools/art/minibosses.py`: **63 unique keys**, no
chibi/tall variants among them. The overlooker's own docstring says "the 63rd",
which is the second witness. So this is the 64th and nothing was rebuilt.

**MY FIRST CENSUS WAS WRONG AND I CAUGHT IT BEFORE I DESIGNED OFF IT.** A
regex over the CANON tuples returned **17 of 63** because the newer entries
are shaped differently; a paren matcher got 61, and `timberman` and `collier`
were read by hand. `docs/art/MINIBOSSES.md`'s table carries only **26 of 63**,
so a gap argument made against the doc would have been an instrument that
cannot see. The corpus below is 63 of 63.

## WHY THIS ONE - THE AXIS IS EMPTY

Every one of the 63 is answered by a decision about WHAT the party does, WHO
acts (Beadle), WHO is struck (Overlooker, Fenman, Dyer), WHERE it stands
(Weigher, Roper, Harrowman), WHEN it acts (Rammer, Panner, Stopper, Blower,
Iceman), HOW HARD it swings (Dredger), or WHICH OF THEM has struck (Straker).
**NOT ONE OF THEM ASKS HOW MANY OF YOU ARE ON IT.**

The three it is nearest to, and the differences are not quibbles:

- the **FERRYMAN** also ends with one hero fighting it, and it is the opposite
  direction: the Ferryman CHOOSES who is aboard and nobody else's blows land.
  The Fanner chooses nothing - every blow lands, and the party decides how
  many of them to spend.
- the **DREDGER** is the nearest in shape of sentence and it is about ONE
  hand: how hard it swings. The Fanner does not care how hard anybody swings.
- the **STOKER** is the other firepit fire and its condition is on the ROOM -
  starve the pit. The Fanner's pit is on its own chest and cannot be starved;
  the draught is the party.

**FIREPIT WAS THE THINNEST THEME** at 3 of 63 (next thinnest were six at 4).
**WEAR 0.64** and **HEIGHT 2.33** are both free rungs, measured off the 63:
0.62 and 0.65 are taken, 0.64 is not; 2.32 and 2.34 are taken, 2.33 is not.

## THREE PASSES, ONE CHANGE EACH, AND EVERY ONE DRIVEN BY A PICTURE

**PASS 1 - FIX A: THE HEARTH DID NOT EXIST IN THE PICTURE.** I sank a FLAT
glow disc 0.052 under the basket rim. All three orthos are near level with it,
so every camera saw the rim wall and none saw the fire: the creature whose
whole mechanic is the hearth it carries rendered as a man holding a black tub.
`ok: true`, `errors: []`, `blank: []` were all true and all blind - a glow
occluded by the body's own geometry is not a blank. It is a DOME now, standing
0.040 proud of the rim, and the fire reads on front, side and three-quarter.

**PASS 2 - FIX B WAS WRONG AND MADE THE GAUGE WORSE.** The four vanes are the
count - "you can count them from the door". Pass 1 read **front 4, side 3,
three-quarter 4**. I widened the ring and stood them up; pass 2 read **front
4, side 2**. My own docstring had argued the vanes against HAIRLINES and never
asked about OCCLUSION, so the gauge failed the one way I had not written down.

**PASS 3 - FIX C: THE CAUSE WAS ARITHMETIC AND NO RADIUS COULD HAVE CURED IT.**
Four vanes at 90-degree spacing are TWO ANTIPODAL PAIRS, so each ortho looks
straight down a line holding two of them and the far one hides behind the near
one at EVERY radius - widening the ring only aligned them more exactly.
Spacings are 75/85/105/95 degrees now, so no two vanes are 180 apart.

## THE FIT PROOF - WHAT I LOOKED AT, AND WHAT IS STILL WRONG

Rendered and LOOKED AT: `renders/art/minibosses/fanner/{front,side,three_quarter}.png`
across all three passes, and the pass-1/2 `hero_{front,side,back}.png` beside a
real KayKit adventurer.

GREEN: `ok: true`, `errors: []`, `blank: []`, border check clean, 4 views,
1014 tris, span 1.32 m CORRIDOR-SAFE, UNDER-LID, NOT room-locked. Hero ratio
0.95 - it stands just under a knight, which is right for a thing that is meant
to look modest until the party crowds it.

**FAULTS I CAN SEE AND AM NOT HIDING:**

1. **THE GAUGE STILL DOES NOT READ 4 FROM EVERY SIDE.** Pass 3 reads **front
   3, side 4**. I traded the side fault for a front one: the vane at 185
   degrees now sits dead behind the basket and the front ortho loses it. This
   is NOT closed. The fix is a pass 4 - lift the rear vane or stand all four
   on a visible ring proud of the rim so the bowl cannot eat one.
2. **THE VANE FEET ARE STILL NOT VISIBLY PLANTED.** They begin behind the
   bowl's rim line on every view, so the join is implied and not seen.
3. **A VANE CROSSES THE BOWL MOUTH** on front and side in pass 3 and clips the
   fire's read - a direct cost of the asymmetry in FIX C.
4. **THE EYES ARE THE SAME WARM TONE AS THE HEARTH**, so face and fire read as
   one material. The hearth should out-read the eyes and currently ties.
5. On the side the far vane sits behind the head and reads as attached to the
   skull rather than to the basket.

## WHAT IS RED AND MUST NOT BE READ AS SHIPPED

`minibossfit` verdict is **RED** and that is CORRECT, not a nuisance:

    fanner: MEASURABLE by the self_seen census and carrying NO self_seen cell
            - an unasked instrument is RED, not green

`_selfseen_census.py` was re-run (fanner is now in the census, 78 rows) and
`_backread.py --keys fanner` returned RC=0, but `_selfseen_all.json` still
holds 62 rows and no `fanner`. **The next ART firing owns this**: find why a
`--keys` backread does not land its row in `_selfseen_all.json` and re-run
`minibossfit --only fanner` until the verdict is GREEN. Until then this body
is BUILT AND PROVEN FOR FIT AND SPAN, and NOT self-seen-proven.

## WIRING - THE GAME BUILD LANE, NOT ME

`scripts/bestiary.gd`: the Fanner is **STATIC** - no armature - so it takes a
`model` path and **NO `anims` entry**, same as the twelve creatures of D76.
Model: `assets/monsters/minibosses/fanner.glb`. Height `h` = **2.33**.
Theme `firepit`. I do not edit that file.
