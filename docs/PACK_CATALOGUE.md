# PACK CATALOGUE - the extracted packs in C:\hd adventure\_packs

Written by the hub lane, 20 Nov 2026 08:5x CT, on the 07:58 TAKE THIS NEXT row (Mr. E's 07:24 batch-wiring directive). READ-ONLY on every pack: nothing was moved, converted or opened in Godot or Blender.

**How it was measured.** A directory walk of `C:\hd adventure\_packs` (49 extracted folders; the sibling .zip/.7z archives are not counted - they hold the same files). Counts are every file, by lower-cased extension (top 7 shown). Size is the sum of file bytes, MB = 10^6. Licence text was read from the pack's own licence/readme file; `.html` licences were tag-stripped. A pack with **no licence file is listed as such and is NOT assumed CC0**.

**What is NOT measured here.** The `Feeds` column is a PROPOSAL from pack name and contents, not a decision read from the plan - the game build owns the mapping. Directories already measured by art are in `renders/art/worldfit/_manifest.json` (five directories under `assets/`: buildings, dungeon, mkprops, nature, props - 173 files) and were not re-measured; this table is the layer BEHIND those, the sources.

**Totals:** 49 packs, 10,122 files, 2,408 MB.

## Licence flags (read these first)

- **Not plain CC0:** `Bestiary_Dungeon_Monsters_Kit` (QAL v1), `grass_07` (custom free-use + asks for a link), `forest-monster` (CC0 stated, but textures derived from another author's).
- ~~**Licence file unreadable:** `Fantasy_Ruins_Pack` (PDF only).~~ **STRUCK 20 Nov 2026 23:4x CT - CLEARED CC0 1.0.** The team lead decoded the PDF's ToUnicode CMap independently (65 one-byte bfchar entries, 12,248 characters recovered: "CC0 1.0 Universal ... for any purposes, including without limitation commercial purposes"; WORK_PLAN 20 Nov 23:1x block). Commercial use permitted, no attribution required. This pack is NOT in the 18-pack import gate. I did not re-decode the PDF myself: `_packs` is not mounted in the hub worktree - the clearance rests on the team lead's reproduction.
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
| `Fantasy_Ruins_Pack` | 110 | 36.7 | .jpg 39, .png 35, .dts 12, .dae 12, .cs 11, .pdf 1 | **CC0 1.0 Universal - CLEARED** (`3TD_CC0_License_EULA.pdf`, text-decoded by the team lead 20 Nov 2026; commercial use permitted, no attribution required). Was UNREAD in this table until 20 Nov 23:4x CT. | 47 (candidate, ruins) |
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
| `Stone_coffin` | 5 | 2.2 | .tga 1, .jpg 1, .txt 1, .fbx 1, .obj 1 | **TERMS ON FILE IN readme.txt** - full CC0 1.0 text read 20 Nov 10:4x CT, provided by Nobiax (also asks, non-binding, for a link) | 47 (candidate, crypt prop) |
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
| `grass_07` | 8 | 6.5 | .tga 4, .fbx 1, .obj 1, .jpg 1, .txt 1 | **TERMS ON FILE IN readme.txt (custom grant, NOT CC0)** - free-use note by Nobiax: free for personal/commercial work, asks for a link to the result - NOT a CC0 grant; a soft condition | 68 (nature) |
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
| `rocks` | 32 | 237.3 | .tga 15, .jpg 6, .fbx 5, .obj 5, .txt 1 | **TERMS ON FILE IN readme.txt** - full CC0 1.0 text read 20 Nov 10:4x CT (same Nobiax text as Stone_coffin) | 68 (nature; 237 MB, 5 fbx) |
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

## Where to read the licence for the 18 packs with no licence file (added 20 Nov 2026 09:5x CT, hub lane)

Method: the pack's folder/zip name and inner folder name were matched to a listing page; the page was fetched and the licence line copied as shown. **Page-side CC0 is a claim by the uploader, not a file in the pack**, so art should still record the page URL + date beside any import. `opengameart.org/content/lowpoly-medieval-village-pack` and the Quaternius uploader page refused automated fetch (robots) - those two were NOT read.

**VERIFIED - a listing page names this exact zip and shows its licence line**

| Pack in `_packs` | Listing page (read) | Author on page | Licence line on page | Zip named on page |
|---|---|---|---|---|
| `dungeon_collection_for_assetforge` | https://opengameart.org/content/modular-dungeon-3d-models | Keith at Fertile Soil Productions | License(s): CC0 | `dungeon_collection_for_assetforge.zip` |
| `dungeon_collection_2` | https://opengameart.org/content/modular-dungeon-2-3d-models | Keith at Fertile Soil Productions | License(s): CC0 | `dungeon_collection_2.zip` |
| `low-poly_RPG_item_collection_2` | https://opengameart.org/content/rpg-item-collection-2 | drummyfish | License(s): CC0 | `low-poly RPG item collection 2.zip` |
| `low-poly_RPG_item_collection_3` | https://opengameart.org/content/rpg-item-collection-3 | drummyfish | License(s): CC0 | `low-poly RPG item collection 3.zip` |

**PROBABLE - same author and family, but the zip name on the page is not the folder name here**

| Pack in `_packs` | Page to read | What matches / what does not |
|---|---|---|
| `quaternius_medieval_weapons_2018_CC0` | https://quaternius.itch.io/lowpoly-medieval-weapons (read: author Quaternius, "CC0 License" in the description, zip `Medieval Weapons Pack by Quaternius.zip`) | Inner folder here is "Medieval Weapons Pack - Sept 2018"; the itch zip name differs. Contents not compared file-by-file. |
| `medieval_pack_CC0` | https://opengameart.org/content/low-poly-medieval-weapons (read: quaternius, CC0, zip `MedievalPack.zip`) | Inner folder here is `MedievalPack`, so this is probably the OGA weapons pack, **not a town/building pack - the catalogue's "15 (candidate)" proposal for it should be dropped until the contents are looked at.** Not file-compared. |

**NOT VERIFIED - no page read that names the pack; where to look**

- `Animals_Pack_by_Quaternius`, `_extracted_rpg_items`, `ultimate_animated_character_pack`: folder names read "Animals Pack by Quaternius", "Ultimate RPG Items Pack - Aug 2019", "Ultimate Animated Character Pack - Nov 2019" - Quaternius packs. Check quaternius.itch.io / quaternius.com for the exact pack page. (Sibling pack `quaternius_ultimate_rpg_items_CC0` already has a CC0 `License.txt` and is likely the same items, which would cover `_extracted_rpg_items`; not compared.) The OGA farm-animals (`Farm Animals by @Quaternius.zip`) and monsters pages both read CC0 but do not name `Animals Pack`.
- `modular_village_collection`, `modular_terrain_collections`: inner folders "Modular Village", "Modular Terrain Beach/Cliff/Hilly". Author not established. The OGA medieval-village page was blocked from fetch; search OpenGameArt by those titles.
- `Castle`, `3d_crystals_new`, `free_mine_assets`, `golem_clean_blend`, `dragon_oga`, `handpainted_weapons`: no author evidence found. `dragon_oga` is by its name from OpenGameArt - read the OGA page for the dragon model. The rest: do not import until a source page is found.
- `_generated`: this project's own output, not a third-party pack - no external licence applies.

**Rule for art:** until a row above is VERIFIED, treat the pack as unlicensed for anything that ships.

## Terms on file in a readme - NOT part of the 18 (added 20 Nov 2026 10:4x CT, hub lane)

The import gate is **18 packs**, the list above, unchanged. Three packs have a licence-bearing `readme.txt` that is not NAMED licence/eula and are the gap between art's 21 and this list's 18 (team lead's ruling, 09:58 CT). I read all three readmes in full:

- `Stone_coffin` - full CC0 1.0 Universal Public Domain Dedication text, "Provided by Nobiax". CC0 ON FILE; no listing page needs chasing.
- `rocks` - the identical CC0 1.0 text, Nobiax. CC0 ON FILE.
- `grass_07` - NOT CC0. One line: "Absolutely free to use or to modify in any kind of work (personal, commercial or else)", plus a request for a link to the result. Custom permissive grant; commercial use granted, the link is a request, not a condition. Record its text in `docs/art/ASSET_SOURCES.md` verbatim; never as CC0.

Note: the Stone_coffin/rocks readmes also carry a non-binding request for a link (nobiax.deviantart.com / OpenGameArt yughues). A credit note is cheap and worth giving.

## Leads for the NOT VERIFIED packs (added 20 Nov 2026 11:4x CT, hub lane) - SEARCH RESULTS ONLY, NOT READ

A web search returned these pages. **Titles and URLs only: I did not open them, so no licence line was read and NO pack is upgraded to VERIFIED.** Each is one lookup for art.

- `modular_village_collection` - lead: https://opengameart.org/content/modular-village and https://fertile-soil-productions.itch.io/modular-village-pack. Fertile Soil Productions is the author of the two VERIFIED dungeon packs above, so the same-author pattern is plausible. Not file-compared.
- `modular_terrain_collections` - lead: https://opengameart.org/content/modular-terrain, https://opengameart.org/content/modular-hilly-terrain-3d-models, https://opengameart.org/content/modular-hilly-terrain-expansion, https://fertile-soil-productions.itch.io/modular-terrain-pack (itch devlog mentions a cliff expansion; the local folder holds Beach/Cliff/Hilly). Not file-compared.
- `ultimate_animated_character_pack`, `Animals_Pack_by_Quaternius`, `_extracted_rpg_items` - search surfaced https://opengameart.org/content/all-cc0-uploader-quaternius (an index of the uploader's CC0 packs) but not a page naming these zips. Read that index and the itch.io pack pages for the exact names.
- Rule unchanged: until a page names the zip AND shows the licence line, the pack is unlicensed for anything that ships. Import gate stays 18.

## Leads for the remaining six NOT VERIFIED packs (added 20 Nov 2026 12:5x CT, hub lane) - SEARCH RESULTS ONLY, NOT READ

Same rule as above: **I did not open any page, read no licence line, and NO pack is upgraded to VERIFIED. The import gate stays 18.** The packs are not in this worktree, so no file was compared. Each lead is one lookup for art: open the page, check the zip name and the licence line against the local file list.

- `dragon_oga` - the local folder (.dae 5, .blend 2, .png 2, .mtl 1, .obj 1) is small; candidate OpenGameArt pages from search: https://opengameart.org/content/simple-3d-dragon-model, https://opengameart.org/content/animated-3d-dragon-model, https://opengameart.org/content/dragon-3d, https://opengameart.org/content/low-poly-ice-dragon. Match the .dae/.obj names to the download list.
- `free_mine_assets` - strongest name match: https://opengameart.org/content/free-mine-assets-pack ; alternates https://opengameart.org/content/3d-mine-assets and https://opengameart.org/content/mine-object-collection.
- `3d_crystals_new` - candidates: https://opengameart.org/content/lowpoly-crystals-pack, https://opengameart.org/content/lowpoly-crystals, https://opengameart.org/content/fantasy-crystals. Local pack is .jpg 4 + .blend 1.
- `golem_clean_blend` - one .blend only; candidates: https://opengameart.org/content/low-poly-robot-golem-with-hand-painted-texture, https://opengameart.org/content/elemental-golem, https://opengameart.org/content/bone-golem. Weak: the folder name says "clean", so it may be a user-cleaned copy.
- `handpainted_weapons` - candidates: https://opengameart.org/content/medieval-weapon-pack, https://opengameart.org/content/3d-weapons-pack, https://opengameart.org/content/cethiels-weapons-3d. Weak: docs/art/ASSET_SOURCES.md:184 already says the extracted pack carries no licence file and the note is ours.
- `Castle` - WEAKEST: the search surfaced only itch.io/OGA titles (e.g. https://blendervoyage.itch.io/low-poly-castle-pack, https://opengameart.org/content/dungeon-low-poly-toon-battle-arena-tower-defense-pack), and several itch.io packs are paid. Local pack is 11 fbx + 3 tga + 1 psd, 107 MB. No source claimed; do not import until a page names the zip.
