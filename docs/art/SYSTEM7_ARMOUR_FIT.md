# System 7 - the armour fit pass. NOT PASSED. What was measured, and what broke.

Written 19 Nov 2026, 22:3x CT by the ART lane. The team lead's 20:1x row asked for four things:
arms through the shell's openings, hem above the belt, horns/spurs anchored, leather closed at
the back - then a re-render. I measured all four. **Two of them cannot be done the way the row
describes without damaging the piece, and I am not shipping damage.** The five shells in
`assets/gear/armour/` are UNCHANGED by this run, so the game build's S49 `.glb.import` siblings
stay valid and nothing regresses.

Body numbers, re-measured off the posed Knight (Idle frame 1), not remembered:
`tools/art/_s7_measure3.py` -> `renders/art/s7_armour/_measure3.json`.
Blender axes, +Z up, hero front = -Y.

| what | measured |
|---|---|
| torso (Knight_Body) | x +-0.405, y -0.3642..0.3847, z 0.3628..1.2795 |
| top of the legs | z 0.5237 |
| arms, outer reach | abs(x) 0.669, z 0.549..1.254 |
| body half-width at shoulder height (z 1.15/1.20) | 0.43 / 0.34 |

## The four faults, as numbers

| shell | hem vs top of legs | shell x reach | shell y front/back |
|---|---|---|---|
| Armor_Black / Golden | **-0.275 m below** | +-0.7699 | -0.4243 / 0.3352 |
| Armor_Metal / Metal2 | **-0.223 m below** | +-0.7156 / +-0.7699 | -0.4243 / 0.3352 |
| Armor_Leather | **-0.100 m below** | +-0.4877 | -0.3352 / 0.3352 |

At shoulder height the shells reach abs(x) 0.77 where the body is only +-0.43 wide. That 0.34 m
of overhang is the floating horns, and it is also why the lower spurs hang beside the hips with
air behind them.

## FINDING 1 - the back gap is MY OWN previous correction, not the pack's geometry

The shipped transform carries `y_offset: -0.0465`. It was fitted on the CHEST BAND alone
(z 0.85..1.12), and that band is not representative: it pushed the whole shell **0.1 m forward**
of where a centred fit puts it, which is what opened the back the team lead saw in
`fit/Armor_Leather_back.png` and `fit/Armor_Black_side.png`. The shell's own back edge (0.3352)
is otherwise level with the body's back (0.3847 at the neck, 0.3338 at the waist).

## FINDING 2 - the hem cannot be fixed by scaling

Scaling the shell in z about the collar so the hem lands on the top of the legs (stage B) drags
the breastplate up with it. The result is a shoulder yoke with the hero's bare grey torso and
belt fully on show - **more** body exposed, not less. Withdrawn. The hem is left where the
artist put it.

## FINDING 3 - the shell's deepest point is a horn, not the plate

Fitting depth on the shell's full bounds (stage F) drags the chest plate (y -0.268) behind the
body's own chest surface (y -0.31) and the armour disappears into the torso. Looked at:
`fit4/F_Armor_Golden_front.png`. A rigid depth fit of any kind is the wrong instrument here.

## FINDING 4 - closing the back is a clean win and costs nothing

Mirroring the clearly-front faces about the body's depth centre gives the open wraps a back.
Bare body still visible in the back view, as AREA inside the body's silhouette:

| shell | as shipped | back closed + conformed |
|---|---|---|
| Armor_Black | 40.0% | **12.6%** |
| Armor_Golden | 37.4% | **5.9%** |
| Armor_Leather | 40.2% | **7.5%** |
| Armor_Metal | 37.0% | **7.6%** |
| Armor_Metal2 | 41.4% | **11.1%** |

The leather vest had no back panel at all - 148 triangles, all front. 60 faces added.

## FINDING 5 - the overhang taper cuts into the plate, and I only saw it by running it alone

The taper remaps abs(x) beyond a 0.45 core onto the body's own half-width. Run WITH the conform
after it, the taper looked free: coverage was identical with it (21.6%) and without it (21.3%).
Run ALONE (stage M) it is not free at all - front coverage collapses to 43.9%, because the
plate's own core reaches abs(x) 0.4495 and a slice of the plate is therefore beyond the
threshold and gets crushed. The conform afterwards was pushing the damage back out and hiding
it. **A fix that is only clean in combination is not clean.**

## FINDING 6 - every conform variant swallows the modelling

- Nearest-surface push-out (stage G/H): per-vertex clearance is not per-face clearance. The
  hero's raised centre chest seam still comes through the gold. `fit6/H_Armor_Golden_front.png`.
- Ray push-out from the body axis (stage J): coverage is the best of any variant and the fit
  faults are gone - **and the plate inflates into a smooth sack. The seams, the belt and the red
  brooch are swallowed.** `fit8/J_Armor_Golden_front.png`.
- Up-scaling the shell 1.18 first so the conform has less to do (stage L118): keeps far more of
  the plate (385 vertices moved instead of 1160) and gives the best coverage numbers of all -
  and the horns become flat antennae at head height and the hem reaches the ankles.
  `fit10/L118_Armor_Golden_front.png`. At 1.30 it clips the frame; the border assert caught it.

A gold sack is slop, and Mr. E's rule is that a viewer who paid for a legendary piece must not
get something second-hand. So none of these ships.

## FINDING 7 - one of my own instruments was blind. Again.

`skin_rows` samples, for each image row, only the LEFTMOST and RIGHTMOST opaque column - the
silhouette EDGE. That edge is the arm and the head outline in every stage by construction, so
armour that covers area INSIDE the outline cannot move it. It reported every single fix as a
regression, and I nearly believed it. Replaced with `bare_area`, which counts body-coloured
pixels inside the body's own silhouette across the torso band and answers the viewer's question.
Both are kept in the harness, the blind one labelled, so the next run cannot re-learn this.
That is the third instrument of mine caught this way (centre-band occupancy at System 1,
`mask_of` at pass 11, this). The pattern each time: the number answered a question nobody asked.

Every instrument in `_s7_fit3..6.py` goes RED ON EMPTY - a metric computed over zero rows, zero
vertices or zero pixels fails rather than reads green.

## WHAT THE NEXT ART RUN MUST DO

Not another whole-shell transform. The chest plate band itself has to be **widened as geometry**
- a lateral widen of the plate band only, out to the body's half-width plus clearance, leaving
the horns, the skirt and the belt alone - and only then conformed for the few remaining pokes.
The back closure (finding 4) is ready to ship with it and should go in the same pass.

## WIRING FOR THE GAME BUILD: NONE THIS RUN

`assets/gear/armour/*.glb` are untouched. The five `.glb.import` siblings generated at S49 stay
valid. Plan row 1(b) - the cut -> shell mapping in `scripts/gear.gd` - must STAY HELD: fit is
still not passed, and wiring a shell that does not fit buys nothing.
