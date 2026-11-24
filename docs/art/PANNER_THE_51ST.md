# THE PANNER - THE 51st MINIBOSS, AND THE TWO IDEAS THE SET KILLED FIRST

24 Nov 2026, 06:3x-07:0x CT, art lane. Mr. E's standing permission of 17:43
(a dry art lane may invent a miniboss outright - no lore, no canon entry, no
content-lane dependency). The team lead's 06:34 row: "THEN YOUR LICENCE IS
INTACT: INVENT THE 51st MINIBOSS if you want the cycle."

## WHAT I CHECKED FIRST, MEASURED AND NOT REMEMBERED

`tools/art/minibosses.py` `BUILDERS` carries **64** keys, of which **50** are
non-variant bodies once the retired `_chibi` / `_tall` variants come out, and
`CANON` carries **50** rows. The two agree, and they agree with the chain the
team lead measured on merged main (`MB_NAME` 50 / `by_key` 50 / published 50).
So the next body is the 51st.

I then pulled the `idea` phrase out of all fifty CANON rows and read them as
MECHANICS rather than as trades, because a trade name is not what makes a
re-skin.

**TWO IDEAS DIED ON THAT TABLE, AND I WOULD HAVE SHIPPED THE FIRST ONE FROM
MEMORY.**

| idea | what killed it |
|---|---|
| A BRANDER - "it marks one of you and the floor goes for the mark" | The **DYER**, verbatim: `IT MARKS ONE OF YOU AND HUNTS ONLY THE MARK`. |
| A KNACKER - "everything else that dies in the room feeds it" | The **RATCATCHER**, and his row is better developed than mine was: the bays fill, he is stronger per bay, and a filled bay can be cut open to give it back. |

## THE IDEA THAT SURVIVED, AND THE GAP IT FILLS

Reading the fifty as mechanics, the set already owns adds, self-repair, pull,
light, raise, exit denial, gear theft, ally healing, flood, terrain spawn,
pre-set traps, resource dependency, false position, floor state, split, arming
others, encumbrance, room bisection, damage-type immunity, aggro marking,
weapon degradation, shape theft, death-feeding, single-file, forced facing,
movement-triggered aggro, forced weakness, anti-heal, choice removal, timed
drop, absorb-and-return, verticality, wall building, gear locking, cask, post
theft, undoing progress, rewind, floor removal, tribute, air, swapping places,
binding heroes, kit shuffling, levelling the best hero, loot denial, potion
drinking, and standing your fallen up against you.

**NOT ONE OF THE FIFTY MAKES THE PARTY HOLD ITS BLOWS.** Every row answers
"what does it do to you" or "what must you break". None answers "WHEN may you
hit it at all". That is a different shape of fight from a condition: the Stoker
is a resource you can starve while hitting it the whole time, the Tanner is a
type immunity you answer by swinging something else, the Rammer is a timed
THREAT. A timed VULNERABILITY inverts the party's job from dealing damage to
withholding it.

> **PANNER - "Onceround" - IT IS SHUT UNTIL THE PAN COMES ROUND.** It is not
> armoured and it is not immune: for most of the fight there is simply nothing
> of it to hit. The whole creature is a closed drum on a crank and the one
> opening in it swings past you once a turn. Blows on the shut wall do nothing
> at all - not reduced, nothing. The window is wide enough for a party that
> waits together and too narrow for one that does not.

Theme **confection**, which was the thinnest theme in the set at two bodies
against the crypt's five. Height **2.26 m** and wear **0.14**, both values
unused by the other fifty - the pan is kept polished because sugar burns onto a
scaled one, which is the wear rule driven by the trade and not by a mood.

## THE THREE PASSES, AND PASS 2 IS THE ONE WORTH KEEPING

**PASS 1 - the picture refuted the design.** Gen GREEN, 1,144 faces, span 2.34
CORRIDOR-SAFE and UNDER-LID, blanks none. And all three frames came back as a
single enormous PALE DISC on legs - the pavise read the docstring claims to
design out, and the almoner's pale-in-pale blob I had quoted at myself two
paragraphs above the line that caused it.

