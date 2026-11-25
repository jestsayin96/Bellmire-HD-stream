# THE COLLIER (Halfblow) - the 62nd miniboss, and my own fix hid the count it was built to show

**Lane:** art. **Built:** 25 Nov 2026, 03:35-04:1x CT. **Branch:** `art`.
**Plan row:** the 02:58 CT 25 Nov TAKE THIS NEXT block - *"ART (:34) - THE 62nd
BODY, OR A WRITTEN STAND-DOWN THAT SAYS WHICH."*

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

| measured | where | value |
|---|---|---|
| `ORDER` | `minibosses.py`, initial literal + every `ORDER = ORDER + [...]`, parsed with `ast` | **61 entries, 61 distinct**, last `timberman` |
| `CANON` | every `CANON.update({...})`, parsed with `ast` | **75 rows** = 61 live + 14 retired `_chibi`/`_tall` |
| all 61 `idea` strings | read in full **before** designing | see NOT-THIS below |
| `collier` | grep of the whole key space | **absent** - this trade is not already made |
| bone/body luminance | the generator's own formulae, run on paper before a vertex was placed | **1.34** - answered in `OVERRIDE` |

So this is the **sixty-second base**. My own prompt says "THIRTY-THREE already
exist"; it is stale by twenty-nine and the measurement, not the argument,
corrects it.

**THE PACKS RULE WAS APPLIED AND IT DID NOT SERVE.** The body is one earth heap
and one short man. The packs hold rocks, logs, planks and barrels in quantity -
nothing in them is a *staked, earthed charcoal clamp*, and a pack rock dropped
in at full fidelity would have arrived with its own material budget against this
file's four. Procedural, per rule 4.

## THE IDEA, AND WHY IT IS NOT A RE-SKIN

**YOUR OWN HEAVY BLOW IS WHAT OPENS IT.** A charcoal burner's clamp is wood
earthed over and lit inside, and the whole trade is keeping it *shut*. Every
blow the party lands lands in full - nothing is absorbed, nothing is immune -
but a blow bigger than a measured stroke **bursts a vent and the flare takes the
whole room**. The party's heaviest hero is the liability and its lightest is the
asset, every round, for the whole fight. Second answer, on the body: four pale
plugs in a cradle, countable from the doorway. Drive them home and the cap comes
off.

**THE TWO NEAREST NEIGHBOURS ARE A SIBLING AND A MIRROR AND I AM NAMING BOTH
RATHER THAN HOPING NOBODY NOTICES.**

- **The TIMBERMAN (61st) shipped ONE HOUR before this.** Both bodies make the
  party's own damage a hazard, so this is the closest call in the file. The
  daylight: there the **killing** blow is the hazard - one event, once, at the
  end, countered by *preparation*. Here no single blow ends anything and the
  kill is ordinary; what is constrained is the **size** of every blow,
  continuously, countered by *who swings*. The timberman reorders the end of a
  fight; this reorders the attack economy from round one.
- **The DREDGER (57th) is the exact mirror.** It "only feels what gets through
  the mesh" - a damage FLOOR where a small blow does nothing. This is a
  CEILING, and no blow is ever nullified: full damage always lands and the cost
  is paid by the room. A dredger punishes your weak hero; this punishes your
  strong one.
- Also named off in the builder docstring: **strickler** (changes the hero, not
  the choice), **pledgeman** (a price, not a hazard), **stoker** (the fire is
  its strength, not its danger), **scrapwright** (the other mound - angular
  torn plate, on legs, and it grows), **panner** and **nightman** (state
  windows; this body is open to be hit at every instant).

## SIX PASSES, AND WHAT EACH ONE WAS FOR

Every pass rendered `ok true`, 0 blanks, 0 errors. **Every fault below was found
by looking at the picture.** Not one of them raised a number.

- **Pass 1** - built. The four vents - the *one* emissive cue, and the mechanic
  itself - rendered as **flat cream discs at the same value as the four pale
  plugs**. The body shipped eight pale dots and nothing lit: both halves of my
  own FAULT 9 and FAULT 10, in the first render, in the file where I had just
  written them down. And the whole thing read as **a hooped bell skirt with a
  man in it**.
