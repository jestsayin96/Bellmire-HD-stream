# THE SELF-SEEN AUDIT - 24 Nov 2026, 11:34 CT firing (art)

The plan's TAKE THIS NEXT gave ART (11:34): "the 54th, or audit the 14
`self_seen` cells under its own 0.75 bar." Took the audit. It was the right
half of that choice: the instrument turned out to be describing a house that
no longer existed, and a 54th body would have been added to a register that
could not see it.

## 1. WHAT I CHECKED FOR FIRST (measured, not remembered)

- `renders/art/minibosses/_fit_report.json`: **55 pairs**, `verdict: GREEN`,
  `errors []`, `unproved_cells []`.
- Its `self_seen` block claimed `measured_bodies: 25`, `unmeasured_bodies: 21`,
  "21 of 46".  **25 + 21 = 46, and the register holds 55.**
- Set difference, taken in python off both files, not from the write-up:
  **NINE bodies were in `pairs` and in NEITHER list** - `almoner`, `blower`,
  `changer`, `nightman`, `panner`, `roper`, `stiltman`, `stopper`, `tither`.
  Every one of them shipped after 21 Nov, including all three bodies in the
  current cascade (panner 51st, stiltman 52nd, nightman 53rd).
- Standing `git status` untracked-`.glb` check: **0 before, 0 after.**

## 2. THE FAULT: A HAND-WRITTEN BLOCK CARRIED AS A MEASUREMENT

`minibossfit.main()` carries forward every top-level block it does not itself
compute. That rule is RIGHT - it is what stopped `ground` being nulled on
every non-`--ground` run. But the `self_seen` block it was carrying was
**written by hand on 21 Nov** over a 46-body house. Nothing recomputed it.  So
for three days the register published a coverage census for a house that had
grown by nine bodies, under `verdict: GREEN`.

This is the coverage form of trap 4. An instrument that cannot move is not a
pass; an instrument that was never ASKED about a body cannot be cited for it
either. `unproved_cells` could not catch it, because that key asks about
`visibility`, which every row had.

## 3. WHAT I MEASURED TO CLOSE IT

`tools/art/_selfseen_census.py` (new) builds every builder and reports, per
register row, whether a `man` span exists and whether it is non-empty. Run on
merged `art`: **55 pairs -> 31 measurable, 1 no-man, 23 not-measurable, 0
build failures.**  Against the instrument's own output that gave the exact
hole: **7 bodies were MEASURABLE AND HAD NEVER BEEN ASKED** - `almoner`,
`blower`, `changer`, `panner`, `roper`, `stopper`, `tither` - and 2
(`nightman`, `stiltman`) have no `man` span at all, which is an honest absence
the file had still never stated.

`tools/art/_backread.py` was then run on those 7. Six returned cells; `panner`
returned the row-level red "the man span merged to no object". Result:
**measured 25 -> 31 bodies, 75 -> 93 cells, and the under-bar list 14 -> 21.**

New under-bar cells, none of which had ever been looked at by anybody:

| rank | cell | man_seen |
|---|---|---|
| 3 | blower / back | 0.5228 |
| 7 | roper / back | 0.6151 |
| 8 | roper / front | 0.6163 |
| 11 | stopper / side | 0.6341 |
| 13 | almoner / side | 0.6501 |
| 17 | stopper / front | 0.6989 |
| 21 | blower / side | 0.7469 |

`blower/back` at 0.5228 is the **third worst cell in the house** and had been
sitting under a GREEN register since the body shipped.

## 4. THE AUDIT PROPER - ALL 21 CELLS, LOOKED AT

`tools/art/_selfseen_sheet.py` could only ever show the worst 8, so ranks 9+
had no picture behind them. Added `--skip` to page the ranking. Two sheets,
ranks 1-11 and 12-21, both opened and read tile by tile:

  `renders/art/minibosses/_backread/_selfseen_worst_sheet.png`
  `renders/art/minibosses/_backread/_selfseen_worst_sheet_p2.png`

**THE MAN CANNOT BE FOUND - the number is right (8 cells).** fuller/side (no
findable person at all), beadle/side (reads as a barrel), blower/back (a
ribbed bellows on two legs - no head, no arms), moulder/back (a pale ball with
a man behind it), dyer/back and greener/back (hanging cloth, a sliver of dark
limb), boiler/side, fenman/side (a dark studded mass; I could not find a man
and it sits at 0.7301, only just under the bar).

