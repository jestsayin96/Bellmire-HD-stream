# Asset catalogue - Jests HD / Bellmire

Every finished piece, where it lives, and what else it can be used for.
Generated buildings are geometry-only glb; materials are shared (assets/kit/materials).

## Buildings (assets/buildings, archived copies in village_assets/buildings/variants + .blend in buildings/landmarks)
| file | what | reuse |
|---|---|---|
| mk_house_a..d.glb | four MegaKit townhouse shapes (8x10, 5.5x7.6, 10x10, 8x12 m) | any town/hamlet/farmstead |
| lm_hall.glb | Chief's Hall, 3 storeys + 5-storey corner tower | keep, guildhall, manor, magistrate |
| lm_chapel.glb | chapel nave + bell tower with spire | temple, shrine town, abbey |
| lm_barracks.glb | two blocks + gate tower | garrison, guildhouse, inn courtyard |
| lm_windmill.glb | 4x4 m stone tower, sails added in Godot | windmill, lookout, wizard tower |
| lm_granary.glb | single-storey long house | barn, storehouse, stable |
| lm_watermill.glb | two-storey mill house, wheel added in Godot | watermill, ferry house |
| lm_workshop.glb | long two-storey workshop | guild workshop, warehouse, inn |
| lm_sawmill.glb | long single-storey shed | sawmill, stable, smithy shed |

## Procedural pieces (scripts/town.gd - functions, reusable anywhere)
_guard_tower (watchtower with lookout), _build_wall (fitted wall + towers + gatehouses), _build_bridge, _build_well,
_signpost, _livery_banner, _flagpole, windmill sails, water wheel, forge with live coals, shop yards (blacksmith,
armourer, apothecary, store, tavern), _road_strip (terrain-following road / dirt track), is_clear (placement rule), _timber_stack (log pile),
_build_mine (hillside mine mouth with rails + cart), _build_range (archery range), mountain + valley terrain (height_at),
ground shader with rock/snow by slope and altitude.

## Characters
addons/kaykit_character_pack_adventures (Knight, Barbarian, Mage, Rogue, Rogue_Hooded + weapons) - unchanged look.
scripts/townsfolk.gd - walking/entering villager.

## Props
assets/props (Quaternius fantasy props, 40+), assets/mkprops (MegaKit fences, wagon, crate, tower roof),
assets/nature (Quaternius trees/bushes).

## Shaders
assets/shaders/ground.gdshader (town dirt -> grass mask), water.gdshader (river).

## Snapshots / renders
snapshots/town_<stamp>_<label>.tscn - every generated town, openable without regenerating.
village_assets/renders/cycles/<stamp>_<label>/ - every probe render set.

## Fishing
data/fishing.json (loot table), scripts/fishing.gd (rules - reusable for any water: dungeon pools, lava 'fishing' later),
scripts/angler.gd (visible cast/bite/reel/show on any character), assets/fishing/ (catch models: fish, fish bones,
keys, chalice, bottle, pouch, chest, coin, rope, buckets, barrel, bone, skull, scar crystal, lily pads, rowboat).
Town pieces: _build_docks (timber jetty with piles, plank gaps, mooring post, rowboat), lily pads.

## Street furniture + meadow (town.gd)
_lamp_post (iron post, arm, glowing lantern, light, optional livery banner), _planter (flower box), _bench,
_meadow (MultiMesh ground cover - any outdoor scene), _kerb_ok/_in_house (placement against real house footprints).

## Countryside + scar (town.gd)
_build_scar (wild-magic scar: crystals, pulsing lights, hue-wandering motes, dungeon mouth arch, guild post with barrier +
'KEEP THE DOOR.'), ground.gdshader scar mode (scorch + flickering veins - reusable for any scar in the dungeon),
_build_fields (fenced crop field draped on terrain, wheat/veg MultiMesh rows), _build_farms (farmhouse + barn + haystacks +
cart + track), _ground_patch (terrain-draped quad grid with any material), _pulses (out-of-step flickering lights).

## Animals
assets/animals/ Cow, Horse, Pig, Sheep, Pug, Llama (rigged, Idle/Walk/WalkSlow/Run/Jump/Death), Duck, Corgi, Red (fox).
Library copies: village_assets/library/animals. scripts/animal.gd (wander-in-area AI, any rigged animal).
town.gd: _pen (fenced pen with water trough + gate gap), _spawn_animals, wheeling birds (_birds).

## Equipment
scripts/gear.gd - weapon families + tiers + armour tiers (data), equip/ignite on KayKit bones, ROLE_GEAR per trade,
dress_hero for viewer heroes. assets/gear - KayKit RPG tools (hammer, tongs, pickaxe, axe, shovel, saw, lantern, torch,
knife, mallet, journal, map) + Fantasy Weapons bits (swords A-E, axes, hammers, halberd, spear, staffs, wand, bow,
shields A-C). town.gd _tier_rack (priced, glowing shop display).

## Clothing + magic
gear.gd strip_props (hide KayKit built-in prop meshes), clothe (livery/role cape colours), rank_trim (guild-rank sash).
scripts/spells.gd - bolt / heal / ward / mend FX + wild-magic misfire rule; reusable by any caster, hero or monster.

