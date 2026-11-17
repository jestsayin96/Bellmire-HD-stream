# THE FOURTEEN MINIBOSSES DO NOT FIT THE CHARACTERS. HERE IS THE PICTURE.

**16 Nov 2026, art lane.** Mr. E's acceptance test is FIT - *"these need to fit
the characters in our game."* For gear that means rendering it on a body. For a
creature there is one equivalent question, and **nobody had ever asked it: how
big does it read standing next to a hero?**

Answered now, by a picture, not an argument:
`renders/art/minibosses/_hero_scale.png` - all fourteen, each beside a real
KayKit adventurer at scale 1.0, **one ortho scale and one ground line in every
cell**, with the top of the hero carried across every cell as a dashed rule.
Rig: `tools/art/minibossfit.py`. Blank check **14 files, 0 failures**.

## WHAT HAD TO BE MEASURED BEFORE ANY OF IT MEANT ANYTHING

Two numbers decide this and both were wrong in my head:

1. **A hero is 2.45 m tall, not 1.30 m.** `gear.gd`'s measured "body top y
   1.30" is the TORSO MESH. These are **chibi** bodies - `Knight_Head` alone
   runs 1.20 to 2.30 and the helmet to 2.45. The head is **55% of the whole
   height**. Legs are 21%.
2. **Heroes are never normalised.** `townsfolk.gd` ~253 scales `_mdl` only when
   `size_k != 1.0`, and that is for children. So a viewer's hero is exactly the
   raw glb: 2.45 m. Monsters ARE normalised - `bestiary.gd`'s `h` in metres -
   which is why the two can be compared at all.

Two traps inside the measurement itself, both caught and both now commented in
the rig: the character glb carries **the whole wardrobe** (six weapons and
shields parked on the rig, plus a hidden 1.9 m Icosphere) and measures 3.45 m
raw; and the **rest pose is not the posed body** - on Blender 4.4+ slotted
actions, setting `animation_data.action` without also setting `action_slot`
leaves the rig in rest and reports success.

## FAULT 1 - SCALE. TEN OF THE FOURTEEN ARE SHORTER THAN THE PARTY.

| | |
|---|---|
| hero | **2.45 m** |
| miniboss authored heights | 2.00 - 2.70 m |
| ratio to the hero | **0.82x to 1.10x** |

A set piece gated to floor 4 and deeper that the heroes **look down on** is not
a set piece. The Scrapwright is 0.82x a hero. Only the Bellman and the Snuffer
are taller, by 6-10%, which reads as a tall man and not as an event.

**This costs no geometry.** The mesh is authored at a proportion, not a size;
the in-game size is whatever `h` the game build lane types into `bestiary.gd`.
The recommendation is **authored + 1.30 m**, which keeps the order and the
spacing of the fourteen exactly as designed, puts the smallest at 1.35x a hero
and the largest at 1.63x, and stays clear below the smallest lord (4.2 m):

| key | authored | now | **recommend `h`** | vs hero |
|---|---|---|---|---|
| scrapwright | 2.00 | 0.82x | **3.30** | 1.35x |
| cook | 2.05 | 0.84x | **3.35** | 1.37x |
| boiler | 2.10 | 0.86x | **3.40** | 1.39x |
| tallyman | 2.15 | 0.88x | **3.45** | 1.41x |
| drillmaster | 2.20 | 0.90x | **3.50** | 1.43x |
| sower | 2.25 | 0.92x | **3.55** | 1.45x |
| porter | 2.30 | 0.94x | **3.60** | 1.47x |
| snarer | 2.30 | 0.94x | **3.60** | 1.47x |
| gaoler | 2.35 | 0.96x | **3.65** | 1.49x |
| stoker | 2.40 | 0.98x | **3.70** | 1.51x |
| sexton | 2.45 | 1.00x | **3.75** | 1.53x |
| sluicekeeper | 2.50 | 1.02x | **3.80** | 1.55x |
| snuffer | 2.60 | 1.06x | **3.90** | 1.59x |
| bellman | 2.70 | 1.10x | **4.00** | 1.63x |

A miniboss at these heights still **fits a three-cell corridor**: the corridor
test is the FOOTPRINT span, which is unchanged by `h` only if `h` is applied as
a uniform normalise - it is (`Monster` scales the body to `h` from its measured
bounds), so the widest, the Gaoler's 3.72 m chain coil, becomes 3.72 x 3.65 /
2.35 = **5.78 m, still inside the 11.0 m clear span**. None of the fourteen is
room-locked at the recommended heights either. The game build lane should
re-run its own clearance test rather than take my word.

## FAULT 2 - PROPORTION. THIS ONE IS THE ART LANE'S, AND IT IS NOT FREE.

The men inside these creatures are seven-head realistic figures with 0.10 m
limbs. The game's characters are chibi: head 55% of height, legs 21%, mitts for
hands. Side by side **they read as two different games** - the minibosses look
like pipe-cleaner men next to a toy knight.

`renders/art/minibosses/_proportion.png` is the worked example on one creature,
four cells, one change per cell: the Drillmaster as he is; rebuilt chibi at the
same 2.20 m; original at the recommended 3.60 m; and both changes together.
`minibosses.drillmaster_chibi` is the builder, keyed out of `ORDER` so it
changes none of the shipped fourteen.

**Both changes together is the one that works.** Proportion alone fixes the
register but leaves him small; height alone makes a thin scarecrow bigger.

### The honest fault list on the chibi Drillmaster - every one of these is visible

Two were found by looking and fixed in a second pass, and are named here rather
than hidden: the **eyes were inside the skull** (the head is 0.44 deep and they
sat at 0.40, so the face was blank from every angle), and the **helm read as a
mushroom** - a 1.24 m brim at mid-head height covering dome and face both.

What is still wrong, after the fix, in the picture as it stands:

1. The helm dome is a **sharp cone**, so it still reads as a pointed farmer's
   hat rather than a kettle helm. It wants a rounded cap.
2. The eyes are **flat pale discs with no pupil**. The knight has a dark pupil
   in a light eye; these read as blank goggles.
3. **No neck and no value break** between head and torso - both are `bone`, so
   the head's bottom edge is lost and the shoulder spheres read as two side
   blobs rather than shoulders.
4. The **baton reads as a lollipop** - a pale ball on a thin stick, hanging off
   a mitt that does not visibly hold it.
5. The **gong crowds the right shoulder** at this bulk and its struck rings
   barely read from the front; it is close to leaving the cell.
6. The **belt has vanished** into the body colour at wear 0.15.
7. **Boots read as hooves** - the legs are so short that the dark blocks are
   most of what is there.

**Do not convert the other thirteen until 1, 2 and 3 are solved on this one.**
They are register problems shared by every figure in the file, and solving them
thirteen more times is the expensive way to find that out.

## WHAT THE GAME BUILD LANE SHOULD DO - the art lane does not touch these files

1. **`scripts/bestiary.gd`** - the fourteen entries are still completely
   unwired (there is no reference to `minibosses` in that file at all). When
   they are added, use the **recommended `h` column above**, not the authored
   height, and no `anims` entry - these are static meshes with no armature.
2. **`scripts/dungeon_hd.gd` ~655** - the theme -> miniboss map, and split the
   shared `shrine`/`crypt` weight row (Snuffer = shrine, Sexton = crypt).
3. Re-run the spawn clearance test with the new heights before shipping.

## FOR MR. E - one decision, and the picture is `_proportion.png`

The fourteen read as a different art style from your own characters. The fix is
not cosmetic and it is not cheap: it is a rebuild of the figure inside each of
the fourteen, and the worked example says roughly a pass per creature. Worth
doing, worth doing later, or leave them realistic and let the dungeon be a
different register from the town? The height fix is free either way and should
happen regardless.

---

## REGISTER CONVERSION 2 OF 14 - THE STOKER, PASS 3

`renders/art/minibosses/_stoker_register.png` - original left, chibi right, a
real 2.45 m KayKit Knight standing beside each. Front, side and back per cell.
Ratio 0.98, pair 4.74 m, fits the fixed frame, blank check 2 files 0 failures,
`BLENDER_EEVEE`. Four faults closed, and the fourth was not where it looked.

**8 - THE T-POSE.** Both arms were TWO-POINT polylines leaving the shoulder
level or rising, so each read as a ball on a stick held straight out. Both are
three-point now with a real elbow: upper arm out and down, forearm forward and
in. A chibi arm is short enough that the elbow IS the read; without one there is
no arm, only a spoke.

**9 - THE LEFT MITT IN THE FLUE.** The mitt sat at x -0.64 and the flue stands
at -0.74 with a 0.115 radius, so the hand was inside the chimney's column in the
front silhouette and the two merged. The forearm now comes to the hip, mitt at
-0.44, clear of the flue's near edge and reading against the body.

**THE EYES.** A single dark oval on a pale skull is a HOLE, not an eye - the
Drillmaster's fault 2 arriving from the opposite direction. The hero's face has
three values and so does this one now: dark socket, pale eye sunk in it, dark
pupil, each standing slightly proud of the last. No glow - this creature's one
light is the grate, which is the thing the party has to starve.

**4 - THE VALUE BREAK, AND IT WAS THE LIMBS, NOT THE HEAD.** `limb()` defaults
to the `bone` slot. Every arm and leg was therefore PALER than the torso: a bone
stick-figure in a brown box, with the lightest things on the creature at its
ankles. Limbs now take the mid tone, boots and mitts the dark, the skull keeps
the bone. The single pale thing above the ground is the face.

### What is still wrong - looked at, front, side and back

1. ~~The heat cap reads as a bowl-cut of hair.~~ **FIXED IN THE SAME PASS, and
   deliberately so: this is the register fault the other twelve would have
   inherited**, and converting them over a cap that reads as hair is the
   expensive way to find that out. A dark dome on a pale skull has no edge
   between them. It now has a brim 0.08 proud of the skull sitting 0.11 above
   the eyes - the Drillmaster's mushroom is what that clearance is for - and a
   bone band in the seam for the cap to end at. Two things to watch in the
   picture as it stands: the brim's front edge runs **close to the eye line**
   and the eyes now sit in its shade (a gain in grimness, a hair from being
   fault 2 of the Drillmaster all over again), and the **bone band is the
   brightest ring on the head**, competing with the face it was meant to serve.
2. **The back is bare** - a flat slab with nothing on it but the flue passing.
   The knight has a cape there; this has nothing that says furnace from behind.
3. The pupils are **small and wide-set with no brow**, so the face reads doll-ish
   rather than grim. The value structure is right; the expression is not.
4. **The belt is invisible from the front** - dark on brown, and both forearms
   now cross it.
5. **Boots are dark blocks nearly as wide as the leg is long** - the Drillmaster's
   fault 7, shared by every chibi conversion so far.
6. From the side the **torso is a shallow slab**, 0.48 deep against a chibi
   knight who is round. Depth, not height, is what is missing.
7. The **fuel basket reads as a flat plank from the FRONT only** - from side and
   back it is plainly a bucket. It is a front-view presentation fault, not the
   geometry fault pass 2 recorded.
8. The **rake haft is `bone`** and is the brightest long line on the figure after
   the grate; it competes slightly with the face.
9. The **shoulder spheres overhang the upper arms** and float a little at the
   joint.

Twelve creatures still to convert. The Scrapwright and the Bellman are a machine
and a shroud with no man-proportions, and should be skipped.

---

## REGISTER CONVERSION 3 OF 14 - THE GAOLER (16 Nov, three passes)

`gaoler_chibi` in `tools/art/minibosses.py`. In CANON and BUILDERS, **keyed OUT
of `ORDER`** like the other two, so the shipped fourteen are untouched and
nothing in `bestiary.gd` should point at it until Mr. E picks the register.
Authored at the original's **2.35 m** so the pair sheet compares ONE thing.

