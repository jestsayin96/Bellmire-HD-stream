# THE CUE READ CENSUS - can the party see what the fight is about?

ART LANE, 25 Nov 2026, 04:3x-05:0x CT; **PASS 7 FIX AND RE-MEASURE 05:3x-06:0x CT**.

## Why it exists

Every miniboss in this file is built around ONE readable object: four lit
vents, five pale pegs on a rim, a bag that fills a band a stroke, a lamp on a
belt. The CANON text says so in nearly every entry - "countable from the
doorway", "you can count them from any side of the room".

The fit register already asserts three things, and NONE of them is that one:

  * `seen: 1.0`   - the CREATURE is visible past the hero. Not the cue.
  * blank check   - the PNG has opaque pixels. Not the cue.
  * border check  - nothing is clipped by the frame. Not the cue.

So a body can ship with every number green and still be, from one side, a
shape with no indication of what it does. That is the Beadle fault of 24 Nov
in a different coat, and it is the pass-11 fault of 17 Nov exactly: an
instrument that cannot see is not a pass.

## The method, and the two methods that are wrong

**WRONG 1 - `mask_of`.** Rendering the cue group ALONE answers how BIG the cue
is. It reads a healthy number for a vent parked behind a shovel. This is the
same lie as `head_glow_px: 156` beside "the head has no face at all".

**WRONG 2 - glow outside the body's alpha.** A cue that sits inside the
silhouette scores zero for every body ever built.

**WHAT IS USED.** Render the body TWICE through the SAME CAMERA - once as it
ships, once with the cue materials swapped for the body material (`MB_CUEOFF`,
no vertex moved) - and COUNT THE PIXELS THAT MOVED. Occlusion, depth, the
shovel and the view transform are then the renderer's problem, which is where
they belong. It is the viewer's question, asked of the renderer.

## It takes a SLOT, and the first run of it was wrong

The first arm swapped only `glow` and called **pledgeman, blower and stopper**
RED. All three are CORRECT bodies. I read their CANON before believing the
instrument: pledgeman's count is "THREE BRIGHT LASHINGS ... the only pale on
the whole body", blower's is a bag "pale and ribbed", stopper's is "five pale
uprights". None of those is emissive - they are `bone`, on purpose, because
the Dyer's pass-3 lesson is that a near-white emissive is a hole and not a
fire. **This file carries most countable cues as PALE GEOMETRY and keeps glow
for things that are actually alight.**

So `MB_CUEOFF=both` is the census and `glow` / `bone` are attributions only. A
slot-scoped run writes "NOT A VERDICT" into its own verdict strings, because a
file on disk saying RED is one read away from somebody chasing a fault that is
not there.

## It goes RED ON EMPTY

A metric computed over zero pairs reads green and means nothing. So a missing
A/B pair is RED and never skipped; a body with zero moved pixels on all three
views is RED; and a run that compares ZERO pairs is RED whatever else it says.

## What the first sample measured - 10 bodies, 25 Nov 04:5x CT

**THIS TABLE IS THE 04:5x SAMPLE AND IS KEPT AS THE BEFORE.** `collier`'s row
was fixed at pass 7 and now reads 427; the live file is
`renders/art/minibosses/_cueread.json`, re-run over the same ten bodies at
05:5x CT. The other nine are unchanged, key for key. See PASS 7 below.

`MB_CUEOFF=both`, 30 pairs, **ok=True, errors 0**. Every body in the sample
shows its cue from front, side AND back. The file is in better shape than the
eye feared.

WEAKEST VIEW PER BODY, ranked (this is the number that matters):

| body      | weakest view px |     | body      | weakest view px |
|-----------|-----------------|-----|-----------|-----------------|
| collier   | **41**          |     | leech     | 5017            |
| pledgeman | 834             |     | timberman | 6708            |
| nightman  | 849             |     | beadle    | 9005            |
| snuffer   | 2087            |     | blower    | 9755            |
| crimp     | 2649            |     | stopper   | 11666           |

## THE ONE FINDING, AND I HAD THE VIEW WRONG BEFORE I MEASURED

**FIXED AT PASS 7, 05:3x-06:0x CT - side 41 -> 427. The finding below stands
as written; it is the diagnosis the fix was built on, not an open fault.**

Looking at the shipped renders I said the collier's fire was a FRONT-ONLY read
and the BACK was the hole. **The measurement says the back is fine and the
SIDE is the hole**, and the measurement is right:

  * collier back - glow 77 px, but `bone` **2393 px**. The four pale plugs,
    which are the ANSWER the CANON text tells the party to use, read clearly
    from behind. The back is not blind.
  * collier side - glow 41 px, `bone` **0 px**. Total cue 41 pixels.

The plug cradle is edge-on and the mound occludes it; the vent arc is all on
-Y. **From the side the collier is an earth mound with a man on it.** I looked
at `collier_cueA/hero_side.png` against `collier_cueC/hero_side.png` and they
are indistinguishable but for one orange sliver. Picture and number agree.

At 41 px it is **20x below the sample's next-worst view** (pledgeman, 834).

## NO THRESHOLD IS SET HERE, DELIBERATELY

Zero is a fault anybody can agree on. "41 is too few" is a THRESHOLD, and a
threshold picked off ten bodies is CHOSEN, not measured. The backlamp guard's
bar was set over all 44 bodies with both arms of a known A/B to separate it;
this instrument has no such calibration yet. The number goes in the file and
the bar waits for the full sweep over all 62. **Do not add a MIN_CUE_PX
constant off this sample.**

