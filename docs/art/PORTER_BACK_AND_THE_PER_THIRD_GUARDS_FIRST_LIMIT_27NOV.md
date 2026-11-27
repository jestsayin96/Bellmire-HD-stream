# THE PORTER WAS A BLANK DOOR FROM BEHIND, AND MY NEW GUARD FAILED ON ITS
# FIRST TWO BODIES

27 Nov 2026, 15:34-16:2x CT. Art lane, W5.

The 14:58 block told me: run my own per-third guard on `changer`; if its thirds
are flat it is dilution like `stopper`, say so and move to `dyer` 0.2654. I did
exactly that. **Both bodies came back clear, the guard turned out not to say
what I built it to say, and the body that actually needed the work was named by
a census this lane committed days ago and had not re-read.**

## 1. THE GUARD IS NOW IN THE INSTRUMENT, NOT IN A SCRATCH SCRIPT

Last hour's per-third breakdown was ad-hoc and died with the run. It is now
`in_diff_thirds` / `thirds_spread` inside `tools/art/_facingread.py`, computed
over the BODY's own vertical extent (not the frame's, or a body that does not
fill the frame reads dead where there is simply nothing), with RED ON EMPTY on
each band. It reproduces last hour's numbers to the fourth decimal:

| body | top | mid | bot | spread | whole |
|---|---|---|---|---|---|
| stopper | 0.1873 | 0.2011 | 0.1101 | 0.091 | 0.1794 |
| bellman (after the bib) | 0.4925 | 0.4481 | 0.4703 | 0.0444 | 0.4703 |
| **changer** | **0.3063** | **0.1683** | **0.1951** | **0.138** | 0.2046 |
| **dyer** | **0.1649** | **0.2061** | **0.5097** | **0.3448** | 0.2654 |

## 2. CHANGER IS NOT BROKEN - GUARD AND PICTURE AGREE

spread 0.138, nearer stopper's 0.091 than the broken bellman's pre-fix 0.449.
**And I looked, because a flat spread is not a verdict.** Front: two eyes, the
pale token on the chest, the hat brim. Mirrored back: no eyes, no token, a
plain coat. The diff mask lights up the hat, the eyes, the token and the
reaching arm. **The facing is real and present.** The low whole-body score is
the post and the drum, which are the same picture from both sides by
construction and are most of the pixels. Dilution, as the lead predicted.
NOTHING WAS CHANGED ON THIS BODY. Picture:
`renders/art/minibosses/_facingread/_look_changer_dyer_thirds_27nov.png`.

## 3. DYER IS ALSO NOT BROKEN - AND THAT IS WHERE MY GUARD BREAKS

By the rule I wrote, dyer's spread of 0.3448 is NOT flat, so the guard says
"real fault, and it is in the top third (0.1649)". **The guard is wrong and the
picture says so.** The dyer's top third is the tenter frame's crossbar and the
upper halves of three hanging sheets - a large prop that is near enough the
same picture from both sides. The low top third is the SAME dilution as
stopper's, just concentrated in one band instead of spread over three.

**THE LIMIT, SAID OUT LOUD BEFORE IT SHIPS A VERDICT: `thirds_spread`
SEPARATES A UNIFORM PROP FROM A BANDED ONE. IT DOES NOT SEPARATE A BANDED PROP
FROM A DEAD REGION, AND THOSE TWO LOOK IDENTICAL IN THE NUMBERS.** I wrote this
guard last hour, the lead asked me to apply it, and it failed on the second
body it ever met. It is still worth having - it told the truth about changer -
but it is a SPLITTER, not a gate, and the docstring now says so. This is the
pass-11 family again: an instrument that cannot see the difference it claims.

## 4. THE BODY THAT ACTUALLY NEEDED WORK WAS ALREADY NAMED, IN A FILE WE HAVE

