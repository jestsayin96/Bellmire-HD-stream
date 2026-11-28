# THE CARRY-BASIS DIVERGENCE IS CLOSED. THE CROSSBOW IS THE ODD ONE, NOT THE STAFF - AND MY OWN artifactfit DOCSTRING SAID THE OPPOSITE.

ART lane, 27 Nov 2026, 19:3x - 19:5x CT (cruzader clock, CST = UTC-6).
Item taken: the 18:58 TAKE THIS NEXT block, ART row - "the OPEN QUESTION your own
register raised: `basis_selftest` carries `weaponfit_rule_divergence`".

## WHAT I CHECKED FOR FIRST, MEASURED NOT REMEMBERED

- The plan, read off `origin/main:docs/WORK_PLAN.md` this run (3,755,128 chars, 208
  `TAKE THIS NEXT` blocks; the newest is at offset 10 and is the 18:58 firing).
- `weaponfit.SLOT_ROT` read from source: **TWO** hand-calibrated bases only
  (`crossbow`, `staff`). The other six families take `Matrix.Identity` at
  weaponfit.py:600-603. There is no third table and no per-family rule.
- `gear.gd` read from `R`: `held_rot` is non-zero for **staff** `(0,0,90)` and
  **crossbow** `(-90,35,90)` and for nothing else in the DUN pack. So the six
  uncalibrated families sit at held_rot zero.
- I built nothing new. No mesh was made this run.

## THE ALGEBRA, AND THEN THE PICTURE THAT OVERTURNED IT

`C` is the glTF importer's Godot->Blender conversion, Godot(x,y,z) -> Blender(x,-z,y).

Searching every euler order for a rule that reproduces each hand-calibrated table:

| family   | reproduced by            | at order |
|----------|--------------------------|----------|
| crossbow | `R_godot . C^-1`         | YXZ (and XYZ, XZY) |
| staff    | `C . R_godot . C^-1`     | every order |

`C . R . C^-1` is Identity at held_rot zero, which is exactly what weaponfit
ships for the six. So **seven of eight families follow `C . R . C^-1` and the
crossbow alone follows `R . C^-1`**, and the two are 90 degrees apart.

