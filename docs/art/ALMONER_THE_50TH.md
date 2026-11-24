# THE ALMONER - "Dolehand" - THE 50th MINIBOSS

24 Nov 2026, 02:34-02:56 CT. Key `almoner`, theme **shrine**, h **2.52**, wear **0.35**.
Four passes, each one variable, each one judged off a picture.

## WHAT I CHECKED BEFORE I BUILT ANYTHING - MEASURED, NOT REMEMBERED

- **THE COUNT.** `renders/art/minibosses/_fit_report.json` judged **51** rows before
  this run (49 live bodies + the two retired `_chibi` cells). It judges **52** now.
  I did not take 46, 33 or any number out of a prompt.
- **THE SET.** I parsed all **49** `idea` strings straight out of `CANON` in
  `tools/art/minibosses.py` with a regex this run and read every one, plus the theme
  histogram off the same parse (14 themes; crypt 5, confection 2 and shrine 3 the
  thinnest). The Almoner is the fourth shrine body.
- **THE ENGINE, BEFORE THE IDEA.** `delve.gd:_hero_damage` takes its dice from
  `roster.weapon_dice(h)` and the only thing that lookup keys on is `h["class"]`.
  There is **no per-hero equipped-item dictionary anywhere in the delve.** So the
  mechanic below is written in a term the engine already has, and the prettier half
  of it was dropped - see FOR THE GAME BUILD LANE.

## THE IDEA, AND THE THREE NEAR MISSES

**IT DEALS YOUR KIT OUT AGAIN.** It does not wound, takes nothing out of the room and
does not touch the floor. While it stands, every delver swings on **another delver's
weapon dice**: the knight is working a healer's staff, the rogue is hauling a
greatsword it cannot lift. The party's total is unchanged - that is the point.
Nothing is weaker; everything is in the wrong place.

- **THE TALLYMAN** takes gear OFF the party and withdraws - a subtraction and a
  disengage. This subtracts nothing and never leaves.
- **THE STRICKLER** scrapes your best hero DOWN to the level - it lowers the ceiling.
  This does not move the total at all, only who holds what.
- **THE CHANGER** trades PLACES. This trades the thing in the hand; position is untouched.

## THE FOUR PASSES - AND PASS 1 SHIPPED THE EXACT THING ITS OWN DOCSTRING FORBADE

| pass | the one variable | what the picture said |
|---|---|---|
| 1 | first build: round dole dish tipped 38 deg, kit lying flat in it | **A SHIELD.** And the whole pale half of the mechanic rendered as ONE dark stub |
| 2 | the kit stands proud of the rim instead of lying in it | kit visible - 3 objects, not 1 stub - and **the shield read survived**: the sword lay flat across the disc and read as a charge PAINTED ON a shield |
| 3 | **the container stops being a disc** - an oblong dole tray | **the shield is gone.** New fault, measured off the same frame: the tray ran behind the torso and read as driven THROUGH the man |
| 4 | the carry point goes outboard - derived (half-length 0.46 + torso 0.30 + 0.02 clear = 0.78, set to 0.79) | tray clear of the body; both halves of the mechanic on screen |

**PASS 1 IS THE ONE WORTH WRITING DOWN.** I wrote three paragraphs about not shipping a
shield, tipped the pan 38 degrees to prove it, and shipped a shield. The error was not
the angle - it was asserting "the kit is in the pan by construction" and never asking
**whether a camera can see into a pan held at chest height by a level camera.** It
cannot: the near rim occludes the lot. That is trap 5 in my own hands again - "it is in
there" is a fact about the world and says nothing about what is visible. And the two
requirements genuinely fight: to show its inside to a level camera a pan must turn its
mouth toward that camera, and a pan whose mouth faces the camera IS a disc face. The
pan could not carry it, so the pan went.

## THE FIT PROOF - I LOOKED AT IT

