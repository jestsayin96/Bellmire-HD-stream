# THE MEALMAN - "Whitedamp". The 65th body. Passes 1-5, 27 Nov 2026, ~00:35-01:15 CT.

## WHAT I MEASURED BEFORE I DESIGNED (not remembered)

- **64 live bodies on `origin/art`**: 77 `.glb` under `assets/monsters/minibosses/`,
  minus 11 `_chibi`, minus the two bosses `broodglut` and `lastcuff`. Counted off
  the ref with `git ls-tree`, not off a worktree.
- **All 76 CANON entries parsed out of `tools/art/minibosses.py` and every gimmick
  string read** before a line was drawn. 62 distinct non-variant bodies across all
  14 floorgen themes; `mess` stands at 4, the joint-thinnest rung, so that is where
  this one goes.
- **Height 2.37 and wear 0.36 are free rungs**, measured off those entries: 2.36 and
  2.38 taken, 2.37 not; 0.35 and 0.38 taken, 0.36 not. `Whitedamp` is not among the
  62 taken titles.

## THREE DESIGNS DIED ON THAT READING

- **Dust on a count** - the air thickens a step per round until a flame takes the room.
  Dead: the SLUICEKEEPER already winds its hazard open "a step at a time", and the
  Tither's own docstring already struck a design for this - an escalating room clock
  is one fight shape, not two. **So the dust here does not escalate.** It is thick at
  the doorway.
- **A sack that bursts when struck.** Dead: the FULLER "gives back what you put in"
  and the TANNER "will not take the same blow twice".
- **A meal-man who strikes the measure level.** Dead before it was drawn - the
  STRICKLER *is* that trade. No measure, no strike, no scoop is on this body.

## THE IDEA

**IT MAKES YOUR OWN FIRE THE ROOM'S.** While it stands, every point of burning
anybody deals lands on every body in the room, its own included. Nothing escalates,
nothing is summoned, nothing is on a count. The party's own kit is the trap: bench
the fire hand for the whole fight, or set the air off on purpose and take the burn
to kill it faster than any blade will.

**What is not in the other 64 is a damage type turned against its owner.** Every
other condition in the file is on the monster, on the party's position (the Fanner's
crowd count) or on one hero (the Dyer's mark). The nearest neighbour is the FULLER
and it is a different sentence: the Fuller punishes the hand that swung and heals
itself; the Mealman does not care who swung, spreads the burn to everyone including
itself, and is therefore the one body you can kill quickest by hurting your own line.

**No emissive slot is used, and that is the mechanic.** First body in the file with
nothing alight on it: a room whose rule is "no flame in here" must not carry a flame.
The cue census is unaffected - this file already carries most countable cues as pale
`bone` geometry and `MB_CUEOFF` takes `bone`.

## THE FIVE PASSES - EACH ONE CHANGE, EACH JUDGED ON A PICTURE

1. **Built.** Verdict GREEN but the fall was placed **from its midpoint**. `L.cone`
   builds base-at-origin; pass 1 passed the midpoint, so the rope started mid-chest
   and ran a full length further - through the trunk, through the trough and out the
   bottom, where it read as **a pale apron**. A bug, not a taste note.
2. **Base moved to the top of the fall.** Apron gone. New fault: the rope ran through
   the corridor his own right forearm occupies (x 0.268 -> 0.196), so it was cut into
   two slivers, and at hero distance those were flecks. The cue did not survive.
3. **The mouth went outboard** (world x 0.455, y -0.330) with the landing moved to
   the trough's near-outer quarter. One unbroken rope, clear of the arm. New fault,
   and it is the one I had predicted in the wrong place: **at hero distance it read
   as a white sword.**
4. **One rope became three.** Width was the wrong lever (a thinner slab is a thinner
   blade). Three strands separated cleanly at render resolution - and **fused back
   into one slab on the hero sheet**, seams under a pixel. The Fanner's fused-vane
   fault in another coat.
5. **The strands splay.** Count was the wrong lever too. What survives distance is the
   **outline**: a blade is a straight-sided wedge, and passes 3 and 4 both kept that
   outline exactly. The strands now leave the chute almost touching and land 0.21 m
   apart over a heap wider than any of them. The hero sheet reads a fan over a heap.

## THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE

Rendered on an actual KayKit adventurer at scale 1.0 (`minibossfit`), front, side and
back, plus the body's own three orthos. Looked at every pass.

**What works.** The face reads at hero distance - pale brow band, dark eye pits, pale
mask, dark breathing slot. **The back is a back**: all pale is front-only by
construction, the hopper rim is deliberately dark, and nothing pale appears from
behind, so the Beadle's no-facing fault does not repeat. The hopper reads as a made,
hooped vessel and not a lump; the chute arch over the shoulder reads from front, side
and three-quarter, so the 34 deg yaw did its job. The trough is clear of the smock hem
on the side ortho - predicted fault 3 did not land.

**Open faults, named not tidied away:**

1. **The fall still hides his right arm** in the front ortho. Pass 3 bought the cue its
   air by putting it where the arm is drawn, and nothing since has given the arm back.
   This is the cost of the cue and it is the loudest remaining fault.
2. **It is still sword-adjacent at hero distance.** The fan is real and the outline now
   has a V in it, but the top third is still a tight pale wedge beside a figure's flank.
   Better, not closed.
3. **The three drift puffs are wrong and are actively harmful.** At the trough lip they
   sit on his mitts and read as **white mittens**, and the third reads as a button on
   his chest. They were meant to say "the air carries it". They say nothing. They should
   move well clear of both hands or be cut.
4. **The heap overhangs the trough rim by about 0.02 m** in x. It reads as meal heaped
   over the lip rather than a float, but it is an overhang and the next pass should
   measure it rather than assume it.
5. **From behind he is a bin with legs.** Honest and not necessarily wrong - it says
   "carrier" - but the man is nearly lost behind his own hopper in `hero_back.png`.

**What the harness cannot see.** No blank check and no border check can see any of
the five above: a sliver is not a blank, a sword-shaped cue is not a clip, and a
mitten-shaped puff passes every count. They are answered by looking and by nothing else.

## NUMBERS

Verdict **GREEN**, `ok: true`, `errors: []`, **0 blanks and 0 frame clips across 195
files**. 3 merged meshes (bar is 4), 1560 faces, size 1.14 x 1.15 x 2.37 m,
footprint span 1.15 m. **CORRIDOR-SAFE** (margin 9.855 m) and **UNDER-LID**
(clear 7.13 m) against `scripts/floorgen.gd` read live. **NOT room-locked.**

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT DO IT

`scripts/bestiary.gd`: add a `mealman` entry with
`model = "res://assets/monsters/minibosses/mealman.glb"`, `h = 2.37`, and **NO `anims`
entry** - the body is static.
`scripts/delve.gd`: add `"mealman": "Whitedamp"` to `MB_NAME`.
Content owes a `miniboss_feed.by_key` row for `mealman`; the feed line is
`"Something ahead is pouring, and the air tastes of flour."`
**Note for the team lead: this takes the live-body count to 65 and so widens the
naming cascade by one until those two rows land.**
