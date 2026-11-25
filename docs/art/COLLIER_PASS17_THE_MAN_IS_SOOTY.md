# COLLIER PASS 17 - THE OPERATOR IS SOOTY, AND HALF MY FIRST NUMBER WAS A SHADOW

25 Nov 2026, ART lane, the 13:34 CT firing. Plan row: **"TAKE THE OPERATOR,
BROWN-ON-BROWN WITH HIS CLAMP - your own pass-14 finding, carried two passes...
Measure the separation you actually have... at the 360p rung, on the real
render, with a control. If the honest fix is value rather than hue, say so."**

## WHAT I CHECKED FOR FIRST, MEASURED AND NOT REMEMBERED

Before modelling anything I read the shipped generator rather than my own fault
list. The cause was in the source and needed no render to find: the man's trunk,
both arms and his pot head are authored in the **`body` slot**, and the clamp he
stands on **is that same `body` slot**. He is not *similar* to his mound, he is
*the same colour as it*, and the only thing between them is the lambert term.
Nothing needed building. The collier already has its body, its renders, its
register row and its CANON entry - this pass makes no new geometry at all and
moves no vertex.

## THE FAULT, AS A NUMBER, FOR THE FIRST TIME

No instrument in this lane reported it and pass 15 said why in its own words:
every arm renders against the same dark background and measures the CUE, not the
man. `_backread` comes closest - it already asks the viewer's question through
one locked camera - but its value cell measures the man against HIMSELF and
never once against what is behind him.

**`tools/art/_opshot.py`** (Blender) re-uses `_backread`'s split exactly - same
verts, same slots, same materials, so the bounds and therefore the camera cannot
move - and shoots three frames per view through ONE locked camera: `B`
everything, `X` the man hidden, `Mo` the man alone.
**`tools/art/_brownread.py`** (Linux bridge) then partitions the man's visible
pixels **by what is behind them**, read off `X` at that same pixel:

* **ON-MOUND** - `X` has alpha, so he is in front of his own apparatus and the
  viewer must tell him from it by colour and value alone.
* **ON-AIR** - `X` has no alpha, so his edge is against background, where the
  silhouette does the work for free.

`dL = |luma(B) - luma(X)|` at the on-mound pixels is then the contrast the
viewer has to see through, and the renderer did the depth and the lighting.
Reported at `_streamscale`'s own rungs with `_streamscale`'s BOX filter
(760 -> 160 for 360p) so the numbers are comparable with pass 16's.

## MY OWN FIRST VERSION INVENTED HALF THE FAULT, AND I CAUGHT IT BY ASKING WHY A SWEEP DID NOTHING

The first `_brownread` used `changed & alone` - `_backread`'s rule, which is
right for `_backread`'s question and **wrong for this one**. Hiding the man also
changes pixels where **the mound is in front of him**, because he was shadowing
or occluding ambient on it, by one to three parts in 255 - which clears the
2/255 epsilon. Those pixels arrived in the on-mound column with a tiny dL and
read as *"the man is indistinguishable from his mound."* On the side view they
were **1701 of 3548 - just under half the evidence.**

I did not find this by inspection. I found it because the first soot sweep
barely moved the side number, I went looking for what those pixels were, and
`Mo`'s own luma at them said 0.116 while `B` said 0.383 - a man who is dark in
his own render and bright in the combined one is a man who **is not in that
pixel**. A soot value sized against that set would have been sized against a
shadow. (I also made a second, smaller error on the way: I first compared the
*surviving* bad pixels across arms, which is survivorship and says nothing. The
fixed-set comparison is what exposed the real cause.)

The honest rule asks which of the two the pixel actually looks like and still
lets the renderer do the depth: **the man is frontmost where `B` is nearer his
own render than it is to the render without him** -
`alone & changed & (|B-Mo| < |B-X|)`. `_brownlook.py`'s magenta overlay was
corrected the same way, so the picture and the number agree about which pixels
are being talked about.

