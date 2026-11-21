# THE BACK-LAMP GUARD, AND THE REGISTER PRINTS ITS REAL VERDICT AGAIN
## 21 Nov 2026, 10:35-11:2x CT (machine clock, `TZ=America/Chicago`)

The 09:58 team-lead block gave the art lane two things, neither urgent, both
mine. Both are done and both are in this run.

---

## 1. ONE SWEEP THAT RE-READS ALL 44 - `tools/art/_backlamp_guard.py`

The census last hour repaired three bodies and `minibossfit.py` now defaults
`EVENLIGHT=1` / `GROUND=1`, so a NEW body cannot be born on the old rig. What
was still open is **drift**: a body re-rendered later with `--worldlight` or
`--noground` goes back to the old look and nothing says so. The guard closes
that. It reads the shipped PNGs - no Blender, no re-render, a few seconds.

Two arms, per body, over the three shipped views:

* **ARM 1 - EVEN LIGHT.** back/side chromaticity distance from the FRONT view
  at or under **0.1550**.
* **ARM 2 - A FLOOR.** every view composites at least **300** ground pixels.

### THE THRESHOLDS ARE MEASURED AND THE MARGINS ARE PUBLISHED

| | value |
|---|---|
| worst live back distance | `boiler` **0.11890** |
| lowest known OLD-RIG back distance | `sealer_ctl13` **0.19374** (`beadle_world` 0.20386) |
| **BACK_MAX** | **0.1550** - +30% over the worst live, -20% under the lowest old-rig |
| lowest live ground count | `relief` back **1405 px** |
| old-rig ground count | **0 px**, every view of both |
| **GROUND_MIN** | **300** - 4.7x under the lowest live, separating a count of ZERO |

### AND I LOOKED, BECAUSE THE NUMBER ALONE WOULD HAVE CONVICTED TWO CLEAN BODIES

`boiler` 0.1189 and `greener` 0.1049 sit well above the pack, and a bar drawn
off the data alone would have called them drifted. **They are not.**
`renders/art/minibosses/_backlamp_look.png` is front/side/back for boiler,
greener, snuffer, a low control (`dyer`) and both arms of the A/B.

* In `beadle_world` the **whole back view turns warm brass against a cool
  front**. That is a cast; you can see it on every material at once.
* In `boiler` and `greener` the light is the same neutral in all three views.
  What changes is **what is facing the camera** - boiler's big pale vessel and
  greener's teal plants cover different fractions of the frame from behind.
  A *mean* chromaticity moves without any lamp moving.

So the statistic cannot tell a cast from a change of mix, the bar is set above
the worst honest body, and **the picture is the reason it is allowed to be.**

### AN INSTRUMENT I BUILT AND THREW AWAY

A cast moves every material; a change of mix moves none of them. So I built the
statistic that should separate the two: quantize chroma to a 64x64 histogram
and, for each back pixel, measure the distance to the nearest OCCUPIED FRONT
bin - a re-weighting scores ~0 because every back material is already in the
front palette, a cast scores the size of the cast.

**IT FAILED ITS OWN CALIBRATION AND IS NOT IN THE SHIPPED FILE.**
`beadle_world` 0.01242 vs `beadle_even` 0.00862 is a 1.4x separation, and
`boiler` - a body I have looked at and know is clean - lands at 0.01020,
**between the two arms of a known A/B**. With many materials the front palette
covers chroma space densely enough to absorb a cast.

A second attempt, the smallest per-luminance-band chroma delta over five bands,
**does** rank both old-rig bodies above all 44 (`sealer_ctl13` 0.0810,
`beadle_world` 0.0726, worst live `greener` 0.0521) - but it separates 1.39x
where the plain mean separates 1.63x. It is published per body as `band_floor`
as a second opinion for a reader and **it decides nothing**. One deciding arm.

### RED ON EMPTY, FOUR WAYS - AND EVERY RED ARM FIRED THIS RUN

