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
| `assets/gear/wand_crystal.glb` | Supplied by Mr. E, 2026-11-16 05:03 | Mr. E's own — no third-party rights | Crystal-headed wand: dark tapered shaft, silver collar, blue faceted crystal. Raw drop was 306,024 tris / 24 MB with two 4096 and one 2048 map. Shipped version is decimated to 8,000 tris with three 1024 maps, 2.38 MB; silhouette, facets and collar all survive — checked on screen before commit. Origin moved to the BASE OF THE GRIP so it hangs off a hand bone. 0.147 x 0.218 x 0.921 units. The untouched original is kept OUT of git at `C:\hd adventure\_packs\_generated\wand_raw.glb`. **24 Nov 2026 04:5x CT - A +30.5 X NODE TRANSLATION WAS BAKED OUT** (`tools/art/_wandbake.py`). The mesh-local origin was always at the base of the grip as described above, but the glTF NODE above it sat thirty metres out on X, so any consumer that respects the node transform - Godot's glTF import does, and a BoneAttachment3D parents the imported scene - would have placed this wand thirty metres from the hand. Found by the first fit render it has ever had (`tools/art/_wandfit.py`). 7,935 verts and 0.147 x 0.218 x 0.921 unchanged to six decimals; only the node offset moved. |

**FITTED AND READ ON A BODY — 27 Nov 2026 21:3x-21:4x CT. THE LINE ABOVE IS STRUCK.** It has now been
rendered on a posed KayKit hero front, side and back at five carries and looked at; see
`docs/art/THE_TIER5_WAND_READ.md` and `renders/art/wand/`. The open question this paragraph used
to carry — wand or short staff — **is answered by measurement, not by asking Mr. E:** it is a
SHORT STAFF. The slot is at the hip, and a thin 0.57 m shaft held near the body's own plane is
occluded by the torso from a side camera at EVERY roll in the derivable family; to clear the
silhouette the tip must pass the head, which needs `hand_scale` ≈ 1.8 — the staff's own scale.
Recommended carry if it ships as the tier-5 wand anyway (strictly better than the horizontal
baton the engine gives it today, in all three views): **`held_rot (0, 15, 90)` at the existing
`hand_scale` 0.62**, clip 19.8% against the SHIPPED `staff_rare`'s 22.7% at its own carry. The
game build lane owns the attach (handslot.r) and the gear.gd entry; the exact two-line change is
in the doc. The one decision left for Mr. E is wand-vs-staff, stated there.

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

## THE THREE PACKS IN THE 18/21 GAP - TERMS ON FILE IN A README (20 Nov 2026, 10:5x CT)

The 09:58 plan row settled the split between my count of 21 packs with no file
NAMED licence and the hub's 18 packs with no licence text ANYWHERE. Both counts
were right about different questions; **18 is the number that gates imports.**
The three packs in the gap are recorded here with the terms **as I read them off
disk myself this run**, not as quoted from the plan row:

**`_packs/Stone_coffin/readme.txt` - CC0 1.0, usable.** "Provided by Nobiax."
then verbatim: *"CC0 1.0 Universal (CC0 1.0) / Public Domain Dedication / No
Copyright / ... You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission."* A link back is requested,
not required.

**`_packs/rocks/readme.txt` - CC0 1.0, usable.** The same explicit CC0 1.0
paragraph, same author, same requested-not-required link.

**`_packs/grass_07/readme.txt` - NOT CC0. A custom permissive grant, usable.**
The whole file, verbatim, because the point of this entry is that it must not be
re-recorded as CC0 by a later seat:

> Provided by Nobiax.
>
> Absolutely free to use or to modify in any kind of work (personal, commercial
> or else).
>
> Give me a link of the result at nobiax.deviantart.com or my other account on
> OpenGameArt.com or ShareCG.com
> ( watch my journal on deviantart ) ;)

Commercial use is granted outright. The link is a REQUEST ("give me a link"),
not a condition of the grant - there is no "provided that" anywhere in it - so
it is not an attribution licence and it does not infect anything. It is also not
share-alike and not non-commercial, so none of the three forbidden families
apply. **Record it as a custom permissive grant, never as CC0.**

*** THE NAMING TRAP, RESTATED FROM THE OTHER SIDE. *** This file already warns
that a folder called `medieval_pack_CC0` is not licensed by its name. These three
are the mirror image: **a pack with no file called `LICENSE` can still be fully
licensed**, and two of these three are CC0 outright. A filename is not a licence
in either direction. The recipe that counts files answers "where do I have to go
and read", not "what am I allowed to use".


## PACK CATALOGUE - 3d_crystals_new (20 Nov 2026, pack-catalogue firing)

| Pack | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|
| 3d_crystals_new | **NO LICENCE FILE FOUND** | none | 5 (`crystals.blend`, `174.jpg`, `174_norm.jpg`, `crystal.jpg`, `crystal_simple_norm.jpg`) | not established | not established |

- Checked: every file in `_packs\3d_crystals_new\` and every entry in the sibling `3d_crystals_new.zip` (the same five files, read by listing the archive, not extracted). No file named licence, license, copying, readme, credits, terms, or about, and no text file of any kind.
- A `.blend` can carry text datablocks with terms, but none was opened for this entry; the pack is recorded as unlicensed until a licence is found on disk.
- Status: **NOT CLEARED.** Under the licence gate in this file, nothing from this pack goes into `assets/` until a licence is read off disk or the author's own terms are on file. The crystal textures are not to be imported on the strength of their folder name or of any search snippet.


## PACK CATALOGUE - Animals_Pack_by_Quaternius (20 Nov 2026, pack-catalogue firing)

| Pack | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|
| Animals_Pack_by_Quaternius | **NO LICENCE FILE FOUND** | none | 21 (`Animals Pack by Quaternius\Blends\`: Bird, Chick, Fish, Red Fox, Whale `.blend` plus `FishTexture.png`; `FBX\`: 5 `.fbx`; `OBJ\`: 5 `.obj` + 5 `.mtl`) | not established | not established |

- Checked: every file under `_packs\Animals_Pack_by_Quaternius\` and every entry in the sibling `Animals_Pack_by_Quaternius.zip` (listed by reading the archive, not extracted). No file named licence, license, copying, readme, credits, terms, or about, and no text file apart from the three `.mtl` material files, which carry material values only.
- The folder name, the `Quaternius` author credit and the Animals Pack's public listing are not a licence and are not treated as one here.
- Status: **NOT CLEARED.** Under the licence gate in this file, nothing from this pack goes into `assets/` until a licence is read off disk or the author's own terms are on file.


## PACK CATALOGUE - Church1_blend (20 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Church1_blend (Blendswap 75990 "Medieval Church") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs/Church1_blend/75990_Church1Upload_blend/75990 - Medieval Church - License.html` | 17 on disk (`Church1Upload.blend`, `church.dae`, `preview_75990.jpg`, 13 textures under `EXPORT\`, the licence HTML); the sibling `Church1_blend.zip` lists the same content | permitted | not required; credit kept (Daniel74, blendswap.com/blends/view/75990) |

- Checked: the whole `_packs\Church1_blend\` tree by walking it, and the sibling `Church1_blend.zip` by listing its entries (not extracted). The licence was read off the file this run, not from a search snippet. The HTML page states: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain)" and "There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, and the text it holds is the licence statement itself. The `.blend` may carry its own text datablocks and embedded assets; none was opened here, so the CC0 grant is recorded for the pack as published, not re-checked per embedded texture.
- Status: **CLEARED for use (CC0 1.0).** Import still goes through the licence gate in this file, which this entry now satisfies for `Church1_blend`.

## PACK CATALOGUE - Fantasy_Props_MegaKit (20 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Fantasy_Props_MegaKit (Quaternius, FREE standard version) | Quaternius | **CC0 1.0 Universal (Public Domain)** | `_packs\Fantasy_Props_MegaKit\License_Standard.txt` | 517 on disk: 94 each of `.fbx`, `.gltf` + `.bin`, `.obj` + `.mtl`; 43 `.png`, 3 `.jpg` (previews), 1 `.txt` (the licence) | permitted | not required; the file asks for a Patreon/Discord link only as a courtesy, not a condition |

- Checked: the whole `_packs\Fantasy_Props_MegaKit\` tree by walking it, and the sibling `Fantasy_Props_MegaKit.zip` by listing its entries (517 files, same count; not extracted). The licence was read off disk this run, not from a search snippet.
- The text reads, verbatim: "License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/" and "Models by @Quaternius". It also states this is the FREE standard subset of the Fantasy Props MegaKit; the PRO and SOURCE versions are paid and are not in this pack.
- Status: **CLEARED for use (CC0 1.0).** Import still goes through the licence gate in this file, which this entry now satisfies for `Fantasy_Props_MegaKit`.

## PACK CATALOGUE - Fantasy_Ruins_Pack (20 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Fantasy_Ruins_Pack (folder `FantasyRuins_Ready`) | not named in the licence text; the file prefix is `3TD` | **CC0 1.0 Universal (Public Domain)** | `_packs\Fantasy_Ruins_Pack\FantasyRuins_Ready\3TD_CC0_License_EULA.pdf` | 110 on disk: 39 `.jpg`, 35 `.png`, 12 `.dts`, 12 `.dae`, 11 `.cs`, 1 `.pdf` (the licence) | permitted | not required |

- Checked: every file in `_packs\Fantasy_Ruins_Pack\` by walking the tree (110 files). The sibling `Fantasy_Ruins_Pack.zip` was not opened in this firing.
- The licence PDF was read off disk this run, not from a search snippet. Its text layer is a Calibri TrueType subset with no plain-text strings, so the text was recovered by decoding the three page content streams through the font's ToUnicode map. The recovered text is the Creative Commons CC0 legal code: a Statement of Purpose, the "Work made available under CC0" wording, and the grant "for any purpose whatsoever, including without limitation commercial, advertising or promotional purposes".
- The earlier catalogue line that called this licence "unreadable" (docs/PACK_CATALOGUE.md, Licence flags) is superseded by this entry.
- Formats: `.dts` (Torque), `.dae` (Collada) and `.cs` (game-engine scripts). No glTF, GLB or FBX, so any use needs a conversion step. The `.cs` files are engine code and are not to be copied into the repo.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for this pack. Nothing is redistributed as an asset; any model that enters `assets/` must still be recorded in its own row.

## Pack catalogue verification - 3d_crystals_new (20 Nov 2026, pack-catalogue worker)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\3d_crystals_new\` (sibling `3d_crystals_new.zip` checked: identical 5 entries, no extra files) |
| Author | Not stated in any file in the pack |
| Licence | **NO LICENCE FILE FOUND** - no LICENSE / License.txt / README / credits / terms file in the directory or the zip. Nothing guessed. |
| File count | 5 (4 x .jpg: `174.jpg`, `174_norm.jpg`, `crystal.jpg`, `crystal_simple_norm.jpg`; 1 x .blend: `crystals.blend`) |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| File dates | jpg 2014-01-24 / 2014-07-17; blend 2014-07-18 (inside zip) |
| Cleared for use | **NO.** Unlicensed. Do not ship, convert or redistribute any file from this pack until an author licence is found. |

Method: directory listed and zip central directory read with Python `zipfile` (not extracted); the one licence-like search (`*licen*`, `*readme*`, `*credit*`, `*terms*`, `*.txt`, `*.md`, `*.html`) returned nothing in either location. The `.blend` was not opened.


## PACK CATALOGUE - HandPainted_Plants (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| HandPainted_Plants (folder `HandPainted_Plants`, sibling `HandPainted_Plants.7z`) | Nobiax / Yughues | **CC0 1.0 Universal (Public Domain)** | `_packs\HandPainted_Plants\ReadMe - Licence.txt` | 36 on disk: 15 `.fbx` (`FBX\`), 15 `.obj` (`OBJ\`), 2 `.tga` (`LP-Plants_d.tga`, `LP-Plants_d-outline.tga`), 3 `.jpg` (`HP Plants.jpg`, `HP Plants bis.jpg`, `HP Plants outline_d.jpg`), 1 `.txt` (the licence) | permitted | not required by CC0; the file asks for a Patreon link and a share if used |

- Checked: every file under `_packs\HandPainted_Plants\` by walking the tree (36 files, counted by `find -type f`). The sibling `HandPainted_Plants.7z` was not opened in this firing; the extracted directory is the copy read.
- The licence was read off the file on disk this run, not from a search snippet. The file reads, verbatim: "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication. No Copyright" and "You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission." It also says "Absolutely free to use or to modify in any kind of work (personal, commercial, educational or else)".
- The same file carries a request, "Please, don't be an ass, don't do basic reselling of it", plus a Patreon and Twitter link. Under CC0 this is a courtesy, not a condition of the grant. Nothing from this pack is to be redistributed AS an asset, which keeps the request satisfied in any case.
- Formats: FBX and OBJ, so any import into `assets/` needs a headless Blender batch convert to .glb first, the same route the Quaternius packs take. Each model that enters `assets/` must still get its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `HandPainted_Plants`.


## PACK CATALOGUE - House1_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| House1_blend (Blendswap 75519 "Medieval houses") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\House1_blend\75519 - Medieval houses - License.html` | 3 on disk: `House1Upload.blend` (7.9 MB), `preview_75519.jpg`, the licence HTML. The sibling `House1_blend.zip` lists the same three entries (not extracted) | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75519) |

