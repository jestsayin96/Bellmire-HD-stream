# EVEN LIGHT, INSTALMENT 5 - THE RIG FIX INSTEAD OF A NINTH BODY

20 Nov 2026, ~22:34-23:0x CT. The team lead's row for this lane read:
"GROUND CONTACT IS NOW THREE INSTALMENTS OLD - you have called it rig-level
yourself twice. If instalment 5 can carry one rig fix instead of a ninth body,
I would rather have the rig fix." It can, and this is it.

## WHAT WAS ACTUALLY BROKEN

Nothing about the bodies. `minibossfit.shoot` renders with
`film_transparent = True` and **no floor object in the scene at all**, so every
subject in every cell has been standing on nothing since the file was written.
Instalment 3 named it on the sluicekeeper and the tanner; instalment 4 named it
on the greener's feet, the greener's frame legs, the dyer's four frame feet and
the dyer's vat. **Five namings, one fault, 44 bodies x 3 views.**

## THE OBVIOUS FIX IS DEAD, AND A RENDER KILLED IT - NOT A RELEASE NOTE

`tools/art/_el_ground_probe.py`. A cube on a plane, built three ways, alpha
read back with numpy:

| build | opaque px | partial | mean alpha |
|---|---|---|---|
| no floor at all | 2,000 | 376 | 0.0337 |
| plane with `is_shadow_catcher = True` | 31,488 | 768 | 0.48500305 |
| plane, plain opaque | 31,488 | 768 | 0.48500305 |

Blender 5.2.3 LTS, `BLENDER_EEVEE`. **`Object.is_shadow_catcher` EXISTS** -
`hasattr` returns True, so a hasattr guard would have passed and shipped - and
**EEVEE does not honour it**: the catcher row and the opaque row are identical
to the last digit. A shadow catcher here turns the cut-out into a white slab.
That is trap 5 in a new costume, and the only reason it did not land is that
the probe renders and reads pixels instead of reading documentation.

## SO THE SHADOW IS MEASURED, NOT CAUGHT

