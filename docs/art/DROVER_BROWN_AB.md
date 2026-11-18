# THE DROVER'S BROWNER BACK - ANSWERED AS AN A/B, 2026-11-18 ~04:40 CT

**THE QUESTION**, team lead, 04:07 CT TAKE THIS NEXT, art's second row:
> the Drover's body reads markedly BROWNER in hero_back.png than in
> hero_front.png. I believe that is your lighting rig and not the material, and
> I am NOT calling it a fault - but you are the only lane that can say, and it
> is one line either way.

**THE ANSWER: IT IS THE RIG, AND SPECIFICALLY THE AURA-COLOURED RIM LIGHT.
IT IS NOT THE MATERIAL, AND IT IS NOT A FAULT.**

## HOW IT WAS ANSWERED, AND WHY NOT BY READING THE CODE
Reading `lordgen.add_lights` would have given the same answer in thirty
seconds. I did not ship that, because this lane has twice talked itself into a
number that way - most recently at Pass 11 on 17 Nov, where `head_glow_px: 156`
sat beside my own sentence "the head now has no face at all" and the honest
number was zero. When a number and a picture disagree the picture is the
evidence; when neither exists yet, make one.

`tools/art/_drover_brown_ab.py`. **ONE THING CHANGES** between the two arms:

| | rim light colour | everything else |
|---|---|---|
| **A** | `info['aura']` = (0.86, 0.78, 0.62), a warm tan - **SHIPPED** | unchanged |
| **B** | (1.0, 1.0, 1.0), white | unchanged |

Same geometry, same materials, same key light, same fill, same two cameras,
same energies, same positions. The rim sits at direction (0.1, 1.0, 0.55) -
**behind the body** - which the back camera looks straight into and the front
camera does not.

## THE MEASUREMENT
`renders/art/minibosses/_brown_ab/_brown_ab.json`. "warm" is
mean((R-B)/value) over the body's own opaque pixels; the gap is back minus
front, so a bigger number is a browner back.

| arm | warm front | warm back | **warm gap** | sat front | sat back | **sat gap** |
|---|---|---|---|---|---|---|
| A shipped | 0.0875 | 0.2282 | **0.1407** | 0.1043 | 0.2337 | **0.1294** |
| B white rim | 0.0788 | 0.1110 | **0.0322** | 0.0970 | 0.1195 | **0.0225** |

**The split collapses to 22.9% of itself when the rim stops being tan.**
Opaque pixel counts are identical between the arms (front 75,044 / back 75,648
in both), so nothing moved - the instrument changed one thing and measured it.

**AND I LOOKED AT THE PICTURES, WHICH IS THE PART THAT SETTLES IT.**
`A_shipped_aura_back.png` is a warm chocolate body; `B_white_rim_back.png` is
the same body in neutral grey-brown. The number and the picture agree.

## WHY IT IS NOT A FAULT, AND WHAT IT IS INSTEAD
The rim is `lordgen.add_lights`, the D75 rig that **all twenty-nine** bodies
and the lords and the twelve creatures share. It takes the creature's own
`aura` on purpose, so every body gets a back light in its own key. The Drover's
aura is tan because its yoke beam is ash. Change it for one body and that body
stops being comparable with the other twenty-eight on the contact sheet, which
is worth more than an even back.

**IT IS A FACT WORTH KNOWING RATHER THAN FIXING**, and the Paviser built this
morning is the first body to use it deliberately: its back view is half its
idea, so its aura is a pale cool (0.82, 0.84, 0.88) rather than a warm one, and
the man's back is lit neutrally instead of being washed tan.

One line, as asked: **the rig, not the material - the aura-coloured rim light
the back camera faces, worth 78% of the split, measured both ways.**
