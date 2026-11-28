# THE TIER-LADDER SHEET GATE

Written 28 Nov 2026 07:5x CT by the 07:34 ART firing, with the Blender bridge
down for a seventh consecutive hour. No render was possible this run; every
number below is replayed from sheets already on disk.

## WHAT WAS WRONG

A tier ladder's acceptance test is the SIDE-BY-SIDE sheet - "a tier variant is
not done until the three tiers are rendered SIDE BY SIDE and the progression
reads at a glance." The well ladder's generator spends **three extra renders
per tier** measuring each tier's silhouette into `sil`, writes it into
`_report.json`, and then **never reads it in a single error branch**. Every
check looked at the whole sheet (blank / subject-moved / border / labels), and
none at the subjects' size.

On 28 Nov the well generator ran three times while the file was being edited:

| run | time | min tier h / sheet h | verdict |
|---|---|---|---|
| `_townbuild_gen.log`  | 06:46 | **0.112** | GREEN |
| `_townbuild_gen2.log` | 06:49 | 0.354 | GREEN |
| `_townbuild_gen3.log` | 06:50 | 0.350 | GREEN |

The 06:46 draft framed the sheet about three times too far away - every tier
roughly **one ninth** the area of the fixed version, with the labels unchanged
at full size - and the gate could not tell it from the fixed one. The author
fixed it **by eye**. `townlib.py`'s own header had already named the hole,
"BORDER - cannot see a subject that is merely small", and nothing closed it.

Note the 06:46 sheet was internally CONSISTENT (50.1 / 47.6 / 51.8 px per
metre): nothing was misplaced, the whole camera was simply too far back. A
consistency check alone would not have caught it.

## THE FLOOR IS DERIVED, AND px/m WOULD HAVE BEEN WRONG

The first instinct was a pixels-per-metre floor off the well's 150-164 px/m.
**That would have RED-flagged the shipped, GREEN, good-looking HALL ladder**,
which runs at 25.8-31.2 px/m purely because a 19.8 m hall needs more world in
the same frame. A px/m floor is a statement about building size, not about
readability. The size-independent measure is the smallest tier's height as a
fraction of sheet height:

    known-bad  well 06:46 draft : 0.112   (0.113 / 0.151 / 0.112)   RY 760
    known-good hall, tightest   : 0.217   (0.217 / 0.418 / 0.743)   RY 820
    known-good well 06:50       : 0.350   (0.350 / 0.478 / 0.354)   RY 760

Floor = geometric midpoint of the two nearest neighbours,
`sqrt(0.112 * 0.217) = 0.156` -> **0.16**: 1.43x above the bad sheet, 1.36x
below the tightest good one. Centred in log space rather than tuned to either.

An earlier draft of this page and of the docstring read the hall at RY 760 and
quoted 0.234. **That was wrong** - the hall sheet is 820 px tall - and the
margin above the floor is thinner than it claimed. Corrected in the same run.

## GROWTH IS DECLARED, NOT ASSUMED

`hallgen.py` asserted `hs[0] < hs[1] < hs[2]`. That is correct **for the hall**
(178 < 343 < 609) and wrong as a general ladder rule. Run it on the well and it
fires on the **GOOD** sheet, because the tier-3 Fountain (1.64 m) is
legitimately SHORTER than the tier-2 roofed Well Kept (2.415 m). A fountain is
not taller than a well-house; that ladder progresses by RICHNESS, not height.

So the caller declares the shape:

  - `growth="monotonic"` - each tier taller and larger than the last (hall)
  - `growth="free"` - progression by richness (well); distinctness only

## THE GATE

`townlib.ladder_gate(sil, order, heights_m, resy, growth=...)`, used by both
`townbuildgen.py` (well, `free`) and `hallgen.py` (hall, `monotonic`).

1. **RED ON EMPTY** - a tier missing from `sil`, or with `px`/`h_px` of zero.
   This is the answer to "what does a PASS look like if the subject is absent?"
   Before it, a tier that failed to render simply vanished from the dict and
   every surviving number read fine.
2. **SCALE FLOOR** - smallest tier >= 0.16 of sheet height.
3. **ONE SCALE** - px/m spread across tiers within 1.6x. Deliberately loose:
   the camera is perspective, not ortho, so tiers at different depths
   foreshorten differently and the hall spreads 1.21x legitimately.
4. **DISTINCTNESS** - no two tiers within 3% in silhouette area, which catches
   the copy-paste bug of two tiers sharing a mesh.
5. **DECLARED GROWTH** - as above.

## WHAT THIS GATE CANNOT SEE - said before the numbers

  - **Whether the WEAR reads.** This is a size and separation check. A tier-1
    rendered large and clean passes every number here and still fails the spec,
    which is that tier 1 is patched and make-do. Wear is the whole point of the
    town ladder and no number here measures it.
  - Whether the three read in the right ORDER, or as one town at all.
  - Colour, value or material separation between tiers.
  - Overlap between neighbouring tiers - the sheets prevent that by
    construction in the span layout, not by a gate.
  - Anything about the hero scale figure; that is a separate gate.

**A pass here is not a done ladder.** The sheet still has to be looked at.

## PROOF

`tools/art/_laddergate_validate.py` - runs with no Blender and no bridge. It
lifts the REAL shipped `ladder_gate` out of `townlib.py` by AST (townlib
imports bpy and cannot be imported outside Blender), so it validates the code
that ships rather than a copy. 11 cases, all passing:

  - the three real well sheets: 06:46 **RED** (was GREEN), 06:49 and 06:50 GREEN
  - the real hall sheet: GREEN, and GREEN under BOTH candidate readings of the
    `dims_m` height axis, so the conclusion does not rest on that ambiguity
  - seven synthetic negative controls, every one RED: tier absent, tier blank,
    all tiers identical, one tier at half scale, empty `sil`, zero sheet
    height, and the well declared `monotonic` (which demonstrates the hall rule
    firing on the good well sheet)
