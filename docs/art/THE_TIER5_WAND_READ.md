# THE TIER-5 WAND, READ ON A BODY — 27 Nov 2026, 21:3x-21:4x CT

Row: plan 20:58 block, ART — *"SOURCE OR AUTHOR A TIER-5 WAND MESH and close it
the only way this house accepts: on a real posed body, FRONT, SIDE AND BACK,
looked at."*

## WHAT I CHECKED FOR FIRST, MEASURED, BEFORE MODELLING ANYTHING

The row says *source or author*. I checked **source** first and it paid.

- `ls assets/gear/artifact/` — seven golden meshes, **no wand, sceptre, spear or
  staff**. The plan's account of the gap reproduces.
- `scripts/gear.gd:223` parsed, not remembered:
  `"wand": kit = [ADV+wand.gltf, KIT+wand_A.gltf, ADV+wand.gltf, KIT+wand_A.gltf, KIT+wand_A.gltf]`
  — tiers **2, 4 and 5 all resolve to `wand_A.gltf`**, same path, so same scale
  and same rotation. A viewer who spends months of points on a legendary wand is
  handed the common one. Confirmed.
- **AND THE MESH ALREADY EXISTS.** `assets/gear/wand_crystal.glb` — Mr. E's own
  asset (16 Nov 05:03), no third-party rights, already decimated to 7,935 verts
  / 2.38 MB, origin already at the base of the grip, the +30.5 X node
  translation already baked out. `grep` over `scripts/` : **no `.gd` file
  references it.** It has sat in the tree unwired.

So nothing was authored and nothing was downloaded. The tier-5 wand mesh was
already on disk and paid for. What was missing is the wiring and the proof.

## THE GATE I HAD TO OVERTURN FIRST — MY OWN

`_wandfit.py --basis engine` returns **GREEN** on the carry the engine gives
this path today: `clip 0`, no blanks, nothing cut by the frame. I looked at
those three renders. **The GREEN is honest about what it measured and blind to
what matters:** at `held_rot (0,0,0)` × `0.62` the wand lies **horizontal, out
of the hip** — a baton on the front view and a single blue dot on the side.

`_wandroll.py` then swept the one family weaponfit can derive, and the sweep is
a trap rather than a choice: **clip and reach trade off monotonically.** The
only `clip == 0` row is `(0, 90, 90)`, where reach collapses to 0.046 — the
same horizontal baton, rolled the other way.

So I measured **the control my clip gate never had** (`tools/art/_wandscale.py`),
reading each carry out of `gear.gd` through `gearcarry` rather than typing it:

| control (SHIPPED weapon, at its real carry) | held_rot | scale | clip |
|---|---|---|---|
| `staff_B.gltf` | (0,0,0) | 0.62 | 51 / 883 = **5.8%** |
| `dungeon/staff_rare.glb` | (0,0,90) | 1.9 | 202 / 890 = **22.7%** |

**`clip == 0` was never the standard.** It is a number this lane's own harness
invented, and it has been rejecting carries *better than the ones already
shipping*. A held shaft grazing the forearm is normal in this game. The control
is the bar now; blanks, blind views, border and ground still gate hard.

## THE SECOND FAULT, AND IT IS MINE AND IT WAS CAUGHT BY THE PICTURE

Pass 1 of `_wandcarry.py` shipped **no render setup**, so Blender used its own
default 1920×1080 — while `WF.frame_outside` derives the frame half-height from
`FRAME_H` and the **intended** `CELL_X/CELL_Y` aspect. At 1920×1080 an
`ortho_scale` of 3.80 spans the *width*, so the real vertical field was
3.80 × 1080/1920 = **2.14 m against a 2.45 m hero**. The body was cut at the
belt in every frame and `frame_clipped` still reported `[]`.

I saw the crop in the picture, not in the number. Same family as the pass-11
mask fault: **an instrument that cannot see is not a pass.** Fixed two ways —
the resolution is set, and the omission is now *unrepeatable*: the file asserts
the scene resolution matches `CELL_X/CELL_Y` at 100% and exits if it does not,
because the border check is only meaningful when the pixels it reasons about
are the pixels that were rendered. Every number below is from the re-render.

## THE CANDIDATES, RENDERED ON A POSED BODY AND LOOKED AT

Hero 2.45 m, `handslot.r` at (-0.491, -0.107, 0.641). All five pass the hard
gates: **0 blanks, 0 blind views, 0 frame clips, 0 ground** — and the border
check now has the resolution assertion behind it.

| name | held_rot | scale | clip | reach | tip_z |
|---|---|---|---|---|---|
| `now_horizontal` (what ships today) | (0,0,0) | 0.62 | 0 (0.0%) | 0.046 | 0.686 |
| `up_roll00` | (0,0,90) | 0.62 | 1370 (23.0%) | 0.571 | 1.211 |
| **`up_roll15`** | **(0,15,90)** | **0.62** | **1177 (19.8%)** | **0.551** | **1.192** |
| `up_roll45` | (0,45,90) | 0.62 | 482 (8.1%) | 0.405 | 1.046 |
| `wandlen_roll45` | (0,45,90) | 0.45 | 477 (9.3%) | 0.294 | 0.935 |

