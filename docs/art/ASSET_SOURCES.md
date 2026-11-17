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
