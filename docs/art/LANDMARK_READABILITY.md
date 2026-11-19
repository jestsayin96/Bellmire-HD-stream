# CAN THE VIEWER SEE IT - the landmark readability test
18 Nov 2026, 20:4x CT. tools/art/_mb_landmark.py

## Why this exists
The team lead looked at renders/art/minibosses/sower/hero_side.png and found
that the Sower's forearm, hand and seed-bag read as ONE PALE MASS. The fit
register said `ok: true, errors: []`. _mb_sil.py could not find it either and
says so in its own docstring - a silhouette throws colour away, so two parts
that overlap are one blob there whether colour tells them apart or not.
Neither instrument asks the viewer's question.

## What it measures, per view
Renders the creature TWICE through ONE camera - once normally, once with the
declared landmark's geometry given a flat magenta emission - and counts the
magenta. The renderer does the depth, which is the pass-11 lesson.

  vis_px  STRUCTURAL. Pixels of the landmark the camera can actually see.
          Zero means occluded, or pointed straight down the camera axis.
  sep     TONAL. Median luminance step, in the NORMAL render, between the
          landmark's own edge pixels and the creature pixels immediately
          outside it. Near zero means visible and still unreadable - the
          pale-on-pale fault, by name.

RED ON EMPTY, both: vis_px == 0 is RED, and a `sep` over zero boundary pairs
is RED, not 0.0. A `_<name>_<view>_mask.png` is written every run so the count
can be LOOKED at.

## THREE PASSES, AND THE FIRST TWO WERE LIARS. Recorded because the numbers
## they printed looked healthy.
PASS 1 defined the landmark as "any pixel where the two renders differ by more
than 0.02". Moving items into their own slot re-merges the meshes and shifts
shading by a hair EVERYWHERE, so the mask - which I wrote out and looked at -
had the Sower's legs, boots and thorn stalks in it. It reported the head as
79% of the side silhouette. That is not a head. The number was noise with a
head-shaped piece in it, and nothing but the picture said so.
PASS 2 marked the geometry into a '_mark' slot. minibosses.merge_objs walks
ONLY ('body','dark','bone','glow'), so the landmark was silently DROPPED and
render B was the creature with a hole in it.
PASS 3, which is what ships, keeps every triangle in both renders and changes
only its colour, and tests for magenta categorically so shading noise cannot
enter the count. Verified by eye: the Sower side mask is the hat and the head
and nothing else.

## What it still cannot see - said plainly
One declared landmark at a time. It says nothing about parts nobody declared,
nothing about whether a shape READS AS what it is meant to be, and nothing
about hue - two parts of equal lightness and different colour score 0 here and
may still separate on a stream. When this number and a picture disagree, the
picture is the evidence.

## Measured 18 Nov, pass 3 (renders/art/minibosses/_landmark/)
         landmark   view            vis_px   sep
sower    casthand   front             5656   0.117  ok
sower    casthand   three_quarter     3633   0.004  RED does not separate
sower    casthand   side                 0    -     RED NOT VISIBLE AT ALL
sower    head+hat   front            15497   0.039  RED
sower    head+hat   three_quarter    16618   0.019  RED
sower    head+hat   side             44511   0.068  ok
sexton   head       front            11103   0.095  ok
sexton   head       three_quarter    11679   0.095  ok
sexton   head       side             10595   0.202  ok
moulder  head       front             7622   0.001  RED
moulder  head       three_quarter     6441   0.097  ok
moulder  head       side              8200   0.017  RED

The Sower's cast hand scoring ZERO from the side has a cause, not a mystery:
the arm is thrown along -X and the side camera sits on +X, so it is looking
straight down the arm. The pale-mass part has a cause too - minibosses.limb()
defaults to slot 'bone', so the torso, the cast arm, the hopper and the hat
are ALL 'bone'. They cannot separate by tone because they are the same
material. That is a construction fact, not a lighting accident.
