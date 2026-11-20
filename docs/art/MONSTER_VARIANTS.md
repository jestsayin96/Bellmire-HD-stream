# The second class of miniboss — monster-pack variants

Written 19 Nov 2026, 22:5x CT by the ART lane, clock read off the machine with
`TZ=America/Chicago date` (22:52:19 CST). **Part 2 of the supervisor's 21:50 CT
directive**, which carries Mr. E's recipe: take a creature that already exists
in the CC0/QAL packs, recolour it, scale it past its regular version, name it,
give it a mechanic that changes the fight, and fit-proof it on a hero body to
the same standard as the thirty-six procedural minibosses.

**ONE, shipped whole, rather than five half-done** — the row said so and it is
the right instruction for a first pass.

## Broodglut — the first one

| | |
|---|---|
| base | `assets/monsters/Puglin.glb`, Quaternius *Bestiary — Dungeon Monsters Kit*, QAL v1.0 |
| regular version | `puglin` in `bestiary.gd`, `h` 0.90, family `fiend` |
| recolour | the pack author's **own** `T_Puglin_BaseColor_2` (red), swapped for `_1` (olive) |
| scale | **2.60 m — 2.89× its regular version**, 1.06× a hero |
| theme | `mess` |
| idea | **IT EATS ITS OWN** — while any lesser puglin in the room still lives it takes one, swallows it and closes its own wounds. The swarm is its health; the big one is not the target. |
| shipped | `assets/monsters/minibosses/broodglut.glb`, 2.98 MB, 7,528 tris, 55 bones, static (no actions) |

### Why the Puglin and why that red

Mr. E's own example for this class was "a regular Goblin is small and green;
its variant is 1.5× and dark red/black". The Puglin is the nearest thing this
repo has to that goblin, and **the author already drew the red**: measured off
disk this run, the kit ships three base-colour maps per creature and this repo
committed only the first. So the recolour is not a tint over an olive map —
which would have gone muddy — it is a second hand-authored skin over the same
UVs, with the normal and ORM detail untouched. It cost one file swap.

### What the recolour is worth, measured

Same mesh, same camera, same lights, only the map changed
(`--ab`, `renders/art/variants/broodglut/_ab/`):

| | olive (`_1`) | red (`_2`) |
|---|---|---|
| mean rendered rgb | 0.275 / 0.265 / 0.123 | 0.303 / 0.159 / 0.163 |
| green − red | −0.010 | −0.144 |

mean rgb distance **0.134**, and **92.5 %** of the shared opaque pixels move
further than a just-noticeable 0.05. Verdict **SEPARATED UNDER THE FIT RIG**.

**Two honest limits on that number, both found by the instrument contradicting
itself rather than by my eye:**

1. **The verdict's first version could not pass.** It required a green→red sign
   flip in at least half the pixels. The same run reported the *olive* skin's
   green−red as **−0.010** — already red-dominant under the rig — so there was
   no sign left to flip and no recolour could ever have met the bar. That is a
   gate built on an assumption about the art instead of a measurement of it,
   and it is this lane's recurring fault wearing a new coat. Replaced with two
   measured quantities; `sign_flipped_frac` is kept in the record as a reading
   with no power to pass or fail anything.
2. **It is NOT a theme-light test, though I wrote that it was.** The mess key
   (1.00/0.68/0.34) and the crypt key (0.70/0.74/1.00) returned 0.1343 and
   0.1339 — the same answer to four decimals. `lordgen.add_lights` colours the
   **rim** with its third argument; the key is a fixed warm white (1.0, 0.97,
   0.92) no caller can reach. Whether a theme's own key collapses the
   difference is **unanswered**, and answering it means driving the key colour,
   which touches every register this lane has shipped.

### The fit proof — what I looked at, and every fault I can see

`renders/art/variants/broodglut/hero_{front,side,back}.png`, the real KayKit
adventurer at scale 1.0, idle pose, one fixed ground line, rendered by
**minibossfit's own `import_hero` / `place` / `shoot`** rather than a second
harness. Blank check, per-edge frame-border check and the with/without
occlusion test all come free with it, and reuse is the cheaper honesty.

Register: `renders/art/variants/_register.json` — verdict **GREEN**: 0 blanks,
0 frame clips, 3 of 3 proving views, errors `[]`, `room_locked: false`
(widest span 4.10 m against an 11.0 m corridor clear — and that span is a
T-pose, i.e. the worst case, so the verdict errs the safe way).

**What the register cannot see, said plainly:**

