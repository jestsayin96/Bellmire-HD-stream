# THE GAOLER'S DRAG-CHAIN - 20 Nov 2026, art lane

**The item**, written by the team lead at 02:58 CT: *"Shacklemaw's drag-chain.
You found it yourself on the contact sheet - it lies flat on the ground plane
and reads as a thin ring from 3/4, so 'it drags' is not carried by the
geometry."* Shacklemaw is `gaoler` / `gaoler_chibi` in `tools/art/minibosses.py`.
Nothing in this tree is named shacklemaw; it is the CANON title, not the key.

## The fault, confirmed before anything was changed

The chain was `L.helix(2.6, 0.055, 0.14, 0.92, 0.26)` - 2.6 turns rising
**0.085 m** across a **0.92 m** radius. At the 3/4 camera's 14 degrees of
elevation a disc lying on the floor cannot project taller than about
`sin(14) = 0.24` of its width, however wide it is. Measured: **0.26**. The
geometry and the picture agreed, and both said HOOP AT REST. The creature's one
idea is IT DRAGS.

## The change, and it is one thing

The helix is **stood up**: 3.5 turns, radius 0.62 -> 0.30, rising 0.06 -> 0.50.
Chain hauled in and dropped does not lie out flat, it HEAPS, and the working
end comes off the top - which is the plainness rule doing the work rather than
a style choice. The run to the hand now starts at `_dragheap`'s **returned free
end**, not at a literal, so re-shaping the heap can never leave the chain in two
pieces. The pass-1 shape is kept runnable as `DRAG_HEAP_FLAT`: an arm nobody
can re-run is not evidence.

## The instrument, and the two versions of it that were WRONG

`tools/art/_gaoler_chain_ab.py`. ONE camera, built once off the whole body's
bounds, then the same frame shot with the chain group's objects hidden from
render; the pixels that MOVED are the chain's visible contribution, occlusion
included, because the renderer did the depth. `mask_of` would have answered how
BIG the chain is and never whether it can be SEEN - the pass-11 lesson.

The run's "does it read as chain or as a bar" metric took **three tries**, and
each wrong one was caught by its own number, not by a picture:

1. perpendicular EXTENT per PCA bin -> cv **0.51 for a plain tube**. Impossible
   for a constant-width band: it was measuring the body OCCLUDING the run and
   the far end FORESHORTENING.
2. pixel COUNT per bin, longest gap-free stretch, detrended -> still cv 0.37.
   It was measuring the run's own BENDS: where a bent line leans away from a
   straight axis, the bin under it collects more pixels.
3. the version that stands: the run's OWN polyline, projected through the same
   camera, walked at a fixed step, thickness measured PERPENDICULAR TO THE
   LOCAL TANGENT. Samples whose centre is outside the mask are dropped;
   samples where the mask runs on past the reach (the line crossing itself) are
   COUNTED AND DROPPED, and a profile that is more than a quarter crossings is
   refused outright.

Red on empty throughout: under 200 moved px, a zero-width box or under 14
surviving samples reports RED and the row carries **no numbers**.

## The numbers, 3/4 view

| | flat (pass 1) | heap |
|---|---|---|
| `gaoler_chibi` heap aspect h/w | 0.262 | **0.615** |
| `gaoler` heap aspect h/w | 0.257 | **0.497** |
| heap height / body height (metres, geometry) | 0.084 | **0.244 / 0.253** |
| moved px kept | - | 0.92 / 1.05 |
| footprint span (m) | 3.78 / 3.79 | **3.57 / 3.57** |

Bar, written before any number was read: aspect >= 0.45, height fraction
>= 0.20, px kept >= 0.60. **PASS on both bodies.** The span SHRANK, so the
corridor margin improved; both stay CORRIDOR-SAFE and UNDER-LID at 47/47.

## What did NOT ship, and why

Links called out along the run (`RUN_LINKS`), to stop the line reading as a
rigid bar. Built, rendered, measured in the same run. One term moved hard in
their favour - the width profile's local maxima went **4 -> 9** on the visible
stretch - and the bar's third clause, "cv must beat the plain tube by 1.4x",
turned out to be **the wrong term**: cv is dominated by the line's own
foreshortening, so a plain tube already reads 0.30 there. **The bar is not
moved in the run that wrote it.** `RUN_LINKS["on"]` is False, the arm stays
runnable, and the next pass can write a bumps-only bar BEFORE it looks.

## A fault this change introduced, found by the instrument and fixed

With the heap standing up, the full-size `gaoler`'s old `arc()` run passed
BEHIND the apron: 3/4 visible run pixels fell **4757 -> 999**, a 79% loss of the
one line that joins the heap to the hook. Re-routed out past the left leg and
across in FRONT of the apron, the way the chibi's already was - the Stoker's
fault 9 in general form. Recovered to **17640**.

## What the register still cannot see

- The run reads as a **straight rigid bar** on both bodies. That is the open
  item above, and no number here says otherwise.
- On the full `gaoler` the chain's end and the hook meet near the wrist but the
  join is not clean: it reads as "a pole and a hook", not "chain -> hook".
- The heap's turns are **evenly stacked**, so it reads as a coil rather than as
  a dropped heap. True of chain that has been coiled; still worth saying.
- `minibossgen` now also asserts **border alpha** on every rendered frame. A
  blank check cannot see a CLIPPED one. It fired on nothing: 0 border pixels
  across the set.

---

# PASS 2 - THE RUN-LINKS ARM, 20 Nov 2026, 05:3x-05:5x CT

The team lead's 04:58 row: *"the run-links arm you deliberately did not re-run.
You wrote that its bar 'is not moved in a run that failed it' - correct
discipline, and the run has now PASSED, so the bar is free. That arm is owed."*

