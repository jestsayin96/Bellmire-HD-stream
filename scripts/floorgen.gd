## PORTED VERBATIM from the old game (trial-and-error/floorgen.gd, read only) into the HD build.
## It already builds floors from the same KayKit Dungeon Remastered kit (copied to the same res://
## path) and Quaternius hex-kit nature. HD additions live in scripts/dungeon_hd.gd so this stays a
## clean port.
class_name FloorGen

# Builds one dungeon floor.
#
# The kit has 203 pieces - 34 floor variants, 32 wall types, 11 staircases and
# ~120 props. The old version used 17 of them and put the same five objects at
# the same coordinates on every floor, which is why every room looked identical
# and unfinished.
#
# Now each floor picks a THEME and is dressed from that theme's vocabulary with
# CLUSTERS - groups of props that belong together, so a room reads as somewhere
# people lived rather than somewhere objects were scattered. A bed comes with a
# trunk and a guttering candle. A long table comes with stools, plates of food
# and a keg.

const GL := "res://addons/kaykit_dungeon_remastered/Assets/gltf/"
const G := 4.0

# ---------------------------------------------------------------- themes
# `floors` is a weighted bag; `accents` are sprinkled sparsely over it.
const THEMES := {
    "barracks": {
        "name": "a barrack room",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_wood_large"],
        "accents": ["floor_tile_small_broken_A", "floor_tile_small_broken_B"],
        "light": Color(1.0, 0.60, 0.26),
        "banners": ["banner_patternA_red", "banner_patternB_red", "banner_shield_red"],
        "clusters": ["bunk", "armsrack", "footlocker", "mess_small"],
    },
    "mess": {
        "name": "a mess hall",
        "floors": ["floor_wood_large", "floor_wood_large", "floor_tile_large"],
        "accents": ["floor_wood_large_dark", "floor_wood_small_dark"],
        "light": Color(1.0, 0.68, 0.34),
        "banners": ["banner_patternC_yellow", "banner_triple_yellow", "banner_brown"],
        "clusters": ["feast", "feast", "kegs", "shelf_stock"],
    },
    "crypt": {
        "name": "a crypt",
        "floors": ["floor_tile_large", "floor_tile_large_rocks", "floor_dirt_large"],
        "accents": ["floor_tile_small_broken_B", "floor_tile_small_weeds_A",
                    "floor_dirt_small_weeds"],
        "light": Color(0.70, 0.74, 1.00),
        "banners": ["banner_patternB_white", "banner_thin_white"],
        "clusters": ["grave_candles", "collapse", "collapse", "old_arms"],
    },
    "prison": {
        "name": "a prison block",
        "floors": ["floor_tile_large", "floor_tile_grate", "floor_tile_large"],
        "accents": ["floor_tile_big_grate_open", "floor_tile_small_broken_A"],
        "light": Color(0.88, 0.72, 0.50),
        "banners": ["banner_thin_brown", "banner_brown"],
        "clusters": ["cell", "cell", "keyring_post", "collapse"],
    },
    "treasury": {
        "name": "a treasury",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_tile_small"],
        "accents": ["floor_tile_small_broken_A"],
        "light": Color(1.0, 0.82, 0.42),
        "banners": ["banner_patternA_yellow", "banner_triple_yellow", "banner_shield_yellow"],
        "clusters": ["hoard", "hoard", "strongbox", "shelf_stock"],
    },
    "shrine": {
        "name": "a shrine",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_tile_small"],
        "accents": ["floor_tile_small_weeds_B", "floor_tile_small_broken_B"],
        "light": Color(0.96, 0.86, 0.62),
        "banners": ["banner_patternC_white", "banner_triple_white", "banner_white"],
        "clusters": ["altar", "grave_candles", "grave_candles", "old_arms"],
    },
    "workshop": {
        "name": "a workshop",
        "floors": ["floor_tile_large", "floor_wood_large_dark", "floor_tile_large_rocks"],
        "accents": ["floor_tile_small_broken_A", "floor_tile_big_spikes"],
        "light": Color(1.0, 0.56, 0.22),
        "banners": ["banner_patternB_brown", "banner_green"],
        "clusters": ["workbench", "stores", "stores", "kegs"],
    },
    "flooded": {
        "name": "a flooded gallery",
        "floors": ["floor_dirt_large", "floor_dirt_large_rocky", "floor_tile_large_rocks"],
        "accents": ["floor_dirt_small_weeds", "floor_tile_small_weeds_A",
                    "floor_tile_small_broken_B"],
        "light": Color(0.62, 0.84, 0.86),
        "banners": ["banner_thin_green", "banner_patternA_green"],
        "clusters": ["collapse", "overgrowth", "overgrowth", "stores"],
    },
}

# BIOMES. The conceit is that a grand master wizard built this place and
# furnished each floor with somewhere he had been - or somewhere he invented -
# so a descent walks through worlds rather than down a corridor of identical
# cellars.
#
# Everything here is built from the two kits already present. The dungeon kit
# supplies grid-aligned floors; the hex kit supplies free-standing trees, rocks
# and water plants; and TINT does the rest. That is the same trick that got
# five creature strains out of eight models.
#
# Fields on top of the ordinary theme fields:
#   floor_tint / wall_tint  recolour the architecture itself
#   scatter   [asset, chance-per-cell, min-scale, max-scale] laid over the floor
#   prop_tint recolours the scatter, for worlds that are not naturally coloured
const BIOMES := {
    "grassland": {
        "name": "a sunken meadow",
        "floors": ["floor_dirt_small_weeds", "floor_dirt_small_weeds",
                   "floor_tile_small_weeds_A"],
        "accents": ["floor_tile_small_weeds_B", "floor_dirt_small_A"],
        "light": Color(1.0, 0.94, 0.72),
        "floor_tint": Color(0.78, 0.96, 0.66),
        "wall_tint": Color(0.82, 0.90, 0.78),
        "banners": ["banner_patternA_green", "banner_green"],
        "clusters": ["overgrowth", "stores", "collapse"],
        "scatter": [["hex:decoration/nature/trees_A_small", 0.16, 0.7, 1.1],
                    ["hex:decoration/nature/rock_single_A", 0.10, 0.5, 0.9],
                    ["hex:decoration/nature/tree_single_B", 0.08, 0.6, 1.0]],
    },
    "wood": {
        "name": "a buried wood",
        "floors": ["floor_dirt_large", "floor_dirt_large", "floor_dirt_large_rocky"],
        "accents": ["floor_dirt_small_weeds", "floor_dirt_small_C"],
        "light": Color(0.72, 0.92, 0.70),
        "floor_tint": Color(0.70, 0.78, 0.62),
        "wall_tint": Color(0.68, 0.74, 0.64),
        "banners": ["banner_patternB_green", "banner_thin_green"],
        "clusters": ["overgrowth", "overgrowth", "collapse"],
        "scatter": [["trunk_large_A", 0.13, 0.9, 1.4],
                    ["trunk_medium_B", 0.11, 0.9, 1.3],
                    ["hex:decoration/nature/trees_B_medium", 0.14, 0.7, 1.2]],
    },
    "firepit": {
        "name": "the firepits",
        "floors": ["floor_dirt_large_rocky", "floor_dirt_large_rocky",
                   "floor_tile_large_rocks"],
        "accents": ["floor_tile_big_spikes", "floor_dirt_small_B"],
        "light": Color(1.0, 0.44, 0.16),
        "floor_tint": Color(0.52, 0.30, 0.26),
        "wall_tint": Color(0.60, 0.34, 0.28),
        "banners": ["banner_patternA_red", "banner_red"],
        "clusters": ["collapse", "collapse", "old_arms"],
        "scatter": [["rubble_large", 0.14, 0.3, 0.45],
                    ["hex:decoration/nature/rock_single_D", 0.10, 0.6, 1.1]],
        "prop_tint": Color(0.70, 0.38, 0.30),
        # He asked for LAVA PITS and got red-lit rock. Checked it with a
        # --nohud capture rather than trusting the tint names: the firepits
        # were warm stone and nothing more. `pools` cuts actual molten holes
        # in the floor using lava.gdshader, which was already in the project
        # but wired only into dungeon.gd (the player scene), never into the
        # floors the sim builds.
        "pools": 5,
    },
    "fogbound": {
        "name": "the grey halls",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_tile_small"],
        "accents": ["floor_tile_small_broken_A", "floor_tile_small_broken_B"],
        "light": Color(0.70, 0.78, 0.90),
        "floor_tint": Color(0.72, 0.76, 0.82),
        "wall_tint": Color(0.70, 0.74, 0.80),
        "banners": ["banner_thin_white", "banner_white"],
        "clusters": ["collapse", "grave_candles", "old_arms"],
        "scatter": [["pillar", 0.07, 0.9, 1.1],
                    ["rubble_half", 0.09, 0.35, 0.5]],
        "prop_tint": Color(0.74, 0.78, 0.84),
    },
    "confection": {
        "name": "the confection",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_tile_small"],
        "accents": ["floor_tile_small", "floor_tile_small_broken_A"],
        "light": Color(1.0, 0.82, 0.92),
        "floor_tint": Color(1.0, 0.76, 0.86),
        "wall_tint": Color(0.86, 0.94, 1.0),
        "banners": ["banner_patternC_white", "banner_patternA_white"],
        "clusters": ["feast", "feast", "kegs"],
        "scatter": [["barrel_small", 0.10, 0.8, 1.2],
                    ["box_small", 0.06, 0.8, 1.1]],
        "prop_tint": Color(1.0, 0.72, 0.84),
    },
    "keep": {
        "name": "the inner keep",
        "floors": ["floor_tile_large", "floor_tile_large", "floor_wood_large"],
        "accents": ["floor_tile_small_broken_B", "floor_tile_small_corner"],
        "light": Color(1.0, 0.80, 0.46),
        "floor_tint": Color(0.94, 0.92, 0.88),
        "wall_tint": Color(0.96, 0.94, 0.90),
        "banners": ["banner_patternA_blue", "banner_shield_blue", "banner_triple_blue"],
        "clusters": ["armsrack", "old_arms", "shelf_stock", "feast"],
        "scatter": [["pillar_decorated", 0.08, 0.9, 1.1],
                    ["column", 0.06, 0.9, 1.2]],
    },
}

