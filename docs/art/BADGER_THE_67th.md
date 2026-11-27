# THE BADGER - "Forestall" - the 67th miniboss

Made by the ART lane, 27 Nov 2026, the 07:34 CT firing. Theme `mess`.
Height 2.43 m. Static - **no `anims` entry**. 3 meshes, 1738 faces.

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

- `tools/art/minibosses.py` `ORDER` parsed with a comment- and string-aware
  reader (not a per-line regex - the team lead's and the chat bot's matchers
  were both wrong on exactly that this same morning): **66 live keys**, no
  duplicates, `ORDER` minus `BUILDERS` empty. The fit register judged 77 rows
  = 66 live + 11 retired `_chibi`. So this is the 67th.
- I read **all 66 mechanics out of CANON in full** before designing, including
  the ones whose strings are wrapped across lines.

## THE FIRST DESIGN, THROWN AWAY UNBUILT

A FOWLER working from behind a line of wicker decoys, so the party spends its
blows on the wrong body. **Dropped: it is a re-skin of the BELLMAN.** Tolburn
already owns that fight - "two bells on two long arms and a third on a pole
behind it ... the party swings at a bell. Only one of the three is ever on
it" - and the bellman's own builder calls that third bell "the decoy". A decoy
in wicker instead of bronze is the same fight in a different material. It cost
a pass of design time and no modelling, because the check came before the mesh.

## THE IDEA, AND THE HOLE IT FILLS

**IT IS LEAVING, AND WHAT GETS OUT WITH IT COMES OFF THE TOWN.**

All 66 existing bodies spend their whole effect inside the room they stand in -
on the party, on the room, on the other monsters, on the party's kit and haul,
or on the rules of the beat. **Not one of them costs the party anything that is
still gone when the delve ends.** This one does. It does not strike, summon or
hold anything of yours. It walks for the stair under a shoulder yoke with four
sacks of Bellmire's own stock, and every sack that leaves the floor is gone
from the granary when the party gets home. You can win the fight and be poorer
for it.

### The two bodies it is nearest, named rather than hoped away
- **TALLYMAN (Velmok)** "it lifts your gear, wears it and withdraws". Velmok's
  theft is recoverable *inside the fight* - kill it and the gear comes back.
  This one's is not.
- **REEVE (Lockwarden)** "while it stands the floor pays its box and not you".
  Lockwarden denies the room's takings and dies with its box in the room. This
  one removes stock that was *already the town's*.

If Mr. E reads either as the same fight, this body is a re-skin and I would
rather be told so than carry it.

A badger (lader, kidder) bought corn in one parish and carried it off to sell
in another; badgering and forestalling were prosecuted because the parish went
short. Nothing theatrical: a man with a yoke and four sacks, going the other
way.

**Wear 0.55** on coat, hood, yoke and boots - he walks for a living. The sacks
are the one new, full, pale thing on him, because they are this morning's stock
out of the store. Condition is the receipt.

## FIT PROOF - MEASURED, AND THEN LOOKED AT

`renders/art/minibosses/badger/hero_front.png`, `hero_side.png`, `hero_back.png`
- rendered beside a real KayKit adventurer at scale 1.0.

| term | value |
|---|---|
| ratio | **0.99** (creature 2.43 / hero 2.45) |
| pair_w / margin_x | 3.04 / 0.12, `fits_frame` true |
| proving views | 3 (front, side, back), `seen` 1.0 on all |
| frame_edge | 0 on all four sides of all three views |
| blank check | 201 files, **0 failures** |
| corridor / lid | CORRIDOR-SAFE (span 1.47 m), UNDER-LID |
| man_seen | front 0.908, side 0.869, back 0.838 |
| value_man_visible spread | front 0.520, 4 bands at 5% |

**GAME BUILD: read `pairs.badger` out of `renders/art/minibosses/_fit_report.json`.
Ratio 1.04 is the THATCHER'S number and 0.97 is the MEALMAN'S. Neither is this
body's. Do not re-derive it and do not copy it from a prompt or a plan row.**

## PASS 3 - THE HEAD. ONE FAULT CLOSED, TWO STILL OPEN, AND MY FIX CAUSED
## THE THING IT WAS MEANT TO CURE

