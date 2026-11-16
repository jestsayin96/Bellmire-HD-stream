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

Two runs, the same test, the same metric. The first one failed five times and
that is what it was built to do; the second is after the fix below.

| row | 15 Nov - first run | worst | 16 Nov - after the fix | worst | median |
|---|---|---|---|---|---|
| ring | TOO SMALL ON STREAM | 0.00% | TOO SMALL ON STREAM | 0.00% | 0.00% |
| amulet | **DUPLICATES 1/15** | 0.00% | TELLS APART | 0.52% | 0.97% |
| cloak | **DUPLICATES 1/15** | 0.00% | TELLS APART | 15.96% | 29.59% |
| boots | TELLS APART | 1.68% | TELLS APART | 1.72% | 4.47% |
| gloves | **DUPLICATES 1/15** | 0.00% | PARTLY TOO SMALL 11/15 | 0.00% | 0.33% |
| hat | **DUPLICATES 1/15** | 0.00% | TELLS APART | 17.54% | 36.07% |
| weapon | **DUPLICATES 1/15** | 0.00% | TELLS APART | 3.05% | 7.65% |
| armour | TELLS APART | 19.65% | TELLS APART | 19.65% | 35.17% |

**NO ROW REPORTS DUPLICATE.** All 120 pairs across the eight rows are two
objects. What is left is the OTHER failure, and it is not a build bug: a ring
and most pairs of gloves are too small to be seen on a body at stream distance,
which is section 2 below and is Mr. E's call, not the builder's.

### 1. FIVE PAIRS OF NAMED ITEMS WERE ONE OBJECT - FIXED 16 Nov

These were not "similar". The renders were identical, and each pair is two
names, two prices and two flavour lines that a viewer would pay separately for:

- **Gatehouse Whistle = Brewster's Charm** (amulet)
- **Hurdler's Cloak = Osier-cutter's Cloak**
- **Baker's Mitts = Millhand's Mitts** (gloves)
- **Straw Hat = Miller's Cap**
- **Scarbow = Seamstring** (weapon - *both tier 5 ranged*)

The cause was the same in all five: the derivation was `name-variant x cost
quartile`, and two items that land on the same variant and the same quartile
land on the same object. Two Mitts are both "mitt". Two tier-5 bows are both a
tier-5 bow - `showcase.weapon()` keyed off **family + tier only**, so EVERY
tier-5 bow was the same bow and the duplicate was visible here only because
the row happened to draw two of them.

**THE FIX: THE ITEM'S OWN KEY NOW REACHES THE GEOMETRY.** `showcase.sig(key,
name)` hashes the two things only this item has and returns twelve dials. The
variant still decides the KIND - that is the part a viewer can name, and it
must not move - but inside a kind the key sets PROPORTION and COUNT: band
width and how many wires in a ring, brim width against crown height on a hat,
hem length and how far the cloth sweeps on a cloak, cuff length on a glove,
limb curve and span on a bow, guard and pommel and blade taper on a sword.

Proportion and count, specifically, and not size: strip 1 frames the item to
its OWN measured bounds, so a uniformly bigger ring is the same picture. Only
a ratio survives that framing, which is why the dials move ratios.

Two more things the pictures forced out of the same code:

- **Four of the eight kinds of hat had no geometry of their own.** Variants 0
  (wide brim), 1 (cap), 2 (cone) and 7 (veil) all fell through to the war-helm
  branch, which is the whole reason a straw hat and a miller's cap were one
  object - and why a straw hat was made of steel. They are soft hats now, a
  brim and a crown, and those two numbers are the difference between them.
- **A hood left no face.** The Pieman's Hood was a closed sphere the size of
  the skull and it swallowed the man, which is the fault the helm builder
  already had a comment warning about. It is a crown and a cowl now, open at
  the front.

### 1b. TWO FAMILIES WERE WEARING THE WRONG BODY

The fit report named these and they are the same bug, so they went with it:

- **"Parish Iron Mace" rendered as a staff.** Its family in the data is
  `arcane`; its name says mace. The name now overrides the family, and there is
  a blunt builder behind it - a short haft with the mass at the top, in one of
  four heads.
- **Hand wraps and knuckles rendered as 1.3 m quarterstaves** standing below
  the feet (family `open`, which fell through to the staff). Cold-White Wraps
  was one of the fit report's worst faults for exactly this reason. They are a
  wrapped fist now: cloth round the knuckles, and a bar across them if the
  name says knuckles.

### 1c. THE TOP OF THE LADDER NOW LOOKS LIKE THE TOP OF THE LADDER

The first run's section 3: both tier-5 bows came back plain brown wood,
visually below the tier-3 Emberline Sword, because wear rode the tier for
blades and axes and never reached the ranged family. Per the 15 Nov ruling
that condition is the receipt, and the two legendary bows were reading
second-hand. The ranged limb is wood to tier 2 and METAL from tier 3; the
string lights at tier 5 and a seam runs up both limbs. A viewer who spent
months of points gets something that reads new.

### 2. RING AND GLOVES CANNOT BE SEEN AT STREAM DISTANCE AT ALL

*(Amulet left this list on the second run: at 0.52% worst and 0.97% median it
is now above the bar, but barely, and the honest reading is "visible, not
legible". Ring and gloves did not move, and nothing in a builder will move
them.)*

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

### 3. THE TOP OF THE LADDER DID NOT LOOK LIKE THE TOP OF THE LADDER - FIXED, see 1c

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

`renders/art/d94/_report.json`, second run 16 Nov. `ok: true`, 0 errors. Blank
check **96 files, 0 failures** - every
PNG re-opened and its opaque pixel count asserted, because a wrong clip range
renders an empty transparent frame and reports success. Engine `BLENDER_EEVEE`
(there is no `BLENDER_EEVEE_NEXT` on 5.2). 48 heroes, 20,184 faces of generated
gear across them. `_overview.png` and the per-slot sheets were viewed before
committing; the four passes above are what viewing them bought.

## For the GAME BUILD lane

Nothing here is wired. The art lane never runs Godot. The five builder
collisions are FIXED on the art side - `dress_cosmetics()` can take the ITEM
and get six different objects back - and what is left for the wiring half is
to key `gear.gd` the same way, and the knowledge that **two of the six
accessory slots are invisible on the body**, so wiring them per-item
buys a viewer nothing on its own - the icon path is where that receipt is paid
today.

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`, on the
KayKit CC0 adventurer bodies already in the repo. No third-party asset is read
by any of it.

