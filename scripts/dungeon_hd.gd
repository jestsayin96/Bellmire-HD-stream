class_name DungeonHD
extends Node3D
## One dungeon floor, HD. FloorGen (ported verbatim) lays the rooms, corridors,
## theme/biome dressing, lava pools and lighting from the KayKit kit; this
## adds the Phase C pieces (traps, cells, portcullis, debris, scar-glass) by
## theme, then peoples it from the Bestiary by depth band, and on a boss floor
## raises a lord. Canon: the floor number is used, a floor COUNT never is.

@export var floor_no := 1
var info: Dictionary = {}
var monsters: Array = []
var lord: Monster = null
var _rng := RandomNumberGenerator.new()
## test hook: a roll below Bestiary.UNIQUE_CHANCE forces a unique (negative = roll)
static var force_unique := -1.0

## HD: Fantasy Props MegaKit pieces by theme, [asset, obstacle radius]. Each
## stands on its own open cell and is registered as an obstacle like the rest.
const MKPROPS := "res://assets/props/"
const MK_SCALE := 1.45
const THEME_PROPS := {
    "prison":   [["Chain_Coil", 0.6], ["Cage_Small", 0.9], ["Chain_Coil", 0.6]],
    "crypt":    [["CandleStick_Stand", 0.5], ["CandleStick_Stand", 0.5], ["Cage_Small", 0.9]],
    "shrine":   [["CandleStick_Stand", 0.5], ["CandleStick_Stand", 0.5], ["BookStand", 0.6]],
    "keep":     [["Bookcase_2", 1.1], ["CandleStick_Stand", 0.5]],
    "treasury": [["Bookcase_2", 1.1], ["Chain_Coil", 0.6]],
    "workshop": [["Bookcase_2", 1.1], ["Chain_Coil", 0.6]],
    "barracks": [["Chain_Coil", 0.6], ["CandleStick_Stand", 0.5]],
    "mess":     [["Bookcase_2", 1.1], ["CandleStick_Stand", 0.5]],
}