## THE FIX IS VALUE, NOT HUE, AND THE ROW ASKED ME TO SAY WHICH

A hue move - greening or reddening the man off his own earth - is the
theatrical answer and **rule 1 forbids it: a thing looks like what it is FOR.**
What a charcoal burner looks like is **sooty**. So this is one multiplier on the
clamp's own earth colour, hue and saturation untouched, pulling him **down and
never up** - **rule 2** again, because the earth was dug this week and the man
has stood in the smoke of it since. He gets darker; nothing gets brighter.

Mechanically it is the **Greener's shipped vertex-colour path** (18 Nov), not a
new one: `OVERRIDE['collier']['body']` gains the fifth element, the slot's
colour comes off the mesh, and every piece of geometry that declares none - the
clamp, the spoil tail, the shovel haft - is painted the slot's own fill and
renders exactly as before. `_collier_soot` paints only the man, keyed off
`man_ranges(P)` - **the same declaration `_backread` and `_opshot` split on**, so
the geometry that gets the soot and the geometry the instrument calls "the man"
cannot drift apart. It raises rather than returning quietly if it paints nothing.

**THE CONTROL IS REAL AND IT WAS CHECKED, NOT ASSUMED.** `COLLIER_SOOT=1.0`
makes the vcol equal the slot fill, and all three views come out **byte for
byte identical** to the pre-change render: `maxdiff 0`, `0` of 577600 pixels
differing, front, side and back.

## THE SWEEP, AT THE 360p RUNG, BOTH SIDES OF THE LEDGER

`mnd` = the on-mound contrast (the fault). `u8` = the share of those pixels
under the 8/255 the stream scaler treats as "did not move" - i.e. the fraction
of him that IS the hill. `air` = the same contrast where his edge meets the
pane, which a value move can only hurt. `gap` = the luma distance between his
own dark cues (apron, hat, brow) and his own body, on the man-alone render -
the floor, because a man taken far enough down becomes one black lump.

| arm | side mnd_p50 | side u8 | front u8 | back u8 | side air_p50 | internal gap |
|---|---|---|---|---|---|---|
| **1.00 (pass 16)** | 0.1037 | **0.266** | 0.017 | 0.060 | 0.331 | 0.125 |
| 0.70 | 0.1192 | 0.088 | 0.006 | 0.000 | 0.283 | 0.108 |
| **0.55 SHIPPED** | 0.1255 | **0.022** | 0.006 | 0.000 | 0.257 | 0.101 |
| 0.40 | 0.1387 | **0.000** | 0.006 | 0.000 | 0.228 | 0.093 |

**THE NUMBERS WANT 0.40 AND THE PICTURE DOES NOT ALLOW IT** - the same shape as
pass 16's `COLLIER_FACE_SKIN`, which is some evidence the method travels. But
**the floor here is a gradient and not a break, and I am saying so rather than
borrowing pass 16's cliff**: nothing snaps at 0.40, the internal gap just keeps
sliding. So the stopping rule is a measured one. Gain per unit of internal
contrast spent: **1.00 -> 0.55 removes 92% of the fault for 0.024 of gap, a
ratio of 10.2. 0.55 -> 0.40 removes the last 8% for 0.008 more, a ratio of
2.75.** The return has flattened and the cost has not. It stops at 0.55.

If 0.55 is judged too dark on stream, `COLLIER_SOOT=0.70` is one env var and
still removes two thirds of the fault; `COLLIER_SOOT=1.0` is pass 16 exactly.

## IT REACHES THE GAME, AND THAT WAS CHECKED TOO

`lordlib.mat_vattr`'s own warning is that a material which renders here and
exports flat is the worst of the three outcomes, because only the renders would
show the fix. So I read the shipped `.glb`: `collier_body` carries **`COLOR_0`**
(7102 verts), its material `collier_body_ov` has **no `baseColorFactor`** (glTF
default white, so the vertex colour is not double-darkened), and the attribute
holds **exactly two distinct values** - `(0.165, 0.132, 0.104)` on 4586 verts
and `(0.09075, 0.0726, 0.0572)` on 2516. That is the fill and the soot, nothing
else. `collier.glb.import` is byte-identical to `greener.glb.import`, the body
that already ships this path.

