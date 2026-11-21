# THE REGISTER'S `seen: 1.0` IS TAKEN BY CONSTRUCTION, AND THE INSTRUMENT THAT CAN MOVE SAYS 14 CELLS ARE BAD

21 Nov 2026, 03:34-04:0x CT. The ART row of the 02:58 team-lead block, both halves,
plus what measuring the second half turned up.

## (1) THE LOST GROUND BLOCKS - RESTORED, THEN PROVEN CURRENT

The charge: `pairs.boiler.ground` and `pairs.ratcatcher.ground` went `null` in my
02:47 value pass; a re-measure that nulls a stored block is evidence lost.

It is true, and **the cause was a one-line defect in my own harness**, not a slip
in the run. `minibossfit.py` rebuilt each row wholesale with
`ground=dict(GROUND_STATS) if GROUND else None`, so **every run made without
`--ground` overwrote a real measurement with a null that reads like a measured
absence**. An absent measurement and a measured absence are not the same fact.

- Recovered from `5687e207a` (21 Nov 01:56 CT), the last ref where both were real.
  *Not* from `origin/main`: the 03:0x merge had already carried my nulls into main,
  so main reads 42/46 too. The team lead's 44 was measured before that merge.
- Then **re-measured for real** (`--ground`, both bodies, 6 views).

**The restored numbers and the fresh ones are identical** on `plane_px`,
`shadow_px`, `mean` and `max` in all six views - boiler front shadow 4566 = 4566,
ratcatcher front 5650 = 5650. The only motion is `rim_filled_px`, by 2-5 px out of
3384-4574 (0.04-0.09%) on three of six views, which is the dilation step reading a
rim whose antialiased alpha the value pass legitimately moved. **So the value pass
did not invalidate the ground geometry** - and that is now proven rather than
asserted. The rows carry `ground_from`.

## (2) THE LYING CELL - AND IT IS LYING ON ALL 46 ROWS, NOT ONE

The charge: the boiler's register cell reads `seen: 1.0` while 29% of the man is
behind his own pan on the side view.

**Measured, not remembered: 264 of 264 occlusion cells read exactly 1.0, and
`vis == alone` in every single one.** The method is sound - with/without through
one locked camera - but `place()` holds measured air between the hero and the
creature (`air_px >= 8` in the tightest view of every row), so neither can ever
hide the other. **The answer is settled before the render.** That is trap 4 in its
purest form: an instrument that cannot move is not a pass. It is now labelled
`taken_by_construction` in the file, and `seen: 1.0` must never again be cited as
evidence that a body reads.

It is not worthless: it still goes red if a layout change ever puts the two bodies
in front of each other, and `alone == 0` still catches a blank or mis-aimed render.
It simply does not answer the question it was being read for.

### The instrument that CAN move

`_backread.py` already asks the viewer's question - how much of THE MAN survives
HIS OWN GEAR - and it was built for two bodies last hour. I ran it over **all 25
bodies that declare a `man` span**: 75 cells, range **0.4611 to 0.9998**. Those
numbers are now in the register as `self_seen`, per row and per view.

| body | view | man_seen |
|---|---|---|
| fuller | side | **0.4611** |
| beadle | side | **0.5174** |
| paviser | front | **0.5740** |
| moulder | back | **0.5837** |
| dyer | back | 0.5949 |
| greener | back | 0.6257 |
| beadle | front | 0.6325 |
| ferryman | front | 0.6405 |
| beadle | back | 0.6854 |
| relief | front | 0.6887 |
| sealer | back | 0.6949 |
| boiler | side | 0.7057 |
| winder | front | 0.7102 |
| fenman | side | 0.7301 |

**The boiler - the one defect the 02:58 row carried - is the TENTH worst in the
house.** Four bodies are worse on a view than the dyer and greener backs called out
at 01:34. The **beadle is under the bar on all three views**, which is the same
body the team lead condemned by eye for having no facing: the number and the
picture agree for once.

**21 of 46 rows have no `man` span and are NOT measured.** They carry no
`self_seen` at all - absent, not green.

## (3) THE BAR WAS WRONG AND THE PICTURE OVERRULED IT

I wrote the bar at 0.70 first. On my own contact sheet the boiler's side cell -
**the fault this item exists to catch** - printed GREEN by six thousandths
(0.7057), beside a tile showing a man substantially behind his own pan and pour.
A bar that passes the fault it was built for is set too low. It is 0.75. It is
still a bar I chose against pictures, not a measured constant, and **no verdict in
the file turns on it**: it names rows, it does not fail them.

## WHAT I LOOKED AT

`renders/art/minibosses/_backread/_selfseen_worst_sheet.png` - the eight worst
cells plus `pitman/side 0.9967` as the honest top end, each tile capped with a bar
whose LENGTH is its own score.

The picture agrees with the number on eight of nine. `fuller/side` has no findable
person in it. The paviser's man is behind his own pavise but for a head and one
arm. `dyer/back` and `greener/back` are a sliver of dark arm past hanging cloth.
`moulder/back` is a pale ball with a man behind it. `beadle/side` reads as a
barrel. `pitman/side` reads clearly beside its ladder, which is what a 0.99 should
look like.

**THE ONE DISAGREEMENT: the ferryman at 0.6405 front.** A figure with a pole does
read in that tile. The score is pushed down by the punt and the pole crossing him,
not by a body that cannot be found. There the number is the suspect and the picture
is the evidence, so the ferryman is **named, not condemned** - and if any seat later
acts on this table, start at the fuller and the beadle, not at him.

## THE SAME DEFECT, THREE TIMES, IN ONE FILE

All three were the same shape - *a run that does not measure a thing declares it
absent* - and I found the second and third only because the first was handed to me:

1. `ground` nulled by every non-`--ground` run. **The team lead found this one.**
2. `self_seen` would have been wiped the same way the moment any `--only` run
   touched a measured row - a block written by a *different* harness. Caught
   before it shipped.
3. **The whole top level.** `rep` is built fresh each run, so every top-level block
   this run does not produce was silently dropped on write. It ate `self_seen` and
   `visibility_scope` the first time I ran a `--ground` pass after writing them,
   and nothing said so. Caught because the write came back with a `KeyError`.

Fixed by carrying anything the run did not compute, with its provenance, and
naming the short list of keys the run owns outright so a stale copy can never mask
a fresh one.

**Proof the fix moves**: a plain `--only pitman` run - which before this would have
nulled pitman's ground, dropped its `self_seen` and eaten both top-level blocks -
now leaves ground at 6549 px with `ground_from: "carried"`, `self_seen_worst`
0.9967 intact, all 25 `self_seen` rows intact, and both top-level blocks present.

## VERDICT, UNCHANGED AND SAID PLAINLY

`ok: false`, `verdict: RED`, on `snuffer_chibi` and `tallyman_chibi` - the two
retired rows with no occlusion measurement on record. **That was already the state
at `fb119c28` before this run; I did not change it and I am not claiming green.**
`red_summary.shipped_red` is empty; both are `retired_red`.