## S61 / SYSTEM 47 (batch 1 of the 114; S62 adds batch 2 and S63 batch 3, sixteen more floor-standing pieces each): whole-pack dungeon props out of assets/props (94) and
## assets/dungeon (20). Every number below is COPIED from art's measured register,
## renders/art/worldfit/_manifest.json (dirs.<dir>.rows[file].base_dz_m / footprint_m), and
## tools/_s61_props.gd asserts the copy against that file live. base_dz_m IS SIGNED: the lowest
## vertex relative to the pivot - negative sinks (Fence -0.9991), positive floats (Workbench_Drawers
## +0.8842). The correction is ONE formula for both signs: lift = -base_dz_m * scale. A single-sign
## shift would fix the sinkers and bury the floaters. Corridor and lid need no gate: art measured all
## 114 CORRIDOR-SAFE and UNDER-LID. Wall-mounted pieces (banners, wall lantern, wall sword) are
## left for a wall-placement row - stood on the floor they would hang off nothing.
const PROP_BATCH := {
    "res://assets/dungeon/Bag_Coins.glb": [-0.0115, 0.442],   # h 0.1146
    "res://assets/dungeon/Column2.glb": [0.0083, 1.3041],   # h 4.0723
    "res://assets/dungeon/Fence_Straight_Modular.glb": [-0.9991, 2.0],   # h 1.2939  (past 5 cm: SINKS)
    "res://assets/dungeon/Pedestal.glb": [-0.0002, 1.9595],   # h 2.1931
    "res://assets/dungeon/Spikes.glb": [-0.0056, 1.7645],   # h 1.1755
    "res://assets/dungeon/Statue_Horse.glb": [0.0152, 3.3784],   # h 5.8548
    "res://assets/dungeon/Vase.glb": [-0.002, 0.311],   # h 0.3610
    "res://assets/dungeon/Woodfire.glb": [-0.0532, 0.8266],   # h 0.8281  (past 5 cm: SINKS)
    "res://assets/props/Anvil.gltf": [0.0027, 1.0816],   # h 0.5560
    "res://assets/props/Barrel.gltf": [0.0034, 0.698],   # h 0.8980
    "res://assets/props/Bench.gltf": [-0.0073, 2.7767],   # h 0.5332
    "res://assets/props/Cabinet.gltf": [0.0002, 1.3618],   # h 0.9974
    "res://assets/props/Cauldron.gltf": [-0.0028, 0.9891],   # h 0.8155
    "res://assets/props/Crate_Metal.gltf": [0.0026, 0.8659],   # h 0.8679
    "res://assets/props/Crate_Wooden.gltf": [-0.0524, 0.9083],   # h 0.9309  (past 5 cm: SINKS)
    "res://assets/props/Dummy.gltf": [-0.0029, 0.8085],   # h 1.8627
    "res://assets/props/Stool.gltf": [-0.0064, 0.4746],   # h 0.5887
    "res://assets/props/Table_Large.gltf": [0.0013, 2.8485],   # h 0.8134
    "res://assets/props/WeaponStand.gltf": [-0.0034, 1.3862],   # h 1.1093
    "res://assets/props/Workbench_Drawers.gltf": [0.8842, 0.4231],   # h 0.2423  (past 5 cm: FLOATS)
    "res://assets/dungeon/Pedestal2.glb": [0.0152, 1.743],   # h 2.3147  S62 batch 2
    "res://assets/props/Anvil_Log.gltf": [0.0014, 0.9293],   # h 1.0734  S62 batch 2
    "res://assets/props/Barrel_Apples.gltf": [0.0034, 0.698],   # h 0.8980  S62 batch 2
    "res://assets/props/Barrel_Holder.gltf": [-0.0063, 1.3592],   # h 1.2574  S62 batch 2
    "res://assets/props/Bed_Twin1.gltf": [0.0005, 2.4119],   # h 0.8051  S62 batch 2
    "res://assets/props/Bag.gltf": [0.0024, 0.6552],   # h 0.7992  S62 batch 2
    "res://assets/props/Chair_1.gltf": [-0.0027, 0.5805],   # h 1.1233  S62 batch 2
    "res://assets/props/Nightstand_Shelf.gltf": [-0.0062, 0.6933],   # h 1.2156  S62 batch 2
    "res://assets/props/Shelf_Small_Bottles.gltf": [-0.0191, 1.1371],   # h 0.6474  S62 batch 2
    "res://assets/props/Whetstone.gltf": [0.0029, 1.1409],   # h 1.1699  S62 batch 2
    "res://assets/props/Workbench.gltf": [0.0002, 2.0191],   # h 0.8946  S62 batch 2
    "res://assets/props/Vase_2.gltf": [-0.0009, 0.6947],   # h 0.5163  S62 batch 2
    "res://assets/props/Vase_4.gltf": [0.0008, 0.3596],   # h 0.4855  S62 batch 2
    "res://assets/props/FarmCrate_Carrot.gltf": [-0.016, 0.7138],   # h 0.4113  S62 batch 2
    "res://assets/props/Bucket_Metal.gltf": [-0.0052, 0.4854],   # h 0.3650  S62 batch 2
    "res://assets/props/Pot_1_Lid.gltf": [-0.0226, 0.5393],   # h 0.2805  S62 batch 2
    "res://assets/props/Bed_Twin2.gltf": [0.0005, 2.4119],   # h 0.7596  S63 batch 3
    "res://assets/props/Bookcase_2.gltf": [-0.0174, 1.4612],   # h 2.5449  S63 batch 3
    "res://assets/props/BookStand.gltf": [-0.0025, 0.5112],   # h 1.4468  S63 batch 3
    "res://assets/props/Bucket_Wooden_1.gltf": [0.0007, 0.4339],   # h 0.2928  S63 batch 3
    "res://assets/props/Cage_Small.gltf": [-0.0425, 0.8843],   # h 0.8052  S63 batch 3
    "res://assets/props/CandleStick_Stand.gltf": [-0.0079, 0.7323],   # h 1.3125  S63 batch 3
    "res://assets/props/FarmCrate_Apple.gltf": [-0.016, 0.7138],   # h 0.2438  S63 batch 3
    "res://assets/props/FarmCrate_Empty.gltf": [-0.016, 0.7138],   # h 0.2438  S63 batch 3
    "res://assets/props/Pot_1.gltf": [-0.0226, 0.5393],   # h 0.2238  S63 batch 3
    "res://assets/props/Stall_Empty.gltf": [-0.0048, 1.8449],   # h 2.6272  S63 batch 3
    "res://assets/props/Vase_Rubble_Medium.gltf": [0.0032, 0.7969],   # h 0.1746  S63 batch 3
    "res://assets/props/Chain_Coil.gltf": [0.0047, 1.0703],   # h 0.0872  S63 batch 3
    "res://assets/dungeon/Skull.glb": [-0.0318, 0.6006],   # h 0.4610  S63 batch 3
    "res://assets/props/BookGroup_Medium_1.gltf": [-0.0038, 1.0626],   # h 0.2983  S63 batch 3
    "res://assets/props/Coin_Pile_2.gltf": [0.0003, 0.2787],   # h 0.0584  S63 batch 3
    "res://assets/props/Carrot.gltf": [-0.2378, 0.222],   # h 0.5658  (past 5 cm: SINKS)  S63 batch 3
}
const THEME_BATCH := {
    "prison": ["res://assets/dungeon/Fence_Straight_Modular.glb", "res://assets/dungeon/Spikes.glb", "res://assets/props/Bucket_Metal.gltf", "res://assets/props/Cage_Small.gltf", "res://assets/props/Chain_Coil.gltf"],
    "crypt": ["res://assets/dungeon/Vase.glb", "res://assets/dungeon/Pedestal.glb", "res://assets/props/Vase_2.gltf", "res://assets/dungeon/Pedestal2.glb", "res://assets/props/CandleStick_Stand.gltf"],
    "shrine": ["res://assets/dungeon/Column2.glb", "res://assets/dungeon/Pedestal.glb", "res://assets/props/Vase_4.gltf", "res://assets/props/Shelf_Small_Bottles.gltf", "res://assets/props/BookStand.gltf"],
    "keep": ["res://assets/props/Cabinet.gltf", "res://assets/props/Bench.gltf", "res://assets/dungeon/Statue_Horse.glb", "res://assets/props/Chair_1.gltf", "res://assets/props/Nightstand_Shelf.gltf", "res://assets/props/Bookcase_2.gltf", "res://assets/props/BookGroup_Medium_1.gltf"],
    "treasury": ["res://assets/dungeon/Bag_Coins.glb", "res://assets/props/Crate_Metal.gltf", "res://assets/props/Barrel.gltf", "res://assets/props/Bag.gltf", "res://assets/props/Coin_Pile_2.gltf"],
    "workshop": ["res://assets/props/Anvil.gltf", "res://assets/props/Workbench_Drawers.gltf", "res://assets/props/Crate_Wooden.gltf", "res://assets/props/Cauldron.gltf", "res://assets/props/Whetstone.gltf", "res://assets/props/FarmCrate_Empty.gltf"],
    "barracks": ["res://assets/props/WeaponStand.gltf", "res://assets/props/Dummy.gltf", "res://assets/dungeon/Woodfire.glb", "res://assets/props/Bed_Twin1.gltf", "res://assets/props/Barrel_Holder.gltf", "res://assets/props/Bed_Twin2.gltf"],
    "mess": ["res://assets/props/Table_Large.gltf", "res://assets/props/Stool.gltf", "res://assets/props/Barrel.gltf", "res://assets/props/Pot_1_Lid.gltf", "res://assets/props/Barrel_Apples.gltf", "res://assets/props/Pot_1.gltf"],
    # the six biomes (FloorGen.BIOMES) draw from the same twenty
    "grassland": ["res://assets/props/Barrel.gltf", "res://assets/props/Crate_Wooden.gltf", "res://assets/props/FarmCrate_Carrot.gltf", "res://assets/props/FarmCrate_Apple.gltf"],
    "confection": ["res://assets/props/Cauldron.gltf", "res://assets/props/Barrel.gltf", "res://assets/props/Barrel_Apples.gltf", "res://assets/props/Stall_Empty.gltf"],
    "flooded": ["res://assets/dungeon/Vase.glb", "res://assets/dungeon/Column2.glb", "res://assets/props/Bucket_Metal.gltf", "res://assets/dungeon/Skull.glb"],
    "firepit": ["res://assets/dungeon/Woodfire.glb", "res://assets/props/Anvil.gltf", "res://assets/props/Anvil_Log.gltf", "res://assets/props/Carrot.gltf"],
    "wood": ["res://assets/props/Crate_Wooden.gltf", "res://assets/props/Stool.gltf", "res://assets/props/Workbench.gltf", "res://assets/props/Bucket_Wooden_1.gltf"],
    "fogbound": ["res://assets/dungeon/Column2.glb", "res://assets/dungeon/Vase.glb", "res://assets/props/Vase_2.gltf", "res://assets/props/Vase_Rubble_Medium.gltf"],
}

## the scale a batch piece stands at: the MegaKit props at MK_SCALE like the rest of them, the
## Quaternius dungeon pieces at 1.0 as DungeonParts.kit draws them
static var batch_red_single_sign := false
static func batch_scale(path: String) -> float:
    return MK_SCALE if path.begins_with(MKPROPS) else 1.0

## a pack piece set down on its own base: the model sits in a holder lifted by -base_dz * scale, so
## the holder's origin is the floor and the lowest vertex lands on it, whichever side of the pivot
## it started. null if the file is gone (never an unguarded instantiate).
static func batch_piece(path: String) -> Node3D:
    if not PROP_BATCH.has(path) or not ResourceLoader.exists(path):
        return null
    var ps := load(path) as PackedScene
    if ps == null:
        return null
    var s := batch_scale(path)
    var holder := Node3D.new()
    holder.name = "Batch_" + path.get_file().get_basename()
    var n: Node3D = ps.instantiate()
    n.scale = Vector3.ONE * s
    var dz := float(PROP_BATCH[path][0])
    # test hook (S61_RED): the single-sign shift row 1 warned about - lifts every piece by |dz|
    n.position.y = (absf(dz) if batch_red_single_sign else -dz) * s
    holder.add_child(n)
    holder.set_meta("batch_path", path)
    return holder

## obstacle radius from art's footprint (its widest horizontal extent), at the drawn scale
static func batch_radius(path: String) -> float:
    return float(PROP_BATCH[path][1]) * batch_scale(path) * 0.5 + 0.1