# ---------------------------------------------------------------- clusters
# [asset, dx, dz, rotation, scale]. Props that belong together, placed together.
const CLUSTERS := {
    "bunk": [["bed_decorated", 0, 0, 0, 1], ["trunk_medium_A", 1.7, 0.8, 24, 1],
             ["candle_lit", -1.5, 0.7, 0, 1], ["stool", 1.4, -1.2, 0, 1]],
    "armsrack": [["sword_shield", 0, 0, 0, 1], ["sword_shield_broken", 1.1, 0.4, 35, 1],
                 ["barrel_small", -1.4, 0.3, 0, 1], ["shelf_small", 0.2, 1.3, 0, 1]],
    "footlocker": [["trunk_large_A", 0, 0, 12, 1], ["trunk_small_B", 1.3, 0.5, -20, 1],
                   ["candle_melted", -1.0, 0.6, 0, 1]],
    "mess_small": [["table_small_decorated_A", 0, 0, 0, 1], ["stool", -1.3, 0.2, 0, 1],
                   ["plate_small", 0.1, 0.1, 0, 1], ["bottle_A_green", 0.5, -0.3, 0, 1]],
    "feast": [["table_long_tablecloth_decorated_A", 0, 0, 0, 1],
              ["stool", -1.8, 1.5, 0, 1], ["stool", 0.4, 1.5, 0, 1],
              ["stool", -1.8, -1.5, 0, 1], ["chair", 2.3, 0, 90, 1],
              ["plate_food_A", -0.8, 0.1, 0, 1], ["plate_food_B", 0.8, -0.1, 0, 1],
              ["candle_triple", 0, 0, 0, 1], ["bottle_B_brown", 1.5, 0.3, 0, 1]],
    "kegs": [["keg_decorated", 0, 0, 0, 1], ["keg", 1.3, 0.5, 30, 1],
             ["barrel_large", -1.4, 0.4, 0, 1], ["plate_stack", 0.3, -1.2, 0, 1]],
    "shelf_stock": [["crates_stacked", 0, 0, 0, 1], ["box_small", 1.5, 0.4, 18, 1],
                    ["bottle_A_labeled_brown", -1.2, 0.5, 0, 1],
                    ["bottle_C_green", -0.8, 0.7, 0, 1]],
    "grave_candles": [["candle_thin_lit", 0, 0, 0, 1], ["candle_thin_lit", 0.7, 0.5, 0, 1],
                      ["candle_melted", -0.6, 0.4, 0, 1], ["rubble_half", 1.0, -0.8, 40, 0.5],
                      ["coin_stack_small", -1.2, -0.7, 0, 1]],
    "collapse": [["rubble_large", 0, 0, 0, 0.45], ["rubble_half", 1.0, 0.7, 55, 0.5],
                 ["barrier_half", -1.7, 0.5, 15, 1]],
    "old_arms": [["sword_shield_broken", 0, 0, 20, 1], ["rubble_half", 0.8, 0.6, 0, 0.5],
                 ["banner_shield_white", -1.3, 0.3, 0, 1]],
    "cell": [["barrier_column", 0, 0, 0, 1], ["barrier", 1.6, 0, 0, 1],
             ["barrier_corner", -1.6, 0, 0, 1], ["bed_floor", 0.4, 1.8, 0, 1],
             ["plate_small", -0.6, 1.6, 0, 1]],
    "keyring_post": [["keyring", 0, 0, 0, 1], ["key", 0.8, 0.5, 25, 1],
                     ["stool", -1.2, 0.4, 0, 1], ["candle_lit", 1.0, -0.6, 0, 1]],
    "hoard": [["coin_stack_large", 0, 0, 0, 1], ["coin_stack_medium", 1.1, 0.6, 0, 1],
              ["coin_stack_small", -0.9, 0.7, 0, 1], ["chest_gold", 0.3, -1.4, 15, 1],
              ["coin", 1.6, -0.5, 0, 1]],
    "strongbox": [["chest", 0, 0, 0, 1], ["trunk_large_C", 1.6, 0.5, -15, 1],
                  ["coin_stack_medium", -1.1, 0.4, 0, 1], ["keyring", 0.5, 1.0, 0, 1]],
    # THE WIZARD'S LAMP-STAND. Every floor has one, dead centre. See
    # `build()` for why it is there and what lighting it does.
    "lampstand": [["pillar_decorated", 0, 0, 0, 1],
                  ["candle_triple", 0, 0, 0, 1],
                  ["candle_thin_lit", 0.55, 0.35, 0, 1],
                  ["candle_thin_lit", -0.5, -0.4, 0, 1],
                  ["coin_stack_small", 0.9, -0.8, 0, 1]],
    "altar": [["table_medium_tablecloth", 0, 0, 0, 1], ["candle_triple", -0.8, 0, 0, 1],
              ["candle_triple", 0.8, 0, 0, 1], ["plate_stack", 0, 0.2, 0, 1],
              ["coin_stack_small", 0.2, -0.9, 0, 1]],
    "workbench": [["table_long_broken", 0, 0, 0, 1], ["box_large", 1.9, 0.6, 20, 1],
                  ["crates_stacked", -1.9, 0.5, 0, 1], ["barrel_small_stack", 0.6, -1.5, 0, 1],
                  ["candle_lit", -0.4, 0.2, 0, 1]],
    "stores": [["crates_stacked", 0, 0, 0, 1], ["box_stacked", 1.5, 0.5, 25, 1],
               ["barrel_large", -1.5, 0.4, 0, 1], ["box_small_decorated", 0.4, -1.3, 10, 1]],
    "overgrowth": [["rubble_large", 0, 0, 0, 0.45], ["barrel_large", 1.7, 0.5, 0, 1],
                   ["rubble_half", -1.5, 0.8, 70, 0.5]],
}

# An asset name prefixed "hex:" comes from the HEX kit instead of the dungeon
# kit. That matters for biomes: the dungeon kit has the grid-aligned floors,
# but the hex kit has the trees, rocks and water plants that turn a stone room
# into a sunken meadow. Hex decoration is free-standing, so it drops onto the
# square dungeon grid without needing to line up with anything.
const HEXGL := "res://addons/hexkit/Assets/gltf/"