`moved` pixels is **not** the discriminator and I did not use it as one: the
*worst* carry scores highest on it (front 4113) because a baton held clear of
the body casts a large shadow. The diff answers "did anything change", not "can
the viewer see the thing". The eye decided.

**WHAT I SAW.**

- **`up_roll15` front and back — good, and a large improvement.** The wand
  stands upright beside the body, a clean vertical shaft from the fist past the
  shoulder with the blue crystal level with the chin. It reads as a wand. Its
  19.8% clip is **below the shipped `staff_rare`'s 22.7%**.
- **`up_roll15` side — WEAK, AND THIS IS THE REAL FAULT.** The shaft is almost
  entirely occluded by the torso. Only the silver collar and a hint of crystal
  survive; from that angle the hero reads as empty-handed.
- **`up_roll45` side — WORSE.** The lower clip bought invisibility: a blue
  speck at the chest. Rolling forward moves the tip *behind* the torso line.
- Every carry: the dark shaft is low-contrast against dark armour. Only the
  crystal and the pale collar carry the read at stream distance.

## THE CAUSE, AND THE DECISION THAT IS MR. E'S AND NOT MINE

The side view **cannot be fixed by the carry**, and the sweep is what proves it
rather than my opinion. The slot is at the hip; a thin 0.57 m shaft held near
the body's own plane is occluded by the torso from a side camera at every roll.
To clear the silhouette the tip must pass the head, which needs reach ≈ 1.66 —
`hand_scale` ≈ 1.8, which is the **staff's** own scale.

**So the measurement answers the question `ASSET_SOURCES.md` has carried open
since 16 Nov: `wand_crystal.glb` is a SHORT STAFF, not a wand.** At any scale
small enough to read as a wand it cannot clear the torso side-on; at the scale
where it reads from every angle it is a staff. I am not asking a question a
picture would answer — the pictures are in `renders/art/wand/` and they say it.

**I still recommend shipping it as the tier-5 wand now**, because it is
strictly better than today in all three views, it costs one line, and it ends
the pixel-identical tier-5. The genuine decision for Mr. E, and the only one:

> **Should `wand_crystal.glb` be the tier-5 WAND (ships now, weak side view), or
> the tier-5 STAFF — where its length is an asset and it would displace
> `Skeleton_Staff.gltf` — with a purpose-built shorter wand authored later?**

## WIRING THE GAME BUILD MUST DO — `scripts/gear.gd`, NOT MINE, I DID NOT TOUCH IT

Two changes. **Neither can reach the common wand**, by construction: both
accessors key on **path**, and `wand_crystal.glb` is a different path from
`wand_A.gltf`. This is the trap the 20:58 plan warned about and it is avoided
here by not raising anything for `wand_A.gltf`.

1. **`KINDS["wand"]`, line ~223** — tier-5 slot only, `kit[4]`:
   `KIT + "wand_A.gltf"` → `KIT + "wand_crystal.glb"`
2. **`held_rot()`, lines ~250-271** — add an arm *before* the `Vector3.ZERO`
   default, matched on `wand_crystal`:
   returns `Vector3(0, 15, 90)`

**`hand_scale()` needs NO change.** `wand_crystal.glb` already resolves to
**0.62** through the existing `begins_with(KIT)` arm — read off `gear.gd` with
`gearcarry`, not assumed. Do not add an arm for it.

Not fixed by this and not claimed: **tiers 2 and 4 are still both
`wand_A.gltf`.** This row closes tier 5 only.

## FILES

- `tools/art/_wandscale.py` — the control + the sub-0.62 scale grid (new)
- `tools/art/_wandcarry.py` — candidate carries rendered on the body, with the
  resolution assertion that keeps the border check honest (new)
- `renders/art/wand/_scale_sweep.json`, `_carry_report.json`
- `renders/art/wand/{now_horizontal,up_roll00,up_roll15,up_roll45,wandlen_roll45}/{front,side,back}.png`

## A FAULT OF MINE IN THIS DOCUMENT, CORRECTED IN THE NEXT COMMIT

The first version of this file, and of the `ASSET_SOURCES.md` paragraph, and the
commit message at `a4386025`, all stamped this work **`~22:4x CT`**. The machine
reads **21:44:46 CST**. That is a **future stamp by a full hour** — the exact
fault this prompt warns about and several lanes have now committed. I was
tracking elapsed minutes in my head and carried an hour I never read. The run
started at a clock-read `21:34:26 CST`; the Blender outputs are stamped
`Nov 28 03:4x UTC`, which is `21:4x CST` (November is CST, UTC **minus 6**).
Nothing about the measurements or the pictures changes — only the stamp was
wrong. `a4386025` is pushed and is not being rewritten; this is the correction
on top, which is the house rule.
