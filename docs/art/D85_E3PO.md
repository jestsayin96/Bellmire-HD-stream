# D85 - THE COMMANDER OF THE GUARDS (art half)

Mr. E, Nov 15 16:25: *"i also have not seen E3PO"*.

## Why he was invisible - measured, not guessed

`notables.gd` defines him with `"role": "guard", "gear": "guard", "near": "garrison"`.
`town.gd:4627` gives every guard the same row:

    ["guard", "garrison", "Knight.glb", 0.74, 0.82, 1.00, 5]

The Commander of the Guards wears the same model, the same pale-blue tint and the same kit
as the five men he commands, standing where they all stand. There was nothing to see. This
is D75's problem again: a named character with no design of his own.

## What was built - A KIT, NOT A NEW BODY

`Knight.glb` is a skinned KayKit mesh on the `Rig_Medium` skeleton. Re-exporting it as a
bespoke E3PO mesh would have thrown the walk and the idle away. So the art half is ORIGINAL
geometry authored in the rig's own REST space, one object per attachment point, each with
its **origin on the bone it hangs from** - parent it and the animation carries it.

    assets/characters/bellmire/e3po_kit.glb      12 objects, 1158 tris
    tools/art/e3po.py                            the kit (shape + colour + wear)
    tools/art/e3pogen.py                         headless driver, render + blank-check

| object(s)                               | bone         | anchor (rest, world)      | follows bone rotation |
|-----------------------------------------|--------------|---------------------------|-----------------------|
| `E3PO_Crest_brass` `_cloth`             | `head`       | (0, 0, 1.2414)            | yes |
| `E3PO_PauldronL_steel` `_brass`         | `upperarm.l` | (0.212, 0, 1.1068)        | yes |
| `E3PO_PauldronR_steel` `_brass`         | `upperarm.r` | (-0.212, 0, 1.1068)       | yes |
| `E3PO_Mantle_cloth` `_brass`            | `chest`      | (0, 0, 0.9726)            | yes |
| `E3PO_Halberd_haft` `_leather` `_steel` `_cloth` | `handslot.r` | (-0.8831, 0, 1.0493) | **no - see below** |

**Four material slots only** (steel / cloth / brass / leather+haft), merged per part, so the
Commander costs at most four extra draw calls on a town street. D23 is already fighting for
frame rate; he is not allowed to cost twenty.

### THE ONE THING THE GAME BUILD WORKER MUST DECIDE
The halberd is authored **vertical, butt on the cobbles**, and in these renders it follows
the hand in **X/Y only** - a man resting a polearm does not let it cartwheel when his
shoulder turns, and its butt stays on the ground. If you parent it rigidly to `handslot.r`
it will swing with the arm through every animation. Either lock its rotation to the body
yaw, or accept the swing. Nothing else in the kit has this question.

## His colour is his - and the first answer was WRONG

The first pass gave him a madder-red mantle. The contact sheet killed it on sight: **the
KayKit knight already wears a red cape**, so all five guards are red-caped and the Commander
would have been one more red man in a red line. Colour had to come from the one axis the
guard line does not occupy - **value**.

