# D95 - THE TEN-CHARACTER SHOWCASE (art half)

Mr. E, 16 Nov 00:59: *"i want 10 characters with different equipment and armor and
accessories as a show case for me ... front, side, back, top down profile views i want to
make sure everything that is made for these characters actually fit. people are not going
to waste money on slop."*

Sheets: `renders/art/d95/_overview.png` (all ten, front) and `_sheet_<key>.png` (four
views each). Raw views in `renders/art/d95/<key>/{front,side,back,top}.png`.
Machine-readable: `renders/art/d95/_report.json`. Kits in
`assets/characters/bellmire/showcase/<key>_kit.glb`.

## This is also D94's art half
`gear.gd dress_cosmetics()` renders an accessory from the SLOT alone, so all 55 rings are
one gold torus, and the 119 named weapons and armour pieces in `items.json` are read by no
script at all. A piece is now built from the ITEM:

| the item's field | what it decides |
|---|---|
| `family` / `cut` / `slot` | the silhouette - blade, axe, arcane, ranged; heavy, light, robe |
| the item's NAME | overrides it where the name says something: an arbalest is not a bow, a greataxe is not a hatchet, a wand is not a staff, a Helm is not a hood |
| `tier` | **which model** within the family, and the material ladder: brown iron -> grey steel -> blued+rune -> dragon ivory -> scarforged white with a lit seam |
| `cost` (accessories) | ornateness, the metal quartile, and WEAR |
| the stat it adds | the gem colour - ac steel, saves violet, hp red, speed green, hit amber, dmg orange |

The last three are **D73's own derivations, imported from `icons.py` rather than copied**,
so the icon in the hub and the thing on the hero are the same object.

## The weapons are REAL MODELS that were already in the repo
The project already carries two CC0 KayKit weapon sets that `gear.gd` has never touched:
`assets/gear/` (dungeon weapon bits) and
`addons/kaykit_character_pack_adventures/Assets/gltf/` (Adventurers 1.0, `LICENSE.txt`
CC0 in that folder). Both are authored Z-up about the GRIP, which is the handslot
convention this rig uses, so a model dropped at the posed hand is held correctly.
`tools/art/gearmodels.py` maps family + name + tier onto them - five different shapes per
family where the packs can give five - then tints up the tier ladder and adds the lit
runed collar (tier 3+) and the seam of light (tier 5) that make it THIS item rather than
the pack's stock model. **Nothing is re-exported**: the kit GLBs carry only original
geometry and `_report.json` names the model path per hero, so the game wires the file that
is already in the project. Three heroes also carry a shield, which `classes.json` asks for
and nothing in the game had.

## The ten

