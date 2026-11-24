# THE NIGHTMAN - "Nightwork" - THE 53rd MINIBOSS
Art lane, 24 Nov 2026, the 10:34 CT firing. Invented under Mr. E's standing
permission of 15 Nov 17:43. No lore, no canon dependency, no content hook.

## WHAT I CHECKED FOR FIRST - MEASURED, NOT REMEMBERED
- `tools/art/minibosses.py` carries **66 CANON rows**, of which **14 are
  chibi/tall variants** of a base. **52 distinct bodies existed**, so this is
  the 53rd. I counted the rows out of the file, not off the prompt.
- I read **every mechanic headline in the file** before designing - 57 strings
  of the form `"IT <VERB>..."` - so this is not a re-skin of one of them.
- Theme balance, counted off the same rows: barracks 3, prison 3, mess 3,
  wood 3, firepit 3, confection 3 against crypt 5 and fogbound 5. **`prison`**
  is one of the thinnest and a nightman emptying the vault under the cells is
  an honest fit, not a stretch to pad a count.
- `git status` untracked-`.glb` standing check: **clean before this run**
  (0 untracked `.glb`), and `nightman.glb` is committed by this run.

## THE IDEA - THE ONE AXIS NOBODY IN THE SET HAD
**IT WORKS IN THE DARK AND WAITS IN THE LIGHT.** Its own shuttered lamp hangs
on its belt where a hand can reach it. **Shutter OPEN: it stands dead still -
it strikes nobody and it CANNOT BE HURT.** A lit nightman is just a man
standing in a room; you can walk past him and he will still be there.
**Shutter SHUT: it can be killed - and it works**, and a thing that works in
the dark is never where you last struck it.

The party owns the switch and **both ways cost**. It does not choose, it does
not time anything and it has no phase. This is the house's best shape (the
Stiltman's break-or-leave, the Roper's one line) and it is a DECISION.

Why it is not a re-skin of the Snuffer: the Snuffer **removes** the room's
light, which is what made light a resource in this dungeon at all. This body is
the one that is **governed** by it. It is the opposite construction and it only
works because the Snuffer shipped first.

## THE READ - WHAT A VIEWER GETS FROM THE DOORWAY
A stooped working man. A wide shallow **tub** on the left hip on a chest strap.
A long **scoop** in the right hand, shaft running down and forward to a pan on
the floor. A **lamp** on the belt - the only bright object on the whole body.
Hood, cloth over the face, thigh boots.

**THE TITHER'S RULE, OBEYED EXACTLY:** the pale thing is the thing the mechanic
is counted on, so `bone` is **THE LAMP AND NOTHING ELSE**. The head carries no
pale panel at all - unlike the Stiltman, which needed one - because a second
pale mark would split the count the mechanic is read off.

**THE BEADLE'S FACING FAULT IS ANSWERED BY CONSTRUCTION, NOT BY A NUMBER.** The
eyes are glow on -Y only and the lamp hangs forward, so **the back view has no
pale face and no eyes**. I looked at `hero_back.png`: it is a dark hood, a back
slab, the tub and the tool, and nothing that reads as a front.

## THE THREE PASSES - AND PASS 1 WAS A FAILURE WORTH WRITING DOWN
**PASS 1 SHIPPED A GREEN REGISTER OVER AN INVISIBLE MECHANIC.** verdict GREEN,
ratio 0.94, `seen 1.0` on three views, 0 blanks, 0 frame clips, errors `[]` -
and the lamp was **a 0.145 solid bone box with the glow sphere SEALED INSIDE
IT**. A light inside a closed box emits into the box. At hero scale it read as
a belt pouch. **On the one body in this file whose whole idea is "the pale
thing is a lamp", the mechanic could not be seen, and no number in the register
could tell me so**, because the register has no term for CONTRAST. That is the
same family as the pass-11 `head_glow_px: 156` fault and it is the fifth time
this lane has shipped a green sheet over a picture that does not read. The
picture was the evidence; the numbers were the suspect.

