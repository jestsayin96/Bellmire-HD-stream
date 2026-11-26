# THE LOADER AUDIT IS GREEN - AND MY FIRST VERSION OF IT SCORED 1.00000 WHILE
# HOLDING THE ONE BROKEN FILE IN A BUCKET NOTHING LOOKED AT

ART lane, 25 Nov 2026. Times read off the machine with `TZ=America/Chicago date`
(21:34:42 at start, 21:52:12 at write). CT is CST in November, UTC minus 6.

**THE BLENDER MCP BRIDGE IS DOWN AND THIS IS THE FIFTH CONSECUTIVE STRANDED ART
FIRING** - 18:34, 19:06, 19:34, 20:34, 21:34. `Cannot connect to Blender at
localhost:9876` at 21:35 and again at 21:37. That bridge is this lane's only
route to git, Blender and Godot, so this run could not render, could not model,
could not run Godot and **could not commit or push**. Only the Linux bridge
answered, and only `C:\hd adventure\bellmire-art` is mounted on it - the main
repo R is not, so even a read-only `git log` is unavailable (the worktree's
`.git` file points at a gitdir outside the mount).

The plan's ART row (17:58) says "NOTHING NEW FROM ME UNTIL I HAVE LOOKED", which
leaves this lane dry, and the standing permission to invent a miniboss is live.
**I DID NOT INVENT ONE.** A new body needs Blender to model it and a render on a
hero body to prove fit, and a piece never rendered on a body is not done and must
not be reported as done. So I took a defect class instead - the one that already
bit this lane - and closed it with the shell.

## WHAT I CHECKED FOR FIRST, MEASURED NOT REMEMBERED

The Overlooker shipped as `overlooker.glb` with no `.glb.import` sibling, so that
body could not load at all: 76 miniboss meshes and 75 loadable ones. Nothing in
the tree was watching for it. Before building anything I measured whether that
fault had siblings elsewhere, by walking the tree the way Godot does.

`tools/art/import_integrity.py` (NEW) - pure python, stdlib only, runs on the
Linux bridge with no Blender and no Godot. Five checks, each over a stated
denominator, each RED ON EMPTY:

| | check | what it catches |
|-|-|-|
| A | MISSING | an importable asset in Godot's scan scope with no `.import` |
| B | ORPHAN | an `.import` whose source asset is gone (Godot errors on these) |
| C | UID | `uid://` must be globally unique; a collision breaks loading |
| D | PATHHASH | the cache path must embed md5 of that `.import`'s OWN `res://` source path - a copy-pasted `.import` keeps the donor's hash and silently points at the wrong cache entry |
| E | NOTIMPORTED | `valid=false` or no cache path: Godot tried and did not finish |

## THE RESULT: GREEN, AND THE OVERLOOKER REALLY WAS THE ONLY ONE

Final state of the tree, `renders/art/_import_integrity_audit.json`:

    scanned      : 2342 importable assets, 2342 .import files
    gdignored    : ['_scratch', '_sup_shot', 'renders']
    A missing    : 0 / 2342
    B orphans    : 0 / 2342
    C uid        : 0 collisions, 2342 distinct, 0 without uid, den 2342
    D pathhash   : 2341 conform / 0 mismatch, rate 1.00000, den 2341
    E notimported: 1 / 2342  (LIVE 0, stale-marker 1, exempt keep/skip: 0)
    accounting   : parsed 2342 == accounted 2342
    VERDICT: GREEN

Per-directory, the game-loadable scope: **assets/ 1243 importable, 0 missing;
addons/ 555 importable, 0 missing; web/ 523 importable, 0 missing.** The
minibosses specifically: **76 `.glb` and 76 `.glb.import`.** So the missing-import
fault had no siblings among game assets. That is the answer I wanted least and
it is the right one to report.

## TWO CLAIMS OF MY OWN LANE'S THAT THIS UPGRADES FROM LOCAL TO TREE-WIDE

The 18:34 firing hand-wrote `overlooker.glb.import` by rule. It checked that rule
on 75 files in one directory and collision-checked its generated uid in that one
directory. Both are now checked against the whole tree:

- **uid `uid://b4pxjsr4fuh2r` is unique across all 2342 `.import` files**, not
  just its directory. 0 collisions anywhere.
- **the md5 path-hash rule holds on 2341 of 2341 applicable files, rate
  1.00000** - and the Overlooker's own file satisfies it, verified by hand and
  independently of the harness: md5 of `res://assets/monsters/minibosses/overlooker.glb`
  is `80afa72be668a33bb9d730e13b0ded66`, and that is exactly the hash in its own
  `path=` and `dest_files=`.

It is **still unverified in the one way that matters**: no Godot run has opened
it, because the bridge that runs Godot is the bridge that is down. Unchanged from
18:34. The next lane with a Godot window should confirm `overlooker.glb` imports;
if Godot rewrites the uid, let it, that is expected.

## THE PART WORTH READING: MY FIRST VERSION OF THIS HARNESS REPORTED AN UNEARNED PASS

The first version of check D scored **`conform_rate 1.00000, mismatch 0`** - and
the single genuinely non-imported `.import` file in the entire tree was sitting in
an `inapplicable` counter that **no check ever looked at**. The file had no
`path=` and no `dest_files=`, so D could not judge it, so D quietly dropped it and
printed a perfect score.

That is the same family as pass 11's `head_glow_px: 156` shipped beside the
sentence "the head now has no face at all". A metric that cannot see a thing
reports a clean number about it. **An "inapplicable" bucket is a blind spot, and
mine had the one real defect in it.** Fixed two ways:

1. every file D cannot judge is now **handed to E and counted** - nothing is
   dropped;
