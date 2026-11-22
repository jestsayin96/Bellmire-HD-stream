# TWO INSTRUMENTS FIXED, BOTH OF THEM MINE - 21 Nov 2026, 21:45 CT

Both were named in the team lead's 20:58 ART row. Neither is a new item: each is a
defect in a harness this lane shipped, and one of them sent a row to the wrong lane.

## 1. `minibossfit.py` - THE REGISTER CRIED WOLF ON 46 SOUND BODIES

`measure_disk_frames()` built `renders/art/minibosses/<key><tag>/<view>` for EVERY
row out of **this run's** tag. The changer pass ran `--tag ch5`, so the disk pass
went looking for `beadlech5/`, `blowerch5/` and 44 more directories that exist only
for the body rendered this run. The shipped file read `errors` **192** (48 rows x
the same 4), `shipped_red` **46**, `ok_shipped` **false** - over 46 bodies whose
three views are on disk, correct, at the untagged canonical path. My own write-up
said "the Beadle's renders need regenerating", which was a WRONG DIAGNOSIS of a
REAL red: nothing needed regenerating.

**The fix is not "drop the tag"** - that is the 17:47 fault going the other way.
`renders/art/minibosses/changer/` exists and holds `front/side/three_quarter.png`
from a different harness entirely, so a directory that merely EXISTS does not
answer the question. `views_dir_for()` now picks the directory that holds **this
row's own view files**, in order: the `views_dir` recorded on the row when it was
rendered, then this run's tag, then the untagged path. The render loop writes
`views_dir` on every row it renders, and the disk pass backfills it for carried
rows, so the ambiguity is gone after one run. `sheet()` uses the same resolver with
the tag preferred, because a tagged sheet exists to show the tagged arm of an A/B.

NOTHING IS SILENCED. A row for which no candidate holds the views is RED and names
every candidate tried and why it was rejected.

RED PROVED, NOT ASSUMED (`renders/art/minibosses/_fit_redprove.json`): one row was
given a view file that is nowhere (`hero_ghost.png`) and another was given a bogus
`views_dir`. Result: **1 red row** (`beadle`, 4 errors, naming `beadlech5: no such
directory; beadle: exists but lacks hero_ghost.png`), `ok_shipped` false, and the
bogus-`views_dir` row fell back to the untagged path and stayed green. A gate that
cannot go red is not a gate.

AFTER, on the shipped register: `errors` **0**, `red_summary.rows` **[]**,
`shipped_red` **[]**, `ok_shipped` **true**, changer still green on its own numbers
(`views_dir: changerch5`, resolved "recorded on the row"), blank check 141 files /
0 failures.

STILL OPEN, SAID OUT LOUD AND NOT FIXED THIS RUN: a `--only <key>` run overwrites
the canonical `_hero_scale.png` with a ONE-CELL sheet, because `sheet()` is drawn
over `keys`. That is the same family as the 17:47 fault - a picture filed under a
name it does not answer. The canonical sheet was regenerated whole this run (49
cells, 8.4 MB) but the hole is still there.

## 2. `weaponfit.py` - THE STAFF WAS NEVER 0.475 m LOW

This register said the staff drags through the floor on all three tiers and a row
built on that number was sent to the game build, which measured first and refused.
It was right: `STAFF_GRIP_SHIFT` is at `gear.gd:90` (0.25) and applied at
`gear.gd:127` to the staff model's children, inside the x1.9 hand scale - and had
NO hit anywhere in `tools/`. Same family as faults 5 and 6: a carry this file does
not READ is a carry it cannot MEASURE.

`grip_shift()` now reads three things out of gear.gd and goes red on each: the
VALUE (`0.25`), the AXIS (`.position.y +=`, mapped Godot +Y -> Blender mesh +Z
through the same importer boundary SLOT_ROT was derived across) and the FAMILY the
engine gates it to (`DUN + "staff_"`). A shift gated to a family with no calibrated
slot basis fails loudly rather than scoring a carry nobody mirrored. It is applied
as `base @ Rslot @ S @ T`, which is the engine's own order (the offset is inside
the scale, so 0.25 x 1.9 = 0.475 m).

MEASURED, BEFORE -> AFTER:

| cell | ground verts | floor_depth | tip_z | clip |
|---|---|---|---|---|
| staff_common | 51 -> **0** | 0.180 -> **0.0** | 1.542 -> 2.017 | 52 -> 141 |
| staff_uncommon | 38 -> **0** | 0.216 -> **0.0** | 1.916 -> 2.391 | 64 -> 110 |
| staff_rare | 149 -> **0** | 0.212 -> **0.0** | 1.996 -> 2.471 | 202 -> 310 |

Verdict FAIL -> **GREEN**, floor_breaks 3 -> 0, 24 cells, 0 blanks, 0 frame clips,
0 blind views, 0 laths. Every non-staff row is unchanged to the digit (sword,
crossbow checked cell by cell), which is what a fix gated on one family should do.

### AND THE FAULT THE FIX EXPOSES - THIS ONE IS THE GAME BUILD'S TO JUDGE

`clip` - staff vertices sitting inside the hero's body mesh, fist sphere excluded -
ROSE on all three tiers (52->141, 64->110, 202->310), and `seen` front fell
0.785 -> 0.659. I LOOKED at `renders/art/system2/_staff_grip_sheet.png` (3 tiers x
front/side/back). What I can see: the butt is clear of the floor on all nine views,
nothing is cut by the frame, no blanks - and the shaft passes THROUGH the pauldron
and upper arm on every front view, and crosses the chin/faceplate on every side
view. That is the carry the engine ships; this register was simply measuring a
different one until now. It is `held_rot`/grip territory in `scripts/gear.gd`,
which is the game build's file. I have not touched it.
I could not show a before/after PICTURE: this pass overwrote the staff renders.
