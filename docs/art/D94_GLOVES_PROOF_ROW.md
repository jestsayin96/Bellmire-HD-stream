# The D94 gloves proof row, re-measured - 2026-11-17 02:52 CT

The ruling is keyed to its OWN proof row and that row had not been re-shot since
16 Nov 07:45 CT. Two commits have landed on the glove derivation since then
(44ca6a5 D94f directional flare, 4ab066d System 1's icon pass), so the row was
measuring a tree that no longer exists. Re-shot here. Same harness
(`tools/art/d94proof.py`), same six cells, same framing (ortho 3.3), same light,
same body, front view, nothing else worn - the only thing that changed is the
tree underneath it.

    blender -b -noaudio -P tools/art/d94proof.py -- --repo W5 --only gloves --tag g6

Output: `renders/art/d94g6/` (`_row_gloves.png`, `_overview.png`, `_report.json`).
The 16 Nov baseline in `renders/art/d94/` is left untouched as the record.

## THE NUMBER

| | baseline (`renders/art/d94`, 16 Nov 07:45) | now (`renders/art/d94g6`, 17 Nov 02:37) |
|---|---|---|
| verdict | **PARTLY TOO SMALL 5/15** | **PARTLY TOO SMALL 1/15** |
| worst pair | **0.00 %** of hero stream px | **0.25 %** |
| median pair | **0.705 %** | **2.251 %** |
| best pair | 3.555 % | 4.738 % |
| worst pair is | Carder's / Bellringer's (0.00 %) | Carder's / Bellringer's (0.25 %) |
| duplicates | 0 | 0 |
| pairs measured | 15 | 15 |

Four of the five failing pairs cleared, the worst pair is no longer literally
identical, and the median more than tripled. Cells are the same six:
baker_mitts 200 g, carder_gloves 200 g, bellrope_wraps 240 g,
quarreller_gloves 280 g, forge_grips 300 g, raidbreaker_gloves 380 g - both
ends of the 200-380 g ladder, unchanged from the baseline row.

## BLANK AND BORDER

12 PNGs, 0 blank, 0 near-blank (smallest opaque count 73,031 px). Border alpha
0 on all 12 - nothing is cut by the frame - and the harness's own frame-clip
assertion reads `outside: 0` on all six cells. `pairs: 15`, not 0, so the
instrument is not reading green on an empty measurement. `ok: true`, `errors: []`.

## WHAT I CAN SEE IN THE SHEET, AND IT IS NOT ALL GOOD

I looked at `renders/art/d94g6/_row_gloves.png` and at crops of strip 1 and of
the three dearest bodies.

1. **THE ONE REMAINING TOO-SMALL PAIR IS THE TWO MOST BURIED PIECES, AND THAT IS
   CAUSAL, NOT A COINCIDENCE.** Mean of the two hands' `inside_pct` (how much of
   the piece is inside the body), measured this run:

   | item | % inside | |
   |---|---|---|
   | raidbreaker_gloves 380 g | **34.5** | best pair member |
   | baker_mitts 200 g | **52.1** | best pair member |
   | forge_grips 300 g | 55.9 | |
   | quarreller_gloves 280 g | 63.9 | |
   | carder_gloves 200 g | **72.5** | worst pair member |
   | bellrope_wraps 240 g | **79.7** | worst pair member |

   The ordering is monotone: the pair a viewer cannot tell apart is exactly the
   pair with the least of itself outside the body. D94f's outboard skew bought
   its improvement where the flare is already wide and did not reach the small
   cuts - a wrap at 80 % inside has 20 % of a small object left to differ with.

2. **THE CUFF SITS AT THE HIP, NOT ON THE HAND.** Measured in the posed scene
   (`tools/art/_g6_place.py` -> `renders/art/_g6_place.json`): `hand.l` is at
   z 0.547 and `chest` at 0.973. The cuff shell's top reaches z 0.844
   (quarreller), 0.839 (raidbreaker), 0.814 (carder) - 70 % of the way from the
   hand to the chest. The `cloth` mitt is placed correctly (centroid z ~0.505,
   floor z ~0.474); it is the metal/leather cuff that occupies the frame.
   The dial is doing what it declares - a vambrace IS a forearm piece - but on
   this chibi body the forearm is short and already at hip height, so a
   forearm piece reads as a waist ornament rather than as a glove. That is the
   amulet question in reverse and it is Mr. E's to look at, not mine to decide.

3. **Strip 1 frames each cell to its OWN pair-bounds**, so a glove whose two
   hands sit further apart is drawn smaller. Size differences between cells in
   strip 1 are framing, not the item. (Carried over from the 16 Nov write-up;
   still true, still not fixed, named so nobody reads the strip as a size ladder.)

4. **The cuffs read as buckets.** Every one is a truncated cone opening away
   from the hand; bellrope_wraps reads as a tin can with wire wound round it,
   raidbreaker as a ribbed basket. Against the plainness rule they do not yet
   look like what they are for.

5. **Left and right are not symmetric.** The harness's fault list names only
   `Acc_GloveL` for quarreller_gloves and forge_grips - the right hand clears
   the threshold and the left does not (forge 63.0 L vs 48.7 R, quarreller
   68.2 L vs 59.5 R). The two hands are at different depths in the torso.

6. **The wear ladder does read, and that part is right.** 200 g brown and grey
   -> 240 g tin and coil -> 280 g white stepped -> 300 g cream -> 380 g gold
   ribbed. The dearest piece is plainly the richest; nobody who paid 380 g is
   handed something second-hand.

7. **Clip faults, unchanged in kind**: carder 0.060 m deep both hands,
   bellrope 0.087 / 0.081 m, quarreller 0.054 m, forge_grips 0.072 m. Six in
   the row's fault list.

## THE HONEST HEADLINE

The number moved the right way on its own row and the ruling's condition is met.
It moved because the cuff got bigger and brighter, and the thing that is still
wrong is where the cuff sits and how much of it is inside the body. Fault 1 is
measurable and is mine to fix next: pull the small cuts' inboard wall out of the
torso rather than widening anything. Fault 2 is a picture for Mr. E.