- **The sheet shows a REST POSE, not a stance.** The glb carries no actions —
  the pack ships Imp and Puglin rigged and unanimated, and `bestiary.gd` grafts
  the UAL library onto the regular puglin at load. So the arms are out because
  nothing is driving them, and viewers will never see this pose. **The sheet
  proves scale and colour. It does not prove stance.**
- **The front silhouette is unresolved.** Ears, arms and shoulder mass run
  together into one wide dark shape; the **side** view is the one that reads —
  a hunched brute leaning at you with a tusk and a reaching arm.
- **The held stick is nearly invisible** — same hue as the body, small, and it
  will read as nothing at stream distance. It is the pack's prop and I have not
  touched it.
- **The silhouette test the thirty-six pass cannot be passed here, by
  construction.** Throw the colour away and this *is* its own regular version —
  same mesh, same outline. What separates them is **scale and colour**, and
  only scale survives a silhouette. That is a property of the class the
  directive asked for, not a defect in this creature, and the register records
  the scale ratio instead of pretending the test was taken.
- **Height is a judgement I changed by looking.** Pass 1 authored 2.30 and every
  number was green; then the front view showed its head sitting *below* a
  hero's, because this body's height is bulk and not stature. 2.60 is inside
  the band the thirty-six occupy and reads as the bigger thing in the frame.
  One change, re-rendered, looked at again.
- **The frame was widened to 6.40 m for this cell** (the thirty-six use 5.60).
  At 2.60 the T-posed pair spans 5.96 m and the border check went red — 228 px
  of arm off the left edge, 233 off the right. **A clip is not a blank**, which
  is exactly why that check exists. The frame width is recorded in the register
  so nobody compares a 6.40 cell with a 5.60 cell by eye.

### The stray Icosphere is not in the asset, and this lane has said otherwise in three places

Imported raw, the Puglin reports 1.902 × 2.000 × 2.000 — a sphere of radius 1
on the origin, not the creature. Dropping it is right and stays. **The reason
given for it was wrong.** `minibossfit.py`, `e3pogen.py` and
`docs/art/MINIBOSS_FIT.md` all say the glb *ships* a stray Icosphere. Proved
otherwise three ways this run:

1. the string `Icosphere` occurs **zero times** in the 3,124,424 bytes of
   `broodglut.glb`, whose JSON chunk carries 59 nodes and 3 meshes — and that
   file still imports one;
2. a **rigged** pack glb gets one (`Frog.glb` → Armature, Frog, Icosphere);
3. an **unrigged** glb of our own does not (`beadle.glb` → four meshes, clean).

It is a Blender 5.2 glTF-import artifact for any glb carrying an armature.
**It is therefore not in the shipped asset, not in Godot, and not a defect for
the game build lane to chase** — which is precisely where the old wording would
have sent someone. The handling passed; the explanation did not.

### Wiring — the GAME BUILD lane's, not mine

`scripts/bestiary.gd`, beside the existing `silkmother` / `spiderling` block:

```gdscript
"broodglut": {"name": "Broodglut", "path": MON + "minibosses/broodglut.glb",
              "anims": A_UAL, "hp": 2.4, "atk": 1.5, "spd": 3.6, "h": 2.60,
              "lift": 0.0, "family": "fiend"},
```

- `h` **2.60** is the number this register measured; the glb is exported at
  **native** scale on purpose, because `Monster` normalises every body to `h`
  from its own bounds and a pre-scaled mesh would put the size in two places
  that can disagree.
- `A_UAL` because the body is rigged and unanimated, exactly like `puglin`.
- `assets/monsters/minibosses/broodglut.glb` has **no `.glb.import` sibling** —
  it cannot load until a Godot run generates one. Same condition as
  `snarer_chibi.glb`.
- The mechanic is the game build's to implement; nothing here assumes it exists.

### One adjacency, declared rather than hidden

Miniboss 8, **Blisterhand** (ex-Cook), *keeps the pack alive*. Broodglut is that
arrow reversed — the pack keeps **it** alive — so the party's decision is
inverted (kill the adds, not the boss) rather than repeated. If Mr. E reads it
as the same idea twice, the fix is one string and no geometry.

### Licence

Quaternius Asset License v1.0, read off `License_Standard.txt` on disk this run
and not off a search snippet: worldwide, royalty-free, perpetual, commercial
use permitted, no attribution required; the only restriction is reselling or
redistributing the assets **as assets**, which a creature inside our own dungeon
is not. Logged in `docs/art/ASSET_SOURCES.md`.

---

## Pass 3 — 20 Nov 2026, 00:0x CT: the ears

### The fault, and it came from an eye, not a number

The team lead looked at pass 2's `hero_front.png` and wrote the one thing the
register could not reach:

> **IN THE FRONT VIEW THE EARS READ AS A SECOND PAIR OF ARMS.** They leave the
> head at the same angle, the same hue and nearly the same taper as the real
> arms, so the silhouette is a six-limbed shape.

Every number in that register was green — `seen: 1.0` on all six subject/view
pairs, 0 blanks, 0 frame clips, 3 of 3 proving views — because **all of them
ask whether the thing is there and not one asks whether the outline separates.**

### Measured before it was touched

`tools/art/_bg_sil_runs.py` renders the creature alone through a front
orthographic camera and counts maximal vertical runs of opaque pixels per
column. On the shipped glb: **234 of 234 ear columns carried a single run** —
the ear's visible outline rested flush on the arm's upper edge with no
background between them anywhere. Verdict **FUSED**. The eye and the pixels
agree.

`tools/art/_bg_ears_probe.py` then answered how to fix it: **the pack's 55-bone
rig has no ear bone.** All 1531 head-and-ear vertices ride `Head`. So this
could not be a pose and had to be geometry.

### The change — one thing

`ear_turn()` in `tools/art/monstervariants.py` turns each ear about its own
measured root (|x| = 0.20, where the head's vertex count collapses from 394 to
166 per slice) and carries it along the resulting arc. Arc length is preserved,
so the ear keeps the pack author's length and taper and only its **direction**
changes. Shipped at **pitch +40°, yaw +45°** — lifted and swept back behind the
skull.

Chosen over three rivals **by looking at four silhouette sheets**, not by score:
a 60° droop squared the skull off and hung the ears as spikes under the armpits,
which is a worse read than the one it fixed.

| | two-run frac | max gap | height overlap |
|---|---|---|---|
| shipped (pass 2) | **0.000** | 0 px | 0.027 |
| droop 60° | 0.000 | 0 px | 0.273 |
| back 60° | 0.027 | 33 px | 0.031 |
| back 45° / up 30° | 0.560 | 31 px | 0.004 |
| **back 45° / up 40° — shipped** | **0.563** | **49 px** | **0.003** |

### Two instruments of mine failed inside this pass, and both were caught here

1. **The deform could not move the ear.** The first `ear_turn` ramped the turn
   across the whole ear: at yaw 55° the tip travelled 0.089 on a 0.243-long ear
   and `span_y` did not change at all. Four candidate sheets would have come out
   looking alike and invited the conclusion that no deform helps.
2. **The gate passed the known fault.** Mid-pass the gate was moved off the run
   count onto `ear_touches_arm_px`, which read **0 on the shipped glb** — a
   perfect score on the fault. The reason is structural and is written on the
   function: a footprint is what a part *adds* to the outline, so where the ear
   covers the arm that pixel is the ear's and not the arm's, and the two
   footprints are disjoint along exactly the seam where the shapes fuse. The
   harder they fuse, the cleaner the number reads. `height_overlap` failed the
   same way at 0.027. **Only counting runs ever went red on the fault**, so the
   gate is back on the run count and the other two are description.

### A pass-2 defect found on the way, and it is not the ears

Re-rendering at minibossfit's **standard cell (FRAME_W 5.60 m)** cut the *hero*
off at the left border — `frame_edge front {left: 228}`. Pass 2 recorded
`fits_frame: true` with `frame_w: 6.4`: that run used minibossfit's `--frame`
override and **nothing in the register said so**, so it read as a creature that
passed the standard cell. It does not. This pair is **5.96 m** wide, because the
pack body is authored in a T-pose whose 4.10 m arm span plus a hero and the gap
do not fit 5.60 m.

`tools/art/_bg_frame_ab.py` ran the pipeline twice in one process, ears off then
ears on: the clip is **byte-identical both ways**, so it is pass 2's to answer
and not pass 3's. The frame is now widened to hold the pair and the override is
**recorded** — `frame_overridden: true`, `fits_standard_cell: false`,
`frame_w_standard: 5.60` — rather than left to be inferred from a number.

### What the fix does not do

- The body is still a **T-pose**, and that is what the game draws: the shipped
  glb carries **zero animations**, and so does the pack's own `Puglin.glb`
  (measured off both glTF JSON chunks this pass). Nothing was dropped by the
  export.
- The ears still run close to the upper arm on their inboard half — 42 of 96
  columns per side remain single-run. That is the shoulder, and it is correct;
  the fused *read* is gone, the margin is not generous.
- Separation is **necessary and not sufficient**. Two of the team lead's three
  cited cues — hue and taper — are invisible to this instrument. The picture
  stays the verdict.
