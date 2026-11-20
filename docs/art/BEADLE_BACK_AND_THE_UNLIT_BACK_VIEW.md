# THE BACK VIEW HAS NEVER BEEN LIT

20 Nov 2026, 16:34-17:0x CT. ART lane. Machine clock read with `TZ=America/Chicago date`.

I took the plan's second option for the ART lane - "the Beadle's missing rear facing, which is
still open and is still yours" - and the answer is that **the Beadle's rear facing is NOT missing,
and the reason the question stayed open for two days is that nobody in this house has ever seen a
back view of anything.**

---

## 1. THE FAULT, AND I MEASURED IT BEFORE I NOTICED IT

`tools/art/lordgen.py:176 add_lights()` builds the rig in WORLD space and `minibossfit.shoot()`
never moves it:

    key   SUN  from (0.9, -1.0, 0.85)   energy 2.3   warm white
    fill  AREA from (-1.0, -0.6, 0.35)              cool blue
    rim   AREA from (0.1,  1.0, 0.55)               colour = THE CREATURE'S OWN `aura`

Key and fill both sit on **-Y, the front**. The only lamp on +Y is the rim, and its colour is a
per-creature value out of `CANON`. The camera orbits to az 180 for the back view. The rig does not.

**So every back view in this file is lit by one coloured lamp and nothing else.**

### THE PROOF IS THE HERO, NOT THE CREATURE

The creature changes from cell to cell, so measuring the creature proves nothing. The **KayKit
Knight is the identical object, at scale 1.0, with identical materials, in all 41 cells.** Mean RGB
of that one body, measured off the shipped renders with numpy over alpha>0.5:

| body | hero front | hero back | that creature's aura |
|---|---|---|---|
| beadle | 108 / 105 / 108 | **121 / 76 / 56** | 1.00, 0.74, 0.26 (amber) |
| leech  | 109 / 105 / 109 | **120 / 53 / 48** | 1.00, 0.22, 0.14 (red) |
| dyer   | 108 / 105 / 110 | **75 / 67 / 90**  | 0.26, 0.46, 1.00 (blue) |

One body. One material. Three back views - **amber, red and blue - and the hue is the creature's
aura every single time.** The knight's steel reads olive-brown behind the Beadle and its red cape
reads dull brick. Not one back render in this tree shows a true value.

**THIS IS TRAP 5 AGAIN AND IT IS MINE.** "An instrument that cannot SEE is not a pass." Every
judgement this house has made off a back view went through a single coloured lamp: my own register
lines, and the team lead's reading of the Beadle. A `seen: 1.0` was never going to catch it, because
`seen` asks about occlusion and has no opinion about light.

---

## 2. THE FIX, AND THE CONTROL THAT MAKES IT AN A/B

`minibossfit.even_lights()` / `aim_lights()` - the same three lamps, kept as objects, spun about Z
by the camera's azimuth each view so the rig is fixed **relative to the viewer**. The rim travels
too, so it stays a rim instead of becoming a key.

    blender -b -noaudio -P tools/art/minibossfit.py -- --repo W5 --only beadle \
            --evenlight --tag _even --name _ab_beadle_even

**THE CONTROL IS THE WHOLE REASON TO BELIEVE IT.** At az 0 the rotation is the identity, so the
front view must come out byte-for-byte the same. It does:

    front  world vs even:  mean delta 0.00, max 3, pixels changed >12: 0
    side   world vs even:  mean delta 11.20, 75,294 px changed
    back   world vs even:  mean delta 15.39, 98,369 px changed

A front view that moved would have meant I had rebuilt the rig rather than carried it. It did not
move. The hero's back-view mean goes **121/76/56 -> 122/85/88**; R/B 2.16 -> 1.38.

Sheet: `renders/art/minibosses/_beadle_lightab.png`. A/B dirs kept as evidence:
`beadle_world/`, `beadle_even/`.

**IT IS DEFAULT OFF AND THAT IS DELIBERATE.** Turning it on changes every pixel of every hero view
in the tree - 41 bodies x 3 views. That is a separate decision and a separate firing, not something
to slip in under a Beadle fix. **I recommend turning it on fleet-wide and I will take that re-render
next firing unless told otherwise.**

---

## 3. THE ANSWER TO THE OPEN QUESTION: THE BEADLE DOES HAVE A REAR FACING

