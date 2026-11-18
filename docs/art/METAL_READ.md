# DOES A MATERIAL READ AS WHAT IT IS? - the Greener's copper, and the instrument

ART lane, 17 Nov 2026. Taking the team lead's 21:05 offer to spend the firing on
*fault 1* - "the copper leaves still read as brown planks, open fault, not
fixed, and it is the weakest thing on the body" - rather than on a twenty-sixth.
His reason, and it is the right one: *a material that reads as what it is serves
every future body with copper, brass or iron on it; a twenty-sixth serves one.*

## THE FAULT IS NOT CLOSED. SAYING SO FIRST.
The leaves still do not read as copper. What this run did was find out WHY three
passes failed, build an instrument that can tell, and fix the half of the fault
that turned out to be the real cause. The verdict line still says
**READS AS TIMBER** and I am not dressing it up.

## WHY THREE PASSES FAILED, MEASURED
Passes E, J and 5 all moved the same three dials - base colour, roughness,
metallic - and all three came back timber. The controls in
`tools/art/_metal_read.py` say why, and the answer is that the dial the lane
kept reaching for was **backwards**:

| surface (greener/side)      | spec_peak | spec_range | mobility |
|-----------------------------|-----------|------------|----------|
| matte oak control           | 0.4865    | 0.3958     | 0.5505   |
| physically-correct copper   | 0.2075    | 0.0233     | 0.0064   |

Real polished copper is **darker, flatter and all but immobile** in our rig, and
oak is the bright lively one. That is not a broken control, it is the physics.
A fully metallic surface has no diffuse term, and `lordgen.render_views` sets
the world to (0.045, 0.05, 0.065) with `film_transparent`, so the only thing in
the environment is two SUN lamps about half a degree across. **A mirror in an
empty room is black.** In Principled a metallic lobe is also tinted by the base
colour, so a half-metallic copper leaf can never produce a white highlight.

So every step toward "more metal" took the surface nearer a dead plate, the lane
compensated by brightening the base colour, and a bright hue carried by a
diffuse term on a smooth sheet **is painted wood**. The dials were never going
to get there.

> **REGISTER-WIDE:** in this rig METALLIC IS NOT A DIAL THAT BUYS A METAL LOOK.
> It is one that spends it. Any future body with copper, brass or iron on it
> should reach for a dielectric lobe with a high specular level, not for
> `metallic`.

## THE INSTRUMENT, AND THE TWO AXES IT THREW AWAY
`tools/art/_metal_read.py`. The mask is what a viewer can SEE - the span is
rendered in and then out through one fixed camera and the moved pixels are the
material - never the group alone, which is the `head_glow_px: 156` mistake this
lane already made once. The bar is NOT mine: it is measured off the **CC0 KayKit
dungeon weapons already in this repo**, under our own lights. Those are
third-party artist metals that demonstrably read as metal.

**Two axes were built and both were abandoned on evidence, which is the useful
part of this file.** Highlight peak/range/mobility, and then high-frequency
speckle, both put the references on the same side as *darker and flatter* - the
KayKit metals measure speckle 0.006-0.019 against oak's 0.077, so "be smoother"
would have scored as "be more metal". **A metric that rewards the wrong change
is worse than no metric.** My own first hypothesis - hammered facets make metal
- was refuted by the ground truth before I spent a pass building it.

The axis that survived is **highlight desaturation**: how much whiter the bright
end is than the body of the surface. It is physics rather than taste - a
specular reflection carries the LIGHT's colour, so a metal's highlight runs to
white while a pigmented surface keeps its hue all the way up. It separates
cleanly: KayKit metals 0.305-0.574 (median 0.441), oak 0.209.

It goes red on empty (absent span, empty span, mask under 400 px, no reference
given), and it **goes red on its author**: it failed its own first run, because
span `plates` holds the copper AND the dark rack and a whole-span mask would
have measured the rack as copper.

## WHAT ACTUALLY FIXED THE HALF THAT GOT FIXED: FORM, NOT MATERIAL
The A/B render is what stopped the dial-chasing. Material alone, best case,
traded *stained plank* for *raw cardboard* - a lateral move, and I was not going
to ship one as a fix. Putting the two sheets side by side named the real cause,
which no number had found:

**At w 0.46 on a 0.095 pitch the five leaves overlapped by about 80%.** They did
not read as five sheets. They read as ONE SOLID PANEL whose only internal detail
was the seams between them - and a flat rectangle with evenly spaced vertical
grooves is a crate side. *That* is what a viewer was naming. Pass 4 had already
tried to break it with yaw, and yaw cannot help when the sheets are flush.

