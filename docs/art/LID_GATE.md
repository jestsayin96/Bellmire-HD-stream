# The lid gate — a height term for the art lane's fit gates
2026-11-20 02:4x CT, ART lane.

## The defect

`minibossgen.py` and `monstervariants.py` both gated a creature on ONE number:
its footprint span against an 11.0 m corridor. There was no height term at all,
and both files carried the corridor clear as a Python literal hand-copied out
of `scripts/floorgen.gd`.

So Broodglut shipped at 6.60 m with a GREEN verdict while standing 0.10 m
through a shadows-only lid whose underside is at 6.50 m — `floorgen.gd:1377-1384`
builds a 1 m BoxMesh at y=7.0 to keep the overworld sun off the floor. Nobody
had ever measured it, and no gate could have failed on it.

## The fix

`tools/art/floorgeom.py` reads the dungeon's own numbers out of
`scripts/floorgen.gd` every run and holds **no literals**:

| number | read from | today |
|---|---|---|
| cell | `const G` | 4.0 m |
| wall inset | `const WALL_IN` | 0.5 m |
| corridor cells | `const HALL_W` | 3 |
| lid y / thickness | the single `SHADOWS_ONLY` anchor and the two lines above it | 7.0 / 1.0 |
| **corridor clear** | derived | **11.0 m** |
| **lid underside** | derived | **6.50 m** |

`verdict(geom, span, height)` returns both terms. `ROOM-LOCKED` is a
construction fact, not an error — the game build gates the spawn. `THROUGH-LID`
**is** an error and reds the report.

**It goes red on empty.** If a number cannot be read, the value is `None`, the
verdict is WITHHELD and the report is RED. It never falls back to 6.50 or 11.0.
A gate that cannot see the lid must not certify a creature as under it — this
lane has already shipped an instrument that could not move (System 1) and one
that could not see (pass 11).

The lid is under review (supervisor 02:12 CT: y 7.0 → 10.0, game build's line).
That is precisely why the gate reads it instead of holding a copy of it.

## Red arms

`python3 tools/art/_floorgeom_proof.py <repo>` — six arms, all move:
shipped / lid raised to 10.0 (Broodglut turns UNDER-LID with 2.90 m clear) /
lid line deleted (withheld, not defaulted) / lid y as an expression (refuses to
guess) / `HALL_W` renamed (span verdict withheld, lid eye still works) / two
`SHADOWS_ONLY` anchors (ambiguity is an error, not a pick).

`MBG_RED_LID=2.50` on `minibossgen.py` forces the lid down so real bodies on
disk must come out THROUGH-LID — it proves the plumbing, not the arithmetic.
A red run writes `_report_red.json` and never overwrites the green register.

## State at the time of writing

- 47 miniboss records re-verdicted from their stored measurements, no re-render:
  **all UNDER-LID**, tallest `beadle` 2.95 m with 3.55 m clear. 0 room-locked.
- `renders/art/variants/_register.json` → **NOT PASSED**: `broodglut` 6.60 m is
  0.10 m THROUGH the lid at 6.50 m. `lastcuff` 6.20 m is UNDER by 0.30 m.
  That verdict flips back to GREEN by measurement the moment floorgen's lid
  reaches 10.0 — nothing in art has to change.

## PROVENANCE — which tree the number came out of (added 07:5x CT, 20 Nov 2026)

A right number in the wrong tree is a wrong number. `renders/art/minibosses/_leech_span.json`
published `lid_y_m 7.0 / lid_underside_m 6.5` with `errors: []` beside it: true of the art
worktree (pre-S56), **false of the dungeon that ships** — `origin/main` has carried `10.0`
since S56. The register escaped the fault only because a human had typed `read_from_tree`
into it by hand, so the honest copy was the one a reader would quote least. Team lead, 06:58.

`floorgeom.read()` now stamps every read and compares it with the ref:

- `provenance.repo` / `branch` / `head` — the tree and commit parsed
- `provenance.gd_sha256_8` and `gd_lid_line` — the file, and the lid assignment **verbatim**
- `provenance.ref` / `ref_commit` / `ref_gd_sha256_8` — `origin/main` and the blob compared
- `provenance.drift` — a **term-by-term** diff of all seven derived numbers, not a file sha
  (an unrelated edit changes a sha; a gate that cries wolf gets switched off)
- `provenance.verified` — false when `origin/main` could not be read. **"I could not check"
  is not "it agrees"**, and `require_current()` refuses that too.

`floorgeom.require_current(geom)` is the publisher's gate: it **raises `StaleTreeError`
and writes nothing** when the parsed `floorgen.gd` disagrees with `origin/main`'s.
`allow_stale=True` flags instead of refusing — and then the published file must carry
`floorgeom_stale: true` in its own body, which `_leech_span.py` does.

`drift_vs()` goes **red on empty**: a comparison that ran over zero terms is a drift entry
saying so, never a silent agreement.

Point a reader at the tree that ships with `FLOORGEOM_TREE=<repo>` (`_leech_span.py`),
`--geom-repo` (`monstervariants.py`). The creature's own GLB and register are still read
from the art worktree, because those are art's.

**Arm I** in `_floorgeom_proof.py` (now **9 arms**) proves the stamp is present, that
`drift_vs` names the moved term *and* the term derived from it, that an unverifiable tree
is refused, that the flag path flags, and that an empty comparison goes red. It was also
proved on two **real** trees: run against the art worktree it reads
`DRIFTED FROM origin/main … lid_y_m: tree 7.0, origin/main 10.0` and the publish is
**refused, rc 3, JSON byte-identical**; against the main repo it reads `AGREES` and
publishes `lid_underside 9.5 / lid_clear 7.18`, which is what the register already said.

One Blender trap recorded here because it nearly scored a refusal as a pass: **`blender -b -P`
swallows a script exception and still exits 0**, and it catches `SystemExit` too. The refusal
path uses `os._exit(3)`.

### Still true of the art worktree

`bellmire-art/scripts/floorgen.gd` still carries `lid.position = Vector3(0, 7.0, 0)`
(sha `e25c31d9`) while `origin/main` carries `10.0` (sha `bc3a603f`). Until the art worktree
merges main, any floorgeom read taken from it is correctly stamped **DRIFTED**, and generators
run there will carry `floorgeom_stale: true`. Read the shipping tree, or merge.
