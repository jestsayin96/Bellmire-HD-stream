# ART lane measured audit - 19 Nov 2026, 17:0x-17:3x CT

THIS FILE IS UNCOMMITTED. The Blender bridge was down for the whole run, and that bridge
is this lane's ONLY path to git. The next ART firing must commit it.

## RUN-BLOCKING FAULT

1. `mcp__remote-devices__Blender__execute_blender_code` refused every call (5 attempts,
   17:01-17:3x CT): "Cannot connect to Blender at localhost:9876". No Blender, no Godot,
   no git, no push this run.
2. Only `C:\hd adventure\bellmire-art` is a connected folder this session - NOT the parent
   `C:\hd adventure`. So the main repo (R) and `_packs` are unreachable from the Linux
   bridge, and `git -C W5` fails there by construction (.git points to
   `C:/hd adventure/jests-hd-medieval-adventure/.git/worktrees/bellmire-art`, outside the
   mount). Per the standing rule, folder access was NOT requested.
   Consequence: the authoritative `origin/main:docs/WORK_PLAN.md` could not be read. The
   TAKE THIS NEXT block below was read from the WORKTREE copy and may be superseded.

## PLAN ITEM FOR ART (worktree copy, block written 18 Nov 20:0x CT)

Both halves need a render, so neither could be executed this run:
  (a) `limb()` slot default -> pale-mass fault. Sower head+hat front 0.039 / three_quarter
      0.019; moulder head front 0.001 / side 0.017.
  (b) "re-render sower hero_{front,side,back}.png" - SEE CORRECTION BELOW.

## MEASURED FINDINGS

### 1. THE SOWER RE-RENDER ROW IS ALREADY ANSWERED - DO NOT RE-RENDER
The team lead's row says the canonical trio is older than the model. Measured mtimes:
    assets/monsters/minibosses/sower.glb        18 Nov 19:48:28 CST
    renders/art/minibosses/sower/hero_front.png 18 Nov 20:51:03 CST  (+63 min)
The trio was re-rendered 63 minutes AFTER the model changed, which is ~51 min after the
row was written. The row was stale on arrival. Nothing to do.

### 2. GREENER'S CANONICAL TRIO IS GENUINELY STALE - NOBODY HAS FLAGGED THIS
    assets/monsters/minibosses/greener.glb       18 Nov 00:51:02 CST
    renders/art/minibosses/greener/hero_*.png    17 Nov 22:52:58 CST  (-118 min)
The shipped greener model is ~2 h NEWER than the hero trio that is supposed to prove it.
greener also carries a metal pass (`_metal_read_greener.json`), so the delta is likely
material, not cosmetic. OWED: re-render the greener hero trio once Blender is back.
(Four chibi bodies - boiler_chibi, cook_chibi, sluicekeeper_chibi, sower_chibi - flag at
0-2 min, which is export-after-render ordering inside one batch, not a mismatch.)

### 3. THE `limb()` CAUSE, MEASURED AT SOURCE
    tools/art/creatures.py:113  def limb(P, pts, r0, r1=None, slot='bone', ring=8)
    call sites in tools/art/minibosses.py:  287 total,  0 pass slot=,  287 inherit 'bone'
So it is not "some limbs" - EVERY limb on EVERY miniboss is the single 'bone' material.
That is the pale-mass fault one level up, exactly as the team lead described it, and the
fix is per-call-site `slot=` on the sower (torso / cast arm / hopper / hat) and the moulder
(head). Both files are in lane (tools/art/). NOT ATTEMPTED: a material change with no
render is an unproven ship, and this lane does not ship unproven.

### 4. MINIBOSS COUNT IS 34, NOT 33
45 .glb in assets/monsters/minibosses/, 11 of them `_chibi` -> 34 distinct minibosses.
Measured off the tree, not off the prompt (which says 33).

### 5. FIT COVERAGE IS COMPLETE, 34/34 - THE REGISTERS ARE HONEST AND CURRENT
  - `_fit_report.json`: verdict GREEN, ok true, errors [], blind_views [],
    blank_check 15 files / 0 failures, 32 `pairs` (30 distinct + 2 chibi).
  - The 4 distinct bodies absent from that aggregate - comfitmaker, dyer, ratcatcher,
    tapster - each carry a full proof in their OWN `_fit_<key>_register.json`:
    creature_h / hero_h / ratio / fits_frame true / three body views / blank_check, all
    verdict GREEN, errors []. Ratios 0.93, 1.06, 1.07, 1.14.
  - `_report.json`: 45/45 entries, ok true, errors [], blank_check 102 files / 0 failures.
  - `renders/art/lords/_report.json`: 8/8 lords, ok true, errors [], 24 files / 0 failures.
  - sluicekeeper's register is keyed `sluice`, not `sluicekeeper`.
  READ HAZARD FOR THE GAME BUILD, not a defect: a consumer reading ONLY `_fit_report.json`
  finds no ratio for comfitmaker/dyer/ratcatcher/tapster. Their ratios are real and are in
  their own registers. No number was copied into the aggregate - an aggregate must report
  what its own run measured.

### 6. THE FIT HARNESS CANNOT REPORT AN UNEARNED PASS HERE - CHECKED, IT IS SOUND
`tools/art/minibossfit.py` opens all three views per cell (the 17 Nov fix for a blank check
that only ever looked at hero_front), goes ok=false on an empty hero block, on empty pairs,
and on any asked-for cell with no ratio. `unproved_cells` (snuffer_chibi, tallyman_chibi -
both retired from M.ORDER) is deliberately NAMED rather than silently carried, with an
in-source comment stating a GREEN verdict does not extend to them. No change made.

### 7. THE "STILL OWED" SNARER ITEM IS CLOSED
`assets/monsters/minibosses/snarer_chibi.glb.import` EXISTS (17 Nov 18:53 CT, 1178 bytes).
A Godot run generated it. That body can load. The prompt's open row is stale - strike it.

## NOTHING WAS RENDERED, SO NOTHING IS CLAIMED FIT THIS RUN
No mesh, icon or generator was created or changed. No blank-and-border check was run,
because no render was produced to check.
