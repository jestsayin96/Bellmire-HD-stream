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