| # | calling | body | rarity | armour (cut) | weapon (model) | accessories, all unique to that hero | wear |
|---|---|---|---|---|---|---|---|
| 1 | knight | Knight | **common** | Padded Gambeson (heavy) | Ironmonger's Blade (`sword_A.gltf`) + shield `shield_A.gltf` | Tallykeeper's Ring (ring 210g), Gatehouse Whistle (amulet 230g), Soft Boots (boots 200g) | 0.82 |
| 2 | ranger | Ranger | **common** | Ford Leathers (light) | Hunter's Crossbow (`crossbow_1handed.gltf`) | Orchardman's Cloak (cloak 220g), Millhand's Mitts (gloves 200g), Chapel Clogs (boots 200g) | 0.90 |
| 3 | rogue | Rogue | **uncommon** | Studded Brigandine (light) | Stonewick Backsword (`sword_B.gltf`) | Pilgrim's Ring (ring 300g), Peat-cutter's Cloak (cloak 250g), Mortarman's Gloves (gloves 230g) | 0.59 |
| 4 | warden | Barbarian | **uncommon** | Militia Hauberk (heavy) | Ferrywarden's Axe (`axe_A.gltf`) | Lamplighter's Amulet (amulet 300g), Drover's Boots (boots 220g), Splint-wrap Gloves (gloves 230g) | 0.69 |
| 5 | mage | Mage | **rare** | Rune-Hemmed Vestment (robe) | Rune-Wrapped Staff (`staff_B.gltf`) | Chapel Candle Amulet (amulet 320g), Tithe Ring (ring 340g), Saltboiler's Cloak (cloak 280g) | 0.35 |
| 6 | duelist | Rogue_Hooded | **rare** | Emberleather Coat (light) | Stitchwound Sabre (`sword_1handed.gltf`) | Lye-boiler's Gloves (gloves 240g), Carter's Boots (boots 240g), Orchard Ring (ring 340g) | 0.45 |
| 7 | barbarian | Barbarian | **very rare** | Wyrmhide Coat (light) | Ash-Maul Greataxe (`hammer_B.gltf`) | Weaver's Long Cloak (cloak 300g), Ferrybell Amulet (amulet 350g), Ashfoot's Boots (boots 280g) | 0.14 |
| 8 | sage | Mage | **very rare** | Dragonsilk Robe (robe) | Dragontooth Staff (`staff_B.gltf`) | Scarglass Ring (ring 400g), Boatwright's Charm (amulet 350g), Saddler's Gloves (gloves 260g) | 0.22 |
| 9 | paladin | Knight | **legendary** | Scarwoven Hauberk (heavy) | Scarfang (`sword_E.gltf`) + shield `shield_spikes.gltf` | Sexton's Hobnails (boots 300g), Forgemaster's Grips (gloves 300g), Wake-ward Cloak (cloak 360g), Raidbreaker's Helm (helm 300g) | 0.05 |
| 10 | cleric | Rogue_Hooded | **legendary** | Seamwoven Vestment (robe) | Staff of the Open Seam (`staff_B.gltf`) + shield `shield_spikes.gltf` | Gaoler's Keyring (amulet 360g), Scarwatch Cloak (cloak 360g), Stair-walker's Boots (boots 300g) | 0.08 |

Two per rarity band, three armour cuts, four weapon families, six bodies, and **one
declared SET** - the paladin's *Scarwoven plate*: hauberk, Sexton's Hobnails,
Forgemaster's Grips and Raidbreaker's Helm share one look, the single exception Mr. E
named. Nothing else shares a look with anything.

**Wear is the receipt.** It rides the tier and is nudged per hero, so no two of the ten
carry the same value: 0.90 and 0.82 at common down to 0.08 and 0.05 at legendary.

## FIT - MEASURED, NOT EYEBALLED
Every shell (cuirass, jerkin, robe, cloak, amulet chain) is built from radii sampled off
the REAL POSED BODY with a BVH ray cast and offset by a stated clearance. A skirt and a
cloak ask a SECOND, whole-body sampler as well, because the torso sampler ignores arms and
legs on purpose and a hem has to clear the legs. Boots and gloves are scaled to the
measured foot and hand, so one boot fits six bodies. The helm is built around the MEASURED
SKULL - on this rig the head bone sits at the neck and the head is half the figure.
Carried models are scaled from their own longest dimension against the body's own
shoulder height, and a staff is dropped until its butt rests on the floor.

Then every finished piece, the bought models included, is re-tested against the body's
full BVH. Per-piece numbers are in `_report.json` (`fit`).

## THE FIT REPORT - WHAT IS ACTUALLY WRONG

Honest list. Nothing here is cropped out of the sheets.

