# D94 GLOVES - WHAT I BUILT, AND WHY THE SLOT STILL FAILS ITS OWN BAR

Mr. E, 16 Nov 04:56, verbatim: *"i understand the rings but gloves can be seen
so we dont have to make new rings."*

So gloves got a real derivation. **IT IS NOT DONE** and I am not reporting it
as done: the proof row still comes back **PARTLY TOO SMALL 6/15**, and the one
version that passed looked like dinner plates. The picture and the number are
both below, because this has stopped being a build problem and turned into a
call only Mr. E can make.

## WHAT IS BUILT AND IS GOOD

**`icons.glove_form(variant, orn, D)` - ONE SOURCE OF TRUTH.** The hub icon
(`icons.build_gloves`) and the thing on the hand (`showcase.acc_gloves`) now
make the SAME call and get the SAME dials. That is the condition that has held
through every D94 fix and it holds through this one.

Five CUTS, from the item's NAME first (`NAME_HINTS`) and its hash only as a
fallback: gauntlet, mitt, studded, vambrace, wrap. Three dials RIDE COST,
because condition is the receipt a viewer paid for:

| dial | what it is | unit | cheap -> dear |
|---|---|---|---|
| CUFF | how far up the forearm | fraction of the forearm | 0.13 -> 0.62 |
| FLARE | the bell mouth, clear of the arm | x forearm radius | 1.18 -> 2.65 |
| KNUCK | the plate off the back of the fist | x shell half-width | 0.06 -> 0.86 |
| SHELL | the hand shell | x fist radius, NEVER below 1.0 | 1.26 -> 1.62 |

