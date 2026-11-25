# THE COLLIER (Halfblow) - the 62nd miniboss, and my own fix hid the count it was built to show

**Lane:** art. **Built:** 25 Nov 2026, 03:35-04:1x CT. **Branch:** `art`.
**Plan row:** the 02:58 CT 25 Nov TAKE THIS NEXT block - *"ART (:34) - THE 62nd
BODY, OR A WRITTEN STAND-DOWN THAT SAYS WHICH."*

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

| measured | where | value |
|---|---|---|
| `ORDER` | `minibosses.py`, initial literal + every `ORDER = ORDER + [...]`, parsed with `ast` | **61 entries, 61 distinct**, last `timberman` |
| `CANON` | every `CANON.update({...})`, parsed with `ast` | **75 rows** = 61 live + 14 retired `_chibi`/`_tall` |
| all 61 `idea` strings | read in full **before** designing | see NOT-THIS below |
| `collier` | grep of the whole key space | **absent** - this trade is not already made |
| bone/body luminance | the generator's own formulae, run on paper before a vertex was placed | **1.34** - answered in `OVERRIDE` |

So this is the **sixty-second base**. My own prompt says "THIRTY-THREE already
exist"; it is stale by twenty-nine and the measurement, not the argument,
corrects it.

**THE PACKS RULE WAS APPLIED AND IT DID NOT SERVE.** The body is one earth heap
and one short man. The packs hold rocks, logs, planks and barrels in quantity -
nothing in them is a *staked, earthed charcoal clamp*, and a pack rock dropped
in at full fidelity would have arrived with its own material budget against this
file's four. Procedural, per rule 4.

## THE IDEA, AND WHY IT IS NOT A RE-SKIN

**YOUR OWN HEAVY BLOW IS WHAT OPENS IT.** A charcoal burner's clamp is wood
earthed over and lit inside, and the whole trade is keeping it *shut*. Every
blow the party lands lands in full - nothing is absorbed, nothing is immune -
but a blow bigger than a measured stroke **bursts a vent and the flare takes the
whole room**. The party's heaviest hero is the liability and its lightest is the
asset, every round, for the whole fight. Second answer, on the body: four pale
plugs in a cradle, countable from the doorway. Drive them home and the cap comes
off.

**THE TWO NEAREST NEIGHBOURS ARE A SIBLING AND A MIRROR AND I AM NAMING BOTH
RATHER THAN HOPING NOBODY NOTICES.**

- **The TIMBERMAN (61st) shipped ONE HOUR before this.** Both bodies make the
  party's own damage a hazard, so this is the closest call in the file. The
  daylight: there the **killing** blow is the hazard - one event, once, at the
  end, countered by *preparation*. Here no single blow ends anything and the
  kill is ordinary; what is constrained is the **size** of every blow,
  continuously, countered by *who swings*. The timberman reorders the end of a
  fight; this reorders the attack economy from round one.
- **The DREDGER (57th) is the exact mirror.** It "only feels what gets through
  the mesh" - a damage FLOOR where a small blow does nothing. This is a
  CEILING, and no blow is ever nullified: full damage always lands and the cost
  is paid by the room. A dredger punishes your weak hero; this punishes your
  strong one.
- Also named off in the builder docstring: **strickler** (changes the hero, not
  the choice), **pledgeman** (a price, not a hazard), **stoker** (the fire is
  its strength, not its danger), **scrapwright** (the other mound - angular
  torn plate, on legs, and it grows), **panner** and **nightman** (state
  windows; this body is open to be hit at every instant).

## SIX PASSES, AND WHAT EACH ONE WAS FOR

Every pass rendered `ok true`, 0 blanks, 0 errors. **Every fault below was found
by looking at the picture.** Not one of them raised a number.

- **Pass 1** - built. The four vents - the *one* emissive cue, and the mechanic
  itself - rendered as **flat cream discs at the same value as the four pale
  plugs**. The body shipped eight pale dots and nothing lit: both halves of my
  own FAULT 9 and FAULT 10, in the first render, in the file where I had just
  written them down. And the whole thing read as **a hooped bell skirt with a
  man in it**.
- **Pass 2** - five separable fixes, judged one at a time in one render. Glow
  deepened and weakened (1.00,0.30,0.06 at 1.15) - **worked, the vents are
  fire**. Plug bundle narrowed from 0.62 m to 0.35 m - **worked**, it had been a
  four-bar fence laid across the whole mound on the side camera, because I
  answered the front camera's question and asked the side nothing. Haft
  overshoot 0.270 -> 0.105 - **worked**, it had run past his jaw. Left arm
  rebuilt on four points - **worked**. Sods and a crown shelf on the mound -
  **did not work**.
- **Pass 3** - the skirt. The cause was an interaction I built myself: **a body
  of revolution with three horizontal iron ribs round it is a crinoline** -
  that is what a crinoline is, and the hoops were the best-reading objects on
  the body selling the wrong word. Eight **vertical stakes** and one lashing
  ring instead of three rings; a **spoil tail** out to y +1.02, because a skirt
  has no tail; the man stepped 0.21 m forward off the apex. **The side camera
  was answered. The front camera was untouched** - every one of those changes
  lives in Y.
- **Pass 4** - the apex walks 0.26 m to +X so the front silhouette is a heap
  with a high side and a low shoulder. **The skirt is gone on both cameras.**
  Stakes pushed proud of the earth they had been sitting *inside*.
