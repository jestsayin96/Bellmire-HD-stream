# THE OVERLOOKER - the 63rd miniboss

`overlooker` / **Velrick** / 2.40 m / theme `workshop` / wear 0.18 / static, no armature.
Invented 25 Nov 2026 under Mr. E's standing permission of 15 Nov 17:43. No lore, no
canon entry, no content-lane dependency.

**THE IDEA: IT STRIKES WHOEVER HAS DONE IT LEAST HARM.** It is not dealt a target and
it does not pick one: it goes for whoever has hurt it least, and it re-reads that the
moment it changes. The back of the room stops being the safe place. A healer who only
heals, an archer who holds a shot, anyone who steps out to drink a flask becomes the
target BY DOING THAT, and the hero carrying the fight is the one it will not touch.
Hitting it harder does not protect you - it moves the mark onto whoever did not.

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

The art prompt still says "THIRTY-THREE already exist as of 18 Nov". **That is stale by
twenty-nine.** Measured four ways this run before a vertex was placed:

| measure | result |
|---|---|
| `ORDER` in `tools/art/minibosses.py` | 62 unique keys |
| `CANON` entries | 76, of which 62 bases + 14 chibi/tall variants |
| team lead's running body count | 62 |
| → so this is | **the 63rd** |

I then parsed all 62 `idea` strings out of CANON with `ast` and read them, rather than
skimming. Families already taken: light, air, water, floor, walls, position, the party's
kit (eleven of them), healing, self-repair, removal-of-one-hero (eight), damage-routing.

**WHY THIS IS NOT THE DYER, which is the one it could have been.** The Dyer (24) MARKS
ONE OF YOU AND HUNTS ONLY THE MARK. That mark is arbitrary and fixed - dealt by the boss,
and the party plays around a choice already made. This inverts both halves: the target is
EARNED, not dealt, and it is continuously re-read, so it moves the instant anyone's
contribution changes. The Dyer punishes luck; this punishes hanging back. Nothing in the
62 picks its target out of the party's own play.

**THE PROP WAS KILLED BY THE SAME GREP.** The first design I took as far as numbers was a
man with a CANE held out, pointing - and `cane` appears nowhere in the file, which looked
clear. It is not: `staff` appears 30 times and `baton` 3, and the BEADLE (33) carries a
pale staff of office while the DRILLMASTER (1) carries a parade baton. An overlooker with
a stick is the Beadle with the stick turned horizontal. **So he carries nothing.** In a
file of 62 carriers and haulers, the one figure holding no object is a silhouette none of
the others can be confused with - and it is the character: the only thing down there that
is not working.

**THE HEAD IS THE MECHANIC AND IT IS A CUE THIS FILE HAS NEVER USED.** Grepped: the only
yawed head in the set is the Timberman's head *tree* at 22 degrees, and two bodies
deliberately built heads whose silhouette is IDENTICAL AT EVERY YAW - the opposite. His
head is turned off his own shoulders: he is not looking where he stands. That answers the
Beadle's second shipped fault (a figure that reads the same front and back has no facing)
by construction, and it is the targeting telegraph, so the mechanic is visible before the
fight starts - the Scrapwright lesson.

## THE THREE PASSES, AND PASS 1 FAILED ON THE PICTURE WHILE EVERY NUMBER READ GREEN

Pass 1's report was `ok: true`, errors `[]`, blanks `[]`, CORRIDOR-SAFE, UNDER-LID, 4
meshes. **It was still a failure**, and nothing in the report could say so.

- **FIX A - THE COAT WAS BUILT UPSIDE DOWN, AND THIS WAS A PLAIN BUG.** `L.cone` is
  `(r_base, r_top, h)` with the base at z=0. Pass 1 passed `(0.300, 0.520)`, so the skirt
  came out NARROW AT THE HEM AND WIDE AT THE WAIST - an upturned bell whose widest point
  was his belt, 0.68 wider than his own shoulders. It read as a chess piece with a man's
  top screwed into it: the Scrapwright's pass-1 "balloon on two legs", arrived at by
  arithmetic. Radii reversed and the hem lifted; the shoulders (0.87 across) are now the
  widest upper mass against a 0.91 hem.
