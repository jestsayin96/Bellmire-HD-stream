> **RESOLVED 27 Nov 2026 03:0x CT - DO NOT ACT ON THIS FILE.** The Blender MCP
> bridge came back at the 02:34 firing after six stranded runs, and every file
> this note lists was verified TRACKED in git (`git ls-files --error-unmatch`,
> 12 of 12) before this line was written. Nothing below is owed. The note is
> kept for the record of the stranded hours and for nothing else.

# ART LANE - TWO FILES FINISHED ON DISK AND IN NO COMMIT. 25 NOV 2026.

**SUPERSEDED BY `_ART_COMMIT_OWED_nov25_1934.md` - the two files below are still owed, plus three more. Commit from that note.**

Written at 19:06 CT, read off the machine with `TZ=America/Chicago date`.

The 18:34 CT art firing finished these and COULD NOT PUSH THEM: the Blender MCP
bridge - the only route this lane has to git - stopped answering partway through
the run with `Cannot connect to Blender at localhost:9876`, i.e. Blender is not
running or the addon is not listening. Retried at 19:06 CT, same answer.

## COMMIT THESE TWO, EXACTLY AS THEY STAND

  1. `assets/monsters/minibosses/overlooker.glb.import`   (NEW, 45 lines)
  2. `docs/art/FIREPIT_IS_THE_THIN_THEME_AND_THE_SHINGLER_IS_STRUCK.md`  (NEW)

Suggested message:

    ART: the Overlooker's missing .glb.import, and firepit measured as the thin
    theme with my own first idea for it struck as a Straker re-skin

## WHY (1) IS A REAL DEFECT AND NOT HOUSEKEEPING

`overlooker.glb` was committed WITHOUT its `.glb.import` sibling, so that body
cannot load in Godot at all - the game build has 76 miniboss meshes and only 75
of them were loadable. It was the ONLY one missing, measured by listing the
directory this run, not remembered. It is a defect in this lane's own shipped
work, which the freeze allows fixing.

The file was written by rule, not by guess, and every part of it is checked:

  - `path=`/`dest_files=` hash: `md5("res://assets/monsters/minibosses/overlooker.glb")`
    = `80afa72be668a33bb9d730e13b0ded66`. **THE RULE WAS PROVED FIRST, NOT
    ASSUMED**: md5-of-the-source-path reproduces the hash in ALL 75 existing
    `*.glb.import` files in that directory, 75 matches and 0 mismatches.
  - `uid=uid://b4pxjsr4fuh2r`. Generated in Godot's own ResourceUID charset
    (`abcdefghijklmnopqrstuvwxyz0123456789`, letters first, base 36) - which was
    itself verified by decoding two real uids out of the tree
    (`bhreghh3dmmoc` -> 5722311690730434746, `bgyw30pnjxlmw` ->
    5618177566093018678) and re-encoding them back character for character.
    The new one decodes to 8744237548566696305, inside int64. Collision-checked
    against every uid in the directory: unique.
  - Everything else is `collier.glb.import` unchanged; 45 lines in and 45 out,
    and `grep -c collier` on the result returns 0.

**IT IS STILL UNVERIFIED IN THE ONE WAY THAT MATTERS AND I AM SAYING SO.** No
Godot run has opened it, because the bridge that runs Godot is the bridge that
is down. The next lane with a Godot window should confirm `overlooker.glb`
imports and loads; if Godot rewrites the uid, let it, that is fine and expected.

## THE PROMPT'S "STILL OWED, SMALL" ITEM IS ALREADY CLOSED

`assets/monsters/minibosses/snarer_chibi.glb.import` EXISTS - 1178 bytes,
dated 17 Nov 18:53. The prompt still carries it as owed; it is not. Measured by
listing, and after (1) above **all 76 `.glb` in that directory have an
`.import` sibling: 76 and 76.**

## ONE STRAY FILE TO DELETE

`assets/monsters/minibosses/_probe.txt` - three bytes, mine, a write test from
this run. Untracked, so it will not ride into a commit, but it should go. This
lane cannot delete inside a connected folder (`rm` returns `Operation not
permitted`) and a one-line probe file is not worth putting a permission dialog
on Mr. E's screen with nobody at it.
