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

## PASS 8 - THE ROW'S NAMED VARIABLE WAS THE WRONG ONE, AND THE PICTURE SAID SO BEFORE THE NUMBER DID

The 05:58 CT plan row: *"COLLIER PASS 8: THE EARTH LIP ... You named the
single change yourself - the seam RADIUS - so that the light comes from UNDER
a brow of earth instead of lying on it as a crescent. ONE VARIABLE, as in
pass 7."* The row is quoting **this file**, PASS 7's own closing sentence.

**I ran it exactly as written, and it failed on both instruments.** Then I
found what does work and ran that the same way. Both are below.

### ARM 1-3: THE SEAM RADIUS, SWEPT. ONE VARIABLE, BEARINGS AND SINKS FROZEN

`COLLIER_SEAMR` scales `rad` on all three seams and nothing else. Unset is
1.0 and the shipped path is byte-for-byte unchanged, the discipline
`MB_CUEOFF` keeps.

| arm | `COLLIER_SEAMR` | front | side | back |
|-----|------|-------|------|------|
| 7c shipped | 1.00 | 3902 | **427** | 2518 |
| 8a | 0.80 | 3870 | **329** | 2493 |
| 8b | 0.62 | 3854 | **254** | 2481 |
| 8c | 0.45 | 3829 | **196** | 2467 |

**Monotone down. Every arm pays side read and buys nothing.** And the number
is the lesser half of it: `collier_p8/radius_sweep_zoom.png` and
`radius_one_seam.png` are the four arms at 5x and 12x, and across all four
the seam is **the same flat orange lozenge on the same flat grey panel, only
smaller**. At 0.45 it is a dash. No arm has a lip in it anywhere.

**WHY IT COULD NOT HAVE WORKED, AND I COULD HAVE KNOWN BEFORE RENDERING.**
Computed off `_courses` before the first arm ran: the tube centreline is
pinned at `r0 - sink` sampled at `zs`, but each seam RISES 0.046 m across its
span while the flank it sits in NARROWS (dR/dz -0.43 to -0.57). Mid-span the
earth has receded out from under a tube that did not follow it, so the tube
stands **+0.034 m proud** of the flank there - a bead on a surface, which is
what a crescent is. Shrinking the tube shrinks the bead and keeps the convex
orange top edge against lit earth. **A crescent reads as a bead because of
what is ABOVE it, and there is no dark earth above these seams at any
radius.** I wrote "the radius is the next pass's single change" in this file
at pass 7 from the look of the thing; it went into the plan row from here,
the same way the struck back-is-blind sentence did. **Two files repeating one
unmeasured guess of mine is the same fault as three did last hour.**

### ARM 4: A BROW. ONE OBJECT, AND IT IS GEOMETRY, NOT A RADIUS

A thin earth ridge standing **proud** of the flank just above each seam,
following the same arc and wider at both ends, `body` not `glow`. It does the
two things a radius cannot: its underside faces down and is unlit, so there
is dark directly over the light; and it clips the top of the glow, so the
seam's upper boundary is a straight hard edge instead of a convex crown.

| arm | | front | side | back |
|-----|---|-------|------|------|
| 7c shipped | no brow | 3902 | 427 | 2518 |
| 8d | brow 0.030 | 3854 | **429** | 2525 |

**The cue is held, not paid for** - +2 on the side where the radius sweep
cost up to 231. The front's -48 is not a loss: it is the brow partly covering
the two mid-height rim nicks pass 7c knowingly allowed, **144 px of them down
to 70**, and those are the marks 7a was rejected for.

### ARM 5-6: THE BROW'S OWN RADIUS, SWEPT THE SAME WAY

| arm | `COLLIER_BROWR` | front | side | back |
|-----|------|-------|------|------|
| 8d | 0.030 | 3854 | 429 | 2525 |
| **8e SHIPPED** | **0.044** | **3830** | **413** | **2517** |
| 8f | 0.058 | 3808 | 339 | 2500 |

`collier_p8/brow_radius_arms.png`, four panels at 11x. 0.030 is a dark
hairline and reads as a drawn stroke, not earth. 0.058 has mass but eats the
top of the glow and **starts reading as a dark worm LYING on the earth -
this fault arriving upside down**, and costs 90 px for it. **0.044 is the
most lip for the least cue: 16 px.**

### THE COUNT MECHANIC, RE-COUNTED RATHER THAN ASSERTED