- **Pass 2** - five separable fixes, judged one at a time in one render. Glow
  deepened and weakened (1.00,0.30,0.06 at 1.15) - **worked, the vents are
  fire**. Plug bundle narrowed from 0.62 m to 0.35 m - **worked**, it had been a
  four-bar fence laid across the whole mound on the side camera, because I
  answered the front camera's question and asked the side nothing. Haft
  overshoot 0.270 -> 0.105 - **worked**, it had run past his jaw. Left arm
  rebuilt on four points - **worked**. Sods and a crown shelf on the mound -
  **did not work**.
- **Pass 3** - the skirt. The cause was an interaction I built myself: **a body
  of revolution with three horizontal iron ribs round it is a crinoline** -
  that is what a crinoline is, and the hoops were the best-reading objects on
  the body selling the wrong word. Eight **vertical stakes** and one lashing
  ring instead of three rings; a **spoil tail** out to y +1.02, because a skirt
  has no tail; the man stepped 0.21 m forward off the apex. **The side camera
  was answered. The front camera was untouched** - every one of those changes
  lives in Y.
- **Pass 4** - the apex walks 0.26 m to +X so the front silhouette is a heap
  with a high side and a low shoulder. **The skirt is gone on both cameras.**
  Stakes pushed proud of the earth they had been sitting *inside*.
- **Pass 5** - **and pass 4 had hidden the count.** Walking the apex put the
  mound's new high shoulder directly in front of the plug bundle: one pale
  sliver where four countable billets belong. *A fix that moves a mass must be
  re-asked what that mass now covers.* I did not ask; the render did. Bundle
  crossed to the low shoulder, vent arc swung clear of the shovel (the fourth
  vent had been behind the blade, so the ember count read three), and the stake
  heads reseated - my own pass-4 drift had walked them off the earth into open
  air, a free end introduced while fixing something else.
- **Pass 6** - **found only on the hero sheet, which the orthos cannot show.**
  Beside a KayKit knight the head read as **a pot with a lid on it**. Head
  bigger, hat tapering up into a crown narrower than the skull with its brim on
  -Y only. Partly worked - see the fault list.

## THE NUMBERS, MEASURED ON THE SHIPPED BUILD

`minibossgen --only collier`: `ok true`, errors `[]`, blank `[]`, **4 meshes /
2,417 faces**, span **2.16 m CORRIDOR-SAFE** (corridor 11.0 m), **UNDER-LID**.
At **2.10 m** it is one of the shortest bodies in the house and the widest-to-
tallest of any of them.

`minibossfit --only collier`: **verdict GREEN, ok true, 64 rows, errors `[]`**,
`blind_views []`, `unproved_cells []`, `stale_margin []`, `red_summary.rows []`.
For this row: `creature_h` 2.10, `hero_h` 2.45, **ratio 0.86** (it is SHORTER
than a hero - the first body in some time that is), `pair_w` 3.90, `air_x`
1.659, `margin_x` 0.12, `fits_frame` true, **3 proving views**, `seen` 1.0 for
creature and hero on all three, **every `frame_edge` and `frame_edge_disk` zero
on front, side and back**, `air_px_min` **102**, tightest view `side`.

`_backread --keys collier` - the viewer's question, rendered with and without
the man through one camera, counting the pixels that MOVED: **man_seen front
0.9914, side 0.9745, back 0.9966** against the house bar of 0.75, errors `[]`.
The census was re-run FIRST (64 register rows, `pairs in NO list: 0`) and the
row is merged into `_selfseen_all.json` row-by-row with its own `measured_at`.

**THE FIT REPORT WENT RED TWICE BEFORE IT WENT GREEN AND BOTH WERE RIGHT.**
First *"in the register and in NO self_seen census list"*, then *"MEASURABLE and
carrying NO self_seen cell - an unasked instrument is RED, not green"*. Neither
was worked around. A third red was mine and earlier: `_backread` refused the
body for *"no `man` span and no `man_parts`"*, correctly, and the first
declaration I wrote put the **shovel** inside the man - which is the dyer's
fault exactly, counting the apparatus as the figure it is supposed to be hiding.
The right arm was split out into its own span and `man_parts` is
`("trunk", "head", "arms_r", "hand")`, with **no `legs`, because this body has
none**.

**`_selfseen_all.json` `ok` is false and it is NOT this body.** It was false
before this run on `panner: the man span merged to no object` - verified against
the file, not asserted. My merge added one row and changed nothing else.

## WHAT I CAN SEE THAT IS STILL WRONG

Looked at on the hero sheet at hero scale, front, side and back:

