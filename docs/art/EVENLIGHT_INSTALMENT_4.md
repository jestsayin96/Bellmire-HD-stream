# EVEN LIGHT, INSTALMENT 4 - EIGHT MORE BODIES, AND THE CLAIM I HAD BEEN
# MEASURING WAS THE WRONG ONE

20 Nov 2026, the 21:35 CT art firing. Same bound as instalments 2 and 3: all
three views on bodies already being re-rendered, under the 19:33 ruling.

**THE EIGHT:** comfitmaker, dauber, drover, dyer, fenman, fuller, greener,
hooper. 24 renders. Every body **GREEN**: `errors []`, `blind_views []`,
`blank_check` 3 files / 0 failures each = **24 files, 0 blanks, 0 frame
clips**, `errors []` on the batch.

## FIRST, THE COUNT - SETTLED, AND THE TWO DOUBTFUL BODIES MEASURED

Instalment 3 said "43 non-chibi bodies, 26 remain" and flagged honestly that it
had **not** checked whether the winder was authored even-lit. The team lead
asked for one number I can defend. Here it is, measured three ways that agree.

**44 non-chibi bodies** - `_report.json` `blank_check` 132 files / 3 = 44, and
a directory census of `renders/art/minibosses/` gives the same 44 once the 12
`_chibi` variants and the tag directories (`beadle_even`, `beadle_world`,
`ferryman_even`, the `_ctl13`/`_el13` scratch pairs) are excluded.

Dating every `hero_back.png` by the commit that last wrote it, against
`cf4ef984` (20 Nov 16:45:28 CT, where `--evenlight` entered `minibossfit.py`),
splits them 24 certainly-stale / 20 candidates. **But a date cannot close this
one, and that is different from instalment 1.** There the `drop` fix was
unconditional, so "written after it" meant "carries it". Here `--evenlight` is
**opt-in**, so a commit later than the switch may still have been rendered
without it. The date narrows the question; it cannot answer it.

So I answered it with pixels. Three bodies were genuinely in doubt - beadle,
winder, pitman. Each re-rendered with `--evenlight` into a `_p4probe` tag
directory, nothing shipped touched, and diffed against the shipped view:

| body | front | side | back | verdict |
|---|---|---|---|---|
| beadle | 86 px (0 over thr) | 78,934 | 102,469 | **NOT even-lit** |
| winder | 89 px (0 over thr) | 89,824 | 103,629 | **NOT even-lit** |
| pitman | **0** | **0** | **0** | **already even-lit** |

**The instrument returns zero when the answer is zero.** The pitman row is the
proof that it can - it was authored with the switch on tonight, and the probe
says so in the only currency that counts. A probe that could never print 0
would have proved nothing about the other two.

**THE NUMBER: 18 of 44 are even-lit, 26 REMAIN.** Even-lit = ferryman (the
first) + instalment 2's eight + instalment 3's eight + pitman. The remaining 26
= the 24 pre-cutoff bodies + **beadle** + **winder**. Instalment 3's "26"
happens to be the same integer, but it was 26 over a 43-body set with the
winder unresolved; this 26 is over 44 with every member named. After this
instalment lands its eight, **18 remain.**

Incidentally the three probe fronts move by 86, 89 and 0 pixels with nothing
over the difference threshold - a third independent confirmation that even
light does not move the front, which is the premise the whole ruling rests on.

## THE CLAIM, MEASURED - AND ONE BODY GOES THE WRONG WAY

Per instalment 3's method, mean saturation over lit pixels on the back view,
with warm fraction as the second reading:

| body | sat before -> after | warm frac before -> after | mean lit RGB after |
|---|---|---|---|
| comfitmaker | 0.335 -> 0.204 | 0.662 -> 0.244 | 116,98,98 |
| dauber | **0.219 -> 0.228** | 0.216 -> 0.216 | 114,96,100 |
| drover | 0.258 -> 0.187 | 0.323 -> 0.218 | 96,81,80 |
| dyer | 0.551 -> 0.378 | 0.224 -> 0.251 | 96,89,104 |
| fenman | 0.263 -> 0.219 | 0.200 -> 0.200 | 104,87,90 |
| fuller | 0.196 -> 0.157 | 0.149 -> 0.122 | 105,93,93 |
| greener | 0.414 -> 0.276 | 0.251 -> **0.418** | 118,95,92 |
| hooper | 0.276 -> 0.239 | 0.213 -> 0.296 | 118,98,99 |

Saturation falls on **7 of 8**. It **RISES on dauber**. Warm fraction rises on
three. On the instalment-2 and instalment-3 statement of the claim - "even
light takes the wash out, so saturation falls" - **dauber is a failure and
greener is half a failure.** I did not want to report it that way without
understanding it, and understanding it turned out to mean the claim was stated
wrongly in both earlier instalments, including by me.

## THE REFERENCE BODY - THE TEST I SHOULD HAVE BEEN RUNNING ALL ALONG

Looking at the contact sheet, not the table: **the reference adventurer standing
beside each miniboss reads BLUE in the dyer's frame and GREEN in the greener's
frame.** It is the same mesh with the same material in all eight frames. Its
colour cannot be its paint. It can only be the light.

