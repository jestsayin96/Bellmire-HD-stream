# THE VALUE PASS ON THE RATCATCHER AND THE BOILER
21 Nov 2026, 02:35-03:15 CT. The 00:58 plan row's remaining half: "`ratcatcher`
and `boiler` (near-black on near-black and pale on pale)". The `dyer` and
`greener` backs, the first half of that row, were ticked at 01:58.

## WHAT I CHECKED FOR FIRST, MEASURED NOT REMEMBERED

Both bodies already exist and are shipped. Nothing was modelled from scratch
and no pack was reached for. The whole run is a defect fix on two bodies this
lane shipped, which the plan says the freeze does not touch.

The register could not see either fault and still cannot: `_fit_report.json`
scores every cell of both keys at `seen: 1.0` across front, side and back,
0 frame edges, `fits_frame: true`. That number asks "how much of THE CREATURE
survives the hero", and the creature is the man AND his apparatus - so a man
drowned in his own props, or a man the same colour as them, scores a perfect
1.0. This is trap 5 in the same coat the dyer wore.

## THE INSTRUMENT

`tools/art/_backread.py`, unchanged, run first on the bodies AS SHIPPED
(`_backread_pre.json`) and again after each change. It renders three frames
through ONE locked camera per view - everything, the man hidden, the man alone -
counts the pixels that MOVED, and reports the luma of only those pixels. It
asserts the world bounds are identical between the split build and the control
build, so nothing below is a camera that moved.

`boiler` had no `man` span, so it could not be measured at all. It has one now.
Its two arms and his hand were authored after the pan and the skimmer and a
span is a contiguous range, so they moved up the function. The geometry is
unchanged and `_backread`'s own bounds assertion is what says so.

## THE RATCATCHER - ONE CHANGE

`OVERRIDE['ratcatcher']['body']` 0.078 -> 0.156 (x2.0), nothing else touched.

The 0.078 was deliberate and the argument behind it - dark man, pale willow,
contrast carries the outline - is still right and is NOT reversed. What was
wrong is how far it was taken. At 0.078 albedo:

  - his side view scored **2 value bands**, which is this document's own
    definition of one flat mass
  - **half** of his front-view pixels sat under 0.20 luma
  - his boots and cap band are `dark` at 0.038, so his one internal line was
    0.078 against 0.038 - no boundary at all at stream distance

| view | man p50 | spread | dark_frac | bands |
|---|---|---|---|---|
| front | 0.200 -> **0.273** | 0.202 -> 0.248 | 0.500 -> **0.265** | 3 -> **2** |
| side  | 0.247 -> **0.336** | 0.148 -> 0.195 | 0.232 -> 0.150 | 2 -> **3** |
| back  | 0.251 -> **0.347** | 0.224 -> 0.307 | 0.198 -> 0.160 | 3 -> **4** |

**THE FRONT BAND COUNT WENT DOWN, 3 TO 2, AND I AM NOT BURYING IT.** Lifting the
body moved a block of pixels out of the lowest eighth and into the band the rest
of him already occupied, so the histogram got *less* spread even though the man
got *more* readable. The picture and the number disagree and the picture is the
evidence: in `_valuepass/ab_ratcatcher.jpg` the top row is a black cut-out and
the bottom row has a cap band, a stooped torso, two arms, two legs and two boots
you can tell apart. `bands_5pct` over an 8-bin histogram cannot see a boundary
that lands inside one bin, and that is a limit of the instrument, not a reason
to restate the fix as a regression.

He is still 4.6x darker than the willow (0.129 luma against 0.598) and now 3.4x
lighter than his own boots.

## THE BOILER - TWO CHANGES, AND THE FIRST ONE NEARLY DID NOTHING

With tint (0.86,0.60,0.34) and wear 0.25 the generator derives `body` at luma
0.510 and `bone` at 0.577 - **0.067 apart**. The man's limbs, his apron, his
head, the pan rim, the skimmer and the pool ring were one value BY
CONSTRUCTION. No lighting separates two materials that are the same colour.

**CHANGE 1** - an override: `body` to dark boiled leather (0.205,0.138,0.090),
`dark` down to 0.043 so it would not collide with the new body; `bone` and
`glow` deliberately untouched so the copper and the sugar keep their end. The
pan dish and the skimmer blade moved `body` -> `bone` so the apparatus would not
follow the man down. `boiler` was added to `OVERRIDE_ALLOWED`, which is a list
whose whole purpose is to stop an override being pointed at an already-shipped
key: this one is the plan's charge, not a drive-by, and it is flagged here.

**IT MOVED THE FRONT MEDIAN BY 0.019.** 0.628 -> 0.609 on a 3.3x albedo drop.
The A/B frame says why and the numbers did not: his apron is the LARGEST
surface he shows from the front and the back, and it was in `bone` with the
pan. He could not leave the pale band while his chest was still in it. (Part of
the rest is that the override also drops metalness 0.36 -> 0.03, and a diffuse
surface at a given albedo renders brighter than a metallic one, so some of the
albedo cut was spent buying it back.)

**CHANGE 2** - the apron leaves `bone` for `body`. It is cloth, not copper. His
head stays `bone` on purpose: a pale head over a dark apron is the one internal
line that says where he is looking.

| view | man p50, shipped -> change 1 -> change 2 | man_seen |
|---|---|---|
| front | 0.628 -> 0.609 -> **0.404** | 0.990 |
| side  | 0.598 -> 0.591 -> **0.575** | **0.706** |
| back  | 0.570 -> 0.563 -> **0.540** | 0.994 |

## STILL OPEN ON THE BOILER, FOUND THIS RUN AND NOT FIXED

**29% OF THE MAN IS HIDDEN BY HIS OWN PAN AND PLUME ON THE SIDE VIEW**
(`man_seen` 0.706, against 0.990 front and 0.994 back). The register reads
`seen: 1.0` on that same cell. This is geometric, not a value fault - the pan
and the pour stand between the side camera and the man - and no change in this
run touched it: 0.704 shipped, 0.706 after both changes. The side view is where
this creature reads worst and it is the next thing to take on this body.

The side value median also barely moved (0.598 -> 0.575) for the same reason:
the apron is edge-on from the side, so change 2 bought almost nothing there.

## WHAT MY HARNESS STILL CANNOT SEE

- `bands_5pct` is 8 fixed bins over the full 0-1 range. A real boundary inside
  one bin is invisible to it, and it counted the ratcatcher's fix as a loss.
- `_backread` renders under `even_lights` against a dark grey world. The
  SHIPPED `hero_*.png` use the fit rig, whose back view is lit warmer than its
  front and side - visible on both bodies, pre-existing, not from this run, and
  the even-light instalments are the thread that owns it.
- Nothing here measures the creature against a DUNGEON FLOOR. Both bodies are
  judged against a dark ground and a transparent frame.