**OCCLUSION IS THE DESIGN - the gear is the point and the man still reads
(4).** paviser/front (a man behind a pavise is what a paviser IS - head and
one arm clear, face legible), winder/front, stopper/side, blower/side.

**THE NUMBER IS THE SUSPECT - the man reads at a glance and crossing gear
pushed the score down (9).** roper/back, roper/front, beadle/front,
ferryman/front, almoner/side, beadle/back, relief/front, sealer/back,
stopper/front. The 21 Nov write-up named ferryman/front as the single
disagreement; by eye it is **nine**, and `almoner/side` 0.6501 is the clearest
of them - hat, arm, sack, ladle and legs all legible.

## 5. WHAT THE INSTRUMENT CANNOT SEE, AND THE TILE THAT PROVES IT

**`self_seen` IS AN OCCLUSION MEASURE. IT IS NOT A READABILITY SCORE AND MUST
NEVER BE CITED AS ONE.**

The proof is on the sheet, in two tiles that sit at opposite ends of the
ranking and say the opposite of what the ranking implies:

- `tither/back` **0.9999** - the best cell of 93 - is a smooth featureless
  dark blob seen from behind. Nothing is in front of him, which is all the
  number means.
- `almoner/side` **0.6501** - thirteenth worst, UNDER the bar - is a man who
  reads instantly.

A high `self_seen` says the man is UNOBSTRUCTED, never that he READS. This is
the `seen: 1.0` correction one rung up, and it is now written into the
register's own `asks` string and into `derive_self_seen`'s docstring so the
next seat cannot over-read it the way `seen: 1.0` was over-read.

## 6. THE SECOND FAULT - MY OWN NEW GATE RAISED AN UNEARNED RED

The first cut of the coverage rule tested only `"man" in spans`, called
`panner` MEASURABLE, found no cells for it and **turned the whole register
RED**. I opened the builder before trusting my own red. `panner` pass 4
removed its operator deliberately, after an A/B it documents in full - "a part
whose removal changes a view by nothing was contributing nothing to that view"
- and left `P.spans["man"] = (len(P.items), len(P.items))`, an EMPTY span, as
the marker. A machine with no operator cannot fail a can-you-see-the-man test.

An instrument that cannot report an unearned PASS can still report an unearned
FAIL, and they are the same fault. The census now reports three states, not
two: measurable / **no_man** (empty span, nothing claimed, NOT red) /
not_measurable. `panner` is `no_man` and the register is GREEN on it.

## 7. THE GATE, AND IT WAS PROVED RED ON PURPOSE

`self_seen` is now **RUN-OWNED** in `minibossfit._RUN_OWNED` and recomputed
every run by `derive_self_seen()`. A stale hand-written block can no longer
outlive the house it describes. One new RED, deliberately narrow: **a body the
census calls measurable that carries NO self_seen cell.**

An assertion nobody has seen fire is not an assertion, so it was fired: with
`beadle` removed from `_selfseen_all.json` the register went
`ok: false / verdict: RED` naming `beadle` exactly, and came back GREEN when
restored. Both states observed this run.

## 8. STATE AT THE END

`_fit_report.json`: `ok: true`, `verdict: GREEN`, `errors []`,
`unproved_cells []`, `blind_views []`, `red_summary.rows []`, blank check
**159 files / 0 failures**, 55 rows judged, **0 rendered** (no body was
re-rendered; this run re-derived).
`self_seen`: `verdict GREEN`, 31 bodies, 93 cells, 21 under bar,
`uncovered []`, `no_man ["panner"]`, `not_measurable` 23 and NAMED.

## 9. OPEN, AND NOT MINE TO CLOSE THIS RUN

The 23 `not_measurable` bodies have no `man` span, so the one instrument built
to ask "can you see the man" **cannot be asked about any of them** - and that
includes `nightman` and `stiltman`, the two newest bodies in the house. Giving
them spans is a builder change per body and is art's, not another lane's; it
is named here rather than done, because doing 23 of them unreviewed in one
pass is how a batch of unlooked-at numbers gets shipped. Nothing in the engine
depends on it.

**NO WIRING IS OWED TO THE GAME BUILD BY THIS RUN.** No mesh, no canon row and
no `.glb` was added or changed; `assets/` is untouched.