1. **Zero bodies audited is VOID**, never a clean green.
2. **The roster has TWO authorities** - `minibosses.ORDER` parsed out of the
   source (44) and the non-retired rows of `_fit_report.json` (46 - 2 = 44).
   They must agree exactly or the run is VOID. Measured this run: **44 = 44,
   zero symmetric difference.**
3. **A missing or blank view is RED.** Fired: a scratch root with
   `relief/hero_back.png` removed returns
   `BACKLAMP_GUARD RED audited=44 red=['relief'] / RED relief: back: missing`.
4. **The calibration arm is fired on every run, PER ARM.**
   My first build calibrated the whole verdict on the pair and **read VOID on
   its first run, correctly**: `beadle_even` is an even-LIGHT body with **no
   floor** - it predates `--ground`, as `_backlamp.ground_px`'s own docstring
   says. The pair proves ARM 1 and cannot prove the green side of ARM 2. So:
   ARM 1 is calibrated on the A/B pair (bad must FAIL the light test, good must
   PASS); ARM 2's red side is the same pair (both floorless, so a no-floor body
   MUST fire it) and its green side is the live population's own minimum, which
   must clear the bar by 2x or the run is VOID.

**And the drift arm fired on a live slot, not only on a scratch body:**
dropping `beadle_world`'s three views into the `beadle` slot returns
`RED beadle: back: chroma 0.20386 from front, over 0.1550 - reads as a second
lamp` plus three ground faults. Body, view and number are all named.

### THE VERDICT ON THE REAL TREE

```
BACKLAMP_GUARD GREEN  audited=44  red=[]  errors=0
  worst live back 0.11890 (cap 0.1550, headroom 0.03610);
  calibration bad=0.20386 good=0.06788
```

`renders/art/minibosses/_backlamp_guard.json`. Run it after any per-body pass:

    python3 tools/art/_backlamp_guard.py --json renders/art/minibosses/_backlamp_guard.json

Exit code is 0 on GREEN and 1 otherwise.

---

## 2. THE TWO RETIRED `_chibi` CELLS - MEASURED, NOT REDEFINED

The fit register has carried `verdict: RED / ok: false` for days on
`snuffer_chibi` and `tallyman_chibi`: two rows in `pairs`, not in `M.ORDER`,
never asked for, with a ratio and **no occlusion measurement**. The team lead
offered either retiring them properly or measuring them once.

**I measured them.** Retiring them properly would mean shrinking the scope that
`ok` covers, and turning a red into a green by redefinition - on an unattended
run - is the worse of the two. One render pass, 7.9 s, both bodies:

    blender -b -noaudio -P tools/art/minibossfit.py -- --repo W5 \
        --only snuffer_chibi,tallyman_chibi

```
verdict GREEN  ok true  rows_judged 46  rendered 2
errors []        unproved_cells []
red_summary {"rows": [], "shipped_red": [], "retired_red": [], "ok_shipped": true}
```

`proving` is now **3 of 3 views on both** where it read `null`. Nothing else in
the register moved: 46 rows before and after, every other row carried.

**AND I LOOKED** - `renders/art/minibosses/_chibi_measure_look.png`, both
bodies beside the hero, three views each. The hero and the creature stand clear
of one another in all six cells, which is what `seen: 1.0` should look like and
is the reason the number is believable. Both bodies came out of the re-render
on the current defaults and now measure even light and a real floor:
`snuffer_chibi` back 0.07289 / 3462 ground px, `tallyman_chibi` back 0.07923 /
3637. They were floorless before.

**Faults I can see, named because they are faults even though these two are
retired and nobody is going to fix them:** `snuffer_chibi`'s silhouette is a
mushroom - it reads "lamp stand", not "the thing that puts the lamps out", and
the two candles are too small to carry the idea; `tallyman_chibi` is a dark
brown cluttered mass whose tally board does not separate from the body at this
size. Both are reasons they were retired. Neither is a reason to re-open them.

---

## WHAT THE GAME BUILD MUST DO

**Nothing.** No `.gd`, no `bestiary.gd`, no wiring. This run touched
`tools/art/`, `docs/art/` and `renders/art/` only.
