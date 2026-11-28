# TIER-5 LEGENDARY CARRY - THE PER-WEAPON PRESCRIPTION

ART lane, 27 Nov 2026, written 17:54 CT (clock read off cruzader with
`TZ=America/Chicago date`). Closes the red artifactfit raised against its own
tier-5 register: `verdict: "FAIL"`, 11 of 13 in `lances`, 2 `frame_clips`,
1 `floor_break`.

**THIS IS A PRESCRIPTION, NOT A FIX.** Every change below is in
`scripts/gear.gd`, which belongs to the GAME BUILD lane. Nothing in gear.gd was
edited by this run. The engine half is the other half of the same item.

Instruments, both new this run and both in `tools/art/`:
`_t5_rx.py` (searches and solves) and `_t5_rxproof.py` (renders and gates).
Data: `renders/art/gear_t5/_rx/_t5_rx.json`, `_t5_rxproof.json`,
cells in `_rx/cells/`, contact sheets in `_rx/_sheets/`.

## 1. THE CAUSE, IN ONE LINE

`gear.gd::held_rot()` has a row for `DUN + "staff_"`, for `ART + "bow_golden.glb"`
and for `DUN + "crossbow_"`, and every other kind falls through to
`return Vector3.ZERO`. The artifact-tier meshes are built along their own long
axis with no rotation, so a zero `held_rot` lays them along the slot's own long
axis, which is world HORIZONTAL. Eleven legendary weapons were couched across
the chest like lances. The two that read correctly are the two with rows.

**AND A SECOND CAUSE THE EULER DOES NOT TOUCH.** Standing them up with a single
Z term made every one of them WORSE on `clip` - dagger 0 -> 112, greatsword
0 -> 343, mace 157 -> 454. These meshes carry their origin at the weapon's
MIDDLE, not at the grip, so rotating about it drives the lower half down through
the hip, the thigh and the cape. It is the same fault as the bow's
`floor_break`: the bow already carries `(0,0,90)`, already reads correctly, and
its 31 sub-floor vertices are its own lower limb buried in the ground.

So each row below has up to two parts: a rotation, and a grip shift using the
mechanism gear.gd ALREADY SHIPS - `const STAFF_GRIP_SHIFT := 0.25` applied as
`.position.x -= STAFF_GRIP_SHIFT`, today gated to the DUN staff family alone.
`position` is in the PARENT (slot) frame and the slot's +X is world DOWN
(gear.gd:245-249, re-measured by the basis selftest on every run), so a
NEGATIVE x offset RAISES the weapon in the fist.

## 2. THE PRESCRIPTION

Euler order YXZ, degrees, as `held_rot` already returns. `grip x` is the
slot-frame x offset in metres; `0.000` means no shift is needed.