That is the viewer's question and the per-frame saturation number cannot ask
it: saturation reads one frame alone and has nothing to compare it to. So
measure the reference instead - isolate the rightmost opaque column-run (the
reference stands clear of the miniboss) and read its mean lit colour in every
frame. **Isolation is checked, not assumed:** the band must be separated by a
real column gap, and the band came out 180 px wide with 43,8xx-43,9xx lit
pixels in all sixteen reads, before and after. A band that had swallowed
miniboss geometry would not hold that count. If no gap exists the body is
reported UNRESOLVED and excluded rather than measured as a merged blob; none
of these eight hit that.

| body | reference RGB before | reference RGB after |
|---|---|---|
| comfitmaker | 121,81,69 | 123,88,91 |
| dauber | 114,84,85 | 125,89,93 |
| drover | 114,78,76 | 122,86,90 |
| dyer | **75,67,90** | 122,87,92 |
| fenman | 108,82,91 | 123,87,91 |
| fuller | 120,85,84 | 122,86,89 |
| greener | **71,82,77** | 123,88,92 |
| hooper | 103,82,91 | 123,88,92 |

**Channel spread across the eight frames: R 50 -> 3, G 18 -> 3, B 22 -> 4.
Mean saturation spread 0.172 -> 0.012.** One body, one material, eight frames,
and after the pass it reads the same in all of them to within three or four
levels.

**SO THE CLAIM IS NOT "SATURATION FALLS". IT IS "THE FRAMES CONVERGE ON ONE
LIGHT."** Even light is a **normaliser**, not a desaturator. Where a frame was
over-washed it takes colour out; where a frame was *under* its own standard it
puts colour in. That is exactly dauber: its body saturation rose 0.219 ->
0.228, and its reference rose too, 0.340 -> 0.348, landing on the same 0.35
every other frame landed on. **Dauber is not the claim failing. It is the claim
working in the direction the earlier statement of it could not express** - and
the reference instrument is the only one of the three that can tell those two
apart. The reference saturation rises on 3 of 8 and converges on 8 of 8.

Anyone carrying instalment 5: instalment 3 warned not to reach for warm
fraction alone. Add this - **do not reach for the direction of saturation
either.** Measure the reference body across frames. It moves, it can print a
null, and it answers what a viewer actually sees.

## THE WASH HAS A THIRD COLOUR

Instalment 2's washes were brown. Instalment 3 found a blue one on the
sluicekeeper. **The greener's was GREEN** - reference 71,82,77, green-dominant,
and its warm fraction *rises* 0.251 -> 0.418 as the green comes out. The dyer's
was blue (75,67,90), the deepest wash in four instalments. Three wash colours
now, which is why no single hue test can stand as the instrument.

## WHAT I LOOKED AT, AND WHAT IS WRONG IN IT

Contact sheet `renders/art/minibosses/_el_inst4_sheet.png`, before | after, all
eight back views; greener and dyer opened at full size. The gain is real and
visible: on greener the linen sheets go from green-stained to pale and the
beads read as separate; on dyer the frame timber reads as wood and the blue and
red cloths separate instead of sitting in one blue field. Faults I can see, and
most are not new:

1. **THE DYER HAS NO CREATURE IN ITS BACK VIEW.** From behind it is a drying
   frame and a vat; the man is a sliver of dark behind the leftmost cloth.
   Nothing in the register can see this - green, 3 proving views, no blanks, no
   clips. This is the Beadle-facing fault in another shape: the harness scores
   the frame, not the read. Not fixed here - named, and it is the first thing
   the dyer's next pass should answer.
2. **THE GREENER'S MAN IS ONE FLAT DARK MASS.** Torso, arms and legs share a
   near-black value, so from behind the body reads as a stand for the sheets.
   Same family as instalment 3's bellman note.
3. **GROUND CONTACT IS STILL MISSING AND STILL INCONSISTENT - THIRD INSTALMENT
   RUNNING.** The greener's feet, the greener's frame legs, the dyer's four
   frame feet and the dyer's vat all sit on white with no shadow. Instalment 3
   named this on the sluicekeeper and tanner. It is a rig-level fault, not a
   per-body one, and it will keep appearing until the rig is fixed.
4. **The greener's head is a capstan.** From behind, a small dark drum with a
   flat disc on top. No head shape at all.
5. **The dyer's dye spills read as decals.** Two pale ellipses on the ground
   with no thickness and no shadow - stickers on white, not spills on a floor.
6. **Both have a pole cut in two by a cloth** - the greener's tool handle and
   the dyer's red stir-pole each vanish behind a hanging sheet and re-emerge,
   reading as two separate sticks.

None of these is a blank and none is a frame clip, which is the point of
writing them down: the harness is green on all eight.

## A SIDE RESULT THAT VALIDATES INSTALMENT 1 ON NEW DATA

The front-view diffs in this batch were not needed for the claim, but they test
instalment 1's date argument on eight bodies it never measured. Instalment 1
predicted which fronts were stale against the `drop` fix. In this batch the
fronts of comfitmaker, drover, dyer, fenman and greener moved by 93k-162k px -
all five are on instalment 1's STALE list. The fronts of dauber, fuller and
hooper moved by 54, 93 and 56 px, antialiasing only - **all three are on its
CURRENT list. Eight for eight.** The date argument discriminates.

## COUNT AFTER THIS INSTALMENT

44 non-chibi bodies. 26 were on the old light at the start of this firing;
these eight land, so **18 remain**: beadle, leech, moulder, paviser, pressman,
quartermaster, rammer, ratcatcher, reeve, relief, scraper, sealer, sower,
stackman, stoker, strickler, tapster, winder. That list is the whole remainder,
named, so instalment 5 does not have to re-derive it.
