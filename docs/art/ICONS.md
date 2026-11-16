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