Proof: `renders/art/minibosses/_gaoler_register.png` (original left, chibi
right, a real 2.45 m posed KayKit Knight beside each), plus
`gaoler_chibi/hero_side.png` and `hero_back.png`. Ratio **0.96**, pair width
**5.58 m**, fits the fixed frame. Blank check **2 files, 0 failures** on the
final pass and on every intermediate one. Engine `BLENDER_EEVEE`.

### What this creature forced that the first two did not

- **The stoop cannot be paid for in height.** The original's character is a man
  bent double, and a bent man is shorter - but both halves of the pair must be
  2.35 m or the sheet compares two things. So the stoop is bought in LEAN and
  CLOTH, in four places at once (torso axis, dropped shoulder, tilted mantle,
  head out over the toes with the face low on the hood). If Mr. E wants him
  standing shorter than the party, that is `bestiary.gd`'s `h`, not mine.
- **The hood is the head**, which makes this one EASIER than the Stoker. The
  Stoker's pass-3 register fault was a dark cap on a pale skull reading as a
  bowl cut; the Gaoler never has a pale skull to put a cap on. The one pale
  thing above the ground is the iron faceplate.
- **The apron is dropped.** The original says it existed "so the legs read as
  thin". Chibi legs are thick stubs, so the reason is gone, and any value it
  could take merges with the torso, merges with the boots, or outshines the
  face. The belt carries the hip read instead.

### The three passes, one change each, looked at every time

1. **The hood point was a WIZARD'S HAT.** A cone standing on the dome with a
   seam across the crown is a pointed hat whatever the comment calls it - the
   Drillmaster's kettle-helm mushroom in a third form. Replaced with a head
   deeper in y than wide and the point falling backward.
2. **The stoop was absent.** Pass 1 leant the torso 0.34 m over an 0.81 m rise,
   which on a chibi is nothing: he stood bolt upright, the one thing the
   original's own docstring forbids. Fixed in the four places above together,
   because the stoop is one read and no single one of them produces it.
3. **The hood's tail was a RABBIT EAR** - a flat paddle from the side, a dark V
   from the back; the wizard's hat lying down. Cloth over a head does not
   project, it gathers at the nape, so the point is now a bunched mass behind
   and below the skull, doubling as the hump a stooped figure wants.

### Faults I can still see - named, not hidden (ten)

1. **The faceplate reads as an ANGRY CARTOON MASK.** Two dark slots on a pale
   oval, with the low-poly facets slanting them, come out as a scowl. That is
   theatrical and Bellmire's register is not. The worst remaining front fault.
2. **The plate is a large bright oval** and is the loudest thing on the figure
   at pane distance - right by the value rule, wrong in degree.
3. **The nape cloth reads as a BUN OF HAIR** from the side - better than the
   ear it replaced, but still a second distinct sphere rather than gathered
   cloth. Fault 3 is improved, not closed.
4. **The brow cone reads as a flat-cap peak** across the top of the hood from
   the side, a hard brim line where cloth should round over.
5. **The back is bare** - a flat tan slab with nothing on it. The Stoker's
   fault 2 exactly; this is now a register fault shared by every conversion.
6. **The legs do not read from the SIDE.** From the front and back they are two
   stubs with boots; from the side the torso runs straight down into the boot
   with no hip or knee break at all, so he reads as a sack.
7. From the side the **torso is a shallow slab** against a round chibi knight -
   the Stoker's fault 6, carried.
8. **The hook is `bone` and is the brightest long shape after the face.** This
   is the Stoker's rake-haft fault, taken DELIBERATELY here: the hook is the
   mechanic and must be the second thing the eye finds. Judge it, do not
   assume it is an oversight.
9. **The belt is invisible from the front** - dark on brown. Third conversion
   running; it is the register, not the creature.
10. **The mantle's rim is a hard polygonal edge**, 20 segments showing plainly
    on a 0.62 m cone.

The chain coil is the best thing in the file from every view and was not
touched. The keys read cleanly on the right hip.

Eleven creatures still to convert. The Scrapwright and the Bellman remain the
recorded skip - a machine and a shroud, neither with man-proportions.


## REGISTER CONVERSION 4 OF 14 - THE SNUFFER (`snuffer_chibi`)

Sheet: `renders/art/minibosses/_snuffer_register.png` (original left, chibi
right, a real 2.45 m posed KayKit Knight beside each), plus
`renders/art/minibosses/snuffer_chibi/hero_front|side|back.png`. All three
looked at. Ratio 1.06, pair 4.21 m, fits the fixed frame, blank check 2 files
0 failures, engine BLENDER_EEVEE.

### WHY IT IS CONVERTED AND NOT SKIPPED

The first three were MEN. The Snuffer is a lamp-stand, and the easy call was to
put it with the Scrapwright and the Bellman in the recorded skip. That would
have been wrong, because **register is not man-proportions - it is how much
mass a shape carries and how many shapes there are.** The Scrapwright (a
lopsided mound) and the Bellman (a hanging shroud) are already bold masses and
read beside a chibi knight untouched. **The Snuffer was made of wire**: tripod
legs r 0.070, column r 0.105, cross-arms r 0.042, four PALE flute ribs at
r 0.016, and eighteen candles at r 0.040-0.045. A hero's arm is 0.29 thick. At
pane distance that is not eighteen candles, it is lint, and the creature reads
as one dark hat floating on a cloud of it. Same failure as the pipe-cleaner
men, in the one form a non-humanoid can have it.

Two things this one forced that the three men did not: **the fix is COUNT, not
only thickness** (eighteen candles thickened would weld into a hedge, so
eighteen become six and the six ring-candles are dropped outright - and the
count IS the mechanic, so a candle that cannot be counted is a mechanic that
cannot be read); and **the pale is a budget the ribs were spending** (the
Stoker's fault 4 in object form - pale hairlines spread over the whole body
while the one lit candle, the only colour and the whole point, was a 0.045
stub). The ribs are gone and the lit candle is now the biggest on the creature.

### FOUR PASSES, ONE CHANGE AND ONE RENDER EACH

1. Build: every member to a chibi weight, 18 candles -> 6, ribs removed.
2. **I OVERCORRECTED AND PUT THE MASS AT THE BOTTOM.** Legs at 0.180 splayed to
   0.56 made the base the heaviest thing on it - a camera tripod walking - and
   the cone at 0.58 had stopped dominating, so the "snuffer cone where a head
   belongs" read went with it. One read (where the mass sits), bought in three
   places: legs to 0.138 and drawn in to 0.47, cone to 0.74 x 0.56, column left
   exactly as it was so the change is legible as a ratio. Dropping the cone to
   keep the top at 2.60 also closed **a clip found in the pass 1 sheet**: the
   upper arm's candles topped out at 2.22, inside the cone's flare.
3. **THE CONE ATE THE CANDLES AND IT BECAME A MUSHROOM.** A 0.78 cap over 0.70
   and 0.46 arms puts every candle in its shade and hides the upper two
   outright; a wide cap on a stubby stem is a toadstool. Arms to 1.12 / 0.94 so
   every cup clears the rim. Nothing else touched.
4. **FROM THE SIDE IT WAS A MAN IN A STRAW HAT.** Both arms ran on X only, so at
   azimuth 90 the candles collapsed onto the column and what was left was a
   conical hat over a stumpy body with legs, holding a light - a FIGURE, the one
   thing a miniboss may never read as. Inherited, not introduced (the original's
   arms are X-only too), but a bolder body has more to be mistaken for a torso.
   The lower tier becomes a CROSS (one candle at each of four ends) and the
   upper bar turns onto Y. **Still six candles** - the count did not move.

### Faults I can still see - named, not hidden (eleven)

1. **The cone's dark rim reads as a separate SAUCER** with a visible seam - a
   lampshade sitting on a plate rather than one piece of sooted tin. Front and
   side both.
2. **The soot streaks read as UMBRELLA RIBS.** Five dark ribs down a smooth
   cone make a parasol, which is the opposite of what they are for.
3. **The cross-bars end in flat cut-offs** and read as scaffolding planks, not
   as wrought iron. The ends want a boss or a curl.
4. **Each candle reads as a BOLLARD.** The cup at 0.165 is nearly as wide as
   the candle is tall, and the dead wick (a 0.040 sphere) is invisible at this
   distance. They are countable shapes; they are not legibly candles.
5. **The six dead candles are nearly the body's own value.** `bone` at wear 0.90
   dulls to within a shade of `body`, so the pale budget saved from the ribs did
   not actually land anywhere except the lit one.
6. **From the front the two front legs read as a pair of legs.** The side view
   kills the figure read; the front does not, and the tripod's third leg hides
   behind the column there, so it looks like two.
7. **The column's two dark collars read as rings on a mushroom stem**, the
   lower one especially, sitting at an odd height with nothing meeting it.
8. **The held arm merges with the lower cross-bar from the front** - the lit
   candle looks like it is standing on the bar rather than being held. The mitt
   only reads from the side.
9. **The cone is smoother than anything on the hero.** 22 segments against a
   KayKit body's hard facets; it is the one surface that does not belong.
10. **The tripod pads are small** relative to the legs above them and read as
    rubber feet rather than as iron.
11. **Ratio 1.06**: it stands 6% taller than a hero, and a set piece the party
    does not look up at is not a set piece. That is `bestiary.gd`'s `h`, a GAME
    BUILD number (h = authored + 1.30 m), not mine.

Corridor: the pair is 4.21 m wide and the creature's own footprint is well
inside the 11.0 m clear span of a three-cell corridor. **CORRIDOR-SAFE** - no
spawn gate needed for it.

Ten creatures still to convert after this one.


## REGISTER CONVERSION 5 OF 14 - THE SEXTON (`sexton_chibi`)

Sheet: `renders/art/minibosses/_sexton_register.png` (original left, chibi right, a real
2.45 m posed KayKit Knight beside each), plus
`renders/art/minibosses/sexton_chibi/hero_front|side|back.png`. All four looked at, every
pass. Ratio 1.00, pair 3.93 m, fits the fixed frame, blank check 2 files 0 failures, engine
BLENDER_EEVEE. CORRIDOR-SAFE - the whole footprint is about 2.4 m, well inside the 11.0 m
three-cell span.

### WHAT THE ORIGINAL ACTUALLY READS AS

Looked at before anything was changed: **a post office sorting rack with a wire man under
it.** Measured off the builder, against a hero arm 0.29 thick - legs 0.100/0.082, hod
uprights 0.055/0.042, cell collars 0.075 slabs, arms 0.072/0.054, spade haft 0.055/0.048,
and the torso at 0.235 the only bold member on it. Three faults fall out of that:

1. **Every member except the torso is a wire**, so the man is a pipe-cleaner holding a
   window frame, and from the SIDE he disappears - a flat board on two threads.
2. **Nine thin cells are a grid, not graves.** At pane distance 0.075 collars round 0.40
   holes are glazing bars: a window, or a bookcase, and the lit plugs read as ENVELOPES.
3. **The count is the mechanic and nine is too many to count.** Four lit among nine is a
   pattern to be scanned. The Snuffer's lesson in its own form: a rising that cannot be
   counted from the doorway is a mechanic that cannot be read.

So this is the Snuffer's conversion, not the Drillmaster's - fattening the man is not
enough. **Six cells, not nine**, each big enough that the hole is a niche, and the lit count
stays **four**, because four risings is the fight.

### FIVE PASSES, ONE CHANGE AND ONE RENDER EACH

1. Build: every wire to a chibi weight (legs 0.150, hod uprights 0.105, cell members 0.145,
   spade haft 0.085), nine cells -> six, stoop and spade kept.