### Real, and not fixed
1. **The carried weapon brushes its owner on eight of the ten**, 0.027 m (barbarian) to
   0.112 m (cleric's staff), measured OUTSIDE the fist - the grip inside the hand is
   excluded from the test because it belongs there. It is the blade or the haft touching
   the hip or the robe's skirt. Visible in the side view, not in the front.
2. **Shields overlap the hip** 0.031-0.042 m, same cause.
3. **The robe's upper shell crosses the hanging arms** - 0.118 m (sage), 0.202 m (cleric).
   The arms hang inside a shell measured off the torso.
4. **Rings are invisible at showcase framing.** A 5 cm ring on a 2.3 m figure is two
   pixels. It is correctly placed on the finger; it will be read in the hub icon, which is
   the same derivation.
5. **Mage and Sage share a body AND the body's own hat**; Duelist and Cleric share the
   hooded body. Tinting pulls them apart, but each pair is close at a glance. Six bodies
   carry ten heroes and that is the cost.
6. **The top-down view shows scalp.** It is in the sheet because it was asked for, but on
   a body that is half head it proves nothing about fit. A 60-degree high angle would.
7. **The staves read small** behind a wide robe skirt - the head and the collar show, the
   shaft is mostly hidden from the front.

### Numbers that look like faults and are NOT
A boot contains a foot, a gauntlet a hand, a pauldron caps a shoulder, a tasset hangs over
a hip, a sleeve surrounds an arm, a thrown-back hood sits over the skull. Their inner
faces are inside the body **by construction**, which is why `_report.json` shows 60-95% of
those pieces "inside". The test classifies those separately and only calls a fault when a
piece is mostly buried. The remaining `CLIPS` lines for tassets, pauldrons, sleeves, the
amulet chain and the paladin's hood are all of that kind.

### What the pictures overruled, pass by pass
1. **Every hero had its own blade lying horizontally through its chest** - the kit followed
   the full shoulder rotation. A carried weapon now follows the hand's TRANSLATION only.
2. **The weapon was a lamppost** - authored at human proportions on a body that is 46%
   head. Scaled to the measured shoulder height.
3. **The helm was invisible**, built around the head BONE which is at the neck, so it
   rendered inside the chest; rebuilt on the measured skull it then swallowed the face. It
   is now a skullcap stopping above the eyes with a neck guard behind.
4. **All ten wore the same mud** - wear mixed leather, iron and wool toward one grey-brown,
   and metalness was so high that kept steel rendered black in an empty world.
5. **The procedural blades were thin** - replaced with the CC0 models above.
6. **The crossbow left the frame** - it is scaled by its longest axis, and a thing carried
   ACROSS the body is scaled shorter than a thing carried UP it.

## Verification
Engine `BLENDER_EEVEE`. Blank check: **40 PNGs, 0 failures**. Every view also tests whether
any vertex fell outside the FIXED frame: **all forty are 0**, so nothing is cropped and no
view is zoomed to flatter a piece - one ortho height (3.30 m), one camera centre (1.28 m)
and one lighting rig for all ten.

## Handed to the GAME BUILD worker
1. `assets/characters/bellmire/showcase/<key>_kit.glb` - rest-space kits, one object per
   material per part, **origin on the bone it hangs from**, same contract as `e3po_kit.glb`.
2. The carried weapon and shield are NOT in those kits. `_report.json` -> `models` gives
   the path of the model already in the repo, per hero. Parent it to `handslot.r` /
   `handslot.l`; for the showcase it follows the hand in TRANSLATION ONLY.
3. `dress_cosmetics()` taking the ITEM: the derivation is `tools/art/showcase.py` +
   `gearmodels.py` + `icons.py`'s `variant_for` / `STAT_GEM` / `METALS`.
4. The body's own hat and cape must be HIDDEN when a helm or cloak is worn; `_report.json`
   lists which meshes were hidden per hero.
5. The in-engine half should use a 60-degree high angle in place of the top-down.

## Licence
All generated gear geometry is original vertex maths through `lordlib`. The bodies are
KayKit Adventurers 2.0 and the weapons/shields are KayKit Adventurers 1.0 and the KayKit
dungeon weapon bits - all CC0, all already committed in this repo with their own
`LICENSE.txt`, read and rendered but never re-exported. No Quaternius Bestiary / QAL.
