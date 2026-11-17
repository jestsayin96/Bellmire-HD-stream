# D94 GLOVES - IS THE KNUCKLE DIAL SPENT? MEASURED, AND THE ANSWER IS NO.

Art lane, 2026-11-17 04:52 CT (clock off the machine). Branch `art`.
Team lead's 03:58 row, verbatim: *"THE KNUCKLE DIAL IS SPENT. You wrote that the
hand is hidden behind the cuff on Quarreller's, Forgemaster's and Raidbreaker's
from the front AND the side, so the knuckle treatments - spikes, studs, dome -
do not read on the body at all and live only in strip 1. ... Make the knuckle
read on the body, or say in writing that the cuff silhouette is the better
trade and the knuckle dial is retired - either closes it."*

**THE CLAIM THAT ROW IS BUILT ON WAS MINE AND IT WAS WRONG.** It was an
eyeball note in my own honest fit list. Measured, the knuckle treatment is
between a third and a half of everything the whole glove changes on the body,
in BOTH views. Nothing is retired and nothing needed rebuilding. No glove
geometry moved this hour.

## HOW IT WAS MEASURED

"Does it read" is a question about PIXELS, so it is answered in pixels, by the
proof sheet's own metric. `tools/art/_g8_knuck.py` renders each of the six
cells of the ticked gloves row THREE times at the row's own framing, light and
resolution (840x1200, Knight, idle, nothing else worn):

  1. **on**   - the glove as it ships
  2. **off**  - the same cell with `showcase.DROP = {'knuck'}`: the knuckle
                treatment block, and nothing else, is not built
  3. **none** - `DROP = {'glove'}`: no glove at all. THE CONTROL.

