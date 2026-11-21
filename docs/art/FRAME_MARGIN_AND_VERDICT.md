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

---

# 4. THE 44 STALE ROWS, CLOSED BY ARITHMETIC - AND THE THREE THINGS THAT
#    TURNED UP WHEN I ASKED WHAT THE MARGIN CANNOT SEE

21 Nov 2026, 00:34-01:2x CT. The team lead's 23:58 row asked for the cheap
honest close of the `stale_margin` flag part 1 left behind, and did the
expensive half first: "I CHECKED EVERY STORED `pair_w` IN THE FILE AGAINST
FRAME_W - MARGIN_X = 5.48 AND NOT ONE STALE ROW EXCEEDS IT."

## 4.1 THE ARITHMETIC REPRODUCES, INDEPENDENTLY

Re-measured off the file, not off the row:

    stale rows                       44  (42 shipped + snuffer_chibi, tallyman_chibi)
    stale rows with NO stored pair_w  0  - so there is no blind cell
    widest stale row                  drover 5.45, then paviser 5.43, gaoler 5.43
    stale rows exceeding 5.48         0
    widest row in the whole file      ratcatcher 5.47 and boiler 5.47, NEITHER stale

The two widest rows in the register are the two the solver re-placed last
hour, and **every one of the 44 stale rows has MORE air than the solver's own
output**. The arithmetic is confirmed and the 44 re-renders are not owed.

## 4.2 WHY THE FLAG WAS NEVER A RE-RENDER - ONE LINE OF THE WRITER

    air_x = round(FRAME_W - (amx.x - amn.x), 3)

`air_x` is a PURE FUNCTION of `pair_w`, which every row stores. A stale row was
never a row that could not answer the margin question; it was a row missing a
field derivable from a field it has. So `audit_rows()` now RE-DECIDES instead
of flagging: it derives `air_x` from the stored `pair_w`, marks the row
`air_x_derived` ("NOT a re-measurement") so arithmetic is never mistaken for a
measurement, lists the derived keys in `margin_derived`, and judges `pair_w`
against the CURRENT `FRAME_W - MARGIN_X` on every row, fresh or carried.

`stale_margin` now means only what it should: a row with NO `pair_w`, which is
RED - underivable, not stale. It is EMPTY. `margin_derived` is 44.

RED-PROVED BEFORE IT WAS RUN, on synthetic rows, both directions:
pair 5.45 green, 5.48 green (the boundary), **5.49 RED by a centimetre**,
**10.80 RED** (the compounding-offset value from part 1, which derives to
-5.20 m of air), missing `pair_w` RED and named. An instrument that cannot
move is not a pass.

## 4.3 AND THE SENTENCE IN MY OWN SUMMARY THAT OUTRAN ITS EVIDENCE

`verdict_scope` read "44 of them rendered this run" on a `--sheet` run, which
renders NO bodies at all: `measured` is the keys ASKED FOR that have a row, and
on the sheet path that is the whole set. Same fault the team lead charged the
game build with an hour ago, sitting in this file's own verdict line. There is
now a `rendered_this_run` and the sheet path says `0 ... (--sheet: no bodies
rendered, 46 judged from stored measurements)`.

## 4.4 THE MARGIN IS A WORLD-SPACE WIDTH BUDGET AND NOT A PROMISE OF AIR

`MARGIN_X = 0.12` m reads as ~16 px of air across the pair at 760 px / 5.60 m.
Measured off the rendered PNGs, alpha > DIFF_EPS, the air a VIEWER gets is
SMALLER than the derived air on **every single row**, by 1.6 to 19 px, mean 8 -
because alpha spreads past the mesh bounds the margin is computed from. Five
rows carry less real air than the margin advertises:

    drover    8 px total   paviser  9 px   boiler 16 px   ratcatcher 16 px   gaoler 22 px

Nothing is clipped - 0 border hits anywhere in the set - so this is not a red.
But `air_x >= MARGIN_X` is a **necessary pre-filter, not a guarantee**, and the
register now stores the measured `air_px` per view (left, right), `air_px_min`
and `air_px_tightest_view` so the pixel answer is on record beside the derived
one. No pixel floor is judged: choosing one is Mr. E's call, not mine.

## 4.5 THE ONE THE MARGIN STRUCTURALLY CANNOT SEE: THE SIDE VIEW IS THE OTHER AXIS

**`ferryman/hero_side.png` has 2 px of air on the right and 0 on the left**, and
every number in its row is green. It is the tightest cell in the set by a wide
margin and the margin machinery is blind to it BY CONSTRUCTION:

  - `pair_w`, `air_x`, `fits_frame` and the hero-offset solver are all the **X**
    axis. `ferryman` pair_w 4.23 leaves air_x 1.37 m = 186 px, and the front and
    back views measure 92 + 92 = **184 px**, which is the derivation confirmed
    by pixels almost exactly.
  - The **side camera looks along X and renders the pair's DEPTH (Y)**. Nothing
    in the margin machinery measures Y, and the solver only ever narrows X, so
    it cannot relieve a tight side view even in principle.

This is the gloves' 3/4-view overlap again: the instrument measured the axis it
was built for and the fault was on the other one. **NOT FIXED THIS RUN** - the
fix is a depth budget (`MARGIN_Y` plus a `GAP`-aware solve) and the depth gap is
the occlusion margin, so tightening it trades a border for the two subjects
hiding each other. Named here, defect in my own harness, carried.

## 4.6 THE DISK PASS - AND THE FALSE RED I ALMOST SHIPPED OFF IT

`frame_edge` is measured ONCE, in `shoot()`, on the buffer that run wrote, and
carried for ever. `audit_rows()` judges that stored number; `sheet()` opens all
132 PNGs to ask whether they are BLANK and throws the alpha away. **Nothing ever
re-asked the border question of the picture now sitting at the canonical path** -
so the register's red rested on a number no later run could contradict, while
holding the alpha array of the real file in its hand. `measure_disk_frames()`
now re-measures every view of every row from disk into `frame_edge_disk`.

**AND MY FIRST VERSION OF IT WAS WRONG, WHICH IS THE PART WORTH READING.** It
raised `ferryman/side: THE FILE ON DISK reaches the frame edge - left 3 px - AND
THE STORED frame_edge SAYS OTHERWISE`, a shipped RED with `ok_shipped: false`.
I went to the pixels before acting on it: 3 pixels, alpha **6, 7 and 8 of 255**,
rows 423-425, on the ground plane. And the row's OWN
`ground.side.shadow_edge` reads `{left: 3}` - accounting for all three exactly.

There are **TWO FILMS**: `frame_edge` is counted on the beauty render before
the ground is composited, `shadow_edge` counts the shadow's reach and by this
file's existing and deliberate design never fails a view, and the PNG on disk
is the composite of both. I had compared a composite against one of its parts.
The register was right and my new instrument was crying wolf - and if I had
trusted it I would have re-rendered the ferryman to chase a shadow.

The disk check now reds only on what **neither film accounts for**, which is
the question actually worth asking of a file: is this the render this row
measured? Red-proved: shadow-only 3 px GREEN, 9 px where 3 are accounted RED,
a real body clip still RED exactly once, a disk hit with no `ground` block at
all RED.

When a number and a picture disagree the picture is the evidence - and when two
numbers disagree, check which film each was shot on before you believe either.