static func _put(parent: Node3D, asset: String, pos: Vector3, rz := 0.0,
                 sc := 1.0, tint := Color(1, 1, 1)) -> Node3D:
    var path := ""
    if asset.begins_with("hex:"):
        path = HEXGL + asset.substr(4) + ".gltf"
    else:
        # The dungeon kit mixes .gltf.glb and .glb. CHECK before loading:
        # calling load() on a missing path still prints a resource error even
        # when the fallback then succeeds, which buried the console in noise
        # every time a floor built.
        path = GL + asset + ".gltf.glb"
        if not ResourceLoader.exists(path):
            path = GL + asset + ".glb"
    if not ResourceLoader.exists(path):
        push_warning("floorgen: no asset " + asset)
        return null
    var ps: PackedScene = load(path)
    if ps == null:
        return null
    var n: Node3D = ps.instantiate()
    n.position = pos
    n.rotation = Vector3(0, deg_to_rad(rz), 0)
    # The hex kit is authored for a world placed at scale 4, while the dungeon
    # kit is life-size at 1. Dropped in raw, a hex tree arrives a quarter of
    # the size it should be, so it gets the kit's own factor first.
    var k: float = sc * (2.5 if asset.begins_with("hex:") else 1.0)
    n.scale = Vector3(k, k, k)
    parent.add_child(n)
    # L25: what this piece is, for the placement rules and the overlap probe
    n.set_meta("fg_kind", _tag)
    n.set_meta("fg_grp", _grp)
    n.set_meta("fg_asset", asset)
    if _tag in REST_KINDS:
        # rest it ON the floor: a wall-mounted piece (a sword-and-shield plaque, a hanging
        # keyring, a shelf) has its origin at the mount, and set down at y 0 it sank to the hilt
        var lb := _local_box(asset, n)
        var low := lb.position.y * k
        if low < -0.03:
            n.position.y -= low
    if _tag in CHECK_KINDS:
        var bx := _box_of(n, asset)
        if fit_checks and _blocked(bx) > PEN_MAX:
            if not _try_table_top(n, asset, bx):
                n.free()
                return null
            bx = _box_of(n, asset)
        _boxes.append(bx)
    elif _tag in SOLID_KINDS:
        _boxes.append(_box_of(n, asset))
    # Tint is what turns one kit into many worlds - the same trick that made
    # five creature strains out of eight models.
    if tint != Color(1, 1, 1):
        Rig.tint(n, tint)
    return n

## ---- HD: everything that stands on the floor is an OBSTACLE the party and
## the creatures walk around (they used to walk straight through tables).
## [floor-local position, radius]; returned with the floor as info.obstacles.
static var _obs: Array = []
const CLUSTER_R := {"lampstand": 0.9, "hoard": 1.5, "strongbox": 1.3, "cell": 2.0, "feast": 1.9,
                    "collapse": 1.8, "overgrowth": 1.8, "bunk": 1.6, "workbench": 1.8}

static func _free_at(at: Vector3, r: float) -> bool:
    for o in _obs:
        if Vector2(at.x - (o[0] as Vector3).x, at.z - (o[0] as Vector3).z).length() < r + float(o[1]) + 0.4:
            return false
    return true

## L25: a cluster is placed only if its first (anchor) piece fits; the rest go where they fit
static func _cluster(root: Node3D, key: String, at: Vector3, facing: float) -> bool:
    if not CLUSTERS.has(key):
        return false
    _grp += 1
    _tag = "prop"
    var c := cos(deg_to_rad(facing))
    var s := sin(deg_to_rad(facing))
    var first := true
    for item: Array in CLUSTERS[key]:
        # L25: an item that does not fit where the cluster puts it tries closer in, then mirrored
        var got: Node3D = null
        for f in ([1.0] if first else [1.0, 0.7, 0.45]):
            for mir in ([1.0] if first else [1.0, -1.0]):
                var dx: float = float(item[1]) * f * mir
                var dz: float = float(item[2]) * f
                got = _put(root, String(item[0]),
                     at + Vector3(dx * c - dz * s, 0, dx * s + dz * c),
                     facing + float(item[3]) * mir, float(item[4]))
                if got:
                    break
            if got:
                break
        if got == null:
            if first:
                return false          # the caller counts a cluster that never found room
            _rejected += 1
        first = false
    _obs.append([at, float(CLUSTER_R.get(key, 1.5))])
    return true

# Drawn from a shuffled bag rather than picked at random, so a descent never
# meets the same room type twice in a row - picking randomly gave three prison
# blocks in the first six floors.
# Every world the wizard furnished: the original interiors plus the biomes.
static func all_themes() -> Dictionary:
    var out := THEMES.duplicate()
    for k: String in BIOMES:
        out[k] = BIOMES[k]
    return out