Plate COUNT rides cost too, and `sig(key, name)` jitters every dial +-14%, so
two gauntlets at one price are not one gauntlet (D94b's rule).

## THREE THINGS THAT WERE MEASURING NOTHING, AND ARE NOW FIXED

**1. THE GLOVE WAS SMALLER THAN THE HAND.** Measured on the KayKit adventurer:
fist 0.15 across, hand bone to fingertip 0.258, forearm 0.26, arm 0.30 thick.
The glove was a 0.085 shell with a 0.095 cuff. A glove inside the hand has no
silhouette to tell apart. SHELL is now bounded below 1.0x the fist by
construction.

**2. THE HAND-RADIUS RAY WAS A NO-OP.** Both drivers did
`ray_out(body_trees, anchors["hand.l"], ...) or 0.045`. `rest_anchors()`
returns REST bone positions and the callers had already run `pose_at_post`, so
every cast started in empty air 0.56 m from the posed hand, returned `None`,
and fell **silently** back to the constant. That is trap 3 wearing a different
coat: a measurement that reports success and measures nothing. Radii now come
from BONE SPACING, which is exact and scales with any body - fist radius =
handlen x 0.50, forearm radius = handlen x 0.38, both checked against the mesh
AABB.

**3. THE TEST ITSELF WAS COST-BLIND, AND IT HID THIS.** `d94proof.spread()`
walked the pool cheapest-first taking the first item of each new variant. With
five variants and six cells, every glove in the row cost 200-240 out of a range
topping 420, so `orn` was ~0.00 in all six cells and **every dial that rides
cost sat on its floor**. A row that cannot see the cost ladder cannot test
Mr. E's receipt. `spread()` now keeps the distinct silhouettes - a Guard Helm
must still not render as a hood - but fills each from the member nearest its
share of the cost range. The row is now six silhouettes AND six prices
(200/200/240/260/300/320). **This affects every row of the sheet, not just
gloves, and the other seven rows have NOT been re-shot against it.**

## THE FIT PROOF - LOOKED AT, NOT ASSUMED

Six gloves, real Knight body, idle pose, FRONT, SIDE and BACK, in
`renders/art/d94g_front|g_side|g_back/_row_gloves.png`. 36 renders, blank check
0 failures. The faults I can see, and there are ten:

1. **AT STREAM SIZE I CANNOT TELL THE SIX APART FROM THE FRONT.** Strip 3 is
   the bar and it fails. 0.60% of the hero's pixels change on the median pair.
2. The cuff reads as a **tankard**, not a gauntlet - the mouth is close to the
   cuff diameter, so it is a cylinder with a rim instead of tapering.
3. **The fingers never show.** They are swallowed by the shell in every cell.
4. The thumb is not readable from any of the three views.
5. The hand shell reads as a plain BOX with a strap tick, not a hand.
6. Baker's Mitts: the mitt pocket pokes through the cuff's upper rim - a clip.
7. Armourer's Gauntlets: the flared lip reads as three separate plates floating
   proud of the cuff rather than one rim.
8. The stat gem on the metal cuts is invisible on the body at any view.
9. `inside_pct` runs 50-88%. Some of that is an artefact - a worn glove MUST
   overlap the hand, and `body_trees` includes the arms - but 88% on Carder's
   is the shell sunk into the arm, not an artefact.
10. Penetration 0.033-0.063 m, worst on the Duchess's wrap.

Honest numbers, before and after, same test:

| | verdict | worst | median |
|---|---|---|---|
| before (committed) | PARTLY TOO SMALL 11/15 | 0.00% | 0.33% |
| now, front | PARTLY TOO SMALL 6/15 | 0.00% | 0.60% |
| now, side | PARTLY TOO SMALL 6/15 | 0.00% | 0.78% |
| now, back | PARTLY TOO SMALL 6/15 | 0.00% | 0.53% |

Better, and still failing.

## THE THING MR. E HAS TO DECIDE, AND THE PICTURE THAT ANSWERS IT

A pass WAS reached, once, and I am reporting it rather than burying it. With
the bell mouth at 2.0-3.3x the forearm radius the row scored **TELLS APART,
worst 6.47% / median 9.92%, in all three views**. It also looked like each
hero was carrying **two dinner plates on their wrists**. I looked at it and
would not ship it, so I backed it out.

That is the whole shape of the problem, and it is geometry, not craft:

- The hero is ~105 px tall on a 1080p stream. A glove that is the size of a
  hand is ~10 px and the hands hang flush against a wide tabard, so most of
  those 10 px are occluded by the torso from the front.
- Therefore a glove can only clear "TELLS APART" by standing well OUTSIDE the
  hip silhouette - and anything that big stops looking like a glove.

So one of these, and it is his call, not the builder's:

**(a) Accept gloves as an inventory item, like rings.** Same ruling he already
made at 04:56 for rings: a viewer reads a glove in the hub, where the icon is
400 px and all five cuts and both cost dials are plainly visible. The slot then
stops being measured against the stream bar. **Cheapest, and consistent with
what he has already decided once.**

**(b) Lower the bar for small slots.** Keep gloves on the body, and say that
"PARTLY TOO SMALL" is a PASS for gloves and rings while "DUPLICATE" stays a
fail. The derivation above already satisfies that.

**(c) Change the pose, not the glove.** The idle pose hangs both arms flush to
the body. A pose with the hands even slightly off the hip would show gloves,
boots-of-the-hand and bracers all at once, for every item in the slot forever.
That is an `auto_director` / animation change and is NOT the art lane's.

I did not take (c) and I did not quietly take (a) either, because both are
rulings and neither is mine.

## FOR THE GAME BUILD LANE - WHAT MIRRORS, AND ONLY IF (a) IS NOT CHOSEN

I do not touch `scripts/gear.gd`. If Mr. E picks (b) or (c), the game build
owns the mirror, exactly as it did for the cloak shade step:

- `scripts/gear.gd`, the glove branch: port `icons.glove_form` bit for bit -
  the five cut tables (`_G_CUFF0/_G_CUFFK/_G_FLARE0/_G_FLAREK/_G_KNUCK0/`
  `_G_KNUCKK/_G_SHELL0/_G_PLATES/_G_METAL/_G_FINGERS`), the name-first cut
  pick off the existing `NAME_HINTS` equivalent, and `orn` = the item's cost
  quantile inside the gloves slot.
- Size the result off BONE SPACING, not off a ray at the hand: fist radius =
  (hand -> wrist distance x 2) x 0.50, forearm radius = the same x 0.38. If
  `gear.gd` casts a ray from a rest anchor at a posed body anywhere else, it
  has the same silent no-op bug described above and it is worth a grep.
- Keep the whole glove on ONE bone. Splitting the cuff onto `lowerarm.<side>`
  was tried here and is wrong: each part is carried rigidly by its own bone, so
  the cuff and the hand shell pull apart in the idle pose and you get a bucket
  floating beside a box. There is a render of that mistake and it is ugly.

================================================================================

# THE 10:24 RULING - MORE DERIVED VARIATION, NOT A BIGGER GLOVE (ART, 16 Nov)

Mr. E, 2026-11-16 10:24: *"okay so fix them"* - gloves must READ AT STREAM
DISTANCE, and the fix is more derived variation off the item's own key. **NOT a
bigger glove: FLARE AND SHELL ARE UNTOUCHED BY THIS PASS.** The 2.0-3.3x bell
mouth that was tried and backed out is still backed out.

## WHAT THE MEASUREMENT ACTUALLY SAID, BEFORE I CHANGED ANYTHING

The baseline is `renders/art/d94/_report.json` (16 Nov 14:39) - the SAME SIX
CELLS this re-shoot uses, so the numbers are comparable:

    gloves  PARTLY TOO SMALL 5/15   worst 0.00%   median 0.70% of hero px

`worst 0.00%` is the whole story: two gloves whose stream images are LITERALLY
IDENTICAL. Every failing pair was a pair of the four SMALL cuts -
carder (vambrace), bellrope (wrap), quarreller (studded), forge (vambrace).
All four put the same little lump in the same place on the wrist, so at 1/3
scale the only thing that differed was COLOUR. Colour is not shape.

## THE FOUR DIALS ADDED, ALL OFF THE ITEM'S OWN KEY AND ITS COST

| dial | what it does | why it is not "a bigger glove" |
|---|---|---|
| REACH | how far up the forearm. A vambrace is a FOREARM piece (0.58-0.88 of it), a wrap is a WRIST piece (0.16-0.30) | length along the arm costs no girth |
| LAMES | 0-4 thin bands breaking the cuff up its length | two same-price vambraces are a 2-lame and a 4-lame |
| KNUCK_KIND | ridge / dome / spikes / studs / none, picked per cut from the key | treatment, not height |
| FPLATE | how far plating runs down the fingers | seated on the finger, not standing off it |

Plus a COP at the elbow end of any long reach (a long tube is not a forearm
piece until it has one) and the WRAP'S LOOSE END - the wrap and the studded
glove sit 0.02 of forearm apart in reach, which at stream size is nothing, so
the wrap takes the one direction nothing else occupies: a tie hanging clear of
the arm. Soft, not a plate.

## THE NUMBER MOVED. HERE IT IS, ALL THREE VIEWS

| view | before | after | median before -> after |
|---|---|---|---|
| front | PARTLY TOO SMALL 5/15, worst 0.00% | **PARTLY TOO SMALL 3/15, worst 0.16%** | 0.70 -> **1.08** |
| side  | PARTLY TOO SMALL 6/15, worst 0.00% | **TELLS APART, worst 0.40%** | 0.78 -> **1.37** |
| back  | PARTLY TOO SMALL 6/15, worst 0.00% | **PARTLY TOO SMALL 3/15, worst 0.18%** | 0.53 -> **0.95** |

Sheets: `renders/art/d94g3_{front,side,back}/_row_gloves.png`. Method unchanged -
one outfit, same framing, same measurement, same six cells. Blank check 12 files
per view, **0 failures**, three views. Engine `BLENDER_EEVEE`.

## TWO PASSES, ONE CHANGE EACH, AND WHAT LOOKING AT IT CAUGHT

1. The dials went in. The number moved (5/15 -> 3/15, median +56%) and the
   sheet showed a new fault immediately: **seven thick rings up a flaring cone
   is a STACK OF PANCAKES** - a lamp shade with ribs, which is machinery, not
   Bellmire. Lames are now capped at 4 and the bands are thin (0.075 of the
   local radius, was 0.13).
2. The icon only: the knuckle dome was **an egg standing on the cuff** and the
   finger plates were **sugar cubes floating in front of the fingers**. The
   dome is now a low oval across the knuckles and the plates are seated on the
   finger. The worn piece was not touched by pass 2, so the numbers above still
   stand.

## WHAT IS STILL WRONG - NAMED, NOT HIDDEN

**Three pairs still fail from the front and the back**: carder | bellrope
(0.16%), bellrope | forge (0.25%), carder | forge (0.28%). All three are
mid-price, and from the FRONT a hanging arm puts the forearm against the hip,
so reach - the dial that did the work - is the dial the front view cannot see.
The side view, where the forearm is clear, is the one that now TELLS APART.
That is the shape of the remaining problem and it is a framing fact, not a
colour fact.

Looked at and still visible, worn (`d94g3_*/_row_gloves.png`):
- the cuff is **a wide open tub with a small hand box under it** - at item-alone
  framing it reads as a bucket, and the hand is the smallest thing in the shot
- on the body, both cuffs **merge into one pale mass at the belly** in the idle
  pose, because the hands meet in front
- the **mitt, the vambrace and the wrap are near-identical from the front** at
  stream size, which is the 3/15 above, said in words
- the **wrap's tie does not read on the body** - it is there in the icon and
  behind the arm on the hero
- **raidbreaker's gold bands sit beside the belt** and at a glance read as belt
  furniture rather than as something on a hand

Looked at and still visible, icon (`renders/art/d94g3_icons/_row_icons.png`):
- the cuff reads as a **plant pot** below the hand; this is the icon's original
  composition and predates this pass
- the fingers read as **four organ pipes** standing out of a box
- the wrap's ties read as **small flaps** near the base
- left and right **fuse in the middle** of the frame
- the mitt has **no cuff read at all**
- a cloth-toned knuckle oval reads as **a pale pebble** rather than as leather

## THE NEXT SINGLE CHANGE, IF THIS LANE COMES BACK TO IT

Give the four cheap cuts mass in the ONE direction the front view can see -
outboard of the hip line - WITHOUT widening the mouth. The candidate is an
asymmetric cuff: a longer outboard lip and a shorter inboard one, so the
silhouette gains on the side the body is not occluding. One change, one render.

================================================================================

# 17 NOV - DIRECTIONAL FLARE. THE `_G_FLARE` RE-TUNE, AND IT IS A RE-TUNE IN
# DIRECTION, NOT IN SIZE.

The plan's ART row named this: *"the gloves' `_G_FLARE0/_G_FLAREK` re-tune.
D94e ported your derivation into gear.gd bit for bit, so the game's glove IS
your proof row, and your re-shot row - SAME METHOD - is the ONLY number that
can move the gloves off PARTLY TOO SMALL 3 of 15."*

## WHAT I CHECKED BEFORE CHANGING ANYTHING, AND IT IS THE REASON THIS WORKED

The previous pass closed with a named next step - *"an asymmetric cuff: a
longer outboard lip and a shorter inboard one, so the silhouette gains on the
side the body is not occluding."* That named a DIRECTION, and a direction can
be wrong, so I measured it instead of taking it:

`e3pogen.pose_at_post` turns each upper arm about the ARMATURE'S OWN Y, by
+1.26 on the left and -1.20 on the right. A rotation about Y carries a rest +Z
direction to `(sin a, 0, cos a)`: **(0.952, 0, 0.306) on the left and
(-0.932, 0, 0.362) on the right.** The left arm lives at +X and the right at
-X, so **REST +Z IS OUTBOARD ON BOTH HANDS** - the single direction a hanging
arm does not bury in the tabard, and the one the d94g3 sheet showed as the only
part of a cuff that survives at the hip. The guess was right and now it is a
number.

The sign does not survive into the cone's own space, and that is the trap.
`aim()` builds its rotation with `to_track_quat('Z','Y')`, so for the cuff axis
`(-sgn,0,0)` the cone's LOCAL +X lands on rest-world **+Z when sgn=+1 and -Z
when sgn=-1**. So a cone's skew carries `sgn` and a ring written straight into
rest-world coordinates (the lip, the lames) does not. Getting that backwards
puts one glove's lip through the hip and would have looked like a clip.

## THE ONE CHANGE

`lordlib.scone` - a cone whose rings are off-circle, `r(th) = r (1 + s cos th)`.
**cos has mean zero over a turn, so the mean radius is exactly r.** The skew
adds NO GIRTH ON AVERAGE; it moves girth from the inboard side to the outboard
side. That is why this is not the 2.0-3.3x bell mouth that was tried in D94 and
backed out as dinner plates: THE MOUTH IS THE SAME SIZE, it is just no longer
round. `_G_FLARE0/_G_FLAREK` are untouched in VALUE - they are re-tuned in
SHAPE, by a new per-cut skew table that rides cost and the item's key like
every other dial:

    #            cut:  gauntlet  mitt  studded  vambrace  wrap
    _G_SKEW0   = (0.14, 0.30, 0.46, 0.34, 0.58)
    _G_SKEWK   = (0.06, 0.10, 0.12, 0.26, 0.08)

The four SMALL cuts carry the big numbers, because all three failing pairs were
pairs of small cuts. The gauntlet barely moves - it did not need it.
The hub icon takes the same dial, because the glove in the satchel must be the
glove on the hero.

## THE NUMBER MOVED, SAME METHOD, SAME SIX CELLS

| view | d94g3 (before) | d94g5 (now) | median |
|---|---|---|---|
| front | PARTLY TOO SMALL 3/15, worst 0.16% | **PARTLY TOO SMALL 1/15, worst 0.25%** | 1.08 -> **2.25** |
| side  | TELLS APART, worst 0.40% | **TELLS APART, worst 0.42%** | 1.37 -> **2.96** |
| back  | PARTLY TOO SMALL 3/15, worst 0.18% | **PARTLY TOO SMALL 1/15, worst 0.18%** | 0.95 -> **1.99** |

Sheets `renders/art/d94g5_{front,side,back}/_row_gloves.png`. Blank check 12
files per view, **0 failures**, three views, errors `[]`. Engine
`BLENDER_EEVEE`. **Two of the three failing pairs are gone** - both the ones
that involved Forgemaster's Grips. THE ONE THAT REMAINS IS
**CARDER'S GLOVES | BELLRINGER'S WRAPS**, 0.25% front and 0.18% back, and it
passes on the side. It is the cheapest vambrace against the wrap: both are
small, both are cloth-toned, and from the front the wrap's tie hangs behind the
arm where the camera cannot see it.

## I LOOKED, AND LOOKING CAUGHT A FAULT I HAD JUST MADE

The first shot (`d94g4`) scored the same verdicts but the item-alone framing
showed the lames **standing clear of the outboard wall like a coiled spring**.
Cause: the lame radius was a straight lerp `hw -> mouth` in `f`, which stopped
lying on the cone the moment the cone stopped being round - two different
parameterisations of the same surface. The bands now read BOTH their radius and
their skew off the cuff's own profile at their own x (`prof()` in
`acc_gloves`), piecewise for a stepped cuff. That moved the median again,
front 2.05 -> 2.25, side 2.51 -> 2.96, back 1.70 -> 1.99.

