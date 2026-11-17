# D73 - EVERY NAMED ITEM GETS A FACE

454 icons, one per named item, generated parametrically. An icon is not a worn
model - that is D74. It is the small image that identifies an item **wherever it
is named**: the hub's Satchel and hero sheet, the shop, the Chronicle, chat's
answer to a `!hero`. It costs a fraction of D74 and it removes most of the
"it's just a name" problem on its own.

## The 454

| Family | Items | Source |
|---|---|---|
| ring | 50 | `items.json` accessories, `slot` |
| amulet | 46 | " |
| cloak | 44 | " |
| boots | 43 | " |
| gloves | 47 | " |
| hat | 122 | `items.json` cosmetics, `kind`, the ones carrying a colour |
| banner | 102 | " |
| **total** | **454** | |

That is the census exactly: 230 accessories with no art at all, and 224 hats and
banners that carried a colour and nothing else.

## Nothing is sculpted. Every icon comes from the item's own fields

    slot / kind       picks the silhouette
    cost              drives ornateness (studs, trim, a feather, a fringe) and
                      the metal - iron, bronze, silver, gold, by quartile
    colour            drives the palette for the 224 that carry one, converted
                      from the stored sRGB hex properly
    the stat it adds  drives the gem colour on the 230 that carry no colour:
                      ac steel, saves violet, hp red, speed green, hit amber,
                      dmg orange - so the colour means something a viewer can
                      learn to read
    the NAME          picks the variant when the name is explicit about it, and
                      a hash of the key picks when it is not

That last line matters. A Straw Hat is a wide brim, a Guild Hood is a hood, a
Guard Helm is a helm with a nasal bar, an Armourer's Visor is a face plate with
eye slots, a Memorial Veil is cloth hanging from a band, a Signet Ring has a
flat seal and a Fisher's Mitts are mittens. Those are read off the item's own
name before the hash is consulted. The hat family carries eight shapes for this
reason - hood, cap, cone, circlet, wide brim, helm, visor, veil - because
"hat" in this data means eight different objects, and a Guard Helm rendering as
a cloth dome is exactly the failure Mr. E's principle names.

## Where things are

    assets/icons/items/<family>/<key>.png     the 454 icons, 256px, transparent
    renders/art/icons/_<family>.png           a labelled contact sheet per family
    renders/art/icons/_report.json            the index: every key with its name,
                                              family, cost, chosen variant, metal,
                                              stat, colour and face count
    tools/art/{icons,icongen}.py              the generator

Regenerate:

    blender -b -noaudio -P tools/art/icongen.py -- --repo <repo> [--fam hat] [--limit 6]

`--limit N` renders N per family, which is the fast way to look at a change.

## Verification

Every one of the 454 PNGs is re-opened after the run and its opaque pixel count
asserted above a floor; the run fails loudly and names any file that comes back
empty. The camera's distance and `clip_start`/`clip_end` are derived from the
evaluated world-space bounds of each icon's own geometry, never assumed - a
camera on Blender's default clip range renders an out-of-range model as an empty
transparent image **and reports success**, which is how three nearly shipped on
15 Nov. Seven contact sheets were rendered and looked at before this was
committed.

## For whoever wires the hub and the shop - NOT done here

The art worker does not touch game or hub code. The icons are keyed by the item
key exactly as `items.json` spells it, so the lookup is:

    assets/icons/items/<slot-or-kind>/<item_key>.png

`renders/art/icons/_report.json` carries the full index if a manifest is wanted
rather than a path convention. D73's DONE bar also asks for the hub showing an
icon beside an item in a hero's Satchel; that half belongs to the hub builder
and is not claimed here.

### One thing Mr. E may want to tune