2. an **accounting identity** is asserted and printed: parsed `.import` files must
   equal conform + mismatch + notimported + exempt, or the audit goes RED on the
   residue. 2342 == 2342 at HEAD.

## AND THEN E OVERSTATED, SO I SPLIT IT ON THE ENGINE'S OWN BOOKKEEPING

E's first wording was "the resource will not load". For the one file it fired on,
that was **overstated** - the same error as the 20:34 run publishing 2.15 m of
corridor headroom when the column maximum made it 1.60 m. A failed import and an
already-healed one look identical inside the `.import`. The engine's own cache
sidecar tells them apart, so E now reads it:

- **E-LIVE** - `.godot/imported/<name>-<md5>.md5` records the **same** source hash
  the file has now. Godot has seen these exact bytes and produced no cache entry.
  A live failure. **Charged, RED.**
- **E-STALE** - the sidecar records a **different** hash, or is absent. The source
  changed after the failure, which is precisely Godot's re-import trigger, so the
  marker is a fossil. **Reported, not charged.**

## THE ONE FILE, AND WHY IT IS NOT A DEFECT ANY LANE NEEDS TO ACT ON

`web/icons/items/hat/turbary_hood.webp.import` - one of my 520 equipment icons.
It carries `valid=false`, no `path=`, no `dest_files=` and no `metadata=`, where
all 519 siblings carry all three.

Measured cause, from the engine's own sidecar rather than from a guess:

- the sidecar records **`source_md5="d41d8cd98f00b204e9800998ecf8427e"`**, which
  is **exactly the md5 of a zero-byte file**;
- `web/NOTES.md` records that this webp **was 0 bytes on main from 17 Nov 07:42**,
  the only zero-byte file under `web/`, `assets/`, `data/` and `scripts/`, and was
  regenerated to 2718 bytes;
- the file on disk now hashes to `148cf7b15edaad94a106c789e90ff2cb` and decodes as
  a valid `RIFF/WEBP/VP8X`, **canvas 160 x 160** - I read the header bytes myself
  rather than taking NOTES.md's word for it;
- there is a `.md5` sidecar for the webp but **no `.ctex`**, consistent with an
  import that never produced a destination.

So `valid=false` is a **fossil of the zero-byte era**, and the recorded hash
differing from the current hash is Godot's re-import trigger. **It clears itself
on the next project scan. No lane needs to do anything.** Severity on the game is
nil for a second, independent reason: **nothing in Godot loads `res://web/icons`
at all** - 0 files across every `.gd`, `.tscn` and `.tres`, checked for dynamic
concatenation too - and the hub serves the raw `.webp` over HTTP via
`web/app.js`, so the icon displays correctly on the site right now.

**WHAT I CANNOT SETTLE FROM HERE:** the sidecar is evidence about what the engine
LAST SAW. It is strong, but it is not a Godot run. E-STALE means "the re-import
trigger is armed", not "I watched it import".

## THE ONE FIX I COULD ACTUALLY APPLY

A and B were 21 and 6 before this run, and **every one of the 27 was in a scratch
directory of mine, not one in a game asset**:

- `_scratch/` - 21 PNGs with no `.import` (Godot was importing art scratch output
  into the project cache);
- `_sup_shot/` - 6 orphan `.import` files whose PNGs are gone. That directory
  contains **nothing but** those six dead files.

`renders/` already carries a 0-byte `.gdignore` for exactly this reason, so I
matched the existing pattern: **`_scratch/.gdignore` and `_sup_shot/.gdignore`,
0 bytes each.** Nothing references either directory - 0 `.gd`/`.tscn`/`.tres`
files mention them - so this removes 27 spurious scan entries and six scan errors
and takes nothing with it. A 21 -> 0, B 6 -> 0. Denominator arithmetic checks:
2414 - 66 (`_scratch` imports) - 6 (`_sup_shot`) = 2342.

**UNVERIFIED IN GODOT**, because the bridge is down. The risk if I am wrong is
that Godot stops importing files nothing uses.

`_look/` and `_s121/` are the same class of art scratch directory and are **still
scanned**. I left them alone deliberately: the audit found **no fault** in either,
and changing something with no measured defect is how a run invents work. Named
here so the choice is visible rather than silent.

## THE HARNESS WAS PROVED TO MOVE, AND THE SELFTEST CAUGHT ME MID-RUN

`tools/art/import_integrity_selftest.py` (NEW) plants one fault per fixture tree
and asserts both the verdict and the specific check that must fire. **9 of 9
behaved**: clean GREEN; A, B, C, E-LIVE each RED on their own fault; D RED saying
the *rule* is unproven on a 4-file corpus and deliberately charging no file; D RED
*naming the guilty file* once 200 clean files establish the rule; E-STALE GREEN
with nothing charged; and an empty tree RED on all five rather than green.

It earned its keep inside this run. When I added the E-LIVE/E-STALE split, the
fixture had no sidecar, so it was classified stale, so **the only path that makes
E go red stopped being tested and the selftest went RED and told me.** That is why
there are now two E fixtures instead of one.

## WHAT THESE NUMBERS ARE NOT

A loader check. Nothing here is a fit proof, a visibility proof or a facing proof.
It answers whether Godot can load a resource and says **nothing** about whether
anything READS on a body. The 39 miniboss bodies with no fit-register entry still
have none - `visibility` needs a render, and an entry without it reads as a pass.
Still owed whenever the bridge returns.

Miniboss count, measured off `tools/art/minibosses.py` this run rather than
trusted from the prompt: **38 generator entries**, 76 `.glb` on disk (base plus
`_chibi`). The prompt's "THIRTY-THREE already exist" line is stale.
