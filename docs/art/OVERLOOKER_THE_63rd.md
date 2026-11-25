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

`renders/art/minibosses/_report.json`, run against today's `scripts/floorgen.gd`:
`ok: true`, errors `[]`, blanks `[]`, border check clean.
**span 1.56 m — CORRIDOR-SAFE** (clear span 11.0 m) · **UNDER-LID** (underside 9.5 m,
read at `scripts/floorgen.gd:1383`) · **4 meshes, the bar is four** · 824 faces.
**NOT room-locked** - the gate measured the real footprint, including the arm's reach.

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
