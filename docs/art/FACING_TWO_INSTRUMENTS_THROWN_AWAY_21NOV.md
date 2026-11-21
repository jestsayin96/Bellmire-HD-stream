# FACING: TWO CANDIDATE ARMS BUILT, BOTH THROWN AWAY, AND WHAT THE PICTURE SAID
21 Nov 2026, 13:3x-13:4x CT. Art lane. No Blender - the bridge was down for the
whole run. Everything here is measured off the SHIPPED hero PNGs with numpy/PIL
on the Linux bridge, and everything judged was looked at.

## WHY I WENT LOOKING

The back-lamp guard asserts even light and a floor. Neither it nor the fit
register asks the question the team lead answered BY EYE on the Beadle: **does
the body say which way it is pointing?** A body with no facing passes every
number we publish. That is a blind spot in my own lane's harness, so I tried to
close it.

## ARM A - PALE-MATERIAL FRACTION, FRONT vs BACK. DISCARDED.

`renders/art/minibosses/_facing_candidate_DISCARDED.json`, all 46 bodies.
**It does not separate.** Median back/front ratio **1.10**; **27 of 46 bodies
read more pale from behind**. Back-heavy is the NORM. It would charge the leech
(6.92), the sluicekeeper (4.87), the hurdleman (3.33) and the greener (3.11) -
bodies nobody has criticised. Same confound the back-lamp guard already names:
it cannot tell a facing fault from a change of what is facing the camera.

## ARM B - SILHOUETTE IoU, FRONT vs MIRRORED BACK. ALSO DISCARDED.

beadle **0.922**, drillmaster **0.916**, leech 0.893, blower 0.817, dyer 0.806.
The Beadle does score near the top, which is the direction the team lead's eye
said - **but the drillmaster is within 0.006 of it and is not charged by
anyone.** A bar that catches the beadle catches the drillmaster with it. An
instrument that cannot be given a threshold is not an instrument.

**NEITHER ARM SHIPS. NEITHER IS A GATE.** They are published so the next seat
does not spend a cycle rebuilding them. Facing is still a LOOK verdict here.

## WHAT THE PICTURE SAID ABOUT THE BEADLE - A CARRIED CRITICISM, NARROWED

`renders/art/minibosses/_facing_look_21nov.png`, bottom row, is the beadle's own
front and back hero crops at 2x. The carried line is "the pale band carrying the
eyes wraps the head so the figure reads the same from front and back - it has no
facing". **On the currently shipped PNG that is true of the OUTLINE and false of
the VALUE.** Outline: IoU 0.922, hat, tray and staff identical - the silhouette
genuinely has no facing. Value: the front band is pale with two dark eyes and
brows; **from behind the same drum reads DARK, with no eyes and no brows** -
front pale fraction 0.228 against back 0.100. A viewer at stream distance who
can only see the outline gets no facing; one who can see the value does.
**I am not closing the criticism** - the silhouette half of it stands and I
measured it. I am saying which half, because "it has no facing" full stop is
not what the shipped picture shows.