Pass 3 changed the head and nothing else: a shorter blunt crown, a brim that
overhangs on -y only, and the face oval repainted from the coat's value to the
cape's (8.5x the hood's albedo instead of 2.9x - the thatcher's pass 6 proved
2.9x is one band once lit, which is why the oval had been invisible).

- **FAULT 4 IS CLOSED.** The head reads as a plain brimmed working hat. The
  pointed-hat silhouette is gone.
- **FAULT 1 IS STILL OPEN AND MY OWN FIX IS NOW THE CAUSE.** The brim I added
  so the hood would have an opening OVERHANGS THE FACE from the fit camera's
  slight downward angle, so the face oval is in shadow behind it and still
  does not read from the front. The value change was right and the geometry
  that was supposed to reveal it is what hides it.
- **FAULT 2 IS IMPROVED, NOT FIXED.** The raked crown and brim give the front
  and back different outlines, but at hero distance both still read as "dark
  hatted figure, two pale sacks, dark bar". A body whose facing rests on a
  brim edge has a weak facing.
- Numbers after pass 3, for the record: man_seen front 0.907 / side 0.869 /
  back 0.840; `value_man_visible` spread 0.521 / 0.495 / 0.502, bands_5pct
  4 / 4 / 5. Register `ok: true`, verdict GREEN, errors [], blank 201 / 0.
  **Every one of those was green while the face was invisible.** They are not
  wrong, they are answering a different question.

## PASS 4 - FAULTS 1, 2 AND 3, IN THAT ORDER. TWO CLOSED, ONE IMPROVED,
## ONE NEW FAULT INTRODUCED BY MY OWN FIX

Run at the 08:34 CT firing, 27 Nov, on the team lead's 08:09 correction block,
which withdrew the 67th's tick and sent this lane back to the fit. It was
right to. **Two instruments were built for this pass because neither fault had
a number attached to it, and both of them caught me.**

### THE PASS-3 CAUSE WAS WRONG, AND I FOUND THAT BEFORE MOVING ANY GEOMETRY

Pass 3's write-up blamed the BRIM for hiding the face. I measured the hood
CONE against the face oval in the model's own axes first, and tucking the brim
back would not have fixed anything:

| at the face oval's own height, z 1.812 | model y |
|---|---|
| hood cone's front edge | **-0.407** |
| face oval's front surface | -0.376 |

**The hood stood 3.1 cm in front of the face.** The brim made it worse; the
cone made it impossible. Had I moved only the brim I would have rendered the
same black void and shipped a second wrong cause on top of the first.

### FAULT 1 - NO FACE. CLOSED, AND MEASURED, NOT ASSERTED

`tools/art/_faceseen.py` (written for the thatcher, re-used here - a new body
is the wrong place to invent an instrument) renders the body with the face
oval repainted into the hood's own slot, through ONE locked camera, and counts
the pixels that MOVED. Vertex-identical builds, `bounds_drift` asserted 0.0.

| view | pass 3 face_seen | pass 4 | pass 3 face/ring ratio | pass 4 |
|---|---|---|---|---|
| front | 119 px | **3117 px** | 0.803 | **2.398** |
| side | 88 px | **1122 px** | 1.003 | **2.398** |
| back | 0 px | **0 px** | - | - |

Two things in that table matter more than the pixel jump. **The pass-3 ratio
was 0.803 on the front - the face was DARKER than the hood around it**, so
even the 119 px that reached the camera could not have been read as a face.
And on the side it was 1.003, dead level, which is the Thatcher's lap fault
exactly. **And the pass-3 run went `ok: false`**: its own control refused to
call 119 px a measurement. The instrument went red on the old geometry, which
is what an instrument is for.

**Back is 0 and that is the DESIGN, not a fault** - a face visible from behind
is the Beadle's no-facing fault built in on purpose.

THREE MOVES, AND THEY ARE ONE MOVE - PUT THE FACE IN FRONT OF THE HOOD. Cone
base 0.250 -> 0.218 and tucked to y -0.150; brim tucked to y -0.165 and
narrowed in y; face oval pushed proud to y -0.330 and raised to z 1.826, eyes
with it. **The cone's AIM is untouched, so the forward rake the side view
lives on survives** - and I checked that by looking, not by assuming.

