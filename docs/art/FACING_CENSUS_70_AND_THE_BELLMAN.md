# THE FACING CENSUS: ALL 70 BODIES, AND THE BELLMAN'S EYES HAD NEVER BEEN SEEN

27 Nov 2026, 14:3x-15:0x CT. Art lane, W5. The team lead's 13:58 block asked for
a pass on **"the body whose own register carries the worst margin"**.

## FIRST FINDING: THE REGISTERS CARRY NO MARGIN. THE RANKING COULD NOT BE DONE.

I tried to do what was asked and could not, and the reason is worth more than
the pass would have been. Across every `_fit_*_register.json`:

- **`seen` is 1.000 on EVERY view of EVERY body.** Not "high" - saturated. There
  is no spread, so there is nothing to sort.
- the smallest `vis` anywhere is **14380 px against a `vis_min` of 700** - a 20x
  margin on the worst cell in the house.
- **zero** non-zero frame-edge values anywhere.

A register with no variance cannot nominate a worst body. This is the same
blindness the team lead found BY EYE on the Beadle, stated numerically: the
Beadle's register read `seen: 1.0` on all three views while the body had no
facing. **THE FIT REGISTER ANSWERS "IS IT THERE", NOT "DOES IT READ."** I did
not invent a new margin to make the row answerable; I went to an instrument that
already has spread.

## THE INSTRUMENT USED, AND IT ALREADY EXISTED

`tools/art/_facingread.py`, built 21 Nov for exactly this question: render front
and back through ONE camera, MIRROR THE BACK, and ask how much of the picture
changed. I did not rebuild it. Two earlier candidate arms were already built and
thrown away on 21 Nov (`FACING_TWO_INSTRUMENTS_THROWN_AWAY_21NOV.md`) and I did
not re-discover them: **`sil_iou` is not usable as a gate** - it was discarded
because a bar catching the Beadle (0.922) also catches the drillmaster (0.916),
who nobody charges. The live signal is the interior read `in_diff_frac`, and
that file deliberately sets NO pass mark. I have not set one either.

**Ran over all 70 bodies, 7 chunks, 140 renders, `errors: []`, zero RED cells.**
`renders/art/minibosses/_facingread/_facingread_census70.json`.

    in_diff_frac:  min 0.1794   median 0.4748   max 0.6812
    worst five:    stopper 0.1794, bellman 0.1832, changer 0.2046,
                   dyer 0.2654, stiltman 0.2672
    THE BEADLE - the body failed by eye - sits at 0.3233, **RANK 10 OF 70**.
    NINE BODIES READ WORSE THAN THE BODY WE ALREADY AGREED WAS BROKEN.

## SECOND FINDING: THE INSTRUMENT'S OWN #1 WAS WRONG, AND THE PICTURE SAID SO

`stopper` scored worst. **It is not the worst and it is not broken.** I looked:
its figure has a clear pale face mask with two eyes on the front and a plain
dark drum behind - it HAS a facing. Its score is low because the enormous
symmetric hexagonal vat rim is most of its pixels and **dilutes the fraction**.

**A BLINDNESS IN `_facingread.py`, NOW SAID OUT LOUD: `in_diff_frac` IS DILUTED
BY A LARGE SYMMETRIC PROP.** A body that is mostly gear will score as facing-less
however good its face is. The docstring already warns that a HIGH score on a
small intersection is suspect; this is the same fault in the other direction and
it was not written down. The cheap guard is the per-third breakdown below -
dilution is uniform across thirds, a real facing fault is not:

    stopper  top 0.186 / mid 0.202 / bot 0.110   <- flat: dilution
    bellman  top 0.482 / mid 0.119 / bot 0.033   <- the bottom 44% is DEAD

## THE REAL WORST: THE BELLMAN, AND ITS EYES HAD NEVER BEEN SEEN BY ANYONE

`_mb_partablate.py` (below) deleted the bellman's 96 eye polygons and re-rendered:

    BEFORE:  front 0 px moved   side 0 px moved   back 0 px moved

**ZERO. ON ALL THREE VIEWS.** The eyes are geometry that exists and cannot be
seen from any angle. The builder's own docstring promises *"a deep hood with
nothing in it but two lights"* and there were no lights. The cause, measured:
the dark hood sphere is centred y -0.12 with a y-radius 0.150, so its front face
is y -0.270; an eye of radius 0.024 centred at `fwd=-0.22` reaches only -0.244
and sat **entirely inside it**. This is the pass-11 fault of 17 Nov on a new
body: a part that is big enough to measure and impossible to see.

## THE FIX - THREE CHANGES, ONE AT A TIME, EVERY CORRECTION FROM THE PICTURE