## Monsters
scripts/bestiary.gd (21 creatures, 8 strains, 8 canon lords, depth bands, home themes, ways in a fight, boss bag), scripts/monster.gd (any creature or
lord: real-height scaling, anim maps, UAL graft for unanimated Quaternius-rig bodies, arms, strain tint, boss trappings).
Models: addons/kaykit_character_pack_skeletons, addons/quaternius_monsters (Slime, Bat, Skeleton, Dragon),
assets/monsters (Rat, Spider, Frog, Snake, Snake_Angry, Wasp, Imp, Puglin, UAL1/UAL2 animation libraries).
L1 creatures reuse owned CC0 bodies: bone bowman (Skeleton_Minion + KayKit Skeleton_Crossbow), bone sentinel
(Skeleton_Warrior + Skeleton_Blade + Skeleton_Shield_Large_A), gravecaller (Skeleton_Mage + Skeleton_Staff), lost delver
(KayKit Knight / Barbarian / Rogue_Hooded, pale), grave-whelp (Quaternius Dragon, small), slimeling (Quaternius Slime, small).
Library copies: village_assets/library/monsters.

## Dungeon
addons/kaykit_dungeon_remastered (203 modular pieces), assets/dungeon (20 Quaternius pieces), scripts/dungeon_parts.gd
(lava pool, spike / pressure / fire traps, portcullis, prison cell, debris, scar-glass, lit torch), assets/shaders/lava.gdshader.
Catalogue: tools/_dungeon_cat.gd. Library: village_assets/library/dungeon.

## Dungeon floors
scripts/floorgen.gd (old FloorGen, ported verbatim), scripts/dungeon_hd.gd + Dungeon.tscn (HD floor: pieces + monsters +
lords), addons/hexkit (nature decorations used by biomes). Probe: tools/_floors.gd.

## Dungeon look (L28, laptop 2026-11-12)
assets/shaders/dungeon_kit.gdshader: the surface every KayKit Dungeon Remastered piece gets on a floor (FloorGen._skin).
All 203 kit pieces share one atlas (Assets/texture/dungeon_texture.png; the per-piece copies are byte-identical), so a
floor uses one material per theme / tint / steel flag. Detail textures are the Quaternius Medieval Village MegaKit set
already in assets/kit/textures (CC0, Quaternius - NOT the Bestiary/QAL packs): T_Plaster_Normal + T_Plaster_ORM (stone
grain), T_WoodTrim_Normal + T_WoodTrim_Roughness (wood grain), T_Noise_Terrain (slow tiling breakup). Read-only use - the
town's .tres materials are untouched. The 8x4 per-swatch roughness / metal map is generated in code (FloorGen._pbr_map).
LICENSE: KayKit Dungeon Remastered CC0 (addons/kaykit_dungeon_remastered/Assets/LICENSE.txt); MegaKit textures CC0.

## Heroes + chat
scripts/roster.gd, scripts/chatcmd.gd (old game, verbatim), scripts/hero_body.gd (hero body: class/tier/rank look,
errands), town.gd chat_line()/feed. Fake-chat test: tools/_heroes.gd.

- scripts/delve.gd - the delve: party into the scar, floors, fights, lords, retreat, chronicle (Cycle 33)
- tools/_delve_test.gd, tools/_delve_render.gd - headless run / two-shot render
- scripts/feed_hud.gd - FeedHUD: parchment chronicle, last 6 feed lines (Cycle 34)
- tools/_return.gd - render: party climbs out of the scar and walks home
- scripts/economy.gd - Economy: valley stock + production, ported from old sim.gd (Cycle 35)
- tools/_stock.gd, tools/_persist.gd - stock-pile render / roster save round trip
- tools/_caravan_shot.gd - render: caravan on the west road / at the market, apothecary shelf (Cycle 36)
- scripts/raids.gd - Raids: raids, defence, breach/ruin, rebuild; ported from the old town (Cycle 37)
- tools/_raid_test.gd, tools/_raid_shot.gd - headless raid test / gate + ruin + rebuild render
- tools/_ten_days.gd, tools/_raid_dbg.gd, tools/_settler_shot.gd - 10-day valley run / raid debug / settler render (Cycle 38)
- scripts/adventurers.gd - Adventurers: the town's own band, musters, kit-up, delves (Cycle 39)
- tools/_adv_dbg.gd, tools/_band_shot.gd - muster debug / band at the scar mouth render
- scripts/daylight.gd - Daylight: sun/moon, sky, lamps and windows follow the old clock (Cycle 40)
- tools/_delve_pace.gd, tools/_clock_shot.gd - delve pace probe / noon-dusk-night render
- tools/_stream_soak.gd, tools/_viewer_dbg.gd, tools/_fps_window.gd, tools/_soak_shots.gd - full soak / viewer trace / FPS / night raid + dawn renders (Cycle 41)
- tools/_lamp_shot.gd, tools/_rack_shot.gd - wizard's lamp-stand lit / shop rack before-after a tier unlock (Cycle 43)

## Characters, 2.0 (L6, laptop 2026-11-11)
assets/characters/kaykit_adv2: KayKit Adventurers 2.0 FREE (CC0, Kay Lousberg; LICENSE.txt + SOURCE.txt) - Knight,
Barbarian, Mage, Ranger (new), Rogue, Rogue_Hooded on Rig_Medium, plus its free animations (General, MovementBasic).
tools/_bake_adv2.gd bakes adv2_anims.res (76 animations of the 1.0 set re-pathed Rig -> Rig_Medium, same bones and
rest poses, with 2.0's own idle/walk/run/hit/death/jump laid over) and hero_<Name>.tscn = the body + an
AnimationPlayer on that library. Load like any KayKit body: from the 1.0 folder the path is
"../../../../assets/characters/kaykit_adv2/hero_<Name>.tscn" (Roster.ADV2). Heroes use them now; townsfolk could too.