func _mk(nm: String) -> Node3D:
    var path := MKPROPS + nm + ".gltf"
    if not ResourceLoader.exists(path):
        return null
    var n: Node3D = (load(path) as PackedScene).instantiate()
    n.scale = Vector3.ONE * MK_SCALE
    if nm == "CandleStick_Stand":
        var l := OmniLight3D.new()
        l.light_color = Color(1.0, 0.72, 0.42)
        l.light_energy = 0.7
        l.omni_range = 4.5
        l.position = Vector3(0, 1.3, 0)
        n.add_child(l)
    return n

func _ready() -> void:
    if info.is_empty():
        build(floor_no)

## L28b: the air of this floor for a camera looking into it (FloorGen.make_env, by theme,
## made once each: full for the director's camera, cheap - no SSAO - for the lane panes)
var _env := {}
func env(cheap := false) -> Environment:
    if not FloorGen.kit_look or info.is_empty():
        return null
    if not _env.has(cheap):
        _env[cheap] = FloorGen.make_env(String(info.get("theme", "")), global_position.y, bool(info.get("boss", false)), cheap)
    return _env[cheap]

## the floor a camera at p is looking into (any floor in the tree whose grid is under p),
## or null in the open air - cameras call this to swap the town's sky for the floor's air
static func env_at(tree: SceneTree, p: Vector3, cheap := false) -> Environment:
    if tree == null or p.y > -150.0:
        return null
    var best: DungeonHD = null
    var bd := 1.0e9
    for n in tree.get_nodes_in_group("dungeon_floor"):
        var d: DungeonHD = n
        var dd := Vector2(p.x - d.global_position.x, p.z - d.global_position.z).length()
        if dd < bd:
            bd = dd
            best = d
    return best.env(cheap) if best and bd < 200.0 else null

func build(n: int) -> void:
    floor_no = n
    add_to_group("dungeon_floor")
    _env = {}
    for c in get_children():
        c.queue_free()
    monsters.clear()
    _reach = {}
    _rng.seed = hash("hd:%d" % n)
    info = FloorGen.build(self, n, Vector3.ZERO)
    _dress()
    _people()
    _atmos()
    _decals()

## ---------------------------------------------------------------- L28d: detail decals
## self-made textures (tools/_l28_decals.gd -> assets/dungeon_look, CC0) projected on floor
## cells and wall bases to break the tile repetition: cracks everywhere, moss / soot / blood by
## theme, scar-glass veins once the floors run deep. Never on the stairs or the keep-clear
## route (info["keep_clear"]: the way through + every corridor). Capped per floor.
const DECAL_CAP := 24
var _vein_at: Array = []               # L37: vein positions placed on this floor
const DECAL_TEX := "res://assets/dungeon_look/decal_%s.png"
## miniboss_feed: theme -> the art lane's miniboss key (docs/art/MINIBOSSES.md, one per
## floorgen theme). The key picks the feed lines in data/lore_lines.json miniboss_feed.
const THEME_MINIBOSS := {"barracks": "drillmaster", "workshop": "scrapwright", "prison": "gaoler",
    "shrine": "snuffer", "crypt": "sexton", "keep": "porter", "treasury": "tallyman", "mess": "cook",
    "flooded": "sluicekeeper", "grassland": "sower", "wood": "snarer", "firepit": "stoker",
    "fogbound": "bellman", "confection": "boiler"}
## S32: more art-lane bodies for a theme. A candidate only enters the draw once it has BOTH a
## loadable body (Delve.miniboss_model) AND content's arrive lines (Delve.miniboss_lines) - without
## lines delve drops the key and spawns a nameless theme creature, so an unwritten candidate must
## never displace the one that works. The base THEME_MINIBOSS key always stays in the draw.
## The draw is hashed off the floor number, NOT _rng, so adding a candidate does not shift the
## floor's own random stream (layout, purses, decals stay as they were).
## S33: every art body now has its theme's row. Theme per key is ART'S OWN TAG - field 5 of the
## tuple in tools/art/minibosses.py ("the dungeon_hd.gd theme whose miniboss weight this was built
## for"), read, not guessed. Sixteen bodies had a fit ratio here and lines in content's file and
## were in NO draw, so they never stood on a floor. `leech` is listed and stays out on its own until
## content writes its arrive lines - the gate in miniboss_for, not this table, decides.
## S35: `beadle` (33rd, art's tag shrine) is listed the same way and is held out until content writes it.
## S38: `rammer` (34th, art's tag flooded) joins the flooded row; content's C-115 lines are in.
## S48: `fuller` (35th, art's tag fogbound) joins fogbound; content's C-126 lines are in. `stackman`
## (36th, art's tag grassland) is listed and held out by the gate until content writes it.
## S65: `dauber` (37th, Wetwall, art's tag keep - field 5 of its CANON tuple) joins keep; content's C-142 lines are in.
## S69: `scraper` (41st, Scourstone, art's tag crypt - field 5) joins crypt; content's feed row has since landed (by_key.scraper arrive 9 / fall 8), so miniboss_for draws it (S91, measured).
## S71: `ferryman` (42nd, Slackwater, art's tag flooded - field 5) joins flooded; content's feed row has since landed (by_key.ferryman arrive 9 / fall 8), so miniboss_for draws it (S91, measured).
## S72: content's C-149 ferryman lines are in (9 arrive / 8 fall), so the gate now lets it into the flooded draw.
## S73: `winder` (43rd, Haulback in art's CANON, art's tag wood - field 5) joins wood; content's C-151 lines landed and S75 added its MB_NAME row, so it now enters the wood draw.
## S76: `pitman` (44th, Underfoot in art's CANON, art's tag crypt - field 5) joins crypt; content's C-152 lines (9 arrive / 8 fall) and its MB_NAME row land together, so it enters the crypt draw now.
## S89: `tither` (45th, Tenthpart in art's CANON, art's tag prison - field 5) joins prison; content's C-167 landed by_key.tither (arrive 9 / act 7 / broken 4 / fall 8), so miniboss_for draws it (S91, measured).
## S93: `blower` (46th, Deadair in art's CANON, art's tag fogbound - field 5) joins fogbound with MB_FIT 1.01; content's C-169 lines have NOT landed (by_key.blower absent), so miniboss_for correctly holds it out until they do. S94: C-169 landed (by_key.blower 9 arrive / 8 fall) and its MB_NAME row is written, so it enters the fogbound draw now.
## S98: `changer` (47th, Evenhand in art's CANON, art's tag treasury - field 5) joins treasury with MB_FIT 1.11; content's by_key.changer has NOT landed, so miniboss_for correctly holds it out and NO MB_NAME row is written (tools/_s51_names.gd requires every MB_NAME key in by_key). When it lands the row is one line: "changer": "Evenhand".
## S101: `stopper` (48th, Chokewell, art's tag crypt - field 5) joins crypt with MB_FIT 0.97. Content's C-176 landed, but stopper.glb is on NO branch: miniboss_model returns "" so miniboss_for holds it out, and NO MB_NAME row is written because tools/_s51_names.gd requires every MB_NAME key to have a .glb stem. When the mesh lands the row is one line: "stopper": "Chokewell".
## S101: `roper` (49th, Drawtight, art's tag grassland - field 5) joins grassland with MB_FIT 1.0; no feed row yet, so NO MB_NAME row and the arrive-lines half of the gate holds it out.
## S107: `almoner` (50th, Dolehand, art's tag shrine - field 5) joins shrine with MB_FIT 1.03; content's C-182 by_key.almoner landed and almoner.glb.import is committed alongside, so miniboss_for can draw it.
## S113: `nightman` (53rd, Nightwork, art's tag prison - field 5) joins prison with MB_FIT 0.94; content's C-190 by_key.nightman landed (9/7/4/8) and nightman.glb.import is committed alongside, so miniboss_for can draw it.
## S115: `iceman` (54th, Hoarback, art's tag mess - field 5) joins mess with MB_FIT 1.27; content's by_key.iceman has NOT landed, so miniboss_for correctly holds it out and NO MB_NAME row is written (tools/_s51_names.gd requires every MB_NAME key in by_key). When C-lines land the row is one line: "iceman": "Hoarback", and _s51_names.gd:64 / _s107_gate.gd:43 move 53 -> 54 with it.
const THEME_MINIBOSS_MORE := {
    "barracks": ["quartermaster", "relief"], "workshop": ["jointer", "greener", "dyer"],
    "prison": ["pressman", "tither", "nightman"], "shrine": ["leech", "beadle", "almoner"], "crypt": ["ratcatcher", "scraper", "pitman", "stopper"],
    "keep": ["reeve", "paviser", "dauber"], "treasury": ["strickler", "sealer", "changer"], "mess": ["loader", "hooper", "iceman"],
    "flooded": ["tanner", "rammer", "ferryman"], "grassland": ["hurdleman", "stackman", "roper"], "wood": ["drover", "winder"],
    "firepit": ["moulder", "tapster"], "fogbound": ["fenman", "fuller", "blower", "stiltman"], "confection": ["comfitmaker", "panner"]}
