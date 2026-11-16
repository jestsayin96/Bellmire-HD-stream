# D94 - THE PROOF SHEET, AND WHAT IT SAYS

D94's own done bar, verbatim: *"A single render, one row per slot, showing SIX
DIFFERENT items of that slot side by side on real hero bodies at stream
distance. If a viewer cannot tell them apart in that shot, it is not done.
Then the same for weapons and armour."*

That is a TEST, not a contact sheet, so it is built to be able to fail - and it
failed five times, which is the whole value of it. Eight rows, 48 heroes, 96
renders, in `renders/art/d94/`. Generator `tools/art/d94proof.py`. The builders
themselves are D95's (`tools/art/showcase.py`) and the derivations are D73's,
imported rather than copied, so the icon in the hub and the thing on the hero
stay the same object.

**ONE PICTURE ANSWERS THIS: `renders/art/d94/_overview.png`.** Every row at
stream size, nothing flattered. The per-slot sheets `_row_<slot>.png` carry the
evidence behind each verdict.

## How a row is built, and why it can fail

Same body, same pose, same light, same framing, **and nothing else worn**. The
only difference between the six cells of a row is the item under test, so
anything you can tell apart you can tell apart because of the item. Each row
has three strips:

1. **THE ITEM ALONE**, framed to its own measured bounds - *are these six
   actually six different objects?*
2. **THE RENDER** - the whole hero. *Where does it sit, and does it fit?*
3. **STREAM SIZE** - strip 2 block-averaged down by 3 and blown back up, which
   is what a viewer receives of a hero standing in a delve. **This strip is the
   bar.** The other two are evidence.

And a measured number, not an opinion: every pair in a row is differenced, and
the row reports the percentage of the hero's own pixels that change. Two
different failures wear the same face on a contact sheet, so they are
separated - **DUPLICATE** (the items are one object: a build bug) versus **TOO
SMALL ON STREAM** (the items differ, a viewer cannot see it: a design answer,
not a bug).

## THE VERDICTS

| row | verdict | worst pair | median |
|---|---|---|---|
| ring | **TOO SMALL ON STREAM** | 0.00% | 0.00% |
| amulet | **DUPLICATES 1/15** | 0.00% | 0.55% |
| cloak | **DUPLICATES 1/15** | 0.00% | 26.72% |
| boots | TELLS APART | 1.68% | 4.09% |
| gloves | **DUPLICATES 1/15** | 0.00% | 0.25% |
| hat | **DUPLICATES 1/15** | 0.00% | 33.97% |
| weapon | **DUPLICATES 1/15** | 0.00% | 5.66% |
| armour | TELLS APART | 19.65% | 35.17% |

### 1. FIVE PAIRS OF NAMED ITEMS ARE ONE OBJECT

These are not "similar". The renders are identical, and each pair is two names,
two prices and two flavour lines that a viewer would pay separately for:

- **Gatehouse Whistle = Brewster's Charm** (amulet)
- **Hurdler's Cloak = Osier-cutter's Cloak**
- **Baker's Mitts = Millhand's Mitts** (gloves)
- **Straw Hat = Miller's Cap**
- **Scarbow = Seamstring** (weapon - *both tier 5 ranged*)

The cause is the same in all five: the derivation is `name-variant x cost
quartile`, and two items that land on the same variant and the same quartile
land on the same object. The weapon case is the worst of them, because
`showcase.weapon()` keys off **family + tier only** - so EVERY tier-5 bow is
the same bow, and the duplicate is only visible here because the row happened
to draw two. The fix belongs in the builder, not in this sheet: the item's own
key has to reach the geometry, not just the material.

### 2. RING, AMULET AND GLOVES CANNOT BE SEEN AT STREAM DISTANCE AT ALL

Look at strip 1 of `_row_ring.png`: six genuinely different rings - a signet, a
plain band, a braided band with a blue stone, gold with amber, gold with
violet. The derivation works. Now look at strip 3: **six identical heroes.**
Worst pair AND median are both 0.00%; not one pixel of the hero changes.

A ring is about two centimetres across on a body a metre high, and it is 62-68%
**inside the hand** besides. No camera angle shows it worn - the detail strip
had to drop the body entirely to photograph the thing at all. Amulet and gloves
are the same story with a bigger object: median 0.55% and 0.25%.

**This is a decision for Mr. E, and it is a picture, not a question.** Three
ways out, and they are not exclusive:

- **Pay the receipt where it can be read.** The hub icon (D73) already varies
  per item and is seen at panel size. If rings and gloves are hub-and-nameplate
  items, say so and price them like it.