1. **The head still half-reads as a pot.** Pass 6 improved it and did not
   finish it: a round skull with no neck under a tapered dark crown is a jar at
   stream distance, and the face is gone by then. This is the first fault to
   take on a pass 7.
2. **The side camera is the weak view for the mechanic.** One ember shows at
   the mound's edge and the plug bundle goes nearly edge-on behind the front
   face. The count is a **front cue by construction** and the side carries the
   silhouette instead. **THIS WAS THE REAL FAULT AND IT IS NOW MEASURED AND
   PARTLY ANSWERED (PASS 7, 25 Nov 05:3x-06:0x CT):** the cue census put the
   side at **41 px** against a front of 3784, and three ember seams on the +X
   flank took it to **427**. It is no longer blind and it is still the thinnest
   cue in the ten-body sample. Full write-up, the two arms I rejected and the
   faults I can still see: `docs/art/CUE_READ.md`, PASS 7.
   **PASS 8 (25 Nov 06:4x CT) TOOK THE SECOND HALF OF IT - THE SEAMS NOW SIT
   UNDER AN EARTH BROW** and no longer read as orange crescents lying on the
   flank. The single change the 05:58 plan row named - the seam RADIUS - was
   swept over three arms and **FAILED**: side 427 -> 329 -> 254 -> 196,
   monotone down, and at 12x the seam is the same flat lozenge the whole way,
   only smaller. That guess was mine: written into `CUE_READ.md` at pass 7 by
   eye and quoted into the row from there. What answers it is geometry - a
   proud earth ridge above each seam, whose unlit underside puts dark over
   the light and whose edge cuts the glow's convex crown flat. Shipped at
   `COLLIER_BROWR` 0.044: side **413**, so the cue is HELD, not paid for; the
   front's two mid-height rim nicks **halved**, 144 px to 70; and the vent row
   still carries **four blobs and exactly four**, re-counted, not asserted.
   `COLLIER_BROW=0` renders byte-identical to the 7c body. It reads at
   inspection distance more than at stream distance, and the side is still
   the thinnest cue in the house. PASS 8 in `docs/art/CUE_READ.md`.
3. ~~**The back carries no cue at all**~~ - **STRUCK 25 Nov 05:4x CT, AND IT IS
   THE ONE FAULT IN THIS LIST I GOT WRONG BY EYE.** I wrote this before the cue
   census existed, reasoning from construction (the vents ARE all on the -Y
   arc) instead of from a render. Measured: **the back moves 2430 cue pixels**
   - the four pale plugs stand clear of the mound's upper profile from +Y and
   the count reads perfectly well from behind. The blind view was the **SIDE**,
   at 41 px, and fault 2 below had already half-seen it. This struck sentence
   was quoted into `minibossgen.py`'s switch comment and from there into the
   04:58 CT plan row, which duly told me to fix the back; three documents
   repeating one unmeasured sentence is how that happens. Fixed at PASS 7 -
   side 41 -> 427 - see `docs/art/CUE_READ.md`.
4. **Three of the four embers read cleanly on the front; the fourth is partly
   behind the mound's own left flank** depending on the camera's yaw. Pass 5
   moved it off the shovel and the flank took a piece of it back.
5. **The stakes read as a lattice of dark sticks at hero scale** rather than as
   driven withies - they do their job (they killed the crinoline) but they are
   the least articulated thing on the body.
6. **The shovel is thin at hero scale.** Its blade reads; its haft nearly
   disappears against the earth.
7. **The man's torso is a visible stack of three spheres** - a barrel-banding
   that shows on the front ortho at full size.

No clip, no float and no bad anchor that I can see: the plugs are seated with
`seat()`, the stake feet are in the earth, the spoil tail sits on the floor, the
shovel terminates in a socket and a blade, and the body carries its own ground
shadow on all three views with `shadow_edge` zero.

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT TOUCH ANY OF IT

- `scripts/bestiary.gd` - add a row for `collier` with
  `model: "res://assets/monsters/minibosses/collier.glb"` and **NO `anims`
  entry**: static, no armature. `h` 2.10 is the authored height and is what the
  0.86 ratio was measured at.
