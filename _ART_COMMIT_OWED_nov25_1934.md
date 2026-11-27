> **RESOLVED 27 Nov 2026 03:0x CT - DO NOT ACT ON THIS FILE.** The Blender MCP
> bridge came back at the 02:34 firing after six stranded runs, and every file
> this note lists was verified TRACKED in git (`git ls-files --error-unmatch`,
> 12 of 12) before this line was written. Nothing below is owed. The note is
> kept for the record of the stranded hours and for nothing else.

# ART LANE - FOUR FILES FINISHED ON DISK AND IN NO COMMIT. 25 NOV 2026, 19:34 FIRING.

**SUPERSEDES `_ART_COMMIT_OWED_nov25_1834.md`** - that note's two files are still
owed and are items (1) and (2) below. Commit all four together.

Times read off the machine with `TZ=America/Chicago date` (19:34 at start,
19:41 mid-run, 19:4x at write). The Blender MCP bridge - this lane's ONLY route
to git, Blender and Godot - answered `Cannot connect to Blender at
localhost:9876` at 19:35, 19:38 and 19:4x. Blender is not running or the addon
is not listening. Third firing in a row stranded (18:34 and 19:06 the same).

## COMMIT THESE FOUR, EXACTLY AS THEY STAND

  1. `assets/monsters/minibosses/overlooker.glb.import`  (NEW, 45 lines - from 18:34)
  2. `docs/art/FIREPIT_IS_THE_THIN_THEME_AND_THE_SHINGLER_IS_STRUCK.md`  (NEW - from 18:34)
  3. `tools/art/glb_bounds.py`  (NEW - pure-python glb AABB reader)
  4. `docs/art/FIT_REGISTER_COVERS_37_OF_76_AND_NOTHING_IS_ROOM_LOCKED.md`  (NEW)
  5. `renders/art/minibosses/_fit_coverage_audit.json`  (NEW - the measured table)

Suggested message:

    ART: the Overlooker's missing .glb.import, firepit measured as the thin theme,
    and a measured audit - the fit register covers 37 of 76 bodies and no miniboss
    is room-locked by construction (11.0 m span, tightest breaches at h=5.6 m)

    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

**Do `git merge origin/art` before pushing** - this lane's local HEAD has been
found a commit behind the remote before.

## WHAT IS NOT OWED

- `assets/monsters/minibosses/snarer_chibi.glb.import` EXISTS. The prompt still
  carries it under "STILL OWED, SMALL"; it is not owed. **All 76 `.glb` in that
  directory have an `.import` sibling, and so do all 720 in the tree.**
- No register entry was written for the 39 uncovered bodies, deliberately. See
  the doc: `visibility` needs a render, and an entry without it reads as a pass.

## ONE STRAY FILE STILL TO DELETE

`assets/monsters/minibosses/_probe.txt` - 3 bytes, mine, untracked, so it cannot
ride into a commit. This lane cannot `rm` inside a connected folder and a 3-byte
probe is not worth a permission dialog on Mr. E's screen with nobody at it.
