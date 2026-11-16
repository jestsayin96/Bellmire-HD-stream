# D95 - THE TEN-CHARACTER SHOWCASE (art half)

Mr. E, 16 Nov 00:59: *"i want 10 characters with different equipment and armor and
accessories as a show case for me ... front, side, back, top down profile views i want to
make sure everything that is made for these characters actually fit. people are not going
to waste money on slop."*

Sheets: `renders/art/d95/_overview.png` (all ten, front) and `_sheet_<key>.png`
(four views each). Raw views in `renders/art/d95/<key>/{front,side,back,top}.png`.
Machine-readable: `renders/art/d95/_report.json`. Kits exported to
`assets/characters/bellmire/showcase/<key>_kit.glb`.

## This is also D94's art half
`gear.gd dress_cosmetics()` renders an accessory from the SLOT alone, so all 55 rings are
one gold torus, and the 119 named weapons and armour pieces in `items.json` are read by no
script at all. The generator here builds a piece from the ITEM:

| the item's field | what it decides |
|---|---|
| `family` / `cut` / `slot` | the silhouette - blade, axe, arcane, ranged; heavy, light, robe |
| the item's NAME | overrides it where the name says something (an arbalest is not a bow, a greataxe is not a hatchet, a Helm is not a hood) |
| `tier` | the material ladder: brown iron -> grey steel -> blued+rune -> dragon ivory -> scarforged white with a lit seam |
| `cost` (accessories) | ornateness, the metal quartile, and WEAR |
| the stat it adds | the gem colour - ac steel, saves violet, hp red, speed green, hit amber, dmg orange |

The last three are **D73's own derivations, imported from `icons.py` rather than copied**,
so the icon in the hub and the thing on the hero are the same object.

## The ten

| # | calling | body | rarity | armour (cut) | weapon (family) | accessories, all unique to that hero | wear |
|---|---|---|---|---|---|---|---|
| 1 | knight | Knight | **common** | Padded Gambeson (heavy) | Ironmonger's Blade (blade) | Tallykeeper's Ring (ring 210g), Gatehouse Whistle (amulet 230g), Soft Boots (boots 200g) | 0.82 |
| 2 | ranger | Ranger | **common** | Ford Leathers (light) | Hunter's Crossbow (ranged) | Orchardman's Cloak (cloak 220g), Millhand's Mitts (gloves 200g), Chapel Clogs (boots 200g) | 0.90 |
| 3 | rogue | Rogue | **uncommon** | Studded Brigandine (light) | Stonewick Backsword (blade) | Pilgrim's Ring (ring 300g), Peat-cutter's Cloak (cloak 250g), Mortarman's Gloves (gloves 230g) | 0.59 |
| 4 | warden | Barbarian | **uncommon** | Militia Hauberk (heavy) | Ferrywarden's Axe (axe) | Lamplighter's Amulet (amulet 300g), Drover's Boots (boots 220g), Splint-wrap Gloves (gloves 230g) | 0.69 |
| 5 | mage | Mage | **rare** | Rune-Hemmed Vestment (robe) | Rune-Wrapped Staff (arcane) | Chapel Candle Amulet (amulet 320g), Tithe Ring (ring 340g), Saltboiler's Cloak (cloak 280g) | 0.35 |
| 6 | duelist | Rogue_Hooded | **rare** | Emberleather Coat (light) | Stitchwound Sabre (blade) | Lye-boiler's Gloves (gloves 240g), Carter's Boots (boots 240g), Orchard Ring (ring 340g) | 0.45 |
| 7 | barbarian | Barbarian | **very rare** | Wyrmhide Coat (light) | Ash-Maul Greataxe (axe) | Weaver's Long Cloak (cloak 300g), Ferrybell Amulet (amulet 350g), Ashfoot's Boots (boots 280g) | 0.14 |
| 8 | sage | Mage | **very rare** | Dragonsilk Robe (robe) | Dragontooth Staff (arcane) | Scarglass Ring (ring 400g), Boatwright's Charm (amulet 350g), Saddler's Gloves (gloves 260g) | 0.22 |
| 9 | paladin | Knight | **legendary** | Scarwoven Hauberk (heavy) | Scarfang (blade) | Sexton's Hobnails (boots 300g), Forgemaster's Grips (gloves 300g), Wake-ward Cloak (cloak 360g), Raidbreaker's Helm (helm 300g) | 0.05 |
| 10 | cleric | Rogue_Hooded | **legendary** | Seamwoven Vestment (robe) | Staff of the Open Seam (arcane) | Gaoler's Keyring (amulet 360g), Scarwatch Cloak (cloak 360g), Stair-walker's Boots (boots 300g) | 0.08 |

Two per rarity band, three armour cuts, four weapon families, six bodies, and **one
declared SET** - the paladin's *Scarwoven plate*: hauberk, Sexton's Hobnails,
Forgemaster's Grips and Raidbreaker's Helm share one look, which is the single exception
Mr. E named. Nothing else shares a look with anything.

**Wear is the receipt.** It rides the tier and is nudged per hero, so no two of the ten
carry the same value: 0.90 and 0.82 at common down to 0.08 and 0.05 at legendary. A
level-1 gambeson is make-do; the scarwoven hauberk reads new.