## The bar, rewritten before a frame was rendered - and what I had already seen

`cv` is **struck from the bar** and is now a reported number only. Pass 1 proved
it is the wrong term: it is dominated by the line's own foreshortening, so a
plain tube already reads 0.30 and a "beat it by 1.4x" clause is unearnable.

The bumps-only bar, on the 3/4 view:

1. `bumps_links / expected_links >= 0.50` - at least half the links lying on the
   measured stretch must show as a bulge. `expected_links` is that stretch's own
   arc length over 0.17 m, so a short visible run cannot pass by being short.
2. `density_links >= 1.8 x density_plain`, density = bumps / samples, both arms
   sampled at the same step - the modulation must be the LINKS' and not the
   line's own bends.

**It is not a blind bar and I will not call it one.** Pass 1's shipped numbers
(bumps 4 -> 9 and 6 -> 7, cv ~0.30 for a plain tube) were in front of me when I
wrote it. It is a bar written to ask the right question, and it was written so
that a row could fail it. One did.

## MY OWN SAMPLING DIAGNOSIS WAS WRONG AND THE FIRST RUN SAID SO

I wrote into the header that the profile's fixed 6.0 px step was **under three
samples per link** - Nyquist - and that `bumps` had been aliasing. The run
measured **px_per_m 161.3 / 162.3** and a link period of **27.4 / 27.6 px**:
the old step was **4.6 samples per link**, comfortably above Nyquist. My
90-100 px/m was an eyeball off the run's bounding box, not a measurement. The
step is still DERIVED from the projected period (period/4 = 6.85 px, barely a
move) because a step that is adequate by luck is not an instrument - but the
sampling was **not** the fault and that sentence does not get to stand.

## THE FAULT THE FIRST RUN DID FIND, IN MY OWN NUMBERS

`gaoler` b_heap read **cv 0.0412** - a dead-flat width profile, which is exactly
what a plain tube is - and the same profile scored **7 bumps**, out-scoring the
links arm's 4. A local maximum with no amplitude floor counts pixel
quantisation. The whole run-links question rests on that term, so a bump must
now clear an amplitude floor (`6%` of mean width) **and** be the maximum within
half a link period. `gaoler` plain fell **7 -> 1**. A flat tube now reads flat.

## THE CONTINUITY GATE - THE TEAM LEAD'S PICTURE, AS A NUMBER

He found by LOOKING that "from 3/4 the run from heap to hand is crossed and is
not legible as a continuous line", and **every number in pass 1's register
passed that picture.** The reason was in `_profile`: a sample whose centre fell
outside the run mask was `continue`d - silently skipped, never counted - so an
occluder eating the middle of the run cost the harness nothing.

Counted now. `longest_visible_frac` = longest unbroken visible stretch over
in-frame samples; **BAR >= 0.60**, reported beside the links and gating nothing
of theirs.

| 3/4, plain run | gaoler_chibi | gaoler |
|---|---|---|
| longest_visible_frac | **0.459** | **0.5735** |
| verdict | FAIL | FAIL |

**BOTH BODIES FAIL IT.** On `gaoler` the break splits the run 39 / 18 samples,
and I can see where in the picture: the run passes **behind the near leg**. Pass
1 re-routed it in FRONT of the apron and recovered 999 -> 17640 run pixels; that
was real and it was not enough. The occluder that remains is the leg.

## ONE GEOMETRY TERM MOVED, AND THE MECHANISM WAS ARITHMETIC FIRST

A link's flat axis alternates by a quarter turn - that turn is the whole read -
so every other link presents `rz` to the camera. `rz` was **0.028 m against a
run tube of radius 0.052 m**: the edge-on link sat ENTIRELY INSIDE THE TUBE and
could not bulge at all. At most half the links could ever register, and the
instrument measured exactly that - 0.3478 and 0.4103 against a bar of 0.50.
`rz` 0.028 -> **0.068**: above the tube so the edge-on link still shows, still
well under `rx` 0.080 so it reads as a flattened ring and not a bead.

| 3/4, links arm | gaoler_chibi | gaoler |
|---|---|---|
| bump_frac_of_expected, rz 0.028 | 0.3478 | 0.4103 |
| bump_frac_of_expected, rz 0.068 | **0.4571** | **0.7273** |
| density vs plain, rz 0.068 | **1.60x** | **7.10x** |
| verdict | **FAIL** | **PASS** |

## THE CALL: `RUN_LINKS["on"]` STAYS FALSE

The set is split. One body clearing a bar is not the set clearing it, and the
bar does not move in the run that wrote it - that is the second hour this term
has been asked and the answer is the answer. The `rz` move is kept, because it
is the arm's geometry and it is measured in both directions.

**I looked at all three frames.** The plain run is unmistakably a smooth dark
POLE. With links at rz 0.068 both bodies read as chain - the full `gaoler`
obviously so. The number and the picture agree, which is why the FAIL is a
scoring fail and not a disagreement.

## What this register still cannot see

- **Nothing here names the occluder.** `longest_visible_frac` says the run is
  broken and by how much; that it is the near LEG is something I read off the
  picture, not off a number. An occluder-attribution arm would be an honest
  next instrument.
- The chibi's run crosses its own heap AND its keyring, so part of its link
  stretch is measured where the chain overlaps itself. That is where its missing
  bulges are likely to be, and it is a testable hypothesis, not a reason to move
  the bar.
- The small pale keyring hangs **in the middle of the chain run** on both
  bodies and reads as a link of it rather than as keys.
- The heap is dark-on-dark against the hood and the apron on both bodies; its
  silhouette carries it, its contrast does not.