## THE FIT PROOF, AND WHAT I CAN SEE IN IT

Rendered on the posed KayKit knight, idle, **front AND side AND back**, and I
looked at the sheet and at a 12x head crop at the rung.
`minibossgen --only collier`: **ok true, 73 bodies, errors `[]`, blank `[]`**,
4 meshes / 2903 tris, span 2.16 m CORRIDOR-SAFE, UNDER-LID.
`minibossfit --only collier`: **verdict GREEN, ok true, 64 rows, errors `[]`**,
blank failures `[]` over 186 files, collier ratio 0.86.
Blank-and-border check, read off the three shipped PNGs myself: opaque px
93689 / 83056 / 94941, **border max alpha 0.0 on all three** - nothing clipped.

**Faults I can see, and the first two are the price of this pass, not
pre-existing:**

1. **He is better separated from his mound and worse at being a man.** His
   apron, hat and fist are the `dark` slot, and I have moved his body toward
   them: the internal gap fell 0.125 -> 0.101. On the front the three stacked
   spheres that read as a torso now read more as one dark mass. This is a real
   trade and it is the cost side of the table above.
2. **The hat brim and pass 16's brow are converging.** At the 360p rung the brow
   IS still one solid bar - pass 16's result survives, I checked it on the
   picture and not on a number - but the light gap between the brim above it and
   the brow is thinner and darker than it was. The face is legible and weaker.
3. **The shovel haft is now the brightest thing on him.** It sits in the
   `shovel` span, not in `man_parts`, so it kept the mound's colour and now
   out-reads the man it belongs to. Pre-existing geometry, newly conspicuous.
4. **His head still has almost no facing** - pass 15's fault, untouched here.
5. **The fourth front vent still reads as a sliver and the count still reads
   THREE at 360p** - pass 13's, untouched here.

## WHAT THIS HARNESS STILL CANNOT SEE

**93-96% of the man's visible boundary is against the PANE, not against his
mound** - that is new, and it is the number pass 15's sentence was reaching for
("put him on a lit floor and that separation is not guaranteed"). This pass
fixes the tenth of his outline that touches his own mound. It does not and
cannot tell you what he does against a **lit background**, because every frame
here is shot against the same near-black world. The on-air column is the only
warning available: it falls 0.331 -> 0.257 on the side, so the soot costs him
real contrast against a dark pane while never crossing the threshold. Against a
bright corridor wall that margin is spent and the sign of the trade flips.
**An arm that shoots the body against a mid-value backdrop is the obvious next
instrument and this pass does not have it.**

Also: at the rung the side's on-mound partition is only ~90 px. It clears the
file's own scaled floor and the floor goes RED rather than green below it, but
it is a small sample and the front and back columns are carrying most of the
confidence.

## FILES

* `tools/art/_opshot.py` - new. The B/X/Mo shot, `_backread`'s split and all
  five of its RED guards, plus one of its own: an on-mound partition under the
  scaled floor is RED and never "clean".
* `tools/art/_brownread.py` - new. The partitioned contrast, both columns, at
  `_streamscale`'s rungs. RED on empty in both of its shapes.
* `tools/art/_brownlook.py` - new. The picture that decides: full-res crop, the
  360p rung, the under-threshold magenta overlay, and `X` so the eye can check
  that "behind him" really is his mound.
* `tools/art/minibosses.py` - `OVERRIDE['collier']['body']` goes vertex-driven;
  `_collier_soot` added and called from `collier()`.
* `renders/art/minibosses/_brown/` - the arms, the sweep sheet, the look sheets,
  the brow crop, `_brownread.json`.
* `renders/art/minibosses/collier/` + `assets/monsters/minibosses/collier.glb` -
  re-rendered and re-exported.
