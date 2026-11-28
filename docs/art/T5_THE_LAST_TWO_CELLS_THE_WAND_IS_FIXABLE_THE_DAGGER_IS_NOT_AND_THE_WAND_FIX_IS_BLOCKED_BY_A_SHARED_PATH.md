# THE LAST TWO TIER-5 CELLS, CLOSED BY LOOKING

ART lane, 27 Nov 2026, written 20:5x CT (clock read off cruzader with
`TZ=America/Chicago date`; CT in November is CST, UTC-6).

The 19:58 CT plan row gave this lane the tier-5 margin: eleven of the thirteen
legendary carries are closed, take the **remaining two** to a real posed body
front, side and back, and close them **by looking**. It also said to measure
the live count myself rather than quote it. I did.

## 0. WHICH TWO, MEASURED OFF THE REGISTER AND NOT OFF THE ROW

`renders/art/gear_t5/_rx/_t5_rxproof.json`, parsed this run. Exactly two of the
thirteen cells carry `proving_views == 2`; the other eleven carry 3:

| kind | vis front | vis side | vis back | proving |
|---|---|---|---|---|
| **dagger** | 1598 | **567** | 1219 | **2** |
| **wand** | 1423 | 1314 | **790** | **2** |

`WF.MIN_PROVING` is 2, so both score GREEN in the shipped register and neither
appears in `blind_views`. **THAT IS THE MARGIN, NOT A PASS.** A gate set at two
views cannot tell a carry that reads from three angles from one that reads from
two, and the third angle is a real viewer's real angle.

New instrument this run: `tools/art/_t5_margin.py`. Same hero import, same
posed `handslot.r`, same basis selftest and the **same WF gate constants** that
artifactfit and `_t5_rxproof` use - not a kinder set. Register at
`renders/art/gear_t5/_margin/_t5_margin.json`, 16 arms, `verdict: GREEN`,
`errors: []`, 48 cells and 12 contact sheets. Blank check 0, border alpha
**0.0000 on all 48 cells**, no floor break on any arm.

## 1. THE WAND: FIXED, AND THE FIX IS ONE NUMBER

Sweep B moved **hand_scale only**, held_rot fixed at the prescribed (0, 0, 90):

| hand_scale | vis F / S / B | proving | clip_frac | show | world length | border |
|---|---|---|---|---|---|---|
| 0.62 (engine) | 1423 / 1314 / **790** | **2** | 0.304 | 1.058 | 0.72 m | 0.0 |
| **0.80** | **2779 / 2476 / 1853** | **3** | **0.163** | 1.054 | 0.93 m | 0.0 |
| 1.00 | 4149 / 4077 / 2710 | 3 | 0.206 | 1.031 | 1.16 m | 0.0 |
| 1.20 | 5703 / 6050 / 3341 | 3 | 0.244 | 1.015 | 1.39 m | 0.0 |

The choice rule was written into the tool **before** it ran: the smallest scale
whose WORST view clears `VIS_MIN` with no frame clip, no floor break and no
lath. That is **0.80**, and its worst view is 1853 against a floor of 900 - a
2x margin, not a squeak.

**ONE NUMBER WENT THE WAY I DID NOT EXPECT AND IT IS THE INTERESTING ONE.**
`clip_frac` FALLS from 0.304 to 0.163 when the wand is made bigger. A longer
shaft does not bury itself deeper in the hero; it reaches PAST him. The
occlusion that was eating the wand was the pauldron and the forearm, and the
cure for being hidden behind the arm is to be longer than the arm.

Sweep C then moved **roll only**, at the chosen 0.80. Every step is worse on the
front: 2779 -> 2369 (y 20) -> 1447 (y 35) -> 844 (y 50, back to proving 2).
**Roll stays 0.** The roll lever is real - it is what gear.gd ships for the
crossbow at (-90, 35, 90) - and it does not help here.

**AND THE SHEETS SAY WHY 0.80 AND NOT 1.20**, which no number above says.
`_sheets/B_wand_scale_{front,back}.png`, looked at: at 0.62 the blue gem is a
chip half-swallowed by the pauldron. At 0.80 it clears the shoulder and reads
as a blue crystal head with the shaft running down past the thigh. At 1.00 and
1.20 the gem rides up **level with the helmet and beside the face**, where it
competes with the one thing on the model a viewer looks at first. The gates
rate 1.20 the best cell on the sheet. It is the worst one to ship.

## 2. THE DAGGER: NOT FIXABLE, AND I TRIED BOTH LEVERS

**Sweep A, roll only, hand_scale fixed at the 0.60 the engine ships since S163.**
I did not re-open the scale; S163 settled it and the team lead recorded the
thin side read as a deliberate cost.

| roll y | vis F / S / B | proving | clip_frac |
|---|---|---|---|
| **0 (shipped)** | **1598 / 567 / 1219** | 2 | 0.346 |
| 20 | 1249 / **535** / 947 | 2 | 0.412 |
| 35 | 749 / 505 / 803 | **0** | 0.533 |
| 50 | 294 / 514 / 620 | **0** | 0.541 |
| 65 | 258 / 715 / 420 | **0** | 0.356 |

