# D94 gloves, pass 7 - the glove was inside the limb. 2026-11-17 03:52 CT

The 02:58 TAKE THIS NEXT row told this lane to pull the small cuts' inboard wall
out of the TORSO and re-shoot. I measured first, and the row's diagnosis is
wrong - in a way that matters, because the fix it names would have moved almost
nothing on the piece that is failing.

## WHAT I MEASURED BEFORE I CHANGED ANYTHING

`tools/art/_g7_probe.py` -> `renders/art/_g7_probe.json`: each of the six cells
built on the posed body, every vertex tested against the **arm meshes** and the
**torso meshes separately**, plus an outboard offset sweep.

| cell | inside body | inside ARM | inside TORSO |
|---|---|---|---|
| bellrope_wraps (the failing pair) | 78.8 % | **89.4 %** | **19.3 %** (cuff alone 5.2 %) |
| carder_gloves (the failing pair) | 73.2 % | **89.6 %** | 55.6 % |
| raidbreaker_gloves (best pair) | 38.8 % | 44.1 % | 45.1 % |

**The wrap's cuff is 5 % in the torso.** It is not buried in the torso; it is
swallowed by the arm it wraps. And on all six cells the hand shell measured
**100.0 % inside the body mesh** - not one vertex of any glove's hand shell was
visible on any of the six.

## WHY, AND IT IS THE NUMBER EVERY GLOVE DIAL IS BUILT ON

`tools/art/_g7_arm.py` -> `renders/art/_g7_arm.json`. Sixteen rays from the bone
axis at eight stations between wrist and elbow, nearest wall, arm meshes only:

* **forearm RADIUS 0.110 (thinnest ring) - 0.123 (mean ring)**
* **hand RADIUS 0.130 (nearest wall) - 0.154 (mean of 26 ways)**

`showcase.acc_gloves` was building from `ar = handlen * 0.38 = 0.056` and a hand
shell half-extent of 0.066-0.085. So the cuff was **2.1x** and the shell about
**1.4x** too small - *smaller than the limb they cover*. The old comment called
those numbers MEASURED and dismissed a mesh scan that returned 0.154 as the
thing that "turned the first pass into dinner plates". The mesh scan was right.

The confirmation is that `inside_pct` is **monotone in flare** - raidbreaker
(dearest flare) 31 %, carder 71 %, bellrope 76 %. A piece with nothing outside
the skin cannot differ from another piece with nothing outside the skin. That
is the failing pair, and no amount of leaning outboard fixes it.

### THE INSTRUMENT LIED FIRST AND I CAUGHT IT
The probe's first run reported an arm radius of 0.50-0.58 m and a torso 0.70 m
inboard, on a body 1.32 m wide. `showcasegen.ray_out` takes the **outermost**
hit - correct when the ray starts on the spine and must find the outside of the
torso, wrong when it starts inside the arm, where it returned the OTHER arm half
a metre away. Fixed to nearest-hit before any geometry was touched.
**The torso-inboard column of `_g7_arm.json` is still not trustworthy** (it
reports ~0.65 m where the body is 0.17 m wide) and no conclusion here rests on
it; the arm and hand radii are cast inside a single mesh and are sound.

## THE CHANGE - TWO PASSES, MEASURED SEPARATELY

**7a. Re-base on the measured limb.** `ar` becomes the measured forearm radius,
the shell becomes a fraction of the measured hand radius. The SHARED dials in
`icons.glove_form` are **not touched** - the 520 hub icons are ticked and must
not move; only how the worn piece reads them changed. Ladder kept as a fraction
of the limb: 1.06-1.48 of the forearm, 1.05-1.31 of the hand, with the key's own
jitter multiplicative so two same-cut gloves still differ.

**7b. A wrist waist**, found by looking at 7a's sheet: 7a went TELLS APART but
the four metal cuts came out as **stacks of pancakes** - a drum of near-constant
diameter with rings round it. Arithmetic, not taste: the cuff cone ran from
`hw*0.99` (now hand-based, 0.162-0.202) to `mouth` (forearm-based, 0.130-0.181),
so `hw` EXCEEDED `mouth` and the "cone" was a cylinder. A glove has a waist. The
cuff's hand end is now the arm's radius; the hand shell stays the wider mass.