| pass | what changed, measured separately |
|---|---|
| 2 A | **THE LAMP IS A CAGE, NOT A BOX.** Bottom plate, top plate, two corner posts, with the glow **block** standing in the gap - a lit face the camera sees directly. Scaled to 0.24 x 0.21 x 0.33, large for a belt lamp and deliberately so, on the Drillmaster's precedent that a working man's instrument is the brightest thing on him. |
| 2 B | **THE ARMS WERE A HORIZONTAL BAR.** A 0.60 x 0.235 shoulder slab with both arms leaving it level read, on the front render, as one beam from the tub to the scoop with the head bolted on. Bar 0.60 -> 0.50 across and 0.235 -> 0.300 deep; elbows dropped from 0.23 below / 0.12 out to **0.375 below / 0.072 out**, so the upper arms HANG and the forearms do the reaching. |
| 2 C | **A BACK.** Pass 1 measured 1.65 wide and **0.91 deep** and the side render showed what that means: a post with a pail on it. |
| 3 D | **THE MAN WAS THE SAME VALUE AS HIS GEAR.** Wool 0.196 against tarred 0.078 rendered as one dark mass. 0.196 -> **0.262**, the smallest move that separates what he IS from what he CARRIES. |
| 3 E | **THE HEAD WAS A KNOB ON A POST.** 0.172 -> **0.202**, which is 0.40 across against the 0.50 bar - the Stiltman's measured ratio for "this is a head", applied rather than re-derived. |
| 3 F | **I ANSWERED FAULT 7 FOR THE THREE CARRIED OBJECTS AND THEN BUILT A NEW ECLIPSE WITH THE SHAFT BETWEEN THEM.** My own pass-1 note separated tub / lamp / pan in both axes and was right about all three, and never checked the **shaft**, which crosses every height. Measured off the two lines: at the lamp's z the pass-2 shaft stood at y -0.29 against the lamp's back face at y -0.335 - a **0.045** gap. Pan forward to y -0.520 and lamp to (-0.500, z 1.150) opens it to **0.08**. |

## THE FIT PROOF - I LOOKED AT IT
`minibossfit` on the posed KayKit knight, front / side / back, EEVEE:
**verdict GREEN**, `ok true`, `errors []`, `blind_views []`, `unproved_cells []`,
`shipped_red []`, `retired_red []`, blank check 3 files / 0 failures,
**frame_edge 0 on all four borders of all three views**.
`creature_h 2.30 / hero_h 2.45 / ratio 0.94 / fits_frame true /
proving_views 3 / seen 1.0 on front, side AND back`, `air_px_min 142`.
`minibossgen`: **CORRIDOR-SAFE** (span 1.63 m, margin 9.37), **UNDER-LID**
(clear 7.20), 701 faces, 4 merged parts, glb written. Not room-locked.

**EVERY FAULT I CAN SEE IN THE PASS-3 RENDER, honestly:**
1. **The arms still half-read as a crossbar** at the shoulders on the front
   view. Fix 2 B moved it and did not finish it; the left arm to the tub rim
   is still close to straight out.
2. **The tub reads as a shallow roasting pan held out at arm's length**, not
   as a tub carried on the hip. It wants to come in and down against the body.
3. **The scoop reads as a carpet sweeper** at hero scale - a clean straight
   shaft with a thin flat pan. A real scoop pan is a scoop, and this one is a
   plate.
4. **The lamp reads as a bright CARD on the hip**, not unmistakably as a
   lantern - the cage posts are too thin to register and the shutter leaf
   reads as a grey flap. The mechanic's *brightness* reads; its *identity*
   does not.
5. **The stoop does not read.** 0.17 over 0.97 m of trunk is applied and
   invisible; the figure stands straight.
6. **The legs are two dark posts** with no knee visible, and on the side view
   they merge into one mass.
7. On the side view **the arms disappear into the trunk and back slab**
   entirely, so that view has no arms at all.
8. The back slab reads as **a flat plate strapped on**, closer to a pack than
   to a back.

None of 1-8 is a blocker for a 53rd body going into the pool, and all of them
are a pass-4 list for whoever takes it next - including me.

## WIRING - THE GAME BUILD LANE'S, NOT MINE
1. `assets/monsters/minibosses/nightman.glb` is committed **with no
   `.glb.import` sibling** - the identical gap `panner` and `stiltman` had.
   A Godot `--headless --import` pass must generate and commit it.
2. `Delve.MB_NAME["nightman"] = "Nightwork"` - **only after content writes
   `miniboss_feed.by_key.nightman`**, because `chatcmd.gd:2252` turns an
   MB_NAME row with no feed into a ghost and `push_error`s on it.
3. `Delve.MB_FIT["nightman"] = 0.94` - copied from this run's
   `_fit_report.json` `pairs.nightman.ratio`, not re-derived.
4. `DungeonHD.THEME_MINIBOSS_MORE["prison"] += "nightman"` - the CANON theme
   tag is **prison** (`tools/art/minibosses.py`). Per the team lead's own
   reading of `dungeon_hd.gd:256` and `_s33_draw.gd:71`, this row is **safe on
   its own before any feed row exists**.
5. Static body: bestiary needs a `model` path and **no `anims` entry**.

I do not touch any of those files. They are the game build lane's.
