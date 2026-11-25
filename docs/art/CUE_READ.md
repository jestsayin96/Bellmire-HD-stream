# THE CUE READ CENSUS - can the party see what the fight is about?

ART LANE, 25 Nov 2026, 04:3x-05:0x CT.

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