## THE NUMBER, SAME HARNESS, SAME SIX CELLS, SAME FRAMING, SAME LIGHT

    blender -b -noaudio -P tools/art/d94proof.py -- --repo W5 --only gloves --tag g7b

| | g6 (17 Nov 02:37) | **g7b front** | g7b side | g7b back |
|---|---|---|---|---|
| verdict | PARTLY TOO SMALL 1/15 | **TELLS APART** | **TELLS APART** | **TELLS APART** |
| worst pair | 0.25 % | **5.341 %** | 4.803 % | 4.175 % |
| median pair | 2.251 % | **7.700 %** | 8.183 % | 6.952 % |
| best pair | 4.738 % | 9.649 % | - | - |
| too-small pairs | 1 | **0** | 0 | 0 |
| duplicate pairs | 0 | 0 | 0 | 0 |
| pairs measured | 15 | **15** | 15 | 15 |
| fit faults | 6 | **0** | 0 | 0 |
| blanks / border | 12 files, 0 fail | 12 files, 0 fail, outside 0 | same | same |

7a scored slightly higher on pixels (worst 5.875, median 8.796) and is kept in
`renders/art/d94g7/` as the record. **7b is shipped anyway**: it trades about a
point of median for a silhouette that reads as a glove instead of a drum, and
the picture is the acceptance test. Both are green on the same gate.

`inside_pct` per cell fell from 47-80 % to 12-44 %, and `fit_faults` went from
six CLIPS lines to none.

## THE SECOND FAULT THE ROW NAMED IS ALSO NOT WHAT IT LOOKS LIKE

The row says the cuff topping out at z 0.844 against hand.l 0.547 and chest
0.973 "reads as a waist ornament" and that forearm length is the dial to fix.
Measured, the posed forearm on this body runs **z 0.620 (wrist) to z 0.877
(elbow)**. A cuff ending at 0.844 ends 0.033 below the elbow - it is a vambrace
sitting exactly where a vambrace belongs. Comparing its top to the hand and the
chest skips the forearm, which is the bone it is on. The reason it read wrong on
the sheet was that it was inside the arm, and that is what pass 7 fixed. **The
reach dial is left alone**; shortening it would have removed the one dial that
separates a vambrace from a wrap and would not have made the piece visible.

## THE HONEST FIT LIST - g7b, looked at, front and side and back

1. **Carder's Gloves is still the least glove-like of the six** - the stepped
   profile plus its lames still read as a ribbed drum rather than a cuff.
2. **The hand is hidden behind the cuff** on Quarreller's, Forgemaster's and
   Raidbreaker's from the front and the side. You see a trumpet, not a hand, so
   the knuckle treatments (spikes, studs, dome) do not read on the body at all -
   they are visible only in strip 1. The knuckle dial is currently spent.
3. **Forgemaster's and Raidbreaker's throw a thin blade-like spur forward** off
   the lip's outboard skew. Not a clip (fit_faults is empty) but it reads as a
   stray shard against the tabard.
4. **Bellringer's loose tie - the one direction that cut owns - does not read on
   the body.** It is there in strip 1 and gone at stream size.
5. **Baker's Mitts is the quietest cell**: dark brown on a dark grey body, it
   reads as a lump at each hip. It is half of the worst pair in all three views.
6. **On the side view the near glove completely hides the far one.** Expected at
   90 degrees; it is the same overlap this lane named at System 1 and it means
   the side view measures one glove, not two.
7. The cuff mouth sits across the belt line on the four metal cuts. No clip and
   no float, but the glove and the belt share a silhouette from the front.

Nothing here is blocking and none of it is Mr. E's to decide.

## WIRING - NOT THIS LANE'S

Nothing. `showcase.py` is `tools/art/`. No `.gd` was touched.
