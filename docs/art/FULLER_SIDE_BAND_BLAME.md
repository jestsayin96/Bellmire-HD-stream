# fuller / side 0.4611 - WHO HIDES HIM, AND WHERE ON HIM

ART lane, 21 Nov 2026, the 05:34 CT firing. The 04:58 plan sent me to the
under-bar queue with `fuller/side` (0.4611) and told me to run the blame
instrument first and let it name the culprit span before moving anything.
Nothing was moved. This is the measurement.

## THE FIGURE I WAS HANDED, RE-COUNTED OFF THE REGISTER

`_selfseen_all.json` holds **75 cells** and `fuller/side` at **0.4611** is
**#1 worst of those 75** - both halves of the plan's figure check out. One
precision: **the under-bar queue is 14 cells, not 75**; 75 is the whole
register. Next three after the fuller are beadle/side 0.5174,
paviser/front 0.5740, moulder/back 0.5837.

## WHO - `tools/art/_selfseen_blame.py`, fuller, all three views

man-alone 52,516 px on the side. Loss charged per span, each measured through
the same locked camera, never inferred from z-order:

| span | items | hidden px | frac of him |
|---|---|---|---|
| trough | 9 | 14,040 | 0.2673 |
| cloth | 3 | 10,525 | 0.2004 |
| stocks | 13 | 8,558 | 0.1630 |
| backside | 12 | 2,911 | 0.0554 |
| bar | 5 | 1,984 | 0.0378 |
| folds | 3 | 0 | 0.0 |
| liquor | 4 | 0 | 0.0 |

Real loss 28,301 px; sum of parts 38,018; **overlap 9,717** - three spans
stack over the same pixels, which is why the parts must not be summed.
Front 0.9724 (all of it the `bar`), back 0.9986.

## WHERE ON HIM - `tools/art/_bandblame.py`, new this run

The culprit list is still not the viewer's question: a man whose shins are
behind a waist-high vat is a man working at a vat, and 0.4611 reads the same
either way. So the same camera and the same moved-pixel test, asked per height
band over the man-alone mask's own bounding box (band 0 = crown):

| band | rows | man px | survival | culprit |
|---|---|---|---|---|
| b0 | 98-151 | 4,984 | **1.000** | - |
| b1 | 151-205 | 5,392 | 0.995 | stocks |
| b2 | 205-258 | 5,948 | 0.637 | stocks |
| b3 | 258-311 | 7,429 | **0.433** | stocks |
| b4 | 311-364 | 7,631 | 0.735 | stocks |
| b5 | 364-418 | 4,627 | 0.265 | cloth |
| b6 | 418-471 | 3,082 | 0.007 | cloth |
| b7 | 471-524 | 3,513 | 0.000 | cloth |
| b8 | 524-578 | 3,657 | 0.000 | trough |
| b9 | 578-631 | 6,253 | 0.000 | trough |

Picture: `renders/art/minibosses/_backread/_bandblame_fuller_side_sheet.png`
(and `_front_`, `_back_`). I looked at all three. The band order is not taken
on the comment in `lordgen.read_png` - the sheet shows the crown green at
band 0 and the boots red at band 9, so top-down is confirmed by the picture.

## THE VERDICT: EXPLAINED, NOT OWED. NOTHING MOVED.

**Every pixel of the loss is from the chest down.** Head, brow and shoulders
survive 1.000 / 0.995; from the waist (b5) the vat, the cloth in it and the
machine's own frame take him completely. He is standing behind the trough he
works at, and the trough is waist high - that is the set piece, not an
apparatus fault. This is a different answer from the Beadle (his own anatomy)
and it lands in the same place: nothing to fix.

The one cell I will name rather than wave past is **b3 = 0.433**, a stock beam
crossing his chest at the readable height. In the picture his head, shoulders
and the arm on the bar still carry the figure and the beam reads as a machine
member in front of a man. Moving the stocks would cost the silhouette the two
hammers over the trough, which is the body's whole idea. **I am leaving it and
saying so with the evidence beside it**, so the team lead can overrule it
without re-deriving anything.

## WHAT THE HARNESS COULD NOT SEE, NOW COUNTED

`_selfseen_blame` charged fuller/**back** 104 px of loss to spans totalling
13 px. The easy reading is render noise. **It is not.** `_bandblame` renders
the man-alone mask twice and reports the disagreement: **floor_px = 0 on all
three views** - two identical renders agree exactly, so there is no noise to
blame.

A man pixel that no span covers and still fails the moved test is a pixel the
geometry leaves **in plain sight** and the values bury: his colour and the
colour behind him agree to within EPS. That is a readability fault, not an
occlusion one, and **no occupancy metric in this tree can see it.** It is now
counted on every run as `hidden_by_no_span_px`:

| view | hidden | charged to a span | charged to NO span |
|---|---|---|---|
| front | 2,064 | 2,061 | 3 (0.004%) |
| side | 28,301 | 27,691 | 610 (1.162%) |
| back | 104 | 5 | **99 (0.133%)** |

On the fuller it is small - the back view's 99 px are a speckle along his left
shoulder seam, visible as red dots in the sheet - so this is a class, not a
defect on this body. It is the dark-on-dark half of the pale-on-pale family
the Relief and the Ratcatcher were caught by.

## WIRING OWED BY THE GAME BUILD LANE - NONE FROM THIS RUN

The fuller is shipped and unchanged; no `.gd` edit is owed by this work.

Separately, **the standing `snarer_chibi.glb` item in my prompt is stale** and
I am striking it with a measurement, not a memory:
`assets/monsters/minibosses/snarer_chibi.glb.import` **exists on origin/main**,
landed 17 Nov 06:23 in b06c2cfb. Of the 57 `.glb` under
`assets/monsters/minibosses/` on main, **four now lack a `.glb.import`
sibling**: `ferryman`, `hooper`, `relief`, `scraper` - the four newest bodies.
A Godot run generates them; that tree is the game build's, not mine.
