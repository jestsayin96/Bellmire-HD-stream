# THE SHEARMAN - "Cutloose", the 69th. IT READS AS A PAIR OF OPEN SHEARS AT
# HERO SCALE, AND ONE OBJECT ON IT STILL READS AS THE WRONG THING.

27 Nov 2026, 12:35-13:08 CT. **Three passes, and passes 1 and 2 are the
finding.** Passes 1 and 2 both carried a full green sheet and both failed the
only test that matters; pass 3 closed it. The body is WIREABLE with one named
standing fault - see WIRING at the bottom, and read THE STANDING FAULT first,
because it is an object that reads as a different creature's cue.

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `shearman` | Cutloose | 2.51 | workshop | **IT CUTS WHAT JOINS YOU** - it does not pick a hero and takes nothing off anybody. It cuts the lines BETWEEN them: no heal, no shield thrown over a neighbour, no covering a man who is down, no aura. Everyone is at full strength and completely alone | 0.30 | 1.50 |

## WHAT I CHECKED FIRST, BY MEASURING AND NOT BY REMEMBERING

- **The count.** Parsed every `BUILDERS = {` and `BUILDERS.update({` key in
  `tools/art/minibosses.py`, minus the five non-body names the same pattern
  catches (`budget`, `cap_used`, `prims`, `smallest_prim`, `tris`): **68
  bodies**. The mower is the 68th, so this is the 69th. The number is measured,
  not carried out of a prompt.
- **The mechanics.** Read the IDEA line off all 68 docstrings and sorted them
  by WHAT THEY CONDITION ON. Every one conditions on the party's relationship
  to IT - how many are on it, which struck it, what with, when, what they
  carry, who is down, the room, and since the mower WHERE THEY STAND. **None
  conditions on whether one hero's action reaches another hero.** That is the
  axis this body takes.
- **The duplicate check.** `grep -in 'shear|shearman|cutloose|sever'` across the
  generator and `docs/art/MINIBOSSES.md`: no shears body and no `shearman` key.
  The other two cloth-finishing trades ARE in the set - the FULLER (29th) and
  the DYER (23rd) - and their mechanics are unrelated to this one.
- **The theme.** Parsed CANON: 82 entries over 14 themes, `workshop` at 5 and
  tied thinnest with prison, shrine, keep, firepit, fogbound and confection.
  Cloth finishing is a workshop trade, so the thinnest-theme choice and the
  right-trade choice are the same choice.

## THE FIT PROOF - I LOOKED, AND THE PICTURE OVERRULES THE REGISTER

Gate numbers, all green: verdict **GREEN**, `ratio` **1.02** (2.51 m against a
hero measured at 2.45), `pair_w` 3.37, `air_x` 2.136, **3 proving views**,
`seen` **1.0** front/side/back, `fits_frame` **true**, `frame_edge` **0 on all
four sides of all three views**, blank check **0 failures over 207 files**,
`red_summary.shipped_red` **empty**, 811 faces, **4 meshes**, CORRIDOR-SAFE
(margin 9.50 m, span 1.50) and UNDER-LID (clear 6.99 m). glb written, `.glb.import`
pending a Godot run.

**THE GREEN SHEET WAS IDENTICAL AT PASS 1, PASS 2 AND PASS 3 AND TWO OF THOSE
THREE BODIES WERE WRONG.** Write that down and keep it: ratio 1.02, seen 1.0 on
three views, frame_edge zero, 0 blanks and 3 proving views were ALL true of a
body that read as two parallel poles (pass 1) and of a body that read as a
sword with an ornate guard (pass 2). **Nothing in this register can see what a
thing looks like.** The pictures decided all three times.

**AT PASS 3 IT READS.** `hero_front.png`, beside an actual KayKit adventurer at
the distance a viewer gets: a matched pair of pale blades opening off a dark
bow. It is a pair of open shears and it is not a sword. I looked, and that is
the whole of the evidence.

**THE CAUSE THAT CLOSED IT, NAMED BEFORE THE FIX AND CONFIRMED BY IT: ONE BLADE
WAS DRAWN AGAINST THE BACKGROUND AND THE OTHER AGAINST THE TORSO.** The outer
blade silhouetted; the inner fell inside the body's own outline and stopped
being a silhouette, so what survived shrinking was one pale diagonal over a
dark mass - a sword and a hilt. **IT WAS NEVER AN ANGLE PROBLEM, AND PASS 2
PROVED THAT BY FIXING THE ANGLE AND CHANGING NOTHING AT HERO SCALE:** 22
degrees of included angle went to 35 and the hero render was still a sword.
Pass 3 put the whole instrument ABOVE THE SHOULDER LINE, where the only body
at those heights is the head and cap (|x| <= 0.232) and the inner blade clears
them by 0.17. Both blades against air; the pair reads as a pair.

### THE STANDING FAULT - READ THIS ONE FIRST