I LOOKED AT THE FRONT RENDER: there is a pale oval with two dark eyes under
the hat brim and it reads as a face. Plain, weathered, no expression.

### FAULT 3 - THE COUNT. FROM 2/2/2 TO 4/4/5, AND IT TOOK FOUR HANGS

`tools/art/_sackcount.py` is new. It renders the body with and without the
`bone` mesh through one locked camera, intersects the moved pixels with the
slot's own solo silhouette so a shadow lifting off the coat cannot be counted
as a mass, and labels the connected components. It goes RED ON EMPTY.

**It reports COUNTABLE beside SEPARABLE, because this fault flattered itself
in BOTH directions during this one pass:**

| hang | front | side | back | what the areas said |
|---|---|---|---|---|
| pass 3 | 4 sep / **2 countable** | 2 / 2 | 2 / 2 | 16499, 15345, **570, 123** - two sacks and two slivers. The raw 4 was never a four. |
| 1 - zigzag, 2 columns | 3 / - | 2 / - | 3 / - | 0.38 pitch against a 0.52 sack OVERLAPS |
| 2 - row of four | 4 / - | **5** / - | **5** / - | five is WORSE than four: a sack cut in half by the coat edge, counted twice |
| 2b - row pushed out in y | 3 / **3** | 3 / 3 | 3 / 3 | 8304, 8295, 8278 and occlusion exactly 0.25 - **one whole sack behind the man** |
| 3 - two columns, 0.53 pitch | 5 / **2** | 3 / 3 | 4 / 2 | a 16588 px component - two sacks touching |
| **4 - shipped, 0.60 pitch** | 6 / **4** | 4 / **4** | 5 / **5** | side is four near-equal masses: 7047, 7031, 7029, 6282 |

Each failure named the next cause, which is the only reason this converged:
overlap -> the sacks hang THROUGH the coat and trunk -> the inboard sacks hide
behind the trunk (so every sack must clear |x| 0.364, so it must be two
columns after all) -> they touch, so open the pitch.

**THE "COUNTABLE" CUT IS A JUDGEMENT AND IT IS WRITTEN DOWN IN THE FILE RATHER
THAN BURIED IN A THRESHOLD**: a component under a quarter of the largest on
that view is a peek, not a load. It was not chosen to make this body pass -
under it pass 3 reads 2/2/2 and hangs 1-3 read 3/3/3 or worse.

**AND AT HANG 3 THE NUMBER AND THE PICTURE DISAGREED, AND I BELIEVED THE
PICTURE.** The instrument said 2 countable on the front; I looked and could
plainly count four, because two sacks TOUCHED and a flood fill cannot see the
shading seam an eye reads them apart by. That is the instrument being
STRICTER than the viewer, which is the rarer direction - and I opened the
geometry's pitch rather than loosening the test.

**BACK STILL READS 5 AND I AM NOT CLAIMING OTHERWISE.** One sack is fragmented
from behind. Front 4, side 4, back 5, against 2/2/2 before. **Fault 3 is
largely closed, not closed.**

### FAULT 2 - NO FACING. IMPROVED, NOT CLOSED, AND MY OWN INSTRUMENT FAILED

`tools/art/_facingread.py` is new: front against the MIRRORED back through one
camera, silhouette IoU and interior luma difference, run over six bodies so
the number has a scale instead of an invented pass mark.

**IT DOES NOT ANSWER THE QUESTION AND I AM REPORTING IT AS A FAILED
INSTRUMENT, NOT AS EVIDENCE.** At pass 3 - with provably no face in any view -
the badger scored `in_diff_frac` **0.4369**, HIGHER than the Beadle's 0.3233.
The Beadle is the body whose no-facing fault is the known one in this house.
A test that ranks the badger's blank back above the Beadle's is measuring
STRIDE AND POSTURE, not facing; this body is mid-stride with one hand up on
the yoke and that asymmetry swamps the signal. The file now says so in its own
docstring under "what it cannot see". It is kept because "are these two
pictures different" is still a real measurement, and `sil_iou` did move the
right way (0.8671 -> 0.8107). **It is not allowed to certify fault 2.**

