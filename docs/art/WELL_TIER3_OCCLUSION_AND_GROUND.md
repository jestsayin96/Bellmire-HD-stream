# THE BRONZE IS ALREADY THERE. THE BOWL IS HIDING IT.

**28 Nov 2026, 09:34-09:41 CT. Blender bridge DOWN for a NINTH consecutive run**
(`Cannot connect to Blender at localhost:9876`, tested this run, not assumed) -
no render, no Godot, no git. Everything below was measured on the ALREADY-SHIPPED
sheet with numpy/PIL in the Linux container, and **looked at** at 4x and 8x zoom.

This document CORRECTS one claim in `docs/art/WELL_TIER3_MATERIAL_READ.md`
(08:34 CT) and ADDS one fault that document's instrument could not see.
Its headline finding - *the Fountain is the flattest thing in its own ladder* -
is **independently confirmed by eye this run and stands.**

---

## 1. THE CORRECTION: "NO BRONZE ON THE SPOUTS" IS WRONG, AND THE REAL CAUSE IS WORSE

The 08:34 document says, verbatim:

> **There is no bronze read on the spouts.** At 1.6% warm the only warm pixels
> in the whole tier are the small finial at the apex.

**Both halves of that sentence are false, measured on the same shipped sheet:**

| t3 bronze pixels (full res, warm & chromatic) | count | share |
|---|---:|---:|
| finial at the apex (y < 390) | 312 | 44.9% |
| **four spout nozzles (y >= 390)** | **383** | **55.1%** |

The spout nozzles carry **more** bronze than the finial does. They are visible,
unambiguous and correctly modelled - four gold-bronze cuffs where each pale arc
meets the central column. I looked at them at 8x: they are there.

**So why did the tier measure 1.6% warm? Because the bowl above them hides them.**
The upper basin is a wide flat revolve whose rim **overhangs the nozzles
completely** at the sheet's camera angle, dropping them into its own shadow. The
bronze is not missing. It is occluded by the tier's own geometry.

### WHY THIS MATTERS MORE THAN A PEDANTIC CORRECTION

The 08:34 fix spec's item 1 is **"Put bronze on the bronze."** Acting on that
would add warm material to surfaces that *already have it* and the tier's warm%
would barely move, because nothing about the occlusion changes. The lane would
re-render, re-measure, see ~1.6% again and conclude the material system is
broken. **The fix is geometric, not material:**

- push the four spouts OUT past the bowl's silhouette so the nozzles clear the
  overhang, **or** reduce the bowl's overhang radius, **or** drop the nozzles
  below the shadow line. One of those three, changed ALONE, then re-rendered.
- only THEN judge whether the bronze needs to be richer.

This is the lane's own standing lesson #5 firing again: a number (1.6% warm) and
a picture (four plainly bronze nozzles) disagreed, **and the picture was right.**
The 08:34 run measured honestly and reasoned from the number to a cause it could
not see. I would not have caught it either without zooming in.

---

## 2. THE NEW FAULT: THE GROUND DRESSING REGRESSES AT THE TOP TIER

Chroma is **structurally blind** to this, which is why four hours of colour
measurement missed it: paving stones are the same grey as the ground they sit on,
so they contribute no chroma and no warmth. They contribute **edges**.

Edge incident in the ground annulus at each tier's foot:

| tier | ground-edge density | what is actually on the ground |
|---|---:|---|
| t1 The Well | 17.69 | scattered rubble and loose stones |
| t2 The Well Kept | 25.34 | a laid ring of flagstones, a proper apron |
| **t3 The Fountain** | **7.81** | **nothing. bare plinth.** |

The top of the ladder has **less than half** t1's ground incident and **under a
third** of t2's. The progression in ground dressing runs
*rubble -> laid flagstones -> bare dirt*. A town square that has just spent
months of viewer points on a dressed-ashlar fountain has **torn up its paving to
get it**.

**The house's own good ladder proves this is the right thing to measure.** The
hall sheet - verified by eye by the team lead at 07:58 CT and by me this run -
scores 19.5 / 37.1 / **72.3**: its top tier has a paved court and an iron railing,
and its caption says so (`A PAVED COURT`). Ground dressing rising with tier is
already this house's standard. The well ladder is the one that breaks it.

### THE FIX
Give t3 a paved apron at least as dressed as t2's flagstone ring - ringed
coursed paving around the basin, reading as laid rather than scattered. The
Medieval Village MegaKit and Castle pack (both cleared, both already supplying
`town_hall_t3`) carry paving modules; **reuse beats authoring.**

---

## 3. THE GATE IS WRITTEN AND IT IS NOT AN UNRUN CHANGE

`tools/art/_tiergate.py` - **NEW this run, and RUN this run.**

The 08:34 document proposed this gate and deliberately did not write it, on the
correct reasoning that `townlib.py`, `townbuildgen.py` and `hallgen.py` were all
modified at 07:34 and have never been run, and stacking a fourth unrun change
would make the first failure impossible to attribute. **That reasoning applies to
the generators and not to a read-only instrument.** This gate is a STANDALONE
file that reads an already-rendered PNG, so it needs no Blender and it was
executed against both shipped sheets the hour it was written. Fold it into
`townlib.py` on the first live-bridge run, AFTER the three existing generators
have been run once.

It also does something the proposal did not account for: **there is no system
Python on cruzader and Blender there has numpy but no PIL.** A PIL-only gate
cannot run on the machine that makes the renders. `load_rgb` tries PIL and falls
back to `bpy.data.images` read as Non-Color so sRGB bytes round-trip.

### SELFTEST - ALL FOUR PASSED, RUN AT 09:39 CT

```
[1] WELL ladder - KNOWN BAD    -> RED    (not richest, not warmest, ground regresses)
[2] HALL ladder - KNOWN GOOD   -> GREEN  (21.1/23.8/35.6 chroma, 19.5/37.1/72.3 ground)
[3] top-tier span with no subject matter -> RED
[4] zero-width span                      -> RED ON EMPTY
```

**An honest note on test [3]:** it goes RED, but by the *comparison* path, not the
red-on-empty path - the span still contains plinth pixels, so `subject_px > 0`.
It is a weaker test than it looks. The red-on-empty branch is proved instead by
test [4] and by a synthetic all-background span, which fires
`span has NO SUBJECT PIXELS -> RED ON EMPTY` as intended.

### WHAT THIS GATE CANNOT SEE - WRITTEN INTO ITS OWN HEADER, BEFORE THE NUMBERS
- **Occlusion** - the exact fault that motivated it. It counts the bronze it can
  SEE, so it reports the symptom and says nothing about the cause. A RED means
  "the top tier does not read rich", **never** "the top tier lacks material".
  The header says in its own words: do not let a RED send you to the material.
- Whether the span holds the *right* subject. Spans are caller-supplied and
  unverified; a span containing the hero scores normally.
- Shape, silhouette, proportion.
- Auto-segmentation is NOT offered, because it was tried and **fails**: a column
  profile of the hall sheet resolves all three tiers as one run, 411..1302,
  because the buildings touch. Explicit crops are not laziness.

---

## 4. WHAT IS NOT DONE

- **Neither fault is fixed.** Both need Blender to re-author and re-render.
- The three generators modified at 07:34 CT have **still never been run.**
- Nothing in this document is committed. `git status` has still never been run on
  this lane: the mount has been narrow (`C:\hd adventure\bellmire-art` only, not
  the parent) for a fourth consecutive run, and W5's `.git` is a FILE pointing
  into R, so every git command fails. `device_request_folder_access` is FORBIDDEN
  and was NOT called.