Under even light, looking at `beadle_even/hero_back.png` myself:

- **no face and no eyes.** The head reads as a dark drum. The pale skull that fills the front is
  gone; what is left is the narrow cream nape band low on the drum, under the hat.
- the staff has swapped sides with the figure, the way a 180-degree camera move makes it.
- the board's pegs point away and the two empty sockets are not visible at all.

The pass-12 `BEADLE_NAPE` change did its job. **The team lead's reading - "the pale band carrying
the eyes wraps the head so the figure reads the same from front and back" - is not what the body
does now, and I do not think it was a bad reading: it was made on a picture lit by one amber lamp,
where the dark drum and the cream band are both mud.** I would rather say that than claim the row
was wrong.

**THE HONEST LIMIT:** the outline is still close front-to-back. It is the VALUE break - pale head
forward, dark head away - that carries the facing, not the silhouette. Same weaker-claim-is-the-true-
one as the Relief write-up.

---

## 4. THE SHIPPED BEADLE RENDERS WERE TWO DAYS STALE AND NOBODY HAD CHECKED

`beadle/hero_front.png` was dated 18 Nov 15:54. Re-rendered today with the SAME lighting and the
current harness it differs by **96,179 px over threshold, 32,697 of them in ALPHA** - that is
geometry and framing, not shading. The cause is benign: the trio predates the 18 Nov 18:5x aim-point
`drop` fix and the hero-view border check, so the pair was framed higher and smaller.

Its `_fit_report.json` row has **no `frame_edge` key at all**, which is the tell. Refreshed this run:

    renders/art/minibosses/_fit_beadle_register.json
    verdict GREEN, errors [], blind_views [], ratio 1.20, pair_w 3.74,
    3/3 proving views, blank failures 0, frame_edge 0 on all four sides of all three views

**A RULE I AM WRITING DOWN FOR MYSELF:** a register is a measurement of a moment. When the harness
changes, every register taken before it is a claim about a picture that no longer exists.

---

## 5. TWO FAULTS I CAN SEE THAT NO NUMBER IN THE REGISTER REPORTS

Both are the same family and both are in my own shipped work.

**(a) THE PEG GAUGE IS CARRIED BY HUE AND NOT BY VALUE.** The four brass pegs are the thing a viewer
must count from the door. Measured off `beadle/hero_front.png`: pegs (204,168,108) **luma 172**,
board top face (168,168,156) **luma 167**. **Five luma apart out of 255 - 2%.** Desaturate the crop
and the pegs very nearly vanish into the plank; the sheet
`renders/art/minibosses/_beadle_peg_value.png` shows colour above and value below.

Pass 4's comment says it fixed exactly this - "the pegs rendered CREAM, the exact colour of the oak
board" - by lowering the glow strength until the HUE survived. **That was a hue fix for a value
fault.** Stream compression crushes chroma before luma, the creature draws small on a dungeon floor,
and a deuteranope loses amber-on-cream entirely.

**PROPOSED FIX, NOT MADE THIS RUN (one change at a time):** darken the board's peg face into a
**dark peg rail** so four bright teeth stand on a dark bar - value contrast - and the empty sockets
become dark gaps in a pale board elsewhere. That is the Beadle's own stated logic ("put the DARK
body against the PALE furniture") applied to its gauge instead of only to its coat.

**(b) THE STAFF KNOB IS PALE-ON-PALE ON THE FACE IN THE SIDE VIEW.** `hero_side.png`: the amber knob
(200,170,110) **luma 172** sits directly across the pale skull (170,160,150) **luma 162** - ten luma,
4%. It reads as a smudge on the cheek. The docstring says pass 5 moved the staff top precisely
because "hero_side.png read the whole top of the staff as a smudge on the face". **It is back, and
the register scored 3/3 proving and `seen 1.0` on that view while it was.**

---

## 6. WHAT THE REGISTER STILL CANNOT SEE, SAID PLAINLY

`visibility.seen` answers **one** question: is this subject occluded by the other one. It has no
opinion on

- whether a view is LIT (section 1 - it scored 1.0 on all three Beadle views the whole time),
- whether a creature's own parts hide each other,
- whether two views have different silhouettes,
- whether a gauge separates in VALUE as well as in hue (section 5),
- whether the render matches the generator that is on disk today (section 4).

Three of those five were caught this hour by looking at a picture. None by a number.
