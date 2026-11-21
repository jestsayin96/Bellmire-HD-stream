# THE BEADLE, PASS 13 - THE TWO VALUE FAULTS I WROTE UP AND LEFT UNFIXED

20 Nov 2026, the 18:34 CT art firing. The team lead's 17:58 row: *"YOUR TWO
WRITTEN-UP LEGIBILITY FAULTS, IN ORDER. The four brass pegs at 5 luma and the
staff knob on the pale skull at 10 luma. You wrote both up and left them
unfixed under your own 'one change at a time' rule and that was right; the
42nd is in, so take them now."*

Both are in `docs/art/BEADLE_BACK_AND_THE_UNLIT_BACK_VIEW.md` section 5. Both
are in my own shipped work. Both are the same family: **a feature carried by
HUE against a ground of nearly the same LUMA.** Stream compression crushes
chroma before luma, the creature draws small on a dungeon floor, and a
deuteranope loses amber-on-cream outright.

## WHAT I CHANGED - TWO THINGS, EACH MEASURED ALONE

**(a) THE PEGS NOW STAND ON A DARK RAIL.** `BEADLE_RAIL=0` rebuilds pass 12.
Pass 4's comment says it fixed this by lowering the glow strength until the HUE
survived - a hue fix for a value fault, with the Dyer's own sentence quoted in
the comment while shipping it. The board's own pass-3 answer applied a third
time: dark END CAPS stopped the pale plank bleeding into a pale background, a
dark FERRULE stopped the knob bleeding into the skull, a dark RAIL stops the
pegs bleeding into the board. The rail is DERIVED off the peg run and ROTATED
IN THE BOARD'S OWN PLANE to lie along the stagger - typed square across the
board it would have had to be 0.26 deep against a 0.30 board and would have
turned the pale plank dark. The two empty sockets stay out on the bare pale
plank: a filled call is bright-on-dark, a spent one is dark-on-pale.

**(b) THE KNOB GETS A DARK PLATE BEHIND IT.** `BEADLE_PLATE=0` rebuilds pass
12. Pass 12 put dark ABOVE and BELOW the ball and it works - but the side
camera throws x away, so what is BESIDE the ball in that projection is skull.
**Dark above and below cannot fix a left-and-right fault.** The dark therefore
goes behind it in x: the boss plate a staff head is seated on. Flattened in x
(0.018) so front and back see it edge-on, wider in y (0.150) than the ball's
own 0.092 so it shows past it on both sides in the side view.

## THE NUMBERS, AND THE ONE THAT MATTERS

`tools/art/_beadle_value_ab.py`, verdict GREEN, errors [], 0 blanks, 0 frame
clips, locked camera, bounds asserted equal on every variant.

| | ring-mean gap | **worst-side gap** |
|---|---|---|
| (a) pegs, pass 12 | 0.0899 (22.9/255) | **0.0698 (17.8/255)** |
| (a) pegs, pass 13 rail | 0.4158 (106/255) | **0.3615 (92.2/255)** |
| (b) knob, pass 12 | 0.3574 (91.1/255) | **0.0820 (20.9/255)** |
| (b) knob, pass 13 plate | 0.4820 (122.9/255) | **0.4088 (104.2/255)** |

Each fix measured ALONE reproduces the both-fixes figure exactly, so neither
is credited with the other's effect. The plate costs the FRONT view 744 px of
245,438 - **0.3% of the body**, which is the number behind the word "thin".

## THREE THINGS MY OWN INSTRUMENT GOT WRONG, AND HOW THEY WERE CAUGHT

**1. THE PROBE SLOT WAS SILENTLY DROPPED, AND ONLY THE BOUNDS ASSERT SAW IT.**
To locate a feature's pixels I re-slot its items to a probe material and
re-render through the same camera. `minibosses.merge_objs` iterates a
HARD-CODED slot tuple `('body','dark','bone','glow')`, so a `probe` group gets
no object and no error - the probe render was the body with the PEGS MISSING,
and because the pegs are the topmost thing, `build_miniboss` re-normalised the
whole creature to 2.95 under the locked camera. Every pixel moved. The first
run reported a peg gap of 0.065 over a feature mask of **59,576 px for four
pegs** - 22% of the body - and would have read as a result.
**The per-variant bounds assert fired and the run went RED.** The knob probe
did NOT trip it, because the knob is interior geometry and dropping it moves no
bound - so half the run looked perfectly healthy while resting on the same bug.
That is why the assert is per-variant and not once.

**2. A RING MEAN CANNOT SEE A DIRECTIONAL FAULT - AND FAULT (b) IS ONE.**
With the probe fixed, the knob's ring-mean gap came back **0.3574**, which
reads like a pass, on a body whose written-up fault was that the ball is
pale-on-pale. Splitting the ring by direction says why: above 0.385, below
0.463, right 0.503, **left 0.082**. Pass 12's ferrule and cap had already
fixed three sides, and the mean averaged them with the broken one. The fault
lived entirely in a number the previous harness did not compute. **The verdict
now rides the worst side, not the mean.**

**3. THE RAIL I BUILT FIRST MERGED WITH THE BOARD'S END CAP, AND NO NUMBER
SAID SO.** At length +0.160 the rail's left end landed at dx -0.477 against the
cap's inner edge at -0.4825. Every number in the report was green; the sheet
showed the left third of the board as ONE DARK BLOCK, because the cap's job
needs the pale plank still beside it. Shortened to +0.100: 0.034 of daylight,
about 13 px in the proving render. **Caught by looking.**

## THE FIT PROOF, LOOKED AT

`renders/art/minibosses/beadle/_pass13_proof.png` - hero_front / hero_side /
hero_back beside a posed KayKit knight, colour above and DESATURATED below,
which is the view the fault was about. Register `_fit_beadle_register.json`:
verdict GREEN, ratio 1.20, pair_w 3.74, 3/3 proving views, frame_edge 0 on all
four sides of all three views, errors [].

**EVERY FAULT I CAN SEE IN IT, INCLUDING THE ONES THIS PASS DOES NOT FIX:**

- the BACK view is lit by one coloured lamp and reads brown - the even-light
  fault, approved by the supervisor at 18:32 as a background back-and-side
  re-render. Not done in this commit; it is a separate change.
- the side view still has NO FACE: the pale band carrying the eyes wraps the
  head, so the figure has no facing. The team lead's finding, not my row, and
  it is untouched here.
- **THE RAIL DOES NOT SERVE THE BACK VIEW.** It is on the board's face, so
  from behind the pegs are still pale tips on a pale plank. That is consistent
  with the body's own written claim - the front and three-quarter views carry
  the COUNT, the side carries the board and the tips - but it is a limit of
  this fix and not a fix of it.
- the board's left edge passes behind the hat brim in the front view. Readable,
  unchanged from pass 12, noted so it is not discovered as new.
- the plate slightly covers the pale cheek band in the side view. It is in
  front of the face because the staff is in front of the face.