static func miniboss_for(theme: String, n: int) -> String:
    var base := String(THEME_MINIBOSS.get(theme, ""))
    if base == "":
        return ""
    var pool: Array = [base]
    for k in THEME_MINIBOSS_MORE.get(theme, []):
        var key := String(k)
        if Delve.miniboss_model(key) != "" and not Delve.miniboss_lines(key, "arrive").is_empty():
            pool.append(key)
    return String(pool[absi(hash("mb:%s:%d" % [theme, n])) % pool.size()])
const THEME_DECAL := {"wood": "moss", "grassland": "moss", "flooded": "moss",
    "firepit": "soot", "workshop": "soot", "prison": "blood", "barracks": "blood", "crypt": "blood"}
const SCAR_VEIN := Color(0.62, 0.32, 1.0)
## L37: no two scar-veins within this many metres - adjacent decals joining edge to edge is
## what made them read as continuous neon piping instead of separate cracks
const VEIN_APART := 9.0
static var _dtex := {}
var decals := 0

static func _decal_tex(kind: String) -> Texture2D:
    if not _dtex.has(kind):
        var p := DECAL_TEX % kind
        _dtex[kind] = load(p) if ResourceLoader.exists(p) else null
    return _dtex[kind]

func _decals() -> void:
    decals = 0
    if not FloorGen.kit_look:
        return
    var cells: Dictionary = info["cells"]
    var keep: Dictionary = info.get("keep_clear", {})
    var G: float = info["grid"]
    var hw: float = (float(info["w"]) - 1.0) * G * 0.5
    var hh: float = (float(info["h"]) - 1.0) * G * 0.5
    var stair_cells := {}
    for k in ["entry", "exit"]:
        var sp: Vector3 = info[k]
        stair_cells[Vector2i(int(round((sp.x + hw) / G)), int(round((sp.z + hh) / G)))] = true
    var cand: Array = []
    for c in cells:
        if not keep.has(c) and not stair_cells.has(c):
            cand.append(c)
    var r := RandomNumberGenerator.new()
    r.seed = hash("decal:%d" % floor_no)
    for i in range(cand.size() - 1, 0, -1):
        var j := r.randi_range(0, i)
        var t = cand[i]; cand[i] = cand[j]; cand[j] = t
    # the floor's mix: its theme's own mark, cracks, and veins that grow with depth
    var plan: Array = []
    var tk := String(THEME_DECAL.get(String(info.get("theme", "")), ""))
    for i in (9 if tk != "" else 0):
        plan.append(tk)
    # L37 (Mr. E, 19:27 recording): the veins read as "bright purple/cyan neon spaghetti looping
    # across the floor rather than cracks in stone". L42 already cut their emission hard (2.4 ->
    # 1.1); this is the other half of the item - COVERAGE and the continuous curves.
    # Count halved and capped at 3 a floor (was up to 6). Below, each vein is also drawn much
    # smaller, kept off the walls, and spaced away from its neighbours - because what made it
    # read as piping was several big curvy decals meeting edge to edge.
    var veins := 0 if floor_no < 6 else mini(int((floor_no - 4) / 2), 3)
    for i in veins:
        plan.append("veins")
    while plan.size() < DECAL_CAP - 6:
        plan.append("crack")
    for i in range(plan.size() - 1, 0, -1):
        var j2 := r.randi_range(0, i)
        var t2 = plan[i]; plan[i] = plan[j2]; plan[j2] = t2
    var sides := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
    var root: Node3D = info["root"]
    var ci := 0
    _vein_at.clear()                       # L37: per-floor record of where veins already sit
    for kind in plan:
        if decals >= DECAL_CAP or ci >= cand.size():
            break
        var c: Vector2i = cand[ci]
        ci += 1
        var tex := _decal_tex(String(kind))
        if tex == null:
            continue
        var d := Decal.new()
        d.name = "Decal_" + String(kind)
        d.texture_albedo = tex
        var base := _cell_pos(c)
        var walls: Array = []
        for s in sides:
            if not cells.has(c + (s as Vector2i)):
                walls.append(s)
        # L37: a vein must never be projected up a wall face - that is what turned a crack in
        # the floor into piping running up the stonework. Veins stay flat on the ground.
        if String(kind) == "veins":
            var too_near := false
            for p in _vein_at:
                if base.distance_to(p as Vector3) < VEIN_APART:
                    too_near = true
                    break
            if too_near:
                continue                       # L37: never two veins close enough to join up
            _vein_at.append(base)
        if not walls.is_empty() and kind != "blood" and String(kind) != "veins" and r.randf() < 0.45:
            # the foot of a wall: projected sideways into the wall face, fading off the floor
            var sv: Vector2i = walls[r.randi() % walls.size()]
            var dir := Vector3(sv.x, 0, sv.y)
            var y_ax := -dir
            var z_ax := Vector3.UP
            d.transform = Transform3D(Basis(y_ax.cross(z_ax), y_ax, z_ax),
                base + dir * (G * 0.5 - FloorGen.WALL_IN) + Vector3(r.randf_range(-0.9, 0.9) * absf(dir.z), 0.75,
                    r.randf_range(-0.9, 0.9) * absf(dir.x)))
            d.size = Vector3(r.randf_range(2.6, 3.6), 0.9, 1.8)
            d.normal_fade = 0.5
        else:
            # L37: a vein is drawn roughly half size, so it reads as a crack in a flagstone
            # rather than a curve sprawling across several of them
            var s2 := r.randf_range(2.6, 3.8) * (0.85 if kind == "blood" else 1.0) \
                * (0.5 if String(kind) == "veins" else 1.0)
            d.position = base + Vector3(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 1.0))
            d.rotation.y = r.randf() * TAU
            d.size = Vector3(s2, 0.7, s2)
            d.normal_fade = 0.35
        d.upper_fade = 0.2
        d.lower_fade = 0.2
        match String(kind):
            "veins":
                # L37: "keep them as a subtle tell". The violet is held but no longer at full
                # strength - a scar-vein should be something a viewer notices on a deep floor,
                # not the brightest thing in the room.
                d.modulate = Color(SCAR_VEIN.r, SCAR_VEIN.g, SCAR_VEIN.b, 0.62)
                d.texture_emission = _decal_tex("veins_glow")
                d.emission_energy = 0.75         # L42 took this from 2.4 to 1.1; L37 finishes the job
            "crack":
                d.modulate = Color(1, 1, 1, 0.85)
            "soot":
                d.modulate = Color(1, 1, 1, 0.9)
        d.distance_fade_enabled = true
        d.distance_fade_begin = 70.0
        d.distance_fade_length = 20.0
        root.add_child(d)
        decals += 1
    print("L28D_DECALS floor %d %s: %d (cap %d)" % [floor_no, String(info.get("theme", "")), decals, DECAL_CAP])

