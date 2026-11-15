# D76 - MEASURED BEFORE BUILDING, AND THE PLAN'S NUMBER IS WRONG

> **STATUS, 15 Nov 23:50: D76 IS NOW BUILT to the measured scope below** - the
> twelve bodies are in `assets/monsters/creatures/` and written up in
> `docs/art/CREATURES.md`. The census line in WORK_PLAN.md still needs
> correcting; this document is why.

**This is the measurement that decided how the item was scoped, taken before any
geometry, because the number in WORK_PLAN.md leads to the wrong plan.**

WORK_PLAN.md and the art census say:

> ~109 monster families share 10 models [...] Build a parametric creature system
> [...] Do NOT attempt 109 sculpts.

Counted from `scripts/bestiary.gd` on 15 Nov, what is actually there is:

| | Plan says | Actually in bestiary.gd |
|---|---|---|
| creature types | ~109 | **30** |
| distinct models | 10 | **18** |
| types sharing a model with another type | ~99 | **12** |

The ~109 is most likely types multiplied by the nine STRAINS, or types plus the
270 lord uniques. It is not a count of creature entries, and treating it as one
makes D76 look like a system-building job when it is a finite list of twelve.

## The twelve that are literally another creature with a label

Ten models are used by more than one type. These are the cases the plan means
when it says "a scarrat is not a rat with a different label":

| Model | Types sharing it |
|---|---|
| `Skeleton_Warrior.glb` | skeleton warrior, **bone sentinel**, **marrow hewer** |
| `Spider.glb` | cave spider, **silk mother**, **spiderling** |
| `Skeleton_Minion.glb` | skeleton minion, **bone bowman** |
| `Skeleton_Rogue.glb` | skeleton rogue, **pale cutthroat** |
| `Skeleton_Mage.glb` | skeleton mage, **gravecaller** |
| `Slime.glb` | slime, **slimeling** |
| `Bat.glb` | cave bat, **gloom bat** |
| `Rat.glb` | giant rat, **scar rat** |
| `Frog.glb` | bog frog, **fen lurker** |
| `Dragon.glb` | grave-whelp, **pit wyrm** |

The other 18 types already have a model of their own.

In fairness to whoever wrote them, these twelve are not bare reskins: L27a gave
each a different height, a tint and glow the stream can read, and in several
cases its own weapon. A spiderling at 0.35 m and a silk mother at 1.3 m do read
differently. What they do not have is a different **shape**.

## What this means for the item

D76 as written asks for a parametric creature system to replace ~99 duplicates.
What the data supports is a smaller, sharper item: **give those twelve a body of
their own**, the way the eight lords got one in D75, reusing the same generator
(`tools/art/lordlib.py` plus a creature module). Twelve bodies is the same order
of work as the eight lords, which took one session - not a system to carry 109.

The nine STRAINS already carry a second axis of variety (tint, glow, scale and
a particle per strain, applied on top of any body), so variety per floor is not
only a model problem and should not be solved twice.

**The supervisor should correct the census line and re-scope D76 before an art
worker starts it.** The art worker did not start building against a number it
could not reproduce.

## Not touched

No creature geometry was generated and no game file was changed for D76. D75
(the eight lords) and D73 (454 item icons) shipped in this session and are on
branch `art`.
