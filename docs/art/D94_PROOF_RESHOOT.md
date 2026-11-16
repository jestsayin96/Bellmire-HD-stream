# D94 proof sheet - the seven re-shot rows, and what the real numbers are
ART lane, 2026-11-16 07:45 CT. Sheets: `renders/art/d94/_overview.png`, `_row_<slot>.png`.

The supervisor's 07:28 row: the proof's `spread()` walked the pool CHEAPEST-FIRST, so every
row was shot with its cost-driven dials pinned on the floor; gloves were re-shot after the fix
and the other seven never were. Re-shot. Below is what actually changed - including the part
where the taint was narrower than the row claimed, and the part where the fix was still wrong.

## 1. TWO OF THE SEVEN WERE NEVER TAINTED

`spread()` is only used by the five accessory rows and the hat row. The WEAPON row picks one
per family by tier, the ARMOUR row picks one per cut at tiers 1 and 5 - neither has ever touched
`spread()`, and both re-shot to byte-identical picks and identical numbers (weapon 3.05 %,
armour 19.65 %). So "every percentage D94 has quoted was measured on a crippled spread" is not
true of those two. It is true of ring, amulet, cloak, boots and hat.

## 2. THE COST LADDER, BEFORE AND AFTER (this is what the bug actually cost)

| row | cheapest-first picks | after the fix | slot's real range |
|---|---|---|---|
| ring   | 210-300 | 210-**520** | 210-520 |
| amulet | 230-300 | 230-**480** | 230-480 |
| cloak  | 220-260 | 220-**500** | 220-500 |
| boots  | 200-220 | 200-**420** | 200-420 |
| hat    | 30-90   | 30-**300**  | 30-300  |
| gloves | 200-240 | 200-**380** | 200-380 |

Every row now shows the cheapest AND the dearest item of its slot. Before, five rows topped out
below half the ladder: the row could not test Mr. E's receipt because no legendary was in it.

## 3. THE FIX NEEDED A SECOND PASS, AND THE FIRST ONE MADE RING WORSE

Keeping one variant per cell but filling each cell with the member nearest its share of the cost
range still cannot reach the top: if the dearest item belongs to a variant an earlier (cheaper)
cell already spent, the top never appears. Measured, not assumed - ring stopped at 460 of 520,
cloak 440 of 500, boots 340 of 420, gloves 320 of 380. Matching cells to variants greedily
cheapest-cell-first made ring WORSE (460 -> 420). Serving the two ENDS of the ladder first and
filling the middle afterwards is what reaches both ends. That intermediate measurement is kept
as `renders/art/d94/_report_variant_order.json` and `_report_ladder_cheapfirst.json`.

## 4. THE REAL NUMBERS (worst pair = % of the hero's own stream pixels that change)

| row | before (crippled) | now | verdict |
|---|---|---|---|
| ring   | 0.00 | **0.00** | TOO SMALL ON STREAM |
| amulet | 0.52 | **0.48** | nominally TELLS APART - see below |
| cloak  | 19.11 | **25.85** | TELLS APART |
| boots  | 1.72 | **1.79** | TELLS APART (median 4.24) |
| gloves | 0.00 (11/15 pairs too small) | **0.00 (6/15)** | PARTLY TOO SMALL |
| hat    | 17.54 | **17.86** | TELLS APART |
| weapon | 3.05 | **3.05** | untainted, unchanged |
| armour | 19.65 | **19.65** | untainted, unchanged |

Nothing got materially worse and nothing got dramatically better. **The honest headline is that
showing the legendary did not rescue a single failing row.** A 520 g ring is exactly as invisible
on a body as a 210 g one.

## 5. WHAT I CAN SEE IN THE SHEETS (I looked at ring, amulet, cloak, hat and the overview)

- **AMULET IS A RING IN DISGUISE.** 0.48 % worst, 0.80 % median. In the stream strip all six
  cells are the same hero. The six pendants are genuinely six objects in strip 1, but ON THE
  BODY only the pendant head shows, about 2 cm of it, and the collar swallows the chain - which
  is the thing that differs most between them. Classified TELLS APART only because the detail
  shot differs. By Mr. E's bar it is the ring verdict.
- **A CLOAK IS A MINI-SKIRT.** Every cloak hangs from the WAIST to mid-thigh; nothing falls from
  the shoulder line. From behind it reads as a kilt. Colour is the only thing telling the six
  apart, which is why the row scores well (25.85 %) while still being wrong.
- Hurdler's Cloak carries a brown sphere (a hood) that is invisible once worn; Deepwarden's has
  an inside-out collar tab that reads as broken mesh; the clasp beads float above the cloak's
  top edge, unattached to anything.
- **The 500 g cloak is not richer than the 220 g one** - flat colour, no trim, no better
  finish. Same for the ring row until the top cell: there the ladder DOES read (plain band ->
  double band -> bronze + stud -> thick bronze -> silver triple coil + gem -> gold cluster + gem).
- **Glazier's Visor (190 g) is a dinner plate** over the whole face, two slits in it.
- **Architect's Hat (300 g, the dearest hat in the game) is a bare wire hoop with a spike** and
  no crown - the hair shows through it, and it FLOATS 0.081 m off the head. A viewer who paid
  the top price gets the least visible hat in the row.
- Tallykeeper's Ring (210 g) has a square block fused to the band that reads as a nut, not
  jewellery; Crater-Glass Ring (520 g) reads as a crushed rock rather than a worked ring.
- Strip-1 framing cuts items off: the amulet chains run past both edges of their cells, and each
  cell is framed to its OWN bounds, so a 520 g ring does not look bigger than a 210 g one.
- **The hero is not dressed the same in every row.** In the hat, weapon and armour rows he wears
  a red cape; in ring, amulet, boots and gloves he does not. It does not break the comparison
  WITHIN a row (all six cells match), but percentages are not comparable BETWEEN rows, and the
  red rosette on his chest is larger than several of the items under test.

## 6. MEASURED FIT FAULTS: 31. Blank check: 96 files, 0 failures.

Unchanged in kind from the last run: gloves and hats clip deepest (`straw_hat` 0.316 m, 19 % of
it inside the head; `carder_gloves` 88 % inside the mitt), `architect_hat` floats 0.081 m, the
two bows stand 0.12 m BELOW the feet, and `w_blade_emberline` passes through the body by 0.130 m.
Full list in `renders/art/d94/_report.json` -> `fit_faults`.
