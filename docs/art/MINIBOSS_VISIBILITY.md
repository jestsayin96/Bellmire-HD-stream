# THE MINIBOSS REGISTER CAN NOW SEE AN OCCLUDED FRAME

17 Nov 2026, 15:51 CT. Art lane. Plan row (origin/main WORK_PLAN, 14:58 block,
ART): *fix the blindness you found in your own miniboss register - it is worth
more than a twenty-first body.*

## THE DEFECT

Building the Reeve, pass 1's side view had a body standing entirely behind
another body - a fit shot in which one of the two subjects could not be seen at
all. `minibossfit` passed it. So did the blank check and the border check, and
neither could have done otherwise:

**A FULLY OCCLUDED FRAME IS STILL FULL OF OPAQUE PIXELS INSIDE THE BORDER.**

That is the whole of it. A blank check answers "did anything render". A border
check answers "did it run off the edge". Neither answers the viewer's question,
which is "can I see the thing". Only looking at the picture caught it, and a
check that depends on somebody looking is not a check.

This is the same fault class retired on the weapon register at fault 4 nine
hours earlier, where `mask_of` answered how BIG a thing was and was read as
whether it could be SEEN.

## THE FIX - THE VIEWER'S QUESTION, WITH THE RENDERER DOING THE DEPTH

Per cell, per view, three renders through ONE camera:

    A = the hero alone        B = the cell (hero + creature)      C = the creature alone

    creature vis  = pixels that MOVED between A and B, counted only INSIDE C's
                    own silhouette
    creature seen = vis / alone

Bounded to the subject's own silhouette ON PURPOSE: the raw diff also catches
cast shadow, and on the weapon register that produced `seen` of 1.20-1.26 - a
fraction of nothing anyone can name. `delta` is kept beside `vis` so the gap
between them (the shadow) stays visible.

**AND THE SAME QUESTION BACK THE OTHER WAY.** This frame has TWO subjects and
either can hide the other, so the hero is measured against the creature as
well: moved between C and B, inside A's silhouette. That half is not
hypothetical - `place()`'s own docstring records the hero-hidden-behind-the-
creature fault being fixed BY CONSTRUCTION on an earlier pass, with nothing
measuring whether it stayed fixed. It does now.

A RATIO IS BLIND TO SIZE, so a view must clear a pixel floor too:

    SEEN_MIN 0.15   VIS_MIN 700 px (~26x26 on a 760x520 cell)
    MIN_PROVING 2 of 3 views must show BOTH subjects, or the cell FAILS
    alone == 0 is RED, not green

## THE RED PATH, PROVED AND RESTORED

`--prove-red` renders the cell with the creature taken out of it while still
measuring the creature - the fault itself in its purest form. Run on `reeve`:

    verdict RED, ok false, proving 0 of 3
    front creature seen 0.000 vis 0 / hero seen 1.000 vis 43672
    side  creature seen 0.000 vis 0 / hero seen 1.000 vis 37758
    back  creature seen 0.000 vis 0 / hero seen 1.000 vis 44027
    blank_check: 3 files, 0 failures

**THE LAST LINE IS THE POINT.** On the identical three frames the old
instruments report no failures and the new one reports none of three proving.
The register now demonstrates its own old blindness in the same file, which is
the standard the team lead set on the weapon register.

Kept at `renders/art/minibosses/_fit_visred.json`.

A FIRST ATTEMPT AT THE RED PATH DID NOT GO RED and is recorded because it is
the more useful half: standing the hero on top of the creature produced
mutual occlusion of only 0.53-0.93 seen, which the test correctly passed. A
partial overlap is not the fault. The red path had to be the fault's own shape.

## THE RESTORED RUN - ALL TWENTY

    verdict GREEN, ok true, asked 20, measured 20, errors []
    blind_views [], blank check 60 files 0 failures
    every one of the twenty: 3 of 3 proving views

## WHAT THIS STILL CANNOT SEE - SAID PLAINLY

1. **SELF-OCCLUSION INSIDE ONE CREATURE.** The Reeve's pass 1 was its own box
   hiding its own man. C contains that occlusion too, so `seen` stays high and
   this test passes it. The literal frame that started this is caught by the
   hero/creature test only when the hidden part IS the creature. The parts are
   merged by MATERIAL (at most four groups), so a part-level port would ask
   about `body` vs `dark`, not about the man vs the box - it would not have
   caught it either. **Nothing here replaces looking at the picture; it
   replaces trusting a green verdict without one.**
2. **READABILITY.** A subject can be fully visible and still read as a smudge
   at pair distance. VIS_MIN is a floor, not a legibility test.
3. **TWO CELLS IT HAS NEVER LOOKED AT.** `snuffer_chibi` and `tallyman_chibi`
   sit in `pairs` with a ratio and no visibility block: neither is in `M.ORDER`
   any more, so neither is ever asked for. They are now named in the report as
   `unproved_cells` so a GREEN verdict cannot be read as covering them.
