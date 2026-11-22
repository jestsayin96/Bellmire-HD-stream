# THE CHANGER (Evenhand) - the 47th miniboss

21 Nov 2026, 20:3x-21:1x CT. Art lane. Branch `art`.

## WHAT I CHECKED FOR FIRST, MEASURED, NOT REMEMBERED

My prompt says "THIRTY-THREE already exist". That line is fourteen bodies
stale and I did not act on it. I parsed `BUILDERS` out of `tools/art/minibosses.py`
by brace-matching every `BUILDERS = {` and `BUILDERS.update({` block:

  * **60 builder keys, 0 duplicates**
  * **46 distinct bodies** once the `_chibi` / `_tall` variants are folded in
  * which is exactly `Delve.MB_NAME` (46), as the team lead re-measured at 19:58 CT

Then I read **every** `IT ...` idea string in the file - all 46 - before writing
a line of this one, because the bar is ONE IDEA THAT CHANGES THE FIGHT and a
re-skin of an existing fight fails it.

**Nothing in the set exchanges.** The five nearest, and why each is a different
fight, are argued in the builder's own comment block: gaoler (drags one TO
itself), ferryman (REMOVES one), winder (pulls everyone one way), hurdleman
(changes the ROOM), porter (takes the EXIT). The 47th is the first whose
mechanic is a SWAP - both bodies stay in the room, both keep acting, and what
is taken is the party's own arrangement.

## THE BODY

| | |
|---|---|
| key | `changer` |
| name | Evenhand |
| height | 2.72 m (unoccupied rung; 2.70 and 2.75 were live) |
| wear | 0.38 (unoccupied; 0.35 and 0.40 were live) |
| theme | treasury |
| static | YES - no `anims` |
| faces | 878 |

A man standing inside a three-armed turnstile: post behind him and to his
right at (0.460, 0.520), three bars at 60/180/300 degrees at hip height, pale
plates on their ends, and a pale drum with three dark rungs on the post head -
**the drum is the count**, a third of a turn per trade, so a viewer can see how
many times the room has been shuffled without being told a number.

## THE GATE

`minibossgen --only changer`, final pass:

```
MINIBOSSGEN_REPORT ok=true  errors=[]  blank=[]
changer span 2.99 m  CORRIDOR-SAFE  UNDER-LID  (corridor clear 11.0 m, lid 9.5 m)
```

`_backread --keys changer` (the with/without delta through one locked camera -
the only version of "can you see the man" that has survived contact with a
picture):

```
front  man_seen 0.9665   creature bands 4   man bands 3
side   man_seen 0.9302   creature bands 4   man bands 3
back   man_seen 0.9180   creature bands 4   man bands 3
errors []
```

`minibossfit --only changer`: `ratio 1.11 hero heights`, 3 views proved,
0 blank failures, **no changer error**. The register's verdict is RED and it is
NOT this body - see the carried fault below.

## THE FIVE PASSES, AND THE THREE FAULTS THE GATES COULD NOT SEE

Every one of these was found by LOOKING at a picture that every number called
green.

1. **PASS 1 - a bar through the man's belly.** The post stood beside him at
   x 0.455 and the 210-degree bar ran through his torso and out the far hip.
   Blank check, border check and corridor span are all blind to one solid
   passing through another. Arithmetic, not a nudge: three bars at 120 degrees
   cover every direction, so a post BESIDE him cannot work at any phase. The
   post went behind him.
2. **PASS 2 - the drum on his head.** Post on the centre line, front camera on
   the same axis: the counter projected onto the crown of his hat and the post
   was invisible behind his body. Green again. Fixed by taking the post off the
   centre line to x 0.460 and re-phasing to 60/180/300, which is the only phase
   of the three I tried that clears him: 90/210/330 puts a bar 18 degrees off
   his bearing and 0/120/240 puts one through his belly at x 0.16.
3. **PASS 3 - the barbell.** Disc paddles on round bars read as three pale
   coins on sticks. Replaced with flat upright plates, which is what a real
   turnstile arm ends in and which keeps a silhouette edge-on.
4. **PASS 4 - A FIX THAT BOUGHT NOTHING, RECORDED RATHER THAN REPLACED.** The
   hero sheet - and only the hero sheet - showed the real fault: at hero scale
   this read as A MAN STANDING NEXT TO A LAMPPOST, two objects and not one
   creature. I tied his shoulder to the post. The re-shot sheet was
   indistinguishable: the tie started INSIDE the shoulder sphere (which reaches
   x 0.318) and ran away from the front camera, so it was hidden for its whole
   length in the one view the fault lives in. A fix that cannot be seen in the
   view that showed the fault is not a fix.
5. **PASS 5 - the tie re-routed** to leave ABOVE the shoulder line at z 1.470,
   outboard at x 0.300, so it breaks the silhouette's top edge. **It is a
   PARTIAL fix and I am not calling it more than that.** On the re-shot hero
   sheet the tie is now visible - a short dark arc off his right shoulder - but
   at hero scale it reads as a handle ON HIM rather than as a line TO the post,
   and the "man beside a lamppost" read is softened, not gone. Two attempts,
   one partial result. If Mr. E wants the two masses welded properly the answer
   is probably a yoke across both shoulders that the post rises out of, which
   is a bigger change than one line and would want its own pass.

## STILL OPEN, STATED BECAUSE I CAN SEE IT

**THE BARS CROSS HIS SILHOUETTE IN TWO VIEWS OF THREE.** From the front the 180
bar comes out past his left side; from the back it crosses his waist. Both are
DEPTH-CLEAR and the numbers are mine: the 180 bar runs along y +0.520 and his
back surface is at +0.29, so 0.23 m of air; the 300 bar clears his flank by
0.47. Nothing interpenetrates. But a bar drawn across a body can be misread as
a spit, and no blank check, border check or corridor span can see a misread.

I did not "fix" it by shortening an arm: a turnstile you can walk round is not
a turnstile, and unequal arms are not a turnstile either. **This is the one
thing on this body for Mr. E to look at and overrule if he wants it gone.**

## WIRING THE GAME BUILD LANE MUST DO (I DO NOT DO IT)

`scripts/bestiary.gd` - add the Changer with a `model` path and **NO `anims`
entry** (static body):

* model: `assets/monsters/minibosses/changer.glb`
* `h`: **2.72**
* NOT room-locked: span 2.99 m against a corridor clear of 11.0 m, under the
  lid at 9.5 m, so its spawn needs no gate.

`scripts/delve.gd` `MB_NAME` - the 47th key/name pair, `changer` -> `Evenhand`,
if and when the set is extended there. That file is not mine.

## A CARRIED RED THAT IS NOT MINE THIS HOUR BUT IS MY LANE'S

`minibossfit` is RED for FOUR errors, all **beadle**, none of them changer:

```
[carried] beadle/back, beadle/front, beadle/side: MISSING FILE - the view this
          row vouches for is not on disk at the canonical path
[carried] beadle: no readable alpha in back,front,side - an air measurement
          over nothing is RED, not green
```

The Beadle's register row vouches for three views that are not on disk. The
instrument is doing exactly what it should - refusing to certify from nothing -
and the Beadle's renders need regenerating at the canonical path. Logged here
so the next art firing takes it rather than re-discovering it.