static func theme_for(floor_no: int) -> String:
    var order: Array = all_themes().keys()
    var rng := RandomNumberGenerator.new()
    rng.seed = 90210
    for i in range(order.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var t = order[i]; order[i] = order[j]; order[j] = t
    # each pass through the bag is rotated so lap two isn't a repeat of lap one
    var lap: int = int(floor(float(floor_no - 1) / float(order.size())))
    var idx: int = (floor_no - 1 + lap * 3) % order.size()
    return String(order[idx])

# ---------------------------------------------------------------- origins
# WHY THIS DUNGEON EXISTS. Straight from the manual: answer this before you
# draw a single room, because the answer decides the layout and who lives
# there. A biome says what a floor LOOKS like; an origin says what it was
# FOR. Without it a descent is fourteen differently-painted boxes.
#
# The causality is deliberately inverted. The manual picks an origin and lets
# it dictate the layout; here `shape_for` picks the shape first - it already
# guarantees all six shapes inside every six floors, and that variety is worth
# keeping - and the origin is drawn from the origins that could plausibly have
# produced that shape. It reads identically from the floor: a cavern is always
# a lair or a buried town, a cross is always a fortress or a tomb. Variety
# guaranteed, coherence gained, no new randomness.
#
# Same trick as the biomes and the creature strains: recombine what is already
# here rather than download anything.
const ORIGINS := {
    "tomb": {"of": "a tomb", "shapes": ["hall", "cross"],
        "tell": "A ceremonial way runs dead straight to a door meant to stay shut."},
    "mine": {"of": "a worked seam", "shapes": ["ell", "twin"],
        "tell": "Rails run down into water nobody has ever measured."},
    "fortress": {"of": "a fallen hold", "shapes": ["cross", "pillared"],
        "tell": "Every corridor was cut so ten could hold it against a hundred."},
    "temple": {"of": "a temple", "shapes": ["hall", "pillared"],
        "tell": "The processional floor still points the way to the sanctum."},
    "lair": {"of": "a lair", "shapes": ["cavern"],
        "tell": "Bone middens, and every passage leading to one chamber."},
    "prison": {"of": "a prison", "shapes": ["twin", "ell"],
        "tell": "The guard posts face inward. Whatever was kept here was worth it."},
    "works": {"of": "a workshop", "shapes": ["pillared", "cross"],
        "tell": "Containment, storage, and an escape route someone already used."},
    "warren": {"of": "a buried town", "shapes": ["twin", "cavern"],
        "tell": "Streets, doorways, a well. People lived down here on purpose."},
}

# Deterministic per floor, like the theme and the shape, so every party that
# walks floor six walks the same floor six and the chronicle agrees with
# itself across delves.
static func origin_for(floor_no: int) -> String:
    var shape := shape_for(floor_no)
    var fits := []
    for k: String in ORIGINS:
        if shape in Array(ORIGINS[k]["shapes"]):
            fits.append(k)
    if fits.is_empty():
        return "tomb"
    fits.sort()
    var rng := RandomNumberGenerator.new()
    rng.seed = hash("origin:%d" % floor_no)
    return String(fits[rng.randi_range(0, fits.size() - 1)])

# ---------------------------------------------------------------- shapes
# Every floor used to be the same rectangle. The room is now built from an
# occupancy GRID, so walls follow whatever shape the grid describes - which
# means the layout can vary without any of the dressing code caring.
const SHAPES := ["hall", "cross", "ell", "cavern", "twin", "pillared"]

# ---------------------------------------------------------------- layout
# ROOMS AND CORRIDORS. Every floor used to be ONE room on a 9x9 grid with a
# shape cut out of it - a cross, an L, a cavern. There were no corridors, no
# corners to come around and nothing hidden, which is exactly why a floor read
# as "a big empty box with props round the edge".
#
# This builds a real plan: several rooms of different sizes, joined by
# one-cell corridors, plus dead ends and small hidden chambers reachable by a
# single passage. Nothing downstream had to change to support it - walls are
# drawn wherever a cell has no neighbour, so corridors wall themselves; entry
# and exit are the furthest-apart occupied cells, so they land in opposite
# rooms on their own; and spawns already avoid the cells near the entry, so
# monsters end up in the far rooms. The whole floor is just a better `cells`.
#
# `shape_for` is kept and still decides the FLAVOUR - how many rooms and how
# big - because the origins are derived from it and that mapping is worth
# keeping.
const PLANS := {
    "cavern":   {"rooms": 3, "min": 4, "max": 7, "hidden": 1},
    "hall":     {"rooms": 4, "min": 3, "max": 6, "hidden": 1},
    "cross":    {"rooms": 5, "min": 3, "max": 5, "hidden": 2},
    "ell":      {"rooms": 5, "min": 3, "max": 5, "hidden": 1},
    "twin":     {"rooms": 6, "min": 2, "max": 4, "hidden": 2},
    "pillared": {"rooms": 6, "min": 3, "max": 4, "hidden": 2},
}

static func _rect_cells(r: Rect2i, into: Dictionary) -> void:
    for j in range(r.position.y, r.end.y):
        for i in range(r.position.x, r.end.x):
            into[Vector2i(i, j)] = true

# An L-shaped passage one cell wide. Corridors are what make a monster
# something you meet around a corner instead of something you can see from
# the doorway.
static func _corridor(a: Vector2i, b: Vector2i, into: Dictionary,
                      rng: RandomNumberGenerator) -> void:
    var x := a.x
    var y := a.y
    if rng.randi() % 2 == 0:
        while x != b.x:
            x += signi(b.x - x)
            into[Vector2i(x, y)] = true
        while y != b.y:
            y += signi(b.y - y)
            into[Vector2i(x, y)] = true
    else:
        while y != b.y:
            y += signi(b.y - y)
            into[Vector2i(x, y)] = true
        while x != b.x:
            x += signi(b.x - x)
            into[Vector2i(x, y)] = true

static func _layout(kind: String, w: int, h: int,
                    rng: RandomNumberGenerator) -> Dictionary:
    var plan: Dictionary = PLANS.get(kind, PLANS["hall"])
    var cells := {}
    var rooms: Array[Rect2i] = []
    var hidden: Array[Rect2i] = []

    var want: int = int(plan["rooms"])
    var lo: int = int(plan["min"])
    var hi: int = int(plan["max"])
    # Rejection sampling with a one-cell margin, so two rooms never share a
    # wall and every join is a corridor you can actually see.
    var tries := 0
    while rooms.size() < want and tries < 240:
        tries += 1
        var rw: int = rng.randi_range(lo, hi)
        var rh: int = rng.randi_range(lo, hi)
        var rx: int = rng.randi_range(1, maxi(1, w - rw - 1))
        var ry: int = rng.randi_range(1, maxi(1, h - rh - 1))
        var cand := Rect2i(rx, ry, rw, rh)
        var clash := false
        for other: Rect2i in rooms:
            if cand.grow(1).intersects(other):
                clash = true
                break
        if clash:
            continue
        rooms.append(cand)
    if rooms.is_empty():
        rooms.append(Rect2i(1, 1, maxi(3, w - 2), maxi(3, h - 2)))

    for r: Rect2i in rooms:
        _rect_cells(r, cells)
    # Join them in a chain, then add one extra link so the plan LOOPS rather
    # than being a line - a loop means a party can be cut off, and gives the
    # floor more than one way through.
    for i in range(1, rooms.size()):
        _corridor(rooms[i - 1].get_center(), rooms[i].get_center(), cells, rng)
    if rooms.size() > 2:
        _corridor(rooms[rooms.size() - 1].get_center(),
                  rooms[0].get_center(), cells, rng)

    # Hidden chambers: small, off a single passage, and never on the chain.
    # These are where the good chests go.
    var want_hidden: int = int(plan["hidden"])
    var hid_tries := 0
    while hidden.size() < want_hidden and hid_tries < 120:
        hid_tries += 1
        var hw: int = rng.randi_range(2, 3)
        var hh: int = rng.randi_range(2, 3)
        var hx: int = rng.randi_range(1, maxi(1, w - hw - 1))
        var hy: int = rng.randi_range(1, maxi(1, h - hh - 1))
        var cand2 := Rect2i(hx, hy, hw, hh)
        var bad := false
        for other2: Rect2i in rooms:
            if cand2.grow(2).intersects(other2):
                bad = true
                break
        for other3: Rect2i in hidden:
            if cand2.grow(2).intersects(other3):
                bad = true
                break
        if bad:
            continue
        hidden.append(cand2)
        _rect_cells(cand2, cells)
        _corridor(cand2.get_center(),
                  rooms[rng.randi_range(0, rooms.size() - 1)].get_center(),
                  cells, rng)

    return {"cells": cells, "rooms": rooms, "hidden": hidden}

static func _carve(kind: String, w: int, h: int, rng: RandomNumberGenerator) -> Dictionary:
    var cells := {}
    var cx := int(w / 2)
    var cy := int(h / 2)
    match kind:
        "cross":
            var aw := 1 + rng.randi() % 2
            for j in range(h):
                for i in range(w):
                    if absi(i - cx) <= aw or absi(j - cy) <= aw:
                        cells[Vector2i(i, j)] = true
        "ell":
            var qx := rng.randi() % 2
            var qy := rng.randi() % 2
            for j in range(h):
                for i in range(w):
                    var in_bite: bool = (i >= cx if qx == 1 else i <= cx) \
                                    and (j >= cy if qy == 1 else j <= cy)
                    if not in_bite:
                        cells[Vector2i(i, j)] = true
        "cavern":
            for j in range(h):
                for i in range(w):
                    cells[Vector2i(i, j)] = true
            # bite irregular chunks out of the corners
            for n in range(4):
                var bx := 0 if n % 2 == 0 else w - 1
                var by := 0 if n < 2 else h - 1
                var r := 1 + rng.randi() % 3
                for j in range(h):
                    for i in range(w):
                        if absi(i - bx) + absi(j - by) < r:
                            cells.erase(Vector2i(i, j))
        "twin":
            var gap := cy
            for j in range(h):
                for i in range(w):
                    if j == gap and absi(i - cx) > 1:
                        continue                 # a wall between, with a doorway
                    cells[Vector2i(i, j)] = true
        "hall":
            # bayed side walls - a great hall, not a packing crate
            for j in range(h):
                for i in range(w):
                    cells[Vector2i(i, j)] = true
            for i in range(1, w - 1):
                if i % 3 == 1:
                    cells.erase(Vector2i(i, 0))
                    cells.erase(Vector2i(i, h - 1))
        _:                                        # pillared
            for j in range(h):
                for i in range(w):
                    cells[Vector2i(i, j)] = true
    # a room with no floor is not a room
    if cells.size() < 9:
        for j in range(h):
            for i in range(w):
                cells[Vector2i(i, j)] = true
    return cells

static func shape_for(floor_no: int) -> String:
    # A shuffled BAG, not an independent roll per floor. Rolling independently
    # gave six plain rectangles in the first twelve floors and never once
    # produced a cross - which is exactly why the floors looked untried. A bag
    # guarantees all six shapes inside every six floors, and the rotation stops
    # a block repeating the previous block's last shape back to back.
    var n: int = SHAPES.size()
    var block: int = int(floor(float(floor_no - 1) / float(n)))
    var bag := _bag_for(block)
    if block > 0:
        var prev := _bag_for(block - 1)
        if bag[0] == prev[n - 1]:
            bag.push_back(bag.pop_front())
    return String(bag[(floor_no - 1) % n])

static func _bag_for(block: int) -> Array:
    var bag := SHAPES.duplicate()
    var rng := RandomNumberGenerator.new()
    rng.seed = hash("shapebag:%d" % block)
    for i in range(bag.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var t = bag[i]
        bag[i] = bag[j]
        bag[j] = t
    return bag

# Builds one floor under `parent` at `origin`. Returns entry / exit / spawn points.
static func build(parent: Node3D, floor_no: int, origin: Vector3,
                  party_size: int = 4) -> Dictionary:
    var boss: bool = Bestiary.is_boss_floor(floor_no)
    var rng := RandomNumberGenerator.new()
    rng.seed = hash("floor:%d" % floor_no)
    var theme_key := theme_for(floor_no)
    var origin_key := origin_for(floor_no)
    var T: Dictionary = all_themes()[theme_key]
    var floor_tint: Color = T.get("floor_tint", Color(1, 1, 1))
    var wall_tint: Color = T.get("wall_tint", Color(1, 1, 1))

    # The grid is the whole floor, not one room. A 9x9 held a single chamber;
    # a plan of four to six rooms with corridors between them needs space to
    # breathe. Rooms and corridors only occupy about a third of it, so the
    # built geometry is comparable to the old solid 9x9 despite the size.
    var w: int = 19 if not boss else 21
    var h: int = 19 if not boss else 21
    var half_w := (w - 1) * G * 0.5
    var half_h := (h - 1) * G * 0.5

    var root := Node3D.new()
    root.name = "Floor%d_%s" % [floor_no, theme_key]
    root.position = origin
    parent.add_child(root)

    # ---- the room's shape, as an occupancy grid
    var shape := shape_for(floor_no)
    # SOLID ROCK UNDER EVERYTHING. A plan of rooms and corridors leaves most
    # of the grid unoccupied, and unoccupied used to mean "nothing rendered" -
    # so the middle of a floor was a see-through hole onto the background
    # instead of the stone the passages were cut through. One dark slab under
    # the whole grid fixes it for the cost of a single mesh.
    var slab := MeshInstance3D.new()
    var sq := PlaneMesh.new()
    sq.size = Vector2(float(w + 2) * G, float(h + 2) * G)
    slab.mesh = sq
    var sdm := StandardMaterial3D.new()
    sdm.albedo_color = Color(0.055, 0.050, 0.058)
    sdm.roughness = 1.0
    slab.material_override = sdm
    slab.position = Vector3(0, -0.52, 0)
    root.add_child(slab)

    var plan := _layout(shape, w, h, rng)
    var cells: Dictionary = plan["cells"]
    var rooms: Array = plan["rooms"]
    var hidden_rooms: Array = plan["hidden"]
    var cell_pos := func(i: int, j: int) -> Vector3:
        return Vector3(float(i) * G - half_w, 0.0, float(j) * G - half_h)

    # ---- floor.
    # Picking a tile at random per cell makes a checkerboard, not a floor - the
    # same mistake as randomising grass colour per hex. One DOMINANT material
    # covers the room; the second forms a single coherent region; accents are
    # sparse wear on top.
    # Which cells are molten is decided BEFORE the floor goes down, because a
    # pool has to REPLACE its tile. Laid on top of one, the tile sat above the
    # lava and hid it completely - a pit you cannot see is just an expensive
    # light.
    var pool_cells := {}
    var n_pools: int = int(T.get("pools", 0))
    if n_pools > 0:
        var pool_bag := cells.keys()
        for i in range(pool_bag.size() - 1, 0, -1):
            var jp := rng.randi_range(0, i)
            var tp = pool_bag[i]; pool_bag[i] = pool_bag[jp]; pool_bag[jp] = tp
        var made := 0
        for c: Vector2i in pool_bag:
            if made >= n_pools:
                break
            # never against a wall, where the stairs live, and never the
            # dead centre, which belongs to the lamp-stand. Excluded HERE
            # rather than cancelled later: by the time the lamp cell is
            # known the floor has been laid, so dropping a pool then would
            # leave a bare hole with nothing in it.
            if c.x <= 1 or c.y <= 1 or c.x >= w - 2 or c.y >= h - 2:
                continue
            if absi(c.x - int(w / 2)) <= 1 and absi(c.y - int(h / 2)) <= 1:
                continue
            # HD: only deep inside a room - a pool in a corridor walled the
            # passage shut, and one by a doorway pinched it to nothing
            var interior := true
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    if not cells.has(c + Vector2i(dx, dy)) or pool_cells.has(c + Vector2i(dx, dy)):
                        interior = false
            if not interior:
                continue
            pool_cells[c] = true
            made += 1

    # L25: the floor's footprints start empty; tiles are floor (flat, not registered)
    _boxes.clear()
    _pool_obs.clear()
    _rejected = 0
    _grp = 0
    _tag = "floor"
    var bag: Array = T["floors"]
    var acc: Array = T["accents"]
    var main := String(bag[0])
    var second := String(bag[bag.size() - 1])
    var layout := rng.randi() % 3
    for c: Vector2i in cells:
        if pool_cells.has(c):
            continue                    # this one is a hole
        var pos: Vector3 = cell_pos.call(c.x, c.y)
        var tile := main
        if layout == 0 and absi(c.x - int(w / 2)) <= 1:
            tile = second
        elif layout == 1 and c.y < int(h / 3):
            tile = second
        if tile.contains("_small"):
            # HD: a "small" tile is a quarter of a cell - lay four, or three
            # quarters of the floor is bare ground (the old patchy look)
            for qx in [-1.0, 1.0]:
                for qz in [-1.0, 1.0]:
                    _put(root, tile, pos + Vector3(qx * G * 0.25, 0, qz * G * 0.25), float(rng.randi() % 4) * 90.0, 1.0, floor_tint)
        else:
            _put(root, tile, pos, float(rng.randi() % 4) * 90.0, 1.0, floor_tint)
        if rng.randf() < 0.16 and acc.size() > 0 and tile == main:
            _put(root, String(acc[rng.randi() % acc.size()]),
                 pos + Vector3(rng.randf_range(-1.1, 1.1), 0.02, rng.randf_range(-1.1, 1.1)),
                 float(rng.randi() % 4) * 90.0, 1.0, floor_tint)

    # ---- the biome's own growth, scattered over the floor. This is what
    # turns a stone room into a meadow or a buried wood: free-standing hex-kit
    # trees and rocks, or the dungeon kit's own trunks and rubble, dropped on
    # occupied cells at the biome's own density.
    var scatter: Array = T.get("scatter", [])
    var prop_tint: Color = T.get("prop_tint", Color(1, 1, 1))
    # HD: the growth is placed LAST (below, before the floor is returned) and
    # only against room walls - never in corridors, the middle of a room, the
    # stairs or on top of furniture, which is where it used to land.
    _obs.clear()

    # ---- walls follow the SHAPE, not a rectangle: a wall goes wherever an
    # occupied cell meets empty space, so an L-room or a cross walls itself
    var torch_spots := []
    var wall_bag := ["wall", "wall", "wall", "wall_pillar", "wall_cracked",
                     "wall_shelves", "wall_window_closed"]
    if floor_no >= 5:
        wall_bag.append("wall_cracked")   # HD: wall_broken opened a see-through hole onto the void
        wall_bag.append("wall_archedwindow_gated")
    if theme_key == "prison":
        wall_bag.append("wall_gated")
    var sides := [[Vector2i(0, -1), 0.0, Vector3(0, 0, -G * 0.5)],
                  [Vector2i(0, 1), 180.0, Vector3(0, 0, G * 0.5)],
                  [Vector2i(1, 0), 90.0, Vector3(G * 0.5, 0, 0)],
                  [Vector2i(-1, 0), 270.0, Vector3(-G * 0.5, 0, 0)]]
    # L25: the stair cells are chosen FIRST, so the walls behind and beside a flight are plain
    # walls (a wall pillar reaches 0.75 m into the cell, a plain wall 0.5) and no column stands
    # in one. The entry is the most southerly cell, the exit the most northerly.
    var occupied := cells.keys()
    occupied.sort_custom(func(x, y): return (x as Vector2i).y > (y as Vector2i).y)
    var near: Vector2i = occupied[0]
    var far: Vector2i = occupied[occupied.size() - 1]
    var n_wall := 0
    _tag = "wall"
    for c: Vector2i in cells:
        var base: Vector3 = cell_pos.call(c.x, c.y)
        for sd: Array in sides:
            var nb: Vector2i = c + (sd[0] as Vector2i)
            if cells.has(nb):
                continue
            n_wall += 1
            var k := "wall_pillar" if n_wall % 4 == 1 else String(wall_bag[rng.randi() % wall_bag.size()])
            if c == near or c == far:
                k = "wall"
            var at: Vector3 = base + (sd[2] as Vector3)
            _put(root, k, at, float(sd[1]), 1.0, wall_tint)
            if n_wall % 4 == 1:
                var inward: Vector3 = (base - at).normalized() * 0.45
                torch_spots.append(Vector3(at.x + inward.x, 2.35, at.z + inward.z))

    # (L25b: the lamp's cell is chosen before the dressing, so the route can go round it)
    var lamp_cell: Vector2i = Vector2i(int(w / 2), int(h / 2))
    # The lamp-stand must stand in a ROOM for the same reason as the pillars.
    # It is a piece of furniture a party fights around, not a cork in a pipe.
    var lamp_ok := false
    for r: Rect2i in rooms:
        if r.has_point(lamp_cell):
            lamp_ok = true
            break
    if not lamp_ok:
        var best := 1e9
        for r2: Rect2i in rooms:
            var c2: Vector2i = r2.get_center()
            var d2 := Vector2(c2 - lamp_cell).length()
            if d2 < best and cells.has(c2):
                best = d2
                lamp_cell = c2
                lamp_ok = true
    if not lamp_ok and not cells.has(lamp_cell):
        var best3 := 1e9
        for c: Vector2i in cells:
            var d := Vector2(c - lamp_cell).length()
            if d < best3:
                best3 = d
                lamp_cell = c
    # L25b: KEEP CLEAR. The way from the stairs down to the stairs out (around the lamp's cell)
    # and every corridor cell are registered as zones no furniture may stand in: props kept
    # landing on the route and in doorways, and the party had to push through them.
    var route_prev := {near: near}
    var rq: Array = [near]
    while not rq.is_empty():
        var rc: Vector2i = rq.pop_front()
        if rc == far:
            break
        for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var rn: Vector2i = rc + dv
            if cells.has(rn) and not route_prev.has(rn) and (rn != lamp_cell or rn == far):
                route_prev[rn] = rc
                rq.append(rn)
    if not route_prev.has(far):
        route_prev = {near: near}          # the lamp cell is the only way through: go by it
        rq = [near]
        while not rq.is_empty():
            var rc2: Vector2i = rq.pop_front()
            for dv2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                var rn2: Vector2i = rc2 + dv2
                if cells.has(rn2) and not route_prev.has(rn2):
                    route_prev[rn2] = rc2
                    rq.append(rn2)
    var keep_clear := {}
    var rcur := far
    while route_prev.has(rcur) and rcur != near:
        keep_clear[rcur] = true
        rcur = route_prev[rcur]
    keep_clear[near] = true
    for c: Vector2i in cells:
        if _is_corridor(cells, c):
            keep_clear[c] = true
    keep_clear.erase(lamp_cell)
    for c: Vector2i in keep_clear:
        var kp: Vector3 = cell_pos.call(c.x, c.y)
        _boxes.append({"o": Vector2(kp.x, kp.z), "ux": Vector2(1, 0), "uz": Vector2(0, 1), "hx": CLEAR_HALF, "hz": CLEAR_HALF,
            "y0": 0.0, "y1": 2.0, "kind": "clear", "grp": -1, "asset": "", "node": null})
    _cells = cells
    _half_v = Vector2(half_w, half_h)

    # ---- torches, tinted by theme
    var lit: Color = T["light"]
    _tag = "torch"
    for t in torch_spots:
        _put(root, "torch_mounted", Vector3(t.x, t.y, t.z))
        var l := OmniLight3D.new()
        l.light_color = lit
        l.light_energy = 9.0
        l.omni_range = 19.0
        l.position = Vector3(t.x, t.y + 0.35, t.z)
        root.add_child(l)
        var flame := MeshInstance3D.new()
        var fm := SphereMesh.new()
        fm.radius = 0.22
        fm.height = 0.52
        flame.mesh = fm
        var fmat := StandardMaterial3D.new()
        fmat.albedo_color = lit
        fmat.emission_enabled = true
        fmat.emission = lit
        fmat.emission_energy_multiplier = 9.0
        fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        fm.material = fmat
        flame.position = Vector3(t.x, t.y + 0.30, t.z)
        root.add_child(flame)

    # Wall torches cannot reach the centre, which is exactly where the fight
    # happens - without these the party is invisible in the dark.
    # A single central fill left the far end of a big room unreadable - one
    # point source with a 1.4 falloff cannot cover a long hall evenly, and a
    # floor you cannot see reads as a floor nobody worked on. Lay the fill out
    # on a grid sized to the room instead, so coverage holds at any shape.
    var span: float = maxf(half_w, half_h)
    var nx: int = clampi(int(half_w / 11.0) + 1, 1, 3)
    var nz: int = clampi(int(half_h / 11.0) + 1, 1, 3)
    for gx in range(nx):
        for gz in range(nz):
            var fx: float = 0.0 if nx == 1 else lerpf(-half_w * 0.55, half_w * 0.55,
                                                      float(gx) / float(nx - 1))
            var fz: float = 0.0 if nz == 1 else lerpf(-half_h * 0.55, half_h * 0.55,
                                                      float(gz) / float(nz - 1))
            var fill := OmniLight3D.new()
            fill.position = Vector3(fx, 8.0, fz)
            fill.light_color = lit.lerp(Color(1, 1, 1), 0.35)
            fill.light_energy = 3.4 / sqrt(float(nx * nz))
            fill.omni_range = span * 1.6 + 16.0
            fill.omni_attenuation = 1.0
            fill.shadow_enabled = false
            root.add_child(fill)
    var bounce := OmniLight3D.new()
    bounce.position = Vector3(0, 1.2, 0)
    bounce.light_color = lit
    bounce.light_energy = 1.8
    bounce.omni_range = span * 2.2
    bounce.omni_attenuation = 1.0
    bounce.shadow_enabled = false
    root.add_child(bounce)

    # a lid so the overworld sun doesn't flood it
    var lid := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(w * G + 14.0, 1.0, h * G + 14.0)
    lid.mesh = bm
    var lm := StandardMaterial3D.new()
    lm.albedo_color = Color(0.04, 0.04, 0.05)
    bm.material = lm
    lid.position = Vector3(0, 7.0, 0)
    lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
    root.add_child(lid)

    # ---- interior structure. "pillared" earns a full colonnade; the others
    # get something lighter so they don't fight the room's own shape.
    # PILLARS BELONG IN ROOMS, NEVER IN A CORRIDOR. A pillar dropped in a
    # one-cell passage fills it completely - it reads as a wall, the party
    # walks straight through it, and it looks broken. A cell counts as a room
    # cell only if it is inside one of the planned rectangles; everything else
    # is passage and stays clear.
    var in_room := func(c: Vector2i) -> bool:
        for r: Rect2i in rooms:
            if r.has_point(c):
                return true
        return false
    _tag = "struct"
    if shape == "pillared":
        for c: Vector2i in cells:
            if c.x % 3 == 1 and c.y % 3 == 1 and in_room.call(c) and c != near and c != far and not keep_clear.has(c):
                _put(root, "pillar_decorated", cell_pos.call(c.x, c.y))
    else:
        var structural := []
        for c: Vector2i in cells:
            if c.x % 4 == 2 and c.y % 4 == 2 and in_room.call(c) and c != near and c != far and not keep_clear.has(c):
                structural.append(c)
        for c: Vector2i in structural:
            _put(root, "column" if rng.randf() < 0.5 else "pillar",
                 cell_pos.call(c.x, c.y))

    # ---- lava pools, for biomes that declare them
    # A pool REPLACES its floor tile and sits below floor level, so it reads
    # as a hole with something molten in it rather than a glowing rug. The
    # shader is unshaded and emissive, so each pool also throws its own light
    # and the room lights itself from the floor up.
    if true:
        for c: Vector2i in pool_cells:
            var at: Vector3 = cell_pos.call(c.x, c.y)
            var mi := MeshInstance3D.new()
            var pm := PlaneMesh.new()
            pm.size = Vector2(G * 1.02, G * 1.02)
            mi.mesh = pm
            var sm := ShaderMaterial.new()
            sm.shader = load("res://assets/shaders/lava.gdshader")   # HD: the old root path loaded nothing - a black square where a lava pit should be
            mi.material_override = sm
            mi.position = at + Vector3(0, -0.38, 0)
            root.add_child(mi)
            _obs.append([at, G * 0.5])      # nobody strolls across molten rock
            _pool_obs.append([at, G * 0.5])
            var gl := OmniLight3D.new()
            gl.light_color = Color(1.0, 0.42, 0.12)
            gl.light_energy = 4.2
            gl.omni_range = G * 2.6
            gl.position = at + Vector3(0, 0.9, 0)
            root.add_child(gl)

    # ---- THE LAMP-STAND, dead centre of every floor.
    #
    # The RTS idea (a Xel'Naga tower: one central thing that PULLS the whole
    # fight toward it) and the manual's "an objective that is not killing"
    # arrived at the same shape independently, so it is worth building once
    # and properly.
    #
    # What it does is deliberately tied to the oil: a hero who reaches it
    # sets it burning and the party gets light back. That matters because
    # depth had become something only gold and guild rank could buy - a poor
    # party simply ran out on floor 3. The lamp-stand is the way to go deeper
    # by PLAYING rather than by purchasing, which is the better half of the
    # curve. It sits in the middle because that is where a party has to fight
    # its way to, not somewhere safe.
    var lamp: Vector3 = cell_pos.call(lamp_cell.x, lamp_cell.y)
    _cluster(root, "lampstand", lamp, float(rng.randi() % 4) * 90.0)

    # ---- entry and exit must be cells that EXIST. On an L-room or a cross the
    # old fixed coordinates landed in empty space outside the floor.
    # (L25: near / far are chosen before the walls go up - see there)
    var entry: Vector3 = cell_pos.call(near.x, near.y)
    var exit_p: Vector3 = cell_pos.call(far.x, far.y)
    # L25: the stairs. The old ones were "stairs_wide" - 7 m across on a 4 m cell - set with
    # their HIGH end buried in the middle of the wall. Now a narrow flight at 3/4 size (3 m wide,
    # 3 m deep, 3.8 m up, under the 4 m wall top), its high end flush on the INNER face of the
    # wall it backs onto (walls reach 0.5 m into the cell), its foot on the floor of the room.
    # The entry is the most southerly cell (a wall on its +z side), the exit the most northerly.
    _tag = "stairs"
    var wall_face := G * 0.5 - WALL_IN
    _put(root, STAIRS, entry + Vector3(0, 0, wall_face), 180.0, STAIRS_K)
    _put(root, STAIRS, exit_p - Vector3(0, 0, wall_face), 0.0, STAIRS_K)

    # ---- dressing. Clusters go in occupied cells near a wall, keeping the
    # middle clear to fight in.
    var edge_cells := []
    for c: Vector2i in cells:
        if c == near or c == far:
            continue
        var touches_wall := false
        for sd: Array in sides:
            if not cells.has(c + (sd[0] as Vector2i)):
                touches_wall = true
        if touches_wall:
            edge_cells.append(c)
    for i in range(edge_cells.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var tmp = edge_cells[i]; edge_cells[i] = edge_cells[j]; edge_cells[j] = tmp
    var cl: Array = T["clusters"]
    # Scale the dressing to the ROOM, not a flat 4-6. A fixed count left a big
    # hall with a handful of props lost in it, which is what made the floors
    # look untried however good the individual clusters were.
    var n_clusters: int = mini(edge_cells.size(),
        clampi(int(float(cells.size()) / 6.5), 5, 15) + (2 if boss else 0))
    var placed := 0
    for i in range(edge_cells.size()):
        if placed >= n_clusters:
            break
        var ec: Vector2i = edge_cells[i]
        if _is_corridor(cells, ec):
            continue
        var at: Vector3 = cell_pos.call(ec.x, ec.y)
        # pull the cluster toward its wall so the room's middle stays open
        var pull := Vector3.ZERO
        for sd3: Array in sides:
            if not cells.has(ec + (sd3[0] as Vector2i)):
                pull += (sd3[2] as Vector3).normalized()
        if pull != Vector3.ZERO:
            pull = pull.normalized()
        at += pull * G * 0.18
        var key := String(cl[rng.randi() % cl.size()])
        if not _free_at(at, float(CLUSTER_R.get(key, 1.5))) or at.distance_to(entry) < G * 1.2 or at.distance_to(exit_p) < G * 1.2:
            continue
        var facing := rad_to_deg(atan2(-at.x, -at.z)) + rng.randf_range(-25.0, 25.0)
        # L25: an anchor that does not fit tries further off its wall, then turned
        var done := false
        for nudge in [0.0, 0.6, 1.2]:
            for turn in [0.0, 90.0, -90.0]:
                if _cluster(root, key, at - pull * nudge, facing + turn):
                    done = true
                    break
            if done:
                break
        if done:
            placed += 1
        else:
            _rejected += (CLUSTERS[key] as Array).size()

    # A few loose things away from the walls so the middle is not bare floor.
    # Kept sparse and off-centre: the party still needs room to fight.
    var inner := []
    for c: Vector2i in cells:
        var walled := false
        for sd2: Array in sides:
            if not cells.has(c + (sd2[0] as Vector2i)):
                walled = true
        if not walled:
            inner.append(c)
    for i in range(inner.size() - 1, 0, -1):
        var j2 := rng.randi_range(0, i)
        var t2 = inner[i]; inner[i] = inner[j2]; inner[j2] = t2
    var ac: Array = T["accents"]
    var n_loose: int = mini(inner.size(), clampi(int(float(cells.size()) / 11.0), 2, 8))
    for i in range(n_loose):
        var ip: Vector3 = cell_pos.call(inner[i].x, inner[i].y)
        var ak := String(ac[rng.randi() % ac.size()])
        _tag = "floor" if ak.begins_with("floor_") else "prop"
        _grp += 1
        _put(root, ak, ip)
        # (HD: no furniture clusters dropped in the middle - the party fights there)

    # banners near the far end
    var bn: Array = T["banners"]
    _tag = "banner"
    for sx: int in [-1, 1]:
        _grp += 1
        # L25: only where that spot is floor with a wall behind it - one used to hang in the void
        var bc := far + Vector2i(sx, 0)
        if not cells.has(bc) or cells.has(bc + Vector2i(0, -1)):
            continue
        _put(root, String(bn[rng.randi() % bn.size()]),
             exit_p + Vector3(float(sx) * G, 0, -G * 0.45))
    if boss:
        _cluster(root, "hoard", exit_p + Vector3(0, 0, G * 1.2), 0.0)

    # ---- what is actually IN the hidden chambers
    # A hidden room with nothing in it is just a wrong turn. Each one gets a
    # hoard or a strongbox, so curiosity pays and the party has a reason to
    # explore the plan rather than walk the shortest line to the stairs.
    for hr: Rect2i in hidden_rooms:
        var c: Vector2i = hr.get_center()
        _cluster(root, "hoard" if rng.randf() < 0.5 else "strongbox",
                 cell_pos.call(c.x, c.y), float(rng.randi() % 4) * 90.0)

    # ---- monsters wait in cells that exist, away from where the party enters
    var spawn_pool := []
    for c: Vector2i in cells:
        if cell_pos.call(c.x, c.y).distance_to(entry) > G * 2.0:
            spawn_pool.append(c)
    if spawn_pool.is_empty():
        spawn_pool = cells.keys()
    for i in range(spawn_pool.size() - 1, 0, -1):
        var j2 := rng.randi_range(0, i)
        var t2 = spawn_pool[i]; spawn_pool[i] = spawn_pool[j2]; spawn_pool[j2] = t2
    var spawns := []
    var count: int = mini(2 + int(floor(float(floor_no) / 2.0)), 6)
    # Scale to the party that actually walked in. Monster strength keys off
    # depth alone, so a pair used to meet exactly what a full band meets -
    # which measured as 0% survival and 88% of heroes dying at level 1 with
    # one kill or none. A short-handed party now meets a short-handed floor.
    count = maxi(1, int(round(float(count) * float(clampi(party_size, 1, 4)) / 4.0)))
    if boss:
        count = maxi(2, int(round(3.0 * float(clampi(party_size, 1, 4)) / 4.0)))
    for i in range(mini(count, spawn_pool.size())):
        spawns.append(cell_pos.call(spawn_pool[i].x, spawn_pool[i].y))
    # SOMETHING GUARDS THE LAMP. Without this the centre of the room was the
    # one place nothing ever happened: measured at 17% of floors, a hero
    # wandered close enough to light the stand, so the objective was
    # decorative. A guard is what makes a central objective an objective at
    # all - the manual's "monster guarding treasure" and the RTS reading of a
    # contested middle are the same note. The party does not have to go; they
    # have to decide whether it is worth it.
    #
    # It replaces a spawn rather than adding one, so floor difficulty is
    # unchanged and this stays a LAYOUT change, not a balance change.
    if not spawns.is_empty() and not boss:
        spawns[0] = lamp + Vector3(G * 0.35, 0, G * 0.2)

    # ---- the biome's growth, against the walls of rooms only
    if not scatter.is_empty():
        for c: Vector2i in cells:
            if _is_corridor(cells, c):
                continue
            var wall_dir := Vector3.ZERO
            for sd4: Array in sides:
                if not cells.has(c + (sd4[0] as Vector2i)):
                    wall_dir += (sd4[2] as Vector3).normalized()
            if wall_dir == Vector3.ZERO:
                continue                      # an inner cell: leave it open
            for spec: Array in scatter:
                if rng.randf() >= float(spec[1]) * 0.6:
                    continue
                var sc2 := rng.randf_range(float(spec[2]), float(spec[3]))
                var at2: Vector3 = cell_pos.call(c.x, c.y) + wall_dir.normalized() * G * 0.3 + Vector3(
                    rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.5, 0.5))
                var r2 := 0.75 * sc2
                if not _free_at(at2, r2) or at2.distance_to(entry) < G or at2.distance_to(exit_p) < G or at2.distance_to(lamp) < G:
                    continue
                _tag = "scatter"
                _grp += 1
                if _put(root, String(spec[0]), at2, rng.randf_range(0.0, 360.0), sc2, prop_tint) != null:
                    _obs.append([at2, r2])
                else:
                    _rejected += 1

    # L25c: a creature never waits inside furniture (the party could not reach it and stood
    # pressing at the table) - one in an obstacle goes to the nearest clear cell
    var wob := walk_obstacles()
    for si in spawns.size():
        var sp: Vector3 = spawns[si]
        if _in_obstacle(sp, wob):
            var bestc := Vector3.ZERO
            var bd := 1e9
            for c: Vector2i in cells:
                var cp: Vector3 = cell_pos.call(c.x, c.y)
                if not _in_obstacle(cp, wob) and cp.distance_to(sp) < bd and cp.distance_to(entry) > G * 2.0:
                    bd = cp.distance_to(sp)
                    bestc = cp
            if bd < 1e8:
                spawns[si] = bestc
    _cells = {}
    _tag = ""
    return {"root": root, "entry": origin + entry, "exit": origin + exit_p, "obstacles": walk_obstacles(),
            "rejected": _rejected, "boxes": _boxes.size(), "keep_clear": keep_clear,
            "spawns": spawns, "origin": origin, "boss": boss,
            "theme": theme_key, "theme_name": String(T["name"]), "shape": shape,
            # The occupancy grid goes home with the floor so the party can be
            # PATHED through it. Straight-line movement was fine when a floor
            # was one convex room; across a plan of rooms and corridors it
            # walks people through walls and over the void between them.
            "cells": cells, "w": w, "h": h, "grid": G,
            "half": Vector2(half_w, half_h),
            "lamp": origin + lamp,
            "origin_key": origin_key,
            "origin_name": String(ORIGINS[origin_key]["of"]),
            "origin_tell": String(ORIGINS[origin_key]["tell"])}

## a corridor cell: open on exactly two OPPOSITE sides (or a dead end)
static func _is_corridor(cells: Dictionary, c: Vector2i) -> bool:
    var n := 0
    for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        if cells.has(c + d):
            n += 1
    if n <= 1:
        return true
    if n == 2:
        return (cells.has(c + Vector2i(1, 0)) and cells.has(c + Vector2i(-1, 0))) or (cells.has(c + Vector2i(0, 1)) and cells.has(c + Vector2i(0, -1)))
    return false

## ---- L25 (Mr. E: "looks like shit - stairs, objects clipping, people get stuck"). Every piece
## the floor places has a real footprint - an oriented box from its own meshes (cached per
## asset) - and furniture is only set down where it fits: not into a wall (walls are 1 m thick
## and reach 0.5 m into every cell), not into a pillar, the stairs or another cluster. A small
## thing that lands on a plain table goes ON it; anything else that does not fit is left out,
## and a cluster whose anchor piece does not fit is not placed at all. tools/_l25_test.gd probes it.
const PEN_MAX := 0.15                # m a piece may touch another (the probe allows 0.2)
const WALL_IN := 0.5                 # a wall reaches this far into its cell (kit walls are 1 m thick, centred on the edge)
const STAIRS := "stairs_narrow"
const STAIRS_K := 0.75
const SOLID_KINDS := ["wall", "struct", "stairs"]       # registered, placed regardless (the shape)
const CHECK_KINDS := ["prop", "scatter", "banner"]      # registered only where they fit
const REST_KINDS := ["prop", "scatter", "struct"]
static var _tag := ""
static var _grp := 0
static var _boxes: Array = []
static var _box_cache := {}
static var _rejected := 0
static var _pool_obs: Array = []
static var _cells := {}
static var _half_v := Vector2.ZERO
const CLEAR_HALF := 0.6              # m round a keep-clear cell centre (the route, the corridors)
static var fit_checks := true        # tests switch it off to measure what placement does without it

## the asset's own bounds, in its node's space at scale 1 (meshes merged, cached)
static func _local_box(asset: String, n: Node3D) -> AABB:
    if _box_cache.has(asset):
        return _box_cache[asset]
    var out := AABB()
    var first := true
    var st: Array = [[n, Transform3D.IDENTITY]]
    while not st.is_empty():
        var it: Array = st.pop_back()
        var c: Node = it[0]
        var xf: Transform3D = it[1]
        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
            var a: AABB = xf * (c as MeshInstance3D).get_aabb()
            out = a if first else out.merge(a)
            first = false
        for g in c.get_children():
            if g is Node3D:
                st.append([g, xf * (g as Node3D).transform])
    _box_cache[asset] = out
    return out

## a placed piece's footprint on the floor: centre, axes, half sizes, height range
static func _box_of(n: Node3D, asset: String) -> Dictionary:
    var lb := _local_box(asset, n)
    var k := n.scale.x
    var a := n.rotation.y
    var ux := Vector2(cos(a), -sin(a))
    var uz := Vector2(sin(a), cos(a))
    var lc := lb.get_center() * k
    var o := Vector2(n.position.x, n.position.z) + ux * lc.x + uz * lc.z
    return {"o": o, "ux": ux, "uz": uz, "hx": lb.size.x * k * 0.5, "hz": lb.size.z * k * 0.5,
        "y0": n.position.y + lb.position.y * k, "y1": n.position.y + lb.end.y * k,
        "kind": _tag, "grp": _grp, "asset": asset, "node": n}

## how deep two footprints interpenetrate (0 = apart): the separating-axis test on the floor,
## and the height ranges
static func pen(a: Dictionary, b: Dictionary) -> float:
    var dy := minf(float(a["y1"]), float(b["y1"])) - maxf(float(a["y0"]), float(b["y0"]))
    if dy <= 0.0:
        return 0.0
    var best := dy
    var d: Vector2 = b["o"] - a["o"]
    for ax: Vector2 in [a["ux"], a["uz"], b["ux"], b["uz"]]:
        var ra := float(a["hx"]) * absf((a["ux"] as Vector2).dot(ax)) + float(a["hz"]) * absf((a["uz"] as Vector2).dot(ax))
        var rb := float(b["hx"]) * absf((b["ux"] as Vector2).dot(ax)) + float(b["hz"]) * absf((b["uz"] as Vector2).dot(ax))
        var ov := ra + rb - absf(d.dot(ax))
        if ov <= 0.0:
            return 0.0
        best = minf(best, ov)
    return best

## the deepest this footprint would sit in anything already placed
static func _blocked(bx: Dictionary) -> float:
    var worst := 0.0
    # L25b: off the floor (a cluster reaching past a doorway into the void) is never a fit
    if not _cells.is_empty():
        var o: Vector2 = bx["o"]
        if not _cells.has(Vector2i(roundi((o.x + _half_v.x) / G), roundi((o.y + _half_v.y) / G))):
            return 99.0
    for b: Dictionary in _boxes:
        if String(b["kind"]) == "clear":
            if pen(bx, b) > 0.0:
                return 99.0            # nothing stands on the route or in a doorway
            continue
        worst = maxf(worst, pen(bx, b))
        if worst > PEN_MAX:
            return worst
    return worst

## a small thing (a plate, a candle, a bottle) that lands on a plain table of its own cluster
## goes on its top instead; a decorated table already has its own and the thing is left out
static func _try_table_top(n: Node3D, asset: String, bx: Dictionary) -> bool:
    if float(bx["y1"]) - float(bx["y0"]) > 1.0 or _tag != "prop":
        return false
    for b: Dictionary in _boxes:
        if int(b["grp"]) != _grp or not String(b["asset"]).begins_with("table") or String(b["asset"]).contains("decorated"):
            continue
        if pen(bx, b) <= 0.0:
            continue
        n.position.y = float(b["y1"])
        var on := _box_of(n, asset)
        var others := 0.0
        for c: Dictionary in _boxes:
            if c != b:
                others = maxf(others, pen(on, c))
        return others <= PEN_MAX
    return false

## L25c: what a delver walks AROUND - one circle per real piece that stands in the way (furniture,
## columns, growth: anything taller than a shin), sized from its measured footprint, plus the lava
## pools. (It was one fixed 1.5-2 m circle per cluster, which covered cell centres the route ran
## through, while pillars and columns were not obstacles at all.)
static func walk_obstacles() -> Array:
    var out: Array = _pool_obs.duplicate()
    for b: Dictionary in _boxes:
        if not (String(b["kind"]) in ["prop", "scatter", "struct"]):
            continue
        if float(b["y1"]) - maxf(0.0, float(b["y0"])) < 0.4 or float(b["y0"]) > 1.0:
            continue
        var o: Vector2 = b["o"]
        out.append([Vector3(o.x, 0, o.y), maxf(float(b["hx"]), float(b["hz"])) * 0.85])
    return out

static func _in_obstacle(p: Vector3, obs: Array) -> bool:
    for o in obs:
        if Vector2(p.x - (o[0] as Vector3).x, p.z - (o[0] as Vector3).z).length() < float(o[1]) + 0.6:
            return true
    return false