**PASS 2 - A CHANGE THAT MOVED NOTHING, AND THAT IS THE FINDING.** My diagnosis
was that the pale mass was the pan's inner FLOOR, so I flipped it from pale to
dark and re-rendered. The front frame came back **BYTE IDENTICAL at 432,898
bytes** - not one pixel different, same 1,144 faces, GREEN both times. A change
that cannot move the picture means the object I changed is not the object in
the picture. **The gate could not tell me, because it has no term for what is
in front of what.**

**WHAT THE PALE DISC ACTUALLY WAS.** `lordlib.cone(r1, r2, h, seg, cap=True)`
caps BOTH ends, and `cap` defaults to True. The "lip ring" I wrote as a short
flared collar was a **solid plate 1.28 m across lying over the mouth**, hiding
the floor, the comfits and the entire interior. There is no annulus primitive
in lordlib - `_ring` sweeps a tube, and only for axis-aligned rings.

**PASS 3 - the lip swept as a real ring** in the mouth's own basis (29 points,
tube radius 0.058). 1,346 faces. The mouth now reads as an opening: dark
interior, pale edge. That is what makes a hole read as a hole, and it is the
inverse of what pass 1 built.

## THE FIT PROOF - RENDERED ON A BODY AND I OPENED ALL THREE

`minibossfit` GREEN, errors [], blind_views [], blanks none, border/frame
clean, panner proving 3 of 3 views, measured beside a real KayKit Knight at
scale 1.0 (hero 2.45 m measured, not assumed).

- **hero_front** - the opening reads. Dark bowl, pale rim, the comfits visible
  as bumps on the floor, the chute coming down into it. Scale beside the knight
  is right.
- **hero_side** - the best view. The rim is an ellipse and the drum wall goes
  back behind it, so the DEPTH is visible and the cask read (a) is answered by
  the picture and not only by the 3.5:1 ratio.
- **hero_back** - **FACING HOLDS.** The closed dark back of the drum is all
  this view gets; nothing pale, no face panel, no eyes. The Beadle's defect (a
  body that reads the same from both ends) is designed out and confirmed by eye
  rather than by `seen: 1.0`.

### EVERY FAULT I CAN SEE, AND THERE ARE SIX

1. **THE MAN IS ECLIPSED IN THE SIDE VIEW - COMPLETELY GONE.** He and the pan
   share a Y, and the side camera looks along X, so no amount of X separation
   can part them. This is the Sealer's pass-3 lesson failing in the one view I
   did not think about when I applied it.
2. **AND IN THE FRONT VIEW HE IS UNREADABLE ANYWAY** - both forearms fold into
   a jumble of boxes at his waist because the crank he is holding is behind the
   pan from that angle. He reads as a bystander, not as the thing driving it.
   He only works in the BACK view, where an arm plainly goes into the machine.
3. The hopper's chute crosses the top of the mouth in front projection and
   notches the opening. Moving it in Y cannot fix that - it has to go up or to
   the side.
4. The comfits are dark beads on a dark floor and read as RIVETS, not sugar.
   Nothing in the frame says confection; it could be a mill or a kiln.
5. The pale rim is a closed continuous ring, which at stream distance reads
   slightly as a porthole - a modern shape, not a medieval one.
6. The man's hat sits above a head with no visible neck, so it floats.

**THE OPEN QUESTION I AM NOT DECIDING ALONE:** fault 1 and 2 are the same man.
Either he moves forward in -Y so he parts from the pan in the side view, or he
comes out altogether and the body becomes a machine with a crank that nobody is
turning - which is plainer, more Bellmire, and removes three faults in one
change. I did not guess at it in a rushed pass.

## WIRING - THE ART LANE DOES NOT DO THIS

`scripts/bestiary.gd` needs a `model` path to
`assets/monsters/minibosses/panner.glb` and **NO `anims` entry** - it is static.
`Delve.MB_NAME` wants `"panner": "Onceround"` once content's feed row lands.
**NOT ROOM-LOCKED: CORRIDOR-SAFE and UNDER-LID** - footprint span 2.34 m
against a corridor clear span of 11.0 m and a lid underside of 9.5 m, both read
out of `scripts/floorgen.gd` this run by `tools/art/floorgeom.py`.