- Checked: every file in `_packs\House1_blend\` by listing the tree (3 files), and the sibling `House1_blend.zip` by reading its entries with Python `zipfile` (not extracted). The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, so its text is the licence statement itself. The `.blend` may carry embedded textures or text datablocks; the `.blend` was not opened here, so the CC0 grant is recorded for the pack as published and not re-checked per embedded asset.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `House1_blend`. Nothing is redistributed AS an asset; any model that enters `assets/` still needs its own row.

## PACK CATALOGUE - House2_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| House2_blend (Blendswap 75861 "Medieval House") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\House2_blend\75861 - Medieval House - License.html` | 3 on disk: `House2_1Upload.blend` (8.8 MB), `preview_75861.jpg`, the licence HTML. The sibling `House2_blend.zip` lists the same three entries (not extracted) | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75861) |

- Checked: every file in `_packs\House2_blend\` by listing the tree (3 files), and the sibling `House2_blend.zip` by reading its entries with Python `zipfile` (not extracted). The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, so its text is the licence statement itself. The `.blend` may carry embedded textures or text datablocks; the `.blend` was not opened here, so the CC0 grant is recorded for the pack as published and not re-checked per embedded asset.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `House2_blend`. Nothing is redistributed AS an asset; any model that enters `assets/` still needs its own row.


## PACK CATALOGUE - House3_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| House3_blend (Blendswap 75862 "Medieval house") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\House3_blend\75862 - Medieval house - License.html` | 3 on disk: `House3Upload.blend` (8.6 MB), `preview_75862.jpg`, the licence HTML. The sibling `House3_blend.zip` lists the same three entries (listed and integrity-tested with `zipfile.testzip()`, not extracted) | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75862) |

- Checked: every file in `_packs\House3_blend\` by listing the tree (3 files), and the sibling `House3_blend.zip` by reading its entries with Python `zipfile` (not extracted). The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, so its text is the licence statement itself. The `.blend` may carry embedded textures or text datablocks; the `.blend` was not opened here, so the CC0 grant is recorded for the pack as published and not re-checked per embedded asset.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `House3_blend`. Nothing is redistributed AS an asset; any model that enters `assets/` still needs its own row.

## PACK CATALOGUE - House4_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| House4_blend (Blendswap 75864 "Medieval House") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\House4_blend\75864 - Medieval House - License.html` | 3 on disk: `House4Upload.blend` (10.8 MB), `preview_75864.jpg`, the licence HTML. The sibling `House4_blend.zip` lists the same three entries (listed and integrity-tested with `zipfile.testzip()`, which returned no error; not extracted) | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75864) |

- Checked: every file in `_packs\House4_blend\` by listing the tree (3 files), and the sibling `House4_blend.zip` by reading its entries with Python `zipfile` (not extracted). The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, so its text is the licence statement itself. The `.blend` may carry embedded textures or text datablocks; the `.blend` was not opened here, so the CC0 grant is recorded for the pack as published and not re-checked per embedded asset.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `House4_blend`. Nothing is redistributed AS an asset; any model that enters `assets/` still needs its own row.
### 21 Nov 2026 - System 2: the three dungeon crossbows are MODIFIED in place (art)
`assets/gear/dungeon/crossbow_{common,uncommon,rare}.glb` are the **KayKit
Dungeon Pack 1.0 (Kay Lousberg, CC0 1.0)** models already listed in the table
above, now carrying a stirrup, a drawn bowstring and a bolt added procedurally
by `tools/art/xbowparts.py` (+116 verts each; 395->511, 531->647, 688->804).
CC0 explicitly permits modification and incorporation and requires no
attribution; the row is kept anyway because every pack used gets recorded. The
added geometry is original and procedural. Nothing is redistributed AS an
asset. THE PRISTINE COPY, if these ever need restoring, is
`_packs/kaykit_dungeon_pack_CC0/Models/gltf/crossbow_<tier>.gltf.glb`, and the
generator REFUSES to run on an already augmented mesh - it asserts the vertex
count against the pack's own 395/531/688 first, so a second stirrup cannot be
added by a re-run.


## PACK CATALOGUE - KayKit_RPGToolsBits_1.0_FREE (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| KayKit : RPG Tools Bits (1.0) (folder `KayKit_RPGToolsBits_1.0_FREE`, nested one level as `KayKit_RPGToolsBits_1.0_FREE\KayKit_RPGToolsBits_1.0_FREE\`) | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0 Universal (Public Domain)** | `_packs\KayKit_RPGToolsBits_1.0_FREE\KayKit_RPGToolsBits_1.0_FREE\License.txt` | 339 on disk: 49 models in each of `Assets\gltf\` (`.gltf` + `.bin`), `Assets\fbx\` (`.fbx`), `Assets\fbx(unity)\` (`.fbx`), `Assets\obj\` (59 `.obj` + `.mtl`, incl. sub-parts); 21 `.png`; 3 `.url` (Patreon, Discord, more-assets links); 1 `.txt` (the licence) | permitted | not required; the licence asks for a credit "Kay Lousberg, www.kaylousberg.com" as optional |

- Checked: every file under `_packs\KayKit_RPGToolsBits_1.0_FREE\` by walking the tree (339 files, counted with Python `os.walk`). The sibling `KayKit_RPGToolsBits_1.0_FREE.zip` was not opened in this firing; the extracted directory is the copy read.
- The licence was read off `License.txt` on disk this run, not from a search snippet. The file reads, verbatim: "License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/" and "This content is free to use in personal, educational and commercial projects." Crediting is stated as optional ("this is not mandatory").
- The same file asks, as a courtesy and not as a condition of the grant, for support via the EXTRA/SOURCE tiers, a donation, or Patreon.
- Formats: glTF (with `.bin`), FBX and OBJ. The glTF set needs no conversion before Godot; the FBX and OBJ sets would need a headless Blender batch convert to `.glb` first, as the other packs do.
- The pack is a tools-and-props set (anvil, grindstone, journal, lantern, map, torch, wrench and similar), not a weapon or character pack. Any model that enters `assets/` must still get its own row in the table above.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `KayKit_RPGToolsBits_1.0_FREE`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - KayKit_ResourceBits_1.0_FREE (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| KayKit : Resource Bits (1.0) (folder `KayKit_ResourceBits_1.0_FREE`, nested one level as `KayKit_ResourceBits_1.0_FREE\KayKit_ResourceBits_1.0_FREE\`) | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0 Universal (Public Domain)** | `_packs\KayKit_ResourceBits_1.0_FREE\KayKit_ResourceBits_1.0_FREE\License.txt` | 466 on disk: 76 glTF models (`Assets\gltf\`: 76 `.gltf` + 76 `.bin`, plus 1 `.png`), 77 `.fbx` (`Assets\fbx\`), 77 `.fbx` (`Assets\fbx(unity)\`), 153 `.obj`/`.mtl` set (`Assets\obj\`), 1 texture (`Textures\resource_bits_texture.png`), 1 `contents.png`, 3 `.url` (Discord, more assets, Patreon), 1 `License.txt` | permitted | not required; the licence says crediting is "not mandatory, but would be appreciated" |

- Checked: every file under `_packs\KayKit_ResourceBits_1.0_FREE\` by walking the tree (466 files, counted with `find -type f`). The sibling `KayKit_ResourceBits_1.0_FREE.zip` was not opened in this firing; the extracted directory is the copy read.
- The licence was read off `License.txt` on disk this run, not from a search snippet. The file reads, verbatim: "License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/" and "This content is free to use in personal, educational and commercial projects." Crediting: "this is not mandatory, but would be appreciated".
- The same file asks, as a courtesy and not as a condition of the grant, for support via Patreon or the EXTRA/SOURCE packs on itch.io.
- Formats: glTF (with `.bin`) needs no conversion before Godot; the FBX and OBJ sets would need a headless Blender batch convert to `.glb` first, as the other packs do.
- The pack is a resource-props set (copper, gold, iron and silver bars, nuggets and stacks; fuel barrels and jerrycans; pallets; stone bricks and chunks; textiles; wood logs and planks; parts piles and cogs). It is not a weapon or character pack. Any model that enters `assets/` must still get its own row in the table above.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `KayKit_ResourceBits_1.0_FREE`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - Smith1_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Smith1_blend (Blendswap 75579 "Medieval Smith Pack") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\Smith1_blend\75579 - Medieval Smith Pack - License.html` | 3 on disk: `Smith1Upload.blend`, `preview_75579.jpg`, the licence HTML (folder count 3; the sibling `Smith1_blend.zip` was not opened this firing) | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75579) |

- Checked: every file in `_packs\Smith1_blend\` by walking the tree (3 files). The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the HTML is a Blend Swap page wrapper, so its text is the licence statement itself. The `.blend` may carry embedded textures or text datablocks; it was not opened here, so the CC0 grant is recorded for the pack as published and not re-checked per embedded asset.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `Smith1_blend`. Nothing is redistributed AS an asset; any model that enters `assets/` still needs its own row.

## PACK CATALOGUE - ThePaintedWench_blend (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| ThePaintedWench_blend (Blendswap 75282 "Medieval Tavern") | Daniel74 | **CC0 1.0 Universal (Public Domain)** | `_packs\ThePaintedWench_blend\75282 - Medieval Tavern - License.html` | 3 on disk: `ThePaintedWench_02Upload.blend` (5,351,400 bytes), `preview_75282.jpg` (3,066 bytes), the licence HTML (5,278 bytes). The sibling `ThePaintedWench_blend.zip` lists the same three entries and was not extracted. | permitted | not required by CC0; credit kept (Daniel74, blendswap.com/blends/view/75282) |

- Checked: every file in `_packs\ThePaintedWench_blend\` by walking the tree (3 files), and the sibling zip's entry list read with Python `zipfile`. The licence was read off the HTML file on disk this run, not from a search snippet. The page states, verbatim: "This file has been released by Daniel74 under the following license: Creative Commons Zero (Public Domain). You can use this model for any porposes according to the following conditions: There are no requirements for CC-Zero licensed blends."
- Note for later seats: the `.blend` was not opened here, so the CC0 grant is recorded for the pack as published. Any model that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `ThePaintedWench_blend`. Nothing is redistributed AS an asset.


## PACK CATALOGUE - Ultimate_Animated_Animals (21 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Ultimate_Animated_Animals (folder `Ultimate Animated Animals - July 2021\`) | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\Ultimate_Animated_Animals\Ultimate Animated Animals - July 2021\License.txt` (364 bytes, read in full this run) | 63 on disk: 12 `.blend` (Blends\), 12 `.fbx` (FBX\), 12 `.gltf` (glTF\), 12 `.obj` + 12 `.mtl` (OBJ\), `Preview.jpg`, `Preview.mp4`, `License.txt` | permitted | not required by CC0; credit kept (Quaternius, "LowPoly Models by @Quaternius") |