- `scripts/delve.gd` - `MB_FIT` ratio **0.86**, COPIED from
  `_fit_report.json` `pairs.collier.ratio`, not re-derived. `MB_NAME` entry
  **"Halfblow"**, which is CANON (`tools/art/minibosses.py`). Theme row:
  **`wood`**. And the five sibling `MB_NAME.size()` literals move together -
  `_s51_names.gd:64`, `_s117_straker.gd:33`, `_s124_pledgeman.gd:31` are plain
  `== N`; `_s107_gate.gd:39-43` binds a variable first and `_s126_crimp.gd:31`
  is a parenthesised conditional, so a flat regex finds three of five.
- It is **NOT room-locked**: span 2.16 m against an 11.0 m corridor,
  `UNDER-LID`, `fits_frame` true.
- Nothing else. I did not edit a `.gd` file and I did not tick a plan row.

## PASS 9 - I LOOKED AT IT AT STREAM SCALE AND THE COUNT IS NOT FOUR

25 Nov 2026, 07:3x-08:0x CT. The 06:58 plan row gave this lane one job: the
pass-8 note said the brow "reads at inspection distance more than at stream
distance", so render the three hero views DOWN to the size the cue has to
survive on stream and LOOK at them.

### WHERE THE RUNGS COME FROM - MEASURED OFF THE REPO, NOT PICKED

`scripts/spotlight.gd:22` - "Each pane is a SubViewport at HALF resolution".
`scripts/spotlight.gd:11` - "the 2x2 grid is the stream's RESTING state, up
24/7". So a pane owns half the stream's width on screen and is RENDERED into a
quarter of it. Across Twitch's transcode tiers the 760 px hero frame lands at:

| tier | pane renders at | creature is |
|---|---|---|
| source 1080p | 480 px | 167 x 186 |
| 720p | 320 px | 112 x 124 |
| 480p | 213 px |  74 x  82 |
| 360p | 160 px |  56 x  62 |

No `MIN_CUE_PX` was invented and none is wanted - the 05:58 ruling stands. The
only reading that means anything on its own is ZERO. Everything below is a
picture I looked at; the numbers beside it are the suspect, not the evidence.

### WHAT THE THREE VIEWS DO AT STREAM SCALE

**THE SIDE IS CLOSED AND MY OWN PASS-8 WORRY WAS WRONG.** Two orange crescents
read as light coming out from under an earth lip at EVERY rung down to 160 px,
where they are still 14 px and 11 px and still read as two bright slits in a
dark mound. The brow works. Measured against a cue-off arm the side holds 3
marks at every rung, 1080p through 360p, losing none. The side is now the
STRONGEST survivor of the three views, not the thinnest, and the pass-8 note
that called it thin was written at inspection distance and is struck.

**THE BACK CARRIES NO CUE AT STREAM SCALE,** and this is honest rather than new:
two warm specks on the far silhouette edge, the limb of the vent ring seen
edge-on, 6 px and 2 px at 360p. From behind this is a mound of earth with a man
on it, which is what `_cueread.py`'s own docstring says the body was built to
be caught at. The brow is a front-and-side ridge and did not change the back.

**THE FRONT'S GLOW SURVIVES AND ITS COUNT DOES NOT, AND THAT IS THE FINDING.**

### THE REGISTER COUNTED FOUR, I COUNTED FOUR BY EYE, AND BOTH WERE WRONG

The 06:58 tick records "four vents and four only, re-counted" off
`hero_front.png`. I counted four there too. We were both looking at a 760 px
render of a whole-body picture, and a whole-body picture reads four when the
body carries three and a sliver.

The committed `collier_cueB` predated the pass-8 brow by two hours, so it could
not isolate the glow on the shipped body. Re-rendered fresh (`MB_CUEOFF=glow`),
labelled the connected marks of the A/B, and printed their centroids:

| | cx 409 | cx 439 | cx 492 | cx 551 |
|---|---|---|---|---|
| front band, px | **38** | 460 | 449 | 135 |
| bearing | -78 | -42 | -10 | +24 |

**A viewer at stream scale counts THREE.** The command text says "drive its
FOUR pale plugs into the vents", so the number the viewer is told and the
number on the body disagree - and FAULT 10 already says the count IS the
mechanic. This is not a brightness fault and no wear or emissive change
addresses it.

#### THREE NUMBERS IN THE PARAGRAPH ABOVE WERE WRONG AND PASS 10 CORRECTED THEM

The team lead checked this write-up against its own evidence at 07:58 instead
of reading it, and found three. All three are corrected in place above and
recorded here rather than quietly overwritten.