- plate: **near-black** (tint `(0.17, 0.18, 0.22)` against the guards' `(0.74, 0.82, 1.00)`)
- mantle, crest fin, halberd pennon: **bleached linen white**
- trim: brass, on the crest keel, the pauldron rims and the shoulder seam - where rank is
  actually worn

Against a line of pale-blue steel and red wool, the only white-and-black man on the street is
the one in charge.

## Sized against the real rig

Measured from `Knight.glb`: body **2.543** tall, helmet crown at **2.398**, shoulders at
**1.107**. **The head is 46% of the man.** The first pass sized a 0.15 crest for a head 1.16
tall and it vanished; the second fanned eleven blades that merged into a white slab. On this
body the helm is the billboard, so the crest is one clean **arc fin** 0.46 tall on a brass
keel, and everything small was cut - a neck gorget and a chest sash read as clutter at pane
distance and are gone. The mantle stops at the **hip**: cut to mid-thigh it read as a dress.

## WEAR IS A VARIABLE, NOT A STYLE (Mr. E, Nov 15 17:50)

Every surface takes `wear` in 0..1, driven from town level:

- **0.12 - a level-12 Bellmire**: bleached white linen, kept near-black plate, bright brass.
- **0.45 - mid**: the default in the exported kit.
- **0.85 - a level-1 Bellmire**: grey-dun cloth washed thin, dulled plate, dark brass, the
  crest cropped shorter, the mantle cut shorter, and **one leather patch riveted on it**.

He is the RANKING officer, so his floor is *maintained*, never *rags* - the range is
narrowed, not removed. All three are on the contact sheet, top row, with silhouettes below.

## Renders - looked at, not just written

    renders/art/e3po/_contact_sheet.png      three wear levels + silhouette row
    renders/art/e3po/_done_test_day.png      E3PO between two ordinary guards, day
    renders/art/e3po/_done_test_night.png    the same at night
    renders/art/e3po/w12|w45|w85/*.png       front / three-quarter / back

Blank check: **11 files, 0 failures** (opaque-pixel assertion on every transparent render,
luminance-spread assertion on the two opaque pane shots).

## D85.5 - THE NOTABLE AUDIT: EVERY ONE OF THE THIRTEEN SHARES A BODY

D85.5 asks for the list of notables with no silhouette of their own. It is all of them.
The whole town is built from five KayKit bodies - `Rogue`, `Rogue_Hooded`, `Barbarian`,
`Mage`, `Knight`. Handing this to the game build worker and the supervisor:

| notable | name | title | body today | shared with |
|---|---|---|---|---|
| chief | Aldric Ashwood | Chief of Bellmire | `Mage.glb` | the healer, and every 4th peasant |
| smith | Garm Coalfoot | the Smith | `Barbarian.glb` | lumberjack, miner, innkeeper, baker |
| healer | Ysolde of the Ford | Healer of the Chapel | `Mage.glb` | the chief |
| innkeeper | Rolf Thatcher | Keeper of the Tavern | `Barbarian.glb` | smith, miner, lumberjack |
| priest | Osric Hollow | Priest of the Chapel | peasant fallback | the crowd |
| crier | Cort Rivers | the Town Crier | peasant fallback | the crowd |
| bard | Wren Bramble | the Bard | peasant fallback (`role: bard` is not in the table) | the crowd |
| pedlar | Petra Fenwick | the Pedlar | `Rogue_Hooded.glb` (gear: merchant) | merchant, trader, washer |
| tove | Tove Bramble | the Bard's Girl | child cycle | every third child |
| dunn | Dunn the Younger | a Boy of Bellmire | child cycle | every third child |
| beggar | Harl Quarryman | the Beggar | peasant fallback | the crowd |
| drunk | Rask Stonehand | the Town Drunk | peasant fallback | the crowd |
| **e3po** | **E3PO** | **Commander of the Guards** | **`Knight.glb`, identical to his 5 guards** | **FIXED HERE** |

Note the four with **no `role` key at all** (priest, crier - and `bard`, whose role is not a
row in the table): they fall through to the peasant body cycle, so a named priest can be
wearing a Rogue_Hooded one session and a Mage the next. That is a code bug as much as an art
gap, and it is the game build worker's to confirm.

Cheapest next art wins, if Mr. E wants them: the **crier** and the **bard** are the two
notables viewers hear from most in the Chronicle, and both are currently nobody.

## LICENCE

All geometry in `tools/art/e3po.py` is generated from vertex maths in `lordlib.py`. No
third-party asset is read or re-exported. `Knight.glb` (KayKit Adventurers, **CC0**, already
in the repo) is opened READ-ONLY for measurement and for the comparison renders.
Quaternius Bestiary / QAL is not used anywhere on this project.