- **Make the piece carry past its own size** - a lit stone that reads as a
  coloured spark at stream distance, a gauntlet that changes the hand's
  silhouette rather than its texture. This is cheap and it is what boots
  already do (1.68%, and boots are the smallest thing on the list that passes).
- **Spend the slots elsewhere.** 55 rings and 51 pairs of gloves is a lot of
  shop stock for something invisible in the delve.

Cloak, hat, weapon and armour all read fine, so this is specifically the three
small slots.

### 3. THE TOP OF THE LADDER DOES NOT LOOK LIKE THE TOP OF THE LADDER

In `_row_weapon.png` the Scarbow and the Seamstring are **tier 5** - the pieces
a viewer spends months of points on - and they come back as plain brown wood,
visually below the tier-3 Emberline Sword. Wear rides tier for blades and axes
and does not reach the ranged family. Per the 15 Nov ruling that condition is
the receipt, the two legendary bows are currently reading second-hand.

## THE FIT REPORT - 32 faults, listed because they are real

Every vertex of every piece is tested against the body's BVH. The full list is
`renders/art/d94/_report.json` (`fit_faults`). The ones that matter:

- **Rings sit 62-68% inside the hand**, 0.038-0.039 m deep.
- **Gloves sit 67-84% inside the hand** (Carder's, Fuller's, Lockkeeper's).
  Enclosing pieces are *supposed* to contain the limb, but this is past the
  threshold for that and the glove's own shape is being eaten.
- **Hats clip the skull by 0.32 m** (Straw Hat, Miller's Cap, Beekeeper's Veil,
  Quarryman's Helm) - the helm builder is sizing off a headbox that does not
  match this body's crown.
- **Bodger's Hat FLOATS** 0.078 m clear of the head.
- **Both bows stand 0.116 m BELOW the feet**; Cold-White Wraps 0.065 m. A
  carried weapon is sunk into the floor.
- **Bearded Greataxe passes through the body by 0.030 m**, Emberline Sword by
  0.021 m - these are carried pieces and are not meant to touch the body at all.
- **Tassets are 69% inside the body** on the Padded Gambeson and the Scarwoven
  Hauberk; the Seamwoven Vestment's left sleeve 79%.

## What the pictures overruled - the sheet itself took four passes

The blank check passed on every bad version of this sheet. Only looking caught
these, and each one would have shipped a WRONG VERDICT, which is worse than a
bad render:

1. **Pass 1 photographed no weapon at all.** The weapon row was framed from the
   side, and a carried weapon hangs beside the right hand where the body
   occludes it completely from 90 degrees. Six heroes holding nothing, and the
   metric duly reported them all identical. The row is FRONT now, and the view
   is named in the code with the reason.
2. **Pass 2 photographed the cape.** The tight detail camera aimed at the ring
   found the Knight's own red cape, which hangs past the hands - and the sheet
   "proved" all six rings were one object. The cape comes off for every row
   that is not about a cape.
3. **Pass 3 photographed the hero's hip.** With the cape gone the camera still
   could not see the ring, because the ring is inside the hand. The measured
   clear-line search did not help: there is no clear line. Strip 1 is now the
   item ALONE on its own bounds, which cannot be occluded by anything.
4. **The first metric was the mean difference over the whole frame**, which is
   mostly empty background, so it reported 0.00 for a cloak row you can tell
   apart across the room. It counts changed pixels as a fraction of the HERO
   now, and it separates duplicate from invisible.

## Verification

`renders/art/d94/_report.json`. Blank check **96 files, 0 failures** - every
PNG re-opened and its opaque pixel count asserted, because a wrong clip range
renders an empty transparent frame and reports success. Engine `BLENDER_EEVEE`
(there is no `BLENDER_EEVEE_NEXT` on 5.2). 48 heroes, 20,184 faces of generated
gear across them. `_overview.png` and the per-slot sheets were viewed before
committing; the four passes above are what viewing them bought.

## For the GAME BUILD lane

Nothing here is wired. The art lane never runs Godot. What this sheet gives the
wiring half of D94 is a list of five builder collisions to fix before
`dress_cosmetics()` starts taking the ITEM, and the knowledge that **three of
the six accessory slots are invisible on the body**, so wiring them per-item
buys a viewer nothing on its own - the icon path is where that receipt is paid
today.

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`, on the
KayKit CC0 adventurer bodies already in the repo. No third-party asset is read
by any of it.