So fault 2 is judged BY LOOKING, and the honest answer is IMPROVED, NOT
CLOSED. The front now carries a face the back has not, which is a real facing
where pass 3 had none. But **the largest pale shape on the body - the leather
yoke-cape - is identical from both sides**, and at stream distance that
trapezoid is what a viewer reads first. The face is small. A later pass should
put the facing on the cape or on the coat front, where the area is, rather
than on a 3000 px oval.

### A NEW FAULT MY OWN FIX INTRODUCED, SEEN IN THE SIDE VIEW

Each rope now drops from the bar to ITS OWN sack instead of from the two bar
ends. From the front that reads as four hangers and helps the count, which is
what it was for. **From the side the two aft ropes rake across the figure as
long straight diagonals and read as RIGID STRUTS - a sawhorse or a scaffold,
not rope.** It is a regression in the side view, which was the view that
worked, and it is mine.

### FAULT 7 - THE CAPE - IMPROVED, BY EYE AND NOT BY NUMBER

The leather yoke-cape, invisible in all three views at pass 3, is now plainly
visible as a mid-value mantle in all three. I did not measure it separately
and I am not claiming a number for it.

### WHAT THIS PASS DID NOT TOUCH

Faults 5, 6, 8 and 9 are unchanged and are listed below as they stand. **Fault
5 is arguably LOUDER**: smaller, separated, narrow-necked sacks read more like
hanging gourds or lanterns than pass 3's two lumps did. The count was the
instruction and the count is what was bought.

### REGISTER AFTER PASS 4

`ok: true`, verdict GREEN, errors [], blind_views [], 69 rows judged, blank
201 files / 0 failures, frame_edge 0 on all four sides of all three views.
ratio 0.99, margin_x 0.12, air_px_min **146** (side, still the tightest),
pair_w **3.17** (was 3.07 - the sacks are wider in x). Span **1.51 m**
(was 1.47), CORRIDOR-SAFE, UNDER-LID, 3 meshes, 1836 faces.

**GAME BUILD: pairs.badger moved this pass. Re-read it from
`renders/art/minibosses/_fit_report.json`. Do not use any number printed in a
plan row, including pass 3's air_px_min 149 - it is 146 now.**

## OPEN FAULTS - WHAT I CAN SEE IN THE RENDERS, AND I LOOKED AT ALL THREE

1. **NO FACE, IN ANY VIEW.** Still open after pass 3. At pass 2 the closed
   cone hid the oval; at pass 3 the brim added to open the hood hides it
   instead. Loudest fault. The next pass should raise the face oval and tuck
   the brim back, or drop the brim and carry the facing on the crown rake
   alone - ONE of those, not both at once.
2. **NO FACING - THE BEADLE'S FAULT, REPRODUCED.** Front and back read almost
   identically: a dark cone-headed figure with two pale sacks and a dark bar.
   **The builder carries a comment claiming the facing is "geometric by
   construction". The picture refutes my own comment.** I predicted the
   mechanism and did not verify the outcome.
3. **THE COUNT DOES NOT COUNT.** Four sacks read as *two* from the front, *two*
   from the side (the near pair occludes the far pair almost exactly) and *two*
   from the back. The builder comment claims the offsets give "every ortho four
   separable masses"; that is also refuted by the picture. This is the worst
   fault in substance, because the count IS the mechanic - a viewer who cannot
   count the sacks cannot judge whether to go in.
4. ~~The hood apex reads as a pointed hat~~ **CLOSED AT PASS 3.**
5. The sacks read as lumpy gourds or bottles rather than grain sacks; the
   bottom bulge makes them read like boxing gloves from the front.
6. The yoke reads as a black coat-rack bracket from the front and the hands are
   not visibly on it.
7. **The leather yoke-cape, the body's one mid value, is invisible in all three
   views.** `value_man_visible` spread 0.520 / 4 bands is better than the
   thatcher's 0.238 / 3, but I cannot see the cape anywhere, so I believe that
   spread is bought by the sacks against the coat and NOT by the cape. The
   number and the picture disagree; the picture is the evidence.
8. Beside the chibi KayKit hero the body reads tall, thin and lamp-like - the
   same proportion mismatch that produced the 11 retired `_chibi` rebuilds.
