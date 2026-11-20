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