| kind | model | held_rot now | held_rot PRESCRIBED | grip x | hang now | hang rx | clip now | clip rx | floor now | floor rx | proving | show |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| axe | `assets/gear/artifact/axe_small_golden.glb` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 150 | 226 | 0 | 0 | 3/3 | 1.002 |
| bow | `assets/gear/artifact/bow_golden.glb` | [0.0, 0.0, 90.0] | **[0.0, 0.0, 90.0]** | **-0.572** | 0 | 0.1 | 451 | 224 | 31 | 0 | 3/3 | 1.002 |
| crossbow | `addons/kaykit_character_pack_skeletons/Assets/gltf/Skeleton_Crossbow.gltf` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 0.0]** | **+0.000** | 90 | 89.9 | 108 | 108 | 0 | 0 | 3/3 | 0.999 |
| dagger | `assets/gear/artifact/dagger_golden.glb` | [0.0, 0.0, 0.0] | **[-90.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 0 | 112 | 0 | 0 | 1/3 | 1.077 |
| greataxe | `assets/gear/artifact/axe_double_golden.glb` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 82 | 344 | 0 | 0 | 3/3 | 1.004 |
| greatsword | `assets/gear/artifact/sword_big_golden.glb` | [0.0, 0.0, 0.0] | **[0.0, 0.0, -90.0]** | **-1.470** | 90 | 0.1 | 0 | 136 | 0 | 0 | 3/3 | 1.039 |
| mace | `assets/gear/artifact/hammer_double_golden.glb` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 157 | 512 | 0 | 0 | 3/3 | 1.059 |
| quarterstaff | `addons/kaykit_character_pack_skeletons/Assets/gltf/Skeleton_Staff.gltf` | [0.0, 0.0, 0.0] | **[0.0, 0.0, -90.0]** | **-1.175** | 90 | 0.1 | 414 | 160 | 0 | 0 | 3/3 | 0.989 |
| sceptre | `assets/gear/hammer_B.gltf` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 162 | 169 | 0 | 0 | 3/3 | 1.008 |
| spear | `assets/gear/halberd.gltf` | [0.0, 0.0, 0.0] | **[90.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 536 | 438 | 0 | 0 | 3/3 | 0.992 |
| staff | `addons/kaykit_character_pack_skeletons/Assets/gltf/Skeleton_Staff.gltf` | [0.0, 0.0, 0.0] | **[0.0, 0.0, -90.0]** | **-1.175** | 90 | 0.1 | 414 | 160 | 0 | 0 | 3/3 | 0.989 |
| sword | `assets/gear/artifact/sword_golden.glb` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 93 | 232 | 0 | 0 | 3/3 | 1.029 |
| wand | `assets/gear/wand_A.gltf` | [0.0, 0.0, 0.0] | **[0.0, 0.0, 90.0]** | **+0.000** | 90 | 0.1 | 17 | 103 | 0 | 0 | 2/3 | 1.058 |

`staff` and `quarterstaff` resolve to the SAME model. Note that gear.gd's
existing staff row keys on `DUN + "staff_"`, and the artifact-tier staff is
`addons/kaykit_character_pack_skeletons/.../Skeleton_Staff.gltf`, which does not
begin with that prefix - that is precisely why it falls through to ZERO.

## 3. WHAT THE PRESCRIPTION CLOSES, MEASURED

Re-run through the SAME gates that found the red, not a kinder set
(`_t5_rxproof.json`):

| gate | shipped register | after the prescription |
|---|---|---|
| `lances` | **11** | **0** |
| `floor_breaks` | **1** (bow) | **0** |
| `frame_clips` | **2** (greatsword front, back) | **0** |
| `blanks` | 0 | 0 |
| `laths` | 0 | 0 |
| `blind_views` | 0 | **1 (dagger)** |
| `errors` | 0 | 0 |

The greatsword's two frame clips closed WITHOUT touching the camera: the clip
was a 2.73 m blade held horizontally across a frame fitted to a 2.45 m hero.
Stood upright with its grip in the fist it fits, and the border alpha on all 39
renders is 0.0.

## 4. THE ONE ROW STILL RED, AND IT IS NOT A ROTATION

**dagger: 1 of 3 views proving.** The carry is geometrically right - upright,
point up, hang 0.1 deg - and the picture says why the gate fails: it reads as a
gold wire. `vis` is 403 px front, 957 side, 190 back against `VIS_MIN` 900.
Its `show` is 1.077 and PASSES, because `show` is a ratio against the weapon's
own mid axis and is blind to absolute size; `VIS_MIN` is the gate that caught
it, and it is right.

This is a `hand_scale` prescription, not a `held_rot` one. gear.gd carries the
dagger at **0.5**. Visible area scales as the square of linear scale, so the
front view needs `0.5 * sqrt(900/403)` = **0.75** to clear `VIS_MIN`, which also
takes the side view to ~2150 px. **0.75 IS AN ESTIMATE FROM A SCALING LAW, NOT A
MEASUREMENT** - occlusion is not linear, so it must be re-proved on a body
before it is believed. The ART lane owes that proving pass; it is not asserted
here.

## 5. THE BASIS QUESTION, SETTLED

`_t5_axisab` found weaponfit's two hand-calibrated bases translating the same
gear.gd euler triples by two different rules - `C.R.C^-1` for the staff,
`R.C^-1` for the crossbow - and could not choose between them. It is settled,
and not by preference:

**RULE A, `Rslot = C . R_godot . C^-1`, IS THE ONLY RULE THAT CAN BE A READING
OF A GODOT EULER.** A change of basis for a rotation is a similarity transform;
`R . C^-1` is not one. The decisive test is the identity: at `held_rot` ZERO,
rule A is 0.00 deg from identity and rule B is **90.00 deg** from it. gear.gd's
`return Vector3.ZERO` must mean "no extra rotation on the slot", and rule B
turns it into a 90-degree one. artifactfit's register corroborates empirically:
under rule A all eleven zero-rotation weapons land on one shared world axis,
which is what a no-op correction looks like.

**SO WEAPONFIT IS WRONG IN EXACTLY ONE PLACE AND HERE IT IS.** Measured against
each family's own calibration triple:

| family | `SLOT_ROT_CAL` | residual vs rule A | residual vs rule B |
|---|---|---|---|
| staff | `(0, 0, 90)` | **0.00 deg** | 90.00 deg |
| crossbow | `(-90, 0, 90)` | 90.00 deg | **0.00 deg** |

`weaponfit.SLOT_ROT["staff"]` is correct. **`weaponfit.SLOT_ROT["crossbow"]` is
wrong by 90 degrees about the slot's -X**, and its calibration constant absorbed
exactly that error, so the two cancel for the crossbow and only for the
crossbow. That is why nothing caught it. It is the same fault weaponfit's own
comment already confesses as FAULT 6 - "the table above is a PHOTOGRAPH, NOT A
LINK" - one layer deeper: the ROLL got linked in November, the BASIS stayed a
photograph.

**AND MY OWN A/B INSTRUMENT ASKED THE WRONG QUESTION.** `_t5_axisab` scored both
conventions at `WF.SLOT_ROT_CAL[fam]`. A calibration constant only means
anything inside the rule it was fitted under, and the crossbow's was fitted
under B - so the A column for the crossbow was asking "does rule A reproduce a
constant fitted under rule B?", to which 81.3 deg is the correct answer and the
wrong question. The tell was in the log and I did not read it: A good / B bad
for the staff and exactly mirrored for the crossbow, both at 81.3 and 8.7, is
the signature of a 90-degree offset in ONE calibration constant, not of a
genuine ambiguity in the rule.

**`_t5_axisab` HAS A SECOND FAULT AND SHOULD NOT BE TRUSTED AGAIN.** Its
`meshX_prod` / `meshY_stock` / `meshZ_thin` labels are unit vectors pushed
through `base @ R`, which are IMPORT-WORLD axes, not the mesh's authored axes -
the glTF importer's Y-up to Z-up conversion sits in the mesh's own
`matrix_world` and is not in that product. That is why `thin_vs_up` read 0.1 in
all four cells: a metric that does not move across two conventions and two
families was not measuring what its name claims. It is the third generation of
the label fault `_t5_slotframe`'s docstring already confesses twice. The algebra
in this section replaces it.

Nothing tier-5 uses weaponfit's crossbow basis, so nothing shipped is wrong
today. The correction belongs to the crossbow's own next pass.

## 6. WHAT THE PICTURE SAYS THAT THE NUMBERS DO NOT

Sheets at `renders/art/gear_t5/_rx/_sheets/rx_{front,side,back}.png`, looked at.
Thirteen knights, every weapon upright at the hand, no lances. Faults I can see
that every gate above rates GREEN:

- **sword and greatsword read as a bare stick from the front.** The blade rises
  directly behind the arm and shoulder, so only a narrow strip clears the body
  silhouette. `clip_frac` 0.344 and 0.101, `show` 1.029 and 1.039 - both green,
  and a viewer who spent months of points on a legendary greatsword sees an
  edge. They want a small OUTWARD cant so the blade clears the shoulder. I have
  not guessed one; it needs its own measured pass.
- **wand reads only marginally** - 2 of 3 proving, the bare minimum, and
  visually a thin line. Same family as the dagger, one notch above the gate.
- **crossbow is the smallest silhouette on the sheet.** Unchanged by design.
- **every one of the thirteen hugs the body's left edge.** None is held clear of
  the silhouette. That is a property of the slot, not of any one weapon.

## 7. A DEFECT IN MY OWN NEW INSTRUMENT, FOUND BY LOOKING

The first contact sheet `_t5_rxproof` wrote came out with **every knight upside
down**, while the cell PNGs Blender saved straight to disk were upright. The
sheet writer applied an extra vertical reverse; `WF.render_to` already returns a
top-down array. Fixed in the same run. Worth recording because a sheet that
turns the figure over is exactly the instrument that would make a correct carry
read as a bad one - the cells were the evidence and the sheet was the suspect,
and the only reason I caught it is that I looked at both.

## 8. THREE TIMES MY OWN GATE WAS THE FAULT, NOT THE GEOMETRY

Recorded because the first two would have shipped a wrong answer:

1. **Pass 1 gated `clip == 0` and `broad >= 0.70`, and ZERO of 1248 candidates
   passed for ANY of the 13 kinds.** An instrument that cannot pass anything has
   not measured anything. The shipped register never gated `clip` at all - it
   carries clip 150, 451, 536 and still reports only lances/floor/frame.
2. **`broad` was not the quantity I named it.** A fraction that cannot exceed 1
   was reading 1.57, 2.75, 3.71. It is now reported as `proj_minor_ratio` and
   gated on nothing; the real `show` comes from a render.
3. **Pass 3's `clip_no_worse` rewarded the defect.** The dagger's and
   greatsword's current clip is 0 PRECISELY BECAUSE they are held out
   horizontally at arm's length, where a weapon barely touches the body. A
   baseline contaminated by the fault being fixed is not a baseline. The ceiling
   is now absolute and calibrated off the one cell confirmed correct by eye: the
   bow at its shipped `(0,0,90)` buries 451 of 1218 checked vertices = 0.370, so
   nothing may bury more than that fraction.

And one more, caught by the sort rather than the gate: **pass 3 prescribed the
BOW a move away from `(0,0,90)`** - the one carry the team lead confirmed by eye
- because launchers skip the upright gate, so a horizontal bow "passed" and
sorted simpler. gear.gd's own triple now wins every tie. A prescription that
changes a carry already known to be right is worse than no prescription.

## 9. WIRING THE GAME BUILD LANE MUST DO

File: **`scripts/gear.gd`**. Nothing else. ART does not edit it.

1. **`held_rot()`** - add a row per kind from the table in section 2, keyed on
   the artifact-tier paths listed there. Nine of the thirteen want
   `Vector3(0, 0, 90)` or `Vector3(0, 0, -90)`, the same single term the staff
   and bow rows already carry.
2. **The grip shift** - generalise `STAFF_GRIP_SHIFT` from one constant gated to
   `DUN + "staff_"` into a per-path lookup, and apply the four non-zero `grip x`
   values: bow -0.572, greatsword -1.470, quarterstaff -1.175, staff -1.175.
   Keep the application site and sign convention exactly as they are
   (`.position.x -= v`, slot frame, slot +X is world down) - those are what
   these numbers were solved against.
3. **`hand_scale()` for the dagger**, 0.5 -> ~0.75, ONLY after ART's proving
   pass confirms it. Do not take 0.75 from this document as measured.
4. **Nothing else.** `weaponfit.SLOT_ROT["crossbow"]` is an ART-side tool fault
   (section 5) and no engine path uses it.

When these land, `artifactfit --tier 5` should come back GREEN but for the
dagger row, and ART re-runs it to confirm rather than assuming.