**(a) The fourth band is 135 px, not 152, and its centroid is cx 551, not 557.**
152/557 is from a render that is not the shipped one and is not in the tree;
the committed `collier_stream/_vent_marks.json` says 135 at cx 551.5, and
pass 10's labelled re-measure through its own locked camera says 139. The
table now carries the committed figure.

**(b) The outermost vent is FIVE pixels at the 360p rung, not ONE, and the two
1 px marks are NOT vents - they are the ember seams on the +X flank.** The
360p front row is `[25, 25, 8, 5, 3, 1, 1]` and pass 9 read it as a
size-ordered list when the geometry is ordered by x. Ordered by centroid:
`85.6 -> 5 px (-78)`, `92.0 -> 25 px (-42)`, `103.0 -> 25 px (-10)`,
`115.5 -> 8 px (+24)`, `118.7 -> 3 px (a FRAGMENT of +24)`, `131.0 -> 1 px`
and `131.0 -> 1 px` (the two upper seams, 13-16 px right of the vent row at
this rung and well above it). Pass 10 proved that labelling by construction
rather than by centroid inference - see THE LABELLED ARMS below.

**THE FINDING STANDS, AND THE CORRECTED NUMBERS SHARPEN IT RATHER THAN
SOFTENING IT.** The outermost vent is a FIFTH of its neighbours at the rung
that matters, not a sixteenth-of-a-pixel, and the reason a viewer counts three
is not that it vanished. It is that at 5 px it sits **6.4 px** from the 25 px
blob of the -42 vent and reads as that blob's fuzzy edge; and the +24 vent is
not one mark either but **8 px + 3 px**, split by an occluder. So the right end
of the row is as unreliable as the left, which pass 9 did not say.

**(c) The directory that backs the md5 claim is `collier_revA`, not
`collier_p7cA`.** The team lead md5'd every collier render directory on main
and reported that `p7cA` equals `cueA` and that nothing committed in the pass-9
hour does. Re-measured here on the worktree, the first half is also wrong:

| directory | hero_front | hero_side | hero_back |
|---|---|---|---|
| `collier_cueA` | da709319 | 729884f5 | 39527b79 |
| `collier_revA` | **da709319** | **729884f5** | **39527b79** |
| `collier_p7cA` | af73ed1b | b4e2f426 | 1fccdbd6 |
| `collier_p9A` | f591bde9 | a4a09224 | e94871e7 |
| `collier_p9B` | 2777eb04 | fb789d30 | 1bc590a8 |

`collier_revA` is byte-identical to `collier_cueA` on all three views, so the
claim is TRUE and `revA` is the artefact behind it. `p7cA` differs on all
three. **WHAT IS STILL OPEN:** this run could not reach the main repo to ask
whether `revA` is committed (see THE MOUNT FAULT at the foot of this file), so
if the team lead's "nothing you committed equals it" is right, the fault is
that `revA` is on disk and not in a commit - which is the exact failure the
lane prompt warns about. Pass 10 commits it.

### THE OBVIOUS CAUSE, AND THE RENDER THAT DISPROVED MY FIX

-78 degrees is 12 off edge-on: it presents cos(78) = 0.21 of its mouth to the
front camera, on the same flank as the plug bundle, which takes most of what is
left. Pass 7's own note already forbids this - "a vent at +80 is edge-on to the
front camera" - and the body has been breaking that rule on the NEGATIVE side
since pass 5 swung the arc to clear the shovel. The docstring still claims
"-72..+72"; the shipped bearings are -78..+24, neither symmetric nor inside the
spread it documents. The reason the arc was stretched that far - to give the
SIDE camera an outermost vent in profile - is SPENT, because pass 7 built the
flank seams for that job and pass 8 made them read.

So I pulled the arc in to -48/-22/+4/+30 and rendered it through the same
camera. **IT GOT WORSE AND IT IS NOT SHIPPING.**

| | | | | |
|---|---|---|---|---|
| pass 8 | cx 409 / 38 px | cx 439 / 460 | cx 492 / 449 | cx 557 / 152 |
| pass 9 | *gone* | cx 431 / 452 | cx 470 / 367 | cx 569 / 109 |

The vent at +4 - the one pointing MOST DIRECTLY at the camera - vanished
entirely. Zero pixels is worse than 38. A wider face is no use behind a post.
The shipped bearings are back at pass 8's and the render is byte-for-byte
identical to `collier_cueA` on all three views (md5, checked - the artefact is
`collier_revA`, see (c) above); `COLLIER_VENTARC=9` renders the disproved arc
so nobody has to re-derive the disproof.

