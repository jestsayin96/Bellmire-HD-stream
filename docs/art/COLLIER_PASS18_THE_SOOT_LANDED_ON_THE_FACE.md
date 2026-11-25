# COLLIER PASS 18 - THE SOOT LANDED ON THE FACE, AND THE SOOT WAS MINE

25 Nov 2026, the 14:34 CT art firing. The row: **"THE 360p BROW, WHICH IS THE
ONE THING STILL UNRESOLVED ON THE COLLIER AND IS YOURS."** Render the brow at
the rung the player sees, LOOK at it, and say whether it reads as a brow or as
a smear.

## THE ANSWER: AT THE SHIPPED SETTING IT WAS A SMEAR, AND I BROKE IT AN HOUR AGO

Pass 16 shipped `COLLIER_FACE_SKIN=0.6` with the sentence *"the brow is still
one solid bar at 360p"*, and the team lead said plainly in that tick that the
sheet DOES NOT RESOLVE IT AT THAT SCALE - the half was this lane's measurement
and not his. He was right to withhold it, but the reason it needed re-asking
turned out not to be pass 16 at all.

**Pass 17 - mine, 13:56 CT, one hour before this run - moved the ground under
it.** `_collier_soot` paints the man's `body` geometry 0.55x the clamp's earth
so he separates from the mound he stands on. THE POT HEAD IS `body`. THE FACE -
brow, sockets, rag - IS `dark`. So the same stroke pulled the head down toward
the face's own colour. Pass 17's own source carries the warning in its own
comment - *"a man taken far enough down stops reading as a man and becomes one
black lump with the cues inside him gone"* - and then nobody re-asked the face.

Authored luma predicted it would go under the house threshold:

| | luma | brow-vs-head |
|---|---|---|
| head `body` (0.165,0.132,0.104) | 0.1370 | 23.3/255 |
| head sooted x0.55 | 0.0753 | **7.5/255** |
| brow `dark` (0.042,0.046,0.054) | 0.0457 | |

**THAT PREDICTION WAS TOO PESSIMISTIC AND I AM RECORDING IT AS WRONG.** On the
render the view transform lifts darks, and the measured rung contrast at the
shipped value is 15.0/255 - above 8/255, one connected mark, 13 px wide. Every
number said PASS. The picture said otherwise: at 0.55 the brow, the sockets and
the rag merge into one dark block with a hint of structure in it. This is the
pass-11 lesson again in a new costume - when the number and the picture
disagree, the picture is the evidence and the number is the suspect.

## THE LEVER PASS 16 SWEPT IS NOT THE LEVER THAT WAS HOLDING IT DOWN

Rung brow-vs-head contrast, measured by ablation through one locked camera:

| SKIN | 0.00 | 0.20 | 0.40 | 0.60 shipped | 0.80 |
|---|---|---|---|---|---|
| contrast /255 | 17.8 | 17.7 | 16.9 | 15.0 | 14.6 |

The whole skin range moves it 3.2/255. Soot alone moves it 15.5/255. Skin was
never the lever.

## THE TRADE I DID NOT TAKE

Raising the whole figure's soot buys the brow and sells pass 17's own fix. Same
rung, the operator against his own mound on the SIDE view (the worst view, the
one with only silhouette doing the work), share of on-mound px under 8/255:

| soot | 0.55 ship | 0.65 | 0.75 | 0.85 | 1.00 |
|---|---|---|---|---|---|
| brow contrast /255 | 15.0 | 18.7 | 22.5 | 26.1 | 30.5 |
| side on-mound under 8/255 | **2.2%** | 5.5% | 13.0% | 22.6% | 26.6% |

## THE FIX IS NOT A POINT ON THAT TRADE - THE STROKE WAS LANDING IN THE WRONG PLACE

Soot exists so the operator separates from the mound **he stands on**. He stands
on it with his trunk and legs; HIS HEAD IS UP AGAINST AIR. So sooting the head
buys the pass-17 fix nothing and costs the face everything. The two are
separable, and `head` is already its own declared span.

**THE CLAIM IS MEASURED, NOT ARGUED.** With the head exempted and the trunk left
at 0.55, the operator/clamp numbers are IDENTICAL TO THE LAST DIGIT on every
view and at every head value:

| head factor | 0.55 (=pass 17) | 0.75 | 0.85 | 1.00 |
|---|---|---|---|---|
| side on-mound px | 90 | 90 | 90 | 90 |
| side mean dL | 0.1281 | 0.1281 | 0.1281 | 0.1281 |
| side under 8/255 | 0.0222 | 0.0222 | 0.0222 | 0.0222 |
| front mean dL | 0.1846 | 0.1846 | 0.1846 | 0.1846 |
| brow contrast /255 | 15.0 | 22.5 | 26.1 | 30.5 |

The head contributes exactly zero on-mound pixels. The exemption is free, and it
moves NO GEOMETRY AT ALL - so the ~47 px side nub pass 16 bought with SKIN is
untouched, and `COLLIER_FACE_SKIN` stays at 0.6.

## SHIPPED: `COLLIER_SOOT_HEAD = 0.85`, AND THE PICTURE PICKED IT

The metric maximises at 1.00. The gain from 0.85 to 1.00 is not visible at the
rung, and two things are lost:
  - **Rule 2, wear is a variable.** A charcoal burner's pot does not come out of
    the smoke clean. At 0.85 the head still carries visible soot.
  - At 1.00 the head sits on EXACTLY the clamp's own unpainted `body` colour,
    leaving no margin if a game camera ever puts the head over the mound. This
    camera never does - which is precisely what made the exemption free - but
    that is a property of this camera, not of the body.

`COLLIER_SOOT_HEAD=<the same value as COLLIER_SOOT>` reproduces pass 17 byte for
byte and is the control arm; it is checked, not assumed.

## IT REACHES THE GAME, CHECKED IN THE SHIPPED FILE

The soot is a vertex colour, so a render-only fix was a live risk. Re-imported
`assets/monsters/minibosses/collier.glb` and read its `collier_body` colour
attribute: three distinct values, ratio to base 1.001 (the clamp, z -0.11..1.45),
0.550 (the man's trunk, z 0.92..1.65) and **0.856 on 864 corners at z 1.57..1.98,
which is the head**. THE FILE SIZE IS BYTE-IDENTICAL TO THE PREVIOUS EXPORT -
only the colour values moved - so a size or mtime check would have called this
shipped when it was not. Read the contents.

## NEW INSTRUMENTS

  - `tools/art/_browshot.py` - Blender. Splits the brow out by its own
    `face_brow` span and renders it WITH and WITHOUT through one camera locked
    before either frame, letting the renderer do the depth. This is the trap-5
    test: `mask_of` answers how big a thing is and never whether it can be seen.
    ONE camera for every arm, derived once, because a per-arm camera differs by
    a hair in `ortho_scale` and at a rung where the whole head is ~20 px that is
    the thing being judged. RED on: no span, span merged to nothing, 0 verts,
    item count not conserved, bounds moved, any blank frame, any alpha on the
    frame border, and ZERO px moved at full res.
  - `tools/art/_browlook.py` - PIL/Linux. The rung arithmetic and the sheet.
    Reports moved px, **the labelled connected marks** (a brow is ONE wide mark;
    two or three is the dashed read pass 16 warned about and could not see in
    its own number) and the contrast, with the side nub beside it as the cost
    column. RED on an empty rung mask - a contrast over no pixels reads perfect.
  - `tools/art/_browzoom.py`, `tools/art/_bodyzoom.py` - the magnified head and
    whole-body crops that were actually looked at.

Reproduce: `BROW_SET=skin|soot|head` on both tools. The per-arm B/X frames are
not committed (26 MB); the sheets, the JSON and the tools are, and the frames
regenerate from them.

## WHAT MY HARNESS STILL CANNOT SEE

  - The face is judged on the FRONT view at one elevation. The in-game camera is
    not this camera, and the head/mound overlap that makes the exemption free is
    a property of this framing.
  - The brow is ~14x3 px at the rung. Nothing here says it reads as a BROW
    rather than as a dark band; it says it is one mark, separated from the
    sockets, at 26.1/255. Whether a viewer reads "face" is not a number I have.
  - The operator is still small against his own clamp, which is the pass-15/16
    fault and is not touched by this pass.
