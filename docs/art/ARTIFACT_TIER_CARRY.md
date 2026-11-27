# The artifact tier is carried flat — tier 5 on a body, first measurement

**Art lane, 27 Nov 2026, 16:34–18:1x CT.** Register:
`renders/art/gear_t5/_fit_t5_register.json`. Sheets:
`renders/art/gear_t5/_sheets/t5_front.png`, `t5_side.png`. Tool:
`tools/art/artifactfit.py`. **Verdict FAIL, 13 cells, 0 blanks, 0 blind,
0 laths, 2 frame clips, 1 floor break, 11 lances.**

## What was checked first, by measuring

Before modelling anything: `weaponfit.py` already proved 24 cells GREEN, and
`assets/gear/` already holds the artifact meshes. The 24 are gear.gd `kit[]`
indices 0–2 (common/uncommon/rare). **gear.gd ships FIVE tiers** (`KINDS`,
gear.gd:209-229) and index 4 is the found-only artifact tier wired at S45.
So the tier a viewer spends months of points on had never been rendered on a
body, while the three tiers they get for free had a green sheet.

**Nothing was modelled this run.** All 12 distinct tier-5 meshes already exist
on disk (7 Quaternius `_Golden`, 2 KayKit skeleton props, 3 kit re-uses);
licence `LICENSE_Quaternius_UltimateRPG_CC0.txt` is in the dir. The kind→path
list is parsed out of gear.gd's own `KINDS` so it cannot go stale.

## The finding: no `held_rot` row, so the weapon is carried flat

**11 of 13 tier-5 kinds have no `held_rot` row of their own**, so they fall
through gear.gd's default arm `return Vector3.ZERO` (gear.gd:250-271) and are
carried with their long axis **90.0° from vertical** — the legendary golden
sword sticks out sideways from the hip like a bar. Measured, and visible in
`_sheets/t5_front.png`.

The correspondence is exact and is the proof:

| kind | tier-5 path | `held_rot` | hangs? |
|---|---|---|---|
| bow | `artifact/bow_golden.glb` | **(0,0,90)** — its own row, gear.gd:255 | **yes, upright** |
| crossbow | `SKA/Skeleton_Crossbow.gltf` | (0,0,0) | forward (correct for a crossbow) |
| sword, greatsword, dagger, axe, greataxe, mace, spear, staff, quarterstaff, sceptre, wand | see register | (0,0,0) | **no — 90° flat** |

**The one artifact path anybody wrote a rotation for is the one that reads
correctly.** This is the family `gearcarry.py`'s own docstring named: there is
no hole, the FALLBACK is the answer, and the fallback here is wrong.

**This is not tier-5-only.** `weaponfit` applies identity to its six
non-crossbow/staff families, which is the same carry, so the DUN tiers are
carried flat too and its register is green because **not one of its gates
measures which way a weapon points**. Stated as a strong reading, not a proven
claim: tier 5 is what was measured this run.

## The rotation rule, and a real inconsistency it exposed in weaponfit

Tier 5 is keyed by PATH and has no calibrated basis, so a rule was needed.
**My first rule was wrong and my own gate caught it before a cell was scored.**
Two candidates, each reproducing exactly one of weaponfit's two hand-calibrated
bases:

* `Rslot = C·R·C⁻¹` — matches weaponfit's **staff**, and is identity at a zero
  held_rot, which is what weaponfit ships for its six unrotated families.
* `Rslot = R·C⁻¹` — matches weaponfit's **crossbow**. Residual between them is
  exactly 90° about X.

**weaponfit's two hand-calibrated bases are not the same rule as each other.**
Settled in favour of the first by the glTF importer's conversion being a
*global* basis change — it conjugates every transform, so it cancels in
`bone·R·mesh` — and corroborated by the picture: under the other rule the
sword became a forward lance. **The crossbow divergence is recorded in the
register, not silently patched. It is the crossbow pass's to resolve, it is
NOT mine, and no tier-5 path is scored through it.**

## Wiring the GAME BUILD lane must do — I do not touch gear.gd

**`scripts/gear.gd`, `held_rot()` (gear.gd:250-271): add rows for the tier-5
paths, the way `bow_golden.glb` already has one at gear.gd:255.** The hero
slot's +Y is forward and +X is down, so a shaft/blade built along Godot +Y
wants `Vector3(0, 0, 90)` to stand up — the same value the DUN staff uses
(gear.gd's own note at :245-249). Paths needing a row:
`artifact/sword_golden.glb`, `artifact/sword_big_golden.glb`,
`artifact/dagger_golden.glb`, `artifact/axe_small_golden.glb`,
`artifact/axe_double_golden.glb`, `artifact/hammer_double_golden.glb`,
`gear/halberd.gltf`, `gear/hammer_B.gltf`, `gear/wand_A.gltf`,
`SKA/Skeleton_Staff.gltf`. Re-run `tools/art/artifactfit.py` after; the
`lances` gate goes green when they hang.

## Other faults I can see, named

* **greatsword clips the frame, front and back.** `sword_big_golden.glb` is
  2.73 m before scale; at `hand_scale` 0.60 that is 1.64 m on a 2.45 m hero.
  Likely oversized for the slot as well as flat.
* **bow breaks the floor**: 31 vertices, deepest 0.012 m under it.
* **spear clip 536, staff/quarterstaff clip 414** — the haft runs through the
  body. May resolve when they stand up; re-measure after the rows land.
* `Skeleton_Staff` and `Skeleton_Crossbow` are **bone-white**, not gold. For
  the found-only legendary tier that reads as second-hand rather than as the
  receipt for what a viewer paid for. A judgement for Mr. E, not a defect.
* The `lances` gate flags the **wand** (aspect ≥ 2). A horizontal wand is
  arguably fine; the row is left in rather than tuned away.

## Carried, not re-shot

**The porter's open half stands, from the 15:58 plan row:** the back now
carries corner bosses, hinge straps and bands and is no longer a blank tan
slab, but **the man is still not there from behind** — beside the knight the
porter reads as an ironbound door, not a creature. The 0.1758 → 0.2347 move
remains unexplained and is not banked. Not re-shot this run, by instruction.