A brow is `body`, so it cannot be an ember - but "it cannot" is a sentence
this file has already been wrong with once. Warm-pixel blobs on the front,
shipped vs brow, measured: the vent row (y 392-405) carries **four blobs and
exactly four, at identical sizes and positions in both arms** (412/399/112/25
px at x 439/492/551/409). **Still four embers and only four, and no fifth at
the vent row's height.** The only front pixels that moved are the two
mid-height rim marks, which got smaller.

### THE SWITCH IS HONEST

`COLLIER_BROW=0` renders **byte-for-byte identical MD5s to the shipped 7c
body on all three hero views** - front `af73ed1b`, side `b4e2f426`, back
`1fccdbd6`. The brow is the only thing that moved.

### WHAT I CAN STILL SEE WRONG, HAVING LOOKED AT ALL THREE VIEWS

**THE BROW READS, AND IT READS AT INSPECTION DISTANCE MORE THAN AT STREAM
DISTANCE.** That is the honest answer to the row's question. At 11x there is
no argument: dark earth over light, the glow cut straight along its top. At
hero scale it is a 1-2 px dark line and the side is still the thinnest cue in
the ten-body sample. **It did not make this a good side view; it made the
side view's light sit in the earth instead of on it.**

1. The brow's left (low) end tapers to a hairline and leaves a small grey gap
   between lip and glow on the lowest seam, so that third still reads as a
   bead. The taper exponent, not the radius, is the lever.
2. The top seam (z 0.742) is still the weakest of the three, crowded by the
   crown shelf and the man's torso - unchanged from pass 7.
3. The brow runs slightly past the glow's right end toward the rim.
4. **NO THRESHOLD IS SET BY THIS PASS EITHER.** 413 is not "enough" and 196
   was not "too few"; the bar still waits for the sweep over all 62.

## A SUBSET RUN IS NOT A DIFFERENT HOUSE - THE RED NOBODY COULD ACT ON

25 Nov 2026, 07:5x CT. `_collier_p8ship.log` shipped
`"verdict": "RED", "ok": false` with the reason *"the census was taken over 64
register rows and is being read against 10 - it describes a different house.
Re-run tools/art/_selfseen_census.py"*, while the committed `_fit_report.json`
sat GREEN with `errors: []`. The 06:58 plan row told this lane to re-run the
census.

**I MEASURED BEFORE TOUCHING ANYTHING AND THE CENSUS WAS NOT STALE.**
`_selfseen_census.json` says `register_pairs: 64`, stamped
`2026-11-25T04:02:20-0600`; the committed register has 64 pairs. The two AGREE.
What disagreed was 64 against the rows a `--only` run happens to carry - 1, in
the run I reproduced it on. That is arithmetic about the RUN and says nothing
about the census. Re-running it would have changed nothing and the next subset
run would have cried RED again, so the row's instruction is followed in its
spirit and not its letter: the row itself said to follow the evidence.

**THE FIX, in `minibossfit.derive_self_seen()`.** The count was only ever a
PROXY for "does the census know about every row in front of me?", and that
question is already asked directly, per key, by the `uncensused` arm. So the
proxy keeps its teeth only where the direct arm cannot see - when the run's
rows are NOT a subset of what the census covers. When they ARE a strict subset
the mismatch is EXPECTED and the block says so in its own `census_count_scope`
string rather than raising an error. That is the same discipline this file
already applies to a `--slot` run, and for the same stated reason: a file on
disk saying RED is one read away from somebody chasing a fault that is not
there. This one cost exactly that.

**RED-PROVED, not merely silenced.** With `collier` struck from every list of a
COPY of the census, so the run's rows are genuinely not a subset, the arm fires
on both halves - `census_count_scope: "judged"`, `uncensused: ["collier"]`,
`verdict: RED`, `ok: false`. With the census restored, the same subset run is
`GREEN`, `errors: []`, and carries
`census_count_scope: "NOT A VERDICT: this run carries 1 of the census's 64 rows
and every one of them is censused - a subset run, not a different house"`.
The census file was restored byte-for-byte afterwards and re-checked at 64 rows
with `collier` present.

NO SHIPPED BODY WAS EVER RED FROM THIS. The committed register is unchanged -
64 pairs, `ok: true`, `verdict: GREEN`, `errors: []`, collier ratio 0.86.