- **Pass 5** - **and pass 4 had hidden the count.** Walking the apex put the
  mound's new high shoulder directly in front of the plug bundle: one pale
  sliver where four countable billets belong. *A fix that moves a mass must be
  re-asked what that mass now covers.* I did not ask; the render did. Bundle
  crossed to the low shoulder, vent arc swung clear of the shovel (the fourth
  vent had been behind the blade, so the ember count read three), and the stake
  heads reseated - my own pass-4 drift had walked them off the earth into open
  air, a free end introduced while fixing something else.
- **Pass 6** - **found only on the hero sheet, which the orthos cannot show.**
  Beside a KayKit knight the head read as **a pot with a lid on it**. Head
  bigger, hat tapering up into a crown narrower than the skull with its brim on
  -Y only. Partly worked - see the fault list.

## THE NUMBERS, MEASURED ON THE SHIPPED BUILD

`minibossgen --only collier`: `ok true`, errors `[]`, blank `[]`, **4 meshes /
2,417 faces**, span **2.16 m CORRIDOR-SAFE** (corridor 11.0 m), **UNDER-LID**.
At **2.10 m** it is one of the shortest bodies in the house and the widest-to-
tallest of any of them.

`minibossfit --only collier`: **verdict GREEN, ok true, 64 rows, errors `[]`**,
`blind_views []`, `unproved_cells []`, `stale_margin []`, `red_summary.rows []`.
For this row: `creature_h` 2.10, `hero_h` 2.45, **ratio 0.86** (it is SHORTER
than a hero - the first body in some time that is), `pair_w` 3.90, `air_x`
1.659, `margin_x` 0.12, `fits_frame` true, **3 proving views**, `seen` 1.0 for
creature and hero on all three, **every `frame_edge` and `frame_edge_disk` zero
on front, side and back**, `air_px_min` **102**, tightest view `side`.

`_backread --keys collier` - the viewer's question, rendered with and without
the man through one camera, counting the pixels that MOVED: **man_seen front
0.9914, side 0.9745, back 0.9966** against the house bar of 0.75, errors `[]`.
The census was re-run FIRST (64 register rows, `pairs in NO list: 0`) and the
row is merged into `_selfseen_all.json` row-by-row with its own `measured_at`.

**THE FIT REPORT WENT RED TWICE BEFORE IT WENT GREEN AND BOTH WERE RIGHT.**
First *"in the register and in NO self_seen census list"*, then *"MEASURABLE and
carrying NO self_seen cell - an unasked instrument is RED, not green"*. Neither
was worked around. A third red was mine and earlier: `_backread` refused the
body for *"no `man` span and no `man_parts`"*, correctly, and the first
declaration I wrote put the **shovel** inside the man - which is the dyer's
fault exactly, counting the apparatus as the figure it is supposed to be hiding.
The right arm was split out into its own span and `man_parts` is
`("trunk", "head", "arms_r", "hand")`, with **no `legs`, because this body has
none**.

**`_selfseen_all.json` `ok` is false and it is NOT this body.** It was false
before this run on `panner: the man span merged to no object` - verified against
the file, not asserted. My merge added one row and changed nothing else.

## WHAT I CAN SEE THAT IS STILL WRONG

Looked at on the hero sheet at hero scale, front, side and back:

1. **The head still half-reads as a pot.** Pass 6 improved it and did not
   finish it: a round skull with no neck under a tapered dark crown is a jar at
   stream distance, and the face is gone by then. This is the first fault to
   take on a pass 7.
2. **The side camera is the weak view for the mechanic.** One ember shows at
   the mound's edge and the plug bundle goes nearly edge-on behind the front
   face. The count is a **front cue by construction** and the side carries the
   silhouette instead.
3. **The back carries no cue at all** - by design (all four vents are on the -Y
   arc, which is the facing) but worth the game build lane knowing: a party
   arriving from behind sees a heap and a man, not the mechanic.
4. **Three of the four embers read cleanly on the front; the fourth is partly
   behind the mound's own left flank** depending on the camera's yaw. Pass 5
   moved it off the shovel and the flank took a piece of it back.
5. **The stakes read as a lattice of dark sticks at hero scale** rather than as
   driven withies - they do their job (they killed the crinoline) but they are
   the least articulated thing on the body.
6. **The shovel is thin at hero scale.** Its blade reads; its haft nearly
   disappears against the earth.
7. **The man's torso is a visible stack of three spheres** - a barrel-banding
   that shows on the front ortho at full size.

No clip, no float and no bad anchor that I can see: the plugs are seated with
`seat()`, the stake feet are in the earth, the spoil tail sits on the floor, the
shovel terminates in a socket and a blade, and the body carries its own ground
shadow on all three views with `shadow_edge` zero.

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT TOUCH ANY OF IT

- `scripts/bestiary.gd` - add a row for `collier` with
  `model: "res://assets/monsters/minibosses/collier.glb"` and **NO `anims`
  entry**: static, no armature. `h` 2.10 is the authored height and is what the
  0.86 ratio was measured at.
- `scripts/delve.gd` - `MB_FIT` ratio **0.86**, COPIED from
  `_fit_report.json` `pairs.collier.ratio`, not re-derived. `MB_NAME` entry
  **"Halfblow"**, which is CANON (`tools/art/minibosses.py`). Theme row:
  **`wood`**. And the five sibling `MB_NAME.size()` literals move together -
  `_s51_names.gd:64`, `_s117_straker.gd:33`, `_s124_pledgeman.gd:31` are plain
  `== N`; `_s107_gate.gd:39-43` binds a variable first and `_s126_crimp.gd:31`
  is a parenthesised conditional, so a flat regex finds three of five.
- It is **NOT room-locked**: span 2.16 m against an 11.0 m corridor,
  `UNDER-LID`, `fits_frame` true.
- Nothing else. I did not edit a `.gd` file and I did not tick a plan row.