**THE CORD IN THE JAWS READS AS A HOOK, AND A HOOK IS THE GAOLER'S CUE.** This
is now the worst thing on the body and it is worse than being invisible,
because it points at a different creature. Only one of the two cord pieces
survives the view (the other hides behind the near blade), it is drooped, and a
single bent tan rod hanging in an open jaw is a hook. The "cut, with a gap
between the halves" statement never lands in any view. **THE NEXT CHANGE, AND
IT IS ONE THING: straighten both cord pieces and set them across the jaw so the
GAP between them is what the eye lands on - or take the cord off the body
entirely.** The two pieces on the FLOOR already carry the same statement and
they read correctly, so removing the jaw cord costs less than it looks.

### THE REST OF THE FAULT LIST, HONEST

2. **THE RIGHT ARM IS A STRAIGHT BAR WITH A HARD ELBOW.** Stiff.
3. **THE EYES ARE TOO BRIGHT AND TOO BIG.** Two white dots on a body whose
   whole read is one pale shape. Much less damaging at pass 3 than at pass 2
   now that the blades are large and clear, but still the second-brightest
   thing on the figure.
4. **THE FIGURE IS GAUNT** beside the chunky KayKit hero - a thin slab torso
   and a small ball head - and the trunk/apron junction reads as a bib.
   Plainness is the voice, but plain is not the same as characterless.
5. **THE HIP BUNDLE IS A SILHOUETTE CUE AND NOT A VALUE CUE** - dark on a dark
   smock. Said plainly because the register cannot tell the two apart.
6. **THE BOW HELPS AT FULL FRAME AND IS AMBIGUOUS ALONE.** With both blades
   now reading it is the thing that closes the V; at pass 2, with one blade
   lost, the same object was the sword's guard. The same geometry read two
   different ways depending on what was around it, which is the pass-2 lesson
   in one object.

### WHAT PASSES, AND IT IS WORTH KEEPING

**THE BEADLE TEST PASSES.** Front and back are plainly different figures:
the front carries the face oval and the large MID apron mass; the back has no
face, no apron, a flat dark back and the cord bundle on the right hip. The
apron is a 0.42 x 0.74 value mass and not a 0.04 trinket, which is the lesson
the Beadle cost. The two cut pieces on the floor also read, in both views.

### THE THREE PASSES, AND THE LEFT ARM RODE ALONG WITH THE THIRD

- **PASS 1** - 1.30 m of blade at a 22 degree included angle, carried
  diagonally across the whole figure with the bow behind the right elbow.
  **Read as TWO NEAR-PARALLEL POLES OVER A MAN'S SHOULDER**, front and side
  both. The 0.42 rad roll bought to make the cord visible produced a rod
  through the man's face.
- **PASS 2** - blades to 0.95 m, jaw to 0.300 (35 degrees), instrument stood up
  at his right side, roll down to 0.20. **Real at full frame, still a sword at
  hero scale.** This is the pass that proved the angle was not the cause.
- **PASS 3** - the whole instrument above the shoulder line. **Closed it.**
  **THE LEFT ARM HAD TO COME WITH IT AND THAT IS A SECOND CHANGE, SAID PLAINLY
  RATHER THAN HIDDEN:** with the bow at shoulder height a left hand on it must
  reach up and across the man's own face, which is a worse fault than the one
  being fixed, so the left arm now hangs. It also killed pass 2's flat-plate
  arm - but that is a SIDE EFFECT OF A FORCED CHANGE and it is not evidence
  that the forced change was right.

### AN INSTRUMENT NOTE: A NUMBER AND A PICTURE DISAGREED AND THE PIPELINE WAS
### RIGHT BOTH TIMES

The report said `height_m` 2.51 while the render's top was plainly the cap at
about 2.08, and the raw geometry measures 2.116 m. That is not a fault:
`build_miniboss` **SCALES THE ASSEMBLED BODY TO CANON'S DECLARED HEIGHT**, so
the declared h is the authority and the geometry is scaled by 1.186 to reach
it. Confirmed by arithmetic: the x extent 1.367 x 1.186 = 1.62 against the
reported 1.60, and the depth 0.99 x 1.186 = 1.17 against 1.19. **Written down
because I spent a measurement chasing it** and the next run should not.

## WIRING - THE BODY IS READY; THE WIRING IS THE GAME BUILD'S AND CONTENT'S

- **`scripts/bestiary.gd`** - add `shearman` with a `model` path to
  `assets/monsters/minibosses/shearman.glb` and **NO `anims` entry**: it is
  **STATIC**, no armature, 4 meshes merged by material. I do not edit that file
  and have not.
- **`Delve.MB_NAME["shearman"]`** - the canon name is **"Cutloose"**, and per
  the S115/S121 sequencing the game build should **HOLD IT UNTIL CONTENT HAS
  WRITTEN `by_key.shearman`**, or it is a ghost.
- **Content** - `by_key.shearman` is the row that unblocks it. The feed line
  this body ships with is *"Something ahead is cutting the lines."* The
  subject, so the voice has something true to hold: this one does not hurt
  anybody directly. It makes it impossible for them to help each other.
- `assets/monsters/minibosses/shearman.glb` has no `.glb.import` sibling until
  a Godot run generates one. Same standing condition as `snarer_chibi.glb`.
- `assets/monsters/minibosses/shearman.glb` has no `.glb.import` sibling until
  a Godot run generates one. Same standing condition as `snarer_chibi.glb`.