The 230 accessories carry no colour of their own, so their leather and cloth
tones come from a small palette picked by the item key - eight tones, in
`icongen.py`. Under the current lighting a few read softer than Bellmire's grim
register. It is one constant and one re-run if he wants them darker.

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`. No
third-party asset is read, copied or derived from, so the CC0-only constraint is
not engaged and the forbidden Quaternius Bestiary / QAL pack is not involved.

## C-61, 16 Nov: THE METAL BAND IS THE STORED RARITY, NOT THE COST QUARTILE

Three readers in this lane banded an accessory's METAL - iron / bronze / silver
/ gold, which is the icon's rarity signal - by where its price fell inside its
slot: `icongen.context` (the icon's metal AND its metal name),
`d94proof.acc_mats` and `showcasegen`'s worn materials. The data has carried a
per-slot `rarity` key on all 254 accessories since C-61's data half landed.

All three now go through `icons.rarity_q(rarity, orn)`. The cost quartile
survives only as the fallback for things that carry no rarity at all -
cosmetics do not have the key.

**99 of 254 accessories (39%) were being rendered in the wrong band.** Examples:
`guild_cloak` (uncommon, 260 g) was iron and is bronze; `smith_gloves` (rare,
280 g) was bronze and is silver; `nightwatch_ring` (uncommon, 380 g) was silver
and is bronze - a cheap-for-its-slot uncommon was being dressed as a rare.

**SIX RARITIES, FOUR METALS.** `very rare` and `legendary` BOTH land on gold.
A fifth metal would separate them, but `METALS` is mirrored in the game build's
`scripts/gear.gd`, so adding one is not this lane's to do alone - it is a
decision plus a two-file change, not a quiet edit.

================================================================================
## SYSTEM 1 - THE RARITY HUE LADDER, AND THE ICON ORIGIN FIX (17 Nov, ~05:00 CT)
Mr. E's own Phase 1 item, ruled 22:08 CT: "the icon is the receipt." A viewer
cannot read detail on a chibi hero at stream distance; the hue around the icon
IS the rarity. Two changes went in one render pass, as the plan asked - but they
are MEASURED SEPARATELY, because one thing at a time has to survive a merge.

### CHANGE 1 (GEOMETRY) - THE RINGS NOW WRAP THE HAND THEY ARE ON
`icons.ring_pts` took no centre, so it built every ring on the ORIGIN.
`build_gloves` draws a PAIR of hands at x = +-0.36 and wrapped the cuff lip and
every lame with it, so both hands' rings were drawn as ONE ring through the
middle of the frame. That is the "left and right fuse in the middle" fault,
carried since d94g3 and deferred one pass on purpose.
`ring_pts` now takes `cx`, defaulting to 0.0 so the nine other callers - all of
them single objects that genuinely sit on the origin - are untouched.

**THE EXACT NUMBER, which is a geometry count and needs no render:**
234 rings across 42 of the 51 glove icons were centred on the origin instead of
on the hand they wrap. **After: 0.** The other 9 glove icons carry neither a lip
nor a lame and are unchanged by construction.

**AND THE PIXEL NUMBER, BY THE SAME METHOD THE GLOVES RULING USED** - worst pair
and median over all 1275 pairs of the 51 glove icons:
worst pair **10.08% -> 11.29%** of pixels differ; median 101.81 -> 102.00.

**I GOT MY OWN INSTRUMENT WRONG FIRST AND IT IS WORTH WRITING DOWN.** My first
measure was centre-band occupancy and connected-component count: 44 of 51 icons
read as one piece BEFORE and 44 of 51 AFTER, and the centre band did not empty.
I nearly reported the fix as not working. It measures the wrong thing: the two
gloves genuinely OVERLAP each other in the 3/4 icon view, so the centre band is
occupied either way. That overlap is a DIFFERENT fault, still present, and now
named: the hands sit 0.36 apart while a hand shell is up to 0.8 wide.
`renders/art/icons/_s1_glove_origin_ba.png` is the before/after, and the change
is plain in it - each cuff now carries its own bands.

### CHANGE 2 (THE LADDER) - HUE OFF THE STORED RARITY, AND NOTHING ELSE
`icons.RARITY_HUE` is the source of truth, in sRGB because read_png/write_png
both force Non-Color:
junk/common **no hue** | uncommon **white** | rare **blue (0.30,0.55,1.00)** |
very rare **purple (0.70,0.35,1.00)** | legendary **tangerine (1.00,0.55,0.12)** |
artifact **bright red (1.00,0.13,0.10)**.
`icongen.apply_hue` grows the halo FROM THE ITEM'S OWN ALPHA, so the glow is the
shape of the thing and not a disc behind it, and lays it UNDER the item so no
hue sits on metal a viewer is trying to read. **ONE STRENGTH ON EVERY RUNG** -
only the hue changes, because a ladder told in brightness has to be compared to
be read, and Mr. E's test is that you see it without reading.
**THERE IS DELIBERATELY NO COST-QUARTILE FALLBACK.** `rarity_q` has one for the
metal band; `rarity_hue` must not, because the metal is a look and the hue is a
CLAIM about what a viewer is holding. No rarity field -> no hue, never a guess.

### THE FRAMING HAD TO WIDEN, AND IT WIDENED FOR EVERY ICON
`ortho_scale` was `max(wide,tall) * 1.14` - 7% of margin a side. The halo
reaches about 9%, so the first ladder shot had the legendary and artifact glow
**cut by the frame edge**. Now 1.30, for hued and un-hued alike: widening only
the hued ones would render the same item at two sizes, and the ladder's whole
claim is that nothing changes but the hue. Border alpha is 0 on all seven
ladder cells and all 520 icons.
**THE BLANK CHECK COULD NOT SEE THAT FAULT** - it only ever asked whether there
were pixels, never whether they ran off the edge. It now asserts border alpha
too. An instrument that cannot see the fault is the fault.

### THE RUN
520 icons, `verdict GREEN`, 0 blanks, 0 frame clips, errors [].
ring 55, amulet 51, cloak 49, boots 48, gloves 51, hat 146, banner 120.
Hues: **white 109, blue 52, purple 36, tangerine 17, none 306.**

### THREE THINGS THE DATA SAYS AND SOMEBODY SHOULD KNOW
1. **THE SET IS 520, NOT 454.** D73's number is stale; content has added items
   since. Anything carrying 454 as a count - the hub's whitelist at 462 names
   included - is short.
2. **THE LADDER'S TOP AND BOTTOM RUNGS HAVE NO ITEMS.** Nothing in items.json
   carries `artifact` or `junk`. Both render correctly (see the ladder sheet,
   which forces every rung) and both are unused by the real set.
3. **266 COSMETICS CARRY NO RARITY FIELD AT ALL** - every hat and banner. They
   get no hue, which is correct, but it means a hat never glows while a ring
   does. If cosmetics are meant to band, the rarity has to go in the DATA; this
   lane will not invent it.

### WHAT I CAN SEE WRONG IN THE SHEETS (I looked at both)
`_rarity_ladder.png` - one boot, seven rungs. `_s1_hue_spread.png` - the real
set, seven items per rung.
- **WHITE IS THE WEAKEST RUNG.** On bone and pale items (barracks_boots,
  bellringer_mitts) the white halo nearly merges with the item. It reads on the
  hub's dark panel; on a light background it would not.
- **THE HALO DOMINATES THIN ITEMS.** An amulet chain is thin geometry, so the
  glow takes more of the cell than the item does and the piece reads smaller
  than a ring of the same rarity.
- On a ring the halo shows THROUGH the hole, so it can read as a disc behind
  rather than a rim. It looks well, but it is not the rim it looks like.
- The ladder sheet is not a pure hue isolate: forcing the rarity also moves the
  METAL BAND and the ornament, because `rarity_q` reads the same field. That is
  deliberate - it is what a viewer actually sees - but it should not be read as
  "the hue alone did all of that".
