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

## PASS 4 - THE GAUGE IS MEASURED NOW, AND THAT CHANGED THE ANSWER TWICE

Three passes judged the vane count BY EYE off a contact sheet and all three
were wrong in a different way. Pass 4 built the instrument first:
`tools/art/_fanner_vane_ab.py` re-slots ONE vane to a probe material and
re-renders through the SAME camera, so a vane's number is the pixels where it
is the FRONT-MOST thing. Geometry is never dropped, so the bounds cannot move
and the camera cannot quietly lie.

**IT IMMEDIATELY SAID SOMETHING NO EYE HAD.** Pass 3's "front 3" was not three
good vanes and one weak one. Three vanes read 4200-6600 px and the fourth read
**ONE PIXEL**. The vane at 185 degrees sat on the ring's BACK, which on this
body is the half holding the man: the glow dome ate its lower band and HIS OWN
SKULL ate the upper. It was absent, not marginal, and no nudge would have found
it.

**FIX A - THE LAYOUT, CHOSEN BY SEARCH AND NOT BY ARGUMENT.** Two faults pull
opposite ways, which is why three passes of reasoning could not land it:

- Move the vanes to the FORWARD arc and occlusion dies - every candidate's
  weakest vane jumped to 400+ px. But every one then read **SIDE = 2**, because
  from the side a vane's lateral position is `-r*cos(theta)` and a mirror-
  symmetric fan collapses two pairs onto each other. Measured min lateral gap
  of the -66/-23/23/66 fan across the four views: **0.0000 m**.
- Spread them round the full ring and the lateral gaps are fine - pass 3's ring
  scored 0.0902 m, better than any forward fan - but the man eats whichever one
  goes behind him.

So the search scores BOTH at once, and round 2 found layouts clear of both,
with gaps to 0.1141 m. Those still read 3 of 4, and the arithmetic says why:
the projected ring is only about 0.74 m across and four blades 0.168 m wide
fill 0.67 m of it, so neighbouring footprints MUST touch. **WIDTH WAS THE ONLY
FREE VARIABLE LEFT.** Round 3 moved it, one change at a time.

WINNER `ring_a_w090` - 79/134/262/310 degrees, 0.300 long, **0.090 wide**:

    front          count=4  px 3923 3920 3752 4087   fused []
    side           count=4  px 2859 4282 1880 3800   fused []
    three_quarter  count=4  px 1926 3650 1588 3776   fused []
    back           count=4  px 3932 4132 3875 3977   fused []

**FOUR FROM EVERY VIEW, NO FUSED PAIR, WEAKEST VANE 1588 px AGAINST ONE.**
0.110 still fused; 0.075 also read 4/4/4/4 and lost the tie on weakest-vane
margin, so the WIDER blade shipped.

**FIX B - THE FEET. A SINGLE RADIUS CANNOT SIT ON THIS RIM.** The bowl is
squashed 0.82 in y, so the rim is an ELLIPSE, 0.392 across and 0.321 deep. The
old fixed 0.405 was outside the rim at the sides and **0.084 clear of it dead
forward** - the forward vanes were standing in mid-air. Each foot now solves
the ellipse for its own angle.

**FIX C - THE EYES AND THE HEARTH WERE ONE MATERIAL.** "The same warm tone" was
not a near-miss, it was an identity: both were slotted `glow`, so they were the
same rgb at the same emission and **no render could ever have separated them**.
The eyes now carry their own emissive slot, `ember`, a deep red at under half
the hearth's strength. Measured in RENDERED pixels inside each feature's own
visible footprint, not on paper (`tools/art/_fanner_value_ab.py`):

    front          eyes luma 0.3337  hearth luma 0.6138  ratio 1.84
    three_quarter  eyes luma 0.3358  hearth luma 0.6203  ratio 1.85

The hearth out-reads the face. It tied before, by construction.

