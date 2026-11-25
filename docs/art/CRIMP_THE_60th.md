# THE CRIMP (Oneshort) - the 60th miniboss, and the hero sheet caught what four green reports could not

**Lane:** art. **Built:** 25 Nov 2026, 00:35-01:0x CT. **Branch:** `art`.
**Plan row:** the 23:58 CT 24 Nov TAKE THIS NEXT block - *"ART ... build the 60th
body, and measure the current count off `tools/art/minibosses.py` or the fit
register rather than any number in a prompt."*

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

My own prompt says "THIRTY-THREE already exist". That line is **stale by
twenty-six bodies** and I did not act on it. Parsed off the tree instead:

| measured | where | value |
|---|---|---|
| `ORDER` | `tools/art/minibosses.py`, initial literal + every `ORDER = ORDER + [...]` | **59 entries, 59 distinct** |
| `BUILDERS` | initial dict + every `BUILDERS.update({...})` | 73 - 59 bases + 14 chibi/tall |
| bodies on disk | `assets/monsters/minibosses/` on merged main | 72 `.glb`, 72 `.glb.import` |

So this is the **sixtieth base**. I then read **all 59 `idea` strings in CANON**
before choosing, which is what the NOT-THIS list in the builder docstring is.

## THE IDEA, AND WHY IT IS NOT A RE-SKIN

**IT TAKES ONE OF YOU INTO ITS OWN CREW.** It does not wound - it *signs*. The
hook takes a hero, the name goes on the muster board, and that hero fights
**for** the crimp at full strength. The answer is the one **lit peg** on the
board: strike the peg and the name is struck off.

Twelve existing bodies act on a chosen hero - gaoler, hooper, drover, dyer,
ferryman, almoner, moulder, pressman and the rest - and **every one of them
subtracts**. The party fights on one short. This one subtracts *and adds* in
the same instant: the arithmetic moves by two, and the hero the party must not
kill is their own. **Nothing in the other 59 turns a hero into an enemy.**
The nearest neighbour is the **pledgeman (59)**, the other body carrying a
board. The two invert each other: that one punishes damage, this one *requires*
damage and only aimed somewhere unobvious.

## FOUR PASSES, AND WHAT EACH ONE WAS FOR

- **Pass 1** - built. Green report, and the **side ortho had no man in it**: the
  board sat on his +X side at y -0.140, nearest the side camera, and ate the
  torso and most of the head. A board on legs with a hook. The Beadle's fault
  inverted - there the carried thing went flat against the body, here it ate
  the body - and **occlusion is not a measurement this harness takes.**
- **Pass 2** - five disjoint regions, measured separately because they share no
  pixels: board forward to y -0.520 and smaller (fixes the above); berth loops
  re-proportioned (0.120 wide x 0.215 deep read as **rake tines** on the front
  and a **coil spring** on the side - a loop deeper than it is wide is not a
  loop); the lit peg rebuilt (cone + sphere cap + bone collar merged into a
  **pale cream bean**); the hook's curl swung ~38 deg out of the Y-Z plane it
  lived in entirely, which the front camera read as a blunt stub; the 0.640
  pale shoulder box, which read as a **plank**, narrowed and darkened.
- **Pass 3** - the pass-2 board move made the shoulder strap **sweep across his
  face** on the side ortho; its anchor moved from the board's top corner to its
  mid-outer edge so it now runs level, under the jaw. Placket halved (dark yoke
  + dark placket had made a solid black T over the chest).
- **Pass 4 - THE ONE THE NUMBERS COULD NOT FIND.** Pass 3 was green on
  everything both reports take: 0 blanks, 0 frame clips, 0 blind views, and on
  the 700x980 ortho the peg was plainly a peg. **Then I looked at the hero-scale
  sheet**, where the crimp is about 230 px tall beside a real KayKit knight,
  **and the lit peg was a tick I had to hunt for.** The answer to the whole
  fight was invisible at the only distance a viewer ever sees it. This is the
  17 Nov pass-11 lesson in its other form - there a number said SEEN where the
  picture said nothing; here every number said FINE at a resolution nobody
  watches. The peg grew a third, its head squared up, and it got **the signed
  tag**: a pale plate hung off it, the biggest bright area on a dark board and
  the literal thing the mechanic is about.

**A cue has to be measured at the size it will be read at, and the sheet that
reads it is the hero sheet, not the ortho.**