## FIT - MEASURED, NOT EYEBALLED
Every shell (cuirass, jerkin, robe, cloak, amulet chain) is built from radii sampled off
the REAL POSED BODY with a BVH ray cast and offset by a stated clearance, so it cannot
float and cannot sink. Boots and gloves are scaled to the measured foot and hand, so the
same boot fits six different bodies. The helm is built around the MEASURED SKULL - on this
rig the head bone sits at the neck and the head is half the figure, which is exactly how
pass 3 built a helm inside the chest.
Then every finished piece is re-tested against the body's full BVH. Numbers per piece are
in `_report.json` (`fit`): vertices, % inside, penetration, gap, lowest point.

## THE FIT REPORT - WHAT IS ACTUALLY WRONG

Honest list. Nothing here is cropped out of the sheets.

### Faults that are real and not fixed yet
1. **The carried weapon passes through the owner on seven of the ten** - 0.020 m (mage) to
   0.040 m (barbarian's greataxe). It is held at the hip and the blade or haft crosses the
   skirt of the armour. From the front it reads as a weapon held at the side; from the
   side the overlap is visible.
2. **The cloak's lower panels cross the hips** - up to 0.184 m on the paladin, 0.092 m on
   the rogue. The cloak hangs from the measured shoulder but flares straight down while
   the body widens at the hip. Hidden from the front, wrong from the side.
3. **The robe skirt crosses the legs** - 0.131 m (sage), 0.202 m (cleric). Same cause.
4. **Rings are invisible at showcase framing.** A 5 cm ring on a 2.3 m figure is two
   pixels. It is correctly placed on the finger (the fit rows prove it) and it will only
   ever be seen in the hub icon, which is the same derivation.
5. **The helm's nasal bar is hidden behind the brow band** from the front.
6. **Mage and Sage share a body AND the body's own hat**; Duelist and Cleric share the
   hooded body. Tinting pulls them apart somewhat, but at a glance each pair is close.
   Six KayKit bodies carry ten heroes and that is the cost.
7. **The top-down view shows scalp.** It is in the sheet because it was asked for, but it
   proves nothing about fit on a body that is half head. A 60-degree high angle would.
8. **No shield anywhere.** `classes.json` says the cleric "carries a shield"; there is no
   shield slot in items.json and none was invented.

### Numbers that look like faults and are NOT
A boot contains a foot; a gauntlet contains a hand; a pauldron caps a shoulder; a tasset
hangs over a hip; a sleeve surrounds an arm. Their inner faces are inside the body **by
construction**, which is why `_report.json` shows 60-95% of those pieces "inside". The
test classifies those separately and only calls a fault when a piece is mostly buried.
The remaining `CLIPS` lines in `fit_faults` for tassets, pauldrons, sleeves and the
amulet chain are all of that kind and are listed for completeness, not as defects.

### What was fixed by LOOKING, in four passes
1. **Pass 1: every hero had its own blade lying horizontally through its chest.** The kit
   followed the full shoulder rotation. A carried weapon now follows the hand's
   TRANSLATION only and stays upright - the same ruling E3PO's halberd needed.
2. **Pass 2: the weapon was a lamppost.** Authored at human proportions on a body that is
   46% head. It is now scaled to the measured shoulder height.
3. **Pass 3: the helm was invisible** - built around the head BONE, which is at the neck,
   so it rendered inside the chest. Then, built around the measured skull, it was a closed
   sphere that swallowed the face. It is now a skullcap stopping above the eyes with a
   neck guard behind.
4. **Pass 4: all ten wore the same mud.** Wear mixed every surface toward one grey-brown,
   so leather, iron and wool arrived at the same colour. Wear now desaturates toward the
   colour's OWN grey, and metalness came down - a mirror in an empty world renders black,
   which is why the tier ladder was invisible.

## Verification
Engine `BLENDER_EEVEE`. Blank check: **40 PNGs, 0 failures**. Every view also tests
whether any vertex fell outside the FIXED frame - all ten are 0, so nothing is cropped and
no view is zoomed to flatter a piece: one ortho height (3.30 m) and one camera centre
(1.28 m) for all ten, and one lighting rig.
Cost: 1744-3562 tris of gear per hero, 15-30 objects, merged by material.

## Handed to the GAME BUILD worker
1. `assets/characters/bellmire/showcase/<key>_kit.glb` - rest-space kits, one object per
   material per part, **origin on the bone it hangs from**, same contract as `e3po_kit.glb`.
   Parent and the animation carries them. The weapon is the exception: parent it to the
   hand in TRANSLATION ONLY or it cartwheels.
2. `dress_cosmetics()` taking the ITEM: the derivation it needs is `tools/art/showcase.py`
   plus `icons.py`'s `variant_for` / `STAT_GEM` / `METALS` - the same three inputs.
3. The body's own hat and cape must be HIDDEN when a helm or cloak is worn.
   `_report.json` lists per hero which meshes were hidden here.
4. The in-engine half of D95 - ten dressed heroes standing up in Godot - should use a
   60-degree high angle in place of the top-down, per fault 7.

## Licence
All gear geometry is original vertex maths through `lordlib`. The bodies are KayKit
Adventurers 2.0 by Kay Lousberg, CC0, already in the repo and read for measurement and
rendering only - never re-exported. No Quaternius Bestiary / QAL.