Before changing a dyer that measured fine, I asked what 0.5949 (dyer's
`man_seen` on the back view) is worth against the house, and the answer was
already on disk: `renders/art/minibosses/_backread/_selfseen_all.json`,
**66 bodies, 198 cells**.

    median 0.9325   mean 0.8799
    worst:  porter back 0.1758 | fuller side 0.4611 | drillmaster back 0.4668
            beadle side 0.5174 | blower back 0.5228 | sexton back 0.5463
            ...  dyer back 0.5949 is RANK 11.

**`porter` back 0.1758 is not the tail of a distribution, it is an outlier
standing on its own**: 0.29 clear of the second-worst cell in the house, with
82% of the figure hidden by its own load.

## 5. WHAT THE PICTURE SHOWED, AND IT IS WORSE THAN THE NUMBER

`renders/art/minibosses/_backread/porter_s118_back.png`: **from behind the
porter is a flat tan slab.** Not a poorly-read creature - no creature at all.
A featureless rectangle with two boots under it. The numbers say the same thing
without being asked: p50 **0.5304**, p95 **0.5467**, so nearly half the picture
sits inside a value band **0.016 wide**, and one eighth-band holds **71%** of
every pixel in the view.

**AND IT IS WORSE THAN AN UGLY VIEW, BECAUSE OF WHAT IT IS A PICTURE OF.** This
dungeon has doors in it. A miniboss whose back view is an unmarked door leaf
standing in a corridor is not merely flat, it is CAMOUFLAGED AS SCENERY.

## 6. THE CAUSE, MEASURED: EVERY PIECE OF IRON WAS ON THE FACE NOBODY SEES

The leaf board spans y 0.33..0.47 (front is model -Y, so +Y is behind him).
Every band, boss, hinge strap and pull ring was placed at `LY - 0.0xx` - the
INNER face, turned toward the man's own back. From the back camera the nearest
surface in the entire picture is a bare 0.84 x 2.12 plank, and all the
ironwork is behind it. A hung door is banded on the face that SHOWS; that is
what bands are for.

## 7. THE CHANGE - ONE THING, AND IT COSTS NO WIDTH

The iron goes on BOTH faces. No new material and no new mesh - every piece is
already the `dark` slot, so the four-mesh cap is untouched.

| | before | after |
|---|---|---|
| back view, fullest eighth-band | **0.710** | **0.374** |
| second populated band | 0.073 | **0.353** |
| p50 -> p95 span | **0.0163** | **0.1312** (8x) |
| x bounds | -1.7621 .. 1.7621 | **identical** |
| z bounds | 0.0 .. 2.3 | **identical** |
| y bounds | -1.11307 .. 0.57505 | -1.11307 .. 0.61818 (+0.043 depth) |

**The width that corridor-safety turns on did not move at all.** The 0.043 is
the outer bosses standing proud, in depth only.

## 8. A GAIN I MEASURED, CANNOT EXPLAIN, AND THEREFORE DO NOT CLAIM

**I wrote in the builder comment, BEFORE rendering, that `man_seen` would not
move** - it asks how much of the MAN is visible and iron on a leaf is gear.
**It moved: back 0.1758 -> 0.2347, man_seen_px 7074 -> 9458, +34%.**

It is not reframing: `man_alone_px` went 40233 -> 40295, a 0.15% camera change
cannot produce a 34% one. So something real happened and **I do not know what
it is.** I can see a pale angular shape high on the leaf in the after-render
that is not in the before-render, and I am not willing to name it from a
thumbnail. **A gain I cannot account for is not a gain I will bank.** The
claimed result of this pass is the value-band break-up in section 7. The
`man_seen` move is CARRIED AS AN OPEN QUESTION for the next run, to be answered
by rendering the B/X/Mo triple and locating the new pixels, not by argument.

## 9. WHAT IS STILL WRONG WITH THIS BODY

