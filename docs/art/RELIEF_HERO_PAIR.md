# THE WATCHTURN (relief) - THE HERO PAIR, AND WHAT THE REGISTER CANNOT SEE
20 Nov 2026, 14:5x CT. ART lane. Plan row 2 of the 13:58 block.

WHAT WAS OWED: the Relief shipped with front/side/three_quarter and NO hero trio and
NO register. Floor geometry (`_report.json fits: true`) is not the on-a-body test.
It now has both: `renders/art/minibosses/relief/hero_front|hero_side|hero_back.png`
and `_fit_relief_register.json`.

THE NUMBERS (minibossfit, BLENDER_EEVEE): verdict GREEN, errors [], creature_h 2.52
against hero_h 2.45 -> ratio 1.03, pair_w 3.61, fits_frame true. 3 of 3 views proving.
Blank check 3 files 0 failures. Frame-edge alpha 0 on all four edges of all three views.

THE PICTURES, LOOKED AT. All three. The back view is the one that was missing and it
is the one that answers the row: THE WATCHTURN HAS A FACING. From behind there is no
face, no pale eyes, and the chest brace is replaced by a small dark mark on the back.
This is NOT the Beadle fault.

*** BUT THE SILHOUETTE HAS NO FACING, AND I MEASURED IT RATHER THAN SAY IT READS. ***
Creature-alone front against the creature-alone back MIRRORED, aligned on bounding box:
  silhouette IoU = 0.898
  of the 39,369 pixels the two silhouettes share, 61.4% differ in colour.
Read it the honest way round: the OUTLINE is the same from front and back (0.90), and
only the SHADING tells them apart. At stream distance, where a viewer reads outline
before shading, the Watchturn's front and back are close to the same picture. That is
a weaker claim than "it has a facing" and it is the true one.

THREE FAULTS I CAN SEE AND NO NUMBER IN THE REGISTER REPORTS:
  1. SIDE VIEW - the figure is a thin slab in profile. Front it is a broad gauge-keeper;
     from the side it is a post with a kettle hat. The capstan carries that view, not him.
  2. SIDE AND BACK - the arm bar runs into the capstan drum and the hand end is lost:
     pale on pale, same family as the Beadle's staff knob against its own pale panel.
  3. BACK - the back of the body is a near-blank grey panel. The gauge at the foot (the
     notches, the dog in the ratchet plate) is the Watchturn's whole read and from behind
     the base ring plates are small and low. The identifying detail is in front of him.

*** WHAT THE INSTRUMENT CANNOT SEE, SAID BEFORE IT IS TRUSTED. ***
`visibility.seen` is 1.0 on all three views and that is NOT a green for any of the above.
It measures ONE thing: hero-against-creature occlusion, by rendering each alone and
counting the pixels that moved. It has no opinion on a creature's parts hiding EACH OTHER
(fault 2 is exactly that, and it scores 1.0), none on silhouette sameness between views
(fault 1 and the IoU), and none on where a body's read lives (fault 3). A register that
says 1.0 three times says the hero and the creature do not hide one another. Nothing more.

ALSO DONE, ONE COMMAND, BECAUSE THE GAME BUILD'S LIVE ROW NEEDS IT: the Hooper had the
hero trio but NO register - I listed all 22 and confirmed the absence rather than assume.
`_fit_hooper_register.json` now exists: GREEN, errors [], ratio 0.96, pair_w 3.24,
3/3 proving, 0 blanks, 0 frame-edge pixels. Looked at hooper/hero_back.png: hoop stack,
banded cask, two legs on two feet, no face from behind. It has a facing.