Per view, two extra renders of a white plane at the ground line (world z = 0,
the same z the camera's aim point already calls the ground): once **with** the
subjects, once with them **hidden**. `1 - with/without` is the occlusion and
nothing else. It is composited into the transparent film as dark semi-opaque
pixels **only where the beauty render is empty**, so the cut-out survives.

The edge and visibility rows are taken off the beauty film **before** the floor
pass runs, so turning this flag on cannot move a border count or a `seen`
score - only the pixels a viewer sees.

## PASS 1 WAS GREEN AND WRONG TWICE, AND THE A/B SAID SO

First build, greener and dyer, six views: verdict GREEN, 0 blanks, 0 clips,
`subject_px_touched` **0**, 5,353-10,458 new alpha px per view. Both faults
came out of the numbers, not out of my head.

1. **THE SHADOW WAS INVISIBLE.** Peak occlusion across all six views was
   0.2262 / 0.2051 / 0.2346 / 0.2409 / 0.2198 / 0.2345, mean 0.044-0.080. After
   grading, the darkest pixel reached alpha **0.12 of 255**. Not a bug: the
   display rig's fill and rim are AREA lamps `radius * 2.2` across - metres
   wide on these bodies - and a lamp that size casts a smear, not a contact.
   **Measuring the shadow off the lamps that light the picture cannot produce
   one you can see.** The floor pass now hides every lamp in the scene and
   switches on a single overhead SUN of its own. Occlusion of one lamp, nothing
   to divide out, nothing to grade. Straight down on purpose: the shadow then
   reads as standing from all three azimuths and does not move when the camera
   orbits. **Peak occlusion went 0.23 -> 0.7103-0.7107.** It stops at 0.71, not
   1.0, because the world background still lights the floor; that residue is
   real and I am not scaling it away.
2. **I ZEROED THE COLOUR OF EVERY TRANSPARENT PIXEL.** The `over` divided by
   alpha everywhere, so an untouched alpha-0 pixel came out RGB 0,0,0 instead
   of keeping Blender's background. Invisible over anything alpha-aware - and
   that is exactly why it matters: **my own diff reported 49,825-62,773 moved
   pixels against 5,353-10,458 of new alpha.** A gap that size with nothing
   visible behind it is the shape of a fault. Chasing it found this one. After
   the fix the same diff reads 5,099-6,930 - new alpha plus its antialiasing,
   and nothing else.

## AND THE CAVEAT I WROTE IS NOW CLOSED, NOT CAVEATED

Before rendering I wrote that the method would be blind in the antialiased rim,
where the floor pass is contaminated by the subject, and would leave a hairline
of unshadowed background hugging the silhouette. **I then cropped the greener's
front view at full resolution and looked**: it was real, 1-2 px, and it read as
the boots being *pasted onto* the shadow rather than standing in it. A caveat
nobody checks is an excuse. `dilate_into_rim` now carries the shadow one step
outward into exactly those partial-alpha pixels and nowhere else - it cannot
reach a pixel of alpha 1, and it cannot reach open background, where the
shadow is already measured. In the re-crop the hairline is gone.

## THE PROOF, AND WHAT I CAN STILL SEE WRONG IN IT

A/B on the two bodies the team lead named. Control = the shipped even-light
view. Treated = the same body, same everything, `--ground` added.

| body / view | new alpha px | mean new alpha /255 | subject px touched | peak occlusion | shadow at frame edge |
|---|---|---|---|---|---|
| greener front | 3,944 | 52.88 | **0** | 0.7103 | 0 |
| greener side  | 3,786 | 50.27 | **0** | 0.7107 | 0 |
| greener back  | 4,007 | 53.01 | **0** | 0.7103 | 0 |
| dyer front    | 3,099 | 56.22 | **0** | 0.7080 | 0 |
| dyer side     | 3,348 | 54.93 | **0** | 0.7077 | 0 |
| dyer back     | 3,644 | 52.66 | **0** | 0.7080 | 0 |

Composited over white, as a viewer meets it: the darkest new pixel reads
86-88 of darkness out of 255, mean 46.8-52.3. At those same pixels the control
reads **5** - near-pure white. There was nothing there before.

Verdict GREEN on both bodies, `errors []`, `blind_views []`, blank check 3 of 3
files per body, 0 failures. Border counts and `seen` scores are byte-identical
to the control by construction.

**I LOOKED AT `_el_gc_sheet.png` (six rows, before | after, over white, with a
2x zoom strip on the ground line) AND AT `_el_gc_crop.png` (greener front, full
resolution).** The knight stands. The frame legs, the vat, the trestle, the
planks and the scattered beads all take their own shadow. Faults I can see:

1. **The shadow is soft and broad, not a tight contact.** It pools about a
   body-width around the feet. It grounds the figure, but a crisper contact
   would need a smaller sun angle, and I have changed one thing this pass.
2. **The dyer's dye spills now read WORSE, and the fix is why.** They were
   already flagged in instalment 4 as decals - two pale ellipses with no
   thickness. Now that everything else on the floor casts something and they
   still do not, they read as stickers more plainly than before. The ground fix
   did not cause that fault; it stopped hiding it.
3. **It does not touch the two faults instalment 4 named.** The dyer still has
   no creature in its back view and the greener's man is still one flat dark
   mass. Those are value and composition faults, not rig faults.
4. Residual world-background light holds peak occlusion at 0.71, so no shadow
   in this rig is ever black.

## RED ON EMPTY

If the unoccluded floor render comes back with no opaque pixels, the view is
recorded as an `error` in the register, not as a clean zero shadow. A shadow
measured over nothing would otherwise read as a pass.

## THE DECISION THAT IS NOT MINE

`--ground` is **default OFF**, exactly as `--evenlight` was, because turning it
on changes every pixel of every cell. Adopting it is one command and about five
minutes of render - but it rewrites **132 shipped files**, and half-applying it
would give a contact sheet where some cells have floors and some do not. **I
have not adopted it.** The 18 bodies still on the old light (beadle, leech,
moulder, paviser, pressman, quartermaster, rammer, ratcatcher, reeve, relief,
scraper, sealer, sower, stackman, stoker, strickler, tapster, winder) should be
finished in the SAME pass that adopts the floor, so the set lands consistent in
one move rather than two.

## CORRECTIONS LANDED IN INSTALMENT 4 THIS PASS

Both were the team lead's, both are right, both are now in that file: the
exclusion recipe for 44 (it named `_ctl13`/`_el13` scratch directories that are
on no ref and omitted `drillmaster_tall`) is replaced with one that reproduces
on `origin/main` - 70 dirs, -13 containing `_chibi`, -9 `_`-prefixed, = 48,
-4 tag dirs, = **44** - and the lit-pixel range is corrected from
"43,8xx-43,9xx" to **43,78x-43,9xx**.