1. **THE MAN IS STILL MOSTLY HIDDEN FROM BEHIND.** 0.2347 is still the worst
   cell in the house by a wide margin. The leaf's top is at z 2.30, half a
   metre ABOVE his helm, and 0.84 wide against shoulders about 1.03 across, so
   head and torso are gone and only shoulder slivers and boots show. **Nothing
   is carried like that** - a slung leaf's top sits near the carrier's head.
   Not fixed this run: lowering, shortening or yawing the leaf all change a
   SHIPPED, WIRED body's silhouette and footprint, and that is a decision
   with a cost, not a tweak.
2. **IT STILL READS AS A DOOR FROM BEHIND, JUST A BETTER-MADE ONE.** The iron
   makes it legible; it does not make it a creature. See the question below.
3. The pull-ring bar is now doubled and the outer one has nothing to pull
   against - truthful on a door, slightly redundant here.
4. The bands protrude 0.03 past the leaf's edge on each side; harmless, but
   it is a 0.90 band on an 0.84 board and that was true before this pass too.

## FOR MR. E - AND IT IS A PICTURE, NOT A QUESTION ABOUT WORK

Compare `porter_s118_back.png` (before) with `porter_p3_iron_27nov_back.png`
(after). The slab is fixed. **The thing I cannot fix without changing a body
that is already in the game is that your porter, seen from behind, is a door -
in a dungeon that has doors in it.** That may be exactly what you want: it bars
the way, and a door that turns out to be alive is a good scare once. It is also
a thing a party can walk past. Say which and I will either leave it or drop the
leaf to head height and re-gate the footprint.

## THE FIT PROOF - ON THE KAYKIT KNIGHT, IDLE POSE, AND I LOOKED

`minibossgen.py --only porter`: `ok true`, errors [], blank [], through_lid [],
room_locked [], porter span **3.52 CORRIDOR-SAFE UNDER-LID, 4 meshes, 1520
faces** against corridor_clear 11.0 and lid 9.5. The four-mesh cap holds.

`minibossfit.py --only porter --evenlight --ground`: **verdict GREEN**, errors
[], blind_views [], unproved_cells [], **blank check 210 files / 0 failures**
over 70 cells, 0 frame clips, porter ratio 0.94. Nothing in the house went red.

Contact sheet: `renders/art/minibosses/porter/_look_porter_p3_onbody_27nov.png`
- front, side, back, porter beside the knight in the idle pose. I looked at it.

GOOD: the scale reads as a set piece - half a head over the knight and far
wider, not a giant. **From behind, the bands, bosses and hinge straps all read
at body scale**, which is the whole point of the change; the flat slab is gone.
Hem and boots sit on the floor, no float, no clip into the knight.

FAULTS, AND THESE ARE REAL:
1. **THE BACK STILL HAS NO MAN IN IT.** At body scale all you see is a banded
   door, the drawbar, and two boots. Confirmed by eye, not just by 0.2347.
2. **IT IS NOW A WELL-MADE CRATE FROM BEHIND, NOT A WELL-MADE DOOR.** The
   bosses sit only at x +/-0.30, so they cluster toward the middle of each
   band and read as corner brackets on a box rather than studs on a leaf.
   Pushing them out toward the board edges would read more like a door; not
   changed this run because one thing at a time.
3. **THE SIDE VIEW READS AS ABOUT TO TIP BACKWARD.** The leaf's 0.10 rad rake
   puts its top edge behind his heels with nothing under it, and the man
   leans forward against it. A carried leaf needs the weight over the feet.
   Pre-existing, not introduced here, and visible now that the leaf has
   detail on it to follow.
4. **THE DRAWBAR CROSSES THE KNIGHT'S SILHOUETTE** in the front view - the
   near iron shoe passes over his helm. Depth-clear, not a clip, but at pane
   distance it is a bar drawn across a hero's head, which is the exact misread
   Mr. E deleted the changer's bars over on 21 Nov.
5. A pale sliver of the board's top face shows above the uppermost band in the
   back view. Small, and it is also where the unexplained `man_seen` pixels
   of section 8 appear to be - I am naming the coincidence rather than
   resolving it.
