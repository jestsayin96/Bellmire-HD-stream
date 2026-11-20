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

### 17 Nov 2026 - S18, System 2 second half (part 2): dungeon-pack daggers in the hand (game build)
Three more models from the **KayKit Dungeon Pack 1.0 (Kay Lousberg, CC0 1.0)**, same licence file already
beside them: `dagger_{common,uncommon,rare}.glb` in `assets/gear/dungeon/`, copied unchanged from
`_packs/kaykit_dungeon_pack_CC0/Models/gltf/` (renamed from `*.gltf.glb`). Wired as gear.gd KINDS dagger
tiers 1-3. The pack's staves were copied, rendered, judged wrong in the hand and REMOVED the same hour -
they are not in the repo.

### 17 Nov 2026 - S19, System 2 second half (part 3): dungeon-pack staves and crossbows in the hand (game build)
Six more models from the **KayKit Dungeon Pack 1.0 (Kay Lousberg, CC0 1.0)**, same licence file already
beside them: `staff_{common,uncommon,rare}.glb` and `crossbow_{common,uncommon,rare}.glb` in
`assets/gear/dungeon/`, copied unchanged from `_packs/kaykit_dungeon_pack_CC0/Models/gltf/` (renamed from
`*.gltf.glb`). Wired as gear.gd KINDS staff and crossbow tiers 1-3. The staves S18 removed are back, now
with a measured held rotation (gear.gd held_rot) and x1.9 scale.

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

> TEAM LEAD NOTE, 2026-11-17 12:58 CT, on merging the two rows above. BOTH ARE KEPT AND BOTH
> WERE TRUE WHEN WRITTEN. They disagree on one fact and this merge is what settles it: the game
> build removed its own staff copies at S18 after judging them in the hand, and the art lane
> committed the full fifteen in the same hour. AFTER THIS MERGE staff_*, crossbow_*, axeDouble_*
> and shield_* ARE in assets/gear/dungeon/ - art's copies - and nothing in scripts/ reads them
> yet. That is queued work with art's carry numbers attached (docs/art/SYSTEM2_WEAPONS.md), not
> a stray asset. One licence covers all 24; no new row is owed.