## Running it

    # arm A (as shipped) and arm C (cue off, both slots)
    blender -b -noaudio -P tools/art/minibossfit.py -- --repo <W5> \
        --only <keys> --name _cueA --tag _cueA              # MB_CUEOFF unset
    MB_CUEOFF=both ... --name _cueC --tag _cueC
    blender -b -noaudio -P tools/art/_cueread.py -- --repo <W5> \
        --keys <keys> --btag _cueC --slot both

`--tag` keeps every arm out of the shipped render directories. With
`MB_CUEOFF` unset the generator is byte-for-byte what it was.


## PASS 7 - THE COLLIER'S SIDE IS FIXED, AND THE PLAN ROW NAMED THE WRONG VIEW

The 04:58 CT plan row told the art lane to *"fix the collier's cue read FROM
BEHIND ... the four vents are all on the -Y arc by construction, so from behind
the party sees a mound of earth and no fire"*. **That is this file's own
pre-measurement guess, which this file then struck one section above.** The
sentence is quoted verbatim from `minibossgen.py`'s switch comment, written at
04:5x CT *before* the census ran; the census contradicted it the same hour.
Measured, on the shipped body, 25 Nov 05:3x CT:

    collier  front 3784   side 41   back 2430

**The back was never the hole. The SIDE was.** The defect the row wanted fixed
is real and it is mine; only its address was wrong. I fixed the side and I did
not touch the back.

### WHY NOTHING ON THE -Y ARC COULD BE BRIGHTENED INTO VIEW

The side camera sits at **az 90, that is +X**, looking down -X. From there the
plug bundle is on the far flank behind 0.86 m of earth, and every vent is at
radius 0.712 inside a mound whose +X extent is 0.85. The cue was **occluded,
not dim** - no change to a material, a strength or a size could have answered
it. It had to be geometry, on the +X arc.

### THE FIX, AND THE THREE THINGS I REFUSED TO DO

`minibosses.py` `collier()`, new span `seams`: **three short ember seams in the
bay between the 67.5 and 112.5 stakes**, sunk into the flank so the earth is
their own lip, bowed so they are not hoops, staggered in length and bearing so
three equal horizontal bars do not stack into pass 3's crinoline wearing light
instead of iron. Not discs, not in iron collars, **not countable** - a
different shape class from a vent, which is what FAULT 10 is actually about.

  * NOT a fifth vent: the count IS the mechanic.
  * NOT the vent arc swung out to +80: a vent at +80 is edge-on to the front
    camera and the front would read three. Pass 5 already paid for answering
    one camera and asking the other nothing.
  * NOT the plug bundle moved back to +X: pass 5 FIX K moved it OFF +X because
    pass 4's apex walk put the mound's high shoulder in front of it. Putting it
    back is reverting a fix that was right.

### THREE ARMS, ONE VARIABLE, AND 7b OVERPAID

Only the bearing window moved between these; radii and sinks were frozen so
the three numbers are comparable.

| arm | seam bearings (centre/half-width) | front | side | back |
|-----|-----------------------------------|-------|------|------|
| shipped (pass 6) | - | 3784 | **41** | 2430 |
| 7a | 95/15, 87/11, 98/7.5 | 3904 | 393 | 2512 |
| 7b | 105/12, 101/8, 104/6 | 3841 | 260 | 2526 |
| **7c SHIPPED** | **103/14, 92/14, 99/9** | **3902** | **427** | **2518** |

7a put TWO orange nicks on the front rim and I nearly shipped 7b to clear them
- which cost a third of the fix. Looking at 7a's front told me what the number
could not: **the hazard is not a mark on the rim, it is a fifth ember AT THE
VENT ROW'S OWN HEIGHT**, because that is the row a viewer counts. Only the
lowest seam sits in that band, so in 7c only the lowest seam is held off the
front arc and the two above it are allowed to graze the rim where the side
read is paid for. The front's +118 px is two faint marks at mid-height on the
mound's upper-right edge, nowhere near the row of four.

**I LOOKED AT ALL THREE VIEWS OF 7c BEFORE CALLING IT FIXED.** The side now
shows fire in the joins of the earth; the front still reads four embers and
only four; the back still reads four pale plugs.

### WHAT IS STILL WRONG, AND IT IS STILL THE WEAKEST BODY IN THE SAMPLE

**427 px is a 10.4x rise off 41 and it is still last.** The gap to the
next-worst (pledgeman, 834) closed from 20x to 2x and did not close. The seams
read as orange crescents lying ON the earth rather than light coming out from
UNDER an earth lip, because there is no dark brow over them; that is the first
thing a pass 8 should take, with the seam RADIUS as its single change. The top
seam (z 0.742) is the weakest of the three - it is crowded by the crown shelf
and the man's own torso - and the lowest is partly crossed by a stake.

**THE BAR IS STILL NOT SET AND THIS PASS IS NOT AN ARGUMENT FOR SETTING ONE.**
427 being "enough" is exactly the threshold this file refused to pick off ten
bodies. Do not add a MIN_CUE_PX constant off this number either.

### THE REGRESSION ARM WAS RE-RUN AND ITS MEANING IS NARROWER THAN IT LOOKS

`_cueread_regress.json`, re-run on the 7c body: `unset_identical true`,
`zero_identical true`. **The shipped MD5s in that file MOVED from the 05:0x
run, and they were supposed to** - the body changed. What the file asserts is
that the `MB_CUEOFF` switch moves no pixel on the shipped path, and both arms
still match the shipped render byte for byte. A reader comparing only the
hashes across the two runs would draw the opposite conclusion, so it is said
here and in the file itself.

`_fit_report.json` was re-run on the new body: **ratio 0.86 unchanged**,
`fits_frame true`, `margin_x 0.12`, `creature_h 2.10`, ok true, errors [],
blind_views []. The seams are inside the silhouette, so the number the game
build lane is copying this hour did not move.