## NINE FAULTS I CAN STILL SEE

1. **THE SPRING IS REDUCED, NOT GONE.** On the glove whose outboard side faces
   the camera the outer lames still stand proud of the wall and read as open
   loops. `prof()` matches the cone analytically, so the remainder is either
   the tube's own radius (0.075 of the local radius, added perpendicular to a
   path that is now strongly curved) or the 14-gon's inscribed-vs-true radius.
   NEXT MEASUREMENT, not a guess: cast each lame vertex at the cuff mesh and
   print the signed distance. I have not run it and I am not claiming which.
2. **PENETRATION GOT DEEPER ON FIVE OF SIX.** carder 0.054 -> 0.060, quarreller
   0.048 -> 0.054, forge 0.047 -> **0.072**, baker 0.057 -> 0.075, raidbreaker
   0.040 -> 0.052. The outboard rim now reaches further and the posed forearm
   leans, so the rim drives into the arm. This is the price of the change and
   it is a real one. The wrap's 0.087 is unchanged and pre-existing.
3. Carder's and Bellringer's **still show nothing at all from the front** on
   the body - they are the pair that still fails, said in pixels.
4. Baker's Mitts are **invisible from the front** on the body at any size.
5. The cuff still reads as **a tub with a small hand box under it** at
   item-alone framing; the skew makes it a LEANING tub.
