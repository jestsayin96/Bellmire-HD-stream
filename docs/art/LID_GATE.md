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