- **FIX B - THE HEAD HAD NO FACE, WHICH IS THE FAULT THIS BODY CLAIMS TO ANSWER.** Pass
  1's "jaw" was a 0.090-thick slab aimed at +Z - laid flat, and it vanished. The head was
  then a sphere under a round cap: no profile from the front and **no face at all from
  the side**. The Beadle fault, shipped in the first pass of the thing built to answer it.
  It is now a snout 0.250 long built along +Z and aimed down his line of sight, so the
  head's mass is off-centre and no camera finds it symmetric.
- **FIX C - CAP, SKULL AND COLLAR MERGED INTO ONE DARK COLUMN.** The collar was 0.246 at
  the mouth and 0.180 tall and the head sat inside it; the side view read as a stack of
  plates. Smaller and lower, so a lit neck separates them and the head is its own island.
- **FIX D - THE EYES WERE 1.0 PERCENT OF THE BODY** (0.025 on 2.40 m) and near-invisible
  at 700 px, so at the 360p rung the collier was just measured at they would not exist.
- **FIX E - THE MITT SAT AGAINST THE SKULL IN THE SIDE VIEW.** 57 degrees of yaw put 0.84
  of the arm into the front ortho and only 0.54 into the side one, and the pale mass read
  as part of the head - the Beadle's pale-knob fault in a different hat. 47 degrees splits
  it 0.73 / 0.68, and the arm was lengthened 0.640 -> 0.770 and dropped.
- **FIX F (pass 3) - THE BRIM OVERHUNG ITS OWN EYES.** Brim 0.268 against eyes at 0.208
  along the same vector: the brim shadowed the cue I had just enlarged, and the side
  render had no eye in it. I had built the cue, could measure it as present, and could
  not see it. Brim pulled to 0.238, eyes out to 0.252 and up.

## THE ONE NUMBER THE BUILDER ASSERTS RATHER THAN COMMENTS

`bone` is THE MECHANIC AND NOTHING ELSE - here the pointing forearm and mitt. Nothing
else on the body is pale and **the head carries no pale at all**. The Beadle shipped a
pale knob at a bone/body luma ratio of 1.07 and it went flat against his own pale panel
while every number in his register read green, so the ratio is asserted in `overlooker()`
and the build dies under 1.30. Measured rec709: body 0.251, bone 0.921, dark 0.068 -
**ratio 3.67**.

## WEAR 0.18 - A SPREAD, NOT A SETTING

Set mean is 0.471 measured off CANON this run. He is near the clean end and it is argued:
**he does not do the work.** Every filthy body in this file is filthy from what it
handles. A man whose whole trade is standing over other men handling things keeps his
coat. Inside the one scalar: coat and collar kept and nearly new; the POINTING MITT is
the brightest thing on him, the instrument of his office the way the Drillmaster's gong
is his; the BOOTS are works-floor filthy, the one part of him that touches the job.

## FIT AND THE GATE

`renders/art/minibosses/_report.json`, re-run at pass 4 against today's `scripts/floorgen.gd`:
`ok: true`, errors `[]`, blanks `[]`, border check clean.
**span 1.54 m — CORRIDOR-SAFE** (clear span 11.0 m) · **UNDER-LID** (underside 9.5 m,
read at `scripts/floorgen.gd:1383`) · **4 meshes, the bar is four** · 850 faces (was 824 at pass 3).
**NOT room-locked** - the gate measured the real footprint, including the arm's reach.

## PASS 4 - THE PICTURE ONLY. THE TEAM LEAD WAS RIGHT AND SO WAS PASS 3's OWN NOTE.

