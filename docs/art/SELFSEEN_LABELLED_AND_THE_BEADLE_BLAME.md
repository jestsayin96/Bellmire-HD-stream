# THE LABELLED SELF-SEEN SHEET, AND WHO IS ACTUALLY HIDING THE BEADLE
### art lane, 21 Nov 2026, the 04:34 CT firing

The 03:58 team-lead block gave the art lane two things, both inside its own
shipped work: **label the tiles** in `_selfseen_worst_sheet.png` and say which
cell is the second green bar; and **take the worst of the 14 under-bar cells**,
the Beadle, first. This is both, and the second one did not end where I
expected.

---

## 1. THE SECOND GREEN BAR WAS `boiler/side`, AND THE OLD SHEET WAS MIS-SELECTED

I did not guess which tiles the 03:58 sheet held. I correlated each of its nine
380 px tiles against all 75 `<key>_ss_<view>.png` renders on disk (LANCZOS to
the tile size, composited over the same background, mean absolute error, bar
strip masked out). Every tile matched one render by a margin of 3x or more
over its runner-up:

| tile | cell | value | bar drawn |
|---|---|---|---|
| 1 | fuller / side | 0.4611 | red |
| 2 | beadle / side | 0.5174 | red |
| 3 | paviser / front | 0.5740 | red |
| 4 | moulder / back | 0.5837 | red |
| 5 | dyer / back | 0.5949 | red |
| 6 | greener / back | 0.6257 | red |
| 7 | ferryman / front | 0.6405 | red |
| 8 | **boiler / side** | **0.7057** | **GREEN** |
| 9 | pitman / side | 0.9967 | green |

**The second green bar is `boiler/side` at 0.7057 - under the 0.75 bar and
drawn green.** The bar widths confirm the same reading independently: measured
off the PNG they are value x 372 px to the pixel for every tile, 262 px for
tile 8, which is 0.7057 and not 0.6325.

Two further things fall out that the write-up did not say:

* **The sheet was not "the eight worst".** It holds seven of them. `beadle/front`
  (0.6325, the 7th worst) is absent, and `boiler/side` (the 12th worst cell) is
  in its place.
* The 02:58-era line calling the boiler "the tenth worst" is right about
  **bodies** and not about **cells** - ranked by each body's worst cell the
  boiler is 10th of 25; ranked by cell it is 12th of 75. Both are true
  statements about different things, so nothing is owed there, but a sheet of
  cells has to be ranked by cells.

## 2. THE SHEET IS A COMMITTED TOOL NOW, AND IT LABELS ITSELF

`tools/art/_selfseen_sheet.py`. The 03:58 sheet was built inline and thrown
away, which is why none of this could be checked by the reader. The new one:

* every tile carries **key, view, value and rank** (`#2 of 75`), drawn under
  its own picture;
* the bar **colour is computed from the bar**, red under `--bar`, green at or
  over it, **no excused cells**, and a white tick is drawn at the bar position
  on every track so the colour can be checked against the geometry by eye;
* the selection is `--worst N` taken strictly, plus the single best cell as a
  top end, and both are named in the header;
* it goes RED and writes nothing on a missing render, a short register, a value
  out of range, a header line that runs off the canvas, or a caption whose ink
  reaches past the bottom edge.

**The last two assertions are there because my own first cut failed both of
them**, and I found it by looking at the picture: the bar sat at the TOP of its
tile, directly beneath the PREVIOUS row's caption, so a reader binds it to the
wrong cell - the exact ambiguity the sheet exists to remove - and the bottom
row's second caption line fell off the canvas. A clipped label is not a blank
one; that is trap 2 wearing a different coat, and the harness now asserts it.

Current sheet: 9 tiles, 75 cells, **14 under the 0.75 bar**, 25 bodies, and the
eight worst really are the eight worst.

## 3. THE BEADLE: A NEW INSTRUMENT, AND A FIX THAT I MEASURED AND THREW AWAY

`_backread.py` says the Beadle's side cell is 0.5174 and names no culprit:
`rest` is ONE merged object, so the number cannot say whether the coat, the
staff or the man's own arm is in front of him. Changing a body on a number that
cannot name a part is guessing with extra steps.

