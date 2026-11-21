# EVEN LIGHT, INSTALMENT 3 - EIGHT MORE BODIES, ALL THREE VIEWS

20 Nov 2026, the 20:34 CT art firing. The 19:33 ruling is *all three views on
bodies already being re-rendered*; instalment 2 shipped eight at 20:07. This
is the next eight, same bound, same shape.

**THE EIGHT:** bellman, boiler, hurdleman, jointer, loader, sluicekeeper,
snarer, tanner. All eight were last written by `de49e9f3` or earlier - they
are in the stale-front set of 28 found at 18:34, so this pass lands the
even light AND the `drop` vertical-aim fix on the same frames.

24 renders. Every body **GREEN**: `errors []`, `blind_views []`,
`blank_check` 3 files / 0 failures each = **24 files, 0 blanks, 0 frame
clips**.

## THE CLAIM, MEASURED BEFORE AND AFTER ON EACH BACK VIEW

Not "pixels moved" - pixels always move. Mean saturation over lit pixels,
warm-pixel fraction, and mean lit colour, shipped vs new:

| body | sat before -> after | warm frac before -> after | mean lit RGB after |
|---|---|---|---|
| bellman | 0.238 -> 0.214 | 0.199 -> 0.200 | 128,112,116 |
| boiler | 0.297 -> 0.246 | 0.554 -> 0.408 | 138,114,113 |
| hurdleman | 0.198 -> 0.174 | 0.130 -> 0.131 | 108,99,100 |
| jointer | 0.290 -> 0.252 | 0.587 -> 0.358 | 122,99,97 |
| loader | 0.288 -> 0.223 | 0.487 -> 0.229 | 117,97,97 |
| sluicekeeper | 0.375 -> 0.223 | 0.169 -> 0.172 | 118,106,111 |
| snarer | 0.343 -> 0.228 | 0.576 -> 0.239 | 124,103,104 |
| tanner | 0.224 -> 0.190 | 0.485 -> 0.202 | 132,115,113 |

**Saturation falls on 8 of 8. Warm fraction falls on 6 of 8 and is FLAT on
bellman and hurdleman.**

## THE FINDING: THE WASH IS NOT ALWAYS A WARM ONE

Instalment 2 was measured with warm-pixel fraction, and on those bodies it
worked - the back wash there was brown. **On sluicekeeper the warm fraction
does not move at all (0.169 -> 0.172) and the fault is still the largest in
this batch**: its saturation falls 0.375 -> 0.223, and its shipped back view
was a *blue* wash - mean lit colour 88,99,110, blue-dominant. A warm-pixel
test alone would have passed sluicekeeper as "nothing to fix" and been wrong.

So the instrument for this work is **saturation over lit pixels**, with warm
fraction as a second reading that says which way the wash leaned. I have used
both here. Anyone carrying instalment 4 should not reach for warm fraction
alone.

## WHAT I LOOKED AT, AND WHAT IS WRONG IN IT

Contact sheet `renders/art/minibosses/_el_inst3_sheet.png`, before | after,
all eight back views - plus sluicekeeper and tanner opened at full size.
The gain is real and visible: on sluicekeeper the wheel spokes separate from
the gate and the hood reads darker than the arms; on loader the stack reads as
separate slabs instead of one olive mass; on snarer the hoops read pale
against a dark figure. Faults I can see, and they are not all new:

1. **tanner - PALE ON PALE, THE SAME FAULT I WROTE UP ON THE RELIEF AND
   REPEATED ON THE SCRAPER.** The two pegged hides are nearly the frame's own
   value; they read by ragged outline only. Even light made this slightly
   WORSE by lifting the frame toward the hides. The hides want a darker,
   wetter value than the timber. Not fixed here - named.
2. **GROUND CONTACT IS INCONSISTENT INSIDE ONE BATCH.** The sluicekeeper's man
   gets a soft contact shadow; the sluice frame beside him gets none, and its
   four feet sit on nothing. The tanner gets no shadow at all. Same rig, same
   pass.
3. **bellman back is one flat value.** The cone is a large smooth grey
   triangle with no interior form; the body reads by silhouette alone. This is
   why its saturation barely moved - there was little hue there to take out.
   Not a regression; a body that even light cannot help.
4. **tanner's bench ends in mid-air** behind the frame - a floating plank edge.
5. **tanner's head reads as a knob** from the back, not a head.

None of these are blanks and none are frame clips, which is exactly the point
of saying them: the harness is green on all eight and these five are things
the harness cannot see.

## COUNT

43 non-chibi bodies. The team lead's count after instalment 2 was **34 still
on the old light** (43 less ferryman, the first ever rendered with
`--evenlight`, less instalment 2's eight). This instalment takes eight of
those, so **26 remain**. I have NOT verified whether the 43rd (winder, built
at 20:01) was authored under the even-light rig; if it was, the real number is
25. I am reporting the number I can defend.