Pass 8 spreads the pitch to 0.175, varies each leaf's width and height, and
staggers the tops in Z. Narrow sheets with air between them read as stock
leaning in a rack; a flush stack reads as a pallet. **This is visible in the
render and it is the one thing in this run that is genuinely better.**

## THE NUMBERS, EACH CHANGE MEASURED SEPARATELY
Axis: oak = 0.00, KayKit artist metal = 1.00.

| pass                               | front  | side   | back   |
|------------------------------------|--------|--------|--------|
| as shipped (baseline)              | -0.15  | -0.15  | -      |
| material alone (pass 6, dielectric)| +0.092 | -0.005 | -0.072 |
| material alone (pass 7, rough up)  | +0.158 | +0.040 | +0.008 |
| **form alone (pass 8)**            | -0.132 | -0.082 | -0.172 |
| **form + material (pass 9, shipped)** | +0.159 | +0.203 | +0.035 |

Form alone correctly does NOT move the material read - the metric is isolating
what it claims to. And the form change is what let the specular work: the side
view goes +0.040 -> +0.203 with the same material, because five sheets at five
angles with air between them give a white sheen five chances to catch an edge
where a flush panel gave it one.

**All three views now sit above the oak control where all three were at or below
it. None of them is near the artist bar.** Verdict stands at READS AS TIMBER.

## WHAT IS LEFT, AND THE NEXT CHANGE NAMED
The remaining gap is the **environment**, and it is not mine to close alone.
With a near-black world there is nothing for a metal to reflect, so a flat-shaded
procedural sheet cannot reach a KayKit weapon's highlight - those carry a baked
texture with painted near-white highlight bands, which is a different mechanism
from anything a BSDF can do here. Two candidate fixes, neither taken in this run:
  1. **Bake the highlight into the leaf** as vertex colour (vertex colours
     survive glTF export; a Blender shader-node network does not), which is what
     the reference metals do and is local to one body.
  2. **Give the rig something to reflect.** This re-lights all 25 bodies and
     invalidates every colour number the register has measured, so it is a
     team-lead call and not one I will take unilaterally.

## THE TWO ONE-LINE ANSWERS HE ASKED FOR
1. **Do the Dyer's hung cloths survive the side view, or do flat planes vanish
   edge-on?** THEY SURVIVE, measured, not guessed: `sheets` moves 0.494 of the
   silhouette front and **0.295 side** - 60% of its front read, not zero. Flat
   planes do not vanish here because the Dyer's planes are bowed in the hanging
   axis, which was the Pressman's fix carried forward. The Dyer's whole trade
   holds at 0.58 side against 0.748 front.
2. **Is the Greener's scraper pole meant to cross the body?** The diagonal is
   DELIBERATE; its loudness is not. The shaft is defined once, travelling in X
   AND Y AND Z, so the front camera gets a diagonal out of X and the side camera
   gets one out of Y - written that way to dodge the Pressman fault, where a
   shaft that only travels in X is a vertical post from the side. So the lead is
   right that it is the loudest line in its own picture and right that nobody
   weighed that cost against the fault it was avoiding. **It should be
   shortened, not re-aimed** - re-aiming it brings the Pressman fault back.

---

# PASS 10, 18 Nov 2026 - THE NAMED CHANGE WAS MADE, IT PASSED, AND I AM NOT
# TAKING THE PASS. THE CAUSE IS ONE LAYER FURTHER DOWN AND IT IS MEASURED.

## WHAT I DID FIRST, MEASURED RATHER THAN REMEMBERED
This file's own candidate 1 - "bake the highlight into the leaf as vertex
colour, which is what the reference metals do and is local to one body". Built
it, and it works mechanically: the five leaves carry a per-vertex ramp (deep
copper in occlusion, the shipped copper through the body, a warm near-white
sheen band), the band is placed by the RIG'S OWN LIGHTS rather than by my
taste, and the colour goes straight from a Color Attribute into Base Color.

**THE SCORE WENT FROM 0.159 / 0.203 / 0.035 TO 0.971 / 0.528 / 0.962 AGAINST A
BAR OF 0.50. THE INSTRUMENT SAID READS AS METAL ON ALL THREE VIEWS.**

## THEN I LOOKED AT THE RENDER AND THE RENDER DISAGREED WITH MY OWN NUMBER
`renders/art/minibosses/_metal_ab_rack_crop.png` - pass 9 on top, pass 10
below, cropped automatically to the pixels that actually differ between the two
builds, so the crop cannot flatter the change.

The sheets still read **TAN**. They do not read as copper. What the ramp
genuinely bought is per-sheet VALUE VARIATION, which helps the pass-8 "five
sheets, not one board" read and is visible in the picture. What it did not buy
is the thing the fault names.

