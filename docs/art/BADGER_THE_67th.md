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