---

# D94c - THE CLOAK TAKES A DYE (art half, 16 Nov)

The game build lane changed `gear.gd` so a cloak wears one of twelve period dyes
instead of a leather tone, and handed this lane one line: *"mirror this rule in
the icon/showcase derivation so the hub icon and the hero match."* If only one
side changes, a viewer buys a cloak, sees a green one in the Satchel and a brown
one on the hero, and the receipt is a lie. So this is mirrored bit for bit.

## One source of truth, because it was copied three times

`TONES` - the eight leather colours - was pasted into `icongen.context`,
`showcasegen.acc_mats` and `d94proof.acc_mats`. Three copies of one rule is how
two sides drift. All three now call **`icons.cloth_tone(slot, key, name)`**, and
that function, `CLOAK_DYES`, `CLOAK_WORDS`, `cloak_dye_i` and `khash` are the
only copy. The numbers are identical to `gear.gd`'s, in Blender linear - Godot
holds the same literals and calls `linear_to_srgb()` on them.

    hay   = (name + " " + key).lower()
    dye_i = first CLOAK_WORDS entry (in list order) whose word is in hay,
            else (khash(key) >> 8) % 12
    gloves and boots keep the TONES - they are leather

Measured over all 49 cloaks: **all twelve dyes used, 45 assigned by name and 4
by hash, no dye on more than 7.** The same spread the build half reports, which
is the point.

## Then the sheet failed, which is what it is for

The first render came back **russet, green, wine, GREEN, olive, GREEN** - three
of six cells green, and the two with the same cut were one object again. Counted
over all 49: **fifteen cloaks shared BOTH a dye and a cut with another cloak,
six of them woad-and-mantle** - every watch, wall and constable cloak in
Bellmire.

That is not a bug in the word list. A hedgeward and an orchardman both wear
green, and the watch wears the town's blue; things look like what they are for.
Scattering the dyes to make a prettier sheet would be a lie about the town. So
the dye stays and a **SHADE STEP** was added inside it, assigned exactly the way
D94b assigned form - **by position in the colliding group, so it cannot collide
by construction**:

    group   = every cloak sharing (dye_i, variant), keys sorted as plain strings
    shade_i = the key's index in that group, capped at 7 - 0 leaves the dye alone
    cloth   = dye * CLOAK_SHADES[shade_i], clamped to [0.02, 0.95]

Same dye, a lighter or darker bolt of it. Result over the 49: **49 distinct
(colour, cut) pairs out of 49 - zero collisions**, from 25 distinct colours.
Thirty-four cloaks are on shade 0, so most of them are the dye untouched.

## What the renders say

- `renders/art/icons/_cloak.png` - all 49 hub icons on one sheet. **Looked at.**
  Twelve colours where there were eight browns. 49/49 rendered, **0 blanks**.
- `renders/art/d94/_row_cloak.png` - six on real bodies, three strips. **Looked
  at, twice: the first version is what failed above.** Cloak verdict TELLS APART,
  worst pair 15.96% -> **19.11%** of hero pixels, median 29.59% -> **31.25%**.
- Whole proof sheet re-run: `ok true`, 8 rows, **blank list empty**, and the
  duplicate check still reports **no row DUPLICATE**.

Honest note on that row: it still shows three greens, because three of the six
the test picks are countryside trades. They are now three different greens on
three different cuts, and the two that were indistinguishable are not - but if
Mr. E wants the greens further apart, that is a change to the WORD LIST on both
sides, not to this lane's derivation.

## THE GAME LANE OWES ONE MIRROR BACK

The shade step is this lane's addition and `gear.gd` does not have it yet. Until
it is mirrored beside `cloak_dye_i`, **the first cloak of each group matches the
hero exactly and the other fifteen are off by a value step - never by a hue**,
so nothing reads as the wrong item in the meantime. The rule to copy is the
three lines above.

## The legendary accessory pool is still 16 deep, and it is not an art fix

Re-measured from `data/items.json`, since the showcase had to borrow very-rare
pieces: legendary (441+) holds **8 rings, 6 cloaks, 2 amulets, 0 boots, 0
gloves**. Boots top out at 420 and gloves at 380 against a 441 band that is the
same for every slot, so **those two slots cannot hold a legendary piece at all**.
No derivation can mint one; the fix is in `items.json` - either band rarity per
slot (a cost quantile within the slot) or write dearer boots and gloves. That is
content-lane data and content is shut down, so it is Mr. E's call which.
