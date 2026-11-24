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

---

# PASS 5 - 24 Nov 2026, 03:34-03:5x CT. TWO CHANGES SHIPPED, ONE REFUSED BY ITS OWN RENDER.

The team lead's item, verbatim: *"pass 5 on the almoner, and it is your own fault 1
plus mine. Two pieces instead of three, bigger, and lift the tray's interior off the
dark-on-dark you already named. The acceptance test is the FRONT at hero scale."*

## WHAT I CHECKED BEFORE I TOUCHED ANYTHING - MEASURED, NOT REMEMBERED

- **The plan**, off `origin/main` this run, not off the prompt's queue list. The prompt
  would have had me invent a 51st miniboss; the plan's TAKE-THIS-NEXT block names pass 5.
- **The miniboss count**, parsed out of `tools/art/minibosses.py` myself: `BUILDERS`
  carries the set, `renders/art/minibosses/_fit_report.json` judges **52** rows
  (50 live + the two retired `_chibi`). The prompt's "thirty-three already exist" is
  six days stale. I did not quote 33, 46 or 51.
- **The existing body**, before changing it: `almoner()` already exists, is already in
  `ORDER`, already exports, and already has a register row. Nothing was rebuilt.

## THE THREE CHANGES, EACH MEASURED ON ITS OWN ARM

| arm | the one variable | the picture |
|---|---|---|
| `p5a` | **A** - flask gone; sword and axe grown (blade 0.030→0.052 / 0.620→0.780, axe haft 0.023→0.036 / 0.560→0.700, head 0.110→0.175). Plus **A2**: the bar steps back half its length so it straddles the grip and is a crossguard, not a spur | the axe reads as an axe for the first time; the sword has a guard. Tray floor still near-black, so the team lead's fault is untouched |
| `p5b` | **B** - the tray **floor only** leaves `dark` (0.068) for `body` (0.355). Rails, lips and cleat stay dark | the box stops being a black slab and becomes a container **with an inside** - which is the one thing a shield face can never have. Kit still specks, as expected |
| shipped | **A + B** | both faults answered, and **they partly fight** - see below |
| `p5c` | **C** - the two pieces trade ends of the tray | **REFUSED. See below.** |

`renders/art/minibosses/_almoner_p5_tray_ab.png` is the tray at 3x in the first three
arms, and it carries the finding neither arm shows alone: **B lifts the DARK half of
the kit and spends contrast off the PALE half.** The axe haft and the sword grip now
read along their whole length against the pale floor; the blade and the crossguard,
which were crisp white-on-black in `p5a`, lose most of their value separation. A single
floor value cannot favour a two-tone kit in both directions. B is still the right ship,
because the dark half was invisible and the pale half is only reduced.

## CHANGE C AND WHY IT IS IN THE FILE SWITCHED OFF

The pale half's real competitor is not the floor at all - it is **his own forearm**,
which enters the tray from +X and is the biggest bright mass inside the tray outline
(my own pass-4 fault 2, which B made worse by closing the arm/floor/blade value gap).
So I mirrored each piece in x: pale sword to the open -X end, dark axe to the +X end
where the arm is.

**The sword then read better than it ever has - and the axe swung its PALE HEAD up
across the man's own hood and face panel.** At hero scale that is an axe struck into
his head, and it puts a second bright mass beside the single pale panel that carries
this body's FACING - the exact property the Beadle lost. Trading a legible sword for a
body that reads as wounded and has no face is not a trade.

**The thing I did not ask before rendering: mirroring a long piece mirrors the END of
it, not its origin.** The axe's arc rules the +X end, not the sword's position. The
flag stays, OFF (`ALM_P5C=1` reproduces it), and `renders/art/minibosses/almoner_p5c/`
keeps the picture, so nobody re-derives this and ships it.

## THE FIT PROOF - I LOOKED AT THE FRONT, THE SIDE AND THE BACK

Shipped build is the **pure default path, no env set**, and its `hero_front.png` is
byte-identical (`md5 a8b1e5ea…`) to the A+B arm rendered under explicit env - so the
defaults really are A on, B on, C off.

Register: verdict **GREEN**, 52 rows, errors `[]`, ratio **1.03** (2.52 / 2.45),
pair width 4.46 m, `fits_frame` true, **3/3 proving views**, `frame_edge` **0 on all
four borders in all three views**, blank check **150 files / 0 failures**,
`blind_views` `[]`, `unproved_cells` `[]`, `stale_margin` `[]`.
Mesh: **4 meshes** (the cap), **927 faces** (down from 1034 - the flask).
Span **2.59 m** (up from 2.48; the kit got longer), **CORRIDOR-SAFE**, **UNDER-LID**.
Height **2.52 m**, unchanged.

### THE FAULTS I CAN STILL SEE. SEVEN, AND TWO OF THEM ARE NEW THIS PASS.

1. **NEW - THE BLADE IS PALE-ON-PALE.** Change B's floor took the contrast off the
   sword. It reads by its shading edges, not by its value. It is better than pass 4
   and worse than the `p5a` arm, and that is a cost I am naming, not hiding.
2. **NEW - THE RIGHT THIRD OF THE TRAY IS A PALE MUSH.** Forearm, floor and blade are
   now three close values stacked in the same place. Pass 4's fault 2 is not fixed; B
   changed its shape from "the arm out-reads the cargo" to "the arm merges with the
   tray". **The next pass's one variable should be the ARM, not the kit** - move the
   carry hand under the tray's near rail so the forearm leaves the tray's mouth.
3. **THE AXE IS NOW THE WHOLE "PUT IN" HALF.** It reads; the sword half-reads. The
   mechanic is "your kit, dealt out", and one legible piece carries it thinly.
4. **FROM THE SIDE THE SACK STILL HIDES THE FAR LEG COMPLETELY** and the sack plus the
   near leg read as one dark mass - the figure stands on a single post. Pass 4's fault
   4, unchanged, untouched this pass.
5. **FROM THE SIDE THE TWO DEALT HANDLES ARE INVISIBLE**, hidden behind the sack body.
   "Two out" is a front and three-quarter read only. (Pass 4's fault 5 is **improved**:
   the tray's two pieces now stand as two distinct uprights in the side view, where
   three small ones were one jumble.)
6. **THE FIGURE IS STILL NARROW AND LONG-LEGGED** beside the stocky knight. Pass 4's
   fault 3, unchanged.
7. **THE TRAY IS STILL THE LARGEST OBJECT ON THE BODY.** B stopped it being the
   highest-CONTRAST object; it is still the biggest one, and the man is still the
   smaller half of his own silhouette.

### AND HERE IS WHAT MY HARNESS CANNOT SEE, THIS PASS

`seen: 1.0`, `frame_edge: 0` and the blank check all passed on the **refused** arm too -
the one with an axe in the man's face. Not one number in the register moved when the
axe head crossed his hood. **The register measures whether a thing is on screen and
inside the frame; it has no term for whether the pieces are in the right PLACE on the
body.** Every verdict in this file is a floor, not a pass.