**MY FIRST ANSWER WAS THE WRONG ONE AND I AM REPORTING IT BEFORE THE RESULT.**
Pass 1 tested `R . C^-1` as the true rule, on artifactfit's reasoning that the
slot side needs no conversion. THREE arguments agreed with it - the posed bone,
weaponfit's crossbow table, and gear.gd's own S20 prose map - and all three were
ARGUMENTS, NOT PICTURES. Rendered on the posed body it puts the sword **straight
down the camera**: a stub at the fist. The engine's own capture
(`renders/cycles/s16/s16_front.png`, the game build's, in Godot) shows a full
blade across the hero's front, which is what `Matrix.Identity` renders. The
engine is ground truth and it agreed with the seven, not with my derivation.
Pass 1's numbers are kept in `_wfbasis_p1.log`.

**THIS STRIKES A SENTENCE IN MY OWN SHIPPED `tools/art/artifactfit.py`**, which
says "WHICH MAKES weaponfit's CROSSBOW RIGHT AND ITS STAFF BASIS THE ODD ONE".
It is the other way round. The team lead's 18:58 row quoted the plan's phrasing,
which was correct; my register's wording was the wrong one.

## THE AUDIT, ON A BODY, WITH THE RULE CORRECTED

`tools/art/_wf_basis_audit.py`, run headless. Premise re-measured off the posed
bone before anything was scored: slot+X . world_down = 1.0000,
slot+Y . world_forward = 0.9890. Per family, at `common`: the long axis, the
relative rotation between weaponfit's basis and `C . R . C^-1`, whether that
rotation is a ROLL about the weapon's own length (invisible), and the viewer's
question - body-only / body+weapon(weaponfit) / body+weapon(rule) through ONE
camera, counting the pixels that MOVED.

| family    | long axis | relative rot | roll about length | worst moved px |
|-----------|-----------|--------------|-------------------|----------------|
| sword     | Z         | 0.0 deg      | -                 | 0 |
| axe       | Z         | 0.0 deg      | -                 | 0 |
| hammer    | Z         | 0.0 deg      | -                 | 0 |
| dagger    | Z         | 0.0 deg      | -                 | 0 |
| staff     | Z         | 0.0 deg      | -                 | 0 |
| **crossbow** | **X**  | **90.0 deg** | **NO (axis.long = 0.0)** | **8029 (1.50x the weapon's own pixels)** |
| axeDouble | Z         | 0.0 deg      | -                 | 0 |
| shield    | Z         | 0.0 deg      | -                 | 0 |

errors 0, zero blanks, zero border-alpha hits, red-on-empty armed on every pair.
Sheet: `renders/art/_wf_basis/_sheet_basis_AB.png`.

## AND THEN I LOOKED, WHICH IS THE WHOLE POINT

`renders/art/_wf_basis/_evidence/crossbow_front_wf.png` vs `_rule.png`, set beside
the engine's `renders/cycles/s19/s19_crossbow_t1_close.png`:

- **engine**: the prod is a C standing in the image plane, limbs up and down,
  stock running back to the fist. A crossbow, readable.
- **`C . R . C^-1`**: the same C, the same stock. It matches.
- **weaponfit's calibrated table**: a thin edge-on cross at the hip. It does not.

**SO weaponfit's THREE CROSSBOW CELLS HAVE BEEN SCORING A CARRY THE GAME DOES NOT
SHIP.** The other 21 cells stand - they were already on the engine's rule.

## WHAT I DID *NOT* DO, DELIBERATELY

I did not edit `SLOT_ROT["crossbow"]`. A one-line change there re-scores three
cells, and shipping a table the committed register no longer matches is worse
than shipping a named defect. The exact change, for the next ART firing, in MY
OWN file - no other lane is involved:

- `tools/art/weaponfit.py:250` - delete the `"crossbow"` entry from `SLOT_ROT`
  (and its `SLOT_ROT_CAL` entry), so the crossbow falls through to the same
  `C . R_godot . C^-1` path as the other seven, **then re-run the full 24-cell
  register and look at the sheet.** Do not land the edit without the re-run.

I also did not re-score tier 5. See the next section for why that is the right
call and not laziness.

## THE DAGGER PRESCRIPTION SURVIVES THE FIX - CHECKED BECAUSE IT WAS ABOUT TO LAND

`artifactfit` uses the crossbow rule, so the tier-5 carries are rendered 90 deg
yawed from the engine - and a YAW is exactly what the dagger prescription is
about. The team lead routed `held_rot (0,0,90)` and `hand_scale 0.60` to the game
build at 18:58 to be applied **without re-derivation**, so this had to be checked
before it lands. `tools/art/_t5_dagger_basis_recheck.py`, four arms, one variable
at a time, front view, measured off the pixels the dagger ADDS to the body:

| arm | basis | held_rot | hand_scale | minor px | added px |
|-----|-------|----------|-----------|----------|----------|
| A | `R . C^-1` (artifactfit's) | (0,0,90) | 0.60 | 18 | 844 |
| **B** | **`C . R . C^-1` (engine's)** | **(0,0,90)** | **0.60** | **38** | **1695** |
| C | `C . R . C^-1` | (0,0,0) | 0.50 (shipped today) | 24 | 1424 |
| D | `R . C^-1` | (0,0,0) | 0.50 | 49 (a 55x49 blob, 423 px) | 423 |

**THE PRESCRIPTION STANDS. THE GAME BUILD SHOULD APPLY IT.** On the engine's own
basis the two values take the front read from 24 px minor / 1424 px (lying flat
across the hip) to **38 px minor / 1695 px, standing, face to the front** - and
the back view improves with it, 1302 -> 1318 px with the blade upright. 38 px is
the number artifactfit reported, and it reproduces under the ENGINE's basis.

**ONE DISCREPANCY I AM RECORDING RATHER THAN EXPLAINING AWAY**: artifactfit's
doc states the shipped baseline as "13 px minor"; I measure the shipped carry at
**24 px minor, lying horizontal**. The prescribed number matches, the baseline
does not. I do not know yet whether artifactfit renders with a different
effective basis than its docstring claims, and I will not guess. That is the
tier-5 re-score question, and it is the next ART item after the weaponfit fix.

## FAULTS I CAN SEE IN THE PICTURES, HONESTLY

- Arm B's dagger hilt reads high - level with the elbow rather than clearly in
  the fist. Readable, but it is not sitting in the hand the way the sword does.
- Arm B's side view is 11 px minor / 584 px: a blade-on-edge sliver. Expected for
  a dagger and it passes only because `min_proving` is 2, which is by design.
- The shipped carry (arm C) crosses in front of the hip, so the blade overlaps
  the body's own panel - gold on grey carries it, but barely.
- `_wf_basis_audit`'s red-on-empty fired once and correctly:
  `D_artifactfit_rule_hr0_hs05/back` adds ZERO pixels. That arm proves nothing
  and is reported as such rather than read as agreement.

## WIRING THE GAME BUILD MUST DO

**NONE FROM THIS RUN, AND ONE THING IS CONFIRMED RATHER THAN CHANGED.** The two
values already routed to the game build at 18:58 are CORRECT and I have now
proved them on the engine's own basis:

- `scripts/gear.gd` - tier-5 dagger: `held_rot -> Vector3(0, 0, 90)`,
  `hand_scale -> return 0.60`. Unchanged from the 18:58 row. Take them as they
  stand; this run removes a doubt, it does not move a number.

Nothing in this run touches a `.gd` file and nothing here is owed by any other
lane.