The 15:58 row said it plainly: *"give it a silhouette that reads as a body at the rung
the player sees"*, and *"the numbers are not the thing that is wrong, so do not re-tune
them."* **Nothing in this pass changed a colour, a luma ratio, a wear value, the
mechanic, the height, the theme or the gate.** The ratio assert is untouched at 3.67 and
the report still reads `ok: true`, errors `[]`, blanks `[]`, border clean, 4 meshes.

### THE FAULT, NAMED EXACTLY RATHER THAN AS "IT LOOKS LIKE A CHESS PIECE"

A chess piece is a **TURNED SOLID**: one axisymmetric profile, monotonically widening
downward, standing on its own base. Pass 3 was all three of those things, and each is a
number I could have read off my own builder without rendering anything:

| the property | pass 3 | why it is the chess piece |
|---|---|---|
| outline from collar to hem | collar 0.41 → waist 0.58 → hem 0.91 across | **never narrows anywhere.** A shape that only widens downward IS a lathe profile |
| visible leg below the hem | hem z=0.330, ankle z=0.105 → 0.225 m of 2.40 m = **9 %** | nine percent of leg under a closed flare is a pawn's base, not a man standing |
| front ortho vs side ortho | every coat section axisymmetric, 22 segments | the two views got **the identical outline** - that is not a resemblance to a turned piece, it is the manufacturing method |

### THE THREE FIXES, EACH RENDERED AND LOOKED AT ON ITS OWN BEFORE THE NEXT

**FIX G - THE HEM CAME UP AND THE LEGS BECAME THE BOTTOM THIRD.** `HEM` 0.330 → 0.660,
clear above the knee at 0.560, so the visible run is 0.555 m (**23 %**) *and it contains a
joint*. A knee in the outline is the cheapest thing in this file a turned piece cannot
have. The stance went to ±0.232 at the ankle and the feet were **staggered** (forward foot
on his pointing side): pass 3's two legs sat at the same y, so from the side they were one
column and the figure had one leg.

**FIX H - A WAIST AND A HIP. AND FIX H ON ITS OWN DID NOTHING, WHICH IS WHY IT IS TWO
ENTRIES.** I narrowed the coat at the waist to 0.212, rendered it, and **the side view did
not change at all.** The trunk inside the coat was a uniform 0.252 tube from belt to
shoulder and simply swallowed the pinch. *A waist is not a narrow thing, it is a thing
narrower than what is above it, and there was nothing above it.* **FIX H2** gave the trunk
a real taper - waist 0.214 → chest 0.274 → shoulder 0.242 - so the chest is 0.55 across
against a 0.43 waist, a 22 % pinch the coat can sit inside instead of behind. The skirt
flare now starts at the **hip** (1.040), not at the belt. **One change at a time is what
caught this**: had I shipped G, H and I in one render I would have recorded the fix that
did nothing as part of the fix that worked.

**FIX I - KILL THE LATHE.** Both coat sections squashed to **0.76 in y**, so the hem is
0.80 across the front and 0.61 deep in the side and no yaw of the camera finds the same
shape twice. Measured at the rung: the side silhouette's bounding box went **98 px wide →
86**, the front's barely moved. That split is the whole point.

### THE EVIDENCE, AND IT IS A PICTURE BECAUSE THE ASK WAS A PICTURE

`renders/art/minibosses/_ol_rung_ab.png` (and the two halves beside it) - pass 3 against
pass 4, all three views, **area-averaged down to the 160 px / 360p rung this file already
uses for the collier brow**, in colour and again as **pure silhouette with the shading
thrown away**, because colour is what lets a bad silhouette pass. Built by
`tools/art/_ol_rung_ab.py`, which goes **RED on an empty rung mask and RED on a body
touching the border** - a metric over zero pixels reads green and means nothing, and a
clipped figure is not a blank one.

**IN MY OWN WORDS, LOOKING AT IT: NO, IT NO LONGER READS AS A CHESS PIECE.** In the pass-3
row all three silhouettes are a bell with a head on it and the side one is textbook pawn.
In the pass-4 row there are shoulders, a waist, a hip, a knee-length coat and two separate
legs with daylight between them, in all three views, at 160 px. I would not have said that
of pass 3 at any resolution.

