# CAN THE VIEWER SEE IT - the landmark readability test
tools/art/_mb_landmark.py

## STAMP CORRECTION, FIRST LINE, BECAUSE IT IS MINE
This file was first written 18 Nov 2026 and headed "20:4x CT". The machine
wrote it at 19:47:26 CT. That is a FUTURE stamp by an hour, on my own lane,
in the same week the prompt warns that several lanes have done it. Corrected
here rather than quietly: the first pass was 19:4x CT, and everything added
below is 18 Nov 20:3x - 20:5x CT, read off `TZ=America/Chicago date`.

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

  vis_px      STRUCTURAL. Pixels of the landmark the camera can actually see.
              Zero means occluded, or pointed straight down the camera axis.
  sep         TONAL, GLOBAL. Difference between the median luminance of the
              landmark's own edge pixels and the median of the creature
              pixels immediately outside it. KEPT FOR COMPARABILITY ONLY -
              see pass 4. It is no longer the verdict.
  sep_local   TONAL, LOCAL, AND THIS IS THE VERDICT. For every landmark edge
              pixel, the largest luminance step to a body pixel ACTUALLY
              TOUCHING IT; the number is the median of those.
  frac_flat   The share of that boundary whose local step is under 0.045.
              This is the thing `sep` cannot express at all.

RED ON EMPTY, all of them: vis_px == 0 is RED, a `sep` over zero boundary
pairs is RED, and a `sep_local` over zero touching pixels is RED. A
`_<name>_<view>_mask.png` is written every run so the count can be LOOKED at.

## FOUR PASSES. THE FIRST TWO WERE LIARS AND THE THIRD WAS A COIN TOSS.
PASS 1 defined the landmark as "any pixel where the two renders differ by more
than 0.02". Moving items into their own slot re-merges the meshes and shifts
shading by a hair EVERYWHERE, so the mask - which I wrote out and looked at -
had the Sower's legs, boots and thorn stalks in it. It reported the head as
79% of the side silhouette. That is not a head.
PASS 2 marked the geometry into a '_mark' slot. minibosses.merge_objs walks
ONLY ('body','dark','bone','glow'), so the landmark was silently DROPPED and
render B was the creature with a hole in it.
PASS 3 keeps every triangle in both renders and changes only its colour,
testing for magenta categorically. That part ships unchanged and is sound.
PASS 4 - `sep` DOES NOT REPRODUCE, AND I FOUND THAT BY RE-RUNNING IT RATHER
THAN BY THINKING ABOUT IT. Re-measured 20:3x CT with nothing in the tree
changed since the pass-3 numbers were written:

         landmark   view            sep then -> sep now
  sower  head       front             0.0386 -> 0.0504   CROSSES THE 0.045 LINE
  sower  head       three_quarter     0.0191 -> 0.0103
  sower  casthand   all three                  identical
  moulder head      front / side      0.0012 / 0.0174    identical

Two runs INSIDE this session are bit-for-bit identical (repeat 1 == repeat 3,
repeat 2 == repeat 4), so the renderer is deterministic and the drift is not
noise. The honest reading is that the pass-3 head row and the pass-3 casthand
row WERE NOT MEASURED ON THE SAME TREE: the head was measured before the
cast-arm slot fix of 19:48 and the casthand after it, and the cast arm's
shoulder sits inside the head landmark's sphere. A table half pre-fix and
half post-fix, with no stamp per row, is a table that cannot be checked.
TWO THINGS CHANGED BECAUSE OF THAT. Every row below is from ONE batch. And
`sep` stopped being the verdict, because it is the difference of TWO GLOBAL
MEDIANS over two separate pixel sets - so on a MIXED boundary (the Sower's
head touches shoulders, hat, hopper rim, strap and two arms) each median sits
between two populations and a handful of pixels tips it across a threshold.
`sep_local` has no global population in it and cannot do that.

## THE ROW LABEL WAS NOT THE PART. CHECK THE MASK, NOT THE NAME.
The row called `moulder head` is NOT the cast's pale egg. The landmark sphere
is at (-0.41, -0.9, 1.64), which is the LITTLE FOUNDRYMAN's head - and
_head_front_mask.png shows that plainly, as does _head_side_mask.png. I was
one edit away from fixing the wrong head on the strength of the label. The
mask picture is written every run for exactly this and it earned its keep.
The cast's own head is now measured separately, as `casthead`.

## THE SOWER'S CAST HAND SCORING ZERO FROM THE SIDE IS A FINDING, NOT A FAULT
and the next seat is not to re-open it. The arm is thrown along -X and the
side camera sits on +X, so that camera is looking straight down the length of
the arm. A structural zero with a geometric cause is the instrument working.
Recorded at the team lead's request, 20:0x CT.

