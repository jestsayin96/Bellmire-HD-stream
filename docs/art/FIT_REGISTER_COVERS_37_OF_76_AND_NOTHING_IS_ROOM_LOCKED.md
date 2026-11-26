# THE FIT REGISTER IS HALF THE BODIES, AND NO MINIBOSS IS ROOM-LOCKED BY CONSTRUCTION

**25 Nov 2026, art lane. Clock read off the machine with `TZ=America/Chicago date`:
19:34 CT at the start of the run, 19:41 CT when the corridor numbers below were
computed.** The Blender MCP bridge was down for the whole firing
(`Cannot connect to Blender at localhost:9876`, probed at 19:35, 19:38 and again
at the end), so **nothing in this file is a render.** No Blender, no Godot, no
git, no push. Everything here was measured off the files with the Linux bridge.

## THE COUNTS, MEASURED THIS RUN, NOT REMEMBERED

| thing | number |
|---|---|
| `.glb` bodies committed in `assets/monsters/minibosses/` | **76** |
| of those, built by `tools/art/minibosses.py` | **74** |
| of those, built elsewhere (`broodglut`, `lastcuff`) | **2** |
| bodies with front + side + back on a hero body, on disk | **76 of 76** |
| bodies with an entry in any `*_register.json` | **37** |
| **bodies with NO register entry** | **39** |
| `.glb` in the whole tree with no `.import` sibling | **0 of 720** |

**The prompt's "thirty-three minibosses" line is badly stale** - it is dated
18 Nov. The count off the generator today is 74 bodies, 76 on disk.

**AND THE REGISTER IS NOT THE COUNT, WHICH IS A PROBLEM, BECAUSE THE PLAN SAYS
IT IS.** The 17:58 row says "the fit register is the count, not any line in a
prompt." Anyone counting minibosses off `_fit_*_register.json` today gets 37 and
is wrong by half. The 39 uncovered bodies are listed in
`renders/art/minibosses/_fit_coverage_audit.json`.

## WHAT THE 39 ARE MISSING, EXACTLY - AND WHAT THEY ARE NOT MISSING

They are **not** unrendered. All 39 have `hero_front.png`, `hero_side.png` and
`hero_back.png` (the Overlooker's are `front/side/back.png` - a different
convention in the same tree, see the fault below). The pictures were taken and
looked at; the write-ups are in `docs/art/` per body.

What they lack is the **machine-readable** entry - `ratio`, `fits_frame`,
`visibility` - that the game build and the team lead read instead of opening a
PNG. That entry needs a render to compute `visibility`, and the bridge is down,
so **I did not write one.** A register entry with the numbers filled and
`visibility` absent would read as a pass, and this lane has already shipped one
number that read as a pass and meant nothing (`head_glow_px: 156` beside "the
head now has no face at all", pass 11, 17 Nov). I am leaving the gap visible
rather than papering it.

## NO MINIBOSS IS ROOM-LOCKED BY CONSTRUCTION, WITH 2.15 m TO SPARE

Measured, all 76, geometry only:

- Three-cell corridor clear span is **11.0 m** (`docs/art/MINIBOSS_FIT.md`).
- Widest footprint diagonal at authored height: **4.648 m** (`sluicekeeper_chibi`).
- Bodies at or over 11.0 m: **ZERO of 76.**

That holds at authored height, and monsters are **normalised** by `bestiary.gd`'s
`h`, so the authored number alone would not settle it. So I computed the height
each body would need before it ever breaches:

- Tightest body is `porter_chibi`: it breaches 11.0 m at **h = 5.6 m**.
- The highest recommended `h` anywhere in `MINIBOSS_FIT.md` is **4.00 m**
  (`bellman`). **CORRECTED 25 Nov 20:4x CT, and it was my own error:** the first
  version of this line said 3.45 m, which is the `tallyman` row - the FOURTH of
  the fourteen, not the largest. I read a row instead of the column's maximum.
- **Margin: 1.60 m**, not the 2.15 m first published. The game build needs no
  footprint spawn gate on any of the 76, and will not need one unless a body is
  normalised past 5.6 m - which is still 1.40x the tallest recommendation.
- The verdict does not move: 5.60 m > 4.00 m, so nothing is room-locked. Only
  the headroom was overstated, by 0.55 m.

## THE INSTRUMENT, AND IT WAS PROVED BEFORE IT WAS BELIEVED

`tools/art/glb_bounds.py` (new, mine) reads a `.glb`'s world-space AABB straight
out of the glTF JSON chunk in pure python - accessor `min`/`max` per POSITION,
eight corners of each mesh box pushed through that node's accumulated world
matrix, unioned. **It exists because when the bridge is down this lane cannot
otherwise measure a body at all.**

**Proved against known data first, not assumed:** run over the 37 bodies whose
`creature_h` is already recorded in a register, it agrees on **37 of 37**, zero
disagreements, tolerance 0.011. The rule was checked where the answer was
already known before it was used where it was not.

It **goes red on empty**: a body with no POSITION accessor carrying min/max
raises rather than returning a size computed over nothing.

**WHAT IT CANNOT SEE, SAID PLAINLY: it is a tape measure.** It answers how BIG a
body is. It says nothing about whether the body READS - no silhouette, no
facing, no occlusion, no visibility. Do not put its output in a fit register.

## THREE FAULTS I FOUND IN MY OWN INSTRUMENTS THIS RUN

1. **MY FIRST `.import` CHECK RETURNED "76 BAD" OFF ZERO MATCHES.** I extracted
   the import hash with `generated/([0-9a-f]{32})` and the path in the file is
   `imported/<name>.glb-<hash>.scn`. The regex matched nothing, the empty set
   compared unequal to the expected hash, and every one of the 76 files was
   reported broken. **It is the same fault as a green-on-empty metric, with the
   sign flipped**, and it would have had me "fix" 76 correct files. The rerun
   carries `assert hashes, "RED ON EMPTY"`. With the right pattern: **76 of 76
   hold the rule, 0 mismatches.**
2. **I NEARLY CHARGED A MISSING BACK VIEW ON EVERY SHIPPED BODY.** My first
   render audit looked for `back.png` and found it on exactly one body. The back
   view is `hero_back.png` on 74 of them. **Two naming conventions in one
   directory**, and the convention, not the art, was the finding. Re-run against
   both names: 76 of 76 have all three views. *The inconsistency is real and
   worth tidying, but it is cosmetic and it is not a missing render.*
3. **`broodglut` AND `lastcuff` LOOKED UNRENDERED AND ARE NOT.** Their renders
   are under `renders/art/variants/`, not `renders/art/minibosses/`, because
   they came from S54/S56 and not from the generator. Three hero views each.

The shape of all three is one thing: **the first number disagreed with the
pictures, and the pictures were right every time.**

## THE OVERLOOKER'S `.glb.import` IS RE-PROVED, BY ME, NOT INHERITED

The 18:34 firing wrote `assets/monsters/minibosses/overlooker.glb.import` and
could not push it. I re-derived its claims this run rather than trusting the
note:

- md5-of-source-path rule: holds on **76 of 76** files in that directory.
- `uid://b4pxjsr4fuh2r` decodes to 8744237548566696305, inside int64, and is
  **unique** against all 76 uids in the directory.
- 45 lines, `grep -c collier` returns 0, `source_file` is the overlooker's own.

**STILL UNVERIFIED IN THE ONE WAY THAT MATTERS, AND I AM SAYING SO AGAIN:** no
Godot run has opened it, because the bridge that runs Godot is the bridge that is
down. If Godot rewrites the uid on first import, that is fine and expected.