6. The **icon's lip and lame rings are still round** inside a skewed cuff, so
   on the icon they cross the wall. I did not fix it this pass: one change at a
   time, and the acceptance number is the worn row.
7. **AND I FOUND THE CAUSE OF A FAULT THAT HAS BEEN LISTED SINCE D94G3.**
   "Left and right fuse in the middle of the frame" on the icon is not a
   composition problem: `build_gloves` draws the lip and the lames with
   `ring_pts(r, n, z)`, which builds a ring **centred on the origin**, while
   the hands are at `x = +-0.36`. Both hands' rings are drawn as ONE ring
   through the middle of the icon. It is a one-line fix and it is NOT in this
   pass, because this pass is one change.
8. The hand shell is still a box; the fingers are still swallowed from the
   front.
9. `worst_peak_pct` is 56% on the failing pair - the two ARE different where
   they differ, there is just too little of it at 1/3 scale.

## STILL FOR THE GAME BUILD LANE, NOT ME

`scripts/gear.gd`, the glove branch (D94e ported the derivation bit for bit, so
it is now behind): add `_G_SKEW0/_G_SKEWK` and the directional mouth. The two
things that will go wrong if it is ported by eye:
  - the local skew carries the SIDE'S SIGN when the cuff is an aimed cone, and
    does NOT when a ring is written in rest-world coordinates. Measured above.
  - anything wrapped round the cuff must read its radius off the cuff's own
    profile at its own x, or it leaves the wall. That is fault 1 above and it
    cost me a render to find.