| # | change | in_diff | what the render said |
|---|---|---|---|
| 0 | as shipped | 0.1832 | worst real facing of 70 |
| 1 | eyes `fwd` -0.22 -> -0.34 | 0.1865 | **A NULL MOVE.** Ablation proves the eyes now move 679 px front / 426 side / **0 back** - genuinely visible, correctly absent from behind - but two 0.024 eyes cannot carry a 2.70 m body. The eyes were never the cause. |
| 2 | oilcloth bib, 5 tilted plates | 0.4291 | Facing achieved - and the render showed **a chest of drawers**: each plate stepped inward 0.050 while being 0.050 deep, so every joint opened a ledge. The SCORE WAS ALREADY GOOD WITH THE FAULT IN IT. |
| 3 | 8 deeper overlapping plates | 0.4671 | Joints closed, but still read as **a staircase** - stepped side edges, visible banding. An oilcloth has no stairs down it. |
| 4 | **ONE quad-strip panel on the cone surface** | **0.4703** | Smooth taper, no steps, nothing to shimmer. Shipped. |

**0.1832 -> 0.4703: worst of 70 to just under the median.** `sil_iou` is
unchanged at 0.8337 and `front_px`/`back_px`/`inter_px` are identical to the
byte - the bib is laid on the cone's own surface and changes nothing in the
OUTLINE. The facing it buys is an interior read, and that is stated, not hidden.

Per-third after: top 0.493 / mid 0.418 / **bot 0.395** (was 0.033).

## THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE

Re-exported through the real driver (`minibossgen.py --only bellman`): `glb` ok,
4 meshes, 950 faces, height 2.70 unchanged, CORRIDOR-SAFE, UNDER-LID.
`minibossfit.py --only bellman --evenlight --ground`: **210 files, 0 blanks, 0
frame clips, 0 unproved cells, ratio 1.10.** Rendered on the KayKit knight in
the idle pose, front/side/back, and I looked at all three plus a 160-rung
thumbnail.

GOOD: scale reads as a set piece beside the knight, not a giant. The bib reads
as a dark panel at body scale AND at the 160 rung. **The back is bare pale
shroud - the facing holds on the body**, which is the exact view the Beadle
failed. Hem sits on the floor, no float, no clip.

FAULTS, AND THEY ARE REAL:
1. **THE SIDE VIEW IS WEAK AND IT IS NOT MY CHANGE - IT IS PRE-EXISTING.** From
   the side the bellman collapses to a plain cone and a bare vertical mast. The
   builder's own claim is *"the ASYMMETRY IS THE LIE and so it is the whole
   silhouette"*; from the side that asymmetry is almost gone, because both arms
   point along the view axis. The third bell's pole reads as a mast with nothing
   on it.
2. **THE SIDE VIEW HAS NO FACING CUE AT ALL.** The bib is on the front face, so
   it is invisible side-on. Front and back are now tellable apart; side is not.
3. **THE EYES ARE VISIBLE BUT NOT LEGIBLE.** 679 px is proven, but at body scale
   they are a speck. The facing is carried by the bib, not by the face. I am not
   claiming the bellman has a readable face - it does not.
4. Small pale gap between the bib's bottom edge and the dark hem ring.

None of 1-4 is fixed this run. Changing one thing at a time is why the staircase
got caught, and I would rather carry four named faults than quietly bundle them.

## THE NEW INSTRUMENT, AND IT IS A GENERALISATION, NOT A FOURTH COPY

`tools/art/_mb_partablate.py` - `_ol_eyeablate.py` with the key, the mesh suffix
and the contamination guard as arguments. The method is unchanged and
un-weakened: never render the part alone (that answers how BIG, not whether
SEEN); render with and without through one camera and count pixels that MOVED.

It carries a fourth guard the overlooker's version did not need. **Materials are
MERGED, so `bellman_glow` is the eyes AND two bell clappers in one mesh** -
hiding it whole would have answered a question nobody asked. `--bbox` deletes
only the polygons inside a world-space box, and `--min-polys` REFUSES when the
box catches too few.

**BOTH GUARDS FIRED ON ME THIS RUN AND THAT IS THE ONLY REASON THE RESULT IS
TRUSTWORTHY.** My first bbox was computed from builder coordinates and caught 0
polygons - because `build_miniboss` scales the body by 1.0844, putting the eyes
at z 2.21 and not the 2.04 the builder says. The harness refused to score rather
than report a clean, meaningless `moved: 0` - which is byte-identical to the
real finding it later produced. **I would not have been able to tell those two
zeroes apart.** I re-measured the glow mesh's actual polygon centres and the
96-poly cluster at x~0, z~2.2 is the eye pair.

## WHAT IS AND IS NOT IN THIS COMMIT

The census wrote 140 front/back PNGs, **50 MB**. That is evidence, but it is not
worth 50 MB of repo, so only the cited frames ship: the census JSON (the result
for all 70), the look sheets I actually judged from, the bellman / stopper /
beadle frames named above, and the full bellman ablation pair. The other 64
bodies' frames are reproducible in ~55 s:

    blender -b -noaudio -P tools/art/_facingread.py -- --repo W5 --keys <list> --tag <t>
