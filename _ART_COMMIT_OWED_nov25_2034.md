# ART LANE - SEVEN FILES FINISHED ON DISK AND IN NO COMMIT. 25 NOV 2026, 20:34 FIRING.

**SUPERSEDES `_ART_COMMIT_OWED_nov25_1934.md` AND `_ART_COMMIT_OWED_nov25_1834.md`.**
Their files are all still owed and are items (1)-(5) below. Commit all seven together.

Times read off the machine with `TZ=America/Chicago date`: 20:34:53 at start,
20:38:26 mid-run. **THE BLENDER MCP BRIDGE IS STILL DOWN** - `Cannot connect to
Blender at localhost:9876` at 20:35 and again at 20:38. Blender is not running,
or the addon is not listening. **THIS IS THE FOURTH CONSECUTIVE STRANDED FIRING**
(18:34, 19:06, 19:34, 20:34). That bridge is this lane's ONLY route to git,
Blender and Godot, so this lane cannot commit, push, render or run Godot at all
until someone starts Blender and enables the MCP addon.

## COMMIT THESE SEVEN, EXACTLY AS THEY STAND

  1. `assets/monsters/minibosses/overlooker.glb.import`                        (NEW - from 18:34)
  2. `docs/art/FIREPIT_IS_THE_THIN_THEME_AND_THE_SHINGLER_IS_STRUCK.md`        (NEW - from 18:34)
  3. `tools/art/glb_bounds.py`                                                 (NEW - from 19:34)
  4. `docs/art/FIT_REGISTER_COVERS_37_OF_76_AND_NOTHING_IS_ROOM_LOCKED.md`     (MODIFIED this run - see below)
  5. `renders/art/minibosses/_fit_coverage_audit.json`                         (MODIFIED this run - see below)
  6. `tools/art/glb_bounds_crosscheck.py`                                      (NEW this run)
  7. `_ART_COMMIT_OWED_nov25_2034.md`                                          (this note; optional)

Suggested message:

    ART: the Overlooker's missing .glb.import, firepit measured as the thin theme,
    the fit-coverage audit (37 of 76 covered, nothing room-locked), and a SECOND
    independent AABB reader that corroborates all 76 bodies and caught my own
    overstated corridor headroom - 1.60 m, not the 2.15 m first published

    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

**Do `git merge origin/art` before pushing** - this lane's local HEAD has been
found a commit behind the remote before.

## WHAT THIS RUN ACTUALLY DID, SINCE IT COULD NOT RENDER

It did not invent a miniboss. The standing permission is live and the reachable
plan row (17:58) leaves this lane dry, but a new body needs Blender to model it
AND a render on a hero body to prove fit, and **a piece never rendered on a body
is not done.** Inventing one would have added an eighth unverifiable file to a
pile already four firings deep. So this run verified the pile instead.

**THE AUDIT'S WHOLE TABLE RESTED ON ONE INSTRUMENT CHECKING ITSELF.**
`tools/art/glb_bounds.py` is new, mine, and written with the bridge down; every
number in `_fit_coverage_audit.json` came out of it. So item (6) is a SECOND
reader, written separately from the glTF spec (recursive node-TRS composition,
accessor min/max corners through the accumulated world matrix) and not by reading
the first one. Over all 76 bodies:

  - `raw_h` / `size_x` / `size_z`  **76/76 agree within 0.002**
  - `footprint_diag`              **76/76**
  - corridor 11.0 m verdict       **76/76**
  - `breach_h`                    **76/76 within 0.05**
  - register `creature_h`         **37/37 agree, 0 disagree**, re-joined out of the
    28 `_fit_*_register.json` `pairs` maps; the `in_register` set matches
    body-for-body with the audit's own flags.

Widest footprint diagonal 4.648 m (`sluicekeeper_chibi`); tightest breach
`porter_chibi` at 5.60 m. Both confirmed twice.

## THE ONE FAULT IT FOUND, AND IT IS MINE

Both (4) and (5) said **"the highest recommended `h` anywhere in MINIBOSS_FIT.md
is 3.45 m"**. That is the `tallyman` row - the FOURTH of the fourteen - not the
column maximum, which is `bellman` at **4.00 m**. I read a row instead of the
column. So the published headroom was wrong:

  - margin is **1.60 m**, not the 2.15 m first published - overstated by 0.55 m
  - **the verdict does not move**: 5.60 m > 4.00 m, so NOTHING is room-locked by
    construction and the game build still needs no footprint spawn gate

Both files are corrected in place, with the correction written into them rather
than quietly patched. Fixing a defect in this lane's own work is allowed under
the freeze. The `breach_h` column itself was never wrong - 76/76 on re-measure.

## WHAT THESE NUMBERS ARE NOT

Geometry only. Two readers agreeing is **not a fit pass**: no render, no
visibility, no facing, no occlusion. It answers how BIG a body is and says
nothing about whether it READS. The 39 bodies without a register entry still
have none, deliberately - `visibility` needs a render, and an entry without it
reads as a pass. That is unchanged and still owed whenever the bridge returns.

## STILL TRUE FROM THE EARLIER NOTES

- `assets/monsters/minibosses/snarer_chibi.glb.import` EXISTS and is NOT owed,
  though the prompt still carries it under "STILL OWED, SMALL". All 76 `.glb` in
  that directory have an `.import` sibling once item (1) lands.
- `overlooker.glb.import` is STILL UNVERIFIED IN THE ONE WAY THAT MATTERS: no
  Godot run has opened it, because the bridge that runs Godot is the bridge that
  is down. The next lane with a Godot window should confirm `overlooker.glb`
  imports and loads. If Godot rewrites the uid, let it - that is expected.
- `assets/monsters/minibosses/_probe.txt` - 3 bytes, mine, untracked, so it
  cannot ride into a commit. This lane cannot `rm` inside a connected folder and
  a 3-byte probe is not worth a permission dialog with nobody at the screen.

## MINIBOSS COUNT, MEASURED NOT REMEMBERED

38 generator entries in `tools/art/minibosses.py`; 76 `.glb` bodies on disk
(base + `_chibi` variants). The prompt's "THIRTY-THREE already exist" line is
stale - measure off the generator, as the prompt itself says to.