**AND THE REASON THE NUMBER MOVED IS THAT I PAINTED THE NUMBER'S ANSWER INTO
THE MESH.** `hilite_desat` asks "is the bright end whiter than the body of the
surface". I baked a near-white band into the brightest vertices. A painted
stripe satisfies that question by construction. On the CC0 reference metals the
same question is fair, because their near-white bands ARE painted and that IS
how they read as metal - but it means the metric cannot tell a reflection from a
decision, and I made the decision.

This is the third time this lane has caught a metric answering a different
question than the sentence beside it (`head_glow_px: 156`; the glove centre-band
occupancy). So the harness now goes red on its author: when a span's slot is
vertex-painted, `_metal_read` reports the score, names it
**PAINTED - NOT EARNED AS REFLECTION**, and refuses to pass on it.

## THE REAL CAUSE, AND IT IS NOT THE MATERIAL. IT IS THE VIEW TRANSFORM.
`lordgen.set_engine` sets the ENGINE and never touches `view_settings`, so the
whole register renders under **Blender's default view transform, AgX**. AgX is a
display transform that desaturates bright warm colours hard.

A flat patch of the exact shipped copper (1.000, 0.520, 0.235), under this rig's
own two suns, nothing else in frame:

| pipeline                      | rendered median RGB        | saturation |
|-------------------------------|----------------------------|-----------|
| authored                      | 1.000, 0.520, 0.235        | **0.765** |
| Raw (shading only, no display)| 0.675, 0.357, 0.173        | **0.744** |
| Standard                      | 0.839, 0.631, 0.451        | 0.463     |
| Khronos PBR Neutral           | 0.820, 0.600, 0.400        | 0.512     |
| Filmic                        | 0.745, 0.635, 0.490        | 0.342     |
| **AgX - what the register uses** | 0.726, 0.592, 0.482     | **0.335** |

**THE SHADING KEEPS THE HUE. THE DISPLAY TRANSFORM TAKES IT - 56% of it.**

That explains the entire fault history at once, which is why I believe it.
Passes E, J and 5 turned hue, roughness and metallic; passes 6, 7 and 9 turned
the specular lobe. **Every one of those dials is UPSTREAM of the thing removing
the evidence.** No material value can survive a transform applied after it. The
earlier finding that `metallic` is backwards in this rig is still true and still
register-wide; this sits underneath it.

## THE HONEST BAR, SINCE THE ROW ASKED FOR ONE
`hilite_desat` tests the HIGHLIGHT and can be satisfied by painting. The axis it
does not cover is whether the BODY of the surface still carries the colour at
all, and that one cannot be painted - whitening a band LOWERS it. So
`_metal_read` now also measures **body saturation**, the median saturation of
the mid-tones (25th-75th luminance band), and **hue retention** against the
authored colour. Measured on pass 10:

| view  | shipped body_sat | matte-oak control | hue retention |
|-------|------------------|-------------------|---------------|
| front | 0.529            | 0.552             | 0.691         |
| side  | 0.309            | 0.500             | 0.404         |
| back  | 0.541            | 0.466             | 0.707         |

**ON SCREEN THE COPPER'S MID-TONES ARE NO MORE SATURATED THAN A MATTE OAK
PLANK'S, AND IN THE SIDE VIEW THEY ARE LESS.** That is "reads as timber" said as
a number that no amount of painting can move, and it is the bar I propose the
fault be judged on: **the leaves close this fault when their body saturation
separates from the timber control.** They currently do not separate at all.

## WHAT I AM NOT TAKING, AND WHY IT IS NOT MINE
Fixing this means changing the view transform - Standard or Khronos PBR Neutral
would return roughly half the lost saturation. **That re-grades all 25 miniboss
bodies, the 8 lords, the 12 creature bodies and every colour number the register
has measured**, including `_colour_read`'s hue-band census and the D95 showcase.
It is the same class as this file's earlier candidate 2 and it is a team-lead or
Mr. E call, not one for the art lane to take on its own initiative at 23:00.

## WHAT IS SHIPPED, AND THE ONE FAULT I CAN SEE IN IT
The vertex-colour ramp IS shipped, labelled for what it is: an improvement to
the five-sheets read, not a closure of fault 1. **The one thing I can see wrong
with it: in the SIDE view the leaf that faces the main sun goes near-white and
reads as a cream-painted board among tan ones** - the sheen is doing too much
on that one sheet. Front and back are better than pass 9; the side is arguable.
Shown rather than asked about, per Mr. E's third rule.

## FAULT 1 IS STILL NOT CLOSED. SAYING SO LAST AS WELL AS FIRST.
