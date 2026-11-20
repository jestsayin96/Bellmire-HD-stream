# PACK CATALOGUE - the extracted packs in C:\hd adventure\_packs

Written by the hub lane, 20 Nov 2026 08:5x CT, on the 07:58 TAKE THIS NEXT row (Mr. E's 07:24 batch-wiring directive). READ-ONLY on every pack: nothing was moved, converted or opened in Godot or Blender.

**How it was measured.** A directory walk of `C:\hd adventure\_packs` (49 extracted folders; the sibling .zip/.7z archives are not counted - they hold the same files). Counts are every file, by lower-cased extension (top 7 shown). Size is the sum of file bytes, MB = 10^6. Licence text was read from the pack's own licence/readme file; `.html` licences were tag-stripped. A pack with **no licence file is listed as such and is NOT assumed CC0**.

**What is NOT measured here.** The `Feeds` column is a PROPOSAL from pack name and contents, not a decision read from the plan - the game build owns the mapping. Directories already measured by art are in `renders/art/worldfit/_manifest.json` (five directories under `assets/`: buildings, dungeon, mkprops, nature, props - 173 files) and were not re-measured; this table is the layer BEHIND those, the sources.

**Totals:** 49 packs, 10,122 files, 2,408 MB.

## Licence flags (read these first)

- **Not plain CC0:** `Bestiary_Dungeon_Monsters_Kit` (QAL v1), `grass_07` (custom free-use + asks for a link), `forest-monster` (CC0 stated, but textures derived from another author's).
- **Licence file unreadable:** `Fantasy_Ruins_Pack` (PDF only).
- **No licence file at all (18 packs):** `3d_crystals_new`, `Animals_Pack_by_Quaternius`, `Castle`, `_extracted_rpg_items`, `_generated`, `dragon_oga`, `dungeon_collection_2`, `dungeon_collection_for_assetforge`, `free_mine_assets`, `golem_clean_blend`, `handpainted_weapons`, `low-poly_RPG_item_collection_2`, `low-poly_RPG_item_collection_3`, `medieval_pack_CC0`, `modular_terrain_collections`, `modular_village_collection`, `quaternius_medieval_weapons_2018_CC0`, `ultimate_animated_character_pack`. Some are covered by a note the game build wrote into `assets/` on first use (e.g. `assets/gear/shields/LICENSE_Quaternius_MedievalWeapons_CC0.txt` for the weapons pack); for the rest the source is in docs/PLAN.md, which this pass did not re-read. Treat as UNVERIFIED until a licence is on file.

## Per pack

| Pack | Files | MB | Extensions | Licence (as read) | Feeds (proposed) |
|---|---:|---:|---|---|---|
| `3d_crystals_new` | 5 | 7.6 | .jpg 4, .blend 1 | **no licence file in pack** | 47 (candidate, mine/crystal dressing) |
| `Animals_Pack_by_Quaternius` | 21 | 4.2 | .blend 5, .fbx 5, .mtl 5, .obj 5, .png 1 | **no licence file in pack** | unassigned (animals; assets/animals already holds the Quaternius farm set) |
| `Bestiary_Dungeon_Monsters_Kit` | 22 | 48.8 | .png 16, .fbx 2, .glb 2, .txt 1, .jpg 1 | **NOT CC0 - Quaternius Asset License (QAL) v1**, `License_Standard.txt` (free-version note: reselling as assets restricted; read the full QAL text before any shipped use) | unassigned (monsters; QAL licence) |
| `Castle` | 15 | 106.9 | .fbx 11, .tga 3, .psd 1 | **no licence file in pack** | 15 (candidate, castle/town buildings; 107 MB, mostly 11 fbx) |
| `Church1_blend` | 17 | 20.7 | .jpg 14, .html 1, .blend 1, .dae 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: church; chapel exists as assets/buildings/lm_chapel) |
| `Fantasy_Props_MegaKit` | 517 | 162.9 | .fbx 94, .bin 94, .gltf 94, .mtl 94, .obj 94, .png 43, .jpg 3 | CC0 1.0 (read off the pack's licence file) - `License_Standard.txt` | 47 + 17 (props/market dressing; part of it already live in assets/props) |
| `Fantasy_Ruins_Pack` | 110 | 36.7 | .jpg 39, .png 35, .dts 12, .dae 12, .cs 11, .pdf 1 | UNREAD - only `3TD_CC0_License_EULA.pdf` is present; the filename says CC0 but the PDF was not text-read | 47 (candidate, ruins) |
| `HandPainted_Plants` | 36 | 10.9 | .fbx 15, .obj 15, .jpg 3, .tga 2, .txt 1 | CC0 1.0 (read off the pack's licence file) - `ReadMe - Licence.txt` | 68 (nature) |
| `House1_blend` | 3 | 7.9 | .html 1, .blend 1, .jpg 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: a house; blend + jpg only, no glTF) |
| `House2_blend` | 3 | 8.8 | .html 1, .blend 1, .jpg 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: a house; blend + jpg only, no glTF) |
| `House3_blend` | 3 | 8.6 | .html 1, .blend 1, .jpg 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: a house; blend + jpg only, no glTF) |
| `House4_blend` | 3 | 10.8 | .html 1, .blend 1, .jpg 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: a house; blend + jpg only, no glTF) |
| `KayKit_Forest_Nature_Pack_1.0_FREE` | 641 | 11.7 | .fbx 210, .bin 105, .gltf 105, .mtl 105, .obj 105, .png 7, .url 3 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 68 (nature) |
| `KayKit_RPGToolsBits_1.0_FREE` | 339 | 7.1 | .fbx 98, .mtl 59, .obj 59, .bin 49, .gltf 49, .png 21, .url 3 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (tools/bits; 17 market candidate) |
| `KayKit_ResourceBits_1.0_FREE` | 466 | 17.6 | .fbx 152, .bin 76, .gltf 76, .mtl 76, .obj 76, .png 6, .url 3 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 17 (candidate, market goods/resources) |
| `Medieval_Village_MegaKit` | 936 | 174.3 | .fbx 176, .bin 176, .gltf 176, .mtl 176, .obj 176, .png 54, .txt 1 | CC0 1.0 (read off the pack's licence file) - `License_Standard.txt` | 15 (town buildings; the largest by file count) |
| `Smith1_blend` | 3 | 5.1 | .html 1, .jpg 1, .blend 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: the smithy; blend + jpg only, no glTF) |
| `Stone_coffin` | 5 | 2.2 | .tga 1, .jpg 1, .txt 1, .fbx 1, .obj 1 | CC0 1.0 (`readme.txt`), provided by Nobiax | 47 (candidate, crypt prop) |
| `ThePaintedWench_blend` | 3 | 5.4 | .html 1, .jpg 1, .blend 1 | Creative Commons Zero (Public Domain), by Daniel74 - read off the html licence | 15 (town building: the tavern; blend + jpg only, no glTF) |
| `Ultimate_Animated_Animals` | 63 | 129.1 | .blend 12, .fbx 12, .gltf 12, .mtl 12, .obj 12, .txt 1, .jpg 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (animals) |
| `Ultimate_Monsters` | 69 | 72.4 | .fbx 18, .obj 17, .mtl 15, .blend 11, .gltf 4, .png 2, .txt 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (monsters) |
| `Ultimate_Stylized_Nature` | 369 | 471.1 | .blend 64, .fbx 63, .mtl 63, .obj 63, .bin 36, .gltf 36, .png 36 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 68 (nature; the largest pack, 471 MB) |
| `_extracted_rpg_items` | 106 | 3.2 | .fbx 106 | **no licence file in pack** | unassigned (gear; fbx only, no licence file) |
| `_generated` | 21 | 68.0 | .png 16, .glb 5 | **no licence file in pack** | unassigned (this project's own generated output, not a third-party pack) |
| `dragon_oga` | 11 | 4.6 | .dae 5, .blend 2, .png 2, .mtl 1, .obj 1 | **no licence file in pack** | unassigned (monster/boss) |
| `dungeon_collection_2` | 180 | 1.9 | .mtl 90, .obj 90 | **no licence file in pack** | 47 (candidate) |
| `dungeon_collection_for_assetforge` | 112 | 0.5 | .mtl 56, .obj 56 | **no licence file in pack** | 47 (candidate) |
| `forest-monster` | 10 | 45.8 | .png 8, .blend 1, .txt 1 | Creative Commons (CC0), author Cestmir Dammer (`Licenses.txt`); textures derived from Rick Hoppmann's - derivation not separately licensed in the file | unassigned (monster) |
| `free_mine_assets` | 9 | 27.6 | .png 7, .blend 2 | **no licence file in pack** | 47 (candidate, mine dressing) |
| `golem_clean_blend` | 1 | 7.0 | .blend 1 | **no licence file in pack** | unassigned (monster) |
| `grass_07` | 8 | 6.5 | .tga 4, .fbx 1, .obj 1, .jpg 1, .txt 1 | Custom free-use note by Nobiax (`readme.txt`): free for personal/commercial work, asks for a link to the result - NOT a CC0 grant; a soft condition | 68 (nature) |
| `handpainted_weapons` | 72 | 5.9 | .png 42, .mtl 14, .obj 14, .blend 2 | **no licence file in pack** | unassigned (gear) |
| `kaykit_character_animations_CC0` | 53 | 9.0 | .fbx 22, .png 7, .mtl 6, .obj 6, .pdf 3, .dae 3, .url 2 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (character animation) |
| `kaykit_dungeon_pack_CC0` | 1,079 | 85.9 | .mtl 226, .obj 226, .fbx 208, .dae 202, .glb 192, .png 12, .gltf 10 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 47 (dungeon props; parts already in assets/gear/dungeon) |
| `kenney_3d-road-tiles` | 915 | 6.9 | .mtl 302, .obj 302, .gltf 302, .url 3, .txt 2, .png 2, .py 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 38 (roads) |
| `kenney_fantasy-town-kit_2.0` | 847 | 10.6 | .png 174, .fbx 167, .glb 167, .mtl 167, .obj 167, .url 3, .txt 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 15 + 17 (town buildings / stalls) |
| `kenney_graveyard-kit_5.0` | 465 | 12.6 | .png 96, .fbx 91, .glb 91, .mtl 91, .obj 91, .url 3, .txt 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 47 (candidate, graveyard) |
| `kenney_retro-fantasy-kit` | 562 | 5.6 | .png 137, .fbx 105, .glb 105, .mtl 105, .obj 105, .url 3, .txt 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 15 / 47 (mixed; candidate) |
| `low-poly_RPG_item_collection_2` | 27 | 6.9 | .png 17, .obj 8, .3ds 1, .blend 1 | **no licence file in pack** | unassigned (gear) |
| `low-poly_RPG_item_collection_3` | 27 | 25.4 | .png 18, .obj 7, .3ds 1, .blend 1 | **no licence file in pack** | unassigned (gear) |
| `medieval_pack_CC0` | 28 | 4.9 | .blend 8, .mtl 7, .obj 7, .png 5, .blend1 1 | **no licence file in pack** | 15 (candidate; name only - no licence file) |
| `modular_terrain_collections` | 264 | 2.8 | .mtl 132, .obj 132 | **no licence file in pack** | 68 / 38 (candidate, terrain pieces; obj only) |
| `modular_village_collection` | 143 | 4.7 | .obj 142, .mtl 1 | **no licence file in pack** | 15 (candidate; obj only) |
| `quaternius_medieval_weapons_2018_CC0` | 97 | 24.7 | .blend 24, .fbx 24, .mtl 24, .obj 24, .png 1 | **no licence file in pack** | unassigned (gear; already under assets/gear/shields) |
| `quaternius_rpg_characters_CC0` | 60 | 39.9 | .fbx 12, .mtl 12, .obj 12, .blend 11, .png 11, .txt 1, .jpg 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (characters) |
| `quaternius_ultimate_rpg_items_CC0` | 533 | 100.5 | .png 107, .blend 106, .fbx 106, .mtl 106, .obj 106, .txt 1, .jpg 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | unassigned (gear; seven models already in assets/gear/artifact) |
| `rocks` | 32 | 237.3 | .tga 15, .jpg 6, .fbx 5, .obj 5, .txt 1 | CC0 (`readme.txt`; snippet only, the full text was not read) | 68 (nature; 237 MB, 5 fbx) |
| `ultimate_animated_character_pack` | 209 | 228.5 | .blend 52, .fbx 52, .mtl 52, .obj 52, .png 1 | **no licence file in pack** | unassigned (characters) |
| `ultimate_nature_pack_by_quaternius` | 602 | 99.6 | .blend 150, .fbx 150, .mtl 150, .obj 150, .txt 1, .jpg 1 | CC0 1.0 (read off the pack's licence file) - `License.txt` | 68 (nature) |

## By system (proposed)

- **15:** `Castle`, `Church1_blend`, `House1_blend`, `House2_blend`, `House3_blend`, `House4_blend`, `Medieval_Village_MegaKit`, `Smith1_blend`, `ThePaintedWench_blend`, `kenney_fantasy-town-kit_2.0`, `kenney_retro-fantasy-kit`, `medieval_pack_CC0`, `modular_village_collection`
- **47:** `3d_crystals_new`, `Fantasy_Props_MegaKit`, `Fantasy_Ruins_Pack`, `Stone_coffin`, `dungeon_collection_2`, `dungeon_collection_for_assetforge`, `free_mine_assets`, `kaykit_dungeon_pack_CC0`, `kenney_graveyard-kit_5.0`
- **68:** `HandPainted_Plants`, `KayKit_Forest_Nature_Pack_1.0_FREE`, `Ultimate_Stylized_Nature`, `grass_07`, `modular_terrain_collections`, `rocks`, `ultimate_nature_pack_by_quaternius`
- **17:** `KayKit_ResourceBits_1.0_FREE`
- **38:** `kenney_3d-road-tiles`
- **unassigned:** `Animals_Pack_by_Quaternius`, `Bestiary_Dungeon_Monsters_Kit`, `KayKit_RPGToolsBits_1.0_FREE`, `Ultimate_Animated_Animals`, `Ultimate_Monsters`, `_extracted_rpg_items`, `_generated`, `dragon_oga`, `forest-monster`, `golem_clean_blend`, `handpainted_weapons`, `kaykit_character_animations_CC0`, `low-poly_RPG_item_collection_2`, `low-poly_RPG_item_collection_3`, `quaternius_medieval_weapons_2018_CC0`, `quaternius_rpg_characters_CC0`, `quaternius_ultimate_rpg_items_CC0`, `ultimate_animated_character_pack`

glTF is present in `Medieval_Village_MegaKit`, `kenney_fantasy-town-kit_2.0`, `Ultimate_Stylized_Nature` and `KayKit_Forest_Nature_Pack_1.0_FREE`. `ultimate_nature_pack_by_quaternius` and `Castle` are fbx/obj/blend or fbx only (no glTF) and the seven `*_blend` house/church/smith/tavern packs are blend + jpg only, so they need the same Blender export the weapons packs got.

## Reproduce
The walk is ~25 lines of Python (`os.walk`, `os.path.getsize`, a licence-file regex), run once from the Blender bridge on 20 Nov. Counts drift only if someone adds to `_packs`.

