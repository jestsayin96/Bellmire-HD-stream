# COLLIER PASS 16 - "FLUSH" WAS THE WRONG WORD

25 Nov 2026, ART lane, taken from the 11:58 CT plan row:
"TAKE THE ~48 px SIDE NUB - your own shipped body, your own unestablished
cause ... do not spend the hour on a fourth guess - ABLATE IT."

Ablated. The cause is established and it is arithmetic, not taste.

## WHAT THE ~48 px ACTUALLY IS

Measured against the p14 control on `hero_side.png`, the shipped pass-15 body
adds **47 px** outside the control outline (1 lost), all of it inside
y204-232, x409-416 - a sliver 8 px wide at eye height. Front and back add and
lose ZERO. Ablation at flush, which pass 15 never ran (its ablation was done
on the +0.012 proud candidate):

| arm        | side added | front face-change px |
|------------|-----------:|---------------------:|
| all        |         47 |                  939 |
| no brow    |         29 |                  816 |
| no rag     |         26 |                  689 |
| no eyes    |         43 |                  707 |
| no face    |      **0** |                    0 |

`no face` is 0, so the nub is **entirely the face** and nothing else on the
body. The boxes SPLIT, which is the part worth having: removing the brow
clears y204-209 and leaves y210-232; removing the rag clears y220-232 and
leaves y204-219. **The "nub" and the "thin dark line curving down from it"
that pass 15 wrote as one finding are two pieces with two causes** - the nub
is the BROW, the line is the RAG.

## THE CAUSE, AND WHY THREE GUESSES AND A SWEEP ALL MISSED IT

A fourth sweep first, because the plan said not to guess: span 1.00 / 0.85 /
0.70 / 0.55 gives **47 / 47 / 47 / 47** while the front face read falls
939 -> 899 -> 874 -> 835. Span is pure cost and moves the nub by nothing at
all. That is the fourth disproof, and it is the clue.

It moves by nothing because **the break is the brow's MIDDLE, not its ends**,
and the middle sits at xf 0 whatever the span is. And the middle is proud
because:

* `_face()` returns a point ON the ellipsoid, and that point is the tube's
  **axis**. At `COLLIER_FACE_OUT=0` the brow's SKIN therefore stands a whole
  tube radius - **0.024 m** - outside the skull.
* `surf()` thickens symmetrically, `+-thick/2` (creatures.py:88), so the rag's
  skin stands **0.010 m** proud at the same setting.

Pass 15 swept `COLLIER_FACE_OUT`, called 0.0 "flush - the face sits exactly on
the skull", and wrote that the residual was unexplained. **The sweep was
moving the centrelines. The residual 47 px is the pieces' own half-thickness,
which that variable cannot reach.** The word "flush" was doing work the
geometry never did.

## THE FIX, AND THE NUMBER THAT TRIED TO PICK THE WRONG ONE

`COLLIER_FACE_SKIN` (new) sinks each piece by a fraction of its OWN
half-thickness, so the SKIN is what sits on the skull.

| SKIN | side nub px | front face-change px |
|-----:|------------:|---------------------:|
| 0.0  |          47 |                  939 |
| 0.40 |          32 |                  909 |
| 0.60 |      **22** |              **897** |
| 0.80 |          15 |                  872 |
| 1.00 |          10 |                  855 |

**THE NUMBERS WANT 1.0 AND THE PICTURE FORBIDS IT.** At SKIN=1 the tube is
tangent to the ideal ellipsoid from inside, so it shows through only where the
16-segment sphere's facets sag in: **the brow renders as two separate dashes**
and at the 360p rung the face stops reading. The face counter fell only
939 -> 855 for that - 9% - so **the instrument cannot tell a solid brow from a
dashed one and must not be allowed to decide this.** I looked at the sweep
(`renders/art/minibosses/_nub/sink_sweep.png`, full size and 360p) and the
brow is one solid bar at 0.4 and 0.6, thinning at 0.8, broken at 1.0.

SHIPPED AT **0.6**: the nub is halved, the "broken handle" read is gone from
the side crop, and the brow is still a solid bar at stream distance.
`COLLIER_FACE_SKIN=0` reproduces pass 15 byte for byte and is the red arm.

## WHAT IS STILL WRONG, AND I CAN SEE IT

- **22 px of the nub remain.** It is no longer a hook; it is a small dark tick
  where the brow crosses the profile, which is arguably what a brow in profile
  should do. I am not claiming it is zero and I did not buy the last 12 px,
  because the brow breaks before they are gone.
- The rag's edge still reads as a thin dark seam down the side of the head
  rather than as cloth. Inside the silhouette now, but visible.
- **At 360p the front still reads as "a head with a front", not as a face.**
  Unchanged by this pass; the knight beside it still reads as a face at the
  same size. Pass 15 said this and it is still true.
- **The operator is still brown-on-brown with the clamp he stands on.**
  Raised in pass 14, raised in pass 15, not touched in pass 16. Still open and
  no number in this lane reports it.

## THE INSTRUMENT, AND WHAT IT CANNOT SEE

`tools/art/_nubread.py` (Linux bridge; PIL + numpy). Counts, per arm, the
pixels the arm's silhouette adds OUTSIDE a control silhouette, localises them
to a box and to row-runs, and - with `--facectl` pointed at the
`COLLIER_FACE=0` arm - also counts how many front-view pixels the face
changes, so a silhouette fix cannot quietly be paid for with the face.

It goes RED on an empty mask and RED on an absent render. That second guard
was added because the first version printed `{"missing": true}` for a mistyped
arm directory, which is a comfortable nothing in the shape of a result.

**IT DID NOT PICK THE SHIPPED VALUE.** It ranked 1.0 best on both of its
numbers and 1.0 is the one arm that breaks the face. It cannot see:
continuity (solid vs dashed), anything dark that lies INSIDE the body's own
alpha, or two pieces that are the same colour as each other. The picture
picked 0.6.

## PROOF

- `renders/art/minibosses/collier/hero_{front,side,back}.png` - on a real
  KayKit knight, idle, three views, looked at.
- `renders/art/minibosses/_nub/nub_crop.png` - the ablation on the side crop
  at 6x: ctl / all / no-brow / no-rag / no-eyes / no-face.
- `renders/art/minibosses/_nub/sink_sweep.png` - the sink sweep on the front,
  full size and at the 360p rung. This is the sheet that overruled the number.
- `renders/art/minibosses/_nub/side_pick.png` - ctl / 0.0 / 0.6 / 1.0 on the
  side crop.
- Red arm `collier_p16red` = `COLLIER_FACE_SKIN=0`, which must measure 47.
