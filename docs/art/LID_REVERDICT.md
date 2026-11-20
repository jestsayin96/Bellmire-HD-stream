# THE LID RE-VERDICT - 20 Nov 2026, 04:4x-05:0x CT

ONE `--reverdict` PASS ON `renders/art/variants/_register.json`. NO RE-RENDER, NO RE-SCALE.
The team lead's 03:58 ART row: the game build landed the lid at S56, so the corridor verdict
written against a 6.50 m lid is a verdict against a dungeon that no longer ships.

## THE TRAP I WALKED INTO FIRST, AND IT WOULD HAVE READ AS A CLEAN PASS

`--reverdict` reads the lid out of `scripts/floorgen.gd` **in `--repo`**, and `--repo` is this
worktree. **THIS BRANCH IS 1306 COMMITS BEHIND origin/main AND ITS floorgen.gd STILL SAYS
`lid.position = Vector3(0, 7.0, 0)`.** Run the plain command and floorgeom reads 7.0, computes
the same 6.50 m underside it computed yesterday, re-writes the identical numbers and exits 0.
Nothing would have failed. The register would have gone on asserting that Broodglut stands
0.10 m through a lid that is now 3.00 m higher, and the run would have looked done.

**THE FIX IS NOT A LITERAL AND IT IS NOT AN EDIT TO floorgen.gd, WHICH THIS LANE DOES NOT OWN.**
`tools/art/monstervariants.py` gained `--geom-repo` (which tree to read the dungeon out of) and
`--geom-note` (provenance). Both are recorded in the register beside the numbers, so the next
seat cannot mistake main's lid for art's:

    "read_from_repo": "...\\_scratch\\lidgate\\geom_main",
    "note": "scripts/floorgen.gd READ OUT OF origin/main e0b11257 - the art branch is 1306
             commits behind and still carries lid y=7.0"

The geom tree was `git show origin/main:scripts/floorgen.gd` written to scratch, nothing else.

## TWO RED ARMS, RUN BEFORE THE GREEN ONE, INTO A SCRATCH COPY OF THE REGISTER

Two consecutive green-only reads cannot tell a working gate from a sleeping one.

| arm | lid fed in | result |
|---|---|---|
| RED, lid forced low | `Vector3(0, 3.0, 0)` -> underside 2.50 | **NOT PASSED** - broodglut THROUGH-LID -4.10, lastcuff THROUGH-LID -3.70 |
| RED, lid line deleted | no `lid.position` line at all | **NOT PASSED** - `lid_underside_m: null`, geom_errors non-empty, both verdicts **WITHHELD, not passed** |
| GREEN, real | origin/main `Vector3(0, 10.0, 0)` -> underside 9.50 | **GREEN** |

The blind arm is the one that matters: floorgeom goes RED ON EMPTY and withholds rather than
defaulting. Neither red arm touched `renders/art/variants/_register.json` - they were pointed at
a scratch copy.

## THE GREEN PASS

corridor clear 11.0 m (`floorgen.gd:21`, `:848`, `:1698`), lid underside **9.50 m**
(`floorgen.gd:1383` y=10.0, `:1378` thick 1.0). Verdict **GREEN**, geom_errors empty.

| body | h | lid | clear | corridor | margin | fits |
|---|---|---|---|---|---|---|
| broodglut | 6.60 | UNDER-LID | **-0.10 -> +2.90** | CORRIDOR-SAFE | 0.594 | yes |
| lastcuff  | 6.20 | UNDER-LID | **+0.30 -> +3.30** | CORRIDOR-SAFE | 4.519 | yes |

Heights and spans are the stored measurements of real renders. Nothing was re-rendered, nothing
re-scaled, and the run-links arm was not re-run - its bar is not moved in a run that failed it.

## WHAT THIS GATE CANNOT SEE - ASK IT EVERY TIME

1. **It is a flat-lid height test.** It answers "is the head under the shadow box", not "does it
   clear a room kit's ceiling, a doorway header or an arch". None of those are parsed.
2. **The corridor term is a T-POSE span.** Broodglut's 10.4063 m is arms-out, the worst case -
   honest, but it leaves **0.594 m in an 11.0 m corridor, about 0.30 m a side**. Any draw-time
   upscale beyond **x1.057** puts it ROOM-LOCKED, and nothing in `scripts/bestiary.gd` carries a
   span for the game build to check that against. See the wiring note in the run summary.
3. **It re-answers arithmetic over stored records.** It cannot see a body that changed since the
   record was written. Broodglut's h is 6.60 in the register and 6.60 at `bestiary.gd:108`; those
   two agreeing is why the carried record is safe to re-verdict.

## ONE THING I CHECKED AND DID **NOT** CHARGE

`broodglut.glb` carries **0 embedded animation clips** while `bestiary.gd:108` gives it
`"anims": A_UAL` - which looks exactly like the static-body/anims fault this lane is told to
report. **IT IS NOT ONE.** All 49 miniboss glbs carry 0 clips, and so do `Puglin.glb` and
`Imp.glb`, which have shipped and played with `A_UAL` since long before any miniboss existed.
A_UAL is a clip-NAME map, not an assertion that the clips live in that file. Broodglut is in the
same shape as a body that works, so there is nothing here for the game build to fix.
