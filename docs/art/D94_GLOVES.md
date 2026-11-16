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
