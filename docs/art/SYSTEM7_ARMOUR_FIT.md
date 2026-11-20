# System 7 - the armour fit pass. NOT PASSED. What was measured, and what broke.

Written 19 Nov 2026, 21:0x CT by the ART lane (pass 1). The first version of this line
read 22:3x CT on a 21:01 commit - a stamp 90 minutes in the future that I did not read off the
machine. Corrected 19 Nov 21:5x CT off `TZ=America/Chicago date`. The team lead's 20:1x row asked for four things:
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

=============================================================
# PASS 2 - 19 Nov 2026, 21:3x - 21:5x CT. The back is closed. The widen was not owed.

The team lead's 21:0x row asked for one thing and named it precisely: *widen the chest plate
band AS GEOMETRY out to the body's half-width plus clearance, leaving horns, skirt and belt
alone, conform only the few remaining pokes, and ship the back closure in the SAME pass.*

**I measured before I modelled, and the widen is not owed. The plate is already WIDER than the
torso.** Everything else in the row was right and is delivered.

## FINDING 8 - the "plate reaches 0.4495" number was circular, and it is mine

Pass 1 separated plate from horn with a `|x| <= 0.45` cutoff and then reported the plate's reach
as **0.4495** - a number that *cannot exceed the cutoff by construction*. It answers the
threshold, not the geometry. Pass 1 finding 5 then reasoned from it ("a slice of the plate is
beyond the threshold and gets crushed"), so that conclusion rested on a measurement of my own
parameter. Same family as `mask_of` at pass 11 and `skin_rows` at pass 1: **the number answered a
question nobody asked.** That is the fourth.

Separated by CONNECTED COMPONENT instead - a fact about the mesh, not about my cutoff
(`tools/art/_s7_islands.py` -> `renders/art/s7_armour/_islands.json`):

| shell | islands | plate island | pauldron / spur islands |
|---|---|---|---|
| Armor_Black / Golden | 9 | 204 v, x **+-0.4937** | 2x74 v to 0.7699, 6x30 v |
| Armor_Metal | 3 | 184 v, x +-0.4937 | 2x54 v to 0.7156 |
| Armor_Metal2 | 3 | 204 v, x +-0.4937 | 2x74 v to 0.7699 |
| Armor_Leather | **1** | 140 v, x +-0.4877 | none |

The plate is one island reaching **0.4937**. The torso's own half-width, per 0.04 m z band
(`tools/art/_s7_measure4.py` -> `_measure4.json`), is **0.2366 to 0.3855** across the whole
chest. The plate is therefore already 0.11 - 0.25 m wider per side than the thing it covers, and
`need_widen_m` comes out NEGATIVE in 14 of the 18 measurable bands. The front render agrees: at
stage A the chest is fully covered and front bare area is **4.4%**. Widening it would push the
plate out past the arms into air.

**Where the row's number came from:** 0.77 is the *pauldron island*, not the plate, and 0.43 is
the *whole body's* half-width *including the arms*. Comparing those two says the shell overhangs
- which is true, and is the float fault - but it does not say the plate is narrow.

## WHAT THE OVERHANG ACTUALLY NEEDED - and the taper was the wrong tool

Because the pauldrons and spurs are SEPARATE ISLANDS, they can be translated inward as **rigid
pieces**. Shape preserved exactly. Pass 1's taper remapped vertices and crushed what it was told
not to touch; a rigid island shift cannot. Binary-searched per island until its nearest point to
the posed body is the clearance:

| island | nearest before | dx | nearest after |
|---|---|---|---|
| Golden upper spur, +x | 0.0991 | 0.0820 | **0.0300** |
| Golden upper spur, -x | 0.0988 | 0.0740 | **0.0300** |
| Golden back spur, +x | 0.1090 | 0.1009 | **0.0300** |
| Golden back spur, -x | 0.1193 | 0.1370 | **0.0300** |

The other islands were already within clearance and were left alone (dx 0.0).

## FINDING 9 - removing pass 1's y_offset is a REGRESSION, and I only know because I looked

Pass 1 finding 1 called the shipped `y_offset -0.0465` my own fault and the cause of the open
back. The team lead did not ask me to remove it; I tried it anyway as stage P1, honestly
re-centred with a shift and no scale. **Front bare area went 4.4% -> 37.1%.** The picture
(`fit12/P1_Armor_Golden_front.png`) shows why: the hero's own grey breastplate, red brooch and
belt poke straight through the gold. The offset is what makes the FRONT read.

**Pass 1 finding 1 is half right and the half that asked for its removal is withdrawn.** The
open back is fixed by closing the back, not by moving the shell. (The red brooch pass 1 mourned
as "swallowed" at stage J is the HERO'S OWN brooch, not the shell's - visible in P1 and hidden in
every stage where the shell sits forward, as it should be.)

## THE SHIP CANDIDATE: STAGE Q5, each change measured on its own stage

`tools/art/_s7_fit7.py`, renders in `fit14/` (A..Q4) and `fit15/` (Q5), register
`fit1{4,5}/_stage.json`. Bare area = body-coloured pixels inside the body's own silhouette,
torso band, read as a delta. Overlays `ov_*.png` tint those pixels red so the number and the
picture can be checked against each other.

| stage | what it adds | Golden front | side | back | float% |
|---|---|---|---|---|---|
| A | as shipped | 4.4 | 6.6 | 37.4 | 28.8 |
| Q2 | + back closure | 4.4 | 2.5 | **12.0** | 30.7 |
| Q3 | + rigid island anchor | 4.4 | **1.1** | 12.0 | **27.3** |
| Q4 | + inside-only poke conform | **3.3** | 1.0 | 11.4 | 27.0 |
| Q5 | + side bridge | 3.3 | 1.0 | **8.1** | 29.0 |

All five shells, A -> Q5, back bare area:

| shell | back A | back Q5 | front A | front Q5 | side A | side Q5 |
|---|---|---|---|---|---|---|
| Armor_Black | 40.0 | **12.3** | 5.0 | 3.9 | 8.5 | 2.7 |
| Armor_Golden | 37.4 | **8.1** | 4.4 | 3.3 | 6.6 | 1.0 |
| Armor_Leather | 40.2 | **21.6** | 14.8 | 13.3 | 44.5 | **40.5** |
| Armor_Metal | 37.0 | **9.9** | 5.7 | 4.5 | 12.6 | 7.0 |
| Armor_Metal2 | 41.4 | **13.7** | 7.6 | 6.6 | 10.3 | 4.8 |

The poke conform moves 39-88 vertices per shell - pass 1's conform moved 385-1160, which is why
it inflated the plate into a sack. **The front column is the proof the modelling survived:** it
does not move except to improve, and the seams, chevron, bevels and belt are all still there in
`fit15/Q5_Armor_Golden_front.png`.

0 blanks, 0 frame clips (max border alpha **0.0** across all 120 renders), errors `[]`.

## WHAT I CAN SEE IN THE RENDERS THAT NO NUMBER SAYS

Contact sheet `renders/art/s7_armour/_fit_sheet_pass2b.png`, five shells x as-shipped/Q5 x
front/back/side. I looked at it, and at the Golden front, side and back full size.

1. **ARMOR_LEATHER DOES NOT PASS AND I AM NOT CLAIMING IT DOES.** Side view 40.5%, unchanged by
   this pass. The vest stands off the body and you look straight into the hollow at the armhole:
   the hero's grey arm and brown belt are plainly visible inside it. The side bridge found only
   20 boundary edges on it and did nothing. Four of five shells pass; this one is held.
2. On every shell a grey strip of the hero's own collar still shows across the UPPER back,
   above the armour's top edge. That is most of the remaining 8-14%.
3. Black and Golden: the spurs no longer float, but anchored they read as a busy claw cluster
   crowded against the arm at the shoulder.
4. float% stays 27-33 and max_d 0.311 m. That is a HORN TIP standing off by design, not a fault
   - but the metric cannot tell those apart, so do not read it as a defect count.
5. The side bridge costs float: +2pp on Black and Golden, because the new side-wall faces are
   far from the body. Small, real, named.
6. The hem still hangs 0.22-0.27 m below the top of the legs on four shells. Unchanged on
   purpose - pass 1 finding 2 showed that scaling it up exposes MORE body, not less.

## FINDING 10 - my own anchor instrument could not move, and I caught it on the first read

`nearest_after` closed over the vertex snapshot taken BEFORE the shift, so it returned
`nearest_before` on every island whatever the shift was. Every row read "no change". Fixed to
re-read the moved vertices off the mesh; it now reads 0.099 -> 0.030, exactly the clearance.
The fix is in `_anchor_islands` with the reason written beside it. **That is the fifth blind
instrument of mine caught and labelled rather than quietly replaced.**

`skin_rows` is still carried, still labelled `BLIND`, and is not a pass criterion.

## WIRING FOR THE GAME BUILD: NONE THIS RUN, AND NOTHING REGRESSES

`assets/gear/armour/*.glb` are UNTOUCHED again this pass. The five `.glb.import` siblings
generated at S49 stay valid. **Plan row 1(b) - the cut -> shell mapping in `scripts/gear.gd` -
must STAY HELD**, because Armor_Leather still does not fit.

I did NOT export Q5 into `assets/gear/armour/` and that is a deliberate hold, not an omission:
replacing those `.glb` files regenerates the game build's `.glb.import` siblings, and shipping
four fitted shells beside one unfitted one would leave the set inconsistent. `_s7_export.py` is
one command from doing it the moment the team lead wants it.