## ---------------------------------------------------------------- L28c: light and fire
## hard cap on particle emitters a floor's dressing may run (motes, the shared flame embers,
## trap fire, the lord's ash...); creatures' own emitters are counted apart
const EMITTER_CAP := 12
var emitters := 0

## the boss floor's drama (a coloured shadowed spot on the lord, ash or embers round it),
## the one shared ember emitter for every flame on the floor, then the emitter count + cap
func _atmos() -> void:
    var root: Node3D = info["root"]
    if FloorGen.kit_look:
        var L := FloorGen.look(String(info.get("theme", "")))
        var hh: Vector2 = info["half"]
        if bool(info.get("boss", false)) and lord:
            var bc := Color(String(L.get("boss", "#ff4030")))
            var at: Vector3 = lord.position
            var s := SpotLight3D.new()
            s.name = "LordLight"
            var pos := at + Vector3(1.6, 6.0, 1.2)
            s.transform = Transform3D(Basis.looking_at(at - pos, Vector3.UP), pos)
            s.light_color = bc
            s.light_energy = 16.0
            s.spot_range = 12.0
            s.spot_angle = 26.0
            s.spot_angle_attenuation = 0.8
            s.shadow_enabled = true
            s.shadow_blur = 1.2
            root.add_child(s)
            var glow := OmniLight3D.new()          # an under-glow that tints the lord's dais
            glow.light_color = bc
            glow.light_energy = 2.2
            glow.omni_range = 6.0
            glow.shadow_enabled = false
            glow.position = at + Vector3(0, 0.4, 0)
            root.add_child(glow)
            var ash := DungeonParts.embers(bc.lerp(Color(1, 1, 1), 0.25), 48, 2.2, 3.2)
            ash.name = "Embers_lord"
            ash.position = at + Vector3(0, 0.1, 0)
            root.add_child(ash)
        var flames: Array = (info.get("flames", []) as Array).duplicate()
        flames.append_array(info.get("brazier_flames", []))
        FloorGen.flame_embers(root, flames, info.get("flame_col", Color(1, 0.6, 0.3)), hh.x, hh.y)
    var mine: Array = []
    var theirs := 0
    var lights := [0, 0]
    _tally(root, mine, lights)
    for m in monsters:
        var c: Array = []
        _tally(m, c, [0, 0])
        theirs += c.size()
    if lord:
        var c2: Array = []
        _tally(lord, c2, [0, 0])
        theirs += c2.size()
    # over the cap: decorative emitters go first (the lord's ash, then the motes) - trap fire stays
    for nm in ["Embers_lord", "Motes_"]:
        if mine.size() <= EMITTER_CAP:
            break
        for e in mine.duplicate():
            if String((e as Node).name).begins_with(nm) and mine.size() > EMITTER_CAP:
                mine.erase(e)
                (e as Node).queue_free()
    emitters = mine.size()
    print("L28C_EMITTERS floor %d %s: %d (cap %d), creatures %d; lights %d (shadowed %d)" % [
        floor_no, String(info.get("theme", "")), emitters, EMITTER_CAP, theirs, lights[0], lights[1]])

## the floor's own emitters and lights (a creature's are its own business)
func _tally(n: Node, out: Array, lights: Array) -> void:
    for k in n.get_children():
        if k is Monster:
            continue
        if k is GPUParticles3D:
            out.append(k)
        elif k is Light3D:
            lights[0] += 1
            if (k as Light3D).shadow_enabled:
                lights[1] += 1
        _tally(k, out, lights)

func _cell_pos(c: Vector2i) -> Vector3:
    var G: float = info["grid"]
    var hw: float = (float(info["w"]) - 1.0) * G * 0.5
    var hh: float = (float(info["h"]) - 1.0) * G * 0.5
    return Vector3(float(c.x) * G - hw, 0.0, float(c.y) * G - hh)

## interior cells (all four neighbours open) - safe for a free-standing piece
func _open_cells() -> Array:
    var cells: Dictionary = info["cells"]
    var out: Array = []
    for c in cells:
        var cv: Vector2i = c
        var ok := true
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            if not cells.has(cv + d):
                ok = false
        if ok:
            out.append(cv)
    out.shuffle()
    return out

## L-cycle 111: the floor cells a body can walk to from the entry stairs without crossing
## furniture (a cell whose centre an obstacle covers is not walked through - the same rule
## as Delve._blocked_cells). A creature set down in a pocket walled in by tables never
## reached the fight and the watchdog had to lift it out.
var _reach := {}
func _reachable() -> Dictionary:
    if not _reach.is_empty():
        return _reach
    var cells: Dictionary = info["cells"]
    var clear := func(c: Vector2i) -> bool:
        return _clear_of_props(_cell_pos(c), 0.45)
    var G: float = info["grid"]
    var hw: float = (float(info["w"]) - 1.0) * G * 0.5
    var hh: float = (float(info["h"]) - 1.0) * G * 0.5
    var e: Vector3 = info["entry"]
    var start := Vector2i(int(round((e.x + hw) / G)), int(round((e.z + hh) / G)))
    var q: Array[Vector2i] = [start]
    _reach[start] = true
    while not q.is_empty():
        var c: Vector2i = q.pop_back()
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var n: Vector2i = c + d
            if cells.has(n) and not _reach.has(n) and clear.call(n):
                _reach[n] = true
                q.append(n)
    return _reach

func _in_reach(at: Vector3) -> bool:
    var G: float = info["grid"]
    var hw: float = (float(info["w"]) - 1.0) * G * 0.5
    var hh: float = (float(info["h"]) - 1.0) * G * 0.5
    return _reachable().has(Vector2i(int(round((at.x + hw) / G)), int(round((at.z + hh) / G))))

## a spawn point clear of furniture AND on the floor AND where the party can get to: the
## nearest such floor cell centre (a push out of a table must not cross a wall)
func _out_of_props(at: Vector3) -> Vector3:
    if _clear_of_props(at, 0.6) and _on_floor(at) and _in_reach(at):
        return at
    var best := at
    var bd := 1e9
    for c in info["cells"]:
        var cp := _cell_pos(c)
        if not _clear_of_props(cp, 0.6) or not _reachable().has(c):
            continue
        var dd := cp.distance_to(at)
        if dd < bd:
            bd = dd
            best = cp
    return best