Rolling the blade to face the side camera makes the **side view worse** (567 ->
535) while gutting the front. `clip_frac` climbing 0.346 -> 0.533 is the reason
and it is visible on `_sheets/A_dagger_roll_side.png`: the roll does turn the
blade's face toward the side camera, and it swings it straight into the
shoulder, so the extra face is behind the pauldron. The shipped y=0 is the best
of the five on all three views.

**Sweep D exists because sweep A failing was not an answer yet.** A had moved
the only lever I had thought of; reporting "the lever failed" without trying the
OTHER lever gear.gd already ships would have been a half-answer. That lever is
the slot-frame grip shift, `position.x`, shipped today as `STAFF_GRIP_SHIFT`.
The slot's +X is world DOWN, so a NEGATIVE x raises the blade in the fist.

| grip x | vis F / S / B | proving | clip_frac |
|---|---|---|---|
| 0.00 | 1598 / 567 / 1219 | 2 | 0.346 |
| -0.10 | 1601 / 470 / 1372 | 2 | 0.469 |
| -0.20 | 1950 / 648 / 1475 | 2 | 0.508 |
| **-0.30** | **2097 / 783 / 1548** | **2** | 0.321 |

**EVERY NUMBER IN SWEEP D IMPROVED AND THE SWEEP IS REJECTED, BY THE PICTURE.**
At -0.30 all three views gain pixels, clip_frac drops below the shipped value,
border stays 0.0, nothing breaks the floor, and the side still misses VIS_MIN
at 783. Then look at `_sheets/D_dagger_grip_{front,side}.png`: the hand is down
at the hip and the blade is up beside the helmet. **It is not being held.** It
floats. That is the fit rule's own fault class, and it is invisible to every
gate in this tool because no gate of mine asks where the grip is relative to
the fist. This is the fifth time in this lane's history that a number and a
picture disagreed and the picture was right; I am recording it as the fifth.

**SO THE DAGGER IS CLOSED AS SHIPPED, WITH NO ENGINE CHANGE.** Two independent
levers, both already in gear.gd, both measured, both rejected. The 567 px side
view is what a 0.11 m-thick blade looks like edge-on, and the only remaining
lever is making the dagger not a dagger. 2 of 3 is the correct score for it.

## 3. THE WAND FIX IS BLOCKED, AND THE BLOCKER IS A SHARED PATH

This is the part my own instrument could not see, because it only ever looked
at tier 5. I parsed gear.gd's `KINDS` myself afterwards. The `wand` row:

| tier | kit entry | resolves to |
|---|---|---|
| 1 | `ADV + "wand.gltf"` | kaykit adventurers wand |
| **2** | `KIT + "wand_A.gltf"` | **res://assets/gear/wand_A.gltf** |
| 3 | `ADV + "wand.gltf"` | kaykit adventurers wand |
| **4** | `KIT + "wand_A.gltf"` | **res://assets/gear/wand_A.gltf** |
| **5** | `KIT + "wand_A.gltf"` | **res://assets/gear/wand_A.gltf** |

`held_rot()` and `hand_scale()` both key on **PATH ALONE**. So:

1. **Changing hand_scale for `wand_A.gltf` to 0.80 would also enlarge the
   TIER-2 COMMON WAND and the tier-4 wand.** Do not do it blind.
2. **And the fault underneath that is already shipped:** the tier-2, tier-4 and
   tier-5 wands are the SAME MESH at the SAME SCALE with the SAME rotation.
   They are pixel-identical. A viewer who spends months of points on a
   legendary wand is handed the common one. That is Mr. E's wear-is-a-receipt
   rule broken in the shipped game, found this run, and it is not something a
   held_rot row can fix.

`assets/gear/artifact/` holds seven golden meshes - sword, big sword, dagger,
small axe, double axe, double hammer, bow. **There is no artifact wand**, no
artifact sceptre, no artifact spear and no artifact staff; those four kinds
borrow a lower tier's mesh. I checked the directory rather than remembering it.

## 4. WHAT I CHECKED FOR BEFORE MAKING ANYTHING

- The two open cells: measured off `_t5_rxproof.json`, not taken from the row.
- `tools/art/_t5_margin.py` is new; nothing in `tools/art/` already swept a
  single carry variable against the shipped gates on a body.
- `assets/gear/artifact/` listed, not remembered: no wand mesh exists.
- **`assets/monsters/minibosses/snarer_chibi.glb.import` IS COMMITTED**, on
  `origin/art` AND on `origin/main`, checked with `git ls-tree`. The standing
  "STILL OWED, SMALL - committed with NO `.glb.import` sibling" note is STALE.
  Nothing is owed there and no Godot run is needed to generate it.
- The Godot lock was never touched. This run is Blender only - no Godot, no
  claim, no crossing into any lane's window.

## 5. WHAT THIS TOOL STILL CANNOT SEE

Stated because the last section of every honest register should be this one:

- `vis` counts pixels that MOVED, so it answers QUANTITY and never SHAPE. A
  wand grown until a dull shaft clears the arm scores the same as a wand whose
  gem got bigger. Section 1's reason for rejecting 1.20 came from the sheet.
- **No gate in `_t5_margin` asks whether the weapon is still in the hand.**
  Sweep D passed every one of them while floating. If the grip shift is ever
  used for anything, that gate has to exist first.
- The hero is one body, the Knight, in one idle pose. A mage body with a
  different pauldron would occlude the wand differently.
- Nothing here looked at the off-hand, at animation, or at any tier below 5.