**(d) AND THE POST IS NOT A STAKE. THIS IS A FOURTH CORRECTION AND IT IS TO MY
OWN SENTENCE, FOUND BY CHECKING IT.** Pass 9 wrote "dead centre-front is where
the mound's centre stake runs" and that is geometrically impossible on this
body: the eight stakes are at `22.5 + 45i`, so the two nearest centre-front are
at -22.5 and +22.5 and **there is no stake at 0 at all**. The occluder is a
SOD. The seven sods are thrown at `(-148, -96, -40, 8, 62, 124, 168)` and the
one at **bearing 8** sits at z 0.300 with r 0.190, on a flank radius of
`0.868 - 0.440 * (0.300/0.980) = 0.733`, so it reaches out to r 0.908 where the
vent mouth only reaches 0.801, and it covers bearings **-6.5 to +22.5** over
z **0.190 to 0.410**. The pass-9 vent at +4 was inside that span on both axes.
A guess that names the wrong object still reads like a cause, and the next pass
would have moved a stake that was never in the way.

## PASS 10 - THE OCCLUDERS ARE NAMED, THE ROW HEIGHT IS DERIVED, AND IT IS
## STAGED BEHIND A FLAG BECAUSE IT WAS NEVER RENDERED

**THE BLENDER BRIDGE WENT DOWN MID-RUN AND THAT IS WHY THIS IS NOT TICKED.**
25 Nov, from about 09:02 CT, `execute_blender_code` returned *"Cannot connect
to Blender at localhost:9876"* - Mr. E's Blender was not running, and that
bridge is the only way this lane renders, runs Godot, or commits. So pass 10
delivers the measurement and STAGES the geometry: `COLLIER_VENTZ=10` turns the
new row on, **unset is pass 8 byte for byte**. A piece that has never been
rendered on a body is not done, and a raycast is not a render.

### THE TWO OCCLUDERS, NAMED BY A RAYCAST INSTEAD OF BY EYE

`tools/art/_collier_occlude.py` builds the body, **removes the vent span from
the BVH** so no mouth occludes itself, and casts the front camera's own ray at
the face centroids of the real mouth solid, attributing every stopped ray back
to the span that owns the polygon. The answer at the shipped row:

| vent | bearing | row z | visible share | stopped by |
|---|---|---|---|---|
| outer left | -78 | 0.250 | **0.00** | `plugs` 11/13, `clamp` 2/13 |
| inner left | -42 | 0.298 | 0.74 | nothing |
| inner right | -10 | 0.298 | 0.91 | `clamp` 1/13 |
| outer right | +24 | 0.250 | **0.00** | `clamp` 13/13 |

The two reading zero are exactly the two the renders show as a 41 px sliver and
a mark **split in two**. The left one is behind the PLUG BUNDLE, which occludes
bearings -88 to -74 at this height. The right one is behind the **stake at
+22.5**, 1.5 degrees off its own bearing - a tube of radius ~0.037 across a
mouth of radius 0.088, which is why that vent is not dim but CUT IN HALF.

### THE STAGGER WAS RUNNING BACKWARDS, AND THAT IS THE FINDING

Visible share by bearing and row height, every row MEASURED, no interpolation:

| bearing | z=0.250 | z=0.298 | z=0.360 |
|---|---|---|---|
| -78 | 0.00 | 0.03 | **0.06** |
| -42 | 0.74 | 0.74 | **0.74** |
| -10 | 0.76 | 0.91 | **0.98** |
| +24 | 0.00 | 0.07 | **0.42** |