9. From the front the trailing boot reads as a detached black block sitting at
   a different height from the other foot.

**WHAT READS, AND IT IS WORTH KEEPING:** the SIDE view's stride. Forward leg
planted, trailing heel up, coat swinging - he reads as a man walking away with
a load, and no other body in the set is mid-stride. `_legs` exists to give the
set a shared PLANTED base; this is the one body that must not use it.

## A DEFECT MY OWN ASSERTION COULD NOT SEE

Pass 1 put the legs, trunk, neck and both arms into the **pale** slot:
`creatures.limb` defaults to `slot='bone'` (the bellman depends on that - its
shroud is meant to be pale). The render showed white stick legs and the four
sacks lost among five other pale masses - the Mealman's rule broken on the one
body whose whole mechanic is counting the pale things. **The three luma
assertions passed clean through it**, because they compare declared colours and
cannot see which slot a call landed in. Fixed in pass 2 by passing
`slot='body'` explicitly on every `limb()` call. The only reason it was caught
is that I looked at the picture.

## WIRING THE GAME BUILD MUST DO - I DO NOT DO IT

1. `scripts/delve.gd` - `MB_NAME.badger = "Forestall"` and the `MB_FIT` pair.
2. `scripts/bestiary.gd` - entry with
   `model res://assets/monsters/minibosses/badger.glb`, `h 2.43`, and
   **NO `anims` entry** - the body is static.
3. Hold it off floors with `miniboss_for` exactly as fanner, mealman and
   thatcher were held, until content has written its `by_key` row.
4. CONTENT writes `miniboss_feed.by_key.badger` first. The feed line is:
   **"Something ahead is carrying sacks the wrong way."**

The cascade order is unchanged: content's `by_key` row, then the game build's
`MB_NAME`, then the chat bot's published count.


---

## PASS 5 - 27 NOV 2026, 09:34-09:45 CT. THE TEAM LEAD'S 08:58 ROW, BOTH ITEMS.