### THE RULE I BENT DOING IT, SAID OUT LOUD RATHER THAN LEFT FOR SOMEONE TO FIND

The standing bar is **"never a hero body"**, and pass 3's own docstring argued the bell
*was* the compliance: *"a hero below the waist is two legs; this is one solid flare, so
the bottom third cannot be read as an adventurer."* **I have just given it two legs.** So I
tested it instead of asserting it: `renders/art/minibosses/_ol_hero_ab.png` puts an actual
KayKit hero body at the same rung beside it. The hero is a short wide blocky mass -
w/h **0.543**, enormous head, armoured shoulders, 9 % of rows showing two legs. The
Overlooker is a tall thin figure, side w/h **0.453**, with a horizontal pale arm at
shoulder height that no hero silhouette has. They are not confusable and the picture says
so. **But the honest version is that what keeps it out of hero territory is now the arm,
the height and the hat - not the base.** If the team lead reads the bar more strictly than
that, the fix is cheap (drop `HEM` back toward 0.50) and I would rather be told than guess.

## WHAT I CAN STILL SEE WRONG AFTER PASS 4 (looked at, at the rung, not inferred)

1. **The neck closes at the rung in the side view.** FIX C in pass 3 opened a lit neck
   between collar and skull and it works at 700 px; at 160 the head sits straight on the
   shoulders. Not a chess-piece fault, but the head's own island is a 700 px claim only.
2. **The idle arm is still the weakest object on the body and pass 4 did not touch it.**
   Pass 3 called it "a plank"; at the rung it is a bulge on the torso rather than an arm,
   front and three-quarter. It was outside the brief for this pass. It is the next thing.
3. **The two thighs still merge under the hem in the side view** - the gap opens lower
   down, at the shins. Better than one column, not two clean legs.
4. **Still no back view rendered.** Pass 3 flagged this and it is still true: the driver
   shoots front, three-quarter and side, and the view that would hardest test this body's
   claim to have a facing is the one nobody has shot. **Not claimed as proved.**
5. **The skirt now reads a little like a jerkin over a kilt** from the front, because the
   chest is wider than the hip section above the flare. It reads as a man, which was the
   ask, but it is not unambiguously a long coat any more.

## WHAT I CAN STILL SEE WRONG (pass 3, looked at, not inferred)

1. **One eye only in the side view, and it is small.** Correct for a profile, but it is
   marginal and I have not measured it at the 360p rung. If it has to survive there it
   wants another pass, and I would rather say so than let the register's `seen` call it.
2. **The idle arm reads as a plank.** From the side it is a dark diagonal slab across the
   coat; from the front its hand disappears behind the hem, so it is a sleeve with no
   hand. It is the weakest object on the body.
3. **The legs are nearly all coat.** One boot from the side, two from the front. The long
   coat is right for him, but the hem is the widest thing in the side frame and from that
   camera the bottom third reads closer to a skirt than to a coat.
4. **The snout is a rectangular block** and reads slightly beaked up close. It survives at
   distance, which is what it is for, but it is blocky.
5. **No back view was rendered.** The driver shoots front, three-quarter and side. This
   body's whole claim is that it HAS a facing, and the view that would test that hardest
   is the one nobody shot. Not claimed as proved.

## WIRING - FOR THE GAME BUILD LANE, NOT ME

1. `scripts/bestiary.gd` - new entry keyed `overlooker`, `model` =
   `assets/monsters/minibosses/overlooker.glb`, **no `anims` entry** (static mesh).
2. `scripts/delve.gd` - the mechanic needs the target picked by LEAST cumulative damage
   dealt to this creature, re-read each time it selects, instead of the usual pick. That
   is the whole fight and it is a targeting rule, not a stat.
3. `scripts/dungeon_hd.gd` - theme `workshop` for the miniboss set-piece weight (35 there).
   No spawn gate needed: it is **not** room-locked.