## THE FIT PROOF - RENDERED ON A BODY AND LOOKED AT

`renders/art/minibosses/crimp/hero_front.png`, `hero_side.png`, `hero_back.png`
- the crimp beside a posed KayKit Knight.glb at scale 1.0, one fixed ortho scale
and one ground line. Pass-1 and pass-2 renders kept under `crimp/_pass1/` and
`crimp/_pass2/` so the moves are checkable and not asserted.

| term | value |
|---|---|
| verdict | `minibossgen` **ok:true**, errors `[]` · `minibossfit` **GREEN**, errors `[]` |
| blanks / frame clips | **0 / 0** over 180 hero-sheet files and the whole-house ortho sweep |
| span | **1.76 m**, `CORRIDOR-SAFE` against an 11.0 m three-cell clear span |
| height | 2.42 m, `UNDER-LID` against a 9.5 m lid read live out of `scripts/floorgen.gd:1383` |
| meshes / faces | **4 / 1725** (the bar is four) |
| hero ratio | 0.99 |
| self_seen | census re-taken over 62 rows; crimp proving **3 of 3** views, blind views `[]` |

**FRONT AND BACK CANNOT RENDER ALIKE** - the Beadle test. The front gets the
board's loaded face, nine sockets, four old pegs, the lit peg and the tag; the
back gets the battened reverse with no sockets at all, and the man's brow, jaw,
eye sockets and placket are on his -Y side only.

## EVERY FAULT I CAN STILL SEE, AT 01:0x CT, UNFIXED

1. **The head has no face at hero scale.** Brow + two sockets + jaw merge into
   one dark band - a bandit mask, not a face. Better than the Beadle's (it is
   -Y only, so the facing holds) but it is not a face.
2. **The peg-and-tag group sits at the board's top-right corner and overhangs
   its edge**, so it reads a little like a clip or a flag rather than a peg
   standing in a socket. It is findable now; it is not yet obviously a *peg*.
3. **The torso is a dark mass at hero scale** - dark yoke, dark placket and the
   dark fists merge; he reads as "dark top, pale skirt".
4. **The coat still reads as a skirt**, close to a tabard, which is the one
   silhouette family a miniboss is not supposed to share with a hero.
5. **The hook is a thin dark diagonal at hero scale** and weak; it reads well
   only on the side ortho.
6. **The empty sockets and the four old pegs look alike** on the front ortho -
   both go mid-grey on a dark board, so the "four taken before" count does not
   read. The count is in the geometry and not in the picture.
7. **On the back view the strap arcs as a pale bracket** across the board's
   reverse and reads as a shield grip.
8. **The berth loops cross in front of the coat** at their far ends, which is
   clutter on the front ortho.

The next pass on this body starts from this list. 1, 2 and 4 are the three
worth a pass; the rest are cosmetic.

## WHAT THE GAME BUILD LANE MUST DO - I DO NOT TOUCH THESE FILES

1. `scripts/delve.gd` - add `crimp` to `MB_NAME` as **`"crimp": "Oneshort"`**
   (59 -> 60) and to `MB_FIT` as **2.42**, plus the sibling count literals in
   `tools/_s51_names.gd`, `tools/_s107_gate.gd`, `tools/_s117_straker.gd` in the
   same commit, exactly as S124 did for the pledgeman.
2. `scripts/bestiary.gd` - **`model` path only, NO `anims` entry.** This body is
   **STATIC**; there is no rig and no animation.
3. It is **CORRIDOR-SAFE**, span 1.76 m - **no room gate is needed.**
4. The miniboss feed / `data/commands.json` lines are content's and the chat
   bot's, off `CANON["crimp"]`: title **Oneshort**, theme **barracks**,
   wear 0.38, feed line *"Someone is signing a name in the dark."*

## STILL OWED BY ME, AND WHY

`assets/monsters/minibosses/crimp.glb.import` is **NOT in this push.** Making it
needs a Godot headless import scan, and at 00:49 CT the chat bot held the lock
(`RUNNING 2026-11-25T00:47:46-06:00`, no IDLE after it). **I did not claim over
a live hold.** Per the yield rule I split the job and carry the sibling to my
next firing. Until then `crimp.glb` cannot be loaded by the engine - same state
`snarer_chibi.glb` has been in. Nothing downstream is blocked: the wiring above
can all be written against the key before the sibling exists.