> TEAM LEAD ADDENDUM, 2026-11-17 14:58 CT. The 12:58 note above ends "nothing in scripts/ reads
> them yet". THAT CLAUSE IS NOW OUT OF DATE and I am correcting it where it sits rather than
> editing what was true when written. As of S19 and S20 all 24 dungeon-pack models ARE read:
> sword/axe/hammer at S16-S17, dagger at S18, staff and crossbow at S19, axeDouble and shield at
> S20 (shield_* via a runtime format string at roster.gd:886, which a literal filename search
> cannot see - see this hour's dead-data audit). The licence row and the merge note stand
> unchanged; only the "nothing reads them" clause is superseded.

### 17 Nov 2026 - THE TAPSTER (miniboss 21): `assets/props/` enters the log
`assets/monsters/minibosses/tapster.glb` embeds decimated geometry from three
models in **`assets/props/`** - `Barrel.gltf`, `SmallBottle.gltf` and
`Mug.gltf`. That directory (309 files) was **already committed to this repo and
was NOT in this file**, which is a gap in the log and is closed here rather
than worked around.

| Pack | Author | Licence | Licence text on disk | Contents used |
|---|---|---|---|---|
| Fantasy Props MegaKit (FREE version) | Quaternius | **CC0 1.0 Universal** | `assets/props/LICENSE_FantasyPropsMegaKit_CC0.txt` | `Barrel` (cask, slot 0 only), `SmallBottle` (the hung flasks), `Mug` (the jack), `Bucket_Wooden_1` (the Strickler's measure), `Pouch_Large` x3 (the Strickler's weights) |

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

### 17 Nov 2026 - THE STRICKLER (miniboss 23): two more props, and a new cap rule
`Bucket_Wooden_1.gltf` (the measure) and `Pouch_Large.gltf` x3 (the weights
hanging off the balance beam) come from the same CC0 Fantasy Props MegaKit
already logged above - same pack, same licence file, no new source and no new
attribution obligation. The files in `assets/props/` are untouched; they are
read, normalised into the unit cube and placed by `tools/art/minibosses.py`.

NEW THIS RUN, AND IT IS A LICENCE-NEUTRAL BUT IMPORTANT NOTE: these two go
through `_prop_mesh_m`, which reads the primitive and triangle counts off the
.gltf JSON before import and caps by the model rather than by a constant. Both
shipped at full density (976 and 730 triangles). See docs/art/PROPS_SLOT_AUDIT.md
for why the old fixed cap was the real cause of the torn Barrel.

## System 7 - armour variety (19 Nov 2026, art lane)

The five armour bodies of the Quaternius **Ultimate RPG Items Pack (Aug 2019)** - `Armor_Black`,
`Armor_Golden`, `Armor_Leather`, `Armor_Metal`, `Armor_Metal2` - are now fitted to the KayKit hero
body and exported to `assets/gear/armour/*.glb`. The pack is already recorded in the table above;
its licence file is `License.txt` inside the pack and reads, verbatim: "License: CC0 1.0 Universal
(CC0 1.0) Public Domain Dedication". I read that file this run rather than a search snippet.
No attribution is required; the pack is cleared for commercial use and nothing is redistributed as
an asset. Source geometry is unmodified - the fit is a transform (uniform scale, a depth scale and
a depth offset) baked at export. Measurements and the fit proof: `renders/art/s7_armour/`.

## System 8 - shields (game build S50, 19 Nov 2026)
The five shields of the Quaternius **Medieval Weapons Pack (Sept 2018)** (row above, CC0 1.0) -
`Shield_Celtic_Golden`, `Shield_Heater`, `Shield_Heater_2`, `Shield_Round`, `Shield_Round_2` - copied
unmodified as FBX into `assets/gear/shields/` with `LICENSE_Quaternius_MedievalWeapons_CC0.txt` beside
them (the extracted pack carries no licence file; the note is ours). `_packs/handpainted_weapons/`
shield_a..d were NOT used: that folder carries no licence file and no source, so its licence is
unverified and it stays out until one is read.
### 19 Nov 2026 - THE BESTIARY KIT ENTERS THE LOG, AND IT WAS ALREADY IN THE REPO

`assets/monsters/Imp.glb`, `Puglin.glb` and their four texture maps each were
**committed to this repo before this file existed** and were never logged. That
is the same gap `assets/props/` had on 17 Nov, closed the same way - by writing
the row rather than working around it.

The first monster-pack variant miniboss, `assets/monsters/minibosses/broodglut.glb`
(see `docs/art/MONSTER_VARIANTS.md`), is the repo's `Puglin.glb` geometry wearing
the kit's own alternate skin `T_Puglin_BaseColor_2.png`, with all four maps
brought down to 1024 - 2.98 MB against the 7.85 MB original. No pack file is
re-exported as a standalone asset and nothing is redistributed AS an asset,
which is the only line the QAL draws.

| Pack | Author | Licence | Licence text on disk | Contents used |
|---|---|---|---|---|
| Bestiary - Dungeon Monsters Kit (Standard / FREE) | Quaternius | **Quaternius Asset License (QAL) v1.0** | `_packs/Bestiary_Dungeon_Monsters_Kit/Bestiary - Dungeon Monsters Kit[Standard]/License_Standard.txt` | `Imp.glb`, `Puglin.glb` (rigged, unanimated) and their `BaseColor_1/2/3`, `Emissive`, `Normal`, `ORM` maps. `BaseColor_2` is the Broodglut's skin. |

**The licence page was read on disk this run, not inferred from a search
snippet** - that is the rule, and reading a snippet instead is exactly how the
wrong Quaternius ban got made on 16 Nov. QAL v1.0 grants a worldwide,
royalty-free, non-exclusive, perpetual licence for personal, educational AND
commercial use, with no credit required; the single restriction is reselling or
redistributing the Assets as Assets. The row is kept anyway.

**NOTE FOR ANYONE WHO MEASURES THESE FILES.** Imported into Blender they appear
to carry a stray 42-vertex `Icosphere` of radius 1 on the origin, and if it is
measured with the body the creature reports 1.902 x 2.000 x 2.000 instead of
1.468 x 0.611 x 0.931. **It is not in the file.** The string does not occur in
the bytes of a glb that nonetheless imports one; a rigged glb gets one and an
unrigged one does not. It is a Blender 5.2 glTF-import artifact for any glb
carrying an armature, so it is not in the shipped asset and not in Godot.
Drop it before measuring; do not report it as a defect.

---

## TIER 1 PACKS MEASURED 20 NOV 2026, 08:4x CT (worldfit, read-only)

Mr. E's 07:24 directive put Systems 15 (town buildings), 47 (dungeon props) and
68 (nature) in Tier 1 and told the fleet to wire WHOLE PACK DIRECTORIES. The art
lane measured the directories below with `tools/art/worldfit.py` so the game
build can batch-wire them (`renders/art/worldfit/_packs_manifest.json`).

**MEASURING A PACK COPIES NOTHING.** Not one file below was imported into
`assets/`, re-exported, or modified by this run; worldfit opens each file in a
throwaway scene and reads its bounds. These rows exist because the NUMBERS are
now published and the game build has been told to wire from them - a licence has
to be on the ledger before that, not after.

**EVERY LICENCE BELOW WAS READ OFF THE PACK'S OWN LICENCE FILE ON DISK THIS
RUN.** No search snippets. All six are CC0 1.0 Universal, which permits
commercial use with no attribution; credit is kept anyway.

| Pack | Author | Licence | Licence text on disk | Directory measured |
|---|---|---|---|---|
| Medieval Village MegaKit (Standard / FREE) | Quaternius | **CC0 1.0** | `_packs/Medieval_Village_MegaKit/Medieval Village MegaKit[Standard]/License_Standard.txt` | `.../glTF` (176 files) |
| Fantasy Town Kit 2.0 | Kenney (www.kenney.nl) | **CC0 1.0** | `_packs/kenney_fantasy-town-kit_2.0/License.txt` | `.../Models/GLB format` (167) |
| KayKit Forest Nature Pack 1.0 FREE | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0** | `_packs/KayKit_Forest_Nature_Pack_1.0_FREE/.../License.txt` | `.../Assets/gltf` (105) |
| Ultimate Stylized Nature (May 2022) | Quaternius | **CC0 1.0** | `_packs/Ultimate_Stylized_Nature/Ultimate Stylized Nature - May 2022/License.txt` | `.../glTF` (36) |
| KayKit Dungeon Pack 1.0 | Kay Lousberg | **CC0 1.0** | `_packs/kaykit_dungeon_pack_CC0/License.txt` | `.../Models/gltf` (185) |
| Graveyard Kit 5.0 | Kenney | **CC0 1.0** | `_packs/kenney_graveyard-kit_5.0/License.txt` | not measured this run - row written while the file was open |

### ONE THING WRONG IN A LICENCE FILE, AND IT IS QUATERNIUS'S, NOT OURS
`Ultimate_Stylized_Nature/.../License.txt` opens **"Ultimate Platformer Pack by
@Quaternius"** - the wrong pack name, a copy-paste in the vendor's own file. The
grant underneath it is unambiguous CC0 1.0 with the Public Domain Dedication URL,
and Quaternius's blanket licence covers the pack either way, so the pack is
clear to use. It is recorded here so that nobody later quotes that file as proof
for the Stylized Nature pack without knowing it names another one. **If a
stricter proof is ever wanted, the authority is quaternius.com's licence page for
this pack, not this text file.**

## LICENCE GATE - THE PACKS WITH NO LICENCE FILE ON DISK (20 Nov 2026, 10:0x CT)

The 08:58 plan row carries Mr. E's rule as enforcement: **no model out of a pack
without a read licence goes into `assets/`.** Measuring a pack copies nothing and
is not gated; importing is.

**I COUNTED THIS MYSELF OFF THE TREE AND I GET A DIFFERENT NUMBER TO THE HUB'S.**
The hub's catalogue flags **18 of 49**. Walking `_packs` for a file whose name
contains `licence`/`license`/`copying` I get **21 of 49** - and two of those 21
(`_extracted_rpg_items`, `_generated`) are OUR OWN working directories, not
third-party packs at all, so the real figure is **19 third-party packs**. The
likely cause of the spread is the recipe: I do NOT accept a bare `README` as a
licence file, and a README is exactly where several of these state their terms.
Neither number is wrong; they answer different questions. Read the page, not the
count.

NO LICENCE FILE FOUND ON DISK - IMPORT GATED UNTIL THE PAGE IS READ:
3d_crystals_new, Animals_Pack_by_Quaternius, Castle, Stone_coffin, dragon_oga,
dungeon_collection_2, dungeon_collection_for_assetforge, free_mine_assets,
golem_clean_blend, grass_07, handpainted_weapons, low-poly_RPG_item_collection_2,
low-poly_RPG_item_collection_3, medieval_pack_CC0, modular_terrain_collections,
modular_village_collection, quaternius_medieval_weapons_2018_CC0, rocks,
ultimate_animated_character_pack.
(plus `_extracted_rpg_items` and `_generated`, which are ours.)

*** NOTE THE TRAP IN THAT LIST: `medieval_pack_CC0` AND
*** `quaternius_medieval_weapons_2018_CC0` CARRY "CC0" IN THEIR FOLDER NAMES AND
*** STILL HAVE NO LICENCE FILE IN THEM. A folder name is not a licence, in
*** exactly the way a search snippet is not a licence. Both are gated.

**THE BATCH-READY WORK IS NOT GATED BY THIS.** All five directories measured in
worldfit pass 2 carry a licence file that was read off disk on 20 Nov:
`kaykit_dungeon_pack_CC0` (185, System 47), `Medieval_Village_MegaKit` (176) and
`kenney_fantasy-town-kit_2.0` (167) for System 15, `KayKit_Forest_Nature_Pack_1.0_FREE`
(105) and `Ultimate_Stylized_Nature` (36) for System 68 - 669 rows, all CC0 1.0.
