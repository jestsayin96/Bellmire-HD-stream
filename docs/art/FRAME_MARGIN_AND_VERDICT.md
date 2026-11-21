# THE RATCATCHER'S FRAME, AND THE VERDICT THAT LIED OVER IT

20 Nov 2026, 23:35-00:1x CT. Both faults are in work THIS LANE SHIPPED. Neither
is a new plan item; both are defects in my own register.

## 1. THE CLIP - AND IT IS BOTH EDGES, NOT ONE

The team lead's 22:58 row named `ratcatcher` front/back `frame_edge` 15 and
described the hero's fist sliced at `x=0`. That is true and it is not the whole
fault. Counted off the shipped PNGs before anything was touched:

    hero_front.png   left 17 rows (y 381-476)   right 3 rows (y 450-452)
    hero_back.png    left  3 rows               right 17 rows (y 352-448)
    content x 0 -> 759 in both

The register itself already carried `right: 3` beside the `left: 15`. **The
pair touches BOTH frame edges**: the hero's arm on one side and the rat-pole's
hook tip on the other. That matters, because a pair touching one edge can be
re-centred and a pair touching both cannot. Only a narrower pair saves it.

**CAUSE.** `fits_frame` compared pair width against `FRAME_W` with ZERO margin:

    fits_frame = (amx.x - amn.x) <= FRAME_W      # 5.59 <= 5.60 -> True

At 760 px / 5.60 m that "fit" is **0.7 of a pixel per side**. Antialiasing alone
eats it. `fits_frame` was not answering the question anyone reads it for.

**FIX, two parts, deliberately separate.**

  (a) `MARGIN_X = 0.12` m (~16 px across the pair). `fits_frame` now demands
      real air, so the NUMBER can see what the border count was catching
      behind its back.
  (b) The hero's HORIZONTAL offset is solved per cell instead of fixed at
      `GAP = 0.45`, so a wide creature gets its frame instead of a clip. Each
      row records `gap_x`, `air_x` and `margin_x`.

The DEPTH offset stays at `GAP`, untouched. That one is the occlusion margin
from the side view; tightening it to win pixels would buy a border at the price
of the two subjects hiding each other. `GAP_MIN = 0.20` is the floor - a cell
that still will not fit at the floor is a real red for a wider frame or a
narrower creature, not something to be squeezed away quietly.

Only two of the 46 rows were wider than `FRAME_W - MARGIN_X` = 5.48:
`ratcatcher` 5.59 and `boiler` 5.51. Both re-rendered `--evenlight --ground`,
one key per subprocess, exactly as instalment 5's adoption pass ran.

    ratcatcher   5.59 -> 5.47   gap_x 0.450 -> 0.326   air 0.13 m   all edges 0
    boiler       5.51 -> 5.47   gap_x 0.450 -> 0.406   air 0.13 m   all edges 0

### AND I BROKE IT ONCE ON THE WAY, LOUDLY

My first version of the solve called `place()` with an ABSOLUTE target on every
attempt. **`place()` is RELATIVE** - read its body, it does
`o.location.x + dx`. Four passes compounded and walked the hero clean out of
the frame: `pair_w` **10.80** on ratcatcher and **11.03** on boiler, every view
RED with "the hero renders EMPTY alone". It is recorded here because the new
row audit in part 2 caught it on the very first run, before anything was
committed. An instrument that goes red on its author is the only kind worth
having.

## 2. THE VERDICT THAT WAS WRITTEN BESIDE THE EVIDENCE AGAINST IT

`_fit_report.json` read `ok: true`, `verdict: "GREEN"`, `errors: []`,
`blind_views: []` at the same moment its own `pairs.ratcatcher.frame_edge`
carried the clip above. Both written by the same program, in the same file.

**MECHANISM.** `main()` starts a fresh `rep` with `ok True` and empty error
lists, then carries forward ONLY `pairs` and `hero` from the file on disk. The
verdict was then drawn INSIDE the render loop, which visits only the keys named
by `--only`. So a one-key run inherits forty-five other cells' DATA and none of
their VERDICTS, and republishes a clean sheet over them. The run that erased
ratcatcher's red was `--only winder`; `asked` in the shipped file says so.

This is the worst member of the lying-instrument family. It does not fail to
see the fault. It sees the fault, writes it down, and prints GREEN next to it.

**FIX.** `audit_rows()`. The verdict is re-derived from EVERY row in the file,
every run, from the stored measurements - frame edges, `fits_frame`,
`alone == 0`, proving-view count. A carried cell is judged by exactly the same
test as a fresh one, so a red can only leave this file when the render that
fixes it lands. Rows judged from stored data are marked `[carried]` so nobody
mistakes a re-derivation for a re-measurement. `verdict_scope` states in the
file what `ok` covers. Re-rendering all 44 on every run would cost an hour to
answer a question the rows already answer.

PROVED BEFORE IT WAS USED: run against the shipped GREEN file, `audit_rows`
returns `ok False` and names `ratcatcher/front` and `ratcatcher/back`.

**AND THE RED IS CLASSIFIED, or the verdict becomes noise.** Two retired cells
(`snuffer_chibi`, `tallyman_chibi` - in `pairs`, not in `M.ORDER`, never
rendered again) have no occlusion measurement and now hold the register RED for
ever. Literally true, practically useless: a reader who learns RED always means
"those two again" has learned to ignore the one number that matters. So
`red_summary` publishes `shipped_red`, `retired_red` and `ok_shipped` BESIDE
`ok`, which is not weakened and still covers all 46 rows.

Current state: `verdict RED`, `shipped_red []`, `retired_red
[snuffer_chibi, tallyman_chibi]`, `ok_shipped true`, blank check 132 files 0
failures, 0 frame-edge hits anywhere in the set.

## 3. A THIRD THING THE SAME MECHANISM DID, FOUND WHILE FIXING THE SECOND

`_hero_scale.png`, the master 44-cell contact sheet, was **2280 x 560 on disk -
THREE cells**. A per-key run rebuilds the sheet out of its own `--only` keys,
and instalment 5 ran 44 of those back to back, so the "master" sheet was a
remnant of the last subprocess. Same shape of fault as the verdict: a global
artefact rewritten from a local scope. Rebuilt over all 44, now 2280 x 8400.

## STILL OPEN, CONFIRMED BY LOOKING THIS RUN, NOT CARRIED ON TRUST

  - **dyer, back view**: there is no creature in it. The drying frame, the
    cloths and the vat are all that read; the body is behind a cloth. From
    behind, the dyer is furniture.
  - **greener, back view**: the man is one flat near-black mass - head,
    shoulders, torso and legs share a value, and only the tan draped paper
    separates anything. The Beadle-facing fault a third time.
  - **ratcatcher and boiler, noted while looking at the new renders**: the
    ratcatcher's body is near-black on near-black with only the brass band and
    two eyes breaking it; the boiler's man, vat, lid and pour are all one pale
    cream, the pale-on-pale fault written up on the Relief and the Scraper.

Each of those is a value pass on a body, not a harness fix, and none of them is
what the plan asked for this hour.
