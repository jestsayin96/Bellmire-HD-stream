# ART LANE - TWELVE FILES FINISHED ON DISK AND IN NO COMMIT. 25 NOV 2026, 21:34 FIRING.

**SUPERSEDES `_ART_COMMIT_OWED_nov25_2034.md`, `_nov25_1934.md` AND `_nov25_1834.md`.**
Their files are all still owed and are items (1)-(7) below. Commit all twelve together.

Times read off the machine with `TZ=America/Chicago date`: 21:34:42 at start,
21:52:12 mid-run. **THE BLENDER MCP BRIDGE IS STILL DOWN** - `Cannot connect to
Blender at localhost:9876` at 21:35, 21:37 and again at 21:53 after the work was
finished, in case it had returned. **THIS IS THE FIFTH CONSECUTIVE STRANDED
FIRING** (18:34, 19:06, 19:34, 20:34, 21:34). That bridge is this lane's only
route to git, Blender and Godot, so this lane cannot commit, push, render or run
Godot at all until someone starts Blender and enables the MCP addon.

Note for whoever reads this next: the main repo R is **not** mounted on the Linux
bridge either (only `C:\hd adventure\bellmire-art` is), and this worktree's `.git`
is a file pointing at a gitdir outside the mount, so **not even a read-only
`git log` works from here.** Every file below was verified to exist on disk by
listing it this run, not copied forward from the previous note.

## COMMIT THESE TWELVE, EXACTLY AS THEY STAND

      bytes  file
       1172  (1) assets/monsters/minibosses/overlooker.glb.import                      NEW  from 18:34
       7247  (2) docs/art/FIREPIT_IS_THE_THIN_THEME_AND_THE_SHINGLER_IS_STRUCK.md      NEW  from 18:34
       3738  (3) tools/art/glb_bounds.py                                               NEW  from 19:34
       7032  (4) docs/art/FIT_REGISTER_COVERS_37_OF_76_AND_NOTHING_IS_ROOM_LOCKED.md   MOD  at 20:34
      18885  (5) renders/art/minibosses/_fit_coverage_audit.json                       MOD  at 20:34
       4373  (6) tools/art/glb_bounds_crosscheck.py                                    NEW  from 20:34
       5768  (7) _ART_COMMIT_OWED_nov25_2034.md                                        (optional)
      16286  (8) tools/art/import_integrity.py                                         NEW  this run
       8185  (9) tools/art/import_integrity_selftest.py                                NEW  this run
      10809 (10) docs/art/THE_LOADER_AUDIT_IS_GREEN_AND_MY_FIRST_VERSION_OF_IT_HID_THE_ONE_DEFECT.md  NEW
       2042 (11) renders/art/_import_integrity_audit.json                              NEW  this run
          0 (12) _scratch/.gdignore  and  _sup_shot/.gdignore                          NEW  this run

Suggested message:

    ART: a loader-integrity audit over the whole tree - GREEN at 2342/2342 - plus
    the Overlooker's missing .glb.import, firepit as the thin theme, the fit-coverage
    audit (37 of 76, nothing room-locked), and two .gdignore files that take 27
    spurious scan entries and six scan errors out of Godot's scope

    The audit's own first version scored D at 1.00000 while holding the one
    non-imported file in an "inapplicable" bucket no check looked at. Both the
    blind spot and an overstatement in its E wording are fixed in this commit,
    and the selftest proves all five checks move in both directions.

    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

**Do `git merge origin/art` before pushing** - this lane's local HEAD has been
found a commit behind the remote before.

## IF YOU ONLY HAVE TIME FOR ONE THING

Run `python3 -I tools/art/import_integrity_selftest.py` (stdlib only, no Blender,
no Godot, a couple of seconds). It must print **SELFTEST GREEN - 9/9**. Then run
`python3 -I tools/art/import_integrity.py . out.json`, which must print
**VERDICT: GREEN** with `A 0`, `B 0`, `C 0 collisions`, `D rate 1.00000`,
`E LIVE 0, stale-marker 1`, and `accounting parsed 2342 == accounted 2342`.
If A or B is non-zero, an art asset in the tree cannot load.

## WHAT IS OWED TO A GODOT WINDOW, AND IT IS TWO ONE-LINE CONFIRMATIONS

1. `overlooker.glb` - confirm it imports and loads. Its `.import` was hand-written
   by rule on 18 Nov and the rule is now proved on **2341 of 2341** applicable
   files tree-wide (was 75 in one directory), and its uid is unique across all
   **2342** (was: one directory). Still, **no Godot run has opened it.** If Godot
   rewrites the uid, let it - that is expected.
2. `web/icons/items/hat/turbary_hood.webp` - confirm Godot re-imports it and
   clears `valid=false`. The evidence says it will: the cache sidecar records
   `source_md5="d41d8cd98f00b204e9800998ecf8427e"`, the md5 of a **zero-byte**
   file, and the webp on disk now hashes to `148cf7b15edaad94a106c789e90ff2cb`,
   which is Godot's re-import trigger. **Nothing is asked of any lane for this** -
   it is a fossil of the 0-byte era recorded in `web/NOTES.md`, the icon is intact
   (RIFF/WEBP/VP8X, 160x160, 2718 bytes) and the hub serves the raw file over HTTP,
   so the site shows it correctly today. Do **not** hand-edit that `.import`.

## WHAT THIS RUN DID NOT DO, AND WHY

**It did not invent a miniboss.** The plan's ART row (17:58) says "nothing new
from me until I have looked", so this lane is dry and the standing permission is
live - but a new body needs Blender to model it **and** a render on a hero body to
prove fit, and a piece never rendered on a body is not done and must not be
reported as done. Fifth firing in a row where that is the honest answer.

**It did not write any new WORK_PLAN item** - the freeze forbids it. A harness
that could report an unearned pass is a defect in this lane's own work, which the
freeze allows fixing, and that is what items (8)-(10) are.

**It did not touch `_look/` or `_s121/`.** They are the same class of art scratch
directory as `_scratch/` and are still inside Godot's scan, but the audit found
**no fault** in either, and changing something with no measured defect is how a
run invents work. Named so the choice is visible rather than silent.

## ONE STRAY FILE STILL TO DELETE

`assets/monsters/minibosses/_probe.txt` - 3 bytes, mine, from the 18:34 run,
still present (listed this run). Untracked, so it cannot ride into a commit. This
lane cannot `rm` inside a connected folder and a 3-byte probe is not worth a
permission dialog on Mr. E's screen with nobody at it.