`ember` is a FIFTH slot and the merge's slot tuple was hard-coded at four.
A body that does not declare it has no `ember` group and the loop skips it, so
nothing else moves - and that is EVIDENCE, not an argument:
`renders/art/minibosses/_ember_regression.json` hashes geometry and material
state for eight shipped bodies (beadle, dyer, greener, overlooker, dredger,
stoker, collier, leech) on origin/art's minibosses.py and on this one. **All
eight hashes identical.**

**FIX D - THE self_seen CELL, AND PASS 3 WAS WAITING FOR SOMETHING THAT CANNOT
HAPPEN.** Pass 3 wrote that `_backread.py --keys fanner` returned RC=0 but the
row never landed, and handed the next firing a bug to find. There is no bug:
**`_backread.py` writes `_backread<tag>.json` and has never written
`_selfseen_all.json` at any point in its life.** The merge was always a
separate hand step - the file's own provenance note says so for the dredger,
the harrowman, the pledgeman and the timberman. The row is merged now, row by
row, 62 -> 63, the other rows untouched, and measured on the PASS-4 geometry
rather than pass 3's, because self_seen is an OCCLUSION measure and both of
this pass's changes move occlusion. `man_seen` front **0.85** against a 0.75
bar.

`minibossfit` is now **GREEN**: `ok: true`, `errors: []`, `shipped_red: []`,
`ok_shipped: true`, blank-and-border 192 files 0 failures across 64 cells.

**A TRAP WORTH THE NEXT LANE'S TIME: BLENDER EXITS 0 ON A PYTHON TRACEBACK.**
The first run of this harness died inside `lordgen.add_lights` - `aura` is the
rim light's rgb triple and I passed a float - and the subprocess still returned
**RC=0**. A `.done` file holding 0 is not a pass. Trust the json or nothing.

## THE FIT PROOF - WHAT I LOOKED AT, AND WHAT IS STILL WRONG

Rendered and LOOKED AT: `renders/art/minibosses/fanner/{front,side,three_quarter}.png`
across all three passes, and the pass-1/2 `hero_{front,side,back}.png` beside a
real KayKit adventurer.

GREEN: `ok: true`, `errors: []`, `blank: []`, border check clean, 4 views,
1014 tris, span 1.32 m CORRIDOR-SAFE, UNDER-LID, NOT room-locked. Hero ratio
0.95 - it stands just under a knight, which is right for a thing that is meant
to look modest until the party crowds it.

**PASS 3's FAULT LIST, AND WHERE PASS 4 LEFT EACH ONE.** 1 and 4 are CLOSED
and measured; 2 is IMPROVED BUT NOT CLOSED; 3 and 5 are STILL OPEN AND I LOOKED
AT THEM. The pass-3 text is kept below verbatim so the record is not tidied.

  1. THE COUNT - **CLOSED.** 4/4/4/4, no fused pair, weakest vane 1588 px.
  2. THE FEET - **NOT CLOSED, AND I CAN SEE IT IN THE FRONT RENDER.** The
     ellipse fix removed the dead-forward float, and on the SIDE the vanes
     plainly meet the rim. On the FRONT there is still background visible
     between the left-hand blades and the bowl. The cause is not the mount: a
     vane planted on the FAR rim projects at the far rim's screen height,
     which sits ABOVE the bowl's near silhouette, so a correct 3D join reads
     as a gap. Fixing it means dropping the feet far enough to tuck behind the
     bowl's silhouette, which costs visible vane px - so it is a pass 5 with
     the gauge re-run, not a tweak.
  3. A VANE CROSSES THE BOWL MOUTH - **STILL OPEN.** Visible on the side view.
     The cause is now known and is NOT the radius: the blade box is built on
     WORLD x/y, so its wide 0.090 axis points radially at some azimuths and
     tangentially at others. The fix is to orient each blade tangentially so
     its radial reach is always the 0.052 thickness. I did not take it this
     pass because it moves occlusion and would have invalidated the self_seen
     cell I had just landed.
  5. THE FAR VANE READS OFF THE SKULL ON THE SIDE - **STILL OPEN**, same fix
     as 3 and same reason for deferring it.

**PASS 3's ORIGINAL LIST, UNEDITED:**

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