func _on_floor(at: Vector3) -> bool:
    var G: float = info["grid"]
    var hw: float = (float(info["w"]) - 1.0) * G * 0.5
    var hh: float = (float(info["h"]) - 1.0) * G * 0.5
    return (info["cells"] as Dictionary).has(Vector2i(int(round((at.x + hw) / G)), int(round((at.z + hh) / G))))

func _clear_of_props(at: Vector3, r: float) -> bool:
    for o in info.get("obstacles", []):
        if FloorGen.obst_gap(o, at.x, at.z) < r:
            return false
    return true

## pieces that stand up block the way; traps and plates are walked over
func _place_solid(node: Node3D, c: Vector2i, r: float, yaw := 0.0) -> void:
    _place(node, c, yaw)
    (info["obstacles"] as Array).append([_cell_pos(c), r])

## D88: a wall-shaped piece is a BOX obstacle (FloorGen.obst_gap), not a disc - a disc big
## enough to cover a box's corners also blocks the floor beside it, and a disc that fits the
## sides leaves the corners walkable. hx / hz are the half-extents in the piece's own frame.
func _place_box(node: Node3D, c: Vector2i, hx: float, hz: float, yaw := 0.0) -> void:
    _place(node, c, yaw)
    (info["obstacles"] as Array).append([_cell_pos(c), Vector2(hx, hz).length(), hx, hz, yaw])

## D88: where a portcullis may stand. It is a WALL ACROSS A PASSAGE, so the spot is a line of
## floor cells across a corridor or a doorway with stone at BOTH ends, at most three cells wide
## (D91's corridors are three), with floor on both sides of every cell of it - the gate meets two
## walls and divides one side from the other. A free-standing gate in the middle of a room blocks
## nothing even with a perfect obstacle, so if the floor has no such line it gets NO portcullis.
## Lines on the way through (keep_clear) are preferred: it is a trap, and a trap nobody crosses
## may as well not exist (L46). Returns {} or {"cells", "d" (the way through), "at", "span"}.
func _gate_spot(used: Dictionary) -> Dictionary:
    var cells: Dictionary = info["cells"]
    var route: Dictionary = info.get("keep_clear", {})
    var G: float = info["grid"]
    var on_route: Array = []
    var off_route: Array = []
    for c0 in cells:
        var c: Vector2i = c0
        for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
            var p := Vector2i(d.y, d.x)
            if cells.has(c - p):
                continue                      # each line is counted once, from its first cell
            var line: Array = [c]
            while cells.has((line[-1] as Vector2i) + p) and line.size() <= 3:
                line.append((line[-1] as Vector2i) + p)
            if line.size() > 3:
                continue                      # a room, not a passage
            var ok := true
            var at := Vector3.ZERO
            var hit := false
            for lc: Vector2i in line:
                if not cells.has(lc + d) or not cells.has(lc - d) or used.has(lc):
                    ok = false
                    break
                if not _clear_of_props(_cell_pos(lc), 1.5):
                    ok = false
                    break
                at += _cell_pos(lc)
                hit = hit or route.has(lc)
            if not ok:
                continue
            at /= float(line.size())
            if at.distance_to(info["entry"]) < G * 2.5 or at.distance_to(info["exit"]) < G * 2.5:
                continue                      # never on the stairs
            var spot := {"cells": line, "d": d, "at": at, "span": float(line.size()) * G - 1.0}
            (on_route if hit else off_route).append(spot)
    var pool := on_route if not on_route.is_empty() else off_route
    if pool.is_empty():
        return {}
    return pool[_rng.randi() % pool.size()]

func _place(node: Node3D, c: Vector2i, yaw := 0.0) -> void:
    node.position = _cell_pos(c) + Vector3(0, 0.05, 0)
    node.rotation.y = yaw
    (info["root"] as Node3D).add_child(node)