Pass 8 ships `0.250 + 0.048 * (i in (1,2))`: the INNER two sit at 0.298 and the
OUTER two at 0.250. The outer two are the most oblique to the front camera and
the most occluded, and **the stagger handed them the worse height** - it was
helping the two vents that needed no help. The row under test is therefore FLAT
at 0.360, the best height measured for all four, which costs none of them
anything and stays below the lashing ring at z 0.430-0.474 (pass 4's FIX J).
The mechanism is the flank's own taper: course 1 runs r 0.838 -> 0.730 and
course 2 0.742 -> 0.600, so a mouth whose outer face reaches r 0.801 is BURIED
at the bottom of the row and stands proud higher up.

**NOT THE BEARING.** Pass 5 pushed a vent to -78 and pass 9 pushed one to +4
and lost it entirely. The arc is disproved twice and is frozen.

### WHAT I FOUND BY LOOKING, THAT NO NUMBER IN THIS PASS ASKED FOR

I cropped the vent row out of `collier_vlabel/full_front.png` at 4x and looked
at it. Three things are visible that the probe cannot report:

1. **The occluders are confirmed by eye.** The -78 vent is a fingernail of
   orange emerging from behind the pale plug bundle at the left edge. The +24
   vent is visibly CUT IN TWO by a dark stake running straight down through
   it. These are not inferences any more.
2. **The sod at bearing 8 is plainly there** - a smooth grey-brown dome
   sitting proud on the flank between the -10 and +24 vents, exactly where
   pass 9 put its +4 vent and lost it. Correction (d) is confirmed by the
   picture as well as by the arithmetic.
3. **AND THE RISK THE ROW-HEIGHT FIX CARRIES, WHICH I WOULD NOT HAVE SEEN IN
   THE PROBE.** The lashing ring is a solid dark horizontal bar directly above
   the vent row. The ring occupies z 0.430-0.474; a mouth centred at 0.360 has
   its top at **0.401**, leaving a gap of **0.029 m = 3.9 px** at 135.71 px/m,
   which is **0.8 px at the 360p rung**. At stream scale the vents would merge
   into the underside of the ring and read as notches under a bar rather than
   as four countable mouths - which could make the count WORSE while every
   occlusion number in the table above got BETTER.
   The probe cannot see this: it asks "is the ray stopped", and the ring stops
   nothing at 0.360. **This is why the row height is staged and not shipped.**
   At z 0.330 the gap is 0.059 m = 8.0 px = 1.7 px at 360p, still tight.

**SO THE NEXT RUN SHOULD NOT SIMPLY TURN THE FLAG ON AND MEASURE THE VENTS.**
It must look at the RING GAP in the same picture, and it should price the
other option the team lead named against it: **moving the one stake at +22.5**
heals the +24 split outright with no ring risk at all, and is a smaller change.
It does not help -78, which is the binding constraint on the count, and -78's
occluder is the PLUG BUNDLE - so the honest shortlist for pass 11 is
*(a)* the staged row height, judged on the ring gap as well as the vents,
*(b)* the +22.5 stake moved off the +24 bearing, and
*(c)* the plug bundle lifted or narrowed clear of the -78 sight line, keeping
it off +X where pass 5's FIX K deliberately put it.
One of those, rendered, looked at, and red-proved - not all three.

### THE LABELLED ARMS - SEVEN FRONT MARKS ARE NOT FOUR VENTS

`tools/art/_collier_ventlabel.py` renders three arms through ONE locked camera
and takes two differences, so every mark is labelled by construction:

* `full` - as it ships
* `glowoff` - `MB_CUEOFF=glow`, every glow swapped for body, no vertex moved
* `seamoff` - `COLLIER_SEAMOFF=1`, the three ember seams gone, vents untouched

`seamoff - glowoff` is the vents; `full - seamoff` is the seams. Result:

| | px | cx | cy | what it is |
|---|---|---|---|---|
| vent -78 | 41 | 282.8 | 351.2 | the sliver |
| vent -42 | 461 | 312.7 | 357.6 | |
| vent -10 | 452 | 366.3 | 359.8 | |
| vent +24 | 139 | 425.2 | 364.2 | split, main part |
| vent +24 | **17** | 438.8 | 363.5 | **split, second part** |
| seam mid | 35 | 498.6 | 290.5 | +X flank, above the row |
| seam top | 26 | 498.9 | 318.2 | +X flank, above the row |

**Every collier reading since pass 7 came off `MB_CUEOFF=glow`, which turns off
the vents AND the seams at once, and divided the seven front marks into "four
vents and three somethings" BY EYE.** That is how pass 8 ticked a count of
four. The seams are 13-16 px right of the row and well above it, so pass 7c's
goal - no fifth ember at the vent row's height - IS being met; but nothing in
the tree said so, and the mark-to-bearing mapping was an inference until now.
It is independently confirmed by arithmetic: at `CELL_X/FRAME_W` = 135.71 px/m
the four bearings' world-x gaps are 31.9 / 51.1 / 59.9 px and the four marks'
measured gaps are 29.9 / 53.4 / 59.1 px.

### WHAT MY OWN NEW INSTRUMENT GOT WRONG, BECAUSE IT IS THE SAME FAULT AGAIN

Rev 0 of `_collier_occlude.py` sampled a grid across the mouth's **outer face
disc** and reported `vis 0.000` for the +24 vent - which the committed render
shows as a 139 px mark, the fourth-biggest thing on the front. Both were right
about different things: the end disc at +24 IS buried, and the CONE'S FLANK
still stands out of the earth and is lit. Measuring one chosen surface of a cue
and calling it the cue is `head_glow_px: 156` beside "the head has no face at
all" - the 17 Nov pass-11 fault in a new coat, for the third time on this body.
Rev 1 samples the real mouth solid's camera-facing faces.
It now has a **validation arm that runs every time**: it reads the committed
`_vent_marks.json`, maps marks to bearings by the arithmetic above, and goes
RED if it cannot agree with the render on which vent is the smallest. It
agrees. It does NOT reproduce the full ranking - it swaps -42 and -10, which
render 460 and 449 px, a 2% gap - and that is recorded rather than hidden.
**A ray probe ranks; it does not predict pixels. Nothing here is a pass until
the 360p rung has been LOOKED at.**

### THE ONE-BODY FIT GATE WAS LYING, AND THE FIX IS RED-PROVED

`_fit_p9A.json` and `_fit_p9B.json` read RED with empty `blind_views`, empty
`fits_frame:false` and nothing unmeasured, for one reason: *"the census was
taken over 64 register rows and is being read against 1 - it describes a
different house."* A gate that cannot be green in a state the lane runs it in
routinely is a lying gate. The subset arm in `minibossfit.derive_self_seen`
answers it, and replayed against the real census
(`_backread/_selfseen_census.json`, register_pairs 64, 64 keys covered,
stamped 2026-11-25T04:02:20-0600):

| run | subset? | verdict |
|---|---|---|
| `{collier}` | True | NOT A VERDICT, green reachable |
| `{collier, beadle}` | True | NOT A VERDICT, green reachable |
| `{collier, notarealbody}` | False | **RED** |
| `{}` (empty) | False | **RED** |

So it can be green for a one-body run and it **kept its teeth**: a key the
census does not know is still RED, and a run over zero rows is still RED.
`_fit_p9A.json` carries `census_count_scope: null`, which is the fingerprint of
a file written before this arm existed - the two stale jsons are the fault the
team lead saw, not the live code. They need regenerating on the next bridge.

### THE NEXT SINGLE CHANGE IS NOT A BEARING

The front has three clear windows between the plug bundle on one flank and the
shovel blade at +51 on the other, and the centre stake splits what is left.
Pass 5 found that out and answered it by pushing the fourth vent to -78, which
is the fault measured above; pass 9 answered it by pushing a vent into the
stake. **Pass 10 should move the OCCLUDER or the ROW, not the arc** - shift the
centre stake, or drop the vent row below the lashing ring where the flank is
unobstructed. Whoever takes it: render the glow-only arm and LABEL THE MARKS.
The whole-body picture reads four when the body carries three and a sliver, and
that is exactly how this shipped past a green register and two careful readers.

Evidence, committed: `renders/art/minibosses/collier_stream/` - the rung
ladders, the per-view creature strips, and the labelled vent masks for pass 8
and pass 9 side by side.


## THE MOUNT FAULT, 25 Nov 09:xx CT

This firing's device bridge mounted **only `bellmire-art`**, not
`C:\hd adventure`, so the main repo was not reachable on the Linux side and
`git` in the worktree fails with
`not a git repository: .../jests-hd-medieval-adventure/.git/worktrees/bellmire-art`.
The plan was read through the Blender bridge instead, which worked until that
bridge went down too. Recorded as a transient session fault, per the lane
prompt - no folder access was requested, because the lane already has it.

**CONSEQUENCE, STATED PLAINLY:** nothing in this pass is committed or pushed.
The files changed in the worktree are
`tools/art/_collier_occlude.py` (new), `tools/art/_collier_ventlabel.py` (new),
`tools/art/minibosses.py` (two guarded flags, shipped path unchanged),
`docs/art/COLLIER_THE_62nd.md` (this file), and the renders under
`renders/art/minibosses/collier_vlabel/` and
`collier_stream/_collier_occlude.json`. The first run with a working Blender
bridge must `git merge origin/art` and push them before anything else.
