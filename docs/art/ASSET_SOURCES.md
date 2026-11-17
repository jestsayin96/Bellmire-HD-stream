# ASSET_SOURCES.md — third-party art packs

Every downloaded pack is logged here. Binding rule (D95):
**CC0 preferred. CC-BY only with attribution recorded in this file.
CC-BY-NC and CC-BY-ND are FORBIDDEN — the stream takes bits and is commercial.
CC-BY-SA is FORBIDDEN — share-alike would infect the repo.**

Packs live at `C:\hd adventure\_packs\` (not committed — binaries stay out of git).
Downloaded 2026-11-16 by the supervisor lane for D94 / D95.

| Pack | Author | Licence | Source | Contents | Format |
|---|---|---|---|---|---|
| Ultimate RPG Items Pack (Aug 2019) | Quaternius | CC0 1.0 | opengameart.org/node/126979 | 106 models: Ring1-7, Necklace1-3, Armor_Black/Golden/Leather/Metal/Metal2, Crystal1-5 (+damaged), Sword/Sword_Golden/Sword_big, Dagger, Axe_Double, Axe_small, Hammer_Double, Bow_Wooden/Golden, Crown, Crown2, Glove, Backpack, Pouch, Chalice, 22 potions, keys, coins, books | FBX / OBJ / BLEND |
| KayKit Dungeon Pack 1.0 | Kay Lousberg | CC0 1.0 | opengameart.org/content/kaykit-dungeon-pack-10 | 186 glTF models. 8 weapon families x 3 rarity tiers (axe, axeDouble, crossbow, dagger, hammer, shield, staff, sword in common/uncommon/rare), plus artifact, chests x3 tiers, 4 rigged characters (barbarian, knight, mage, rogue) with 3 alternate heads each | **glTF/GLB** + FBX/OBJ/DAE |
| Medieval Weapons Pack (Sept 2018) | Quaternius | CC0 1.0 | opengameart.org/content/lowpoly-medieval-weapons | 24 models: Claymore, Scythe, Spear, Shield_Heater x2, Shield_Round x2, Shield_Celtic_Golden, Bow_Evil, 4 swords, 2 daggers, 3 axes, 2 hammers | FBX / OBJ / BLEND |
| LowPoly RPG Characters (Nov 2020) | Quaternius | CC0 1.0 | opengameart.org/content/lowpoly-rpg-characters | 12: Cleric, Monk, Ranger, Rogue, Warrior, Wizard + their held weapons | FBX / OBJ / BLEND |
| KayKit Character Animations 1.0 | Kay Lousberg | CC0 1.0 | opengameart.org/content/kaykit-character-animations | Animation library + PrototypePete rig | FBX / glTF / DAE |
| 19 Low-Poly Fantasy Weapons | (OGA upload) | CC0 | opengameart.org/content/19-low-poly-fantasy-weapons | 19 weapons in one blend | BLEND |
| Low poly medieval weapons | (OGA upload) | CC0 | opengameart.org/content/low-poly-medieval-weapons | Club, Dagger, Katana, LongSword, ShortSword, SimpleAxe, Spear | OBJ / BLEND |

## REJECTED on licence — do not use
- **Kingdom Weapon Set** (pfunked, OGA) — CC-BY-SA 3.0. Share-alike. Rejected.
- **Stylised Fantasy Weapons** (OGA) — CC-BY 3.0. Legal but carries a permanent
  attribution obligation; not taken while CC0 covers the need. Available if wanted.

## Notes for the art lane
1. **Use what is already in the repo first.** 61 weapon/shield models are already
   committed and `gear.gd` wires none of them.
2. Only the KayKit packs ship glTF. The Quaternius packs are FBX/OBJ/BLEND and
   need a headless Blender batch convert to .glb before Godot can load them.
3. KayKit files carry a double extension (`axe_common.gltf.glb`). Rename on import.
4. Licence text ships inside each zip. Keep it with the converted assets.

## Assets supplied by Mr. E

| Asset | Source | Licence | Notes |
|---|---|---|---|
| `assets/gear/wand_crystal.glb` | Supplied by Mr. E, 2026-11-16 05:03 | Mr. E's own — no third-party rights | Crystal-headed wand: dark tapered shaft, silver collar, blue faceted crystal. Raw drop was 306,024 tris / 24 MB with two 4096 and one 2048 map. Shipped version is decimated to 8,000 tris with three 1024 maps, 2.38 MB; silhouette, facets and collar all survive — checked on screen before commit. Origin moved to the BASE OF THE GRIP so it hangs off a hand bone. 0.147 x 0.218 x 0.921 units. The untouched original is kept OUT of git at `C:\hd adventure\_packs\_generated\wand_raw.glb`. |

**NOT YET FITTED TO A BODY.** It has not been rendered on a KayKit hero, so by the FIT IS THE
ACCEPTANCE TEST rule it is not finished. At 0.921 long against a hero whose head sits at y
1.05-1.22, this reads closer to a short staff than a wand — Mr. E should say which he wants
before anyone scales it. The game build lane owns the attach (handslot.r) and the gear.gd entry.

## 2026-11-17 - `assets/gear/` geometry now rides inside a miniboss glb

`assets/monsters/minibosses/quartermaster.glb` (the sixteenth miniboss) embeds
decimated geometry from `assets/gear/spear_A.gltf` and `assets/gear/shield_A.gltf`
- the **KayKit Dungeon Pack 1.0, Kay Lousberg, CC0 1.0** already listed in the
table above. CC0 permits incorporation and redistribution inside our own work
with no attribution required; the row above is kept anyway. **No pack file is
re-exported as a standalone asset** and nothing is redistributed AS an asset,
which is the only line the Quaternius licence draws either. The decimate is a
Blender modifier applied at import time inside `tools/art/minibosses.py`; the
files in `assets/gear/` are untouched.

### 17 Nov 2026 - THE LOADER (miniboss 17)
Uses three more models from the **KayKit Dungeon Pack 1.0 (Kay Lousberg, CC0
1.0)** already listed in the table above - `crate`, `barrelDark` and
`lootSackA`, read out of `_packs/kaykit_dungeon_pack_CC0/Models/gltf/` at
generation time, decimated and **baked into the exported `loader.glb`**. CC0,
so no attribution is required and none is owed; recorded here because every
pack used gets recorded. Nothing is redistributed as an asset. The generator
falls back to procedural boxes if the pack is absent and the report records
`pack_used` either way.

### 17 Nov 2026 - S16, System 2 first half: dungeon-pack swords in the hand (game build)
Three models from the **KayKit Dungeon Pack 1.0 (Kay Lousberg, CC0 1.0)**, already in the table
above - `sword_common`, `sword_uncommon`, `sword_rare` - COPIED UNCHANGED into
`assets/gear/dungeon/` as `.glb` (renamed from `*.gltf.glb`) with the pack's own `License.txt` beside
them as `LICENSE_KayKit_Dungeon_CC0.txt`. Licence read off that file on first use by the game build,
10:10 CT: "License: (Creative Commons Zero, CC0) ... free to use in personal, educational and
commercial projects", crediting optional. Wired as gear.gd `KINDS["sword"]` tiers 1-3. Nothing
redistributed as an asset.

### 17 Nov 2026 - S17, System 2 second half (part 1): dungeon-pack axes and hammers in the hand (game build)
Six more models from the **KayKit Dungeon Pack 1.0 (Kay Lousberg, CC0 1.0)**, same licence file already
beside them: `axe_{common,uncommon,rare}.glb` and `hammer_{common,uncommon,rare}.glb` in
`assets/gear/dungeon/`, copied unchanged from `_packs/kaykit_dungeon_pack_CC0/Models/gltf/` (renamed
from `*.gltf.glb`). Wired as gear.gd KINDS axe and mace tiers 1-3.

## KayKit Dungeon Pack 1.0 - the tiered weapon ladder (S2, art's half of System 2)
- Pack: KayKit : Dungeon Pack (1.0)
- Author: Kay Lousberg (www.kaylousberg.com)
- URL: https://kaylousberg.itch.io/kaykit-dungeon
- Licence: CC0 1.0 (Creative Commons Zero) - read off the pack's own License.txt on
  17 Nov 2026, not off a search snippet: "free to use in personal, educational and
  commercial projects", crediting optional. The pack's licence file is copied into
  the repo beside the models at assets/gear/dungeon/LICENSE_KayKit_Dungeon_CC0.txt.
- Date added: 2026-11-17 (sword / axe / hammer were added at S16-S17; the remaining
  fifteen on 2026-11-17 by the art lane)
- What was taken: EIGHT families at three tiers each - 24 models, geometry only,
  unmodified: sword, axe, axeDouble, hammer, dagger, staff, crossbow, shield, each
  in common / uncommon / rare. Nothing was re-exported or re-materialled; the files
  are the pack's own .glb renamed from `<fam>_<tier>.gltf.glb` to `<fam>_<tier>.glb`.
- Where: assets/gear/dungeon/

### 17 Nov 2026 - THE TAPSTER (miniboss 21): `assets/props/` enters the log
`assets/monsters/minibosses/tapster.glb` embeds decimated geometry from three
models in **`assets/props/`** - `Barrel.gltf`, `SmallBottle.gltf` and
`Mug.gltf`. That directory (309 files) was **already committed to this repo and
was NOT in this file**, which is a gap in the log and is closed here rather
than worked around.

| Pack | Author | Licence | Licence text on disk | Contents used |
|---|---|---|---|---|
| Fantasy Props MegaKit (FREE version) | Quaternius | **CC0 1.0 Universal** | `assets/props/LICENSE_FantasyPropsMegaKit_CC0.txt` | `Barrel` (cask, slot 0 only), `SmallBottle` (the hung flasks), `Mug` (the jack) |

**THE LICENCE WAS READ OFF THE FILE ON DISK, NOT OFF A SEARCH SNIPPET** - the
standing rule, and the exact habit that produced the wrong Quaternius ban on
16 Nov. `assets/props/LICENSE_FantasyPropsMegaKit_CC0.txt` states CC0 1.0
Universal Public Domain Dedication, models by @Quaternius, and notes only that
PRO/SOURCE versions carry more models. CC0 permits incorporation and
redistribution inside our own work with no attribution required; the row is
kept anyway because every pack used gets recorded. **Nothing is redistributed
AS an asset.** The decimate is a Blender modifier applied at import time inside
`tools/art/minibosses.py`; the files in `assets/props/` are untouched.

ONE THING WORTH CARRYING TO ANY LANE THAT LOADS FROM THIS PACK: `Barrel.gltf`
is one object with TWO material slots at the same radius to within 1 mm - slot
0 `MI_Trim_Furniture` (the cask) and slot 1 `MI_Trim_Metal` (its hoops). Import
both and they Z-FIGHT; the barrel renders as torn shards with holes in it and
every opacity check still reads green. Take one slot. Other models in this pack
may be built the same way.