2. **IT WAS A CHEST OF DRAWERS.** The plug filled the cell face, a horizontal glow strip
   across it read as the drawer LABEL and the dark knob as the PULL. One read, bought where
   it was made: the plug becomes a rough stopper 0.60 of the mouth standing 0.34 proud, the
   light becomes a RIM leaking round it, the knob goes.
3. **THE MAN WAS BEHIND HIS OWN LOAD.** Head, shoulders and frame all sat inside the wall's
   outline - a cabinet with legs, which is the Porter's read. Not fixed by shrinking the
   wall (the wall is the mechanic): the stoop is deepened until the head breaks the outline
   below it.
4. **I OVERCORRECTED AND BUILT A QUADRUPED.** Pass 3 laid the spine almost flat, so from the
   side the barrel ran horizontal with the head hung off the front and both mitts near the
   floor - a dog. A miniboss may not read as a hero; it may not read as somebody's wolfhound
   either. Half the stoop back; the head still clears the wall, the spine is a diagonal again.
5. **THE COWL WAS A SAUCER.** A 0.44 brim cone over a dark dome on a neckless chibi is a
   lampshade from the front and a conical straw hat from the side - the Snuffer's pass-4
   fault in the one slot where it does most harm. A cowl is cloth drawn BACK over the skull
   onto the shoulders with a short peak over the face; no disc, nothing wider than the head.

### TWELVE FAULTS I CAN STILL SEE

1. The empty niches are holes from the BACK but read as dark panels from the FRONT, so the
   wall is still a slab there and keeps a cabinet quality.
2. The lit plug's glow is a flat square plate - it reads as a lit WINDOW PANE, not as light
   leaking round a stone. The worst remaining front fault and the one I would take next.
3. The wall's outline is a plain regular rectangle. It reads as masonry furniture, not as
   something strapped to a back; a hod is lashed and uneven.
4. The hod uprights are completely hidden behind the wall from the front, so the wall looks
   attached to nothing.
5. From the SIDE the wall is a thin plank edge-on and the whole mechanic disappears at
   azimuth 90 - inherited from the original, not introduced, but the bolder wall makes the
   loss bigger.
6. The spade reads as a shovel lying on the ground rather than one held: the blade meets the
   floor at the same angle the haft runs, with no wrist in it.
7. The near mitt merges with the torso from the front.
8. The hood cuts a dark band across the pale face plate, so the eyes barely read at pane
   distance.
9. The boots merge with the spoil mounds at that distance - two dark lumps and two dark
   boots in one silhouette.
10. From the back, his own shoulders show THROUGH the two lower cells, which half-fills two
    of the holes the pass-2 fix opened.
11. Ratio **1.00** - a set piece the party looks level at, not up at. Same note as the
    Snuffer's 1.06; that is the game build's `h`, not mine.
12. The two dark cells read as missing panels rather than spent graves - nothing says a
    grave was ever there.

Ten creatures still to convert. The Scrapwright and the Bellman remain the recorded skip -
a machine and a shroud, neither with man-proportions.


## REGISTER CONVERSION 6 OF 14 - THE PORTER (`porter_chibi`)

Sheet: `renders/art/minibosses/_porter_register.png` (original left, chibi right, a real
2.45 m posed KayKit Knight beside each), plus
`renders/art/minibosses/porter_chibi/hero_front|side|back.png`. All looked at, every pass -
six passes, six renders. Ratio 0.94, pair 5.52 m, fits the fixed frame, blank check 2 files
0 failures, engine BLENDER_EEVEE. CORRIDOR-SAFE - the bar runs 3.66 m tip to tip after
normalisation and the whole footprint is under 3.7 m, well inside the 11.0 m three-cell span.
It is the WIDEST of the fourteen and the only one where that is worth saying out loud.

### WHAT THE ORIGINAL ACTUALLY READS AS