func _dress() -> void:
    var theme := String(info.get("theme", ""))
    var spots := _open_cells()
    var used := {}
    var take := func() -> Vector2i:
        for c in spots:
            var cv: Vector2i = c
            if not used.has(cv) and _clear_of_props(_cell_pos(cv), 2.2):
                for dx in range(-1, 2):
                    for dy in range(-1, 2):
                        used[cv + Vector2i(dx, dy)] = true
                return cv
        return Vector2i(-999, -999)
    # L46 (Mr. E: "traps do no damage"): measured first, and the damage was never the problem -
    # over four floors a delver came within the trigger radius of only 2 of 6 traps, the rest
    # sitting 3.9 to 23.5 m off the line anyone walked. A trap in a corner nobody visits may as
    # well not exist, which is exactly why he never sees one go off. info["keep_clear"] is the
    # way through plus the corridors - where the party actually walks - so traps are now laid ON
    # it by preference and only fall back to any open cell when the route is used up. Props are
    # kept OFF keep_clear; traps are the one thing that belongs on it.
    var route: Dictionary = info.get("keep_clear", {})
    var take_route := func() -> Vector2i:
        for c in spots:
            var cv: Vector2i = c
            if route.has(cv) and not used.has(cv) and _clear_of_props(_cell_pos(cv), 2.2):
                for dx in range(-1, 2):
                    for dy in range(-1, 2):
                        used[cv + Vector2i(dx, dy)] = true
                return cv
        return Vector2i(-999, -999)
    # every floor: a few traps on the open floor, debris in proportion to depth
    # L29c r5: the pool is now eight kinds - the two new ones carry status effects
    # instead of a flat damage spike (poison dart stacks venom; swarm trap lets
    # creatures up through the grate), and both hit the TRAPS dict + the _spring
    # branches in delve.gd. Weighted by inclusion count - the old six each appear
    # once, poison/swarm once each too, so every kind lands at even weight.
    # D88: the portcullis first, so it gets its pick of the passages before the traps take them.
    # It is a TRAP (Mr. E, Nov 15 16:41), hung raised and still; Delve drops it on a crossing.
    # Its obstacle is registered only when it is DOWN (a wall-to-wall box) - raised, its posts
    # stand against the passage walls and nothing blocks the way.
    if theme in ["crypt", "shrine", "treasury"]:
        var gs := _gate_spot(used)
        if not gs.is_empty():
            var span: float = gs["span"]
            var winch := 0 if _rng.randf() < 0.5 else (1 if _rng.randi() % 2 == 0 else -1)
            var pn := DungeonParts.portcullis(span, 4.0, winch)
            var dv: Vector2i = gs["d"]
            # the grid is built across its local x and the way through is its local z
            var yaw := PI * 0.5 if dv.x != 0 else 0.0
            pn.position = (gs["at"] as Vector3) + Vector3(0, 0.05, 0)
            pn.rotation.y = yaw
            (info["root"] as Node3D).add_child(pn)
            for lc: Vector2i in gs["cells"]:
                for dx in range(-1, 2):
                    for dy in range(-1, 2):
                        used[lc + Vector2i(dx, dy)] = true
            # half-width reaches 0.5 m into each wall (kit walls stand 0.5 m into the end cells)
            var gate := {"node": pn, "kind": "Portcullis", "cells": gs["cells"], "d": dv, "at": gs["at"],
                "yaw": yaw, "span": span, "winch": winch, "state": "up",
                "box": [gs["at"], span * 0.5 + 0.6, span * 0.5 + 0.5, 0.45, yaw]}
            if not info.has("gates"):
                info["gates"] = []
            (info["gates"] as Array).append(gate)
            if not info.has("traps"):
                info["traps"] = []
            (info["traps"] as Array).append(gate)
    var traps := [DungeonParts.spike_trap, DungeonParts.pressure_plate, DungeonParts.fire_trap,
                  DungeonParts.dart_trap, DungeonParts.blade_trap, DungeonParts.pit_trap,
                  DungeonParts.poison_dart, DungeonParts.swarm_trap]
    for i in range(1 + mini(floor_no / 3, 3)):
        var c: Vector2i = take_route.call()
        if c.x <= -999:
            c = take.call()
        if c.x > -999:
            var tn: Node3D = (traps[_rng.randi() % traps.size()] as Callable).call()
            _place(tn, c)
            # L9: Delve rolls Perception / DEX saves against these
            if not info.has("traps"):
                info["traps"] = []
            (info["traps"] as Array).append({"node": tn, "kind": String(tn.name)})
    # L49: CHESTS. Something physical to walk to and search - the loot roll already existed but
    # happened invisibly at floor's end, so a viewer never saw anyone find anything. These go on
    # open floor rather than keep_clear: a chest should be a place you go TO, not something you
    # trip over on the way through (that is what the traps are for).
    for i in range(1 + _rng.randi() % 2):
        var cc: Vector2i = take.call()
        if cc.x > -999:
            var ch: Node3D = DungeonParts.chest()
            _place(ch, cc)
            if not info.has("chests"):
                info["chests"] = []
            (info["chests"] as Array).append({"node": ch, "searched": false})
    for i in range(1 + _rng.randi() % 3):
        var c: Vector2i = take.call()
        if c.x > -999:
            _place_solid(DungeonParts.debris(_rng.randi()), c, 1.0, _rng.randf() * TAU)
    # theme pieces
    match theme:
        "prison":
            for i in range(3):
                var c: Vector2i = take.call()
                if c.x > -999:
                    # D88 audit: a 3.0 x 3.0 box, not a 1.9 disc (its corners stood outside the disc)
                    _place_box(DungeonParts.cell(3.0, 3.0, 2.8, i == 0), c, 1.55, 1.55, float(_rng.randi() % 4) * PI * 0.5)
    for spec in THEME_PROPS.get(theme, []):
        var c: Vector2i = take.call()
        if c.x <= -999:
            # crowded floor (a prison's cells): any open cell with room for it
            # (edge cells too - a stand against a wall is no stranger), never on the stairs
            var all_cells: Array = spots + (info["cells"] as Dictionary).keys()
            for sc in all_cells:
                var sv: Vector2i = sc
                var sp := _cell_pos(sv)
                if used.has(sv) or not _clear_of_props(sp, float(spec[1]) + 0.4):
                    continue
                if sp.distance_to(info["entry"]) < 3.0 or sp.distance_to(info["exit"]) < 3.0:
                    continue
                used[sv] = true
                c = sv
                break
        if c.x <= -999:
            continue
        var pn := _mk(String(spec[0]))
        if pn:
            _place_solid(pn, c, float(spec[1]), float(_rng.randi() % 4) * PI * 0.5)
    # S61 / System 47: the batch pieces, each on its own open cell, each set on its own base
    var batch_n := 0
    for bp in THEME_BATCH.get(theme, []):
        var c: Vector2i = take.call()
        if c.x <= -999:
            break
        var bn := batch_piece(String(bp))
        if bn:
            _place_solid(bn, c, batch_radius(String(bp)), float(_rng.randi() % 4) * PI * 0.5)
            batch_n += 1
    info["batch_props"] = batch_n
    # L28c: standing braziers on the open floor - light where the wall torches cannot reach,
    # each flame feeding the floor's shared ember emitter (DungeonHD._atmos)
    if FloorGen.kit_look:
        info["brazier_flames"] = []
        for i in range(2):
            var c: Vector2i = take.call()
            if c.x <= -999:
                break
            var bz := DungeonParts.brazier(info.get("flame_col", Color(1, 0.6, 0.3)), _rng.randi())
            _place_solid(bz, c, 0.6)
            (info["brazier_flames"] as Array).append(bz.position + DungeonParts.BRAZIER_FLAME)
    # wild-magic scarring deepens with depth: scar-glass breaks through the floor
    var scars := 0 if floor_no < 3 else mini((floor_no - 1) / 2, 5)
    for i in range(scars):
        var c: Vector2i = take.call()
        if c.x > -999:
            _place_solid(DungeonParts.scar_glass(_rng.randi(), 5 + _rng.randi() % 6), c, 1.0)

func _people() -> void:
    var spawns: Array = info.get("spawns", [])
    var root: Node3D = info["root"]
    var count := clampi(3 + floor_no / 2, 3, 9)
    # Everything here is in the floor's OWN space (FloorGen spawns, cells and
    # entry are all floor-local). Mixing in the root's world offset cancelled
    # out for a floor at x = 0 and threw every monster 700 m away in a side lane.
    # FloorGen spawns are sized for a party; top up from open interior cells
    var pts: Array = []
    for sp in spawns:
        pts.append(sp if sp is Vector3 else _cell_pos(sp))
    for c in _open_cells():
        if pts.size() >= count:
            break
        pts.append(_cell_pos(c))
    # creatures at home in this floor's theme are likelier (Bestiary.pool_for);
    # a pack animal brings its kind along, and the pack counts toward the floor
    var theme := String(info.get("theme", ""))
    var placed := 0
    var i := 0
    while placed < count and i < pts.size():
        var p: Vector3 = _out_of_props(pts[i])
        i += 1
        var d := Bestiary.pick(floor_no, theme)
        # L50: a pack used to fill as many slots as it liked from ONE pick, so a single rat
        # pack could take a third of a small floor and two picks could all but fill it - which
        # is how a floor came to read as three repeats. A pack still arrives as a pack; it just
        # cannot own more than roughly a third of what is down here.
        var pack_cap := maxi(1, int(round(float(count) * 0.34)))
        var n := 1 + mini(mini(int((d.get("ways", {}) as Dictionary).get("pack", 0)), pack_cap - 1), count - placed - 1)
        for k in range(n):
            var m := Monster.new()
            m.def = d if k == 0 else Bestiary.make(String(d["type"]), String(d["strain"]))
            m.state = Monster.S.PATROL
            m.roam = 3.0
            var off := Vector3.ZERO if k == 0 else Vector3(cos(float(k) * 2.1), 0, sin(float(k) * 2.1)) * 1.1
            var q: Vector3 = p if k == 0 else _out_of_props(p + off)
            m.position = Vector3(q.x, 0.0, q.z)
            root.add_child(m)
            monsters.append(m)
            placed += 1
    # L2: now and then a rare unique holds an ordinary floor the way a lord holds
    # its own (Bestiary.unique_for; never two of the same running)
    var u := {} if bool(info.get("boss", false)) else Bestiary.unique_for(floor_no, force_unique if force_unique >= 0.0 else randf())
    if bool(info.get("boss", false)) or not u.is_empty():
        var b := Bestiary.next_boss(floor_no) if u.is_empty() else {}
        if not b.is_empty() or not u.is_empty():
            lord = Monster.new()
            # L45: the lord is scaled to the depth it is met at - a deep lord is meaningfully
            # harder than a shallow one (uniques already scaled; lords did not)
            lord.def = Bestiary.boss_def(b, floor_no) if u.is_empty() else Bestiary.unique_def(u, floor_no)
            lord.state = Monster.S.IDLE
            # the lord holds the open interior cell farthest from where the party
            # comes in - never the stairs, never a corridor
            var entry: Vector3 = info["entry"]
            var far := Vector3.ZERO
            var fd := -1.0
            for c in _open_cells():
                var cp := _cell_pos(c)
                if not _reachable().has(c) or not _clear_of_props(cp, 0.6):
                    continue        # (a lord in a sealed pocket never comes to the fight)
                var d := cp.distance_to(entry)
                if d > fd:
                    fd = d
                    far = cp
            lord.position = far if fd >= 0.0 else _out_of_props(Vector3.ZERO)
            root.add_child(lord)
            lord.call_deferred("entrance")
    _set_pieces()