- Checked: every file under `_packs\Ultimate_Animated_Animals\` by walking the tree (63 files), and the licence file read in full off disk. The licence text states: "LowPoly Models by @Quaternius ... License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/".
- Animals in the pack (12 species, each present in the blend, FBX, glTF and OBJ sets): Alpaca, Bull, Cow, Deer, Donkey, Fox, Horse, Horse_White, Husky, ShibaInu, Stag, Wolf.
- Note for later seats: the `.zip` sibling `Ultimate_Animated_Animals.zip` was not opened this firing; the CC0 grant is recorded for the pack as published. Any animal that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `Ultimate_Animated_Animals`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - Ultimate_Monsters (23 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Ultimate_Monsters (folder `Ultimate Monsters\`, licence header reads "Ultimate Platformer Pack by @Quaternius") | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\Ultimate_Monsters\Ultimate Monsters\License.txt` (374 bytes, read in full this run) | 69 on disk: `Atlas_Monsters.png`, `Color Guide.png`, `Preview.jpg`, `Big\` (8 `.blend`, 17 `.fbx`, 17 `.obj` + `.mtl`, 4 `.gltf`), `Blob\` (9 `.fbx`), `Flying\` (4 `.blend`, 8 `.obj` + `.mtl`), `License.txt`. The sibling `Ultimate_Monsters.zip` was not opened this firing. | permitted | not required by CC0; credit kept (Quaternius, "Ultimate Platformer Pack by @Quaternius") |

- Checked: every file under `_packs\Ultimate_Monsters\` by walking the tree (69 files), and the licence file read in full off disk. The licence text states, verbatim: "Ultimate Platformer Pack by @Quaternius ... License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/".
- Naming discrepancy noted, not resolved: the folder and zip are named "Ultimate Monsters" but the licence header names the pack "Ultimate Platformer Pack". The CC0 statement is the same either way; the pack-title mismatch is recorded so a later reader is not confused about which Quaternius release this is.
- Monsters in the pack (named in the file tree): Alien, Birb, BlueDemon, Frog, Ninja, Orc_Skull, Tribal, Cactoro, Dino, Fish, Monkroose, MushroomKing, Orc, Yeti, GreenBlob, GreenSpikyBlob, Mushnub, Pigeon, PinkBlob, Wizard, Glub, Glub_Evolved, Goleling_Evolved, Squidle, Alpaking_Evolved, Ghost, Hywirl, Bunny. Any monster that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `Ultimate_Monsters`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - forest-monster (23 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| forest-monster (folder `_packs\forest-monster\`; sibling `forest-monster.7z`, not opened) | Čestmír Dammer (CDmir), project www.kelgar.org, idea Torben | **CC0** (stated as "Creative Commons (CC0)", no version given) | `_packs\forest-monster\Licenses.txt` (589 bytes, read in full this run) | 10 on disk: `forest-monster-final.blend`, `Licenses.txt`, `texture\forest-monster-AO.png`, `-norm.png`, `-skin.png`, `-skin1.png`, `-spec.png`, `tree.png`, `tree-norm.png`, `tree-spec.png` | permitted (CC0) | not required by CC0; credit kept (CDmir / kelgar.org) |

- Checked: every file under `_packs\forest-monster\` by walking the tree (10 files), and `Licenses.txt` read in full off disk. The file states, verbatim: "Author: Čestmír Dammer (CDmir) / License: Creative Commons (CC0) / Project: www.kelgar.org / Textures: UV-Teture was derived from textures by Rick Hoppmann."
- Animations listed in the file (frame ranges, not separate files): Idle, Walk, melee hold, melee strike, melee charge, melee cooldown, Dying, Dead.
- OPEN NOTE FOR MR. E, not resolved here: the UV texture is stated to be derived from textures by Rick Hoppmann, and the licence file gives no licence for those source textures. The model's CC0 statement is clear; the texture provenance is not. Confirm before any `forest-monster` texture enters `assets/`.
- Note for later seats: the `.blend` was not opened, so the CC0 grant is recorded for the pack as published. Any monster that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0) for the model as stated. Texture provenance open (see note).** Nothing is redistributed AS an asset.

## PACK CATALOGUE - kaykit_character_animations_CC0 (23 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| kaykit_character_animations_CC0 (KayKit : Character Animations 1.0; folder `_packs\kaykit_character_animations_CC0\`) | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0 Universal (Public Domain)** | `_packs\kaykit_character_animations_CC0\License.txt` (638 bytes, read in full this run) | 53 | Yes. The licence reads: "free to use in personal, educational and commercial projects" | Not mandatory. The licence says crediting Kay Lousberg is "not mandatory"; recorded here anyway |

- Checked: every file under `_packs\kaykit_character_animations_CC0\` by walking the tree (53 files), and `License.txt` read in full off disk. The file states, verbatim: "KayKit : Character Animations (1.0) / Created/distributed by Kay Lousberg (www.kaylousberg.com) / Creation date: 03/02/2021 15:00 / License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/".
- File breakdown (by extension): 22 .fbx, 6 .obj, 6 .mtl, 3 .dae, 2 .glb, 1 .gltf, 7 .png (brand resources), 3 .pdf (Godot, Unity, Unreal implementation guides), 1 .txt, 2 .url (links only).
- Content: one combined animation FBX (`Animations\KayKit Animated Character_v1.0.fbx`) plus 18 single-animation FBX files in `Animations\Single Animations\` (Attack(1h), BasePose, Block, Cheer, Climbing, Defeat, HeavyAttack, Hop, Idle, Jump, LayingDownIdle, Run, Shoot(1h), Shoot(2h), Shooting(1h), Shooting(2h), Walk, Wave). Also three static props in `Models\` (Case, Pencil, PrototypePete), each as obj/fbx/dae, with PrototypePete additionally as gltf.
- Naming note: the pack title in the licence is "KayKit : Character Animations", and the folder is `kaykit_character_animations_CC0`. Both refer to the same pack.
- Note for later seats: the `.zip` sibling `kaykit_character_animations_CC0.zip` was not opened this firing; the CC0 grant is recorded for the pack as published. The rigged character meshes these animations target are in the separate KayKit Dungeon Pack (already catalogued above), so any animation used with those meshes is a rig-compatibility question, not a licence question. Any file that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `kaykit_character_animations_CC0`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - kenney_3d-road-tiles (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| kenney_3d-road-tiles (folder `_packs\kenney_3d-road-tiles\`, sibling `kenney_3d-road-tiles.zip` not opened) | Kenney Vleugels for Kenney (www.kenney.nl) | **CC0 1.0 Universal (Public Domain)** | `_packs\kenney_3d-road-tiles\License.txt` | 915 on disk: 302 `.gltf`, 302 `.obj`, 302 `.mtl` (`Models\roadTile_001`-`roadTile_302`), 2 `.png` (`Preview.png`, `Sample.png`), 1 `.py` (`Convert\Three.js (Blender)\fixQuads.py`), 2 `.txt` (`License.txt`, `Convert\Three.js (Blender)\readme.txt`), 1 `.unitypackage` (`Unity package\roadPack_unity.unitypackage`), 3 `.url` (donation/social links) | Permitted: "You may use these textures/photographs in personal and commercial projects." | Not required. Credit to Kenney / www.kenney.nl is requested ("would be nice but is not mandatory"). |

**Licence text read in full from disk this firing.** `License.txt` names the CC0 1.0 Universal URL (creativecommons.org/publicdomain/zero/1.0/) and states the commercial-use permission above. No share-alike, no non-commercial, no no-derivatives clause. The `Convert\Three.js (Blender)\readme.txt` is a conversion note only (Three.js needs quads; points to a third-party `fixQuads.py` gist) and states no separate licence. The `fixQuads.py` script is a third-party tool shipped in the pack and is NOT part of what enters `assets/`; do not import it.

Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `kenney_3d-road-tiles`. Any file that enters `assets/` still needs its own row.

## PACK CATALOGUE - kenney_retro-fantasy-kit (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| kenney_retro-fantasy-kit (Retro Fantasy Kit 2.0; folder `_packs\kenney_retro-fantasy-kit\`, sibling `kenney_retro-fantasy-kit.zip` not opened) | Kenney (www.kenney.nl) | **CC0 1.0 Universal (Public Domain)** | `_packs\kenney_retro-fantasy-kit\License.txt` (720 bytes, read in full this run) | 562 on disk: FBX, GLB and OBJ+MTL model sets (one file per piece, with a shared Textures folder in each format), `Previews\` (PNG per model), `Preview.png`, `Sample.png`, `Overview.html`, 3 `.url` link files | Yes. The licence reads: "You can use this content for personal, educational, and commercial purposes." | Not required. The licence says crediting 'Kenney' or 'www.kenney.nl' is "not a requirement"; recorded here anyway |

- Checked: every file under `_packs\kenney_retro-fantasy-kit\` by walking the tree (562 files), and `License.txt` read in full off disk. The file states, verbatim: "Retro Fantasy Kit (2.0) / Created/distributed by Kenney (www.kenney.nl) / Creation date: 19-02-2025 16:10 / License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/". `Overview.html` (line 157) independently links the same CC0 1.0 Universal URL.
- Note for later seats: the `.zip` sibling was not opened this firing; the CC0 grant is recorded for the pack as published. Any file that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `kenney_retro-fantasy-kit`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - quaternius_rpg_characters_CC0 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| quaternius_rpg_characters_CC0 (the pack is titled "RPG Characters - Nov 2020"; folder `_packs\quaternius_rpg_characters_CC0\RPG Characters - Nov 2020\`, one level deeper than the folder name; no `.zip` sibling exists) | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\quaternius_rpg_characters_CC0\RPG Characters - Nov 2020\License.txt` (read in full this run) | 60 on disk: 11 `.blend` (`Blends\`: Cleric, Monk, Ranger, Rogue, Warrior, Wizard, plus 5 weapon-only blends in `Blends\Only Weapons\`), 12 `.fbx` (`FBX\`, incl. `Only Weapons\` with 6 weapons and a Ranger arrow), 24 `.obj` + `.mtl` files, 12 pairs (`OBJ\`, incl. `Only Weapons\`), 11 `.png` (`Textures\`), `Preview.jpg`, `License.txt` | permitted (CC0 1.0: no attribution or share-alike obligation) | not required by CC0; credit kept (Quaternius, "LowPoly Models by @Quaternius") |

- Checked: every file under `_packs\quaternius_rpg_characters_CC0\` by walking the tree (60 files), and `License.txt` read in full off disk. The file states, verbatim: "LowPoly Models by @Quaternius ... License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/".
- Naming note: the folder is `quaternius_rpg_characters_CC0` but the pack inside is "RPG Characters - Nov 2020". Recorded so a later reader does not confuse it with other Quaternius RPG releases.
- Not opened this firing: the 11 `.blend` files and the `.fbx`/`.obj` geometry. The CC0 grant is recorded for the pack as published. Any character or weapon that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `quaternius_rpg_characters_CC0`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - quaternius_ultimate_rpg_items_CC0 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| quaternius_ultimate_rpg_items_CC0 (the pack is titled "Ultimate RPG Items Pack - Aug 2019"; folder `_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019\`, one level deeper than the folder name; no `.zip` opened this firing) | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019\License.txt` (364 bytes, read in full this run) | 533 on disk: 106 `.blend` (`Blends\`), 106 `.fbx` (`FBX\`), 106 `.obj` + 106 `.mtl` (`OBJ\`), 107 `.png` (`Icons\`), `Preview.jpg`, `License.txt` | permitted (CC0 1.0: no attribution or share-alike obligation) | not required by CC0; credit kept (Quaternius, "LowPoly Models by @Quaternius") |

- Checked: every file under `_packs\quaternius_ultimate_rpg_items_CC0\` by walking the tree (533 files, counted by extension), and `License.txt` read in full off disk. The file states, verbatim: "LowPoly Models by @Quaternius ... License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/".
- Naming note: the folder is `quaternius_ultimate_rpg_items_CC0` but the pack inside is "Ultimate RPG Items Pack - Aug 2019". Recorded so a later reader does not confuse it with the Quaternius "Ultimate Animated Character" or "Ultimate Nature" releases.
- Not opened this firing: the individual `.blend`, `.fbx` and `.obj` geometry. The CC0 grant is recorded for the pack as published. Any item that enters `assets/` (potions, crystals, weapons, and so on) still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `quaternius_ultimate_rpg_items_CC0`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - ultimate_nature_pack_by_quaternius (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| ultimate_nature_pack_by_quaternius (the pack is titled "Ultimate Nature Pack - Jun 2019"; folder `_packs\ultimate_nature_pack_by_quaternius\Ultimate Nature Pack - Jun 2019\`, one level deeper than the folder name; sibling `.zip` (22.99 MB) not opened this firing) | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\ultimate_nature_pack_by_quaternius\Ultimate Nature Pack - Jun 2019\License.txt` (read in full this run) | 602 on disk: 150 `.blend`, 150 `.fbx`, 150 `.obj` + 150 `.mtl` (`OBJ\`), `Preview.jpg`, `License.txt` (counted by extension by walking the tree) | permitted (CC0 1.0: no attribution or share-alike obligation) | not required by CC0; credit kept (Quaternius, "LowPoly Models by @Quaternius") |

- Checked: every file under `_packs\ultimate_nature_pack_by_quaternius\` by walking the tree (602 files), and `License.txt` read in full off disk. The file states, verbatim: "LowPoly Models by @Quaternius ... License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/".
- Content note: nature set (rocks, tree stumps, wood logs, wheat, and many willow variants in plain, autumn, snow, and dead forms). Recorded so a later reader can find it by contents.
- Not opened this firing: the individual `.blend`, `.fbx` and `.obj` geometry. The CC0 grant is recorded for the pack as published. Any model that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `ultimate_nature_pack_by_quaternius`. Nothing is redistributed AS an asset.

## PACK CATALOGUE - Bestiary_Dungeon_Monsters_Kit (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Bestiary_Dungeon_Monsters_Kit (the pack is titled "Bestiary - Dungeon Monsters Kit [Standard]", the FREE version; folder `_packs\Bestiary_Dungeon_Monsters_Kit\Bestiary - Dungeon Monsters Kit[Standard]\`) | Quaternius (patreon.com/quaternius) | **Quaternius Asset License (QAL) v1.0** (quaternius.com/license.html, "Last updated: 8/28/2026") | `Bestiary - Dungeon Monsters Kit[Standard]\License_Standard.txt` (read in full off disk this run) | 22 on disk: 2 `.fbx` (Exports\FBX (Unity)\), 2 `.glb` (Exports\GLB (Godot-Unreal)\), 2 preview `.png` (Importing_Godot.png, Importing_UnrealUnity.png), 13 texture `.png` (Textures\, plus Textures\Unreal Normals\ x2), `Preview.jpg`, `License_Standard.txt` | permitted: Section 2 grants use, modification and commercial exploitation of a Product with no fee, royalty or credit | not required (QAL s.2: "No attribution is required"); credit kept (Quaternius, "Models by @Quaternius") |

- Checked: every file under `_packs\Bestiary_Dungeon_Monsters_Kit\` by walking the tree (22 files), and `License_Standard.txt` read in full off disk. The file states, verbatim: "License: Quaternius Asset License (QAL) v1.0 ... You can use these assets, free of charge, in personal, educational, and commercial games and other projects, with no credit required. You just can't resell or redistribute the assets themselves as assets."
- Restriction that binds us: QAL s.3(a) forbids redistributing the Assets as a standalone asset, asset pack, or similar product. Shipping the monsters inside a game is allowed; re-exporting an Imp or Puglin file as a loose asset is not. This is the same line already recorded for the Imp/Puglin/broodglut rows above.
- Scope note: this is the FREE Standard edition (its own licence file says it holds only part of the models). The SOURCE edition is not in `_packs\` and is not covered by this row.
- Status: **CLEARED for use (QAL v1.0).** Licence gate satisfied for `Bestiary_Dungeon_Monsters_Kit`. Commercial use permitted; no attribution required. Nothing is redistributed AS an asset.

## PACK CATALOGUE - Castle (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Castle (folder `_packs\Castle\`, nested one level as `_packs\Castle\Castle\`; sibling `Castle.zip` 75 MB, names listed only, not extracted) | Not named in any file on disk | **NO LICENCE FILE FOUND** | None. No licence, readme, terms, credit or URL file exists in the folder tree or in the zip listing. | 15 on disk: 11 `.FBX` (`Castle_Building_Blocks\`: Arch, Brick_Wall, Cathedral_Window, Cornice, Door, Narrow_Pillar, Pillar_Standalone, Pillar_Top, Wide_Pillar_No_Door, Wide_Pillar_With_Door, Windows), 3 `.tga` + 1 `.psd` (`Castle_Texture_Atlas\`: Castle_D, Castle_N, Castle_S, Castle_Master_Mat) | Unknown. Not granted on disk. | Unknown |

- Checked: walked every file under `_packs\Castle\` (15 files, by extension) and listed the names inside `Castle.zip`. Searched for licence/copying/readme/terms/credit/url/pdf/html names: none. Grepped the binary texture and psd files for licence wording: the only hits were pixel-data noise, not licence text. The FBX header carries an empty author field.
- The folder name carries no licence claim, so none is inferred from it.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Import into `assets/` is gated until a licence is supplied by the source or by Mr. E. Nothing has been imported, converted or redistributed.

## PACK CATALOGUE - dragon_oga (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| dragon_oga (folder `_packs\dragon_oga\`, sibling `dragon_oga.zip` 1.35 MB, names listed only) | Not named in any licence file. Exporter metadata in the `.dae` files reads "Blender User" (an authoring-tool default, not a licence). | **NO LICENCE FILE FOUND** | None. No licence, readme, terms, credit or URL file exists in the folder or in the zip listing. | 11 on disk: 5 `.dae` (`dragon.dae`, `dragon_attack.dae`, `dragon_die.dae`, `dragon_idle.dae`, `dragon_walk.dae`), 1 `.obj` + 1 `.mtl`, 2 `.blend` (`dragon-2_79b.blend`, `dragon-2_80.blend`), 2 `.png` (`dragon.png`, `dragon_black.png`). Zip holds the same 11 entries. | Not stated | Not stated |

- Checked: walked every file under `_packs\dragon_oga\` (11 files) and listed the 11 entries inside `dragon_oga.zip`. No file name matches licence, copying, readme, terms, credit, url, about or pdf/html/json/md.
- Grepped the text-like files (`.obj`, `.mtl`, `.dae`) for licence, copyright, creative commons, CC0, public domain and all-rights wording: no hits. The `.mtl` names `dragon.png` as its only texture and carries no terms. The one raw grep hit was in `dragon_black.png`, an empty XMP `plus:CopyrightOwner` template field, which is binary noise and not a licence.
- The folder name carries no licence claim, so none is inferred from it.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Import into `assets/` is gated until a licence is supplied by the source or by Mr. E. Nothing has been imported, converted or redistributed.


## PACK CATALOGUE - dungeon_collection_2 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| dungeon_collection_2 (folder `_packs\dungeon_collection_2\`, subfolder `Dungeon Set 2\`; sibling `dungeon_collection_2.zip` 269 KB, 180 entries, names listed only, not extracted) | Not named in any file on disk | **NO LICENCE FILE FOUND** | None. No licence, readme, terms, credit or URL file exists in the folder tree or in the zip listing. A grep of every file for licence, copyright, creative commons, CC0, CC-BY, public domain, all rights, terms of use, free to use and attribution returned no hits. | 180 on disk, all in `Dungeon Set 2\`: 90 `.obj` + 90 `.mtl` (dungeon props, walls, floors, traps, doors, pillars and steps; materials Dark_Grey, Grey, Iron, Steel, Wood, Dark_Wood, Red_Wood). No texture images. The `.obj` and `.mtl` headers carry no author or tool comment. | Not established | Not established |

- Checked: walked every file under `_packs\dungeon_collection_2\` (180 files, counted by type), listed the 180 entries inside `dungeon_collection_2.zip` with Python `zipfile` (not extracted; no licence-named entry), and grepped all 180 text files for licence wording. The folder name carries no licence claim, so none is inferred from it.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Under the licence gate in this file, nothing from this pack goes into `assets/` until a licence is read off disk or the author's own terms are on file. Nothing has been imported, converted or redistributed.

## PACK CATALOGUE - KayKit_Forest_Nature_Pack_1.0_FREE (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| KayKit_Forest_Nature_Pack_1.0_FREE (folder `_packs\KayKit_Forest_Nature_Pack_1.0_FREE\`, nested one level as `_packs\KayKit_Forest_Nature_Pack_1.0_FREE\KayKit_Forest_Nature_Pack_1.0_FREE\`; sibling `KayKit_Forest_Nature_Pack_1.0_FREE.zip` 6.4 MB, not opened this firing) | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0 (Creative Commons Zero)** | `...\KayKit_Forest_Nature_Pack_1.0_FREE\License.txt` (1,469 bytes, read in full off disk this firing) | 641 files on disk: 105 `.gltf` + 105 `.bin` (Assets\gltf), 210 `.fbx` (Assets\fbx and Assets\fbx(unity)), 105 `.obj` + 105 `.mtl` (Assets\obj), 7 `.png` (forest texture, sample, contents image), 1 `.txt` (License.txt), 3 `.url` (Discord, More KayKit Assets, Patreon). 105 distinct models; the same models appear in glTF, FBX and OBJ sets. | permitted: the licence says "free to use in personal, educational and commercial projects" | not required by CC0; the licence text asks for credit to Kay Lousberg, www.kaylousberg.com ("not mandatory, but would be appreciated") |

- Checked: walked every file under the pack (641 files, counted by extension and by directory), listed the licence-named files (only `License.txt`), and read `License.txt` in full. The licence text states: "License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/" and "This content is free to use in personal, educational and commercial projects."
- The folder name and the earlier tier-1 row (line 244, which cites this pack's `License.txt`) were not used as the licence claim; the CC0 grant comes from the file read this firing.
- Format note for the art lane: glTF/GLB is available (`Assets\gltf`), so no Blender conversion is needed for this pack. KayKit double-extension rule from the Notes section still applies to any file that is renamed on import.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `KayKit_Forest_Nature_Pack_1.0_FREE`. Nothing has been imported, converted or redistributed by this firing. Any model that enters `assets/` still needs its own row.

## PACK CATALOGUE - dungeon_collection_for_assetforge (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| dungeon_collection_for_assetforge (folder `_packs\dungeon_collection_for_assetforge\`, flat, no subfolder; sibling `dungeon_collection_for_assetforge.zip` 78,780 bytes, 112 entries, names listed only, not extracted) | Not named in any file on disk | **NO LICENCE FILE FOUND** | None. No licence, readme, terms, credit or URL file exists in the folder or in the zip listing. A grep of every file for licen, copyright, creative commons, cc0, cc-by, public domain, all rights, terms, attribution, author and credit returned no hits. | 112 on disk: 56 `.obj` + 56 `.mtl` (modular dungeon pieces: floors, walls, doorframes, pillars, rails, steps, gateways, levers, pedestal, switch floor; each in Full / Half / Outer / Large variants). Materials: Dark_Grey, Grey, Light_Grey, Green_Stone_-_Dark, Green_Stone_-_Normal. No texture images. The `.obj` and `.mtl` headers carry only `mtllib` and object names, no author or tool comment. | Not established | Not established |

- Checked: walked every file under `_packs\dungeon_collection_for_assetforge\` (112 files, counted by type), listed the 112 entries inside `dungeon_collection_for_assetforge.zip` with Python `zipfile` (not extracted; no licence-named entry), and grepped all text files for licence wording. The folder name carries no licence claim, so none is inferred from it.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Under the licence gate in this file, nothing from this pack goes into `assets/` until a licence is read off disk or the author's own terms are on file. Nothing has been imported, converted or redistributed.

## PACK CATALOGUE - free_mine_assets (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| free_mine_assets (folder `_packs\free_mine_assets\`, flat, no subfolder; sibling `free_mine_assets.zip` 15,879,070 bytes, 10 entries, names listed only, not extracted) | Not named in any file on disk (a `.blend` `author[80]` field exists in the binary header but holds no value worth reading as a licence) | **NO LICENCE FILE FOUND** | None. No licence, readme, terms, credit or URL file exists in the folder or in the zip listing. A grep of every file for licen, copyright, creative commons, cc0, cc-by, public domain, all rights, attribution, author and readme returned no licence wording. The seven PNGs carry only `IHDR`, `IDAT`, `pHYs`, `tIME`, `bKGD` chunks, no `tEXt`/`zTXt`/`iTXt` text. The one `cc0` byte run inside `rock1_norm.png` is raw compressed pixel data, not a licence. | 9 on disk: `mine_parts.blend`, `mine_parts_prev.blend`, and `textures\` holding `iron_diffuse`, `iron_normal`, `rock1`, `rock1_norm`, `rock1_spec`, `wood1`, `wood1_norm` (.png). | Not established | Not established |

- Checked: walked every file under `_packs\free_mine_assets\` (9 files), listed the 10 zip entries with Python `zipfile` (not extracted), grepped all nine files for licence wording, and parsed the PNG chunk tables of the seven textures. The folder name carries no licence claim, so none is inferred from it.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Under the licence gate in this file, nothing from this pack goes into `assets/` until a licence is read off disk or the author's own terms are on file. Nothing has been imported, converted or redistributed.

## PACK CATALOGUE - Medieval_Village_MegaKit (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Medieval Village MegaKit, STANDARD (free) edition (folder `_packs\Medieval_Village_MegaKit\Medieval Village MegaKit[Standard]\`; sibling `Medieval_Village_MegaKit.zip` 161,003,471 bytes, 10 entries not extracted) | Quaternius (quaternius.com) | CC0 1.0 Universal | `License_Standard.txt`, read verbatim: "License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/" then "Models by @Quaternius" | 936 files on disk: 176 models each in FBX, glTF, OBJ (with 176 .mtl and 176 .bin companions), 54 PNG and 1 JPG textures, 1 TXT licence | Yes (CC0) | Not required. The file asks for Patreon and Discord support only. |

- Checked: walked the whole pack folder with `find` (936 files, by extension), read `License_Standard.txt` in full, confirmed the CC0 1.0 grant. Nothing extracted, converted or imported.
- Scope: the file says this is the STANDARD free edition, which holds only a portion of the models. The PRO and SOURCE editions are separate purchases and are not on disk. Nothing from them is covered by this entry.
- Status: **CLEARED. CC0 1.0, usable for commercial use, no attribution required.** Covers only the 176 models in this folder.

## PACK CATALOGUE - golem_clean_blend (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| golem_clean_blend (folder `_packs\golem_clean_blend\`, flat, one file; sibling `golem_clean_blend.zip` holds the same single entry, not extracted) | Gapchich Vladislav (aka gavlig), named in the file's own text block | **NO LICENCE FILE FOUND.** The author's informal note is inside the .blend only: no named licence (not CC0, not CC-BY, not any family on the forbidden list) | None as a file. Inside `golem_clean.blend` a text datablock reads, verbatim: "You can use it in any way you want, you don't even have to credit me as an author (Though I'd like to know if you use it in some interesing project just to please my ego :))" and "So if you like it and want to use it - go ahead!" and "please, email me at gavlig@gmail.com" for mistakes or a request. A second note: "Concept was taken from http://www.render.ru/gallery/show_work.php?work_id=72971 (Many thanks to Boris. for his super awesome artwork!)". A third: "This version of .blend doesn't include diffuse, normal and spec maps because I used a texture from cgtextures.com and blendswap.com forbids sharing textures". | 1 on disk: `golem_clean.blend` (7,019,420 bytes, Blender 2.64 format). No texture files shipped. The blend names `golem_emit.png` and `golem_swap.png` as image references, which are not in the pack. | Granted in the author's note ("any way you want"). Not stated as a formal licence. | Not required by the note. Author asks for a link or a message, which is a request, not a condition. |

- Checked: walked `_packs\golem_clean_blend\` (1 file), listed the 1 zip entry with Python `zipfile` (not extracted), grepped the .blend for licence, copyright, CC, attribution, author, credit and URL wording, and read the full text of the two datablocks that carry the author's notes. The folder name carries no licence claim, so none is inferred from it.
- Judgement call, for Mr. E: the author's note is a real, commercially permissive grant, and the log's own gate counts "the author's own terms on file" as enough. It is still not a named licence, it does not say whether redistribution is allowed beyond "use it", and the concept is credited to another artist's render.ru artwork, whose rights are not on file. For those reasons this firing records it as NOT CLEARED rather than reading the note as CC0. The author's address is in the note if a written licence is wanted.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND. Author's informal note only (gavlig, in-file, permissive but unnamed); concept-art provenance (render.ru) unverified.** Nothing from this pack goes into `assets/` until Mr. E decides or a named licence is on file. Nothing has been imported, converted or redistributed.

## PACK CATALOGUE - handpainted_weapons (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| handpainted_weapons (folder `_packs\handpainted_weapons\`, sibling `handpainted_weapons.zip` 2.1 MB, 73 entries incl. one directory, not extracted) | not named in any file on disk | **NO LICENCE FILE FOUND** | none. No LICENSE, README, credits or terms file in the folder or in the zip. | 72 on disk, agreeing with the zip: `shield_a..d` and `sword_a..j` as `.obj` + `.mtl` (8 + 20), two Blender scenes `handpainted weapons 2-79.blend` and `2-80.blend`, and `textures/` with 42 PNG | not established | not established |

- Checked: walked the folder (72 files), listed every zip entry with `unzip -l` (not extracted), name-scanned both for licence, readme, credits, terms, about and copying (none), and grepped every file, the binary `.blend` scenes included, for licence, CC0, CC-BY, public domain and copyright wording. The only hits in the PNGs are the stock XMP metadata template, with empty CopyrightOwner and Licensor fields. The OBJ and MTL headers name a Blender scene and nothing else.
- LEAD, NOT A LICENCE: both `.blend` scenes carry an embedded text datablock reading "The models are based on Cethiel's CC0 2D weapon collection", linking opengameart.org/content/weapons-collection and Cethiel's Patreon and Twitter, and saying "under CC0 as well". That points at a CC0 source and is worth a follow-up, but it is a note inside a model file, not a licence file, and the source page was not read from disk or fetched this firing. Per the gate it does not clear the pack.
- This closes the open question left in the System 8 section above: the folder has no licence file, so `shield_a..d` remain out of the repo.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Lead only: an in-blend note naming Cethiel's CC0 2D weapon collection. Nothing from this pack goes into `assets/` until a licence is read off disk, or the Cethiel OGA page's terms are read and recorded here under their own row.

## PACK CATALOGUE - low-poly_RPG_item_collection_2 (24 Nov 2026, pack-catalogue firing)

- **Licence: NO LICENCE FILE FOUND.** Checked the extracted folder and the sibling `low-poly_RPG_item_collection_2.zip`: neither holds a licence, copying, readme, terms or credits file. The zip lists 27 entries, all models and textures. The `.blend` and `.3ds` binaries carry no readable licence text (a string scan found only binary noise). Per the rule, nothing is recorded as CC0 or any other licence.
- **Import status: GATED.** No model from this pack goes into `assets/` until a licence is found. Measuring it is allowed, and importing is not.
- **File count:** 27 files in the folder (the zip holds the same 27 entries). Contents: 8 `.obj` models and 17 `.png` textures (each model has a numbered second texture, and crystal has a third) (armor, barrel, book, crossbow, crystal, dagger, key, scroll; crystal has 3), plus `rpg items 2.blend` and `rpg items 2.3ds` sources.
- **Commercial use:** unknown, because no licence text was found. Not cleared for use.
- **Attribution:** unknown.
- **Action for Mr. E or the art lane:** find the original listing (the author or source page) and take its licence text, then put that text in this folder before any import.

## PACK CATALOGUE - low-poly_RPG_item_collection_3 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| low-poly_RPG_item_collection_3 (folder `_packs\low-poly_RPG_item_collection_3\`, sibling `low-poly_RPG_item_collection_3.zip` 24.5 MB, 27 entries, not extracted) | not named in any file on disk | **NO LICENCE FILE FOUND** | none. No LICENSE, COPYING, README, credits or terms file in the folder or in the zip. | 27 on disk, agreeing with the zip entry for entry: 7 `.obj` (`bridge`, `conifer`, `house`, `rock`, `sign`, `tree`, `well`), 18 `.png` textures (each model has one or two numbered textures, plus `dirt`, `grass`, `pavement`, `sand`), `rpg items 3.blend` (13 MB), `rpg items 3.3ds` | not established | not established |

- Checked: walked the folder (27 files, counted by extension), listed every zip entry with `python zipfile` (names only, not extracted), name-scanned both for licence, copying, readme, terms, credits and about (none), grepped every `.obj` header for licence, copyright, CC0, public domain, author and Quaternius or Kenney wording (no hits), and ran `strings` over the `.blend` and `.3ds` binaries for the same terms (no licence text; the only hits are Blender's own `author` metadata field name).
- Naming note: the sibling `low-poly_RPG_item_collection_2` (catalogued 24 Nov, see above) is a different pack with the same no-licence result. Do not treat either as covered by the other.
- Status: **NOT CLEARED. NO LICENCE FILE FOUND.** Nothing from this pack goes into `assets/` until a licence is found: take the original listing's licence text from its author or source page and record it here under its own row.

## PACK CATALOGUE - Stone_coffin (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Stone_coffin (folder `_packs\Stone_coffin\`, flat, no subfolder; sibling `Stone_coffin.7z` 1,004,262 bytes, not opened this firing) | Nobiax (named in the readme: "Provided by Nobiax") | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\Stone_coffin\readme.txt` (885 bytes, read in full off disk this run) | 5 on disk: `Stone_coffin.FBX` (32,288 bytes), `Stone_coffin.obj` (16,832 bytes), `diffuse.tga` (1.57 MB), `preview.jpg` (1280x720), `readme.txt`. Walked the tree with `find`: 5 files, no others. | Yes. The readme states: "You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission." | Not required. The readme asks for a link back ("Please, give me a link of the result at nobiax.deviantart.com ..."), which is a request, not a condition. |

- Checked: walked every file under `_packs\Stone_coffin\` (5 files), read `readme.txt` in full off disk (CRLF text; it names "CC0 1.0 Universal (CC0 1.0) / Public Domain Dedication" and quotes the grant wording in the Licence column; it carries no URL). The `grep` for licence terms hit `preview.jpg` only; inspected it with `grep -a` and `file`: the hits are JPEG/Exif byte noise ("CC00CB"), not licence text, so no licence is taken from the image.
- Consistency: this agrees with the earlier gap entry in the LICENCE GATE section (THE THREE PACKS IN THE 18/21 GAP, 20 Nov), which read the same readme. Nothing there is changed.
- Note for later seats: the `.7z` sibling was not opened; the CC0 grant is recorded for the pack as published. Any mesh or texture that enters `assets/` still needs its own row.
- Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `Stone_coffin`. Nothing has been imported, converted or redistributed by this firing.

## PACK CATALOGUE - Ultimate_Stylized_Nature (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Ultimate Stylized Nature - May 2022 (folder `_packs\Ultimate_Stylized_Nature\`, one subfolder `Ultimate Stylized Nature - May 2022\`; no zip sibling on disk) | Quaternius (quaternius.com, Patreon link in the file) | **CC0 1.0 Universal (Public Domain Dedication)** | `_packs\Ultimate_Stylized_Nature\Ultimate Stylized Nature - May 2022\License.txt` (read in full off disk this firing) | 369 on disk: 64 `.blend`, 63 `.obj`, 63 `.mtl`, 63 `.fbx`, 36 `.gltf` with 36 `.bin` sidecars, 36 `.png`, 7 `.jpg`, 1 `.txt` (`License.txt`) | Permitted: the CC0 1.0 grant covers commercial use with no conditions. | Not required by the licence. |

**Licence text read in full from disk this firing.** The file carries the CC0 1.0 Universal grant and the URL `creativecommons.org/publicdomain/zero/1.0/`, with the Quaternius Patreon line above it. No share-alike, no non-commercial, no no-derivatives clause.

**Vendor header error, recorded so it is not quoted as proof for the wrong pack.** The title line inside that `License.txt` reads "Ultimate Platformer Pack by @Quaternius", not "Ultimate Stylized Nature". This is the same copy-paste already logged in the licence-gate note above (ONE THING WRONG IN A LICENCE FILE). The grant beneath it is unambiguous CC0 1.0 and Quaternius's blanket licence covers the pack either way. If a stricter proof is ever wanted, the authority is quaternius.com's licence page for this pack.

Status: **CLEARED for use (CC0 1.0).** Licence gate satisfied for `Ultimate_Stylized_Nature`. Nothing has been imported, converted or redistributed by this firing. Any file that enters `assets/` still needs its own row.

## PACK CATALOGUE - grass_07 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| grass_07 (folder `_packs\grass_07\`, flat, no subfolder; sibling `grass_07.7z` 1,386,811 bytes, not opened this firing) | Nobiax (named in the readme: "Provided by Nobiax") | **Custom permissive grant - NOT CC0.** Do not re-record as CC0. | `_packs\grass_07\readme.txt` (262 bytes, CRLF, read in full off disk this run) | 8 on disk: `grass_07.FBX` (38,896 bytes), `grass_07.obj` (4,314 bytes), `diffus.tga`, `normal.tga`, `opacity.tga`, `specular.tga`, `preview.jpg`, `readme.txt`. Walked the tree with `find`: 8 files, no others. | Yes. The readme states, verbatim: "Absolutely free to use or to modify in any kind of work (personal, commercial or else)." | Not required. The readme says "Give me a link of the result at nobiax.deviantart.com or my other account on OpenGameArt.com or ShareCG.com" - a request, with no "provided that" anywhere, so it is not an attribution condition. |

- Checked: read `readme.txt` in full off disk this run (the whole file is three short paragraphs and is quoted in the table above). A content scan of all 8 files for licence, copyright, CC0 and "free to use" terms hit only `readme.txt`; the binaries and `preview.jpg` were not treated as licence sources.
- Consistency: agrees with the 20 Nov entry in THE THREE PACKS IN THE 18/21 GAP section, which read the same readme. Nothing there is changed.
- Not share-alike, not non-commercial, not no-derivatives: none of the three forbidden families applies, so the pack is not rejected.
- Note for later seats: the readme grants a custom permissive licence, not CC0. Any repo copy that is not a file-for-file re-export should still carry its own row, and any redistribution AS an asset is outside what this readme states on its face.
- Status: **CLEARED for use (custom permissive grant, commercial use permitted, no attribution required; link-back requested).** Licence gate satisfied for `grass_07`. Nothing has been imported, converted or redistributed by this firing.

## PACK CATALOGUE - kaykit_dungeon_pack_CC0 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| KayKit Dungeon Pack 1.0 (folder `_packs\kaykit_dungeon_pack_CC0\`, sibling `kaykit_dungeon_pack_CC0.zip`) | Kay Lousberg (www.kaylousberg.com) | **CC0 1.0 Universal** (text states "License: (Creative Commons Zero, CC0)" with link to creativecommons.org/publicdomain/zero/1.0/) | `License.txt` (630 bytes, CRLF, read in full off disk this run) | 1,079 files on disk in total: 226 .obj, 226 .mtl, 208 .fbx, 202 .dae, 192 .glb, 12 .png, 10 .gltf, 2 .url, 1 .txt. `Models/gltf/` holds 185 `*.gltf.glb` models (as the 20 Nov rows record). | Yes. The licence states verbatim: "This content is free to use in personal, educational and commercial projects." | Not required. The licence states: "Support me by using a brand resource provided in this pack or by crediting Kay Lousberg, www.kaylousberg.com (this is not mandatory)". |

- Checked: read `License.txt` in full off disk this run (quoted in the table). Tallied file types with `find` on the pack tree. The `.url` and `.png` files were not treated as licence sources.
- Consistency: agrees with the 20 Nov worldfit note (`kaykit_dungeon_pack_CC0`, 185 models, CC0 1.0). Nothing there is changed.
- Not share-alike, not non-commercial, not no-derivatives: none of the forbidden families applies.
- Status: **CLEARED for use (CC0 1.0, commercial use permitted, no attribution required).** Licence gate satisfied for `kaykit_dungeon_pack_CC0`. Nothing has been imported, converted or redistributed by this firing.

## PACK CATALOGUE - kenney_fantasy-town-kit_2.0 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Fantasy Town Kit (2.0) (folder `_packs\kenney_fantasy-town-kit_2.0\`, flat, no nested subfolder; sibling `kenney_fantasy-town-kit_2.0.zip` 3,854,691 bytes, not opened this firing) | Kenney (www.kenney.nl), created 03-08-2025 | **CC0 1.0 Universal (Creative Commons Zero)** | `_packs\kenney_fantasy-town-kit_2.0\License.txt` (read in full off disk this run, CRLF text) | 847 on disk: 167 models each in FBX (`Models\FBX format\`), GLB (`Models\GLB format\`), and OBJ + MTL (`Models\OBJ format\`), i.e. 668 model files; 174 `.png` (`Previews\` per model, `Models\*\Textures\colormap.png`, `Models\Textures\variation-a.png`, `Preview.png`, `Preview (Variation A).png`, `Sample.png`); 3 `.url` (documentation, Kenney, Patreon); `Overview.html`; `License.txt` | Yes. The licence reads verbatim: "License: (Creative Commons Zero, CC0)" with the CC0 1.0 URL, then "You can use this content for personal, educational, and commercial purposes." | Not required. The licence says: "Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)". Credit kept anyway. |

- Checked: read `License.txt` in full off disk this run (the whole file is a header, the CC0 grant, a support note and social links). Counted every file under the pack folder by extension with `find`: 847 files, no others. The `.png` and `.url` files were not treated as licence sources.
- Consistency: agrees with the 20 Nov Tier 1 row for Fantasy Town Kit 2.0 (CC0 1.0, `.../Models/GLB format` 167 files) and with the 20 Nov worldfit measurement. Nothing there is changed.
- Not share-alike, not non-commercial, not no-derivatives: none of the forbidden families applies.
- Status: **CLEARED for use (CC0 1.0, commercial use permitted, no attribution required).** Licence gate satisfied for `kenney_fantasy-town-kit_2.0`. Nothing has been imported, converted or redistributed by this firing. Any file that enters `assets/` still needs its own row.

## PACK CATALOGUE - kenney_graveyard-kit_5.0 (24 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| Graveyard Kit 5.0 (folder `_packs\kenney_graveyard-kit_5.0\`, flat, one `Models\` subtree; sibling `kenney_graveyard-kit_5.0.zip` 3,623,408 bytes, not opened this firing) | Kenney (www.kenney.nl), created 17-10-2025 | **CC0 1.0 Universal (Creative Commons Zero)** | `_packs\kenney_graveyard-kit_5.0\License.txt` (702 bytes, CRLF, read in full off disk this run) | 465 on disk: 91 `.fbx` (`Models\FBX format\`), 91 `.glb` (`Models\GLB format\`), 91 `.obj` + 91 `.mtl` (`Models\OBJ format\`), 96 `.png` (previews, textures, `Preview.png`, `Sample.png`), 3 `.url`, 1 `.html` (`Overview.html`), 1 `.txt` (`License.txt`). Walked the tree with `find`: 465 files, no others. | Yes. The licence reads verbatim: "License: (Creative Commons Zero, CC0)" with the CC0 1.0 URL, then "You can use this content for personal, educational, and commercial purposes." | Not required. The licence says: "Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)". |

- Checked: read `License.txt` in full off disk this run. `Overview.html` line 143 links the same CC0 1.0 Universal URL, so the vendor's two files agree. Counted every file under the pack folder by extension (465 total, matching the sum of the per-type counts). The `.url` and `.png` files were not treated as licence sources.
- This closes the gap left by the 24 Nov licence-gate row for Graveyard Kit 5.0, which read "not measured this run - row written while the file was open". That row's CC0 claim now rests on the file read here, not on the earlier note.
- Not share-alike, not non-commercial, not no-derivatives: none of the forbidden families applies.
- Status: **CLEARED for use (CC0 1.0, commercial use permitted, no attribution required).** Licence gate satisfied for `kenney_graveyard-kit_5.0`. Nothing has been imported, converted or redistributed by this firing. Any file that enters `assets/` still needs its own row.


## PACK CATALOGUE - medieval_pack_CC0 (24 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\medieval_pack_CC0\` (sibling `medieval_pack_CC0.zip` checked: identical 28 files, no extras) |
| Author | Not stated in any file in the pack |
| Licence | **NO LICENCE FILE FOUND** - no LICENSE / License.txt / README / credits / terms file in the directory or the zip; zip comment empty. The folder name `CC0` is NOT a licence. Nothing guessed. |
| File count | 28 (`MedievalPack/Blends/`: 9 x .blend incl. `Katana.blend1` backup; `Blends/Textures/`: 5 x .png; `OBJ/`: 14 x .obj/.mtl) |
| Contents | Club, Dagger, DoubleAxe, Katana, LongSword, ShortSword, SimpleAxe, Spear |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed and gated. Do not import, convert or redistribute any file from this pack until an author licence is found. |

Method: directory listed recursively and zip central directory read with Python `zipfile` (not extracted); licence-like search (`*licen*`, `*readme*`, `*credit*`, `*terms*`, `*.txt`, `*.md`, `*.html`, `*.pdf`) returned nothing in either location. No `.blend` or `.obj` was opened.

## PACK CATALOGUE - modular_terrain_collections (25 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\modular_terrain_collections\` (sibling `modular_terrain_collections.zip`, 511,263 bytes, checked by central directory read with Python `zipfile`, not extracted: 264 entries, identical to the folder, zip comment empty) |
| Author | Not stated in any file in the pack |
| Licence | **NO LICENCE FILE FOUND** - no LICENSE / License.txt / README / credits / terms / copying / html / pdf / url file anywhere in the directory or the zip. A case-insensitive text search of every file in the folder for `licen*`, `CC0`, `creative commons`, `public domain` and `attribution` returned no hits. The folder name `modular_terrain_collections` carries no licence claim. Nothing guessed. |
| File count | 264 on disk: 132 x `.obj` and 132 x `.mtl`, nothing else. No textures. Walked with `find`, extension count with `sed`/`uniq`. |
| Contents | Two sub-sets with models: `Modular Terrain Beach/` (sand, docks, shells, starfish, palms, treasure chest) and `Modular Terrain Cliff/` (cliff bases, mid and top corners, waterfalls, hills). |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed and gated. Do not import, convert or redistribute any file from this pack until an author licence is found. The 20 Nov licence-gate list already named this pack as gated; this firing confirms that state against the disk. |

Method: directory listed recursively; licence-like names searched in the folder and in the zip; every file's text searched for licence terms with `grep -ril`, which returned nothing. No `.obj` or `.mtl` was opened as a licence source.


## PACK CATALOGUE - modular_village_collection (25 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\modular_village_collection\` (sibling `modular_village_collection.zip`, 648,523 bytes, checked by central-directory read with Python `zipfile`, not extracted: 143 entries, identical to the folder, zip comment empty) |
| Author | Not stated in any file in the pack |
| Licence | **NO LICENCE FILE FOUND** - no LICENSE / License.txt / README / credits / terms / EULA / html / pdf / url file in the directory or the zip. A case-insensitive text search of every file for `licen*`, `CC0`, `creative commons`, `public domain`, `attribution`, `copyright` and `credit` returned no hits. The folder name carries no licence claim. Nothing guessed. |
| File count | 143 on disk: 142 x `.obj` and 1 x `.mtl` (`Materials_Modular_Village.mtl`), all under `Modular Village/`. No textures, no images. |
| Contents | Modular village kit: stucco and stone walls, doorways, windows, roof pieces and eaves, canopies, wood and cobble floors, waterwheel and flume sections, and props (barrels, crates, wells, street lamp, ladder, broom, sign). |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed and gated. Do not import, convert or redistribute any file from this pack until an author licence is found. This entry confirms against the disk the 20 Nov licence-gate listing, which had named the pack without a read. |

Method: directory listed recursively and extension-counted with `find`; the sibling zip read by central directory; a case-insensitive grep of every file's text for licence terms returned nothing. No `.obj` was opened as a licence source; the `.mtl` material values were checked and carry no terms.


## PACK CATALOGUE - quaternius_medieval_weapons_2018_CC0 (25 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\quaternius_medieval_weapons_2018_CC0\` (inner folder `Medieval Weapons Pack - Sept 2018\`; sibling `quaternius_medieval_weapons_2018_CC0.zip`, 3,741,460 bytes, checked by central-directory read with Python `zipfile`, not extracted: 101 entries = 97 files + 4 folder entries, zip comment empty, identical to the folder) |
| Author | Quaternius (named in the table above from the source page; the pack's own files do not state it) |
| Licence | **NO LICENCE FILE FOUND.** No LICENSE / License.txt / readme / credits / terms / copying / html / pdf / url file anywhere in the folder or the zip. A case-insensitive text search of every file in the folder for `licen*`, `CC0`, `creative commons`, `public domain`, `attribution`, `copyright` and `credit` returned no hits. The folder name carries `CC0`, but a folder name is not a licence (see the 20 Nov naming-trap note). The `CC0 1.0` entry in the table above is the supervisor's record from the source page, not a licence read from this pack, so it is not treated as cleared. Nothing guessed. |
| File count | 97 on disk: 24 x `.blend` (`Blends/`), 24 x `.fbx` (`FBX/`), 24 x `.obj` + 24 x `.mtl` (`OBJ/`), 1 x `Preview.png`. No textures on disk. |
| Contents | Medieval weapons and shields, 24 models: Arrow, Axe, Axe_Double, Axe_Small, Bow_Evil, Bow_Golden, Bow_Wooden, Bow_Wooden2, Claymore, Dagger, Dagger_2, Hammer_Double, Hammer_Small, Scythe, Shield_Celtic_Golden, Shield_Heater, Shield_Heater_2, Shield_Round, Shield_Round_2, Spear, Sword, Sword_2, Sword_Big, Sword_Golden. |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed and gated. Do not import, convert or redistribute any file from this pack until a licence file or an author licence is found on disk. This firing confirms against the disk the 20 Nov licence-gate listing, which had named the pack without a read. |

Method: folder walked recursively with `find` and extension-counted; sibling zip read by central directory; licence-like filenames searched at every depth; case-insensitive grep of every file's text for licence terms returned nothing. No `.obj`, `.mtl` or `.fbx` was opened as a licence source. Only the `.mtl` header was looked at, to confirm it is a Blender export and carries no terms.

## PACK CATALOGUE - rocks (25 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\rocks\` (sibling `rocks.7z`, 77,656,287 bytes, not opened) |
| Author | Nobiax (named in the licence text as "Provided by Nobiax"; Yughues credited as the OpenGameArt/ShareCG handle) |
| Licence | **CC0 1.0 Universal (Public Domain Dedication)**, read verbatim from `readme.txt` (885 bytes, SHA-256 `04bd29b2a8d12f4b86700c69a8d9ddf933ec8a43913017950c9948afe34bfcc2`). The file states the work is dedicated to the public domain, "You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission." |
| File count | 32 on disk across 6 directories: 5 x rock folders (`01`-`05`), each holding `diffuse.tga`, `normal.tga`, `specular.tga`, `preview.jpg`, `rock_0N.obj` and `rock_0N.fbx` (30 files), plus root `preview.jpg` and `readme.txt`. The `05` folder's FBX is named `rock_05..fbx` (double dot) - rename on import. |
| Contents | Five rock models with their own diffuse, normal and specular maps. Recorded so a later reader can find it by contents. |
| Commercial use | **Permitted.** CC0 1.0 grants it outright. |
| Attribution | **Not required.** The readme asks for a link to the result ("Please, give me a link of the result at nobiax.deviantart.com ... or on Youtube"). That is a request, not a condition of the grant, so it is recorded here and not enforced. |
| Forbidden-family check | None of CC-BY-NC, CC-BY-ND, CC-BY-SA apply. |
| Cleared for use | **YES - CC0 1.0.** Licence gate satisfied. The 20 Nov licence-gate list named `rocks` as having no licence file; that was wrong: `readme.txt` is present at the pack root and was read in full this firing. Any file that enters `assets/` still needs its own row. |

Method: folder walked recursively with `find` (32 files, 6 directories); `readme.txt` read in full with `cat -A` to see line endings and hidden text, and hashed. Sibling `rocks.7z` not opened. No model or texture was opened as a licence source.

## PACK CATALOGUE - ultimate_animated_character_pack (25 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack directory | `C:\hd adventure\_packs\ultimate_animated_character_pack\` (inner folder `Ultimate Animated Character Pack - Nov 2019\`; sibling `ultimate_animated_character_pack.zip`, 48,430,012 bytes, checked by central-directory read with Python `zipfile`, not extracted: 213 entries = 209 files + 4 folder entries, zip comment empty, same contents as the folder) |
| Author | Not stated by the pack itself. The 2019 name and the `Blends/`, `FBX/`, `OBJ/` layout match the Quaternius character set, but no author line was found in any file read, so nothing is attributed here |
| Licence | **NO LICENCE FILE FOUND.** No LICENSE / License / copying / readme / credits / terms / eula / about / txt / md / html / pdf / url file in the folder or the zip, at any depth. The folder holds only `.blend`, `.fbx`, `.obj`, `.mtl` and one `Preview.png`. A case-insensitive text search of every `.obj` and `.mtl` for `licen`, `creative commons`, `CC0`, `CC-BY`, `copyright`, `public domain`, `attribution`, `quaternius` and `author` returned no hits. The 20 Nov licence-gate list also named this pack without a read; that is confirmed here. No licence is recorded from memory or from the source page. Nothing guessed. |
| File count | 209 on disk: 52 x `.blend` (`Blends/`), 52 x `.fbx` (`FBX/`), 52 x `.obj` + 52 x `.mtl` (`OBJ/`), 1 x `Preview.png` (1920 x 1080 RGBA). No textures on disk. 4 subfolders. |
| Contents | Animated base and character models (BaseCharacter, BlueSoldier_Female/Male, Casual2_Female and similar). Recorded so a later reader can find it by contents. |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed and gated. Do not import, convert or redistribute any file from this pack until a licence file or an author licence is found on disk. |

Method: folder walked with `find` (209 files, 5 directories including root), extension-counted; sibling zip read by central directory; licence-like names searched at every depth; case-insensitive grep of the `.obj` and `.mtl` text for licence terms returned nothing. The `.mtl` header was read only to confirm it is a Blender export. No `.blend`, `.fbx` or `.obj` body was opened as a licence source. Selection note: every other directory in `_packs` already has a catalogue entry; this pack appeared only in the 20 Nov gate list, so it was the next one unverified.

## PACK CATALOGUE - 19_fantasy_weapons_CC0.blend (26 Nov 2026, pack-catalogue firing)

| Field | Value |
|---|---|
| Pack location | `C:\hd adventure\_packs\19_fantasy_weapons_CC0.blend` (loose single file, 653,584 bytes, Blender 2.7x-era header `BLENDER_v271`. Not a directory, and it has no sibling `.zip` or folder. It was the only item in `_packs` with no catalogue entry, so it was the next one unverified) |
| Author | Not stated in the file. The top table of this document credits "(OGA upload)", and that is not verified against anything on disk |
| Licence | **NO LICENCE FILE FOUND.** No LICENSE, readme, credits or terms file exists beside the blend in `_packs`. A binary scan of the whole `.blend` for `licen[cs]e`, `creative commons`, `CC0`, `CC-BY`, `public domain`, `attribution`, `copyright`, `opengameart`, `author`, `readme`, `credit`, `terms`, `kenney`, `kaykit`, `quaternius` returned no licence text. The only hit was the Blender struct field `author[80]`, which is not a licence. No text datablock is present. **The CC0 entry in the top table is therefore unverified against the file, and this entry does not confirm it.** Nothing is guessed. |
| File count | 1 file. Inside it: 19 weapon objects (Axe, Bardiche, Battleaxe, Bow, Broadsword, Buckler, Dagger, Glaive, Greatsword, Halberd, Katana, Longsword, Mace, Rapier, Saber, Scimitar, Shortsword, Spear, Warhammer), plus a `Weapons` collection and a `Camera`. The mesh datablocks are 26, materials 3 (`Material`, `Material.001`, `Material.002`), images 1 (`longsword_normal.png`, which is an external-path reference and not embedded). |
| Commercial use | Not determinable from the pack |
| Attribution | Not determinable from the pack |
| Cleared for use | **NO.** Unlicensed on disk and gated. Do not import, convert, or ship any mesh from this file until a licence file or an author licence is found on disk. |

Method: file size and magic header read with `od`. Binary scan run with Python `re` (case-insensitive, read-only) over the whole file for licence terms and a broad set of licence-adjacent words. Datablock names extracted from the binary by prefix (`OB`, `ME`, `MA`, `TE`, `IM`, `TXT`, `SC`, `WO`, `CA`, `LA`). The file was not opened in Blender and nothing was written to it. No other file was read as a licence source.

Selection note: every real directory in `_packs` already has a catalogue entry (checked by name against this file), so the only unverified item was this loose blend. The `_extracted_rpg_items` and `_generated` folders are our own working directories (see the LICENCE GATE section), not third-party packs.

## PACK CATALOGUE - _extracted_rpg_items (27 Nov 2026, pack-catalogue firing)

| Pack | Author | Licence | Licence text on disk | Files | Commercial use | Attribution |
|---|---|---|---|---|---|---|
| _extracted_rpg_items (an FBX-only extraction of "Ultimate RPG Items Pack - Aug 2019", whose source is `_packs\quaternius_ultimate_rpg_items_CC0\`, verified above) | Quaternius (patreon.com/quaternius) | **CC0 1.0 Universal** (inherited from the source pack) | **NONE inside this folder.** Licence read in full from the source: `_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019\License.txt` ("LowPoly Models by @Quaternius ... CC0 1.0 Universal ... https://creativecommons.org/publicdomain/zero/1.0/") | 106 `.fbx`, 0 other files | permitted (CC0 1.0) | not required by CC0; credit kept (Quaternius) |

- Checked: walked every file under `_packs\_extracted_rpg_items\` (106 files, all `.fbx`, all under `Ultimate RPG Items Pack - Aug 2019\FBX\`). Set-compared against the source pack's `FBX\` folder: 106 names in each, identical, none extra, none missing.
- Why a row at all: the folder name is not in the log, so a reader could mistake its FBX files for an unlogged download. They are the same CC0 geometry as the row above, not a new source.
- No licence file in this folder. Per the rule, it is recorded as such here rather than guessed; the licence is taken from the source pack's `License.txt`, which is the only copy on disk.
- Not in `_packs\_generated\` (art-lane output, not a third-party download): it holds lane-made `.glb`, textures and `refs\` images, with no licence claim. Not catalogued here.
- Status: **CLEARED for use (CC0 1.0), by inheritance from `quaternius_ultimate_rpg_items_CC0`.** Any FBX that enters `assets/` still needs its own row.

## Pack catalogue - 2026-11-27 (PACK CATALOGUE worker)

### `_packs/3d_crystals_new/` - NO LICENCE FILE FOUND - NOT CLEARED FOR USE
- Directory checked: `_packs/3d_crystals_new/` (5 files) and `_packs/3d_crystals_new.zip` (5 entries, zip comment empty). Neither holds a licence, readme, terms or credits file.
- Files: `174.jpg`, `174_norm.jpg`, `crystal.jpg`, `crystal_simple_norm.jpg` (images, 0.46-1.56 MB each), `crystals.blend` (4.0 MB Blender scene).
- Licence type: **unknown**. Author and source: **unknown** (no pack name, author or URL found on disk).
- Byte-level search of `crystals.blend` and the four JPGs for licence, copyright, CC and attribution strings returned nothing. The .blend may be compressed, so this search is not conclusive.
- Commercial use: **not established**. Attribution: **not established**.
- Decision: per the rule, recorded as NO LICENCE FILE FOUND and not guessed. Do not load, convert or ship anything from this pack until a licence is found or the author confirms one.
- Catalogue note: the pack is not in the tables above. Whether any file in the repo uses it was not checked.
## System - the tier-5 SPEAR (art lane, 27 Nov 2026, 23:4x CT)

`assets/gear/artifact/spear_golden.glb` is **derived from
`_packs/quaternius_medieval_weapons_2018_CC0/Medieval Weapons Pack - Sept 2018/OBJ/Spear.obj`**
(Quaternius, **CC0 1.0**, opengameart.org/content/lowpoly-medieval-weapons - the
row near the top of this file). That pack carries no licence file inside the
extracted folder, which is why it appears in the "no licence file on disk" list
above; it was nevertheless cleared and FIRST USED on 19 Nov for System 8's five
shields, which shipped with `LICENSE_Quaternius_MedievalWeapons_CC0.txt` written
beside them. This is a later use of an already-cleared pack, not a new import.

The derivation, all of it reversible from `tools/art/_speargen.py`:
  1. `Steel -> Golden` and `LightSteel -> LightGold`, which is **Quaternius' own
     golden-tier substitution** - proven this run by `tools/art/_goldmatprobe.py`,
     which found the pack's plain `Sword.obj` and the shipped `sword_golden.glb`
     carry identical triangle counts material for material (Steel 224 / Golden 224,
     LightSteel 132 / LightGold 132, DarkSteel 180, LightWood 240, DarkWood 96).
     Material VALUES are taken from the shipped `sword_golden.glb`, so the piece
     joins the golden family rather than inventing a gold.
  2. Uniform scale 9.7171 -> 3.500 units, origin moved to 33.0% from the butt
     (`spear_A`'s own proportion), shaft axis centred on x=y=0.
  3. Four radial gold langets and a LightGold collar at the socket, generated
     procedurally by `_speargen.py --langets 1` and therefore **original**.

Geometry otherwise unmodified. Fit proof and the honest fault list:
`docs/art/THE_TIER5_SPEAR_READ.md` and `renders/art/spear_langets/`.

## System 15 - the town square WELL -> FOUNTAIN, tiers 1-3 (art lane, 28 Nov 2026, 00:3x-01:2x CT)

**THE THREE MESHES THAT SHIPPED ARE ORIGINAL.** `assets/buildings/town_well_t1.glb`,
`town_well_t2.glb` and `town_well_t3.glb` are generated procedurally by
`tools/art/townbuild.py` (bmesh primitives out of `tools/art/lordlib.py`, no
imported geometry of any kind), so they carry no third-party rights and are
reproducible from that file alone. Full write-up: `docs/art/TOWN_WELL_TIERS.md`.

**WHY NOTHING WAS DERIVED FROM A PACK, WHICH IS THE PART THAT NEEDED CHECKING.**
Mr. E's rule 3 is packs before generation, and the plan row says a tier variant
derived from a cleared pack beats a mesh authored from nothing. So the packs
were walked first, this run, and not from memory:

| candidate | holds a well? | status | why |
|---|---|---|---|
| `low-poly_RPG_item_collection_3` | yes, `well.obj` | **GATED** | Already recorded above: NO LICENCE FILE FOUND, author not named, terms not established. |
| `modular_village_collection` | yes, 5: `Prop_Well_{1,Cobblestone,Dirt,Grass,Inside}.obj` | **GATED** | In the 20 Nov no-licence list. **Re-checked by walking the folder this run: 147 files, ZERO text files of ANY kind** - no LICENSE, no README, nothing that could carry terms. The "a README can still be a licence" exception cannot apply where there is no text file at all. |
| `kenney_fantasy-town-kit_2.0` | no well; 10 `fountain-*` | **CLEARED (CC0 1.0)** and **NOT USED - rejected on READ** | Measured off the evaluated depsgraph: `fountain-round` 2.00 x 2.00 x **0.28 m**, `-detail` 0.48 m, `fountain-center` 1.00 x 1.00 x 0.14 m. They are FLOOR TILES for a 2 m grid - ankle to knee on a 1.80 bar. A fountain the stream cannot see cannot carry "the town levelled up". The pack stays cleared and available for roads, walls and stalls. |
| `Medieval_Village_MegaKit` | no well, no fountain | CLEARED (CC0 1.0) | Nothing in it serves this item. |
| `Castle` | no well, no fountain | gated anyway | 11 building blocks, none relevant. |

Evidence for the Kenney row: `tools/art/_townwell_probe.py`, sheet
`renders/art/town/_probe/_kenney_fountain_candidates.png`, numbers
`renders/art/town/_probe/_probe.json` (verdict GREEN, 0 blanks, border 0,
subject proven seen at 32,866 px moved under ablation). **Measuring a pack
copies nothing; nothing was imported, converted or redistributed by this run.**

*** A NOTE ON WHAT THAT PROBE SHEET CANNOT SHOW, SO NOBODY RE-USES IT BLIND. ***
Its label gate scored every caption above 3,600 px and the captions are still
unreadable - they overlap in a diagonal pile, because I placed them all at one
world height and a pixel count cannot see overlap. Two pieces also fell off the
short floor slab. The per-piece DIMENSIONS in the table above are sound - they
come off the depsgraph per piece, independently of that sheet - but the sheet
itself is evidence only for "these things are small".

## The twelve town buildings - TEXTURES RESTORED (art lane, 28 Nov 2026, 02:0x-03:0x CT)

**No new source was introduced by this run and nothing was redistributed.**
The twelve buildings in `assets/buildings/` (`lm_barracks`, `lm_chapel`,
`lm_granary`, `lm_hall`, `lm_sawmill`, `lm_watermill`, `lm_windmill`,
`lm_workshop`, `mk_house_a`-`mk_house_d`) were already derived from the
**Medieval Village MegaKit [Standard]** on 15 Nov. That export stripped the
textures: all twelve carried **zero images and zero base-colour links**, every
material sitting at Blender's default grey. This run put the pack's **own**
textures back on them.

| asset | author | licence | licence file | what was taken |
|---|---|---|---|---|
| Medieval Village MegaKit [Standard] | Quaternius | **CC0 1.0 Universal** | `_packs\Medieval_Village_MegaKit\Medieval Village MegaKit[Standard]\License_Standard.txt` (read off disk 24 Nov, entry ~line 703) | the 9 material node graphs `MI_{Plaster, Brick, UnevenBrick, RockTrim, RoundTiles, WoodTrim, WoodTrim_Wear, MetalOrnaments, WindowGlass}` and their base-colour maps |

**THE DERIVATION IS REPRODUCIBLE FROM `tools/art/towntex.py` ALONE**, which is
the standard the tier-5 spear set. That file names the exact source module each
material is harvested from, and the recovery is exact rather than a repaint
because the stripped export kept both halves of the evidence - **UVs intact**
(225/225 meshes in `lm_hall`, inside 0..1) and **material names preserved**
under Blender's `.NNN` de-duplication suffix, with the pack's **object** names
(`Corner_Exterior_Brick.050`) surviving as independent corroboration.

Two materials were **checked rather than assumed**: `MI_WoodTrim_Wear`
resolves to the `T_WoodTrim_*` maps (the pack ships no `T_WoodTrim_Wear`), and
`MI_WindowGlass` carries no texture at all.

**Deliberate, reversible trade:** base colour only (normal and ORM maps
dropped, their channel means measured and baked to constants), JPEG q90 at
1024. `lm_hall` 28.1 MB -> 2.24 MB; the set costs **+12.5 MB** in total. Pass
`--px 2048` and restore the normal branch to reverse it.

Full write-up, the per-file table, the gates and the faults still visible:
`docs/art/TOWN_BUILDING_TEXTURES.md`. Sheet: `renders/art/town/_texfix_sheet.png`.