## MEASURED 18 Nov 20:4x - 20:5x CT, ONE BATCH, pass 4
         landmark   view            vis_px  sep     sep_local  frac_flat
sower    head       front            15513  0.0504    0.1503     0.165   ok
sower    head       three_quarter    16632  0.0103    0.1717     0.085   ok
sower    head       side             44511  0.0678    0.1043     0.309   ok
sower    hopper     front            17149  0.0430    0.1415     0.195   ok
sower    hopper     three_quarter    16899  0.0390    0.1513     0.150   ok
sower    hopper     side             26273  0.0871    0.1207     0.264   ok
sower    casthand   front             5656  0.0801       -         -     ok
sower    casthand   three_quarter     3633  0.2484       -         -     ok
sower    casthand   side                 0    -          -         -     RED, structural, see above
moulder  head       front            11350  0.0927    0.1413     0.216   ok   (was 0.0334 / 0.583)
moulder  head       three_quarter     9067  0.1258    0.1367     0.158   ok   (was 0.0361 / 0.602)
moulder  head       side             10516  0.1446    0.0915     0.237   ok   (was 0.0698 / 0.360)
moulder  casthead   front            74151  0.0711    0.1244     0.147   ok
moulder  casthead   three_quarter    48118  0.0548    0.0700     0.363   ok
moulder  casthead   side             60963  0.0550    0.1024     0.264   ok

TWO VERDICTS CHANGED WHEN THE LOCAL NUMBER REPLACED THE GLOBAL ONE, in both
directions, which is the only reason to trust the swap:
  A FALSE RED CLEARED. `sower head` was the row I was handed to fix. On the
  shipped model it is not red - sep_local 0.15 / 0.17 / 0.10 - and the picture
  agrees: the head reads under the hat. I did not build a fix for it. Half of
  its old RED was the stale row and half was the global statistic.
  A FALSE GREEN CAUGHT. `moulder head` three_quarter passed at sep 0.0965 and
  is RED locally: 60% of that boundary was flatter than the threshold. The
  global median had averaged a sharp edge and a dead one into a pass.

## THE ONE FIX THIS PASS, AND IT IS THE MOULDER'S MAN
His head, his cap, his apron and the shoulders under it were ALL 'body' -
0.072 luminance, the darkest material in that register - so his head had no
lower boundary at all. In the picture he was a black blob with two orange
eyes. He now has a NECK CLOTH in 'dark', which on this body is the rammed
foundry sand, grey-buff at 0.243: a man who has spent a shift ramming sand
has it on his neck cloth, and it is the only material on him that can carry a
step against his own soot. Not a hat - a hat separates from the SKY, which
was never the fault. One change, measured alone, and every one of the nine
numbers above moved the right way.
HONEST FAULTS IN IT, FROM LOOKING AT hero_front.png AND nm/side.png:
  - from the side it reads a little like a brace or a ruff rather than a
    cloth; it is the cleanest-edged thing on a filthy man.
  - it is the same material as the sand bed behind him, so an azimuth that
    puts his collar against the bed will lose it again. No view in the three
    does, but the set is three samples of a circle.
  - at register size on the hero sheet it is a thin band. It is the
    difference between a head and no head, and not more than that.

## OPEN, NOT RED, AND I AM NOT FIXING IT ON A HUNCH
The CAST's head - the big pale egg - reads to my eye as one continuous pale
mass from crown to sand line on the front view, broken only by the dark brow
band. The instrument disagrees: sep_local 0.124 front, frac_flat 0.147. The
shoulder pads and arm plates give real local shading steps even though the
albedo is identical, and the number counts those. I am recording the
disagreement rather than resolving it, because the rule in this house is that
the picture is the evidence - but a late unmeasured change to a row that is
not red is how unearned work ships. renders/art/minibosses/moulder/hero_front.png
is the picture; the weakest row is three_quarter at frac_flat 0.363.
ALSO OPEN, SAME STANDING: from the side the Sower's hopper, legs and thorn
stems are all 'bone' and read as one pale field. The hopper measures fine
(frac_flat 0.264) and my eye says otherwise. Same disagreement, same answer.

## What it still cannot see - said plainly
One declared landmark at a time, and THE LABEL IS NOT CHECKED AGAINST THE
GEOMETRY - `moulder head` pointed at a different man's head for a whole pass.
It says nothing about parts nobody declared, nothing about whether a shape
READS AS what it is meant to be, and nothing about hue: two parts of equal
lightness and different colour score 0 here and may still separate on a
stream. The Sower's 'body' (lum 0.498) and 'bone' (0.549) are 10% apart in
luminance and plainly different in colour, so this instrument is close to
blind on that creature by construction. Three azimuths are three samples of a
circle. When this number and a picture disagree, the picture is the evidence.