## ---------------------------------------------------------------- L29c: set pieces
## A floor is more than a room of monsters. One set piece per non-boss floor, chosen
## from the kinds below, placed on an OPEN interior cell far from the entry so the
## party has to WALK TO it: that is what makes it a set piece rather than another
## spawn. The resolver (delve.gd _setpieces_tick) fires when a hero gets close.
##
## ROUND 3: four kinds of set piece, chosen by weighted roll per floor.
##   AMBUSH   - the hero walks over the trigger and a short pack of theme-matched
##              creatures peels out of the dark RIGHT WHERE THE PARTY STANDS.
##   PRISONER - a captive who was already down here when the floor was made.
##              First hero close enough frees them; they slip a coin pouch to
##              the party before fleeing up the stairs. Prison theme is likelier.
##   SHRINE   - a small altar. First hero to touch rolls a coin flip in the
##              Chronicle: a BOON mends the party; a CURSE takes a bite from each.
##              Shrine / crypt themes are likelier.
##   MINIBOSS - an elite theme creature alone in a chamber, 2x hp and +20% atk.
##              A real fight, not a pack like ambush. Kill it and a bonus purse
##              is split among the party - the Chronicle calls it out by name.
##              Barracks / workshop themes (the drillmaster's kind of floor) lean
##              this way.
## One set piece per floor; a floor can hold only one. The resolver fires when
## any alive hero crosses SETPIECE_TRIGGER_R of the set piece's pos.
##
## Boss floors keep the lord's drama. Floor 1 is clean. Everything else has
## roughly a two-in-three chance.
const SETPIECE_TRIGGER_R := 5.0
const SETPIECE_MIN_FROM_ENTRY := 10.0

func _set_pieces() -> void:
    info["set_pieces"] = []
    if bool(info.get("boss", false)) or floor_no < 2:
        return
    if _rng.randf() > 0.66:
        return
    var cells: Dictionary = info["cells"]
    var entry: Vector3 = info["entry"]
    var exit_p: Vector3 = info["exit"]
    var keep: Dictionary = info.get("keep_clear", {})
    var on_route: Array = []
    var fallback: Array = []
    for c in cells:
        var cv: Vector2i = c
        var cp := _cell_pos(cv)
        if cp.distance_to(entry) < SETPIECE_MIN_FROM_ENTRY:
            continue
        if cp.distance_to(exit_p) < SETPIECE_MIN_FROM_ENTRY * 0.5:
            continue
        if not _clear_of_props(cp, 0.6):
            continue
        if keep.has(cv):
            on_route.append(cp)
        else:
            for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                if keep.has(cv + d):
                    fallback.append(cp)
                    break
    var cand: Array = on_route if not on_route.is_empty() else fallback
    if cand.is_empty():
        return
    var at: Vector3 = cand[_rng.randi() % cand.size()]
    # weighted kind pick - theme tilts the odds a little without changing them
    # all the way (a crypt still rolls an ambush now and then; a prison still
    # gets its shrines)
    var theme := String(info.get("theme", ""))
    # ambush stays the most common because it is the clearest beat on stream; the
    # other three fill the rest in roughly equal shares, and the theme nudges
    # which one gets the extra weight (a prison more prisoners, a barracks more
    # drillmasters, a shrine more altars). A miniboss on floor 2 would be a
    # slog with a starting party - gate it on floor_no >= 4 so the set-piece
    # ladder matches the rest of the dungeon's difficulty curve.
    var weights := {"ambush": 45, "prisoner": 20, "shrine": 20, "miniboss": 15}
    if theme == "prison":
        weights = {"ambush": 30, "prisoner": 40, "shrine": 15, "miniboss": 15}
    elif theme == "shrine" or theme == "crypt":
        weights = {"ambush": 30, "prisoner": 15, "shrine": 45, "miniboss": 10}
    elif theme == "barracks" or theme == "workshop":
        weights = {"ambush": 35, "prisoner": 15, "shrine": 15, "miniboss": 35}
    if floor_no < 4:
        weights.erase("miniboss")
    var total := 0
    for k in weights:
        total += int(weights[k])
    var roll := _rng.randi() % total
    var kind := "ambush"
    var acc := 0
    for k in weights:
        acc += int(weights[k])
        if roll < acc:
            kind = String(k)
            break
    match kind:
        "ambush":
            var pack: Array = []
            var want := 2 + _rng.randi() % 2
            for i in range(want):
                pack.append(Bestiary.pick(floor_no, theme))
            (info["set_pieces"] as Array).append({
                "kind": "ambush", "pos": at, "r": SETPIECE_TRIGGER_R, "resolved": false, "pack": pack,
            })
        "prisoner":
            # purse scales with depth so freeing someone on floor 10 pays better
            # than on floor 2, which is what the Chronicle already does with other
            # per-floor payouts
            var purse: int = 25 + floor_no * 8 + _rng.randi() % 20
            (info["set_pieces"] as Array).append({
                "kind": "prisoner", "pos": at, "r": SETPIECE_TRIGGER_R, "resolved": false, "purse": purse,
            })
        "shrine":
            # seed the flip at build time so the write's own test can inspect
            # the outcome without rolling again at resolve time
            var boon: bool = _rng.randi() % 2 == 0
            (info["set_pieces"] as Array).append({
                "kind": "shrine", "pos": at, "r": SETPIECE_TRIGGER_R, "resolved": false, "boon": boon,
            })
        "miniboss":
            # a theme-matched creature, picked once at build so the Chronicle
            # line can name it before the fight ("A drillmaster holds this
            # chamber alone"). The scaling (2x hp, 1.2x atk) is applied by
            # delve._setpiece_miniboss when it spawns - the def is just the
            # content writer's row.
            var def := Bestiary.pick(floor_no, theme)
            var purse: int = 40 + floor_no * 12 + _rng.randi() % 25
            # the miniboss_feed reader: which of the art lane's fourteen this
            # chamber holds, by theme (MINIBOSSES.md) - delve reads the feed lines by it
            var mb_key := miniboss_for(theme, floor_no)
            (info["set_pieces"] as Array).append({
                "kind": "miniboss", "pos": at, "r": SETPIECE_TRIGGER_R, "resolved": false,
                "def": def, "purse": purse, "mb_key": mb_key,
            })
