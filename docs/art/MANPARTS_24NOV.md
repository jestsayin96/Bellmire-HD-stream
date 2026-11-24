# THE SELF_SEEN CENSUS COULD NOT SEE SIX BODIES, AND FOUR OF THEM WERE THE NEWEST IN THE HOUSE

24 Nov 2026, 16:34-17:1x CT, art lane. The plan's item was "the 56th, or close
the 25 `not_measurable` bodies". This is the second, and the first thing it
found is that the list of 25 was wrong about six of them.

## WHAT WAS WRONG

`_backread.py` asks the viewer's question - render the figure with and without
through ONE locked camera and count the pixels that moved - and it took the
figure as a single CONTIGUOUS span named `man`. `_selfseen_census.py` therefore
tested `"man" in spans` and printed, for 25 of 57 register rows:

> no `man` span at all: nothing to split, so NOTHING IS CLAIMED.

Measured off the builders themselves with the new `tools/art/_spanprobe.py`,
that sentence was FALSE for six of the 25, and the four most recent bodies in
the house were among them:

| body | the spans its builder already declares for the figure |
|---|---|
| `iceman` (54th) | `legs` `trunk` `head` + `arms` |
| `straker` (55th, ticked this hour) | `legs` `trunk` `head` + `arms` |
| `nightman` (53rd) | `legs` `trunk` `head` + `arms` |
| `stiltman` (52nd) | `legs` `trunk` `head` `arms` |
| `hurdleman` | `man_lower` `head` `tool_arms` |
| `tanner` | `man_lower` `head` (+ `arms`, see below) |

Every one of them splits the figure from the gear. They split it under names
other than `man`, and a span-NAME match cannot see a decomposition that is
sitting right there. Three of the six are not even contiguous, for one
authoring reason: the arms must reach the apparatus, so they are built after it
exists and land last in `P.items`.

Being wrong in this direction is SILENT. `not_measurable` is the list where
nothing is claimed and nothing is printed, so a body that drops into it leaves
measurement wearing a green file. That is the same fault class as the
hand-written 46-body census the 11:4x run found, one level down again.

## THE FIX, AND WHY IT IS NOT A LIST OF NAMES

A guessed name set - "trunk is a man" - is how an instrument reports an
UNEARNED number. `trunk` is a man in these six and could be a tree in the next
builder. So the BUILDER states it, in its own body:

    P.man_parts = ("legs", "trunk", "head", "arms")

`minibosses.man_ranges(P)` is the ONE resolver, read by the census and by
`_backread`'s splitter, so the instrument and its coverage report can never
disagree about what the figure is. It returns RANGES, never a merged guess,
and `_backread` now partitions on a range SET rather than one range. It guesses
no names and it goes RED, not absent, on every bad declaration.

## THE THREE THINGS THIS RUN CAUGHT IN ITS OWN WORK

1. **`tanner` measured a man with no arms.** His arms are authored inside the
   `work` block because they must reach the beam that block builds, so they
   were inside the `work` SPAN, and the first `man_parts` written here
   (`man_lower` + `head`) called that armless figure the man. Found by opening
   the front render and counting the limbs against the span. `_span("arms")`
   added; `man_seen` front 0.5731 -> 0.6173, side 0.5447 -> 0.5759.
2. **Declared-and-empty read as undeclared.** `getattr(P, "man_parts", None)`
   plus `if parts:` sent `man_parts = ()` down the no-declaration branch and
   into `not_measurable` - the silent outcome, from the very mechanism written
   to abolish it. Caught by arm D of `_manparts_prove.py` on that harness's
   FIRST firing. Sentinel added.
3. **The harness failed its own author.** Arm A asserted "at least 7 bodies
   resolve from parts" from memory and the real tree says SIX. The number is
   now measured and pinned.

`tools/art/_manparts_prove.py` watches all of it fire: a `man_parts` naming an
undeclared span is RED and NAMES the span; declaring both `man` and
`man_parts` is RED; an empty `man_parts` is RED; and the `panner` marker - a
deliberately EMPTY `man` span, a machine with no operator - is still NOT an
error, because an unearned FAIL is the same fault as an unearned pass.
Eight arms, all GREEN.

## WHAT THE SIX NOW MEASURE, AND IT IS NOT ALL GOOD NEWS

Register after: `measurable` 31 -> **37**, `not_measurable` 25 -> **19**,
`measured_cells` 93 -> **111**, `census_covers_register: true`, `uncovered []`,
`uncensused []`, `build_failed []`, verdict GREEN, `errors []`.

Two of the six come in UNDER the 0.75 bar, which is the point of measuring
them. The bar NAMES rows, it does not fail them:

- `tanner` front **0.6173** / side **0.5759**. I opened the front: he reads -
  hooded, two pale eyes, apron - but the beam and the hide across it cover his
  lower half. The number is honest occlusion, not a blind body.
- `hurdleman` back **0.6749**. I opened it. From behind he is mostly fence:
  a dark round head, two shoulder knobs and a pale trunk read THROUGH the
  hurdle lattice, and the figure does not separate from his own work. This is
  the Beadle question (does it read from BEHIND) answered badly, on a body
  ticked long before that question existed.
- `stiltman` front/side score **2 value bands** where the house wants three or
  more, and the picture agrees with the number: he is one mid-grey from stilt
  to hood. NOTE ONE HONEST COST OF THE DECLARATION: his pale CUFFS are the only
  light value on him and they are GEAR - the straps that bind him to the stilts
  - so they are correctly excluded, and excluding them is part of why he reads
  as two bands. Not gamed back in.

None of the three is fixed here. They are now MEASURED and NAMED, which they
were not this morning.

## THE CHANGE MOVED NO PIXEL, AND PROVING THAT FOUND SOMETHING ELSE

A whole-house `minibossfit` run re-rendered 55 cells / 165 files. Every PNG in
the house is byte- or pixel-identical to what is committed, EXCEPT four - and
`boiler/hero_side.png` and `boiler/hero_back.png` differ by **60,153** and
**75,608** pixels.

THAT IS NOT THIS CHANGE. Proved three ways: run-to-run with my code is
bit-identical; HEAD's own `minibosses.py` renders the same two files the same
way; and HEAD-code vs my-code on the boiler is zero differing pixels on all
three views.

**The committed `boiler/hero_side.png` and `hero_back.png` are STALE.** They
show a BROWN boiler. The code renders him GREY, and the committed FRONT view
is already grey - so a colour pass landed, the front was refreshed and the
other two views were never re-rendered. The fit register has been judging those
two cells off pictures that are not of the current body. Both are refreshed in
this commit. `_hero_scale.png` and `changer/hero_front.png` also show as
modified and are PIXEL-IDENTICAL (0 differing pixels, 1/255 encode dither) -
the "changed in git without changing a pixel" class.

## WHAT IS LEFT, HONESTLY

**19 bodies remain `not_measurable`** and they are the real remainder: their
builders declare NO spans at all, so there is nothing to name yet. Closing each
one means reading its builder and spanning the figure out of it - about a body
at a time, and each one is a chance to call a prop a man. Nothing is claimed
for any of the 19 and the register says so.

    bellman cook drillmaster gaoler jointer loader porter quartermaster
    rammer scrapwright sexton sluicekeeper snarer snuffer snuffer_chibi
    sower stoker tallyman tallyman_chibi