Two numbers come out of differencing them, and they are kept apart because
they are two different claims:

  - `px`  - percent of the hero's own pixels that change by a visible amount,
            block-averaged to STREAM size (the proof sheet's own metric, so
            it reads straight against the row's worst-pair number)
  - `sil` - percent of the hero's pixels the knuckle ADDS TO OR TAKES FROM THE
            OUTLINE. Shading inside a glove is not a shape a viewer can name.

## THE NUMBERS (renders/art/_g8_knuck.json, stream size)

| cell | cost | kind | verts | px | sil | WHOLE GLOVE px / sil |
|---|---|---|---|---|---|---|
| Baker's Mitts front | 200 | dome | 172 | 1.279% | **1.023%** | 4.874 / 1.820 |
| Baker's Mitts side | | dome | 172 | 1.534% | 0.000%* | 4.395 / 0.000* |
| Carder's Gloves front | 200 | dome | 172 | 1.068% | **0.911%** | 5.866 / 1.693 |
| Carder's Gloves side | | dome | 172 | 1.517% | 0.000%* | 6.040 / 0.000* |
| Bellringer's Wraps front | 240 | studs | 592 | 0.448% | **0.363%** | 3.322 / 0.659 |
| Bellringer's Wraps side | | studs | 592 | 1.462% | 0.000%* | 3.311 / 0.000* |
| Quarreller's Gloves front | 280 | **none** | **0** | 0.000% | 0.000% | 6.896 / 1.793 |
| Quarreller's Gloves side | | **none** | **0** | 0.000% | 0.000%* | 7.893 / 0.000* |
| Forgemaster's Grips front | 300 | spikes | 188 | 0.611% | **0.472%** | 5.616 / 1.490 |
| Forgemaster's Grips side | | spikes | 188 | 1.441% | 0.000%* | 5.861 / 0.000* |
| Raidbreaker's front | 380 | ridge | 236 | 1.543% | **1.179%** | 8.167 / 2.913 |
| Raidbreaker's side | | ridge | 236 | 2.801% | 0.000%* | 8.752 / 0.000* |

Share of the whole glove's own outline contribution, front: Baker 56%,
Carder 54%, Bellringer 55%, Forgemaster 32%, Raidbreaker 40%. By pixels from
the side: 33% - 44%. **A dial carrying a third to a half of the piece is not
spent.**

## *THE STAR IS THE INSTRUMENT ADMITTING WHAT IT CANNOT SEE.

Every `sil` in the SIDE column is 0.000%, which on its own reads as "the
knuckle changes no outline from the side" - and that would have been a tidy
confirmation of the row. It is false. The CONTROL says the WHOLE GLOVE also
changes 0.000% of the outline from the side, on all six cells: from 90 degrees
the arm hangs inside the torso's own profile, so **no part of any glove can
reach that silhouette**. The side column cannot test outline at all; it tests
shading, and it is labelled that way on the sheet and flagged in the report as
`views_blind_to_silhouette`. Without the control I would have reported a
blindness as a finding. That is the System 1 lesson applied before the damage,
not after.

## QUARRELLER'S GLOVES BUILDS NO KNUCKLE AT ALL, AND IT IS NOT HIDDEN

0 vertices, both views. `knuck_kind` is `none` and `orn` is 0.444, a hair under
the 0.45 at which the plain cut takes its gem instead. So the `knuck` dial of
0.2737 is spent on nothing. **The hub icon does exactly the same thing on the
same two conditions** (`icons.build_gloves`, `elif kind == 'none' and orn >
0.45`), so the glove in the satchel and the glove on the hand still agree,
which is the rule that matters. Changing it means changing `icons.glove_form`
or the shared `none` branch, and the 520 hub icons are ticked and must not
move. **I have not touched them.** If Mr. E wants no glove to land on a bare
knuckle, that is a dial decision for the shared form and it is one line - but
it moves ticked icons, so it is his call, not mine.

## THE PICTURE, LOOKED AT - renders/art/_g8_knuck_sheet.png

Twelve columns, knuckle ON over knuckle DROPPED, framed on the pixels the
control says the glove owns (the first attempt framed a band of the hero's
height, photographed the tabard, and produced a sheet that could not disagree
with me - that is recorded in `_g8_sheet.py`). What I see:

  - Raidbreaker's front: the gold ridge plates hang clear below the hip line
    and are the loudest single difference on the sheet. Gone in the bottom row.
  - Forgemaster's front: gold spike tips break the hip silhouette forward.
  - Baker's and Carder's side: the dome reads as a distinct cap on the cuff
    drum; without it the drum is bare.
  - Bellringer's: four studs along the glove's upper edge, both views.
  - Quarreller's: top and bottom rows are identical, as 0 verts predicts.

## FAULTS I CAN SEE AND AM NOT HIDING

  1. From the FRONT the knuckle reads as mass hanging off the HIP, not as a
     thing on the back of a hand - because the idle arm puts the fist at the
     hip and the tabard behind it. It reads; it does not read *as a knuckle*.
     Fixing that means moving the pose or the hand, not the dial.
  2. Forgemaster's and Raidbreaker's throw a thin blade-like spur forward off
     the lip's outboard skew (the team lead named this too). Not a clip.
  3. Carder's Gloves is still the least glove-like of the six - a fan of pale
     plates. Not a clip, and its knuckle dome is one of the clearest on the
     sheet.
  4. The side view can never test any glove's silhouette on this body. If an
     outline test is wanted for gloves it needs a three-quarter view, not a
     90-degree one.

## PROOF THAT NOTHING SHIPPED MOVED

`showcase.acc_gloves` gained a guard (`if 'knuck' not in DROP:`) and an early
return, both inert while `DROP` is empty, which it always is outside the probe.
Asserted, not asserted-by-assertion: the six post-patch front renders were
differenced against the TICKED row's own renders in `renders/art/d94g7b/gloves/`.

    max channel difference 0, pixels differing 0, over 1,008,000 px, all six.

Byte for byte the same image. `tools/art/d94proof.py` and `tools/art/icons.py`
are untouched this hour; the gloves row was NOT re-shot, as the row instructed.

## SNARER_CHIBI - ANSWERED, AND IT IS NOT A SNARER QUESTION

**Yes, it is wanted**: `snarer_chibi.glb` is the body the fit register actually
measured (`renders/art/minibosses/_fit_snarer_register.json`: ratio 1.00 to the
hero, pair width 4.51, fits_frame true, three views, 0 errors, blank check 2/0).

But it is not alone, and that is the real finding. On `main`, every `.glb` in
`assets/monsters/minibosses/` HAS a `.glb.import` sibling ON CRUZADER'S DISK,
and **five of them are untracked in git**: `gaoler_chibi`, `sexton_chibi`,
`snarer_chibi`, `snuffer_chibi`, `stoker_chibi`. They load on this machine
because Godot generated them here; a fresh clone would fall back to the base
bodies for all five. **This is not an art file and I have not committed it** -
see the wiring note in the summary.
