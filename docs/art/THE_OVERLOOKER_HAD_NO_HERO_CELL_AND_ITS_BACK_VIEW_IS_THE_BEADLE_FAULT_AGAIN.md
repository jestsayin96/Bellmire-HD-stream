# THE OVERLOOKER HAD NO HERO CELL AT ALL - AND NOW THAT I HAVE RENDERED ONE, ITS BACK VIEW IS THE BEADLE FAULT AGAIN

ART lane, 25 Nov 2026, the 22:34 CT firing. Clock read off the machine with
`TZ=America/Chicago date` before every time in this file: 22:34:43 start,
22:41:36 mid, 22:46:05 census. **DO NOT READ TIMES OFF THE FILE MTIMES IN THIS
WORKTREE** - the Linux bridge reports them three hours ahead of CT, and the
render I made at 22:44 CT lists as `Nov 26 04:44`. Convert or do not quote them.

## THE TEAM LEAD WAS RIGHT TO WITHHOLD THE TICK

The plan's ART row at the 17:58 firing says:

> I am LOOKING AT `renders/art/minibosses/overlooker/back.png` AND THE
> `_back_report.json` FACING SCORE MYSELF before I tick, because a back view is
> precisely where a number said `seen: 1.0` on the Beadle while the picture had
> no face at all.

I ran the scale harness this run and found something that should come before
that look: **the Overlooker had never been rendered beside a hero at all.**

`tools/art/minibossfit.py --sheet` over the whole house came back **RED** on its
own, and its two errors were both honest:

    "no ratio on record for: overlooker (asked for 1, measured 0)"
    "blank_check: opened 186 view PNGs but the sheet has 63 cells, so 3 files
     were never looked at. A check that skipped files must not report green."

186 of 189 files, and the three absent ones were `overlooker/hero_front.png`,
`hero_side.png` and `hero_back.png` - every other one of the 64 rows had its
three proving cells. The body's own `front/side/back/three_quarter` existed,
which is why nothing upstream noticed: **a body can have four renders and still
have no fit proof, because the fit proof is the one with the hero in it.**

**AND MY FIRST ATTEMPT TO FIX IT WAS WRONG IN THE WAY THIS LANE KEEPS BEING
WRONG.** I passed `--only overlooker --sheet` and the report came back with
`"rendered": 0`. I read `--sheet` as "render and also compose a sheet". Line
1759 of the harness is `rendered = 0 if args.sheet else len(measured)`: `--sheet`
is compose-ONLY and skips the measurement loop entirely. I had asked the
instrument to render and it had told me, in a field I did not read, that it had
rendered nothing. Re-run without `--sheet`:

    blender -b -noaudio -P tools/art/minibossfit.py -- --repo W5 --only overlooker

    rendered: 1
    overlooker ratio: [0.98, 3.41, true]       <- 0.98x hero height, corridor-safe
    blank: 189 files / 189 expected, failures []   <- was 186/189
    blind_views: []

The second RED that then surfaced was also real: the self_seen census covered
**64** register rows and was being read against **65**, so the Overlooker was in
the register and in no census list - the instrument that asks the VIEWER'S
question had never been asked about this body. `tools/art/_selfseen_census.py`
re-run at 22:46:05 CT: `pairs=65 measurable=61 no_man=1 not_measurable=3
build_failed=0`, **`pairs in NO list: 0`**. Covered now.

## THE FIT PROOF - WHAT I SEE IN THE THREE RENDERS, HAVING LOOKED AT ALL THREE

Hero measured this run, not taken: KayKit knight, posed, h 2.45, w 1.32, d 1.253.

**THE BACK VIEW IS THE BEADLE FAULT, REPEATED. THIS IS THE ONE THAT MATTERS.**
Put `hero_back.png` beside `hero_front.png` and the knight is unmistakable in
both - from behind you get the red cape, the back of the helmet and no face.
**The Overlooker is very nearly the same picture in both.** Same silhouette,
same pale rod out to one side, same dark cap, and **the pale eye-dot on the head
is still visible from BEHIND.** The figure has no facing. That is the Beadle's
shipped fault, verbatim, on the next body, and it is exactly what the team lead
said a back view is where you find.

The rest, honestly and in full:

  1. **PIPE-ARM IN BOTH ORTHOS.** The pale arm is dead horizontal in the front
     view AND in the side view. The Weigher's own docstring sets the rule this
     breaks: "a reach that is horizontal in one ortho is the pipe-arm, and only
     a reach DOWNWARD AND DIAGONAL escapes both." This one escapes neither. In
     the side view it reads as a pale cylinder floating off the chest.
  2. **PROPORTION - IT IS A SEVEN-HEAD MAN BESIDE A CHIBI.** Tiny head, narrow
     shoulders, thin straight legs, against the knight's huge head and chunky
     limbs. This is the 16 Nov FIT EXPERIMENT note's own words - "beside a chibi
     knight they read as pipe-cleaner men from a different game" - and that note
     is in this file at the top of the miniboss generator.
  3. **MONOCHROME BODY.** Cap, coat, arms, legs and boots are one grey value.
     The only separated thing is the pale rod. This is the defect the Dauber's
     PASS 2 comment says OVERRIDE exists to break, arrived at from the value
     side rather than the hue side.
  4. **NO FACE FROM THE SIDE EITHER.** In `hero_side.png` the head is a
     featureless dark cap with a brim. Front, side and back all fail to carry a
     face; the eye-dot is the only cue and it is readable from the wrong side.
  5. **THE COAT IS A FLAT SLAB IN SIDE VIEW** - almost no depth front-to-back
     against the knight's real volume.
  6. **GROUND CONTACT IS WEAK.** The knight sits in a firm contact shadow; the
     Overlooker's is faint and the small dark boot blocks read as hovering just
     off the floor rather than planted.
  7. **0.98x IS NOT A SET PIECE HEIGHT.** The ratio is honest and corridor-safe,
     but at 0.98 the thing stands eye-to-eye with the party. The generator's own
     scale note says "a floor-4 set piece that the heroes look down on is not a
     set piece"; a set piece the heroes look levelly at is only half a step
     better. This is a number for the team lead and the game build to rule on,
     not for me to change unilaterally - `h` is theirs.

**NONE OF THESE ARE BLANKS OR FRAME CLIPS.** Blank-and-border: 189/189 files
opened, 0 failures, 0 blind views, 0 unproved cells. Every fault above is a
thing the numbers passed and the picture did not, which is the whole reason the
standing rule is to look.

## WHAT I AM NOT CLAIMING

I did not fix any of the seven. Pass 6 is a modelling pass and I had neither the
window nor a mandate to re-cut a body the team lead is mid-way through judging.
**The Overlooker is NOT done** by this lane's own rule, and I am saying so
rather than banking the green blank-check as a pass.

## WIRING THE GAME BUILD LANE MUST DO

**NONE from this run.** Nothing new entered `assets/`. The Overlooker's
`.glb.import` landed in `de6fb69b` earlier this firing. The `h` for the
Overlooker in `bestiary.gd` is the game build's to type and the measured
argument for it is now on record at ratio 0.98 of a 2.45 m hero - see fault (7)
before typing it.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