**`tools/art/_selfseen_blame.py`** splits the build on **every** span, not only
`man`, and asks the viewer's question once per span through the same locked
camera: man alone, then man + span S, counting the man pixels S leaves
standing. It goes red on spans that do not partition the item list, on moved
bounds, on a man mask under 500 px, and it reports a span that covers nothing
as `0.0` rather than dropping it - a metric over an empty set reads green and
means nothing.

It also forced a fix to the span table itself: the Beadle's **gripping arm was
inside the `staff` span**, so a limb and a prop shared one number. It is now
its own span, `griparm`. That is the instrument being able to see, not a tidy-up.

**The Beadle, measured (shipped geometry):**

| view | griparm | head | staff | coat | arm | board | pegs | base | man_seen |
|---|---|---|---|---|---|---|---|---|---|
| front | 0.0015 | 0.2117 | 0.0000 | 0.1174 | 0.0358 | 0 | 0 | 0 | 0.6325 |
| side | **0.2091** | 0.1929 | 0.1390 | 0.0884 | 0.0019 | 0 | 0 | 0 | **0.5174** |
| back | 0.0002 | 0.2035 | 0.0000 | 0.0689 | 0.0163 | 0 | 0 | 0 | 0.6854 |

**The side cell is mostly the man's own anatomy.** His forearm and his own head
account for 0.40 of the 0.48 that is lost; the only prop in it is the staff at
0.139. That is not the fault `_backread.py` was built to catch - the Dyer fault
is a man hidden behind his own *apparatus*, and a forearm across a chest is a
man.

**I tried the obvious fix anyway.** Move the whole staff span forward in y by
0.30 so the side camera stops projecting it onto him, the gripping arm's
shoulder staying on the body so the arm reaches forward. Same locked camera,
bounds identical to five decimal places in both builds
(`[-1.06405, -0.7072, 0.0, 0.81045, 0.48047, 2.95]`), so every moved pixel is
real:

| side | control | staff +0.30 forward |
|---|---|---|
| man_seen | 0.5174 | **0.4357** |
| staff | 0.1390 | 0.1124 |
| griparm | 0.2091 | 0.2360 |
| overlap | 2583 px | 1168 px |

**It is worse, and the overlap term says why**: the shaft barely came off him.
What changed is that the shaft and the arm stopped covering the *same* torso
pixels and started covering different ones.

**And the picture agrees** - which is the only reason I am willing to call it
settled. `renders/art/minibosses/_backread/_p14_side_ab.png`, control left,
moved right, 760 px each: the moved staff runs down the figure's own front
**contour** and breaks the coat's silhouette edge, its foot crosses in front of
the boot, the gripping arm reads as a dark wedge jammed across the belly, and
the amber knob has barely left the cheek. Number and picture agree, and they
agree it is worse. **So it is reverted. The Beadle in this commit is byte-for-byte
the pass-13 body**, and I proved that rather than asserting it: a fresh
`_backread.py` run on the shipped tree returns 0.6325 / 0.5174 / 0.6854 and the
same bounds, matching the register exactly.

The flag `BEADLE_STAFFY=1` re-runs the A/B in one command. It is **off**.

## 4. WHAT I COULD NOT SETTLE, SAID PLAINLY

* **The blame terms do not sum to the loss, and one sign is wrong.** Front and
  back report a *negative* overlap (-23 px of 18402, and **-447 px of 17375,
  2.6%**): pixels lost in the full render that no single span accounts for.
  The explanation I believe is anti-aliasing - a pixel part-covered by two
  different spans can fall under the 2/255 threshold against each one alone and
  over it against both. I have not proved that, and 2.6% on the back view is
  larger than I would like. It is reported in the JSON as `overlap_px` rather
  than folded away.
* **The 0.75 bar is being asked a question it may not answer.** If the Beadle's
  side cell is 0.40 anatomy and 0.14 prop, then a body with a raised arm and a
  wide hat can sit under the bar while reading perfectly well, and a body whose
  apparatus eats it can sit over the bar. The blame table makes a **prop-only**
  figure computable for all 25 bodies. I have not computed it and I am not
  proposing a bar change off one body - this is a flag, not a claim.
* One pixel of wobble: the eight-way split returns `front 0.6324` where the
  two-way split returns `0.6325` (11638 vs 11639 of 18402). It is the merge
  seam under anti-aliasing, not the body - the two-way run on the shipped tree
  reproduces the register exactly.