Looked at before anything was changed: **a man standing in a wardrobe holding three separate
planks.** Measured off the builder, against a hero arm 0.29 thick and a hero head 1.09
across - legs 0.115/0.092, arms 0.090/0.068, torso 0.270/0.280 the one bold member, head a
0.155 sphere (0.31 across, a FIFTH of the hero's), drawbar 0.19 square and built out of five
separate boxes. Four faults fall out of that:

1. **Every member except the torso is a wire.** Third conversion running; it is the register.
2. **The widest horizontal in the dungeon is not a horizontal.** The original raked the bar
   by building it from a centre box plus two offset end boxes plus two detached shoes, each
   nudged in y and z. On the sheet those read as THREE SEPARATE PLANKS with iron rubble
   floating off the left end. The rake was meant to stop either end hiding; what it did was
   break the one member the creature is named for. **A bar is ONE PIECE.**
3. **The leaf is a sentry box.** Square-on behind a man of the same width it stops being a
   door he carries and becomes a cabinet he stands in - and from the SIDE the same slab is
   edge-on, a plank, and the mechanic is gone from that view entirely.
4. **The back of the leaf is bare** - every band and boss on the front face only. That is the
   Gaoler's fault 5 and the Stoker's fault 2, and this is the conversion that stops carrying it.

### AND THE CARRIED FAULT, TAKEN HERE BECAUSE 6 OF 14 HAS A HEAD

The supervisor's 13:58 instruction: the Gaoler's faceplate reading as an ANGRY CARTOON MASK
has travelled three conversions, fix it where there is a head. The Porter had the same plate
in miniature - a pale `bone` slab on a dark helm, a dark slot across it, two glowing eyes
behind - and at pane distance it is a TOY ROBOT. The diagnosis is not brightness, it is
**count and value**:

- **TWO apertures read as EYES however they are shaped. ONE reads as a SLIT.**
- **A PALE plate on a dark head is a FACE. A DARK plate is a DOOR.**

So the Porter's helm is dark iron end to end, with one unbroken sight slit under a brow
shelf and no eyes at all - "a door has no face either" is the original's own line and this is
it kept. The pale value the three-value stack wants does not vanish, it MOVES TO THE OAK: the
bar is the palest thing on the creature, which is also the mechanic, so the brightest member
and the dangerous one are now the same object. Nothing vertical crosses the slit; a helm
reinforce down the middle would cut it in two and hand the face straight back.

### SIX PASSES, ONE CHANGE AND ONE RENDER EACH

1. Build: every wire to a chibi weight (legs 0.150, arms 0.150/0.125, torso 0.38, head 0.80
   across), the leaf YAWED 22 degrees in plan so it reads broad from the side and narrow from
   the front, the bands and bosses wrapped onto both faces, the bar rebuilt as one member,
   and the helm turned into a door.
2. **HE WAS STILL STANDING IN IT.** The yaw fixed the side, but a 2.16 m leaf anchored at
   chest height still runs above the helm, so from the front the head was a dark lump inside
   the door's outline and from the back he was gone altogether. A man does not carry a door
   over his head: the leaf is slung LOW, standing on its own bottom edge behind his heels,
   and the helm clears the top of it - which is also the only way a deliberately dark helm
   gets a silhouette at all.
3. **THE BAR CAME APART AT BOTH ENDS AGAIN, and the frame proved it in numbers.** The iron
   shoe's taper was seated 0.10 OUTSIDE the end of the oak - the original's exact fault
   rebuilt by accident, visible on the back sheet as a wedge floating clear. And dropping the
   leaf made the helm the tallest thing, so the normaliser scaled the creature up by a
   quarter and a 3.24 m bar came out 4.05 m: the pair burst the fixed frame at 6.69 m against
   5.60. Cone seated ON the end point, bar authored at 2.48.
4. **THE ONE SLIT CAME OUT AS TWO EYES, AND I DID NOT DECIDE THAT - THE GEOMETRY DID.** The
   head crop of pass 3 shows two bright rectangles with a dark gap between them: a face, the
   exact read this conversion exists to kill. Cause, measured: the dome was 0.42 deep in y
   and bellied to -0.54 while the plate's face sat at -0.51, so the dome covered the MIDDLE
   of the slit and left its two ends showing. **The lesson is general: one aperture becomes
   two whenever anything round stands in front of its centre. It has to be measured against
   everything forward of it, not declared.** Dome shallowed to 0.30, slit 0.04 proud of the
   plate, brow shelf the only thing in front of it and above it.
5. **THE BAR WAS CARRIED ACROSS HIS OWN FACE.** At a mid height of 1.23 the near end stood
   above the shoulder and the oak ran under the chin and through the slit's line, so the two
   loudest things on the creature - the mechanic and the one lit aperture - fought each other
   at pane distance. Dropped to chest height, rake halved. A drawbar is carried at the height
   of the brackets it goes into, which is where the belt sockets already are.
6. **FROM THE SIDE THE BAR WAS A POINT.** Square across the body, the side camera sees 2.48 m
   of oak end-on: three boxes stacked at the lens, reading as a chimney, and the member the
   creature is named for contributed nothing to a third of its views. Same fix as the leaf
   got in pass 1 - 16 degrees of plan yaw, 4% of the front width spent, 0.72 m of visible
   length bought.

### THIRTEEN FAULTS I CAN STILL SEE

1. **The arms do not read from the front.** Between the shoulder and the bar there is no
   visible limb, so the two fists appear to sit ON the oak with nothing joining them to him.
   The worst remaining front fault and the one I would take next.
2. **The torso is almost entirely hidden** between the helm and the bar - the man is a helm,
   two shoulder lumps, a bar and a pair of boots.
3. **The grips read as crates hung on the bar**, not as closed fists: a 0.21 x 0.32 dark box
   at that distance is cargo.
4. **The leaf's front bands cross his hips** as three horizontal stripes, so from the front
   he reads as wearing a ladder.
5. **From the SIDE the bar is a battering ram** - it points at the lens at chest height and
   the man reads as standing behind a weapon rather than carrying a bar. The yaw bought
   length; it did not buy a held read.
6. **From the SIDE the helm is a featureless dark egg.** The slit is a front-only feature, so
   the head has nothing at azimuth 90 - the inverse of the Gaoler's fault, and arguably the
   price of killing the face.
7. **From the SIDE the whole figure is a pile of boxes** - nothing separates torso from leaf
   from bar in value. The Stoker's fault 6 and the Gaoler's fault 7, carried.
8. **The leaf reads as a banded packing crate, not a door.** Bands and bosses on both faces
   and hinge straps on both edges is not how a door is built: a door hinges on ONE edge and
   has a lock plate on the other, and this one has neither.
9. **From the BACK the man is still mostly gone** - a dark dome above a crate. Better than
   the original, where he was gone completely, but not fixed.
10. **The slit is a flat glow plate with no depth** - at crop scale it reads as a sticker
    rather than light standing in a gap. There is no recess behind it.
11. **The brow shelf floats** above the slit as a separate band instead of overhanging it.
12. **The boots and the leaf's bottom rail merge** into one dark mass at the floor from the
    front.
13. Ratio **0.94** - the Porter is still SHORTER than a viewer's hero, which for a creature
    whose whole idea is that it closes the room is the wrong way round. That is `bestiary.gd`'s
    `h`, not mine; same note as the Snuffer's 1.06 and the Sexton's 1.00.

Eight creatures still to convert, two of them the recorded skip - the Scrapwright and the
Bellman, a machine and a shroud, neither with man-proportions.


## REGISTER CONVERSION 7 OF 14 - THE TALLYMAN (`tallyman_chibi`)

Sheet: `renders/art/minibosses/_tallyman_register.png` (original left, chibi right, a real
2.45 m posed KayKit Knight beside each), plus
`renders/art/minibosses/tallyman_chibi/hero_front|side|back.png`. All looked at, every pass -
six passes, six renders, plus a 2x head-and-chest crop that is how three of the six faults
were caught at all. Ratio 0.88, pair 3.58 m, fits the fixed frame, blank check 2 files 0
failures, engine BLENDER_EEVEE. Mesh shipped: `assets/monsters/minibosses/tallyman_chibi.glb`,
4 meshes, 1558 faces, static, no armature. CORRIDOR-SAFE - footprint span **1.72 m** against
the 11.0 m three-cell clear span, and the NARROWEST of the fourteen, so if anything in this
file is ever room-locked it will not be this one.

### WHAT THE ORIGINAL ACTUALLY READS AS

Looked at before anything was changed: **a surveyor's tripod with a washing line on it** -
and from the back, a clothes horse. Measured off the builder, against a hero arm 0.29 thick
and a hero head 1.09 across - legs 0.072/0.056, arms 0.062/0.040, fingers 0.020, quill
0.020/0.008, frame uprights 0.08, bead wires 0.035, five hanging cords at 0.014, torso
0.52x0.34x0.44 and a head 0.26x0.30 which is a SIXTH of the hero's. Five faults fall out of
that, and only the first is the usual one:

1. **Every member except the torso is a wire.** Fourth conversion running; it is the register.
2. **The receipt is unreadable, and that is the worst of the five.** This is the one creature
   in the file whose entire job is Mr. E's binding principle - what it has taken is HANGING
   ON IT, where the viewer who paid for that helm can see it. On the sheet the helm is a grey
   ball, the boot a dark chip, the satchel a chip, the blade a toothpick and the ring a wire
   hoop. The modelling was there. The SIZE and the VALUE BREAK were not.
3. **The spreader bar is a scaffold.** 1.86 m of horizontal bone at shoulder height with five
   cords dropping off it is a drying rack, and it is what makes the creature read as
   architecture. It was pass 2's fix for the kit fusing with the torso and it worked by
   turning him into a frame. Both can be had: the kit hangs off a ring he WEARS.
4. **Zero depth - the mechanic is gone at azimuth 90.** Frame, beads, spreader and all five
   hangers sit in ONE Y plane, so from the side the creature is a fencepost with twigs and
   there is no tally and no loot on it at all. This is the Stoker's fault 6, the Gaoler's 7
   and the Porter's 7 in its hardest form, because here there is nothing TO separate. It is
   the carried fault and this conversion takes it: the loot goes AROUND him in plan at five
   azimuths, so every view has three or four pieces and no view has the lot.
5. **Twenty-one beads is not a count.** Four rows of 7/5/3/6 at 0.052 is a texture. The
   Sexton's lesson in its own form.

**And one ruling applied rather than a fault: the hung RING is gone.** Mr. E, 04:56 - "i
understand the rings but gloves can be seen so we dont have to make new rings." A 0.065 wire
hoop at pane distance was the proof of his own point. Its slot goes to a SHIELD, which reads
at any distance.

### SIX PASSES, ONE CHANGE AND ONE RENDER EACH

1. Build: every wire to a chibi weight, the strongbox PROMOTED from an add-on to the torso
   itself, twenty-one beads to six, the gantry replaced by a hoop he wears with the loot at
   five azimuths, and every stolen piece taken from 0.13-0.25 up to 0.34-0.62 with a value
   break on each. The depth fix worked first time and is the one thing here that did.
2. **THE SHADE WAS A FUNNEL AND THE HEAD WAS AN EGG.** An inverted cone 0.30 across over a
   0.33 dome is a MARTINI GLASS from the front, a WINE GLASS from the side and, with the
   dome, a PERFUME BOTTLE from the back - the Sexton's pass-5 saucer and the Snuffer's pass-4
   lampshade, walked into again in the same slot. The rule those two paid for is absolute:
   **nothing on a head may be wider than the head, and nothing round belongs on top of
   something round.** The lamp goes; the head becomes a SECOND STRONGBOX, squared, banded,
   hasped - the same object as its chest in miniature. A tallyman keeps his head the way he
   keeps his takings.
3. **SIX BEADS CAME OUT AS A BREAD ROLL.** I cut twenty-one to six to make the count readable
   and then spaced them 0.14 apart at radius 0.11, so adjacent beads OVERLAP and the row
   fuses into one pale sausage. The count was still unreadable, by my own hand, in the pass
   written to fix exactly that. **The lesson is arithmetic and it is general: a row of n
   spheres reads as n only while the gap exceeds twice the radius. It is measurable before
   rendering and I did not measure it.** Four beads, 0.25 apart, 0.02 of clear air between.
4. **THE TALLY AND THE LOOT WERE ON THE SAME LINE.** Spacing was necessary and not sufficient:
   at z 1.22 the rod sat level with the shoulders, the tally ring and the hung helm, so four
   pale beads, two pale shoulder balls and a pale helm made ONE pale band straight across the
   creature and nothing in it could be told from anything else. **Two mechanics cannot share a
   horizontal.** The rod drops onto the clear brass between the box's two wrapping bands, and
   the coin slot drops with it so the two do not simply swap the collision.
5. **HALF THE BEADS WERE THREADED ON NOTHING AND A PIPE STUCK OUT OF HIS RIGHT SIDE.**
   `lordlib.cone` is built along +Z **with its base at the origin, not centred**, so aiming it
   along +X from x=0 ran the whole 1.02 m of rod to the RIGHT: the two left beads hung in
   mid-air and 0.6 m of iron projected clear of the body like a spigot. The Porter's pass-3
   note says the same thing from the other side. Caught on the crop, not on the full sheet -
   at cell size it was a thin dark line and looked like an arm. Pair width 3.77 -> 3.58 m.
6. **THE HELM WAS A MUSHROOM**, and it is the piece that matters most, because this creature
   exists so a viewer can see THEIR OWN HELM hanging on it. A 0.46 pale dome with a 0.44 flat
   dark band directly under it is a disc exactly as wide as the thing above it - the shade's
   fault for the third time in one session. **A helm does not read by being dome-shaped. It
   reads by having a sight slot, a brow over it and a neck under it**, and it had none of the
   three. One dark slot, not two: the Porter's rule holds for a helm on a hook exactly as it
   holds for a head.

### THIRTEEN FAULTS I CAN STILL SEE

1. **From the SIDE the torso is a black void** - nothing separates box from ring from legs in
   value, and the one lit thing (the coin slot) is a front-only feature. The Stoker's fault 6,
   the Gaoler's 7 and the Porter's 7, carried. Worst remaining fault and the one I would take
   next.
2. **From the SIDE the head is a plain dark box.** The slit is front-only, so at azimuth 90 the
   head has nothing on it at all. The Porter's fault 6 exactly, carried, and for the same
   reason - it is the price of a deliberately dark head.
3. **From the SIDE and the BACK the four beads vanish.** They sit flush to the box face, so the
   count - the thing this creature is named for - is a front-only mechanic.
4. **The tally ring reads as a round TRAY or a table-top**, worst from the back, where it is a
   pale ellipse with things standing on it. It is meant to read as a hoop strapped round him.
5. **The helm's outline is broken from the front** - it is crowded between the left shoulder
   ball and the slate, so the piece a viewer most wants to recognise is the one piece with
   something in front of it.
6. **The slate merges with the strongbox** and reads as a drawer front, not as something held.
   The hand holding it is behind it and invisible.
7. **The pinch mitt is hidden behind the shield** from the front, so "it lifts, it does not
   hook" is not visible in the view that matters.
8. **The hung pieces are axis-aligned in world space** - none of them is turned to face its own
   azimuth, so the sword and the boot at +/-120 are seen from an arbitrary angle rather than
   presented. This is why the sword is only a pale sliver at the left edge.
9. **The sword is the least visible piece on the creature** and for most viewers it is the item
   they would most want to see on it.
10. **The boots merge with the leg posts** - one dark mass from mid-shin down. The Sexton's
    fault 9 and the Porter's 12, carried.
11. **From the BACK the purse reads as a gourd or a water-skin**, not a coin purse, and the
    glow coin that would have said "coin" is hidden behind it.
12. **The shoulder balls read as pauldrons** on a creature wearing no other armour - two pale
    domes with nothing to justify them.
13. Ratio **0.88** - the Tallyman is SHORTER than a viewer's hero, which for a creature whose
    whole threat is that it walks off with your kit is the wrong way round. That is
    `bestiary.gd`'s `h`, not mine; same note as the Snuffer's 1.06, the Sexton's 1.00 and the
    Porter's 0.94. The recommended `h` for this one is **3.45 m**.

Seven creatures still to convert, two of them the recorded skip - the Scrapwright and the
Bellman, a machine and a shroud, neither with man-proportions.

---

## REGISTER CONVERSION 8 OF 14 - THE COOK (`cook_chibi`)

Sheet: `renders/art/minibosses/_cook_register.png` (original left, chibi right, a real
2.45 m posed KayKit Knight beside each), plus
`renders/art/minibosses/cook_chibi/hero_front|side|back.png`. All looked at, every pass - six
passes, six renders. Ratio 0.84, pair 3.96 m, fits the fixed frame, blank check 2 files 0
failures, engine BLENDER_EEVEE. Mesh shipped: `assets/monsters/minibosses/cook_chibi.glb`,
4 meshes, **2539 faces** - the heaviest in the file and worth saying so; the 24-segment
cauldron and the two apron membranes are where it went. Static, no armature.
CORRIDOR-SAFE - footprint span **2.10 m**, which at the recommended `h` of 3.35 becomes
3.43 m against the 11.0 m three-cell clear span.

### WHAT THE ORIGINAL ACTUALLY READS AS

Looked at before anything was changed: **a sandwich-board man standing next to a washtub** -
and from the side it is worse, it is a washtub and the man is gone. Seven faults, and only
the first is the usual one:

1. **Every member except the torso and the pot is a wire.** Fifth conversion running.
2. **The pot is a wooden tub with a lid on, and the pot is the whole fight.** Two causes,
   both mine: an 18-segment sphere shows its vertical facets and vertical facets on a round
   brown vessel are STAVES; and the mouth is wider than the belly, which is the proportion of
   a tub. The pale flange with a lit disc under it reads as a LID, so the one thing a party
   has to spill was sealed.
3. **The apron is a sandwich board** - 0.74 x 0.90 of flat pale panel at one value, hung on
   the front plane only, the largest member on the creature, saying nothing and hiding the
   torso behind it.
4. **The pot is parked, not slung.** Its bottom sat on the ground line and its chains were
   0.026 wires. The whole idea is a man bent under a weight and nothing was bearing.
5. **The man is gone at azimuth 90.** Pot at x +0.86, man at x 0, everything in one y plane.
6. **The ladle is a lollipop** - a 0.034 haft with a 0.17 ball 1.2 m up in clear air.
7. **Three mess bowls on nothing** - 0.115 cones spaced 0.075 on a 0.012 cord. The Tallyman's
   arithmetic failed again: gap must exceed twice the radius.

**And the face is inside the skull** - `eyes()` called at y 0.0 on a head centred at y -0.18,
so the pupils sat behind 0.16 m of scalp. That is the Drillmaster's pass-2 fault verbatim,
shipped a second time in this same file.

### THE CARRIED FAULT, AND THIS CONVERSION TOOK IT

The lit mechanic has been a **front-only feature** on every creature here - the Tallyman's
coin slot, the Porter's, the Sexton's niches. A party reads a set piece from whichever door it
came in by. The Cook's heat is now the **mouth of the pot**: a glow ring proud of the rim,
radially symmetric, so there is no azimuth and no elevation this rig will ever shoot at from
which the pot is not visibly ON.

### SIX PASSES, ONE CHANGE AND ONE RENDER EACH

1. Build: every wire to a chibi weight, a 0.80 barrel torso behind the apron instead of a
   0.265 spine, the pot slung with visible chains, the mess kit given a keg for mass, and the
   eyes put on the face with pupils in them.
2. **AN X OFFSET IS DEPTH, NOT SEPARATION.** Pass 1 pulled the pot in from x 0.86 to 0.78 and
   nudged it 0.12 in y, and at azimuth 90 the man was still gone - of course he was, the side
   camera looks down the X axis. **The lesson is general: a load carried on ONE axis is
   invisible from that axis.** The carry went DIAGONAL IN PLAN at 40 degrees - pot back-right,
   kit front-left, the man between them in every view.
3. **THE FIRE CAME OUT AS A SOCK WITH TEETH IN IT.** Pass 2's fire was a flat glow disc with
   three dark grate bars across it. At 6 degrees of elevation a squashed disc is seen EDGE ON -
   a pale band, with the bars reading as teeth. From the side the pot had a mouth, the wrong
   way. **A flat disc is not a shape at this elevation, it is a line.**
4. **THE BAIL IS THE ONE CUE THAT SETTLES TUB VERSUS POT.** An urn, a crock and a washtub all
   have a belly and a lip; none of them has a handle arching over the mouth. Three passes went
   on proportion and facet count trying to argue the thing out of being a barrel and one arc
   did it. Same pass: a pelvis, because **from the BACK the legs were two stumps under a
   floating ball** - the torso bottom at 0.52, the hips at 0.43 and nothing bridging the 0.09.
   The apron hid it from the front and there is no apron behind.
5. **THE TAPERS CAME BACK POPCORN.** Pass 3's flame cones read as a bowl of rice in a cup
   sitting on the floor beside his boot - eleven parts buying a fault. The brazier was deleted
   outright and the heat moved to the rim. Same pass: the apron stopped being a signboard
   (a rectangle with a framed edge and two dark rectangles on it is a NOTICE, and the scorch
   patches put there for Mr. E's wear rule were the two windows) and became a tapered membrane
   with a kicked hem and two tie-ends; and the ladle got a deep bowl with a dark hollow and a
   ferrule, because **a flat pale oval on a stick is a lollipop whatever the stick is made of.**
6. **THE SCOURED RIM WAS EATING THE FIRE.** The pale `bone` lip - put there for the wear rule,
   a cook keeps his pot - sat directly against the glow ring, and at this aura the `glow` slot
   normalises to very near white. **Bright-next-to-pale is no contrast at all**, so the burning
   mouth read as a polished one. The bone lip went; the pot is black iron end to end and the
   only pale thing on it is the fire. The pot also dropped 0.12 so the man's head and shoulders
   clear it at azimuth 90.

### THE VALUE PLAN, MEASURED RATHER THAN ASSUMED

At the Cook's wear of 0.60 the generator's `body` lands at luminance 0.372 and its `bone` at
0.441 - **a 19% separation, the weakest in the file**, which is why the original's apron, torso
and head all read as one pale mass. Nothing in this conversion leans on body-versus-bone: the
figure is `body`, every break on it is `dark` (luminance 0.06), the pot is `dark`, and the fire
is the only `glow`.

### TEN FAULTS I CAN STILL SEE

1. **The bail reads as two thin dark struts** - spider legs over the pot, worst from the front
   and from the side, where the arc's near and far limbs separate. It wants to be a flat strap
   rather than a tube, or thicker again.
2. **The ladle bowl is a second head at azimuth 90.** It sits directly above and behind the
   skull at a similar size, so from the side the creature has two balls stacked on it.
3. **The ladle still reads as a mallet or a mushroom from the front**, deeper bowl and all.
   Four passes have not made this member honest and it is the one I would take next.
4. **The bowl stack is a fused dark cluster.** The arithmetic was done for the rims and not for
   the silhouette: three 0.165 cones at 0.20 pitch merge into one ribbed blob at cell size, and
   it reads as a stack of tyres or a concertina. The Tallyman's lesson, failed in a new way.
5. **The keg is invisible from the front** - entirely behind the torso. The counterweight that
   was built to justify the balance only exists in the side and back views.
6. **The legs read as two dark blocks.** Boots and shins are one value from mid-shin down - the
   Sexton's fault 9, the Porter's 12 and the Tallyman's 10, carried, and not taken here.
7. **The apron is still slab-like at cell size.** The taper and the kicked hem read at 2x; at
   the size a viewer sees it, it is a pale panel.
8. **The lit mouth is a flat cream disc, not a fire.** It reads as something hot in a pot,
   which was the brief, but it does not read as flame - the `glow` slot at this aura is near
   white and EEVEE gives it no bloom to spread.
9. **2539 faces** - 63% more than the Tallyman and the heaviest set piece in the file.
10. Ratio **0.84** - the Cook is SHORTER than a viewer's hero, which for a creature the party
    has to reach past its pack to kill is the wrong way round. That is `bestiary.gd`'s `h`, not
    mine; recommended `h` for this one is **3.35 m**.

Six creatures still to convert, two of them the recorded skip - the Scrapwright and the
Bellman, a machine and a shroud, neither with man-proportions.

**THE SKIP RULING CAME BACK GRANTED** (supervisor, 16 Nov 17:02), with one
condition: a skip is still a CLAIM about how something reads, and every other claim in this
file has a number behind it, so both go through the fit harness ONCE and are recorded here
marked SKIPPED, MEASURED. That is done and the two rows are directly below.

================================================================================
## THE TWO SKIPS, MEASURED - THE SCRAPWRIGHT AND THE BELLMAN

One render run, the existing harness, the fixed frame, beside a chibi Knight at scale 1.0.
Sheet: `renders/art/minibosses/_skipmeasure.png`, report `_fit_skipmeasure.json`,
footprints `_footprint.json`. **Blank check: 2 files, 0 failures. BLENDER_EEVEE.**

| key | ratio vs hero | pair span | fits frame | footprint span | meshes / faces | verdict |
|---|---|---|---|---|---|---|
| `scrapwright` | **0.82** | 4.62 m | yes | **2.76 m** CORRIDOR-SAFE | 4 / 975 | SKIPPED, MEASURED |
| `bellman`     | **1.10** | 4.58 m | yes | **2.72 m** CORRIDOR-SAFE | 4 / 842 | SKIPPED, MEASURED |

**THE BAND THE CONVERTED EIGHT SIT IN** is ratio 0.84 - 1.06 and pair span 3.58 - 6.69 m.
The two skips land at 0.82 and 1.10: **0.02 and 0.04 outside the converted band's ends, and
well inside the set's own range.** Both differences are `bestiary.gd`'s `h` - one number the
game build lane types - and not geometry. Nothing in the measurement argues for converting
either.

**AND THE HONEST HALF, BECAUSE THE RULING ASKED FOR A CLAIM WITH A NUMBER BEHIND IT AND I CAN
SEE SOMETHING THE NUMBERS DO NOT COVER.** I looked at the sheet. The reasoning for the skip
holds for the MASSES: the Scrapwright is one lopsided dark mound and the Bellman is one bold
pale cone, and neither reads as a figure, so "chibi" has nothing to act on - that is exactly
right and it is why converting them would change nothing a viewer can see. But each carries
members that ARE wire by the standard the other twelve were converted against: the
Scrapwright's arm out to the box and its strut down to the tray are two thin struts off a
heavy body, and the Bellman's three hanging arms are thinner than a hero's limb at the same
distance. **That is a smaller fault than a pipe-cleaner man and it is NOT what the register
conversion exists to fix** - it is member thickness, not proportion - so I am not reopening
the ruling on it. It is recorded here so that if Mr. E ever points at either one on stream
and says the arms look like wire, the answer is in this file and nobody has to re-derive it.

================================================================================
## REGISTER CONVERSION 9 OF 14 - THE SLUICEKEEPER (`sluicekeeper_chibi`)

Sheet: `renders/art/minibosses/_sluice_register.png` (original | chibi, a real posed 2.45 m
KayKit Knight beside each), plus `renders/art/minibosses/sluicekeeper_chibi/hero_front|side|
back.png`. **Ratio 1.02 · pair span 5.36 m · fits the fixed frame · blank check 2 files, 0
failures · BLENDER_EEVEE · `sluicekeeper_chibi.glb` 4 meshes, 2623 faces, static, no armature
· CORRIDOR-SAFE, footprint span 3.50 m (4.48 m at the recommended `h` of 3.20).**

### WHAT THE ORIGINAL ACTUALLY READS AS
A seven-head pipe-cleaner man with 0.10 m limbs holding a thin wheel on a thin frame, with a
puddle. Beside a chibi Knight he is from another game, which is the fault this whole register
exists to close. The IDEA does not change: man, open wheel high on his right, screw, gate
board, water.

### THE EIGHT PASSES, ONE CHANGE AND ONE RENDER EACH
1. **Built in register** - stub legs, barrel torso, big head, mitts, a hood set into the crown,
   the wheel turned 40 degrees in plan so it is open from the front AND the side, the water a
   lit basin with a proud rim.
2. **THE MACHINE CAME BACK A TANGLE AND MY OWN VALUE PLAN DID IT.** Measuring `bone` at only
   14% off `body` at this wear, I put the whole creature in `body` and `dark` - and so the
   wheel, the posts, the beam and the screw were one value and the handwheel, which IS this
   creature's silhouette, disappeared into the frame. Frame and beam back to `bone`.
   **THE LESSON: a weak pair in the palette is not a reason to use ONE value for everything;
   it is a reason to find which pair IS strong and build on that.** Here it is bone/dark,
   0.342 against 0.060.
3. **THE WATER CAME BACK A DISPLAY PLINTH.** A pale circle, flat on the floor, with a dark
   kerb outside the bright rim, carrying a figure: that is a cake stand. Every cue added for
   legibility was a cue for furniture. **WATER HAS NO EDGE OF ITS OWN - IT TAKES THE EDGE OF
   WHAT IT IS IN.** Kerb deleted, outline made irregular on eight unequal lobes, surface
   raised so it CUTS the legs instead of carrying them.
4. **HIS BOOTS WERE STILL UNDER A SHEET.** A surface with no side is a sheet, not a flood.
   The water got a skirt down to the floor and became a volume.
5. **THE ARMS CAME BACK AS A PLANK, AND THE CAUSE WAS THE LAYOUT.** With the man off to one
   side of the wheel's plane, the nearest rim was 0.85 m ACROSS the wheel and both arms had to
   span it, merging into one bar with a ball on the end. **NEW RULE: A FIGURE OPERATING A
   MACHINE MUST STAND IN THE MACHINE'S OWN PLANE** - you turn a handwheel from its edge. He
   moved along the machine's axis, which keeps the Cook's diagonal on BOTH axes.
6. **HE WAS STANDING ON THE WHEEL** at 1.30 m out, so the rim was read through a man; and the
   basin, still hand-typed, left the OUTER BOOT CORNER STICKING OUT OF THE WATER at 1.11 m
   against a 0.98 m lobe - found by measuring the dark slot's vertices below the waterline,
   not by staring. Deriving a CIRCLE to fix it put the pair at 5.77 m against a 5.60 m cell,
   so the basin became an ELLIPSE on the machine's axis with both semi-axes computed from the
   boot corners and the posts' feet. It cannot leave a foot dry by construction.
7. **THE NEAREST-POINT SCAN WAS SEARCHING THE WRONG HALF OF THE WHEEL** - a straight bug.
   `cos(a)*WR` is the coordinate along the machine's axis, so a near pi is the quadrant
   pointing AWAY from the man, and four passes of arm work had been faithfully finding the
   nearest point of the far rim. Upper hand to the near-TOP quadrant, lower to the near-BOTTOM.
8. **THE WATERLINE, AND I HAD THE ELEVATION ARITHMETIC BACKWARDS.** The front view was right
   and the back view still showed his boots through the water. An ortho ray at 6 degrees aimed
   at the top of a 0.13 m boot crosses the surface plane `(BZ - 0.13) / tan(6 deg)` BEFORE it
   arrives: at BZ 0.30 that is **1.62 m of water that must lie between camera and boot**. From
   the front the pool is nearly that deep; from the back he stands at the near edge and the
   camera looks straight under the surface. Widening to 1.6 m of margin broke the frame at
   5.86 m. The SURFACE CAME DOWN to 0.15 instead, where the required reach is 0.19 m and the
   0.22 m margin already has it. **THE RULE: at this elevation a raised surface hides what
   stands in it only if it REACHES `(height - object top) / 0.105` metres toward the camera.**

### THE VALUE PLAN, MEASURED RATHER THAN ASSUMED
At this wear of 0.95 - the highest in the file, and justified, because this is the one thing
down there that is never dry - `body` lands at luminance 0.299 and `bone` at 0.342: a **14%
separation, weaker than the Cook's 19% and the weakest in the file**. So nothing leans on
body-versus-bone. The man is `body`, every break on him is `dark` (0.060), the machine's wheel
and screw are `dark` against a `bone` frame, the gate board is the one other `bone` object,
and the water is the only `glow`.

### THE CARRIED FAULT, TAKEN - AND THE PROOF IS NOT VISIBLE ON THIS CREATURE
"The legs read as two dark blocks" is the Sexton's fault 9, the Porter's 12, the Tallyman's 10
and the Cook's 6, carried four times. The cause was that shin and boot were both `dark`, which
is 0.060 against 0.060. Here the shins are `body` and only the boot is `dark`, so the leg
breaks in value at the ankle where a real one does. **It is in the file and it is right, and
you cannot see it, because pass 8's waterline covers his legs to the ankle.** The next
conversion inherits the fix and will show it.

### TWELVE FAULTS I CAN STILL SEE
1.  **The lower arm is invisible from the front and the side.** It merges into the torso, so
    "two mitts on one wheel at two points" - the pose the whole conversion was built around -
    reads as ONE hand on the wheel in two views out of three. It is the fault I would take next.
2.  **The man is a stack of spheres from the back** - torso, pelvis, two shoulders and a head,
    five round masses with one dark belt across them. A snowman with a belt.
3.  **The hood's peak is a party hat** from the front and a cat's ear from the side. It is the
    one member that did not survive the chibi weight.
4.  **The eyes read as goggles** - two pale dots on a dark brow band.
5.  **The gate board, which is what a sluice IS, only reads from the BACK.** The wheel and the
    screw stand in front of it from the other two azimuths. It sits on the wheel's far side by
    construction and I did not move it.
6.  **The water has no ripple and no second lapping line**, so it is one flat pale shape. On
    black it reads as a flood; the structure that would make it read as moving water is not
    there, and pass 8's arithmetic forbids fixing it by raising the surface.
7.  **At 0.15 m it is a shallow sheet, not a rising level.** True to the feed line - "the water
    is coming up" - but it is less of a mechanic than pass 4's 0.30 m version was.
8.  **2623 faces - now the heaviest set piece in the file**, past the Cook's 2539. The water's
    skirt is 40 quads of that.
9.  **The near frame post crosses the wheel's rim** in the front view.
10. **Pair span 5.36 m against a 5.60 m frame.** This is the widest converted creature and it
    has 0.24 m of headroom left; anything added on the man's side breaks the sheet.
11. **The arms run about 0.78 m on a 2.10 m man** - long for this register. Named in pass 7
    and kept, because shorter put his body through the rim.
12. **Ratio 1.02 is the creature, not the man.** The figure inside is about 2.03 m of the 2.50,
    so a viewer's hero still looks the operator in the eye. Recommended `h` is **3.20 m** -
    that is `bestiary.gd`'s number, not mine.

### WIRING THE GAME BUILD LANE MUST DO (I touched no `.gd`)
`scripts/bestiary.gd` - if `sluicekeeper_chibi` is adopted in place of `sluicekeeper`, point
the Sluicekeeper's `model` at `assets/monsters/minibosses/sluicekeeper_chibi.glb`, **no `anims`
entry** (it is static), and set `h` to **3.20**.

### THE REGISTER AFTER THIS RUN
**9 converted + 2 measured-and-skipped, and THREE REMAIN, named so the count stops being
re-derived: the BOILER, the SOWER and the SNARER.** *(As of that run. The SOWER was converted
the run after - see conversion 10 of 14 at the end of this file.)*

---

## REGISTER CONVERSION 10 OF 14 - THE SOWER (`sower_chibi`)

Sheet: `renders/art/minibosses/sower_register.png` (original | chibi, a real posed 2.45 m
KayKit Knight beside each), plus `renders/art/minibosses/sower_chibi/hero_front|side|back.png`
and the standalone `front|side|three_quarter.png`. **Ratio 0.98 · pair span 5.16 m against a
5.60 m frame · fits the fixed frame · blank check 2 files, 0 failures · BLENDER_EEVEE ·
`sower_chibi.glb` 4 meshes, 1994 faces, static, no armature · CORRIDOR-SAFE, footprint span
3.29 m (3.97 m at the recommended `h` of 2.90).**

### WHAT THE ORIGINAL ACTUALLY READS AS
A seven-head pipe-cleaner man in a wide cone hat, carrying a crate, with three pale sticks
behind him. Beside a chibi Knight he is from another game. THE IDEA DOES NOT CHANGE: hopper on
the chest, one arm thrown wide with seed in the air, thorn already standing up out of the floor.

### THE VALUE PLAN, MEASURED FIRST - AND THIS IS THE WEAKEST PAIR IN THE FILE
At tint (0.72, 0.68, 0.44) and wear 0.40 the generator's `body` lands at luminance **0.498**
and its `bone` at **0.549**: a **10% separation**, against the Sluicekeeper's 14% and the
Cook's 19%, and the weakest in the fourteen. So bone-against-body carries NOTHING here. The
pairs that are strong are `dark` (0.092) against either, and `glow` against all three. Hence:
the man is `body`; every break on him is `dark`; the hat is `bone` and only ever reads against
the black above his shoulders, with a `dark` band at the join doing the work where hat and head
touch; the stems are `dark`; and **the seed is the only `glow` on the creature - in the
hopper's mouth, in the air out of his hand, and again as the thorn standing out of the floor.
One lit material told three times IS the mechanic: what he throws is what comes up.**

### THE NEW IDEA IN THIS CONVERSION
**The cast and the thorn are on opposite sides of him**, so the creature carries its own BEFORE
AND AFTER in one silhouette - seed leaving his hand on one side, thorn already up on the other.
A viewer who sees it once knows what the fight is going to do to the floor.

### THE CARRIED LEG FAULT - AND THIS IS THE CREATURE IT SHOWS ON
The Sexton's fault 9, the Porter's 12, the Tallyman's 10 and the Cook's 6 - "the legs read as
two dark blocks" - was fixed in the Sluicekeeper's file and INVISIBLE there, because pass 8's
waterline covered his legs to the ankle. **Nothing covers these legs.** Shins are `body`, only
the boot is `dark`, and the break at the ankle is visible in front, side and back alike. The
fix is now proven, not just committed.

### FIVE PASSES, ONE CHANGE AND ONE RENDER EACH
1. **The register itself**: chibi mass and count off the measured Knight - 0.150 m shins on a
   0.50 m hip, a barrel torso over a pelvis that bridges it, a 0.30 m skull, mitts. **And the
   hat is NOT a cone.** "The second wide cone in the file after the Snuffer's" was the
   original's third named fault, and a cone is a cone from every azimuth, so posture cannot
   separate two of them. This is a **flat brim with a low crown**: at 6 degrees of elevation a
   flat disc is a LINE, so the Snuffer reads as a triangle on a stalk and the Sower as a
   horizontal bar on a head. Nothing round sits on something round - the crown is narrower than
   the skull (0.255 against 0.300) and set into it, with the dark band at the join.
2. **THE SIDE VIEW HAD NO MECHANIC IN IT, AND IT IS THE COOK'S FAULT AGAIN: AN X-ONLY
   DIRECTION IS DEPTH, NOT SEPARATION.** Pass 1 threw the arm and the seed along -X and set
   the thorns out along ±X, so at azimuth 90 the camera looked straight down the line of the
   cast: the arm foreshortened into a lump on his chest, the four seeds stacked into two dots
   at his hip, and every thorn went edge-on - three bare poles with a ball on top, which is a
   candle, not a thorn. Every direction on this creature that was X-only is now **diagonal in
   plan**: the cast runs along -U at 37 degrees, the seed falls along it, the thorns stand out
   across it.
3. **THE THORNS WERE STILL FLECKS, AND ALTERNATING THEM ALONG ONE AXIS IS THE SAME MISTAKE ONE
   STEP SMALLER.** Pass 2 moved them off X onto V, which made them visible from the side
   INSTEAD of from the front, not from both - two directions is still a plane. **THE RULE,
   GENERAL: a feature repeated along a member goes ON A HELIX, not alternated on an axis** -
   then every azimuth sees some of it broadside by construction and none sees all of it
   edge-on. Four thorns a stem at 0.30 m, each 80 degrees around from the last.
4. **A DARK PROP ON A BLACK FIELD HAS NO SILHOUETTE, AND THE HOPPER IS THE PROP THAT NAMES
   THIS CREATURE.** `dark` is 0.092 and the cell background is 0.045: against his body the box
   was the boldest thing on him, and the moment it cleared his body - which is every view but
   the front - it was gone. One prop visible from one azimuth out of three is the front-only
   fault the Cook's lit mouth closed for the pot. **THE RULE: a dark mass needs a PALE EDGE
   where it stands against the room, not a different fill.** The hopper keeps its dark body and
   gains a `bone` rim round its mouth - which is also what a seed hopper has.
5. **THE THORN WAS GROWING THROUGH HIM.** Pass 3's bolder thorns reach 0.30 m instead of 0.21,
   and the nearest stem stood 0.95 m out on a man whose shoulder and casting arm already reach
   0.56, so from the front two thorns crossed his arm. All three shoots step 0.25 m further out
   along the line he walks - the same distance each, so the fan keeps its shape and only the
   gap changes.

### ELEVEN FAULTS I CAN STILL SEE
1.  **The hopper's bone rim and its lit mouth fuse into one pale shape** from three-quarter.
    Two pale things 0.04 m apart at cell size is one pale thing; the rim fixed the silhouette
    and cost the mouth its separate read.
2.  **The hopper still reads as a crate held across the belly**, not slung. The strap is `dark`
    on a `dark` box and does nothing; from the front the near hand that steadies it is behind
    the box entirely, so nothing explains how it hangs.
3.  **The cast arm foreshortens to a stub in the side view.** Pass 2 saved the SEED from that
    view, not the arm: the arm still runs mostly along the line the side camera looks down, and
    what tells the story at azimuth 90 is the four lit spheres, not the throw.
4.  **The back is a stack of spheres** - torso, pelvis, two shoulders and a head, with one dark
    belt across them. The Sluicekeeper's fault 2, unpaid again.
5.  **The belt reads as a flat plank through him**, protruding past the pelvis on both sides at
    three-quarter. It is the file's standard 0.80 x 0.66 belt box on a 0.69 m pelvis.
6.  **The thorns read as pale blades or leaves, not thorn.** They are broad cones (0.075 base
    on 0.30 of length) and lit, so they read closer to a palm frond than to something that
    would stop you walking.
7.  **The third shoot hides behind the first** from the front and from the back; only two of
    the three read in those views. The fan is 21/41/73 degrees in plan, which is spread enough
    for the side and not for the other two.
8.  **The two near shoots read as one bush** in the three-quarter view, which is the contact
    sheet's own view.
9.  **At wear 0.40 nothing on him looks worn.** The hat is clean straw and the hopper is a
    clean box; the number says "a farm tool used hard and kept" and the model does not say it.
10. **His mitt does not read as an open casting hand** - it is a ball on the end of a tube, so
    the cast is told entirely by the seed leaving it.
11. **1994 faces**, third heaviest in the file behind the Sluicekeeper's 2623 and the Cook's
    2539. The four thorns a stem bought that.

### WIRING THE GAME BUILD LANE MUST DO (I touched no `.gd`)
`scripts/bestiary.gd` - if `sower_chibi` is adopted in place of `sower`, point the Sower's
`model` at `assets/monsters/minibosses/sower_chibi.glb`, **no `anims` entry** (static, no
armature), and set `h` to **2.90**. Footprint at that `h` is 3.97 m against an 11.0 m
three-cell corridor: **CORRIDOR-SAFE, not room-locked.**

### THE REGISTER AFTER THIS RUN
**10 converted + 2 measured-and-skipped, and TWO REMAIN: the BOILER and the SNARER.**

---

## REGISTER CONVERSION 11 OF 14 - THE BOILER (`boiler_chibi`)

**Ratio 1.00 of a 2.45 m hero** - pair span **5.52 m** inside the 5.60 m fixed frame -
footprint **3.65 m, CORRIDOR-SAFE** (4.18 m at the recommended `h` 2.80, against an
11.0 m three-cell corridor) - **4 meshes / 1940 faces**, static, no armature -
**blank check 0 failures** - BLENDER_EEVEE. Sheet: `renders/art/minibosses/boiler_register.png`
(original beside conversion, one ortho scale, one ground line).

### WHAT THE ORIGINAL ACTUALLY READS AS - looked at first, before anything was changed
`renders/art/minibosses/boiler/hero_front|side|back.png`:

* **FRONT** - a wooden puppet standing beside **a parasol table**. A wide flat disc on two
  0.070 posts at head height is a garden table from every azimuth, and the pale apron is a
  sandwich board - the Cook's fault 3, still unpaid in this file.
* **SIDE** - **THE MAN IS GONE.** Pan at x +1.06, man at x -0.44, the whole creature strung
  along X: at azimuth 90 the camera looks straight down the line of the pair and the dish
  eclipses him. What is left is a mushroom with sticks behind it.
* **BACK** - **every member is the same tan.** `body`, `bone` and the pan all land in one
  value, so the back view is a pale mannequin with no break anywhere but the boots.

The one thing that works in all three is **the pour and the pool**. That line from a held
thing down to the ground is the only one in the fourteen, and the conversion keeps it and
throws away what hides it.

### THE VALUE PLAN, MEASURED FIRST
At tint (0.86, 0.60, 0.34) and wear 0.25: `body` **0.508**, `bone` **0.577**, `dark` **0.093**.
Bone against body is a **13.5%** pair - the Sluicekeeper's, not the Sower's 10%. Enough to
carry ONE pale object and no more. So: the man is `body`, every break on him is `dark`; the
**sleeve guards** are the one pale thing on him and they sit exactly where the mechanic is;
the cradle and the pan body are `dark` with a `bone` **rim** (a dark mass on a black field
needs a pale EDGE, not a different fill - the Sower's hopper, paid forward); and **the glow
is the sugar and nothing else** - lit in the pan, lit in the fall, lit in the pool. One
material, one continuous line, three places.

### TWO REGISTER DECISIONS, BOTH DROPS
1. **THE APRON IS DROPPED.** `cook_chibi` is two cells away wearing one, and a flat pale
   panel on the front plane is the sandwich board. The pale moves to **heavy sleeve guards**
   elbow to wrist - which is what a man who pours boiling sugar actually wears, clears the
   Cook by construction, and puts the only pale on the man onto the two hands doing the work.
2. **THE SKIMMER IS DROPPED FROM HIS SHOULDER AND STOOD IN THE POOL.** A 0.038 haft with a
   0.27 disc 2.0 m up in clear air is the Cook's lollipop (fault 6). Moved, it stops being a
   bubble wand and becomes the creature's own evidence: **a scraper set fast in the floor it
   poured.** Same prop, one new site, two faults closed and the mechanic told twice.

### THE ONE NEW IDEA: THE POOL IS SETTING FROM THE OUTSIDE IN
The original poured into a clean lit puddle with a hairline rim, which says POURS and does
not say AND IT SETS. Here the centre is still `glow`, the whole edge is a heavy `bone` crust
with three broken plates riding it, and the scraper stands seized in it. **Liquid at the lip,
set on the floor** - the Sower's before-and-after in one silhouette, applied to a floor
instead of to a man's two sides.

### SIX PASSES, AND WHAT EACH ONE BOUGHT
1. **Pass 2 - THE LIT MOUTH WAS INVISIBLE FROM ALL THREE VIEWS, and both causes were mine.**
   (a) **The glow was sunk inside its own rim**: an 0.080 `bone` wall at radius 0.47 over an
   0.34 lit disc set 0.028 below its top is **a cup with a lid on** at 6 degrees of elevation
   - the exact thing the Cook's lit mouth was supposed to have closed for good. Rim down to
   0.055, disc out to 0.42 and level with its top. (b) **The pan was barely rolled** - 37
   degrees off flat puts the mouth's normal 53 degrees above the horizon and a camera at 6
   sees a third of its width.
2. **Pass 2 - the pour was a sheet, not a rope.** 0.150 of radius on a 1.0 m fall is 30% of
   the drop in width, and under flat light a ribbon that wide shows one face and reads as a
   sail. Narrowed, and bowed 0.09 across the plan so it is a curve in two directions.
3. **Pass 3 - the lit disc had a dark hole punched through its middle.** The pan body is
   0.235 deep along its own normal and pass 2 floated the glow at 0.186 - **inside it** - so
   the dark pole came up through the sugar and the mouth read as a washer. **A cover must
   clear the covered solid's own pole, measured, not guessed.**
4. **Pass 3 - pass 2's hard roll made the mouth face the room, and the room is where BOTH
   cameras are.** A circle 53 degrees over was a full circle at azimuth 0 AND at 90: the
   Snuffer's cone fault in a new form, a shape that cannot be told apart from itself. 45
   degrees keeps 71% of the width in both and reads as a pan tipping in neither.
5. **Pass 4 - A 13.5% PAIR CANNOT EDGE ITSELF.** Three passes in, the `bone` sleeve guard -
   the only pale thing on the man - had never once read, because on a round member under flat
   light the file's weakest usable separation simply vanishes. It did not need a stronger
   fill, it needed a **BOUNDARY**: a `dark` cuff at the wrist, where dark against either is a
   5x pair. The guard is legible because of what is at its end, not what it is made of.
6. **Pass 5 - the pan ate the man at azimuth 38.** 0.93 m of lit face centred 0.98 out and
   1.27 up sat over his chest, both arms and the whole handle. The Cook's fault 5 and the
   original Boiler's own side view, one azimuth over. Pan 0.22 further out and 0.09 lower -
   CLEAR AIR, which also bought back the hands at azimuth 90.
7. **Pass 6 - THE DIAGONAL WAS AIMED AT THE ONE CAMERA I HAD NOT COUNTED, AND THIS IS THE
   RULE THE RUN IS FOR.** The Sower's rule says put the mechanic on a diagonal because an
   X-only direction is depth at azimuth 90. It does not say WHICH diagonal, and the one I
   picked by eye (51.5 degrees in plan) sat **thirteen degrees off the file's three-quarter
   camera at azimuth 38**. The hero sheet was clean at 0 and 90 and the contact sheet was the
   original Boiler all over again. **A plan diagonal is not "off-axis", it is a NUMBER, and
   the number to pick is the one that MAXIMISES THE MINIMUM ANGLE TO EVERY CAMERA THE PIECE
   WILL BE SHOT FROM.** For azimuths 0 / 38 / 90 / 180 that is **64 degrees**, and it takes
   the worst case from 13 degrees to 26 (0 is 64 off, 38 is 26 off, 90 is 26 off). Diagonal
   by eye is how a run clears two cameras and loses the third without ever being told.

### CARRIED FORWARD, AND ONE OF THE SOWER'S OWN FAULTS PAID
* **Shins `body`, boot `dark`** - the leg breaks in value at the ankle. Nothing covers these
  legs either (the apron is gone), and the break reads front, side and back.
* **The belt is a flattened ELLIPSOID, not the file's standard box.** The Sower's fault 5 was
  "the belt reads as a flat plank through him, protruding past the pelvis at three-quarter".
  A ring at the waist has no corner to show from any azimuth, and it does not.

### TWELVE FAULTS I CAN STILL SEE
1.  **At azimuth 90 the pan still covers his hands and the lever.** Pass 5 bought the arms
    back at 38 and only partly at 90: from the side he reads as a man standing BEHIND a pan,
    not holding one. The handle is the thing that explains the roll and it is invisible there.
2.  **The scraper crosses the pour in the three-quarter view** - the one azimuth where the
    two still overlap. Moved twice (off -E, then further along +D) and still not clear.
3.  **The scraper reads as a MALLET, not a scraper.** A 0.34 x 0.11 x 0.27 block on a 0.084
    post is a maul standing on its head; nothing says scraping edge.
4.  **The pan plus the cradle reads as a drum on a tripod** from the front. Two dark posts
    under a dark cylinder with a pale head is a drum kit, and the lit face does not undo it.
5.  **The lip is not visible AS a lip.** The sugar appears to leave the pan's face rather
    than run over an edge, because at 45 degrees the rim's low point is behind its own wall.
6.  **The lever is a stub.** From the front the dark bar between his hands and the pan is
    mostly hidden by the pan, so two arms reaching at a vessel is the only read.
7.  **The crust plates read as grey pebbles**, not as a skin that has broken. They are three
    low cones at one size and one tilt.
8.  **The back is a smooth featureless barrel** - no break between the shoulders, and both
    arms disappear round the front. The Sluicekeeper's fault 2 and the Sower's fault 4,
    unpaid a third time.
9.  **At wear 0.25 nothing on him looks scoured or new.** The number says a sugar man keeps
    his copper bright and the model says matte tan everywhere; the only object that could
    carry it is the pan rim and it carries it no differently from the man's own skin.
10. **His mitts do not read as gripping.** They are balls on the ends of tubes; the dark cuff
    behind each one is doing all the work.
11. **Pair span 5.52 m in a 5.60 m frame.** It passes, and it is the tightest cell in the
    file by a long way - 0.08 m of headroom. Pass 6's maximin aim stretched him along X.
12. **1940 faces**, fourth heaviest in the file behind the Sluicekeeper's 2623, the Cook's
    2539 and the Sower's 1994.

### WIRING THE GAME BUILD LANE MUST DO (I touched no `.gd`)
`scripts/bestiary.gd` - if `boiler_chibi` is adopted in place of `boiler`, point the Boiler's
`model` at `assets/monsters/minibosses/boiler_chibi.glb`, **no `anims` entry** (static, no
armature), and set `h` to **2.80**. Footprint at that `h` is 4.18 m against an 11.0 m
three-cell corridor: **CORRIDOR-SAFE, not room-locked.**

### THE REGISTER AFTER THIS RUN
**11 converted + 2 measured-and-skipped, and ONE REMAINS: the SNARER.**

## REGISTER CONVERSION 12 OF 14 - THE SNARER (`snarer_chibi`). THE LAST ONE.

**Ratio 1.00 of a 2.45 m hero** - pair span **4.51 m** inside the 5.60 m fixed frame -
footprint **3.73 m, CORRIDOR-SAFE** (4.26 m at the recommended `h` 2.80, against an
11.0 m three-cell corridor) - **4 meshes / 2523 faces**, static, no armature -
**blank check 42 files 0 failures** (gen) and **2 files 0 failures** (fit) - BLENDER_EEVEE.
Sheet: `renders/art/minibosses/snarer_register.png` (original beside conversion, one ortho
scale, one ground line). Per-view: `renders/art/minibosses/snarer_chibi/`.

### WHAT THE ORIGINAL ACTUALLY READS AS - looked at first, before anything was changed
* **FRONT** - a pipe-cleaner man under **three fishing rods**. 0.052 poles 2.0 m tall are
  rods, and a 0.20 ring hanging in clear air off a 0.013 cord is a croquet hoop. Nothing
  on the floor at all, on the one creature in the file whose whole idea is the floor.
* **SIDE** - **THE MECHANIC IS GONE, and it is the Sower's pass 2 exactly.** The three roots
  sit at x -1.34 / +1.12 / +1.62 with 0.66 m of total y between them, so at azimuth 90 the
  poles stack into a bundle of straws and **all three nooses go edge-on and vanish** - a
  ring is a PLANE, and a plane seen along itself is a line. What is left is a man in a tepee.
* **BACK** - the rings read and the man does not: every member, both poles and the floor
  props land in one value.
The one thing that works in all three is **the bent pole**, the only curve in the fourteen.

### THE VALUE PLAN, MEASURED FIRST
At tint (0.50, 0.42, 0.32) and wear 0.55 `body` lands at luminance **0.339** and `bone` at
**0.404**: a **19% separation, the widest pair in the file** (the Boiler's was 13.5%, the
Sower's 10%), with `dark` 5.1x below `body`. 19% carries a whole pale MASS, not just an
edge - so for once the pale thing is the STRUCTURE and the man is the hole in it:
* the **poles are `bone`** and they are the silhouette;
* the **man is `body`** with every break `dark` (boots, belt, cowl) and **no pale object at
  all** - he is the dark middle of a pale cage, which nothing else in the fourteen does;
* the **glow is the set line and nothing else**: the coil at his hip, the cord out of it,
  three nooses, three trip lines and three taut cords back up to the pole tips. One
  material, one continuous network, drawn across the whole footprint.

### THREE REGISTER DECISIONS, ALL DROPS, ALL SAID OUT LOUD
1. **THE NOOSES COME OUT OF THE AIR AND ARE SET OPEN ON THE GROUND.** A ring in the XZ plane
   is invisible at azimuth 90 and a ring on a string is the Cook's lollipop with a hole in
   it. A noose lying open on the run, staked, under a cord to a bent pole, is also **what a
   spring snare actually is** - the fix and the truth are the same move.
2. **THE LOOSE PEGS AND THE FLOOR COIL ARE DROPPED.** Crumbs at cell size that said nothing
   the snares do not. The peg becomes each snare's own trigger - one prop, three sites - and
   the coil moves to his hip, where it is the end of the lit network.
3. **NO HAT.** The file carries the Snuffer's cone, the Sower's brim, the Cook's cap and the
   Boiler's brow rag; a fifth crown is a repeat. He gets a **cowl pushed back**, so the mass
   is at the shoulders, where nothing else in the fourteen puts one.

### THE ONE NEW IDEA: THE ROOM IS DRAWN BEFORE THE FIGHT STARTS
The original said SNARES; it never said ALREADY SET. Three lit trip lines now run stake to
stake and close a triangle round him a hand's height off the floor, and **he is standing
inside it**. A viewer who sees it once knows where they are not allowed to walk, which is
the whole fight. A line at 0.12 m is a line from every azimuth; a figure painted on the
floor would be a smear at 6 degrees of elevation.

### THE LAYOUT IS SOLVED, NOT EYEBALLED, AND IT NAMED ITS OWN TEST BEFORE THE RUN
Sites at plan bearings **80 / 192 / 302** at radii 1.05 / 0.75 / 1.25, roots 0.55 further
out - the arrangement maximising the **minimum projected gap between any two sites and any
two roots over azimuths 0, 38, 90 and 180**. That minimum is **0.70 m**. The test, stated
in advance: *three separate snares must be countable in all four views, the side included.*
**Result: they are, but only by their cords - at azimuth 90 just two of the three pole arcs
clear the man.** Half a pass, honestly.

### SIX PASSES, AND WHAT EACH ONE BOUGHT
1. **Pass 2 - A SNARE ON A CAMERA'S DEPTH AXIS LANDS ON THE CREATURE, AND NO PLAN LAYOUT CAN
   AVOID IT.** At azimuth 38 bearing 308 is exactly 38 - 90, so the tallest pole's root AND
   tip projected to **x = 0.000** and a 0.105 pale pole ran vertically down through his head,
   his chest and between his feet. The layout had been solved snare-against-snare and never
   snare-against-MAN - and it **cannot** be solved for both: three snares ringed round a
   figure give 6 points x 4 cameras = 24 projected positions, and the best rotation of the
   whole 360 still leaves one of them 0.131 m off his centre line. **THE RULE: when a
   constraint cannot be met in plan, move the member OUT OF PLAN.** Rotate -6 degrees (0.000
   -> 0.131 m, and a rotation cannot touch the snare-against-snare gap), then **bow each pole
   0.30 m sideways at mid-height**, sign computed per pole to carry it away from the centre
   line at the acceptance camera. A loaded sapling bows sideways as well as over.
2. **Pass 2 - THE EMPTY HOOD WAS A SECOND HEAD.** A 0.30 dark ellipsoid behind the shoulder
   at 1.455, against a 0.300 skull at 1.74, is not read as cloth: front and back, it is a
   hump the size of his own head and the eye counts two. A pushed-back hood is a collar with
   nothing in it, so the collar is now the whole of it.
3. **Pass 3 - THE CORD WAS OUTSHOUTING THE THING IT IS TIED TO.** At 0.028 and emission 3.2
   the three cords stood up as blown-white **strip lights**, the boldest objects in every
   view, one of them straight down his chest - and a cord is the least interesting part of a
   snare. Halved to 0.015. The weight of the lit network belongs to the nooses and the lines.
4. **Pass 3 - FROM THE BACK HE WAS A STACK OF PLATES.** Pelvis, belt and cowl were three
   flat discs at 0.345, 0.445 and 0.395 across, each wider than deep, each at its own height.
   **THE RULE: widths up a figure must STEP, not alternate** - narrow, wide, narrow is read
   as objects stacked; narrowing all the way up is read as one body. The cowl is now
   narrower than his own shoulders and deeper.
5. **Pass 4 - HE WAS A SEGMENTED ABDOMEN, AND THE CAUSE IS ARITHMETIC.** A barrel's
   half-width falls to zero at its own bottom pole, so a barrel 0.395 tall centred at 0.97
   ENDS at 0.575 while the pelvis topped out at 0.695: the two met at a **pinch** with the
   belt sitting in it. **Two stacked ellipsoids read as one body only where the upper one
   reaches PAST the lower one's equator.** Barrel to 0.455 tall, dropped to 0.95. The belt
   became a band INSIDE the silhouette (0.352 against the barrel's own 0.372 at that height)
   instead of a 0.028-proud flange.
6. **Pass 4 - 0.30 of bow was a tangent, not a clearance.** It put the crossing pole's waist
   0.470 from the centre line against 0.45 of shoulder: 20 mm. 0.42 of bow puts it at 0.588.
7. **Pass 5 - PAYING A FAULT THE WHOLE FILE CARRIES.** The Boiler's own fault 10 is "his
   mitts do not read as gripping - balls on the ends of tubes", and every chibi here has the
   same ball. **A fist round a shaft is not a sphere, it is a short cylinder whose axis is
   the shaft's.** The hands are aimed along the beating pole, so every azimuth sees a band
   wrapped ACROSS the staff instead of a bead threaded ON it.
8. **Pass 6 - ON THE DARK CELL THE LIT NET WAS A WHITE SLAB.** Everything pale reads on a
   white fit sheet; the contact sheet is the dark one, and at emission 3.2 the rings at 0.036
   and the lines at 0.030 bloomed into one bright platform he was standing on - three nooses
   and three lines counted as one puddle. **THE RULE: a lit member's radius must be judged on
   the DARK field, because emission blooms outward and a pale field hides the bloom.** Ring
   0.027, line 0.021: the same drawing with a finer pen.

### CARRIED FORWARD, AND ONE FAULT PARTLY PAID
* **Shins `body`, boot `dark`** - the leg breaks in value at the ankle (Sower, Boiler).
* **The belt is a flattened ELLIPSOID, not the file's box** (the Sower's fault 5, paid on the
  Boiler and kept): a ring at the waist has no corner to show from any azimuth.
* **THE SPARE STAKES ON HIS BACK** - three short pale stakes under a dark strap. This is a
  first instalment on a fault the Sluicekeeper (2), the Sower (4) and the Boiler (8) all
  carry unpaid: *the back is a featureless barrel and both arms disappear round the front.*
  It also says he is not finished. It is an instalment, not a payment - see fault 6 below.

### TWELVE FAULTS I CAN STILL SEE
1.  **At azimuth 90 only two of the three pole arcs clear the man.** The third merges with
    his silhouette and the three snares are countable there only by their lit cords. This is
    the test I set in advance and it is half-failed, by construction, not by oversight.
2.  **The bowed pole clears his shoulders and not his shins.** The bow is zero at root and
    tip and maximal at mid-height, so at azimuth 38 the pole still crosses his lower legs.
3.  **The fist reads as a BLOCK.** A 10-sided cylinder on a staff is a prism - a collar with
    no thumb and no taper. Better than the ball it replaced and still not a hand.
4.  **The nooses are rings of even thickness.** A real noose has a running knot and a free
    tail; nothing here says the loop can close, which is the one thing it has to say.
5.  **Nine stakes read as black teeth** round the floor at cell size - a picket fence, not
    evidence of a man having staked ground.
6.  **The spare stakes read from the back and the side only** - two views out of four, for a
    prop costing four members. The arms still have no silhouette behind him.
7.  **The beating pole's striking end is a plain knob.** Nothing on it says beating; it could
    be a walking staff with a bad foot.
8.  **At wear 0.55 nothing reads half-worn.** The poles are fresh-cut and the man is clean.
    The number says woodsman's kit used hard and kept; the model says new.
9.  **The head is a bare ball** - two eyes and a collar, and no structure in between. It is
    the plainest head in the file, and plain is the voice, but this is close to blank.
10. **The trip-line triangle passes 0.49 m from his own centre**, so from every azimuth one
    lit line crosses his boots. He is inside his lines, which is the read, and it also means
    the net never has clear air round the figure.
11. **A trip line and a noose both sit at 0.10-0.155 m**, so where they meet, line, ring and
    stake fuse into one lit blob at the stake - three of those, one per corner.
12. **2523 faces, second heaviest in the file** behind the Sluicekeeper's 2623 - most of it
    in three 18-segment noose rings and nine stakes.

### WIRING THE GAME BUILD LANE MUST DO (I touched no `.gd`)
`scripts/bestiary.gd` - if `snarer_chibi` is adopted in place of `snarer`, point the
Snarer's `model` at `assets/monsters/minibosses/snarer_chibi.glb`, **no `anims` entry**
(static, no armature), and set `h` to **2.80**. Footprint at that `h` is 4.26 m against an
11.0 m three-cell corridor: **CORRIDOR-SAFE, not room-locked.**

### THE REGISTER AFTER THIS RUN
**12 converted + 2 measured-and-skipped = 14. THE REGISTER IS CLOSED.**
