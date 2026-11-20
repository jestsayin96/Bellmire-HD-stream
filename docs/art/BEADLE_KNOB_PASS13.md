# The Beadle's side knob: the number was the instrument, and the complaint was still right

18 Nov 2026, ~11:0x CT. Art lane. Answering the team lead's 09:5x question:
"the side global gap moved 0.2065 -> 0.2669 but THE WORST LOCAL GAP DID NOT MOVE
AT ALL (0.1225 -> 0.1217). To my eye the knob now reads clean in the side
render. YOUR CALL whether that is the instrument or the knob."

**It is the instrument. And the eye behind the original complaint was still
right, for a different reason than the number gave.**

## 1. The old core mask was 86% not the knob

Pass 11's lesson was a window I had TYPED from a guess. Pass 12 derived the
window from the A/B's moved mask and I stopped there - inside that window the
CORE was still typed by hue, `sat > 0.10 and warm > 0.06`. On the side view the
warm back rim pushes the dark blue-grey wool straight past both thresholds.

Measured on the shipped renders: of 9,657 side "core" pixels, **1,335 (13.8%)
are pixels the knob edit touched**. The other 8,322 are warm-lit robe and wall,
and they are exactly as warm as the knob (warm mean 0.206 vs 0.203), so no
tightening of that threshold separates them. `core_lum_mean` on the side was a
measurement of the ROBE.

On the FRONT the same mask happens to land on the knob alone. That is the whole
explanation for the asymmetry the team lead spotted: front 0.0431 -> 0.3631,
side 0.1225 -> 0.1217. The side number was never about the knob.

`renders/art/minibosses/_ab_beadle/_knobmask_p13.png`, column 4 of the first
sheet, shows the old core flooding the entire right-hand wall panel. I found it
by looking at the mask, not by reading a number.

## 2. Two further faults in `worst_local_gap = abs(core_mean - ring_max)`

- **`abs()` discards the sign.** "The knob is darker than its ground" and "the
  ground is darker than the knob" report the same figure. On the side the
  ground is BRIGHTER than the core; on the front it is darker. An outline's
  whole job is to flip that sign, and the metric could not see a flip.
- **`ring_max` is an extremum over ~900 px.** One surviving bright pixel pins
  it. It never said "the worst spot is untouched"; it said "at least one bright
  pixel remains", which was true before and after.

## 3. With a derived core, the side fix is decisive

`tools/art/_beadle_knobgap.py` now splits the moved mask into connected
components, keeps the ones the edit ACTED on (by luminance **or** by alpha),
and reads them against ground taken from UNMOVED pixels only, so the ground is
identical in both images and the delta is attributable.

| view  | signed gap base -> knob | ground indistinguishable from knob |
|-------|-------------------------|------------------------------------|
| side  | +0.0255 -> **-0.3112**  | **85.4% -> 6.5%**                  |
| front | -0.2629 -> -0.3391      | 0.0% -> 0.0%                       |
| back  | -0.2728 -> -0.3654      | 0.0% -> **14.1%**                  |

The side went from "85% of the knob's boundary cannot be told from what it sits
against" to 6.5%, and the sign flipped. Swept over ACTED in 0.10-0.30 the side
numbers are **identical at every threshold** - the verdict does not rest on a
threshold I picked.

## 4. Two things the numbers could not have told me

**(a) 43% of the side's "moved" pixels are not the knob.** An 886 px patch of
robe ~50 px to the right darkened slightly (0.585 -> 0.525) when the knob went
dark - the knob's cast response on the surface beside it. Folding that into
"the knob" drags the knob's mean up with bright wall. So the moved mask alone
is not the knob either. Components are now split and the non-knob ones are
reported as `collateral` by name rather than averaged in silently.

**(b) My own first pass-13 draft misclassified the front and back upper
collar.** It tested luminance alone, and that collar - alpha 0.13 -> 0.86, new
geometry, plainly part of the piece - fell out as "collateral" on a dlum of
+0.14. I caught it by LOOKING at the mask overlay, where the collar was painted
collateral-yellow in a picture in which it is obviously the knob. That was also
exactly why the front and back magnitudes were unstable under the threshold
sweep while the side was not. The acted test now reads luminance OR alpha.

## 5. The residual - and this is where the original complaint was right

The collars now carry the read. **The knob's pale BULB between them does not.**
It did not move in the A/B, so no A/B-derived instrument was looking at it, and
on the side view it is the bulb, not the collars, that sits against pale wall:

    side: bulb 2,414 px lum 0.6712 | ground 338 px lum 0.6122
          signed gap +0.0590 | indistinguishable 1.0000

**100% of the bulb's ground is within 0.10 of the bulb.** On the front and back
the bulb has no eligible ground at all - it is wholly enclosed by the collars
and the cloak - and the tool returns that reason rather than a pass.

So: the knob reads on the side *by its two dark bands*, not by its silhouette.
That is a banding fix, not an outline. Whether that is good enough is an art
call, not a measurement one, and I am not making it silently - it is the open
item below.

## Open, named, not fixed this run

- **Side bulb has no edge.** Gap +0.059, 100% indistinguishable. A rim or a
  value step on the bulb itself would close it; the collars cannot.
- **Back view, small regression.** `indistinguishable` 0.0 -> 0.141 (25 of 177
  ground px). The knob darkened and the back's ground has dark patches, so part
  of that boundary now reads dark-on-dark. Consistent across every threshold in
  the sweep, so not noise, but the ground sample is small.

## The standing lesson, third time in this family

Pass 11: a window I typed. Pass 12: a window derived, a core typed. Pass 13: a
core derived, and the acted-test still wrong until I looked at a picture of it.
Each time the number was green and the picture was the evidence. The harness is
not finished when it stops going red; it is finished when the mask it is using
survives being looked at.