The row asked for two things in order and nothing else ("BADGER PASS 5. **NOT
THE 68th.**"). Both are done and both were judged BY LOOKING, as it required.

### (a) FAULT 2 - THE CAPE HAD NO FACING. THE CAUSE WAS ONE WORD: `cone`.

The lead: "the largest pale shape on the body - the leather yoke-cape - is
identical from both sides, and at stream distance that trapezoid is what a
viewer reads first."

He is right, and the cause is not a tuning value. `L.cone` IS A SURFACE OF
REVOLUTION ABOUT ITS OWN AXIS: the cape **could not** have a facing, by
construction, whatever numbers went into it. The single `aim` direction
(0, -0.130, 1.0) tips it about 7 degrees forward, and that tip was the entire
difference between the front and the back of the biggest pale mass on the body.
Sub-pixel at stream distance. No amount of re-tuning that cone would ever have
closed this.

So the fix is not to the cone. It puts pale AREA on the front that has no
counterpart on the back, and the trade supplies the reason: a yoke pad is
STRAPPED ON. Two leather straps run from under the front hem down the chest to
a belt at the waist - that is what keeps the pad from riding off the shoulders
when the man walks. Same vertex colour, so all three luma guards are untouched
and no fourth value was added to argue with the sack count.

JUDGED BY LOOKING, front and back opened side by side:
  FRONT - pale trapezoid, then two pale bands continuing down the chest,
          crossed by one dark bar.
  BACK  - plain pale trapezoid, clean hem, dark coat below it and nothing else.
The two no longer read as the same figure. The facing is now carried by the
mass a viewer reads FIRST, not by a 3000 px oval he reads last.

A SUPPORTING NUMBER, AND IT IS SUPPORTING ONLY - THE PICTURE IS THE EVIDENCE.
Counting CAPE-coloured pixels (chroma > 0.06, which on this body is the pad,
the straps and the face oval and nothing else) on the creature-alone renders:
  front 4289 px, reaching 47.7% down the figure
  back  2083 px, reaching 29.9% down the figure
  -> the front carries 2.06x the leather and it runs 18 points further down.
MY FIRST ATTEMPT AT THIS MEASURE WAS WRONG IN BOTH DIRECTIONS AND IS RECORDED
HERE BECAUSE IT WILL BE MADE AGAIN. I banded by luma 0.085-0.33 and called it
"the leather". That band INCLUDED the coat (luma 0.118) and EXCLUDED the cape
(0.344), so it measured the coat; it read 1.000 "reaches the bottom of the
figure" on all three views, which a shoulder pad cannot do, and that tell is
the only reason it was caught. The band is now taken off the actual pixels, not
from theory, and it is guarded RED ON EMPTY. It certifies nothing.

### (b) THE ROPE STRUTS - MY OWN PASS-4 REGRESSION, AND THE CAUSE WAS A COMMENT THAT WAS HALF TRUE.

The lead confirmed it by looking: "in hero_side.png the two aft ropes read as
long straight RIGID STRUTS - a sawhorse, not rope."

Pass 4 wrote `# the rope leaves the bar DIRECTLY ABOVE ITS OWN SACK` and then
started all four ropes at a FIXED `y = -0.100`, while the sacks sit at
y -0.455 and y +0.415. The comment was TRUE IN X AND FALSE IN Y, and nobody
reading it would have caught that. An aft rope therefore ran 0.515 back and
0.611 down: a straight metre of dark at 40 degrees. Rope does not hold an
angle, so it read as a strut. It only showed in the SIDE view because that is
the one camera that sees y.

THE HONEST FIX IS THE YOKE, NOT THE ROPE. One bar across the shoulders can hang
TWO loads; this man carries FOUR, two of them aft. He therefore carries a
CROSS-YOKE - the shoulder bar plus a short fore-and-aft spar at each end -
which is what anyone hanging four loads off one set of shoulders actually uses.
Every rope now drops dead vertical in x AND y, so no camera has a diagonal left
to read as a strut. Confirmed by looking at hero_side.png: the sawhorse is
gone. THE FOUR-HANGER READ THAT PASS 4 BOUGHT IS INTACT - I counted four sacks
by eye in front, side and back; the spars are horizontal, dark and continuous
with the bar at the top of the figure, and read as the yoke frame, not as
masses. The stride survived.

### WHAT I CAN STILL SEE, AND IT IS NOT DRESSED UP.

1. THE STRAPS ARE STUBBY. They run from the cape hem to the belt and at close
   range read as two short pale tabs rather than as straps. They carry the
   facing, which was the job, but they are not yet handsome.
2. THE BELT IS HALF BURIED behind the straps and the near sack; it reads more
   as a shadow than as a belt.
3. **THE ONE WORTH THE NEXT PASS:** at THREE-QUARTER the fore sack hangs across
   the chest and partly covers the new harness. Straight-on front is clear
   (the sacks are outboard in x), but 3/4 is the view a bestiary portrait is
   most likely to use, so the facing cue is weakest exactly where it may be
   needed most. The hat, the face oval and the stride still carry the facing
   there, so this is a weakening and not a return of fault 2.
4. The spar ends overhang past the outer ropes far enough to read faintly as
   scaffold at 3/4.
5. The cape hem shows a stepped edge where the cone's 16 segments meet the
   straps.

### GATES

minibossfit --only badger: verdict GREEN, ok true, errors [], blind_views [],
stale_margin [], 69 rows judged, ratio 0.99, pair_w 3.17, fits_frame true,
seen 1.0 and proves true on all three views.
BLANK: 201 files checked, 0 failures. BORDER: frame_edge 0 on top, bottom,
left and right in all three views; air_px front [164,163], side [146,149],
back [163,164].
minibossgen --only badger: ok true, errors [], blank [], badger span 1.51 m,
CORRIDOR-SAFE, UNDER-LID, 3 components. NOT room-locked.
THE .glb WAS REBUILT, 211,172 -> 218,252 bytes. minibossfit RENDERS FROM THE
BUILDER AND DOES NOT EXPORT, so a pass that runs only the fit harness ships new
pictures over an old body. That nearly happened here and is written down.

### WIRING - UNCHANGED BY THIS PASS.

Pass 5 changes geometry only. No new file, no rename, no new slot, no `anims`.
Every wiring line in the section above still stands exactly as written.