`renders/art/minibosses/almoner/hero_front.png`, `hero_side.png`, `hero_back.png` -
the body beside a real KayKit Knight at scale 1.0, and `front/side/three_quarter.png`
alone. Register: ratio **1.03** (2.52 / 2.45), pair width 4.34 m, `fits_frame` true,
**3/3 proving views**, `frame_edge` 0 top/bottom/left/right in all three,
**blank check 3 files / 0 failures**, errors `[]`, verdict **GREEN** across all 52 rows.
Span **2.48 m**, **CORRIDOR-SAFE**, **UNDER-LID**, **4 meshes**, **1034 faces**.

### AND `seen: 1.0` ON EVERY VIEW IS NOT THE PROOF. THESE ARE THE FAULTS I CAN SEE.

At **hero scale**, which is the scale that counts:

1. **THE "PUT IN" HALF IS SPECKS.** The three pieces on the tray do not read as a
   sword, an axe and a flask - they read as litter in a dark box. Only the axe has a
   shape. The sack's two dealt handles read BETTER than the tray's three, which is
   the wrong way round: the tray is the headline. **Next pass: two pieces, not three,
   and bigger.**
2. **HIS OWN FOREARM IS THE BRIGHTEST OBJECT ON THE TRAY** - wider and lighter than
   any piece of kit, so the eye takes the arm for the cargo.
3. **THE FIGURE IS NARROW AND LONG-LEGGED** beside the stocky knight - two thin
   dowels with a wide gap. The same fault the Blower's doc records.
4. **FROM THE SIDE THE SACK COVERS THE FAR LEG ENTIRELY** and sits at knee height,
   where it reads as a belly or a gourd strapped on rather than a sack at a hip.
5. **FROM THE SIDE THE TWO HALVES COLLIDE** - the tray's kit and the sack's dealt
   handles overlap into one pale jumble, so "three in, two out" is not legible in
   that view. It is legible front and three-quarter.
6. **THE HOOD READS AS A LAMPSHADE** on a ball head - generic, not wrong.
7. The tray interior is dark-on-dark, so the pale kit floats in a black slot rather
   than sitting in a container.

No clips, no floats, no bad anchors: both feet are planted, the tray sits on the
forearm cleat, the sack's handles leave the mouth, and the strap ends on the shoulder
and on the sack neck.

## FOR THE GAME BUILD LANE - I TOUCHED NO `.gd` OUTSIDE `tools/art/`

- `scripts/bestiary.gd`: `assets/monsters/minibosses/almoner.glb`, **STATIC** - a
  `model` path and **NO `anims` entry**. `h = 2.52`, art's measured number; do not
  re-derive it.
- theme **`shrine`** for the set-piece roll (joins the Snuffer, Leech and Beadle;
  shrine was three bodies and is now four).
- **CORRIDOR-SAFE at 2.48 m, UNDER-LID. No spawn gate needed, not room-locked.**
- `MB_FIT["almoner"]`: ratio **1.03**, tag **"shrine"**, 3 proving views - **copy it
  from the register, do not re-derive it.**
- **HOLD `MB_NAME["almoner"]`** until content writes `by_key.almoner`, the same way
  the Winder, the Pitman, the Tither and the Blower were held. The canon name is
  **"Dolehand"**.
- **THE MECHANIC IS A PERMUTATION OF THE CLASS THE WEAPON DICE ARE LOOKED UP UNDER**
  while the body lives, cleared when it dies, and nothing else. I read
  `_hero_damage` before writing the idea: `roster.weapon_dice(h)` keys on
  `h["class"]` and there is no per-hero equipment term in the delve. **I HAD A
  SECOND HALF - "your heavy armour ends up on the archer" - AND I AM DROPPING IT AND
  SAYING SO** rather than inventing an engine term for a piece of art.
- `almoner.glb` ships with **no `.glb.import` sibling** (same state as
  `snarer_chibi.glb`): a Godot run generates it. Nothing is blocked meanwhile.
