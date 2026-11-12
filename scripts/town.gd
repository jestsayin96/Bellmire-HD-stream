extends Node3D
## Bellmire.
##
## ORDER MATTERS: roads are laid FIRST, then plots are derived from the roads.
## The previous version placed houses on hex centres at random yaw and it read
## as sheds in a field - nothing had a frontage because nothing had a street to
## face. A house must face a road, and must be positioned by its FACADE, not
## its centre, or its front wall ends up in the carriageway.
##
## Hexes are assigned to the NEAREST district centre, which gives irregular
## organic borders instead of radial sectors. Roof livery is the district
## signal, coloured by ADJACENCY: only four liveries for eight districts, so no
## two touching districts may share one.

## Four house shapes. DEPTH is measured from the imported glb (footprint +
## roof overhang) and sets how far the plot stands back from the road, so each
## model carries its own - one shared constant would put the deep ones in the
## carriageway, which is the bug that made the first town a canyon.
const HOUSES := {
    "a": {"path": "res://assets/buildings/mk_house_a.glb", "depth": 11.1},
    "b": {"path": "res://assets/buildings/mk_house_b.glb", "depth":  9.1},
    "c": {"path": "res://assets/buildings/mk_house_c.glb", "depth":  9.1},
    "d": {"path": "res://assets/buildings/mk_house_d.glb", "depth": 13.1},
    "lm_hall":      {"path": "res://assets/buildings/lm_hall.glb", "depth": 16.0},
    "lm_chapel":    {"path": "res://assets/buildings/lm_chapel.glb", "depth": 18.0},
    "lm_barracks":  {"path": "res://assets/buildings/lm_barracks.glb", "depth": 14.0},
    "lm_windmill":  {"path": "res://assets/buildings/lm_windmill.glb", "depth": 6.0},
    "lm_granary":   {"path": "res://assets/buildings/lm_granary.glb", "depth": 8.0},
    "lm_watermill": {"path": "res://assets/buildings/lm_watermill.glb", "depth": 8.0},
    "lm_workshop":  {"path": "res://assets/buildings/lm_workshop.glb", "depth": 12.0},
    "lm_sawmill":   {"path": "res://assets/buildings/lm_sawmill.glb", "depth": 12.0},
}
## Lore (world.json district_rules): "Each district has a centre hex; its
## landmark is planted first, its own trades nearest that heart."
const LANDMARKS := {"keep": ["lm_hall"], "temple": ["lm_chapel"], "garrison": ["lm_barracks"],
                    "mill": ["lm_windmill", "lm_granary"], "craft": ["lm_workshop"]}
## which shapes suit which district: trades get wide fronts, keep and garrison
## tall narrow blocks, homes the plainer two.
const DISTRICT_SHAPES := {
    "market":  ["c", "c", "a"], "craft":   ["c", "a", "d"],
    "keep":    ["b", "b", "a"], "garrison":["b", "a", "c"],
    "temple":  ["a", "b", "d"], "mill":    ["d", "a"],
    "homes_s": ["a", "d", "b"], "homes_w": ["a", "d", "b"],
}
const LIVERIES := ["blue", "green", "red", "yellow"]
const LIVERY_BANNER := {"blue": Color(0.16, 0.26, 0.62), "green": Color(0.18, 0.45, 0.20),
    "red": Color(0.62, 0.14, 0.12), "yellow": Color(0.85, 0.66, 0.16)}

const PROPS := "res://assets/props/"
const NATURE := "res://assets/nature/"
const MKPROPS := "res://assets/mkprops/"
## Quaternius props are modelled small; MegaKit houses are real-world size.
const PROP_SCALE := 1.45
## what stands on the market square, and what leans against a house front
const SQUARE_PROPS := ["Stall_Empty", "Stall_Cart_Empty", "Barrel_Apples",
                       "FarmCrate_Apple", "FarmCrate_Carrot", "Crate_Wooden",
                       "Bench", "Barrel"]
const STREET_PROPS := ["Barrel", "Crate_Wooden", "FarmCrate_Empty", "Bench",
                       "Anvil_Log", "Workbench"]
const TREES := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4",
                "CommonTree_5", "Pine_1", "Pine_2", "Pine_3"]
const BUSHES := ["Bush_Common", "Bush_Common_Flowers"]

## SHARED MATERIALS. The house glb is exported with NO embedded textures
## (49.8 MB -> 0.75 MB). The kit's 26 textures live in the project ONCE, at
## 25.2 MB total, and every house points at the same StandardMaterial3D
## resources. Roof variants are built once at startup, not per instance.
const KIT_MATS := "res://assets/kit/materials/"
const KIT_MAT_NAMES := ["MI_Brick", "MI_UnevenBrick", "MI_Plaster", "MI_RockTrim",
                        "MI_RoundTiles", "MI_WoodTrim", "MI_WoodTrim_Wear",
                        "MI_WindowGlass", "MI_MetalOrnaments", "MI_Vine",
                        "MI_Cobble", "MI_Grass"]

## roof tint per livery. red is left neutral - the kit's tiles are already
## terracotta, so tinting it red would just oversaturate.
const LIVERY_TINT := {
    "blue":   Color(0.58, 0.68, 0.95),
    "green":  Color(0.62, 0.84, 0.60),
    "red":    Color(1.00, 1.00, 1.00),
    "yellow": Color(1.00, 0.88, 0.52),
}

const SETBACK := 6.0          # road centreline -> facade
const ROAD_W := 9.0

## ---------------------------------------------------------------- terrain
## Bellmire is a valley market town, so the ground is a bowl: a FLAT floor
## under the built area and hills rising beyond it. Flat-in-the-middle is not
## laziness - it means streets stay walkable and houses never straddle a
## slope, without needing a separate flattening pass over road cells.
const VALLEY_R := 150.0        # radius of the flat floor
const HILL_RISE := 26.0        # how high the rim gets
var _noise: FastNoiseLite
var _ridges: FastNoiseLite
const MOUNTAIN := Vector3(40.0, 175.0, -470.0)   # x, peak height, z
const MOUNTAIN_R := 120.0

## ---------------------------------------------------------------- river
## Bellmire is a valley MARKET town, so a river runs through the valley,
## south of the built core. It is a world-space polyline, not hex cells: it
## has to bend freely and cut a gorge where it leaves through the hills.
## Water sits at a fixed level; the ground is carved under it with a smooth
## bank so there is no cliff edge at the waterline.
const RIVER_W := 7.0           # half-width of open water
const RIVER_BANK := 9.0        # extra width over which the bank slopes in
const RIVER_BED := -2.6
const WATER_Y := -0.9
## D12: the ford west of the bridge (valley.gd) - a gravel bar just above the water
const FORD_X := -150.0
const FORD_Y := -0.75
var ford_x := FORD_X
var valley = null              # D12: Valley - the country beyond the wall
var river_pts: PackedVector3Array = PackedVector3Array()
var _bridge_z := 0.0

var district_of := {}         # Vector2i -> district id
var centre_of := {}           # district id -> Vector2i
var livery_of := {}           # district id -> livery
var road_cells := {}          # Vector2i -> true
var plots := []               # {cell, pos, yaw, district}
var _mat := {}                # material name -> shared resource
var _roof := {}               # livery -> shared tinted roof material
var _scene := {}              # shape key -> PackedScene
var square := {}              # Vector2i -> true, the market square
var _props_made := 0
var _nature_made := 0
var _rejected := 0
var _overlap_dropped := 0
var _wall_info := {}
var wall_parts: Array = []     # wall blocks, merlons, towers, gate arches (D3: palisade -> stone)
var growth = null              # scripts/growth.gd - what the town level shows (D3)
var _sound_level := 0          # S1: the last level shown (the fanfare plays only going up)
var _scar := Vector3.ZERO      # centre of the wild-magic scar (dungeon mouth beyond it)
var _north_from := Vector3.ZERO  # where the Delvers' Road leaves the ring
var _scar_info := {}
var _fields := []             # [centre, fwd, side, half_w, half_d]
var farms := []
var _farm_frames := []       # [hp, fw, sd, side sign]
var animals: Array = []
var roster: Roster
var chat: ChatCmd
var heroes := {}             # user_id -> HeroBody
var feed: Array = []
## D6: Bellmire's named people and their days (scripts/notables.gd)
var notables: Notables
## the valley's stock (Economy: a port of the old Sim). Delves bring ore,
## stone, salvaged gear and potions home into it.
var economy: Economy
## the viewers' party goes in together: once nobody queued is still on the road
## to the scar (a few seconds after the last arrives), or 45 s after the first
## arrival with whoever is there - and never while their last delve is below
var _muster_t := -1.0
var _since_last := 0.0

func _viewer_muster(delta: float) -> void:
    if _muster_t < 0.0 or _at_mouth.is_empty() or delve != null:
        return
    _muster_t += delta
    _since_last += delta
    var on_road := 0
    for uid in chat.away:
        if String(chat.away[uid]) == "on the road to the scar":
            on_road += 1
    if (on_road == 0 and _since_last > 4.0) or _muster_t > 45.0:
        _muster_t = -1.0
        _begin_delve()
var raids: Raids
var adventurers: Adventurers
var daylight: Daylight
var persist := false
var _save_t := 30.0
var _shop_frame := {}          # kind -> [yard, side, fwd]
var _piles := {}               # good -> [count, Node3D holder]

## The stock you can SEE: an ore heap in the smithy yard, salvaged gear laid
## out at the armourer's, potions on the apothecary's shelf. Rebuilt only when
## a visible count changes.
func _stock_piles() -> void:
    if economy == null:
        return
    _pile("ore", clampi(int(economy.stock["ore"] / 3.0), 0, 14))
    _pile("gear", clampi(int(economy.stock["gear"]), 0, 8))
    _pile("potion", clampi(int(economy.stock["potion"]), 0, 10))

func _pile(good: String, n: int) -> void:
    var old: Array = _piles.get(good, [-1, null])
    if int(old[0]) == n:
        return
    if old[1] != null and is_instance_valid(old[1]):
        (old[1] as Node).queue_free()
    var holder := Node3D.new()
    holder.name = "pile_" + good
    add_child(holder)
    _piles[good] = [n, holder]
    match good:
        "ore":
            if not _shop_frame.has("blacksmith"):
                return
            var fr: Array = _shop_frame["blacksmith"]
            var c: Vector3 = fr[0] + fr[1] * -3.0 + fr[2] * -1.65   # between the whetstone and the metal crate, clear of the anvil
            var ore := StandardMaterial3D.new()
            ore.albedo_color = Color(0.30, 0.29, 0.33)
            ore.roughness = 0.55
            ore.metallic = 0.35
            var rust := StandardMaterial3D.new()
            rust.albedo_color = Color(0.52, 0.30, 0.18)
            rust.roughness = 0.8
            # a mound: a ring on the ground, the rest stacked toward the middle
            for i in n:
                var ring := 0 if i < 7 else 1
                var a := float(i) * 2.399
                var r := (0.6 if ring == 0 else 0.25) + 0.05 * float(i % 3)
                var q := c + Vector3(cos(a) * r, 0, sin(a) * r)
                var g := height_at(q.x, q.z) + (0.0 if ring == 0 else 0.32)
                _pile_item(holder, NATURE + ("Rock_Medium_%d.gltf" % (1 + i % 3)), Vector3(q.x, g, q.z), a, 0.32, ore if i % 4 != 3 else rust)
        "gear":
            if not _shop_frame.has("armorer"):
                return
            var fr: Array = _shop_frame["armorer"]
            # laid out in a neat row along the fence: blade, shield, blade ...
            for i in n:
                var q: Vector3 = fr[0] + fr[1] * (-3.1 + float(i % 4) * 0.55) + fr[2] * (-1.0 - float(i / 4) * 0.9)
                var nm := "Sword_Bronze.gltf" if i % 2 == 0 else "Shield_Wooden.gltf"
                var it := _pile_item(holder, PROPS + nm, Vector3(q.x, height_at(q.x, q.z) + 0.04, q.z), atan2(fr[2].x, fr[2].z), PROP_SCALE, null)
                if it:
                    it.rotation.x = -PI * 0.5      # lying flat on the ground
        "potion":
            var sh = _shop_frame.get("apo_shelf")
            if sh == null or not is_instance_valid(sh):
                return
            var shelf: Node3D = sh
            var b := shelf.global_transform.basis
            var top := _top(shelf)
            var nms := ["Potion_1.gltf", "Potion_2.gltf", "Potion_4.gltf", "Bottle_1.gltf"]
            for i in n:
                var dx := -0.72 + float(i) * 0.16
                var q := shelf.global_position + b.x.normalized() * dx
                _pile_item(holder, PROPS + String(nms[i % 4]), Vector3(q.x, top - 0.02, q.z), shelf.rotation.y + float(i) * 0.7, PROP_SCALE * 0.8, null)

func _pile_item(holder: Node3D, path: String, at: Vector3, yaw: float, s: float, mat: Material) -> Node3D:
    if not ResourceLoader.exists(path):
        return null
    if not _scene.has(path):
        _scene[path] = load(path)
    var n: Node3D = _scene[path].instantiate()
    n.scale = Vector3.ONE * s
    n.position = at
    n.rotation.y = yaw
    holder.add_child(n)
    if mat:
        for m in n.find_children("*", "MeshInstance3D", true, false):
            (m as MeshInstance3D).material_override = mat
    return n
var stores: Dictionary:
    get: return economy.stock if economy else {}

func receive_haul(h: Dictionary) -> void:
    for k in h:
        economy.add(String(k), float(h[k]))
    _stock_piles()          # on-screen event lines (anonymous IRC is read-only)
var delve: Delve = null
var _at_mouth: Array = []
var _birds := []
var _pens := []
var _pulses := []             # [light, base energy, speed, phase]
var _furniture := {}
var docks := []               # [dock end Vector3, forward Vector3]
var anglers: Array = []
var fishing_log: Array = []     # every catch: {who, item, value}
var _sites := []             # workplaces outside the wall: {landmark, door, door_in}
var _spinners := []           # [node, axis Vector3, rad/s]
var landmarks := {}           # key -> [pos, fwd]
var _house_box := {}          # shape -> [half extents Vector2, centre offset Vector2]
var _house_door := {}         # shape -> local door position (street-most Door_* node)
var _road_segs := []          # [a, b, half_width] - every carriageway
var _objs := []               # [pos, radius] - structures nothing may overlap
var shops := []               # [type, pos, fwd]
var towers := []              # Vector3
var _stalls := []             # [stall pos, yaw the stall faces]
var people: Array[Townsfolk] = []
var _market_pos := Vector3.ZERO

func _ready() -> void:
    economy = Economy.new()
    economy.town = self
    add_child(economy)
    economy.changed.connect(_stock_piles)
    raids = Raids.new()
    raids.town = self
    raids.economy = economy
    add_child(raids)
    adventurers = Adventurers.new()
    adventurers.setup(self)
    add_child(adventurers)
    adventurers.call_deferred("found")
    daylight = Daylight.new()
    add_child(daylight)
    daylight.call_deferred("setup", self)
    # sound and music (assets/audio, CC0): world sounds, day/night/raid music, the bell
    # (test hook: JESTS_NO_SFX=1 leaves it out)
    if OS.get_environment("JESTS_NO_SFX") == "":
        var sfx := Sfx.new()
        sfx.name = "Sfx"
        add_child(sfx)
        sfx.setup(self)
    # the player's own eye (only when the game is played, not under a test tool)
    if not OS.get_cmdline_args().has("--script"):
        var eye := RtsCamera.new()
        add_child(eye)
        eye.call_deferred("setup", self)
        # live Twitch chat, read only (user://twitch.cfg: channel, enabled, ignore)
        var tw := TwitchChat.new()
        tw.name = "TwitchChat"
        add_child(tw)
        tw.call_deferred("setup", self)
        # Twitch phase 2 (T1): bits, subs, follows, channel points, chat replies as the bot
        # (tokens in user://; [twitch] eventsub=false in user://twitch.cfg turns it off)
        var es := TwitchEventSub.new()
        es.name = "TwitchEventSub"
        add_child(es)
        es.call_deferred("setup", self)
        # W1a: the viewer hub's snapshot - one Supabase row every 60 s (key in
        # user://supabase.json; no key = off, quietly)
        var snap := SnapshotPublisher.new()
        snap.name = "SnapshotPublisher"
        add_child(snap)
        snap.call_deferred("setup", self)
        var board := LeaderboardPanel.new()
        add_child(board)
        board.call_deferred("setup", roster)
    call_deferred("_stock_piles")
    roster.load_all() if roster and roster.has_method("load_all") else null
    var hud := FeedHUD.new()
    hud.source = feed
    add_child(hud)
    _init_noise()
    _init_river()
    _find_scar()
    _load_materials()
    _pick_centres()
    _assign_hexes()
    _colour_by_adjacency()
    _lay_roads()
    _make_square()
    _measure_houses()
    _plant_landmarks()
    _plots_from_roads()
    _resolve_overlaps()
    _pick_north_road()
    _clear_gate_lanes()
    _collect_road_segs()
    if _north_from != Vector3.ZERO:
        _road_segs.append([_north_from, _scar, 3.6])
    # HD: the scar road and gate lanes are only known now - last sweep so no
    # house is left standing on any of them
    # (the south road to the bridge is laid later, in _build: count it now)
    _road_segs.append([Vector3(0, 0, 60.0), Vector3(0, 0, river_z_fast(0.0)), 3.4])
    plots = plots.filter(func(pl) -> bool: return pl.has("landmark") or not _rect_on_road(_rect(pl)))
    _road_segs.pop_back()
    _pick_shops()
    _pick_towers()
    _build()
    if OS.get_environment("JESTS_NO_NAV") != "1":     # test hook: old street routing
        _bake_nav()
    _spawn_people()
    _spawn_animals()
    _spawn_garrison()
    _start_guild()

func _districts() -> Array:
    var d = Lore.districts()
    if d.is_empty():
        d = [{"id": "keep"}, {"id": "market"}, {"id": "craft"}, {"id": "temple"},
             {"id": "homes_s"}, {"id": "homes_w"}, {"id": "garrison"}, {"id": "mill"}]
    return d

func _pick_centres() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261108
    var tries := 0
    for d in _districts():
        var id := String(d.get("id", "d%d" % centre_of.size()))
        while true:
            tries += 1
            var c := Vector2i(rng.randi_range(3, Hex.COLS - 4),
                              rng.randi_range(3, Hex.ROWS - 4))
            var ok := true
            for other in centre_of.values():
                if Hex.dist(c, other) < 4.0:
                    ok = false
                    break
            if ok or tries > 4000:
                centre_of[id] = c
                break

func _assign_hexes() -> void:
    for cell in Hex.all_cells():
        var best: String = ""
        var bestd := 1e9
        for id in centre_of:
            var dd := Hex.dist(cell, centre_of[id])
            if dd < bestd:
                bestd = dd
                best = id
        district_of[cell] = best

func _colour_by_adjacency() -> void:
    var adj := {}
    for id in centre_of:
        adj[id] = {}
    for cell in district_of:
        var a: String = district_of[cell]
        for n in Hex.neighbours(cell):
            var b = district_of.get(n, "")
            if b != "" and b != a:
                adj[a][b] = true
    var ids := centre_of.keys()
    ids.sort_custom(func(x, y): return adj[x].size() > adj[y].size())
    for id in ids:
        var taken := {}
        for nb in adj[id]:
            if livery_of.has(nb):
                taken[livery_of[nb]] = true
        var chosen: String = LIVERIES[0]
        for lv in LIVERIES:
            if not taken.has(lv):
                chosen = lv
                break
        livery_of[id] = chosen

## Walk a hex line by repeatedly stepping to whichever neighbour gets closest
## to the target. Cheap, always terminates, and the wander reads as organic.
func _walk(a: Vector2i, b: Vector2i) -> void:
    var cur := a
    var guard := 0
    while cur != b and guard < 400:
        guard += 1
        road_cells[cur] = true
        var best := cur
        var bestd := Hex.dist(cur, b)
        for n in Hex.neighbours(cur):
            var dd := Hex.dist(n, b)
            if dd < bestd:
                bestd = dd
                best = n
        if best == cur:
            break
        cur = best
    road_cells[b] = true

## Nearest hex cell to a world position. Cheap over 437 cells and saves
## converting world coords back into offset coords by hand.
func _cell_near(w: Vector3) -> Vector2i:
    var best := Vector2i(0, 0)
    var bestd := 1e20
    for cell in Hex.all_cells():
        var d: float = Hex.pos(cell.x, cell.y).distance_squared_to(w)
        if d < bestd:
            bestd = d
            best = cell
    return best

func _lay_roads() -> void:
    ## A spine alone left the town one frontage deep. Lay a spine, a ring
    ## around the core, cross streets between them, then a branch to each
    ## district centre. Blocks only appear where roads enclose something.
    var mid := int(Hex.ROWS / 2)
    _walk(Vector2i(1, mid), Vector2i(Hex.COLS - 2, mid))

    # ring: eight waypoints on a circle, walked consecutively
    var rx := Hex.COLS * Hex.COL_W * 0.30
    var rz := Hex.ROWS * Hex.ROW_H * 0.32
    var ring: Array[Vector2i] = []
    for i in range(8):
        var a := TAU * float(i) / 8.0
        ring.append(_cell_near(Vector3(cos(a) * rx, 0.0, sin(a) * rz)))
    for i in range(ring.size()):
        _walk(ring[i], ring[(i + 1) % ring.size()])

    # cross streets: a few verticals tying the ring to the spine
    for frac in [0.28, 0.5, 0.72]:
        var cx := int(round(float(Hex.COLS - 1) * frac))
        var top := _cell_near(Vector3(Hex.pos(cx, mid).x, 0.0, -rz))
        var bot := _cell_near(Vector3(Hex.pos(cx, mid).x, 0.0, rz))
        _walk(top, bot)

    for id in centre_of:
        var c: Vector2i = centre_of[id]
        _walk(Vector2i(clampi(c.x, 1, Hex.COLS - 2), mid), c)

## The market district's heart is cleared and paved. A town needs somewhere
## that is neither a street nor a house.
func _make_square() -> void:
    if not centre_of.has("market"):
        return
    var c: Vector2i = centre_of["market"]
    square[c] = true
    _market_pos = Hex.pos(c.x, c.y)
    _market_pos.y = 0.0
    for n in Hex.neighbours(c):
        square[n] = true

func _plots_from_roads() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    ## density per district: dense trades, looser homes, sparse mill
    var density := {"market": 0.95, "craft": 0.92, "keep": 0.85, "garrison": 0.85,
                    "temple": 0.75, "homes_s": 0.70, "homes_w": 0.70, "mill": 0.40}
    for cell in district_of:
        if road_cells.has(cell) or square.has(cell):
            continue
        # a plot must touch a road, and it faces that road
        var front := Vector2i(-999, -999)
        for n in Hex.neighbours(cell):
            if road_cells.has(n):
                front = n
                break
        if front.x == -999:
            continue
        var id: String = district_of[cell]
        if rng.randf() > float(density.get(id, 0.7)):
            continue
        var cp := Hex.pos(cell.x, cell.y)
        var rp := Hex.pos(front.x, front.y)
        var dir := (rp - cp)
        dir.y = 0.0
        if dir.length() < 0.001:
            continue
        dir = dir.normalized()
        # FACADE at SETBACK from the road centre, so the centre sits further back
        var shapes: Array = DISTRICT_SHAPES.get(id, ["a"])
        var shape: String = String(shapes[rng.randi() % shapes.size()])
        var depth: float = float(HOUSES[shape]["depth"])
        var base := rp - dir * (SETBACK + depth * 0.5)
        if river_dist(base.x, base.z) < RIVER_W + RIVER_BANK + depth * 0.5:
            continue
        # the glb's street side faces +Z in local space
        var yaw := atan2(dir.x, dir.z)
        # along-street axis, so a frontage can carry a short terrace instead of
        # one lonely house per 14 m hex
        var along := Vector3(-dir.z, 0.0, dir.x)
        ## over-propose; _resolve_overlaps() keeps only what fits
        var n_here := 3
        for k in range(n_here):
            var hw: float = (_house_box[shape][0] as Vector2).x * 2.0 if _house_box.has(shape) else 8.0
            var off := (float(k) - (float(n_here) - 1.0) * 0.5) * (hw + 1.2)
            var pos := base + along * off
            pos += Vector3(rng.randf_range(-0.35, 0.35), 0.0,
                           rng.randf_range(-0.35, 0.35))
            plots.append({"cell": cell, "pos": pos,
                          "yaw": yaw + rng.randf_range(-0.03, 0.03),
                          "district": id, "shape": shape})
        # a back rank behind the frontage, so the blocks the ring encloses
        # actually fill in instead of leaving a hollow middle
        for bk in [-1.0, 1.0]:
            if rng.randf() > 0.8:
                continue
            var bshape := String(shapes[rng.randi() % shapes.size()])
            var back_pos := base - dir * (depth + 2.6)
            back_pos += along * (float(bk) * 5.2 + rng.randf_range(-0.8, 0.8))
            plots.append({"cell": cell, "pos": back_pos, "back": true,
                          "yaw": yaw + PI + rng.randf_range(-0.08, 0.08),
                          "district": id, "shape": bshape})

func _init_river() -> void:
    ## a gentle double-sine meander, kept clear of the plots (they reach about
    ## z = 95) so the river never runs through a house
    river_pts = PackedVector3Array()
    var x := -700.0
    while x <= 700.0:
        var z := 125.0 + 9.0 * sin(x * 0.017) + 5.0 * sin(x * 0.045 + 1.3)
        river_pts.append(Vector3(x, 0.0, z))
        x += 15.0

## Distance from a point to the river centreline, in the XZ plane.
func river_dist(x: float, z: float) -> float:
    var best := 1e9
    var p := Vector2(x, z)
    for i in range(river_pts.size() - 1):
        var a := Vector2(river_pts[i].x, river_pts[i].z)
        var b := Vector2(river_pts[i + 1].x, river_pts[i + 1].z)
        var ab := b - a
        var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
        best = minf(best, p.distance_to(a + ab * t))
    return best

func _init_noise() -> void:
    _noise = FastNoiseLite.new()
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    _noise.seed = 1108
    _noise.frequency = 0.0045
    _ridges = FastNoiseLite.new()
    _ridges.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
    _ridges.fractal_octaves = 4
    _ridges.seed = 2211
    _ridges.frequency = 0.0035

## Ground height at a world position. Everything placed on the map must use
## this - a prop that ignores it floats or sinks once the rim starts rising.
func height_at(x: float, z: float) -> float:
    var r := sqrt(x * x + z * z) / VALLEY_R
    var ripple := _noise.get_noise_2d(x, z)
    var h: float
    if r <= 1.0:
        # floor: essentially flat, a few cm of unevenness so it is not glass
        h = ripple * 0.35
    else:
        # foothills, then the ring of mountains the valley sits in
        var t: float = minf((r - 1.0), 3.4)
        h = HILL_RISE * pow(t, 1.55) * (0.75 + 0.45 * ripple) + ripple * 0.35
        h += _ridges.get_noise_2d(x, z) * 22.0 * smoothstep(1.8, 3.0, r)
    # Lore: "a meadow sits under a mountain." The mountain stands north of
    # Bellmire; the dungeon's scar opens at its foot.
    var md := Vector2(x - MOUNTAIN.x, z - MOUNTAIN.z).length()
    h += MOUNTAIN.y * exp(-(md * md) / (2.0 * MOUNTAIN_R * MOUNTAIN_R))
    if river_pts.size() > 1:
        var d := river_dist(x, z)
        if d < RIVER_W + RIVER_BANK:
            # 1 in the channel, easing to 0 across the bank
            var k := 1.0 - smoothstep(RIVER_W * 0.6, RIVER_W + RIVER_BANK, d)
            h = lerpf(h, RIVER_BED, k)
            # D12: the ford - a gravel bar across the channel, just above the water
            var fd := absf(x - FORD_X)
            if fd < 7.5:
                h = lerpf(h, maxf(h, FORD_Y), 1.0 - smoothstep(4.0, 7.5, fd))
    return h

func _ground_mesh(extent: float, steps: int) -> ArrayMesh:
    var verts := PackedVector3Array()
    var uvs := PackedVector2Array()
    var idx := PackedInt32Array()
    var step := (extent * 2.0) / float(steps)
    for j in range(steps + 1):
        for i in range(steps + 1):
            var x := -extent + float(i) * step
            var z := -extent + float(j) * step
            verts.append(Vector3(x, height_at(x, z), z))
            uvs.append(Vector2(float(i) / float(steps), float(j) / float(steps)))
    for j in range(steps):
        for i in range(steps):
            var a := j * (steps + 1) + i
            var b := a + 1
            var c := a + steps + 1
            var d := c + 1
            # winding: Godot culls back faces, and the other order left the
            # ground invisible from above
            idx.append_array([a, b, c, b, d, c])
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = verts
    arr[Mesh.ARRAY_TEX_UV] = uvs
    arr[Mesh.ARRAY_INDEX] = idx
    var m := ArrayMesh.new()
    m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    # normals from the geometry rather than hand-computed
    var st := SurfaceTool.new()
    st.create_from(m, 0)
    st.generate_normals()
    st.generate_tangents()
    return st.commit()

## A road runs south from the ring and crosses the river on a timber bridge.
## The hex grid stops short of the river, so this road is laid in world space.
## The bridge deck spans the whole carved channel and both banks, and stays
## level - the road never dips into the gorge.
func _build_bridge() -> void:
    var x0 := 0.0
    # where the river crosses x = 0
    var rz := 0.0
    var best := 1e9
    var z := 60.0
    while z < 200.0:
        var d := river_dist(x0, z)
        if d < best:
            best = d
            rz = z
        z += 0.5
    var half := RIVER_W + RIVER_BANK + 1.5
    var deck_y := 0.55
    ## MI_WoodTrim is a TRIM SHEET authored for the kit's own UVs; on a plain
    ## BoxMesh it samples the wrong strip and half the deck came out white.
    ## A triplanar copy tiles the grain in world space instead.
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.62, 0.48, 0.36)
    var road = _mat.get("MI_Cobble")
    # approach roads, both sides
    var segs := [[74.0, rz - half], [rz + half, rz + half + 34.0]]
    _road_segs.append([Vector3(x0, 0.0, 70.0), Vector3(x0, 0.0, rz + half + 34.0), 3.2])
    for sg in segs:
        var za: float = float(sg[0])
        var zb: float = float(sg[1])
        var zz := za
        while zz < zb:
            var z2: float = minf(zz + 6.0, zb)
            var q := MeshInstance3D.new()
            var qm := PlaneMesh.new()
            qm.size = Vector2(6.0, (z2 - zz) + 1.0)
            q.mesh = qm
            q.material_override = road
            var mz := (zz + z2) * 0.5
            q.position = Vector3(x0, maxf(height_at(x0, mz), 0.0) + 0.07, mz)
            add_child(q)
            zz = z2
    # deck
    var deck := MeshInstance3D.new()
    var dm := BoxMesh.new()
    dm.size = Vector3(6.4, 0.45, half * 2.0 + 1.0)
    deck.mesh = dm
    deck.material_override = wood
    deck.position = Vector3(x0, deck_y, rz)
    add_child(deck)
    # railings and posts
    for sx in [-1.0, 1.0]:
        var rail := MeshInstance3D.new()
        var rm := BoxMesh.new()
        rm.size = Vector3(0.18, 0.18, half * 2.0 + 1.0)
        rail.mesh = rm
        rail.material_override = wood
        rail.position = Vector3(x0 + sx * 3.0, deck_y + 1.05, rz)
        add_child(rail)
        var pz := rz - half
        while pz <= rz + half + 0.1:
            var post := MeshInstance3D.new()
            var pm2 := BoxMesh.new()
            pm2.size = Vector3(0.24, 1.1, 0.24)
            post.mesh = pm2
            post.material_override = wood
            post.position = Vector3(x0 + sx * 3.0, deck_y + 0.55, pz)
            add_child(post)
            pz += 2.4
    # piers down into the water
    for oz in [-RIVER_W * 0.55, RIVER_W * 0.55]:
        for sx in [-1.0, 1.0]:
            var pier := MeshInstance3D.new()
            var prm := BoxMesh.new()
            prm.size = Vector3(0.6, 3.6, 0.6)
            pier.mesh = prm
            pier.material_override = wood
            pier.position = Vector3(x0 + sx * 2.4, deck_y - 1.9, rz + float(oz))
            add_child(pier)
    _bridge_z = rz

func _build_water() -> void:
    ## ONE continuous strip along the river, not a transparent quad per
    ## segment - overlapping transparent quads double up and band.
    var verts := PackedVector3Array()
    var idx := PackedInt32Array()
    var n := river_pts.size()
    for i in range(n):
        var prev := river_pts[max(i - 1, 0)]
        var next := river_pts[min(i + 1, n - 1)]
        var d := (next - prev).normalized()
        var side := Vector3(-d.z, 0.0, d.x) * (RIVER_W * 1.15)
        var c := river_pts[i]
        verts.append(Vector3(c.x, WATER_Y, c.z) - side)
        verts.append(Vector3(c.x, WATER_Y, c.z) + side)
    for i in range(n - 1):
        var a := i * 2
        idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = verts
    arr[Mesh.ARRAY_INDEX] = idx
    var m := ArrayMesh.new()
    m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    var st := SurfaceTool.new()
    st.create_from(m, 0)
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    var wm := ShaderMaterial.new()
    wm.shader = load("res://assets/shaders/water.gdshader")
    mi.material_override = wm
    add_child(mi)

func _load_materials() -> void:
    for n in KIT_MAT_NAMES:
        var path: String = KIT_MATS + String(n) + ".tres"
        if ResourceLoader.exists(path):
            _mat[n] = load(path)
        else:
            push_warning("town: missing material " + path)
    # one tinted roof material per livery, built ONCE
    var base = _mat.get("MI_RoundTiles")
    for lv in LIVERIES:
        if base == null:
            continue
        var d := base.duplicate() as StandardMaterial3D
        d.albedo_color = LIVERY_TINT.get(lv, Color.WHITE)
        _roof[lv] = d

## Swap the glb's textureless materials for the project's shared ones, by name.
## glTF keeps material names, so MI_Brick in Blender arrives as MI_Brick here.
func _dress(node: Node, livery: String) -> void:
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        var cnt := mi.get_surface_override_material_count()
        for i in range(cnt):
            var m := mi.get_active_material(i)
            if m == null:
                continue
            var parts: PackedStringArray = String(m.resource_name).split(".")
            var key: String = parts[0] if parts.size() > 0 else ""
            if key == "MI_RoundTiles" and _roof.has(livery):
                mi.set_surface_override_material(i, _roof[livery])
            elif _mat.has(key):
                mi.set_surface_override_material(i, _mat[key])
    for c in node.get_children():
        _dress(c, livery)

func _build() -> void:
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.29, 0.46, 0.74)
    sm.sky_horizon_color = Color(0.72, 0.79, 0.86)
    sm.ground_bottom_color = Color(0.46, 0.52, 0.42)
    sm.ground_horizon_color = Color(0.70, 0.76, 0.80)
    sky.sky_material = sm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.85
    e.ssao_enabled = true
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    # distance haze: far ridges fade into the sky instead of ending hard
    e.fog_enabled = true
    e.fog_light_color = Color(0.70, 0.77, 0.84)
    e.fog_density = 0.0011
    e.fog_aerial_perspective = 0.6
    e.fog_sky_affect = 0.15
    we.environment = e
    add_child(we)

    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(38.0), 0.0)
    sun.light_energy = 1.5
    sun.shadow_enabled = true
    add_child(sun)

    # continuous ground - there are no hex plates in this build
    var gnd := MeshInstance3D.new()
    ## big enough that the mountains close the horizon - no void past the edge
    var extent := 760.0
    gnd.mesh = _ground_mesh(extent, 380)
    ## dirt in town fading to tinted grass outside it - see ground.gdshader
    var gsm := ShaderMaterial.new()
    gsm.shader = load("res://assets/shaders/ground.gdshader")
    var T := "res://assets/kit/textures/"
    gsm.set_shader_parameter("dirt_tex", load(T + "T_Dirt_BaseColor.jpg"))
    gsm.set_shader_parameter("dirt_nrm", load(T + "T_Dirt_Normal.jpg"))
    gsm.set_shader_parameter("grass_tex", load(T + "T_Meadow_BaseColor.jpg"))
    gsm.set_shader_parameter("grass_nrm", load(T + "T_Meadow_Normal.jpg"))
    gsm.set_shader_parameter("scar_c", _scar)
    gsm.set_shader_parameter("scar_r", SCAR_R)
    gsm.set_shader_parameter("town_mask", _town_mask())
    gsm.set_shader_parameter("mask_half", MASK_HALF)
    gnd.material_override = gsm
    add_child(gnd)

    # road surface: one quad per road cell, overlapping into a ribbon
    var rmat = _mat.get("MI_Cobble")
    if rmat == null:
        rmat = StandardMaterial3D.new()
        rmat.albedo_color = Color(0.37, 0.36, 0.34)
        rmat.roughness = 0.95
    ## A quad per hex paved a 14 m plaza. Draw a ribbon along each road-to-road
    ## link instead, at the real carriageway width.
    for cell in square:
        var sq := MeshInstance3D.new()
        var sqm := PlaneMesh.new()
        sqm.size = Vector2(Hex.COL_W * 1.1, Hex.ROW_H * 1.25)
        sq.mesh = sqm
        sq.material_override = rmat
        var sp := Hex.pos(cell.x, cell.y)
        sq.position = Vector3(sp.x, height_at(sp.x, sp.z) + 0.05, sp.z)
        add_child(sq)

    var done := {}
    for cell in road_cells:
        var a := Hex.pos(cell.x, cell.y)
        for n in Hex.neighbours(cell):
            if not road_cells.has(n):
                continue
            var key: String = ""
            if cell.x < n.x or (cell.x == n.x and cell.y < n.y):
                key = "%d,%d|%d,%d" % [cell.x, cell.y, n.x, n.y]
            else:
                key = "%d,%d|%d,%d" % [n.x, n.y, cell.x, cell.y]
            if done.has(key):
                continue
            done[key] = true
            var b := Hex.pos(n.x, n.y)
            var d := b - a
            var L := d.length()
            if L < 0.01:
                continue
            var q := MeshInstance3D.new()
            var qm := PlaneMesh.new()
            qm.size = Vector2(ROAD_W, L + ROAD_W * 0.6)
            q.mesh = qm
            q.material_override = rmat
            var mid3 := (a + b) * 0.5
            q.position = Vector3(mid3.x, height_at(mid3.x, mid3.z) + 0.06, mid3.z)
            q.rotation.y = atan2(d.x, d.z)
            add_child(q)

    for k in HOUSES:
        var hpath: String = String(HOUSES[k]["path"])
        if ResourceLoader.exists(hpath):
            _scene[k] = load(hpath)
        else:
            push_warning("town: missing " + hpath)
    _build_water()
    _build_bridge()
    _build_wall()
    if _scene.is_empty():
        return
    var vrng := RandomNumberGenerator.new()
    vrng.seed = 99
    for plot in plots:
        var shape: String = String(plot.get("shape", "a"))
        if not _scene.has(shape):
            shape = String(_scene.keys()[0])
        var h: Node3D = _scene[shape].instantiate()
        var hp: Vector3 = plot["pos"]
        hp.y += height_at(hp.x, hp.z)
        h.position = hp
        h.rotation.y = plot["yaw"]
        # cheap variety from one model. NOT a 180 yaw flip - that would turn
        # the door away from the street, which is the whole point of the plot.
        var sx := vrng.randf_range(0.93, 1.10)
        var sy := vrng.randf_range(0.95, 1.18)
        var sz := vrng.randf_range(0.93, 1.10)
        if not plot.has("landmark"):
            h.scale = Vector3(sx, sy, sz)
        plot["node"] = h
        if _house_door.has(shape):
            var dl: Vector3 = _house_door[shape]
            var dw := h.transform * dl        # town root sits at the origin
            var fw := _fwd(plot)
            plot["door_in"] = Vector3(dw.x, height_at(dw.x, dw.z), dw.z) - fw * 0.5
            plot["door"] = Vector3(dw.x, height_at(dw.x, dw.z), dw.z) + fw * 1.4
        add_child(h)
        var lv: String = String(livery_of.get(plot["district"], "red"))
        _dress(h, lv)

    _dress_square()
    _dress_landmarks()
    _build_watermill()
    _build_outworks()
    _build_docks()
    _dress_shops()
    _dress_doors()
    _build_towers()
    _street_furniture()
    _dress_streets()
    _scatter_nature()
    _build_scar()
    _build_fields()
    _build_farms()
    # D12: the valley beyond the wall - steadings, the Ashwood, the ford, the Old Footing
    valley = preload("res://scripts/valley.gd").new()
    add_child(valley)
    valley.setup(self)
    _scatter_country()
    _meadow()
    # D3: the town grows with its level - lots, upgrades, new buildings, the wall
    growth = preload("res://scripts/growth.gd").new()
    add_child(growth)
    growth.setup(self)
    growth.show_level(1, true)

## D3: economy.check_town_level calls this; quiet at the founding
func show_level(lv: int, quiet := false) -> void:
    if growth != null:
        growth.show_level(lv, quiet)
    _show_garrison(lv, quiet)
    # S1: a new level is a fanfare for the whole stream (flat, not in the world):
    # level_up, then quest_complete under the Chronicle line. Only on the way up.
    if not quiet and _sound_level > 0 and lv > _sound_level:
        Sfx.play("level_up", -2.0)
        get_tree().create_timer(1.6, true, false, true).timeout.connect(func() -> void:
            Sfx.play("quest_complete", -4.0))
    _sound_level = lv

## ---------------------------------------------------------------- dressing
func _spawn(dir_path: String, name: String, pos: Vector3, yaw: float,
            scale_f: float = 1.0) -> bool:
    var path := dir_path + name + ".gltf"
    if not ResourceLoader.exists(path):
        return false
    if not _scene.has(path):
        _scene[path] = load(path)
    var n: Node3D = _scene[path].instantiate()
    if dir_path == PROPS:
        scale_f *= PROP_SCALE
    pos.y += height_at(pos.x, pos.z)
    n.position = pos
    n.rotation.y = yaw
    if scale_f != 1.0:
        n.scale = Vector3.ONE * scale_f
    add_child(n)
    _solid_of(n)
    return true

## ---- HD walking: every solid piece of furniture leaves a footprint that the
## navigation mesh carves out, so nobody walks through tables, stalls, benches
var _solid_rects: Array = []
var _wall_solid: Array = []
var nav: TownNav = null

func _solid_of(n: Node3D) -> void:
    var box := AABB()
    var first := true
    var inv := n.global_transform.affine_inverse()
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var ab: AABB = (inv * (c as MeshInstance3D).global_transform) * (c as MeshInstance3D).get_aabb()
            box = ab if first else box.merge(ab)
            first = false
        for g in c.get_children():
            st.append(g)
    if first:
        return
    var sc := n.scale.x
    var he := Vector2(box.size.x, box.size.z) * 0.5 * sc
    if box.size.y * sc < 0.35 or maxf(he.x, he.y) < 0.2:
        return                  # rugs, mugs and flat things are walked over
    var yaw := n.rotation.y
    var ax := Vector2(cos(yaw), -sin(yaw))
    var az := Vector2(sin(yaw), cos(yaw))
    var cen := box.get_center() * sc
    var c2 := Vector2(n.position.x, n.position.z) + ax * cen.x + az * cen.z
    _solid_rects.append([c2, ax, az, he + Vector2(0.1, 0.1)])

func _bake_nav() -> void:
    var rects: Array = _solid_rects.duplicate()
    for plot in plots:
        var sh: String = String(plot.get("shape", "a"))
        if not _house_box.has(sh):
            continue
        var he: Vector2 = (_house_box[sh][0] as Vector2) * 1.04 + Vector2(0.15, 0.15)
        var off: Vector2 = _house_box[sh][1]
        var yaw: float = float(plot["yaw"])
        var ax := Vector2(cos(yaw), -sin(yaw))
        var az := Vector2(sin(yaw), cos(yaw))
        var pp: Vector3 = plot["pos"]
        rects.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, he])
    var solids: Array = []
    for o in _objs:
        if float(o[1]) <= 2.65:
            solids.append([o[0], float(o[1]) * 0.75])
    var extent := maxf(260.0, Vector2(_scar.x, _scar.z).length() + 40.0)
    var band: Array = []
    var x := -extent
    while x < extent:
        var x2 := x + 3.0
        # the bridge and (D12) the ford stay open
        if absf(x) > 6.0 and absf(x2) > 6.0 and absf((x + x2) * 0.5 - FORD_X) > 3.0:
            band.append([Vector3(x, 0, river_z_fast(x)), Vector3(x2, 0, river_z_fast(x2)), RIVER_W + 0.5])
        x = x2
    nav = TownNav.new()
    add_child(nav)
    nav.setup(self, extent, solids, rects, _wall_solid, band)

## river centreline z at x, straight from the meander formula (river_z searches)
func river_z_fast(x: float) -> float:
    return 125.0 + 9.0 * sin(x * 0.017) + 5.0 * sin(x * 0.045 + 1.3)

## The square is LAID OUT, not scattered: a well in the middle, stalls on a
## ring facing it, set between the streets that run into the square so no
## stall blocks a way in.
func _dress_square() -> void:
    if not centre_of.has("market"):
        return
    var cell: Vector2i = centre_of["market"]
    var c := Hex.pos(cell.x, cell.y)
    c.y = 0.0
    _market_pos = c
    _build_well(c)
    _objs.append([c, 2.2])
    var angs: Array[float] = []
    for n in Hex.neighbours(cell):
        var d := Hex.pos(n.x, n.y) - Hex.pos(cell.x, cell.y)
        angs.append(atan2(d.z, d.x))
    angs.sort()
    var rng := RandomNumberGenerator.new()
    rng.seed = 404
    for i in range(angs.size()):
        var a0: float = angs[i]
        var a1: float = angs[(i + 1) % angs.size()]
        if a1 <= a0:
            a1 += TAU
        var am := (a0 + a1) * 0.5
        var dir := Vector3(cos(am), 0.0, sin(am))
        var side := Vector3(-dir.z, 0.0, dir.x)
        var sp := c + dir * 13.5
        var face := atan2(-dir.x, -dir.z)        # front (+Z) toward the well
        var stall := "Stall_Empty" if i % 2 == 0 else "Stall_Cart_Empty"
        _props_made += int(_spawn(PROPS, stall, sp, face))
        _stalls.append([sp, face])
        _objs.append([sp, 2.6])
        var goods := ["Barrel_Apples", "FarmCrate_Apple", "FarmCrate_Carrot", "Crate_Wooden", "Barrel"]
        for k in range(2):
            var g: String = goods[rng.randi() % goods.size()]
            var off := side * (4.2 if k == 0 else -4.2) + dir * rng.randf_range(-0.6, 0.6)
            _props_made += int(_spawn(PROPS, g, sp + off, rng.randf_range(0.0, TAU)))
        if i % 2 == 1:
            _props_made += int(_spawn(PROPS, "Bench", c + dir * 5.0, atan2(dir.x, dir.z)))
        if i % 3 == 0:
            _props_made += int(_spawn(PROPS, "Banner_1", c + dir * 8.0 + side * 1.5, face))

func _stone() -> StandardMaterial3D:
    if _mat.has("_stone_tp"):
        return _mat["_stone_tp"]
    var src = _mat.get("MI_UnevenBrick")
    var m: StandardMaterial3D
    if src == null:
        m = StandardMaterial3D.new()
    else:
        m = (src as StandardMaterial3D).duplicate()
    ## world triplanar: wall blocks are SCALED unit boxes, so object-space UVs
    ## would stretch the bricks along every long segment.
    m.uv1_triplanar = true
    m.uv1_world_triplanar = true
    m.uv1_scale = Vector3(0.22, 0.22, 0.22)
    m.albedo_color = Color(0.82, 0.80, 0.76)
    _mat["_stone_tp"] = m
    return m

func _box(size: Vector3, pos: Vector3, mat: Material, yaw: float = 0.0) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat
    mi.position = pos
    mi.rotation.y = yaw
    add_child(mi)
    return mi

func _build_well(c: Vector3) -> void:
    var g := height_at(c.x, c.z)
    var ring := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 1.45
    cm.bottom_radius = 1.6
    cm.height = 1.1
    ring.mesh = cm
    ring.material_override = _stone()
    ring.position = Vector3(c.x, g + 0.55, c.z)
    add_child(ring)
    var water := MeshInstance3D.new()
    var wm := CylinderMesh.new()
    wm.top_radius = 1.15
    wm.bottom_radius = 1.15
    wm.height = 0.04
    water.mesh = wm
    var wmat := StandardMaterial3D.new()
    wmat.albedo_color = Color(0.04, 0.09, 0.11)
    wmat.roughness = 0.08
    water.material_override = wmat
    water.position = Vector3(c.x, g + 0.95, c.z)
    add_child(water)
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.62, 0.48, 0.36)
    for sx in [-1.25, 1.25]:
        _box(Vector3(0.22, 2.9, 0.22), Vector3(c.x + sx, g + 1.45, c.z), wood)
    _box(Vector3(2.9, 0.2, 0.2), Vector3(c.x, g + 2.55, c.z), wood)
    var roof := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(3.6, 1.1, 2.6)
    roof.mesh = pm
    roof.material_override = _roof.get("red", wood)
    roof.position = Vector3(c.x, g + 3.4, c.z)
    add_child(roof)

func _dress_streets() -> void:
    ## Props go against the FACADE, never in the carriageway - the same
    ## mistake the Blender props() made before it took a setback.
    var rng := RandomNumberGenerator.new()
    rng.seed = 505
    for plot in plots:
        if rng.randf() > 0.33:
            continue
        var yaw: float = float(plot["yaw"])
        var fwd := Vector3(sin(yaw), 0.0, cos(yaw))        # toward the street
        var side := Vector3(-fwd.z, 0.0, fwd.x)
        var pos: Vector3 = plot["pos"] + fwd * rng.randf_range(5.0, 6.4) \
                         + side * rng.randf_range(-3.4, 3.4)
        if plot.has("shop") or plot.has("landmark") or not is_clear(pos, 0.7, true):
            continue
        var nm: String = STREET_PROPS[rng.randi() % STREET_PROPS.size()]
        _props_made += int(_spawn(PROPS, nm, pos, rng.randf_range(0.0, TAU)))
        _objs.append([pos, 0.7])

func _scatter_nature() -> void:
    ## Only on cells with no road, no square and no plot, so nothing grows
    ## through a house or a street.
    var taken := {}
    for plot in plots:
        taken[plot["cell"]] = true
    var rng := RandomNumberGenerator.new()
    rng.seed = 606
    for cell in district_of:
        if road_cells.has(cell) or square.has(cell) or taken.has(cell):
            continue
        if rng.randf() > 0.45:
            continue
        var c := Hex.pos(cell.x, cell.y)
        for i in range(rng.randi_range(1, 3)):
            var a := rng.randf_range(0.0, TAU)
            var r := rng.randf_range(0.0, 5.0)
            var tp := c + Vector3(cos(a) * r, 0.0, sin(a) * r)
            if river_dist(tp.x, tp.z) < RIVER_W + 2.0:
                continue
            var lane_end := Hex.pos(Hex.COLS - 2, int(Hex.ROWS / 2))
            if absf(tp.z - lane_end.z) < 9.0 and absf(tp.x) > absf(lane_end.x) - 8.0:
                continue        # keep the gate lanes clear
            var is_tree := rng.randf() < 0.65
            if not is_clear(tp, 1.6 if is_tree else 0.8):
                _rejected += 1
                continue
            _objs.append([tp, 1.6 if is_tree else 0.8])
            var pool: Array = TREES if is_tree else BUSHES
            var nm: String = String(pool[rng.randi() % pool.size()])
            _nature_made += int(_spawn(NATURE, nm,
                c + Vector3(cos(a) * r, 0.0, sin(a) * r),
                rng.randf_range(0.0, TAU),
                rng.randf_range(0.8, 1.35) if is_tree else rng.randf_range(0.7, 1.1)))

## The spine is carried out to the wall later, so nothing may stand on that
## line - a house had been built right across the inside of the west gate.
func _clear_gate_lanes() -> void:
    var mid_row := int(Hex.ROWS / 2)
    var kept := []
    for plot in plots:
        var pp: Vector3 = plot["pos"]
        var lane := false
        for side in [-1.0, 1.0]:
            var end := Hex.pos(1 if side < 0.0 else Hex.COLS - 2, mid_row)
            if absf(pp.z - end.z) < 12.0 and pp.x * float(side) > absf(end.x) - 6.0:
                lane = true
        if _north_from != Vector3.ZERO and not plot.has("landmark") \
                and _seg_dist(pp, _north_from, _scar) < 9.0 + _plot_r(plot) * 0.6:
            lane = true
        if not lane:
            kept.append(plot)
    plots = kept

## A road as ONE strip that follows the ground at every vertex. Separate flat
## quads left steps and gaps as soon as the road met the rising hills.
func _road_strip(pts_in: Array[Vector3], w: float, dirt := false) -> void:
    if pts_in.size() < 2:
        return
    ## resample every 2 m: a long segment between two waypoints otherwise
    ## spans a hill as a straight line and disappears under the ground
    var pts: Array[Vector3] = [pts_in[0]]
    for i in range(1, pts_in.size()):
        var a: Vector3 = pts_in[i - 1]
        var b: Vector3 = pts_in[i]
        var n := maxi(1, int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 2.0)))
        for k in range(1, n + 1):
            pts.append(a.lerp(b, float(k) / float(n)))
    var verts := PackedVector3Array()
    var norms := PackedVector3Array()
    var idx := PackedInt32Array()
    for i in range(pts.size()):
        var a := pts[maxi(i - 1, 0)]
        var b := pts[mini(i + 1, pts.size() - 1)]
        var t := (b - a)
        t.y = 0.0
        t = t.normalized()
        var side := Vector3(-t.z, 0.0, t.x) * (w * 0.5)
        for sgn in [-1.0, 1.0]:
            var v: Vector3 = pts[i] + side * float(sgn)
            # lift more where the ground is steep, or the slope pokes through
            # between the 2 m samples
            var hh := height_at(v.x, v.z)
            var slope := absf(height_at(v.x + 1.0, v.z) - hh) + absf(height_at(v.x, v.z + 1.0) - hh)
            v.y = hh + 0.08 + slope * 0.35
            verts.append(v)
            norms.append(Vector3.UP)
    for i in range(pts.size() - 1):
        var a := i * 2
        idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = verts
    arr[Mesh.ARRAY_NORMAL] = norms
    arr[Mesh.ARRAY_INDEX] = idx
    var m := ArrayMesh.new()
    m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    for i in range(pts.size() - 1):
        _road_segs.append([pts[i], pts[i + 1], w * 0.5])
    var mi := MeshInstance3D.new()
    mi.mesh = m
    var mkey := "_path_strip" if dirt else "_road_strip"
    if not _mat.has(mkey):
        var rm: StandardMaterial3D = (_mat.get("MI_Grass" if dirt else "MI_Cobble") as StandardMaterial3D).duplicate()
        rm.cull_mode = BaseMaterial3D.CULL_DISABLED
        if dirt:
            rm.albedo_color = Color(0.78, 0.66, 0.52)
        _mat[mkey] = rm
    mi.material_override = _mat[mkey]
    add_child(mi)

## ---------------------------------------------------------------- town wall
## An ellipse fitted OUTSIDE every plot, broken where a road reaches it (a
## gate, flanked by towers, with a road running on into the country) and
## where the river cuts it (the water is the defence there).
const WALL_H := 5.0
const WALL_T := 1.6
func _build_wall() -> void:
    var ax0 := Hex.COLS * Hex.COL_W * 0.5
    var az0 := Hex.ROWS * Hex.ROW_H * 0.5
    var m := 0.0
    for plot in plots:
        var pp: Vector3 = plot["pos"]
        m = maxf(m, sqrt(pow(pp.x / ax0, 2.0) + pow(pp.z / az0, 2.0)))
    var ax := ax0 * m + 13.0
    var az := az0 * m + 13.0
    # every point a road actually runs through
    var road_pts: Array[Vector3] = []
    for cell in road_cells:
        road_pts.append(Hex.pos(cell.x, cell.y))
    var zz := 60.0
    while zz < _bridge_z:
        road_pts.append(Vector3(0.0, 0.0, zz))
        zz += 3.0
    if _north_from != Vector3.ZERO:
        var nl: Array[Vector3] = []
        var k2 := 0.0
        var L2 := _north_from.distance_to(_scar)
        while k2 <= L2:
            var q := _north_from.lerp(_scar, k2 / L2)
            road_pts.append(q)
            k2 += 3.0
    ## The spine stopped short of the wall, so no road ever reached it and
    ## there were no gates. Carry both ends of the spine out to the wall.
    var mid_row := int(Hex.ROWS / 2)
    var road = _mat.get("MI_Cobble")
    for side in [-1.0, 1.0]:
        var end := Hex.pos(1 if side < 0.0 else Hex.COLS - 2, mid_row)
        var x := absf(end.x) - 4.0
        var lane: Array[Vector3] = []
        while x < ax + 2.0:
            var rp := Vector3(x * float(side), 0.0, end.z)
            road_pts.append(rp)
            lane.append(rp)
            x += 3.0
        _road_strip(lane, 7.5)
    # sample the ellipse at ~3 m spacing
    var n := int((PI * (3.0 * (ax + az) - sqrt((3.0 * ax + az) * (ax + 3.0 * az)))) / 3.0)
    var pts: Array[Vector3] = []
    var kind: Array[int] = []     # 0 wall, 1 road gap, 2 river gap
    for i in range(n):
        var t := TAU * float(i) / float(n)
        var p := Vector3(ax * cos(t), 0.0, az * sin(t))
        var k := 0
        if river_dist(p.x, p.z) < RIVER_W + RIVER_BANK + 1.0:
            k = 2
        else:
            for rp in road_pts:
                if Vector2(rp.x - p.x, rp.z - p.z).length() < 9.0:
                    k = 1
                    break
        pts.append(p)
        kind.append(k)
    for i in range(n):
        if kind[i] == 0:
            var tg := Vector3(-ax * sin(TAU * float(i) / float(n)), 0.0, az * cos(TAU * float(i) / float(n))).normalized()
            _wall_solid.append([pts[i], tg])
    var stone := _stone()
    var blocks := MultiMesh.new()
    blocks.transform_format = MultiMesh.TRANSFORM_3D
    blocks.mesh = BoxMesh.new()
    var merl := MultiMesh.new()
    merl.transform_format = MultiMesh.TRANSFORM_3D
    merl.mesh = BoxMesh.new()
    var bx: Array[Transform3D] = []
    var mx: Array[Transform3D] = []
    for i in range(n):
        var j := (i + 1) % n
        if kind[i] != 0 or kind[j] != 0:
            continue
        var a := pts[i]
        var b := pts[j]
        var ha := height_at(a.x, a.z)
        var hb := height_at(b.x, b.z)
        var d := b - a
        var L := d.length() + 0.25
        var yaw := atan2(-d.z, d.x)
        var lo := minf(ha, hb) - 1.0
        var hi := maxf(ha, hb) + WALL_H
        var mid := (a + b) * 0.5
        var basis := Basis(Vector3.UP, yaw)
        bx.append(Transform3D(basis.scaled_local(Vector3(L, hi - lo, WALL_T)),
                              Vector3(mid.x, (lo + hi) * 0.5, mid.z)))
        var tng := d.normalized()
        for f in [-0.25, 0.25]:
            var mp := mid + tng * (L * float(f))
            mx.append(Transform3D(basis.scaled_local(Vector3(0.85, 0.9, WALL_T * 0.9)),
                                  Vector3(mp.x, hi + 0.45, mp.z)))
    blocks.instance_count = bx.size()
    for i in range(bx.size()):
        blocks.set_instance_transform(i, bx[i])
    merl.instance_count = mx.size()
    for i in range(mx.size()):
        merl.set_instance_transform(i, mx[i])
    for mm in [blocks, merl]:
        var mmi := MultiMeshInstance3D.new()
        mmi.multimesh = mm
        mmi.material_override = stone
        add_child(mmi)
        wall_parts.append(mmi)
    # towers: at both ends of every gap, plus every ~45 m along the wall
    var gates: Array = []
    var since := 0
    for i in range(n):
        var j := (i + 1) % n
        if kind[i] == 0 and kind[j] != 0:
            # a gap opens after i: find where it closes
            var e := j
            while kind[e] != 0 and e != i:
                e = (e + 1) % n
            var gap_kind := kind[j]
            _tower(pts[i], gap_kind == 1)
            _tower(pts[e], gap_kind == 1)
            if gap_kind == 1:
                gates.append(_gatehouse(pts[i], pts[e]))
            since = 0
        elif kind[i] == 0:
            since += 1
            if since >= 15:
                _tower(pts[i], false)
                since = 0
    _wall_info = {"ax": snappedf(ax, 0.1), "az": snappedf(az, 0.1), "segments": bx.size(),
                  "gates": gates}

func _tower(p: Vector3, gate: bool) -> void:
    var g := height_at(p.x, p.z)
    var h := WALL_H + (5.0 if gate else 2.6)
    var t := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 2.5 if gate else 2.1
    cm.bottom_radius = cm.top_radius + 0.25
    cm.height = h + 1.0
    t.mesh = cm
    t.material_override = _stone()
    t.position = Vector3(p.x, g - 1.0 + (h + 1.0) * 0.5, p.z)
    add_child(t)
    wall_parts.append(t)
    var r := MeshInstance3D.new()
    var rm := CylinderMesh.new()
    rm.top_radius = 0.05
    rm.bottom_radius = cm.top_radius + 0.6
    rm.height = 3.6 if gate else 3.0
    rm.radial_segments = 12
    r.mesh = rm
    r.material_override = _roof.get("red", _stone())
    r.position = Vector3(p.x, g + h + rm.height * 0.5, p.z)
    add_child(r)

## Arch over the gap, and the road carried on outward into the country.
func _gatehouse(a: Vector3, b: Vector3) -> Vector3:
    var mid := (a + b) * 0.5
    var d := b - a
    var w := d.length()
    var g := maxf(height_at(a.x, a.z), height_at(b.x, b.z))
    if w < 26.0:
        wall_parts.append(_box(Vector3(w, 2.6, WALL_T + 0.6), Vector3(mid.x, g + WALL_H + 1.6, mid.z),
             _stone(), atan2(-d.z, d.x)))
    var out := Vector3(mid.x, 0.0, mid.z).normalized()
    if absf(out.z) > 0.9 and out.z > 0.0:
        return Vector3(snappedf(mid.x, 0.1), 0.0, snappedf(mid.z, 0.1))   # bridge road already runs south
    if _scar != Vector3.ZERO and out.dot(Vector3(_scar.x, 0, _scar.z).normalized()) > 0.8:
        return Vector3(snappedf(mid.x, 0.1), 0.0, snappedf(mid.z, 0.1))   # the Delvers' Road, laid by _build_scar
    var lane: Array[Vector3] = []
    var s0 := -3.0
    while s0 <= 90.0:
        lane.append(mid + out * s0)
        s0 += 3.0
    _road_strip(lane, 7.0)
    return Vector3(snappedf(mid.x, 0.1), 0.0, snappedf(mid.z, 0.1))

## ---------------------------------------------------------------- footprints
## Houses were spaced 4.6 m apart along a frontage when they are 8-12 m wide,
## so pairs stood inside each other. Measure each shape ONCE from its mesh,
## space frontages by real width, then drop any plot whose footprint overlaps
## one already kept (frontages win over back ranks).
func _measure_houses() -> void:
    for k in HOUSES:
        var hpath: String = String(HOUSES[k]["path"])
        if not ResourceLoader.exists(hpath):
            continue
        var n: Node3D = (load(hpath) as PackedScene).instantiate()
        add_child(n)
        var box := AABB()
        var first := true
        var st: Array = [n]
        while not st.is_empty():
            var c: Node = st.pop_back()
            if c is MeshInstance3D:
                var mi: MeshInstance3D = c
                var ab: AABB = mi.global_transform * mi.get_aabb()
                box = ab if first else box.merge(ab)
                first = false
            for g in c.get_children():
                st.append(g)
        # the street-most door: MegaKit doors arrive as nodes named Door_*
        var best := Vector3(0, 0, box.end.z)
        var found := false
        var st2: Array = [n]
        while not st2.is_empty():
            var c2: Node = st2.pop_back()
            if c2 is Node3D and String(c2.name).begins_with("Door_"):
                var dp: Vector3 = (c2 as Node3D).global_position
                if not found or dp.z > best.z:
                    best = dp
                    found = true
            for g2 in c2.get_children():
                st2.append(g2)
        _house_door[k] = best
        remove_child(n)
        n.free()
        var cen := box.get_center()
        _house_box[k] = [Vector2(box.size.x * 0.5, box.size.z * 0.5), Vector2(cen.x, cen.z), box.end.y]   # [2]: roof top (camera pull-in)

func _rect(plot: Dictionary) -> Array:
    var sh: String = String(plot.get("shape", "a"))
    var he := Vector2(5.0, 5.0)
    var off := Vector2.ZERO
    if _house_box.has(sh):
        he = (_house_box[sh][0] as Vector2) * 1.10 + Vector2(0.4, 0.4)   # scale jitter + eaves
        off = _house_box[sh][1]
        if plot.has("landmark"):
            he += Vector2(4.5, 4.5)      # a landmark keeps its ground: a forecourt, not a crush
    var yaw: float = float(plot["yaw"])
    var ax := Vector2(cos(yaw), -sin(yaw))      # local +X in world xz
    var az := Vector2(sin(yaw), cos(yaw))       # local +Z in world xz
    var pp: Vector3 = plot["pos"]
    var c := Vector2(pp.x, pp.z) + ax * off.x + az * off.y
    return [c, ax, az, he]

func _rects_overlap(a: Array, b: Array) -> bool:
    var ca: Vector2 = a[0]
    var cb: Vector2 = b[0]
    var axes: Array[Vector2] = [a[1], a[2], b[1], b[2]]
    for ax in axes:
        var ra: float = absf((a[1] as Vector2).dot(ax)) * (a[3] as Vector2).x + absf((a[2] as Vector2).dot(ax)) * (a[3] as Vector2).y
        var rb: float = absf((b[1] as Vector2).dot(ax)) * (b[3] as Vector2).x + absf((b[2] as Vector2).dot(ax)) * (b[3] as Vector2).y
        if absf((cb - ca).dot(ax)) > ra + rb:
            return false
    return true

func _resolve_overlaps() -> void:
    var order: Array = []
    for plot in plots:
        if plot.has("landmark"):
            order.append(plot)
    for plot in plots:
        if not plot.has("back") and not plot.has("landmark"):
            order.append(plot)
    for plot in plots:
        if plot.has("back"):
            order.append(plot)
    var kept: Array = []
    var rects: Array = []
    var dropped := 0
    # HD: a terrace runs ALONG its street and a back rank sits behind it, but
    # the hex streets zig-zag, so either could land on ANOTHER street - houses
    # standing in the road. Test every house footprint against the paving.
    _road_segs.clear()
    _collect_road_segs()
    for plot in order:
        var r := _rect(plot)
        var hit := false
        if not plot.has("landmark") and _rect_on_road(r):
            dropped += 1
            _road_dropped += 1
            continue
        for o in rects:
            if _rects_overlap(r, o):
                hit = true
                break
        if hit:
            dropped += 1
            continue
        kept.append(plot)
        rects.append(r)
    plots = kept
    _overlap_dropped = dropped
    _road_segs.clear()      # rebuilt for real once the gate lanes are cut

var _road_dropped := 0

## any part of a footprint (5x5 samples over the rect) on or within 0.4 m of a road
func _rect_on_road(r: Array) -> bool:
    var c: Vector2 = r[0]
    var ax: Vector2 = r[1]
    var az: Vector2 = r[2]
    var he: Vector2 = r[3]
    for i in range(5):
        for j in range(5):
            var q := c + ax * he.x * (float(i) / 2.0 - 1.0) + az * he.y * (float(j) / 2.0 - 1.0)
            if road_dist(Vector3(q.x, 0.0, q.y)) < 0.4:
                return true
    return false

## ---------------------------------------------------------------- landmarks
func _depth_of(shape: String) -> float:
    if _house_box.has(shape):
        return (_house_box[shape][0] as Vector2).y * 2.0
    return float((HOUSES.get(shape, {"depth": 10.0}) as Dictionary)["depth"])

func _width_of(shape: String) -> float:
    if _house_box.has(shape):
        return (_house_box[shape][0] as Vector2).x * 2.0
    return 10.0

## The landmark stands BESIDE its district's centre hex (the centre itself is
## where the branch road ends), facade to that road. Planted before any house
## so nothing else can take its ground.
func _plant_landmarks() -> void:
    for id in LANDMARKS:
        if not centre_of.has(id):
            continue
        var c: Vector2i = centre_of[id]
        var cp := Hex.pos(c.x, c.y)
        var keys: Array = LANDMARKS[id]
        var used := 0
        var nbs: Array = Hex.neighbours(c)
        # neighbours furthest from the town centre first: landmarks face inward
        nbs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            return Hex.pos(a.x, a.y).length() > Hex.pos(b.x, b.y).length())
        for nb in nbs:
            if used >= keys.size():
                break
            var nbv: Vector2i = nb
            if road_cells.has(nbv) or square.has(nbv) or not district_of.has(nbv):
                continue
            var key: String = keys[used]
            var np := Hex.pos(nbv.x, nbv.y)
            var dir := (cp - np)
            dir.y = 0.0
            dir = dir.normalized()
            var pos := cp - dir * (SETBACK + _depth_of(key) * 0.5)
            if river_dist(pos.x, pos.z) < RIVER_W + RIVER_BANK + _depth_of(key) * 0.5:
                continue
            plots.append({"cell": nbv, "pos": pos, "yaw": atan2(dir.x, dir.z),
                          "district": id, "shape": key, "landmark": key})
            landmarks[key] = [pos, dir]
            used += 1

## Lights, inscriptions, yards and moving parts that make each landmark read
## as what it is.
func _dress_landmarks() -> void:
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.62, 0.48, 0.36)
    for plot in plots:
        if not plot.has("landmark"):
            continue
        var key: String = plot["landmark"]
        var p: Vector3 = plot["pos"]
        var f := _fwd(plot)
        var side := Vector3(-f.z, 0.0, f.x)
        var yaw := atan2(f.x, f.z)
        var g := height_at(p.x, p.z)
        var front := p + f * (_depth_of(key) * 0.5)
        _objs.append([p, maxf(_depth_of(key), _width_of(key)) * 0.55])
        var lv: String = String(livery_of.get(plot["district"], "red"))
        # standing banners (Fantasy Props MegaKit) flank every landmark's front
        if key != "lm_windmill":
            for sgn in [-1.0, 1.0]:
                # as far out as the forecourt allows, but never on the road
                for out in [1.6, 0.9, 0.5]:
                    var bp: Vector3 = front + f * float(out) + side * (float(sgn) * (_width_of(key) * 0.5 - 0.6))
                    if road_dist(bp) > 0.8:
                        _yard("Banner_1" if sgn < 0.0 else "Banner_2", bp, side, f, 0.0, 0.0)
                        break
        match key:
            "lm_hall":
                # the inscription over the Chief's Hall, word for word from canon
                var ins := Label3D.new()
                ins.text = "MEASURE THE GRAIN. COUNT THE FLASKS. KEEP THE DOOR."
                ins.font_size = 56
                ins.pixel_size = 0.0062
                ins.modulate = Color(0.92, 0.86, 0.66)
                ins.outline_size = 14
                ins.outline_modulate = Color(0.12, 0.08, 0.04)
                var ip := front + f * 0.12
                ins.position = Vector3(ip.x, g + 3.35, ip.z)
                ins.rotation.y = yaw
                add_child(ins)
                for sgn in [-1.0, 1.0]:
                    _livery_banner(front + side * (float(sgn) * 3.0) + f * 0.25, yaw, lv, g + 5.5)
                    _glow(front + side * (float(sgn) * 1.6) + f * 0.6 + Vector3(0, g + 2.6, 0), Color(1.0, 0.75, 0.45), 0.8, 7.0)
                _flagpole(p + side * (-_width_of(key) * 0.5 - 2.5) + f * 2.0, lv, 13.0, wood)
            "lm_chapel":
                _glow(front + f * 2.6 + Vector3(0, g + 2.6, 0), Color(1.0, 0.85, 0.6), 1.0, 8.0)
                # the reading stand at the door with its candle, a candle-stand either side
                var bs := _yard("BookStand", front + f * 3.4, side, f, 2.0, 0.0, PI)
                _on_top("Candle_1", bs, 0.25, 0.0)
                for sgn in [-1.0, 1.0]:
                    var cs := _yard("CandleStick_Stand", front + f * 2.4, side, f, float(sgn) * 3.0, 0.0)
                    if cs:
                        _glow(cs.position + Vector3(0, 1.9, 0), Color(1.0, 0.75, 0.45), 0.5, 4.0)
                # a bell hanging in the tower top (the tower stands in front of the nave)
                var tp := p + f * (_depth_of(key) * 0.5 - 2.0)
                var bell := MeshInstance3D.new()
                var bm := CylinderMesh.new()
                bm.top_radius = 0.35
                bm.bottom_radius = 0.7
                bm.height = 0.9
                bell.mesh = bm
                var bronze := StandardMaterial3D.new()
                bronze.albedo_color = Color(0.72, 0.52, 0.22)
                bronze.metallic = 0.85
                bronze.roughness = 0.35
                bell.material_override = bronze
                bell.position = Vector3(tp.x, g + 11.4, tp.z)
                add_child(bell)
                # small kept garden of graves beside the nave
                for i in range(6):
                    var gp := p - side * (_width_of(key) * 0.5 + 3.0) + f * (float(i % 3) * 2.6 - 2.6) - side * (float(i / 3) * 2.2)
                    if is_clear(gp, 0.6, true):
                        _box(Vector3(0.7, 1.0, 0.18), Vector3(gp.x, height_at(gp.x, gp.z) + 0.45, gp.z), _stone(), yaw)
                        _objs.append([gp, 0.8])
            "lm_barracks":
                # drill yard in front: dummies, racks, archery butts
                var yard := front + f * 5.0
                for i in range(4):
                    _yard("Dummy", yard, side, f, -6.0 + float(i) * 4.0, 0.0, PI)
                _yard("WeaponStand", yard, side, f, -8.5, -2.0, PI * 0.5)
                _yard("WeaponStand", yard, side, f, 8.5, -2.0, -PI * 0.5)
                _yard("Barrel", yard, side, f, 9.0, 1.0)
                _livery_banner(front + side * 3.2 + f * 0.25, yaw, lv, g + 5.0)
                _livery_banner(front - side * 3.2 + f * 0.25, yaw, lv, g + 5.0)
                _objs.append([yard, 7.0])
            "lm_windmill":
                # hub on the street face of the tower, four sails turning
                var hub := Node3D.new()
                var hp := p + f * 2.55
                hub.position = Vector3(hp.x, g + 8.2, hp.z)
                hub.rotation.y = yaw
                add_child(hub)
                var sail := StandardMaterial3D.new()
                sail.albedo_color = Color(0.74, 0.66, 0.52)
                sail.roughness = 0.95
                sail.cull_mode = BaseMaterial3D.CULL_DISABLED
                var spin := Node3D.new()
                hub.add_child(spin)
                for i in range(4):
                    var arm := Node3D.new()
                    arm.rotation.z = float(i) * PI * 0.5
                    spin.add_child(arm)
                    var spar := MeshInstance3D.new()
                    var sm := BoxMesh.new()
                    sm.size = Vector3(0.22, 7.2, 0.18)
                    spar.mesh = sm
                    spar.material_override = wood
                    spar.position = Vector3(0, 3.6, 0.35)
                    arm.add_child(spar)
                    var cloth := MeshInstance3D.new()
                    var cm := BoxMesh.new()
                    cm.size = Vector3(1.4, 5.0, 0.03)
                    cloth.mesh = cm
                    cloth.material_override = sail
                    cloth.position = Vector3(0.8, 4.4, 0.40)
                    arm.add_child(cloth)
                    # the lattice the canvas is laced to
                    for k in range(6):
                        var bar := MeshInstance3D.new()
                        var brm := BoxMesh.new()
                        brm.size = Vector3(1.7, 0.08, 0.08)
                        bar.mesh = brm
                        bar.material_override = wood
                        bar.position = Vector3(0.8, 2.0 + float(k) * 0.95, 0.44)
                        arm.add_child(bar)
                    var rail := MeshInstance3D.new()
                    var rlm := BoxMesh.new()
                    rlm.size = Vector3(0.08, 5.2, 0.08)
                    rail.mesh = rlm
                    rail.material_override = wood
                    rail.position = Vector3(1.6, 4.4, 0.44)
                    arm.add_child(rail)
                var cap := MeshInstance3D.new()
                var capm := CylinderMesh.new()
                capm.top_radius = 0.35
                capm.bottom_radius = 0.35
                capm.height = 0.9
                cap.mesh = capm
                cap.material_override = wood
                cap.rotation.x = PI * 0.5
                cap.position = Vector3(0, 0, 0.3)
                hub.add_child(cap)
                _spinners.append([spin, Vector3(0, 0, 1), 0.45])
            "lm_workshop":
                var wy := front + f * 3.2
                _yard("Workbench", wy, side, f, -3.5, 0.0)
                _yard("Workbench_Drawers", wy, side, f, -1.0, -0.3)
                _yard("Crate_Wooden", wy, side, f, 1.8, -0.4, 0.3)
                _yard("Barrel", wy, side, f, 3.2, 0.2)
                _timber_stack(p + side * (_width_of(key) * 0.5 + 2.6), yaw, wood)
                _livery_banner(front + side * 2.4 + f * 0.25, yaw, lv, g + 4.8)
            "lm_granary":
                for i in range(5):
                    _yard("Bag", front + f * 1.6, side, f, -3.0 + float(i) * 1.5, 0.0, float(i))
                _yard("FarmCrate_Empty", front + f * 1.6, side, f, 3.8, 0.4)

func _livery_banner(p: Vector3, yaw: float, lv: String, top_y: float) -> void:
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = LIVERY_BANNER.get(lv, Color(0.6, 0.15, 0.12))
    cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
    _box(Vector3(1.1, 2.6, 0.05), Vector3(p.x, top_y - 1.3, p.z), cloth, yaw)
    var trim := StandardMaterial3D.new()
    trim.albedo_color = Color(0.85, 0.72, 0.35)
    trim.metallic = 0.6
    _box(Vector3(1.3, 0.08, 0.08), Vector3(p.x, top_y, p.z), trim, yaw)

func _flagpole(p: Vector3, lv: String, h: float, wood: Material) -> void:
    var g := height_at(p.x, p.z)
    _box(Vector3(0.2, h, 0.2), Vector3(p.x, g + h * 0.5, p.z), wood)
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = LIVERY_BANNER.get(lv, Color(0.6, 0.15, 0.12))
    cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
    _box(Vector3(2.2, 1.3, 0.04), Vector3(p.x + 1.2, g + h - 0.8, p.z), cloth)
    _objs.append([p, 0.8])

## The watermill sits on the far bank, outside the wall, its wheel in the race.
func _build_watermill() -> void:
    var path := "res://assets/buildings/lm_watermill.glb"
    if not ResourceLoader.exists(path) or river_pts.size() < 2:
        return
    for xx in [-48.0, 52.0, -70.0, 75.0]:
        var pos := _watermill_at(float(xx))
        if pos != Vector3.ZERO:
            landmarks["lm_watermill"] = [pos, Vector3(0, 0, 1)]
            return

## a watermill on the far (south) bank at x: house, plinth, turning wheel.
## Returns where it stands, or ZERO if a road is in the way. (D12: the Ford
## Mill uses it too.)
func _watermill_at(x: float) -> Vector3:
    var path := "res://assets/buildings/lm_watermill.glb"
    # river centre z at this x
    var rz := 0.0
    var best := 1e9
    var z := 60.0
    while z < 220.0:
        var d := river_dist(x, z)
        if d < best:
            best = d
            rz = z
        z += 0.5
    var dep := _depth_of("lm_watermill")
    var pos := Vector3(x, 0.0, rz + RIVER_W - 0.5 + dep * 0.5)
    if road_dist(pos) < dep:
        return Vector3.ZERO
    var h: Node3D = (load(path) as PackedScene).instantiate()
    h.position = Vector3(pos.x, 0.15, pos.z)
    add_child(h)
    _solid_of(h)            # D12: the mill is solid ground for the navmesh
    _dress(h, "green")
    # stone plinth: the bank falls away under the back of the mill
    _box(Vector3(_width_of("lm_watermill") + 0.6, 3.2, dep + 0.6), Vector3(pos.x, -1.45, pos.z), _stone())
    # the wheel, axle along X, dipping into the water on the river side
    var wheel := Node3D.new()
    # wheel on the river side of the house, axle into the back wall
    wheel.position = Vector3(pos.x, 0.5, pos.z - dep * 0.5 - 2.9)
    ## wheel plane must hold the river's flow (along X): axle along Z
    wheel.rotation.y = PI * 0.5
    add_child(wheel)
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.albedo_color = Color(0.5, 0.38, 0.28)
    var spin := Node3D.new()
    wheel.add_child(spin)
    for i in range(12):
        var a := float(i) * TAU / 12.0
        var paddle := MeshInstance3D.new()
        var pm := BoxMesh.new()
        pm.size = Vector3(1.2, 0.9, 0.12)
        paddle.mesh = pm
        paddle.material_override = wood
        paddle.position = Vector3(0, sin(a) * 2.5, cos(a) * 2.5)
        paddle.rotation.x = -a
        spin.add_child(paddle)
    for sx in [-0.55, 0.55]:
        var rim := MeshInstance3D.new()
        var tm := TorusMesh.new()
        tm.inner_radius = 2.3
        tm.outer_radius = 2.55
        rim.mesh = tm
        rim.material_override = wood
        rim.rotation.z = PI * 0.5
        rim.position = Vector3(float(sx), 0, 0)
        spin.add_child(rim)
    var axle := MeshInstance3D.new()
    var am := CylinderMesh.new()
    am.top_radius = 0.18
    am.bottom_radius = 0.18
    am.height = 3.2
    axle.mesh = am
    axle.material_override = wood
    axle.rotation.z = PI * 0.5
    axle.position = Vector3(-1.6, 0, 0)
    wheel.add_child(axle)
    _spinners.append([spin, Vector3(1, 0, 0), -0.6])
    _objs.append([pos, maxf(dep, _width_of("lm_watermill")) * 0.6 + 2.0])
    return pos

## ---------------------------------------------------------------- outworks
## Workplaces outside the wall from the old roster: the Lumber Mill in the
## woods past the west gate, the Mine cut into the eastern hills, and the
## Archery Range by the east road. Each gets a path from its gate road.
func _gate(side: float) -> Vector3:
    for g in _wall_info.get("gates", []):
        var gv: Vector3 = g
        if signf(gv.x) == signf(side):
            return gv
    return Vector3(side * 170.0, 0, 0)

func _site(key: String, door: Vector3, door_in: Vector3) -> void:
    _sites.append({"landmark": key, "door": door, "door_in": door_in, "pos": door})
    landmarks[key] = [door, (door_in - door).normalized() * -1.0]

func _build_outworks() -> void:
    if not _wall_info.has("ax"):
        return
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.58, 0.45, 0.33)
    _build_sawmill(wood)
    _build_mine(wood)
    _build_range(wood)

func _build_sawmill(wood: Material) -> void:
    var path := "res://assets/buildings/lm_sawmill.glb"
    if not ResourceLoader.exists(path):
        return
    var gw := _gate(-1.0)
    var dep := _depth_of("lm_sawmill")
    var pos := Vector3(gw.x - 42.0, 0.0, gw.z + 24.0)
    var f := Vector3(0, 0, -1)                       # faces the west road
    var h: Node3D = (load(path) as PackedScene).instantiate()
    h.position = Vector3(pos.x, height_at(pos.x, pos.z), pos.z)
    h.rotation.y = atan2(f.x, f.z)
    add_child(h)
    _dress(h, "green")
    _objs.append([pos, 9.0])
    var dl: Vector3 = _house_door.get("lm_sawmill", Vector3(0, 0, dep * 0.5))
    var dw := h.transform * dl
    _site("lm_sawmill", Vector3(dw.x, 0, dw.z) + f * 1.4, Vector3(dw.x, 0, dw.z) - f * 0.5)
    # path from the west road to the yard
    var a := Vector3(pos.x, 0, gw.z)
    _road_strip([a, a.lerp(dw + f * 3.0, 0.5), dw + f * 3.0], 3.2, true)
    # log piles, stumps and a chopping block in the yard beside the shed
    var side := Vector3(-f.z, 0, f.x)
    var yard := pos + side * (_width_of("lm_sawmill") * 0.5 + 5.0)
    _timber_stack(yard, atan2(side.x, side.z), wood)
    _timber_stack(yard + f * -5.0, atan2(side.x, side.z), wood)
    _objs.append([yard, 5.0])
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.36, 0.26, 0.18)
    var rng := RandomNumberGenerator.new()
    rng.seed = 31
    for i in range(6):
        var sp := pos + Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(8, 22))
        if not is_clear(sp, 0.8):
            continue
        var st := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = rng.randf_range(0.3, 0.45)
        cm.bottom_radius = cm.top_radius + 0.08
        cm.height = 0.55
        st.mesh = cm
        st.material_override = bark
        st.position = Vector3(sp.x, height_at(sp.x, sp.z) + 0.27, sp.z)
        add_child(st)
        _objs.append([sp, 0.8])
    _yard("Axe_Bronze", yard + side * 4.0, side, f, 0.0, 0.0, 0.6)
    # the woods the lumberjacks work: a dense stand of pines behind the mill
    for i in range(40):
        var tp := pos + Vector3(rng.randf_range(-40, 10), 0, rng.randf_range(12, 48))
        if is_clear(tp, 1.6):
            var nm: String = ["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"][rng.randi() % 5]
            if _spawn(NATURE, nm, tp, rng.randf_range(0, TAU), rng.randf_range(1.0, 1.6)):
                _objs.append([tp, 1.6])
                _nature_made += 1

## Logs: a neat pyramid of cylinders, the way a yard stacks them.
func _timber_stack(p: Vector3, yaw: float, wood: Material) -> void:
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.42, 0.30, 0.20)
    var g := height_at(p.x, p.z)
    var holder := Node3D.new()
    holder.position = Vector3(p.x, g, p.z)
    holder.rotation.y = yaw
    add_child(holder)
    var rows := [4, 3, 2]
    for r in range(rows.size()):
        for i in range(int(rows[r])):
            var lg := MeshInstance3D.new()
            var cm := CylinderMesh.new()
            cm.top_radius = 0.28
            cm.bottom_radius = 0.28
            cm.height = 3.6
            lg.mesh = cm
            lg.material_override = bark
            lg.rotation.z = PI * 0.5
            lg.position = Vector3(0, 0.28 + float(r) * 0.5, (float(i) - float(int(rows[r]) - 1) * 0.5) * 0.58)
            holder.add_child(lg)
    _objs.append([p, 2.4])

func _build_mine(wood: Material) -> void:
    var ge := _gate(1.0)
    var rng := RandomNumberGenerator.new()
    rng.seed = 77
    # walk out from the east gate until the ground has risen into a hillside
    var best := Vector3.ZERO
    var a := deg_to_rad(-38.0)
    var dir := Vector3(cos(a), 0, sin(a))
    var d := 60.0
    while d < 200.0:
        var q := ge + dir * d
        # a mine wants a real slope: high ground, and rising behind the mouth
        if height_at(q.x, q.z) > 12.0 and height_at(q.x + dir.x * 8.0, q.z + dir.z * 8.0) > height_at(q.x, q.z) + 2.0:
            best = q
            break
        d += 2.0
    if best == Vector3.ZERO:
        best = ge + dir * 90.0
    var face := (ge - best)
    face.y = 0.0
    face = face.normalized()                         # entrance looks back toward the gate
    var yaw := atan2(face.x, face.z)
    var side := Vector3(-face.z, 0, face.x)
    var g := height_at(best.x, best.z)
    # rock face built up around the opening
    # rock shoulders either side of the mouth and a crag above it - never in front of it
    for i in range(16):
        var sx := rng.randf_range(2.8, 8.0) * (1.0 if i % 2 == 0 else -1.0)
        var back := rng.randf_range(2.5, 6.0)
        var lift := 0.0
        if i >= 12:
            sx = rng.randf_range(-2.0, 2.0)
            back = rng.randf_range(4.5, 6.5)
            lift = 3.6
        var rp := best + side * sx - face * back
        var sc := rng.randf_range(1.8, 3.2)
        var nm: String = ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][rng.randi() % 3]
        _spawn_raw(NATURE, nm, Vector3(rp.x, height_at(rp.x, rp.z) - 0.8 + lift, rp.z), rng.randf_range(0, TAU), sc)
    # the dark mouth and its timber frame
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.02, 0.02, 0.02)
    _box(Vector3(3.0, 3.4, 4.0), Vector3(best.x, g + 1.7, best.z) - face * 1.6, dark, yaw)
    for sgn in [-1.0, 1.0]:
        var pp := best + side * (1.75 * float(sgn)) + face * 0.3
        _box(Vector3(0.35, 3.8, 0.35), Vector3(pp.x, g + 1.9, pp.z), wood, yaw)
    var lp := best + face * 0.3
    _box(Vector3(4.1, 0.4, 0.45), Vector3(lp.x, g + 3.85, lp.z), wood, yaw)
    _glow(best + face * 1.2 + Vector3(0, g + 3.2, 0), Color(1.0, 0.7, 0.4), 1.0, 8.0)
    # rails out of the mouth, a cart, and spoil heaps
    var iron := StandardMaterial3D.new()
    iron.albedo_color = Color(0.25, 0.24, 0.23)
    iron.metallic = 0.7
    for sgn in [-1.0, 1.0]:
        var rp2 := best + face * 5.0 + side * (0.55 * float(sgn))
        _box(Vector3(0.08, 0.1, 12.0), Vector3(rp2.x, height_at(rp2.x, rp2.z) + 0.06, rp2.z), iron, yaw)
    for k in range(8):
        var tp := best + face * (0.0 + float(k) * 1.5)
        _box(Vector3(1.6, 0.08, 0.22), Vector3(tp.x, height_at(tp.x, tp.z) + 0.02, tp.z), wood, yaw)
    var cart := best + face * 7.0
    _spawn_raw(MKPROPS, "Prop_Wagon", Vector3(cart.x, height_at(cart.x, cart.z), cart.z), yaw + PI * 0.5, 0.7)
    for i in range(10):
        var pb := best + face * rng.randf_range(4, 9) + side * rng.randf_range(3.0, 6.0)
        _spawn_raw(NATURE, "Pebble_Round_" + str([1, 3][rng.randi() % 2]), Vector3(pb.x, height_at(pb.x, pb.z), pb.z), rng.randf_range(0, TAU), rng.randf_range(3.0, 6.0))
    _objs.append([best, 9.0])
    _site("mine", best + face * 3.0, best - face * 1.2)
    # a dirt track from the east road up to the mine
    var start := ge + Vector3(1, 0, 0) * 20.0
    _road_strip([start, start.lerp(best + face * 12.0, 0.5), best + face * 12.0, best + face * 2.0], 3.4, true)

func _spawn_raw(dir_path: String, nm: String, pos: Vector3, yaw: float, sc: float) -> Node3D:
    var path := dir_path + nm + ".gltf"
    if not ResourceLoader.exists(path):
        path = dir_path + nm + ".glb"
    if not ResourceLoader.exists(path):
        return null
    if not _scene.has(path):
        _scene[path] = load(path)
    var n: Node3D = _scene[path].instantiate()
    n.position = pos
    n.rotation.y = yaw
    n.scale = Vector3.ONE * sc
    add_child(n)
    if dir_path == MKPROPS:
        _dress(n, "red")
    return n

func _build_range(wood: Material) -> void:
    var ge := _gate(1.0)
    var f := Vector3(1, 0, 0)                        # shooting toward open country
    var side := Vector3(0, 0, 1)
    var origin := ge + Vector3(14.0, 0, 24.0)        # south of the east road, clear of the mine track
    var line := origin
    # shooting line: a rail, a rack and a bench
    _box(Vector3(0.12, 0.9, 12.0), Vector3(line.x, height_at(line.x, line.z) + 0.45, line.z), wood)
    _yard("WeaponStand", line, side, f, -7.0, -1.5, -PI * 0.5)
    _yard("Bench", line, side, f, 7.0, -1.5, PI * 0.5)
    var straw := StandardMaterial3D.new()
    straw.albedo_color = Color(0.82, 0.68, 0.38)
    var ring_cols := [Color(0.9, 0.9, 0.85), Color(0.75, 0.12, 0.10), Color(0.95, 0.80, 0.20)]
    for i in range(4):
        var tp := line + f * 26.0 + side * (-4.5 + float(i) * 3.0)
        var g := height_at(tp.x, tp.z)
        # A-frame legs
        for sgn in [-1.0, 1.0]:
            _box(Vector3(0.12, 1.8, 0.12), Vector3(tp.x + 0.35, g + 0.9, tp.z + 0.45 * float(sgn)), wood)
        var butt := MeshInstance3D.new()
        var bm := CylinderMesh.new()
        bm.top_radius = 0.75
        bm.bottom_radius = 0.75
        bm.height = 0.35
        butt.mesh = bm
        butt.material_override = straw
        butt.rotation.z = PI * 0.5
        butt.position = Vector3(tp.x, g + 1.3, tp.z)
        add_child(butt)
        for r in range(3):
            var ring := MeshInstance3D.new()
            var rm := CylinderMesh.new()
            rm.top_radius = 0.6 - float(r) * 0.2
            rm.bottom_radius = rm.top_radius
            rm.height = 0.02
            ring.mesh = rm
            var mat := StandardMaterial3D.new()
            mat.albedo_color = ring_cols[r]
            ring.material_override = mat
            ring.rotation.z = PI * 0.5
            ring.position = Vector3(tp.x - 0.18 - float(r) * 0.005, g + 1.3, tp.z)
            add_child(ring)
    # a low fence round the lane
    for k in range(9):
        for sgn in [-1.0, 1.0]:
            var fp := line + f * (2.0 + float(k) * 3.0) + side * (7.5 * float(sgn))
            _spawn_raw(MKPROPS, "Prop_WoodenFence_Single", Vector3(fp.x, height_at(fp.x, fp.z), fp.z), PI * 0.5, 1.0)
    _objs.append([line + f * 14.0, 16.0])
    _site("range", line - f * 2.0, line - f * 0.5)

## ---------------------------------------------------------------- A2 streets
## Lamp posts down every street (district banners on every other one), benches
## where a street meets the square, planters by front doors. Everything stands
## between the carriageway edge and the house fronts - tested against the real
## house footprints (oriented rects), not the coarse circle is_clear uses.
func _in_house(p: Vector3, r: float) -> bool:
    var pr := [Vector2(p.x, p.z), Vector2(1, 0), Vector2(0, 1), Vector2(r, r)]
    for plot in plots:
        var pp: Vector3 = plot["pos"]
        if Vector2(pp.x - p.x, pp.z - p.z).length() > 20.0:
            continue
        if _rects_overlap(pr, _rect(plot)):
            return true
    return false

func _kerb_ok(p: Vector3, r: float) -> bool:
    if road_dist(p) < 0.6:
        return false
    if _dist_to_market(p) < 18.0:
        return false
    if _in_house(p, r):
        return false
    for o in _objs:
        var op: Vector3 = o[0]
        if Vector2(p.x - op.x, p.z - op.z).length() < float(o[1]) + r:
            return false
    return true

func _iron() -> StandardMaterial3D:
    if _mat.has("_iron"):
        return _mat["_iron"]
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.13, 0.13, 0.14)
    m.metallic = 0.75
    m.roughness = 0.45
    _mat["_iron"] = m
    return m

func _lamp_post(p: Vector3, out: Vector3, lv: String, banner: bool) -> void:
    var g := height_at(p.x, p.z)
    var iron := _iron()
    var yaw := atan2(out.x, out.z)
    _box(Vector3(0.16, 3.6, 0.16), Vector3(p.x, g + 1.8, p.z), iron, yaw)
    _box(Vector3(0.34, 0.25, 0.34), Vector3(p.x, g + 0.12, p.z), iron, yaw)
    # arm reaching over the street, lantern hanging from it
    var arm := p + out * 0.45
    _box(Vector3(0.08, 0.08, 0.9), Vector3(arm.x, g + 3.5, arm.z), iron, yaw)
    var lp := p + out * 0.8
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(1.0, 0.86, 0.55)
    glass.emission_enabled = true
    glass.emission = Color(1.0, 0.72, 0.38)
    glass.emission_energy_multiplier = 2.2
    _box(Vector3(0.28, 0.38, 0.28), Vector3(lp.x, g + 3.08, lp.z), glass, yaw)
    _box(Vector3(0.36, 0.06, 0.36), Vector3(lp.x, g + 3.3, lp.z), iron, yaw)
    _box(Vector3(0.32, 0.05, 0.32), Vector3(lp.x, g + 2.87, lp.z), iron, yaw)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.76, 0.45)
    l.light_energy = 0.7
    l.omni_range = 8.0
    l.position = Vector3(lp.x, g + 2.9, lp.z)
    add_child(l)
    if banner:
        var cloth := StandardMaterial3D.new()
        cloth.albedo_color = LIVERY_BANNER.get(lv, Color(0.6, 0.15, 0.12))
        cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
        var side := Vector3(-out.z, 0, out.x)
        var bp := p - out * 0.12
        _box(Vector3(0.05, 1.5, 0.62), Vector3(bp.x, g + 2.25, bp.z), cloth, yaw)
        var trim := StandardMaterial3D.new()
        trim.albedo_color = Color(0.85, 0.72, 0.35)
        trim.metallic = 0.5
        _box(Vector3(0.07, 0.07, 0.7), Vector3(bp.x, g + 3.02, bp.z), trim, yaw)
    _objs.append([p, 0.5])

func _bench(p: Vector3, face: Vector3) -> void:
    _spawn(PROPS, "Bench", p, atan2(face.x, face.z))
    _objs.append([p, 1.2])

func _planter(p: Vector3, yaw: float, wood: Material) -> void:
    var g := height_at(p.x, p.z)
    _box(Vector3(1.1, 0.45, 0.45), Vector3(p.x, g + 0.22, p.z), wood, yaw)
    var soil := StandardMaterial3D.new()
    soil.albedo_color = Color(0.22, 0.15, 0.10)
    _box(Vector3(1.0, 0.04, 0.36), Vector3(p.x, g + 0.44, p.z), soil, yaw)
    var nm: String = ["Flower_3_Group", "Flower_4_Group", "Bush_Common_Flowers"][int(absf(p.x * 7.0 + p.z * 3.0)) % 3]
    _spawn_raw(NATURE, nm, Vector3(p.x, g + 0.45, p.z), yaw, 0.55 if nm != "Bush_Common_Flowers" else 0.35)
    _objs.append([p, 0.7])

func _street_furniture() -> void:
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.55, 0.42, 0.30)
    var lamps := 0
    var benches := 0
    var planters := 0
    # lamps: walk every road link, one side then the other, ~20 m apart
    var done := {}
    var k := 0
    for sg in _road_segs:
        var a: Vector3 = sg[0]
        var b: Vector3 = sg[1]
        var hw: float = float(sg[2])
        var d := b - a
        d.y = 0.0
        var L := d.length()
        if L < 4.0 or hw < 4.0:
            continue          # skip paved patches and narrow outside tracks
        var t := d / L
        var n := Vector3(-t.z, 0, t.x)
        var mid := (a + b) * 0.5
        var key := "%d,%d" % [int(mid.x / 9.0), int(mid.z / 9.0)]
        if done.has(key):
            continue
        done[key] = true
        k += 1
        var sd := 1.0 if k % 2 == 0 else -1.0
        var lp := mid + n * sd * (hw + 1.0)
        if _kerb_ok(lp, 0.35):
            var c := _cell_near(lp)
            var lv: String = String(livery_of.get(district_of.get(c, ""), "red"))
            _lamp_post(lp, -n * sd, lv, k % 4 < 2)
            lamps += 1
    # benches: round the edge of the square, facing the well
    if _market_pos != Vector3.ZERO:
        for i in range(10):
            var ang := TAU * float(i) / 10.0 + 0.3
            var bp := _market_pos + Vector3(cos(ang), 0, sin(ang)) * 19.0
            var ok := road_dist(bp) > 0.4 and not _in_house(bp, 1.0)
            for o in _objs:
                if Vector2(bp.x - (o[0] as Vector3).x, bp.z - (o[0] as Vector3).z).length() < float(o[1]) + 1.2:
                    ok = false
            if ok:
                _bench(bp, _market_pos - bp)
                benches += 1
    # planters beside front doors of street-facing houses
    var rng := RandomNumberGenerator.new()
    rng.seed = 2121
    for plot in plots:
        if not plot.has("door") or plot.has("back") or plot.has("shop") or rng.randf() > 0.45:
            continue
        var f := _fwd(plot)
        var side := Vector3(-f.z, 0, f.x)
        var door: Vector3 = plot["door"]
        var pp := door - f * 0.9 + side * (1.6 if rng.randf() < 0.5 else -1.6)
        if road_dist(pp) > 0.4:
            var clash := false
            for o in _objs:
                if Vector2(pp.x - (o[0] as Vector3).x, pp.z - (o[0] as Vector3).z).length() < float(o[1]) + 0.6:
                    clash = true
            if not clash:
                _planter(pp, atan2(side.x, side.z), wood)
                planters += 1
    _furniture = {"lamps": lamps, "benches": benches, "planters": planters}

## ---------------------------------------------------------------- meadow
## Grass tufts, clover and wildflowers across the countryside, as MultiMeshes
## (thousands of instances, a handful of draw calls). Never on a road, track,
## the river, or inside the wall.
func _mesh_of(path: String) -> Mesh:
    if not ResourceLoader.exists(path):
        return null
    var n: Node = (load(path) as PackedScene).instantiate()
    var st: Array = [n]
    var found: Mesh = null
    while not st.is_empty() and found == null:
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            found = (c as MeshInstance3D).mesh
        for g in c.get_children():
            st.append(g)
    n.free()
    return found

func _meadow() -> void:
    if not _wall_info.has("ax"):
        return
    var ax: float = float(_wall_info["ax"]) + 6.0
    var az: float = float(_wall_info["az"]) + 6.0
    ## scales: these Quaternius tufts are modelled ~1.5-3 m tall, knee height wants ~0.3
    var kinds := [["Grass_Common_Short", 12000, 0.35], ["Grass_Wispy_Tall", 5000, 0.28], ["Grass_Common_Tall", 3500, 0.28],
                  ["Clover_1", 2000, 0.35], ["Flower_3_Group", 1400, 0.32], ["Flower_4_Group", 1400, 0.32],
                  ["Fern_1", 400, 0.4], ["Mushroom_Common", 120, 0.35]]
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242
    var total := 0
    for kd in kinds:
        var mesh := _mesh_of(NATURE + String(kd[0]) + ".gltf")
        if mesh == null:
            continue
        var xs: Array[Transform3D] = []
        var tries := 0
        while xs.size() < int(kd[1]) and tries < int(kd[1]) * 4:
            tries += 1
            # bias toward the near country, where the camera usually is
            var r := pow(rng.randf(), 1.8) * 360.0 + 8.0
            var ang := rng.randf() * TAU
            var p := Vector3(cos(ang) * (ax + r), 0, sin(ang) * (az + r))
            if river_dist(p.x, p.z) < RIVER_W + 2.0:
                continue
            if height_at(p.x, p.z) > 60.0:
                continue
            if road_dist(p) < 0.4 or _in_field(p, 0.5):
                continue
            if _scar != Vector3.ZERO and Vector2(p.x - _scar.x, p.z - _scar.z).length() < 34.0:
                continue
            var sc := rng.randf_range(0.7, 1.3) * float(kd[2])
            var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc))
            xs.append(Transform3D(b, Vector3(p.x, height_at(p.x, p.z), p.z)))
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = mesh
        mm.instance_count = xs.size()
        for i in range(xs.size()):
            mm.set_instance_transform(i, xs[i])
        var mmi := MultiMeshInstance3D.new()
        mmi.multimesh = mm
        mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        mmi.visibility_range_end = 260.0
        add_child(mmi)
        total += xs.size()
    _furniture["meadow"] = total

## ---------------------------------------------------------------- A3 the scar
## Lore: "A botched casting scars the ground. Inside a scar every spell misfires
## in turn. The dungeon is one enormous scar - that is why a meadow sits under a
## mountain." The scar opens where the valley floor meets the mountain, north of
## town; the Delvers' Road runs to it from a north gate. Whether Jests made it by
## accident or on purpose is NOT answered here - nothing on screen says.
const SCAR_R := 30.0

func in_scar(p: Vector3) -> bool:
    return _scar != Vector3.ZERO and Vector2(p.x - _scar.x, p.z - _scar.z).length() < SCAR_R

func _find_scar() -> void:
    var dir := Vector3(MOUNTAIN.x, 0, MOUNTAIN.z).normalized()
    var d := 180.0
    while d < 460.0:
        var q := dir * d
        if height_at(q.x, q.z) > 32.0:
            _scar = q
            break
        d += 2.0
    if _scar == Vector3.ZERO:
        _scar = dir * 300.0
    _scar.y = height_at(_scar.x, _scar.z)

func _pick_north_road() -> void:
    var dir := Vector3(_scar.x, 0, _scar.z).normalized()
    var best := 1e9
    for cell in road_cells:
        var c := Hex.pos(cell.x, cell.y)
        # the ring road's northern side, on the line toward the scar
        var d := c.distance_to(dir * 70.0)
        if d < best:
            best = d
            _north_from = c

func _glow_crystal(n: Node, col: Color, e: float) -> void:
    if n is MeshInstance3D:
        var mi: MeshInstance3D = n
        if mi.mesh:
            for i in range(mi.mesh.get_surface_count()):
                var m := StandardMaterial3D.new()
                m.albedo_color = col.darkened(0.35)
                m.emission_enabled = true
                m.emission = col
                m.emission_energy_multiplier = e
                m.roughness = 0.15
                m.metallic = 0.2
                mi.set_surface_override_material(i, m)
    for c in n.get_children():
        _glow_crystal(c, col, e)

func _build_scar() -> void:
    if _scar == Vector3.ZERO:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 1313
    var dir := Vector3(_scar.x, 0, _scar.z).normalized()     # town -> mountain
    var side := Vector3(-dir.z, 0, dir.x)
    var face := atan2(-dir.x, -dir.z)                       # looking back at town
    var cols := [Color(0.62, 0.32, 1.0), Color(0.30, 0.85, 1.0), Color(1.0, 0.35, 0.75), Color(0.45, 1.0, 0.55)]
    # scar-glass breaking out of the ground; colours disagree with each other
    for i in range(34):
        var a := rng.randf() * TAU
        var r := pow(rng.randf(), 0.7) * (SCAR_R - 2.0)
        var cp := _scar + Vector3(cos(a), 0, sin(a)) * r
        var n := _spawn_raw("res://assets/fishing/", "detail_crystal", Vector3(cp.x, height_at(cp.x, cp.z) - 0.4, cp.z),
                            rng.randf() * TAU, rng.randf_range(5.0, 16.0) * (1.4 - r / SCAR_R * 0.6))
        if n == null:
            continue
        n.rotation.x = rng.randf_range(-0.55, 0.55)
        n.rotation.z = rng.randf_range(-0.55, 0.55)
        _glow_crystal(n, cols[rng.randi() % cols.size()], rng.randf_range(0.8, 2.4))
    # warped trees round the rim
    for i in range(30):
        var a := rng.randf() * TAU
        var r := rng.randf_range(SCAR_R + 2.0, SCAR_R + 26.0)
        var tp := _scar + Vector3(cos(a), 0, sin(a)) * r
        var nm: String = ["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5", "TwistedTree_1",
                          "TwistedTree_3", "TwistedTree_5"][rng.randi() % 8]
        if road_dist(tp) > 2.0:
            _spawn_raw(NATURE, nm, Vector3(tp.x, height_at(tp.x, tp.z), tp.z), rng.randf() * TAU, rng.randf_range(0.9, 1.6))
            _objs.append([tp, 1.6])
    # lights that pulse out of step with each other
    for i in range(5):
        var a := TAU * float(i) / 5.0 + 0.4
        var lp := _scar + Vector3(cos(a), 0, sin(a)) * rng.randf_range(4.0, 16.0)
        var l := OmniLight3D.new()
        l.light_color = cols[i % cols.size()]
        l.light_energy = 2.2
        l.omni_range = 16.0
        l.position = Vector3(lp.x, height_at(lp.x, lp.z) + 2.5, lp.z)
        add_child(l)
        _pulses.append([l, 2.2, rng.randf_range(1.2, 3.4), rng.randf() * TAU])
    # motes rising off the scar; their hue wanders - every spell misfires in turn
    var gp := GPUParticles3D.new()
    gp.amount = 140
    gp.lifetime = 7.0
    gp.preprocess = 7.0
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    pm.emission_sphere_radius = SCAR_R * 0.8
    pm.direction = Vector3(0, 1, 0)
    pm.spread = 30.0
    pm.initial_velocity_min = 0.3
    pm.initial_velocity_max = 1.4
    pm.gravity = Vector3(0, 0.2, 0)
    pm.scale_min = 0.5
    pm.scale_max = 1.0
    pm.color = Color(0.7, 0.45, 1.0)
    pm.hue_variation_min = -0.35
    pm.hue_variation_max = 0.35
    gp.process_material = pm
    var qd := SphereMesh.new()
    qd.radius = 0.07
    qd.height = 0.14
    qd.radial_segments = 6
    qd.rings = 3
    var qm := StandardMaterial3D.new()
    qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    qm.vertex_color_use_as_albedo = true
    qm.emission_enabled = true
    qm.emission = Color(0.7, 0.5, 1.0)
    qm.emission_energy_multiplier = 2.5
    qd.material = qm
    gp.draw_pass_1 = qd
    gp.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 50, 80))
    gp.position = _scar + Vector3(0, 1.0, 0)
    add_child(gp)
    # THE MOUTH: cut into the slope at the scar's far edge, framed in fallen rock
    var mouth := _scar + dir * (SCAR_R + 6.0)
    var mg := height_at(mouth.x, mouth.z)
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.015, 0.01, 0.02)
    _box(Vector3(7.0, 6.5, 9.0), Vector3(mouth.x, mg + 2.6, mouth.z) + dir * 2.5, dark, face)
    for i in range(18):
        var t := float(i) / 17.0
        var ang := PI * t                                  # arch: left foot -> over the top -> right foot
        var off := side * (cos(ang) * 5.4) + Vector3(0, sin(ang) * 6.2, 0) - dir * rng.randf_range(0.0, 1.4)
        var rp := mouth + off
        var nm: String = ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][rng.randi() % 3]
        _spawn_raw(NATURE, nm, Vector3(rp.x, mg + off.y - 0.6, rp.z), rng.randf() * TAU, rng.randf_range(2.0, 3.4))
    for i in range(10):
        var rp := mouth + side * rng.randf_range(-12.0, 12.0) + dir * rng.randf_range(1.0, 6.0)
        if absf((rp - mouth).dot(side)) < 6.0:
            continue
        _spawn_raw(NATURE, "Rock_Medium_" + str(1 + rng.randi() % 3), Vector3(rp.x, height_at(rp.x, rp.z) - 0.8, rp.z), rng.randf() * TAU, rng.randf_range(3.0, 5.0))
    var deep := OmniLight3D.new()
    deep.light_color = Color(0.55, 0.30, 1.0)
    deep.light_energy = 3.0
    deep.omni_range = 12.0
    deep.position = Vector3(mouth.x, mg + 2.0, mouth.z) + dir * 1.5
    add_child(deep)
    _pulses.append([deep, 3.0, 0.9, 0.0])
    _objs.append([mouth, 9.0])
    _objs.append([_scar, SCAR_R])
    # THE GUILD POST on the road before the scar: "KEEP THE DOOR."
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.50, 0.38, 0.27)
    var post := _scar - dir * (SCAR_R + 12.0)
    var pg := height_at(post.x, post.z)
    for sgn in [-1.0, 1.0]:
        var pp := post + side * (2.6 * float(sgn))
        _box(Vector3(0.35, 3.4, 0.35), Vector3(pp.x, pg + 1.7, pp.z), wood, face)
        # torches on the posts
        var fl := StandardMaterial3D.new()
        fl.albedo_color = Color(1.0, 0.6, 0.2)
        fl.emission_enabled = true
        fl.emission = Color(1.0, 0.55, 0.15)
        fl.emission_energy_multiplier = 4.0
        var flame := MeshInstance3D.new()
        var fm := SphereMesh.new()
        fm.radius = 0.16
        fm.height = 0.42
        flame.mesh = fm
        flame.material_override = fl
        flame.position = Vector3(pp.x, pg + 3.6, pp.z)
        add_child(flame)
        var tl := OmniLight3D.new()
        tl.light_color = Color(1.0, 0.62, 0.3)
        tl.light_energy = 1.4
        tl.omni_range = 9.0
        tl.position = Vector3(pp.x, pg + 3.7, pp.z)
        add_child(tl)
        _pulses.append([tl, 1.4, 7.0, float(sgn)])
    # a barrier pole across the road, raised at one end
    var bar := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(5.6, 0.18, 0.18)
    bar.mesh = bm
    var stripe := StandardMaterial3D.new()
    stripe.albedo_color = Color(0.70, 0.16, 0.12)
    bar.material_override = stripe
    bar.position = Vector3(post.x, pg + 1.2, post.z)
    bar.rotation.y = face
    add_child(bar)
    var sign := Label3D.new()
    sign.text = "KEEP THE DOOR."
    sign.font_size = 72
    sign.pixel_size = 0.009
    sign.modulate = Color(0.95, 0.88, 0.68)
    sign.outline_size = 16
    sign.outline_modulate = Color(0.1, 0.06, 0.03)
    sign.position = Vector3(post.x, pg + 3.35, post.z)
    sign.rotation.y = face
    add_child(sign)
    _box(Vector3(5.6, 0.7, 0.12), Vector3(post.x, pg + 3.35, post.z) + dir * 0.08, wood, face)
    _livery_banner(post + side * 2.6 - dir * 0.25, face, String(livery_of.get("garrison", "blue")), pg + 3.0)
    _objs.append([post, 4.0])
    # the Delvers' Road: from the north gate's cobbles on to the guild post, then
    # a worn track the last stretch to the mouth
    var gate := Vector3.ZERO
    for g in _wall_info.get("gates", []):
        var gv: Vector3 = g
        if gv.dot(dir) > 0.0 and (gate == Vector3.ZERO or gv.dot(dir) > gate.dot(dir)):
            gate = gv
    var start := gate + dir * 2.0 if gate != Vector3.ZERO else _north_from
    _road_strip([start, post - dir * 2.0], 6.0, true)
    _road_strip([post + dir * 2.0, mouth - dir * 1.5], 4.0, true)
    # the inner end of the road, ring -> north gate, in cobble
    if gate != Vector3.ZERO:
        _road_strip([_north_from, gate + dir * 2.0], 7.5)
    _scar_info = {"pos": _scar, "mouth": mouth, "post": post, "fwd": -dir, "gate": gate}

## ---------------------------------------------------------------- A3 fields
func _in_field(p: Vector3, pad: float) -> bool:
    for f in _fields:
        var c: Vector3 = f[0]
        var fw: Vector3 = f[1]
        var sd: Vector3 = f[2]
        var d := p - c
        if absf(d.dot(sd)) < float(f[3]) + pad and absf(d.dot(fw)) < float(f[4]) + pad:
            return true
    return false

func _field_ok(c: Vector3, fw: Vector3, sd: Vector3, hw: float, hd: float) -> bool:
    var lo := 1e9
    var hi := -1e9
    for i in range(-2, 3):
        for j in range(-2, 3):
            var q := c + sd * (hw * float(i) / 2.0) + fw * (hd * float(j) / 2.0)
            if not is_clear(q, 1.2):
                return false
            if road_dist(q) < 2.5 or _in_field(q, 3.0):
                return false
            if _scar != Vector3.ZERO and q.distance_to(Vector3(_scar.x, q.y, _scar.z)) < 75.0:
                return false
            var h := height_at(q.x, q.z)
            lo = minf(lo, h)
            hi = maxf(hi, h)
    return hi - lo < 4.0 and hi < 26.0

func _ground_patch(c: Vector3, fw: Vector3, sd: Vector3, hw: float, hd: float, mat: Material) -> void:
    var nx := int(hw * 2.0)
    var nz := int(hd * 2.0)
    var verts := PackedVector3Array()
    var uvs := PackedVector2Array()
    var idx := PackedInt32Array()
    for j in range(nz + 1):
        for i in range(nx + 1):
            var q := c + sd * (-hw + float(i) * hw * 2.0 / float(nx)) + fw * (-hd + float(j) * hd * 2.0 / float(nz))
            verts.append(Vector3(q.x, height_at(q.x, q.z) + 0.06, q.z))
            uvs.append(Vector2(float(i), float(j)) * 0.5)
    for j in range(nz):
        for i in range(nx):
            var a := j * (nx + 1) + i
            idx.append_array([a, a + 1, a + nx + 1, a + 1, a + nx + 2, a + nx + 1])
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = verts
    arr[Mesh.ARRAY_TEX_UV] = uvs
    arr[Mesh.ARRAY_INDEX] = idx
    var m := ArrayMesh.new()
    m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    var st := SurfaceTool.new()
    st.create_from(m, 0)
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    mi.material_override = mat
    add_child(mi)

func _build_fields() -> void:
    if not _wall_info.has("ax"):
        return
    var ax: float = float(_wall_info["ax"])
    var az: float = float(_wall_info["az"])
    var rng := RandomNumberGenerator.new()
    rng.seed = 515
    var soil: StandardMaterial3D = (_mat.get("MI_Grass") as StandardMaterial3D).duplicate()
    soil.albedo_color = Color(0.55, 0.42, 0.30)
    soil.cull_mode = BaseMaterial3D.CULL_DISABLED
    var wheat_mesh := _mesh_of(NATURE + "Grass_Wispy_Tall.gltf")
    var wheat := StandardMaterial3D.new()
    wheat.albedo_color = Color(0.86, 0.70, 0.32)
    wheat.roughness = 0.9
    wheat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var veg_mesh := _mesh_of(NATURE + "Plant_1.gltf")
    var fence_mesh := _mesh_of(MKPROPS + "Prop_WoodenFence_Single.gltf")
    var fence_len := 2.0
    if fence_mesh:
        var fa := fence_mesh.get_aabb()
        fence_len = maxf(fa.size.x, fa.size.z)
    var tries := 0
    while _fields.size() < 8 and tries < 600:
        tries += 1
        var a := rng.randf() * TAU
        var e := rng.randf_range(1.12, 1.75)
        var c := Vector3(cos(a) * ax * e, 0, sin(a) * az * e)
        var yaw := a + (PI * 0.5 if rng.randf() < 0.5 else 0.0)
        var fw := Vector3(sin(yaw), 0, cos(yaw))
        var sd := Vector3(-fw.z, 0, fw.x)
        var hw := rng.randf_range(10.0, 16.0)
        var hd := rng.randf_range(8.0, 12.0)
        if not _field_ok(c, fw, sd, hw, hd):
            continue
        var is_wheat := _fields.size() % 3 != 2
        _fields.append([c, fw, sd, hw, hd])
        _ground_patch(c, fw, sd, hw, hd, soil)
        # crop rows along the long side
        var mesh: Mesh = wheat_mesh if is_wheat else veg_mesh
        if mesh:
            var xs: Array[Transform3D] = []
            var row := -hd + 1.0
            while row < hd - 0.8:
                var col := -hw + 0.8
                while col < hw - 0.6:
                    var q := c + sd * (col + rng.randf_range(-0.12, 0.12)) + fw * row
                    var sc := rng.randf_range(0.26, 0.34) if is_wheat else rng.randf_range(0.30, 0.42)
                    var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * (1.25 if is_wheat else 1.0), sc))
                    xs.append(Transform3D(b, Vector3(q.x, height_at(q.x, q.z) + 0.05, q.z)))
                    col += 0.42 if is_wheat else 0.9
                row += 1.1
            var mm := MultiMesh.new()
            mm.transform_format = MultiMesh.TRANSFORM_3D
            mm.mesh = mesh
            mm.instance_count = xs.size()
            for i in range(xs.size()):
                mm.set_instance_transform(i, xs[i])
            var mmi := MultiMeshInstance3D.new()
            mmi.multimesh = mm
            if is_wheat:
                mmi.material_override = wheat
            mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            mmi.visibility_range_end = 320.0
            add_child(mmi)
        # fence round it, a gap on the side nearest town for the gate
        if fence_mesh:
            var fx: Array[Transform3D] = []
            var corners := [[-1.0, -1.0, 1.0, -1.0], [1.0, -1.0, 1.0, 1.0], [1.0, 1.0, -1.0, 1.0], [-1.0, 1.0, -1.0, -1.0]]
            var to_town := -c.normalized()
            for cr in corners:
                var p0 := c + sd * (hw * float(cr[0])) + fw * (hd * float(cr[1]))
                var p1 := c + sd * (hw * float(cr[2])) + fw * (hd * float(cr[3]))
                var L := p0.distance_to(p1)
                var dirv := (p1 - p0) / L
                var outward := ((p0 + p1) * 0.5 - c).normalized()
                var gate_side := outward.dot(to_town) > 0.7
                var n := int(L / fence_len)
                for k in range(n):
                    if gate_side and absf(float(k) - float(n) * 0.5) < 1.0:
                        continue
                    var q := p0 + dirv * (fence_len * (float(k) + 0.5))
                    var b := Basis(Vector3.UP, atan2(dirv.z, -dirv.x) * -1.0)
                    if absf(dirv.x) < absf(dirv.z):
                        b = Basis(Vector3.UP, PI * 0.5)
                    b = Basis(Vector3.UP, atan2(dirv.x, dirv.z) - PI * 0.5)
                    fx.append(Transform3D(b, Vector3(q.x, height_at(q.x, q.z), q.z)))
            var fmm := MultiMesh.new()
            fmm.transform_format = MultiMesh.TRANSFORM_3D
            fmm.mesh = fence_mesh
            fmm.instance_count = fx.size()
            for i in range(fx.size()):
                fmm.set_instance_transform(i, fx[i])
            var fmi := MultiMeshInstance3D.new()
            fmi.multimesh = fmm
            add_child(fmi)
        _objs.append([c, sqrt(hw * hw + hd * hd)])

## A farmstead beside some of the fields: farmhouse, barn, haystacks, a cart,
## and a track to the nearest road. Farmers work here.
func _nearest_road_point(p: Vector3) -> Vector3:
    var best := Vector3.ZERO
    var bd := 1e9
    for sg in _road_segs:
        if float(sg[2]) < 3.0:
            continue
        var a: Vector3 = sg[0]
        var b: Vector3 = sg[1]
        var ab := Vector2(b.x - a.x, b.z - a.z)
        var ap := Vector2(p.x - a.x, p.z - a.z)
        var t := 0.0
        if ab.length_squared() > 0.001:
            t = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
        var q := a.lerp(b, t)
        var d := Vector2(q.x - p.x, q.z - p.z).length()
        if d < bd:
            bd = d
            best = q
    return best

func _build_farms() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 616
    var hay := StandardMaterial3D.new()
    hay.albedo_color = Color(0.85, 0.70, 0.36)
    hay.roughness = 1.0
    for f in _fields:
        if farms.size() >= 3:
            break
        var c: Vector3 = f[0]
        var fw: Vector3 = f[1]
        var sd: Vector3 = f[2]
        for sgn in [1.0, -1.0]:
            var hp: Vector3 = c + sd * (float(f[3]) + 11.0) * float(sgn)
            var ok := true
            for t in [hp, hp + fw * 8.0, hp - fw * 8.0]:
                var tv: Vector3 = t
                if not is_clear(tv, 5.0) or road_dist(tv) < 4.0 or _in_field(tv, 2.0):
                    ok = false
            if not ok:
                continue
            var road := _nearest_road_point(hp)
            var to_road := (road - hp)
            to_road.y = 0.0
            to_road = to_road.normalized()
            var house_path: String = String(HOUSES["d"]["path"])
            var h: Node3D = (load(house_path) as PackedScene).instantiate()
            var house_pos := hp + fw * 5.0
            h.position = Vector3(house_pos.x, height_at(house_pos.x, house_pos.z), house_pos.z)
            h.rotation.y = atan2(to_road.x, to_road.z)
            add_child(h)
            _dress(h, "green")
            var barn: Node3D = (load(String(HOUSES["lm_granary"]["path"])) as PackedScene).instantiate()
            var barn_pos := hp - fw * 7.0
            barn.position = Vector3(barn_pos.x, height_at(barn_pos.x, barn_pos.z), barn_pos.z)
            barn.rotation.y = atan2(to_road.x, to_road.z)
            add_child(barn)
            _dress(barn, "red")
            # haystacks
            for k in range(4):
                var sp := hp + sd * (float(sgn) * rng.randf_range(6.0, 9.0)) + fw * rng.randf_range(-8.0, 8.0)
                var stack := MeshInstance3D.new()
                var cm := CylinderMesh.new()
                cm.top_radius = 0.3
                cm.bottom_radius = 1.4
                cm.height = 2.4
                stack.mesh = cm
                stack.material_override = hay
                stack.position = Vector3(sp.x, height_at(sp.x, sp.z) + 1.1, sp.z)
                add_child(stack)
            var cart := hp + to_road * 6.0 + fw * 2.0
            _spawn_raw(MKPROPS, "Prop_Wagon", Vector3(cart.x, height_at(cart.x, cart.z), cart.z), rng.randf() * TAU, 0.75)
            var door := house_pos + to_road * (_depth_of("d") * 0.5 + 1.4)
            _road_strip([door, door.lerp(road, 0.5), road], 3.0, true)
            _objs.append([hp, 14.0])
            farms.append(hp)
            _farm_frames.append([hp, fw, sd, float(sgn), to_road])
            _sites.append({"landmark": "farm", "door": door, "door_in": door - to_road * 1.8, "pos": door})
            break

## ---------------------------------------------------------------- A4 animals
## Quaternius Farm Animals (converted from .blend, every action kept) and
## GobKit duck/corgi/fox. Real sizes: the source files are all over the place
## (a 9 m cow, a 400 m duck), so each gets a scale to a real body length.
const ANIMALS := {
    "Cow":   ["res://assets/animals/Cow.glb", 0.25, 0.9],
    "Horse": ["res://assets/animals/Horse.glb", 0.27, 1.1],
    "Pig":   ["res://assets/animals/Pig.glb", 0.145, 0.8],
    "Sheep": ["res://assets/animals/Sheep.glb", 0.22, 0.8],
    "Llama": ["res://assets/animals/Llama.glb", 0.36, 0.9],
    "Pug":   ["res://assets/animals/Pug.glb", 0.17, 1.4],
    "Duck":  ["res://assets/animals/Duck.glb", 0.0019, 0.5],
    "Corgi": ["res://assets/animals/Corgi.glb", 0.0019, 1.5],
    "Fox":   ["res://assets/animals/Red.glb", 0.0022, 1.3],
    "Foal":  ["res://assets/animals/Horse.glb", 0.17, 0.9],
    "Hen":   ["proc:hen", 1.0, 0.7],
    "Cat":   ["proc:cat", 1.0, 0.9],
}
var _flock_pens := []         # [centre, fw, sd, hw, hd] of each sheep pen (D5 sheepdogs)
var _paddock := []            # [centre, fw, sd] of the horse paddock

func _animal(kind: String, c: Vector3, fw: Vector3, sd: Vector3, hw: float, hd: float, at: Vector3, float_y := INF) -> void:
    var a := Animal.new()
    var d: Array = ANIMALS[kind]
    a.model = d[0]
    a.scale_f = float(d[1])
    a.speed = float(d[2])
    a.town = self
    a.kind = kind
    a.centre = c
    a.fwd = fw
    a.side = sd
    a.hw = hw
    a.hd = hd
    a.float_y = float_y
    if float_y == INF:
        at = keep_walkable(at)            # never start inside a stall or a house
    a.position = Vector3(at.x, float_y if float_y != INF else height_at(at.x, at.z), at.z)
    a.rotation.y = randf() * TAU
    a.name = kind
    add_child(a)
    animals.append(a)

func _pen(c: Vector3, fw: Vector3, sd: Vector3, hw: float, hd: float, gate_dir: Vector3) -> void:
    var corners := [[-1.0, -1.0, 1.0, -1.0], [1.0, -1.0, 1.0, 1.0], [1.0, 1.0, -1.0, 1.0], [-1.0, 1.0, -1.0, -1.0]]
    for cr in corners:
        var p0 := c + sd * (hw * float(cr[0])) + fw * (hd * float(cr[1]))
        var p1 := c + sd * (hw * float(cr[2])) + fw * (hd * float(cr[3]))
        var L := p0.distance_to(p1)
        var dirv := (p1 - p0) / L
        var outward := ((p0 + p1) * 0.5 - c).normalized()
        var gate_side := outward.dot(gate_dir) > 0.7
        var n := int(L / 2.0)
        for k in range(n):
            if gate_side and absf(float(k) - float(n) * 0.5) < 0.6:
                continue
            var q := p0 + dirv * (2.0 * (float(k) + 0.5))
            _spawn_raw(MKPROPS, "Prop_WoodenFence_Single", Vector3(q.x, height_at(q.x, q.z), q.z), atan2(dirv.x, dirv.z) - PI * 0.5, 1.0)
    # trough + hay inside
    var tr := c + sd * (hw - 1.2) + fw * (hd - 1.4)
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.albedo_color = Color(0.5, 0.38, 0.27)
    _box(Vector3(1.8, 0.45, 0.6), Vector3(tr.x, height_at(tr.x, tr.z) + 0.22, tr.z), wood, atan2(sd.x, sd.z))
    var wtr := StandardMaterial3D.new()
    wtr.albedo_color = Color(0.15, 0.3, 0.38)
    wtr.roughness = 0.1
    _box(Vector3(1.6, 0.03, 0.42), Vector3(tr.x, height_at(tr.x, tr.z) + 0.43, tr.z), wtr, atan2(sd.x, sd.z))
    _pens.append(c)

func _spawn_animals() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7070
    # one pen per farmstead, on the far side from the house's road
    var herds := [["Cow", 4], ["Sheep", 6], ["Pig", 4]]
    for i in range(_farm_frames.size()):
        var ff: Array = _farm_frames[i]
        var hp: Vector3 = ff[0]
        var fw: Vector3 = ff[1]
        var sd: Vector3 = ff[2]
        var sg: float = float(ff[3])
        var to_road: Vector3 = ff[4]
        var pc := hp + sd * (sg * 21.0)          # clear of the farmhouse wall
        if not is_clear(pc, 6.0) or _in_field(pc, 6.0) or road_dist(pc) < 8.0:
            pc = hp - to_road * 16.0
        if _in_field(pc, 6.0) or road_dist(pc) < 8.0 or river_dist(pc.x, pc.z) < RIVER_W + RIVER_BANK + 10.0:
            continue
        var hw := 8.0
        var hd := 6.0
        _pen(pc, fw, sd, hw, hd, (hp - pc).normalized())
        _objs.append([pc, 10.0])
        var hk: Array = herds[i % herds.size()]
        if String(hk[0]) == "Sheep":
            _flock_pens.append([pc, fw, sd, hw - 1.4, hd - 1.4])
        for k in range(int(hk[1])):
            var at := pc + sd * rng.randf_range(-hw + 1.5, hw - 1.5) + fw * rng.randf_range(-hd + 1.5, hd - 1.5)
            _animal(String(hk[0]), pc, fw, sd, hw - 1.4, hd - 1.4, at)
    # horses + llamas grazing loose in the meadow by the first farm (a paddock)
    if not _farm_frames.is_empty():
        var hp0: Vector3 = _farm_frames[0][0]
        var out := Vector3(hp0.x, 0, hp0.z).normalized()
        var pd := hp0 + out * 34.0
        if river_dist(pd.x, pd.z) < RIVER_W + RIVER_BANK + 16.0:
            pd = hp0 - out * 30.0 + Vector3(-out.z, 0, out.x) * 26.0
        if road_dist(pd) > 12.0 and not _in_field(pd, 10.0) and river_dist(pd.x, pd.z) > RIVER_W + RIVER_BANK + 16.0:
            var pfw := out
            var psd := Vector3(-out.z, 0, out.x)
            _pen(pd, pfw, psd, 13.0, 10.0, -out)
            _paddock = [pd, pfw, psd]
            _objs.append([pd, 16.0])
            for k in range(3):
                _animal("Horse", pd, pfw, psd, 11.5, 8.5, pd + psd * rng.randf_range(-8, 8) + pfw * rng.randf_range(-6, 6))
            for k in range(2):
                _animal("Llama", pd, pfw, psd, 11.5, 8.5, pd + psd * rng.randf_range(-8, 8) + pfw * rng.randf_range(-6, 6))
    # ducks on the slow water, a little flotilla at a few spots
    for xx in [-80.0, 12.0, 95.0, -150.0]:
        var x: float = float(xx)
        var rz := river_z(x)
        var c := Vector3(x, 0, rz)
        for k in range(rng.randi_range(3, 5)):
            _animal("Duck", c, Vector3(0, 0, 1), Vector3(1, 0, 0), 9.0, RIVER_W * 0.55,
                    c + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-2, 2)), WATER_Y + 0.02)
    # dogs about town: round the square and the streets near it
    if _market_pos != Vector3.ZERO:
        for k in range(4):
            var kind := "Pug" if k % 2 == 0 else "Corgi"
            _animal(kind, _market_pos, Vector3(0, 0, 1), Vector3(1, 0, 0), 9.0, 9.0,
                    _market_pos + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6)))
    # a fox at the edge of the lumber mill's woods
    if landmarks.has("lm_sawmill"):
        var sw: Vector3 = landmarks["lm_sawmill"][0]
        var fc := sw + Vector3(-18, 0, 30)
        _animal("Fox", fc, Vector3(0, 0, 1), Vector3(1, 0, 0), 10.0, 8.0, fc)
    # birds: little dark shapes wheeling over the valley, crows over the scar
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.08, 0.08, 0.1)
    dark.cull_mode = BaseMaterial3D.CULL_DISABLED
    var spots := [[Vector3(0, 42, 0), 70.0, 6], [Vector3(-160, 34, 70), 40.0, 4], [_scar + Vector3(0, 24, 0), 22.0, 5]]
    for sp in spots:
        for k in range(int(sp[2])):
            var b := Node3D.new()
            for side_s in [-1.0, 1.0]:
                var wing := MeshInstance3D.new()
                var wm := BoxMesh.new()
                wm.size = Vector3(0.55, 0.03, 0.22)
                wing.mesh = wm
                wing.material_override = dark
                wing.position = Vector3(0.28 * float(side_s), 0, 0)
                b.add_child(wing)
            var body := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(0.12, 0.1, 0.35)
            body.mesh = bm
            body.material_override = dark
            b.add_child(body)
            b.scale = Vector3.ONE * 1.4
            add_child(b)
            var w := rng.randf_range(0.12, 0.25) * (1.0 if rng.randf() < 0.5 else -1.0)
            _birds.append([b, sp[0] as Vector3 + Vector3(rng.randf_range(-8, 8), rng.randf_range(-4, 6), rng.randf_range(-8, 8)),
                           float(sp[1]) * rng.randf_range(0.6, 1.1), w, rng.randf() * TAU])
    _spawn_more_animals(dark)

## D5: hens in a fenced run by each farmhouse, a sheepdog walking the edge of
## each flock, more horses and a foal in the paddock, cats about the streets,
## crows wheeling over the fields. Own rng so the older herds stay where they were.
func _spawn_more_animals(dark: StandardMaterial3D) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 5055
    for i in range(_farm_frames.size()):
        var ff: Array = _farm_frames[i]
        var hp: Vector3 = ff[0]
        var fw: Vector3 = ff[1]
        var sd: Vector3 = ff[2]
        var sg: float = float(ff[3])
        var to_road: Vector3 = ff[4]
        var run := Vector3.INF
        # (the farm's own yard is in _objs, so is_clear() refuses all of it: test
        # the footprints, the other pens, the fields, the road and the river instead)
        for cand in [hp - sd * (sg * 13.0), hp + fw * 13.0, hp - fw * 13.0, hp - to_road * 13.0,
                     hp - sd * (sg * 17.0), hp + fw * 17.0, hp - fw * 17.0, hp - to_road * 17.0]:
            var cv: Vector3 = cand
            var near_pen := false
            for pc in _pens:
                if Vector2(cv.x - (pc as Vector3).x, cv.z - (pc as Vector3).z).length() < 15.0:
                    near_pen = true
            if not near_pen and not _in_field(cv, 4.0) and road_dist(cv) > 6.0 \
                    and river_dist(cv.x, cv.z) > RIVER_W + RIVER_BANK + 5.0 and solid_at(cv, 6.5).is_empty():
                run = cv
                break
        if run == Vector3.INF:
            continue
        _pen(run, fw, sd, 3.5, 3.0, (hp - run).normalized())
        _objs.append([run, 5.0])
        for k in range(rng.randi_range(5, 7)):
            _animal("Hen", run, fw, sd, 2.7, 2.2, run + sd * rng.randf_range(-2.4, 2.4) + fw * rng.randf_range(-1.9, 1.9))
    # a sheepdog with every flock, working the fence line
    for fp in _flock_pens:
        var c: Vector3 = fp[0]
        _animal("Corgi", c, fp[1], fp[2], float(fp[3]), float(fp[4]), c + (fp[2] as Vector3) * float(fp[3]))
        (animals[animals.size() - 1] as Animal).edge = true
    # the paddock: two more horses and a foal (five grown horses in all)
    if not _paddock.is_empty():
        var pd: Vector3 = _paddock[0]
        var pfw: Vector3 = _paddock[1]
        var psd: Vector3 = _paddock[2]
        for kind in ["Horse", "Horse", "Foal"]:
            _animal(String(kind), pd, pfw, psd, 11.5, 8.5, pd + psd * rng.randf_range(-8, 8) + pfw * rng.randf_range(-6, 6))
    # cats about the streets and doorsteps inside the town
    if _market_pos != Vector3.ZERO:
        var cats := 0
        var tries := 0
        while cats < 8 and tries < 600:
            tries += 1
            var a := rng.randf() * TAU
            var r := rng.randf_range(16.0, 62.0)
            var p := _market_pos + Vector3(cos(a) * r, 0.0, sin(a) * r)
            if road_dist(p) > 3.5 or not solid_at(p, 1.2).is_empty() or river_dist(p.x, p.z) < RIVER_W + RIVER_BANK + 3.0:
                continue
            _animal("Cat", p, Vector3(0, 0, 1), Vector3(1, 0, 0), 4.0, 4.0, p)
            cats += 1
    # crows over the fields
    var fi := 0
    for f in _fields:
        if fi >= 5:
            break
        fi += 1
        var fc: Vector3 = f[0]
        var top := fc + Vector3(0, height_at(fc.x, fc.z) + 15.0, 0)
        var rad := 8.0 + maxf(float(f[3]), float(f[4])) * 0.35
        for k in range(3):
            var b := Node3D.new()
            for side_s in [-1.0, 1.0]:
                var wing := MeshInstance3D.new()
                var wm := BoxMesh.new()
                wm.size = Vector3(0.55, 0.03, 0.22)
                wing.mesh = wm
                wing.material_override = dark
                wing.position = Vector3(0.28 * float(side_s), 0, 0)
                b.add_child(wing)
            var body := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(0.12, 0.1, 0.35)
            body.mesh = bm
            body.material_override = dark
            b.add_child(body)
            b.scale = Vector3.ONE * 1.3
            add_child(b)
            var w := rng.randf_range(0.15, 0.3) * (1.0 if rng.randf() < 0.5 else -1.0)
            _birds.append([b, top + Vector3(rng.randf_range(-4, 4), rng.randf_range(-2, 4), rng.randf_range(-4, 4)),
                           rad * rng.randf_range(0.6, 1.1), w, rng.randf() * TAU])

## ---------------------------------------------------------------- fishing
## Timber docks on the town bank, a fisher on each. Fishing rules are in
## scripts/fishing.gd, the visible cast/bite/reel in scripts/angler.gd.
const DOCK_Y := 0.35

func river_z(x: float) -> float:
    var best := 1e9
    var bz := 0.0
    var z := 40.0
    while z < 240.0:
        var d := river_dist(x, z)
        if d < best:
            best = d
            bz = z
        z += 0.5
    return bz

func _build_docks() -> void:
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.55, 0.42, 0.30)
    for xx in [-30.0, 34.0]:
        var x: float = float(xx)
        var rz := river_z(x)
        var land := Vector3(x, 0, rz - RIVER_W - RIVER_BANK - 1.5)
        var end := Vector3(x, 0, rz - RIVER_W * 0.25)
        if not is_clear(land, 2.0):
            land.x += 8.0
            end.x += 8.0
        var fw := Vector3(0, 0, 1)
        var L := end.z - land.z
        var mid := (land + end) * 0.5
        _box(Vector3(3.0, 0.22, L), Vector3(mid.x, DOCK_Y, mid.z), wood)
        # planks read as planks: thin dark gaps across the deck
        var gap := StandardMaterial3D.new()
        gap.albedo_color = Color(0.16, 0.11, 0.07)
        var zz := land.z + 0.6
        while zz < end.z:
            _box(Vector3(3.02, 0.03, 0.05), Vector3(mid.x, DOCK_Y + 0.11, zz), gap)
            zz += 0.6
        # piles down into the water, a mooring post at the end
        zz = land.z + 3.0
        while zz <= end.z:
            for sx in [-1.35, 1.35]:
                _box(Vector3(0.28, 3.6, 0.28), Vector3(mid.x + float(sx), DOCK_Y - 1.7, zz), wood)
            zz += 3.0
        _box(Vector3(0.3, 1.2, 0.3), Vector3(end.x + 1.35, DOCK_Y + 0.6, end.z - 0.3), wood)
        # a bucket for the catch, a barrel, and a rowboat tied alongside
        var bp := end - fw * 2.2 + Vector3(-0.9, 0, 0)
        _spawn_raw("res://assets/fishing/", "Bucket_Wooden_1", Vector3(bp.x, DOCK_Y + 0.11, bp.z), 0.0, PROP_SCALE)
        var bb := end - fw * 4.5 + Vector3(0.95, 0, 0)
        _spawn_raw("res://assets/fishing/", "Barrel", Vector3(bb.x, DOCK_Y + 0.11, bb.z), 0.3, PROP_SCALE)
        var boat_path := "res://assets/fishing/boat_small.gltf"
        if ResourceLoader.exists(boat_path):
            var bt: Node3D = (load(boat_path) as PackedScene).instantiate()
            var boatp := end - fw * 3.0 + Vector3(3.3, 0, 0)
            bt.position = Vector3(boatp.x, WATER_Y - 0.15, boatp.z)
            bt.rotation.y = PI * 0.5
            bt.scale = Vector3.ONE * 0.55
            add_child(bt)
        _objs.append([mid, L * 0.5 + 2.0])
        docks.append([Vector3(end.x, 0, end.z), fw])
    # lily pads drift in the slow water near the banks, away from docks and bridge
    var rng := RandomNumberGenerator.new()
    rng.seed = 909
    for i in range(70):
        var x := rng.randf_range(-260.0, 260.0)
        if absf(x) < 12.0 or absf(x + 30.0) < 8.0 or absf(x - 34.0) < 8.0:
            continue
        var side := -1.0 if rng.randf() < 0.5 else 1.0
        var lp := Vector3(x, 0, river_z(x) + side * rng.randf_range(RIVER_W * 0.55, RIVER_W * 0.95))
        var nm := "waterlily_A" if rng.randf() < 0.5 else "waterlily_B"
        _spawn_raw("res://assets/fishing/", nm, Vector3(lp.x, WATER_Y + 0.02, lp.z), rng.randf_range(0, TAU), rng.randf_range(1.2, 2.2))

func _on_caught(item: Dictionary, who: String) -> void:
    fishing_log.append({"who": who, "id": item.get("id"), "name": item.get("name"),
                        "rarity": item.get("rarity"), "value": item.get("value", 0)})

## Chat / hero entry point (!fish): roll a cast with the hero's luck and lure,
## and if a dock is free play it out there so the stream sees the catch.
func go_fish(hero_name: String, luck := 0, lure := 0, hook_bonus := Fishing.DOCK_HAND) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var res := Fishing.cast_result(rng, luck, lure, hook_bonus)
    if bool(res.get("caught", false)):
        for a in anglers:
            var an: Angler = a
            if an.state == Angler.S.WAIT and an.forced.is_empty():
                an.forced = res["item"]
                an.who = hero_name
                break
        _on_caught(res["item"], hero_name)
    return res

func _process(delta: float) -> void:
    if economy:
        _caravan_pass(delta)
    if chat:
        _viewer_muster(delta)
    if persist:
        _save_t -= delta
        if _save_t <= 0.0:
            _save_t = 30.0
            roster.save_all()
    var tnow := Time.get_ticks_msec() / 1000.0
    for b in _birds:
        var bn: Node3D = b[0]
        var c: Vector3 = b[1]
        var r: float = b[2]
        var w: float = b[3]
        var a := tnow * w + float(b[4])
        bn.position = c + Vector3(cos(a) * r, sin(tnow * 0.7 + float(b[4])) * 2.0, sin(a) * r)
        bn.rotation.y = -a + (PI if w > 0.0 else 0.0)
        var flap := sin(tnow * 9.0 + float(b[4])) * 0.6
        (bn.get_child(0) as Node3D).rotation.z = flap
        (bn.get_child(1) as Node3D).rotation.z = -flap
    for pl in _pulses:
        var lt: OmniLight3D = pl[0]
        # uneven, stuttering pulse: the scar never settles into a rhythm
        lt.light_energy = float(pl[1]) * (0.65 + 0.35 * sin(tnow * float(pl[2]) + float(pl[3])) * sin(tnow * 0.37 * float(pl[2]) + 1.7))
    for sp in _spinners:
        var n: Node3D = sp[0]
        n.rotate_object_local(sp[1], float(sp[2]) * delta)
    _lod_t -= delta
    if _lod_t <= 0.0:
        _lod_t = 0.25
        _lod_pass()

## ---- D7: far-away LOD. Townsfolk past LOD_NEAR from the camera step and
## animate every 2nd physics tick, past LOD_FAR every 4th (townsfolk.gd set_lod).
## Viewers' heroes and the mounted watch always run full; so does everyone while
## raiders are in the valley (raids.gd moves the fighters itself).
const LOD_NEAR := 60.0
const LOD_FAR := 120.0
var _lod_t := 0.0
var lod_counts := [0, 0, 0]
var lod_on := true          # tools compare FPS with it off

func _lod_pass() -> void:
    var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
    var fight: bool = raids != null and not (raids as Raids).raiders.is_empty()
    lod_counts = [0, 0, 0]
    for p in people:
        if not is_instance_valid(p) or not (p is Townsfolk):
            continue
        var v: Townsfolk = p
        var l := 0
        if lod_on and cam != null and not fight and not (v is HeroBody) and not (v is Cavalry):
            var d := cam.global_position.distance_to(v.global_position)
            l = 2 if d > LOD_FAR else (1 if d > LOD_NEAR else 0)
        v.set_lod(l)
        lod_counts[l] += 1

## ---------------------------------------------------------------- placement
## ONE rule for everything that stands on the ground: not in a carriageway,
## not inside a house, not on the square, not on another structure, not in
## the wall or the river. A tree in the middle of a road was a bug in every
## scatter pass that had its own ad-hoc test; they all use this now.
func _collect_road_segs() -> void:
    var done := {}
    for cell in road_cells:
        for n in Hex.neighbours(cell):
            if not road_cells.has(n):
                continue
            var key := "%d,%d|%d,%d" % [mini(cell.x, n.x), mini(cell.y, n.y), maxi(cell.x, n.x), maxi(cell.y, n.y)]
            if done.has(key):
                continue
            done[key] = true
            _road_segs.append([Hex.pos(cell.x, cell.y), Hex.pos(n.x, n.y), ROAD_W * 0.5])
    # a road cell with no road neighbour is still a paved patch
    for cell in road_cells:
        var c := Hex.pos(cell.x, cell.y)
        _road_segs.append([c, c, ROAD_W * 0.5])

func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
    var ab := Vector2(b.x - a.x, b.z - a.z)
    var ap := Vector2(p.x - a.x, p.z - a.z)
    var l2 := ab.length_squared()
    var t := 0.0
    if l2 > 0.0001:
        t = clampf(ap.dot(ab) / l2, 0.0, 1.0)
    return (ap - ab * t).length()

## distance from p to the nearest road EDGE (negative = on the road)
func road_dist(p: Vector3) -> float:
    var best := 1e9
    for sg in _road_segs:
        var d: float = _seg_dist(p, sg[0], sg[1]) - float(sg[2])
        if d < best:
            best = d
    return best

func _plot_r(plot: Dictionary) -> float:
    var sh: String = String(plot.get("shape", "a"))
    var dep: float = float((HOUSES.get(sh, {"depth": 10.0}) as Dictionary)["depth"])
    return dep * 0.5 + 1.2

func is_clear(p: Vector3, r: float, near_facade := false) -> bool:
    if road_dist(p) < r + 0.5:
        return false
    if _market_pos != Vector3.ZERO and Vector2(p.x - _market_pos.x, p.z - _market_pos.z).length() < 20.0 + r:
        return false
    if not near_facade:
        for plot in plots:
            var pp: Vector3 = plot["pos"]
            if Vector2(p.x - pp.x, p.z - pp.z).length() < _plot_r(plot) + r:
                return false
    for o in _objs:
        var op: Vector3 = o[0]
        if Vector2(p.x - op.x, p.z - op.z).length() < float(o[1]) + r:
            return false
    if river_pts.size() > 1 and river_dist(p.x, p.z) < RIVER_W + 1.5 + r:
        return false
    if _wall_info.has("ax"):
        var ax: float = float(_wall_info["ax"])
        var az: float = float(_wall_info["az"])
        var e := sqrt(pow(p.x / ax, 2.0) + pow(p.z / az, 2.0))
        if absf(e - 1.0) * minf(ax, az) < 3.5 + r:
            return false
    return true

## Countryside: trees on the hills outside the wall, never on the gate roads.
func _scatter_country() -> void:
    if not _wall_info.has("ax"):
        return
    var ax: float = float(_wall_info["ax"])
    var az: float = float(_wall_info["az"])
    var rng := RandomNumberGenerator.new()
    rng.seed = 808
    var ext: float = maxf(Hex.COLS * Hex.COL_W, Hex.ROWS * Hex.ROW_H) * 0.78
    var made := 0
    var tries := 0
    while made < 170 and tries < 2500:
        tries += 1
        var p := Vector3(rng.randf_range(-ext, ext), 0.0, rng.randf_range(-ext, ext))
        if sqrt(pow(p.x / ax, 2.0) + pow(p.z / az, 2.0)) < 1.08:
            continue
        var is_tree := rng.randf() < 0.8
        var r := 1.8 if is_tree else 0.9
        if not is_clear(p, r):
            continue
        var pool: Array = TREES if is_tree else BUSHES
        var nm: String = String(pool[rng.randi() % pool.size()])
        if _spawn(NATURE, nm, p, rng.randf_range(0.0, TAU),
                rng.randf_range(0.9, 1.5) if is_tree else rng.randf_range(0.8, 1.2)):
            _objs.append([p, r])
            made += 1
            _nature_made += 1

## ---------------------------------------------------------------- shops
## A shop is a house that WORKS: its frontage, a yard beside it where the
## trade happens in the open, and a sign at the street. The yard takes the
## place of the next plot along, so nothing is built on top of it.
const SHOP_PLAN := [
    ["blacksmith", "craft", "Blacksmith"],
    ["blacksmith", "craft", "Blacksmith"],
    ["armorer", "craft", "Armourer"],
    ["armorer", "garrison", "Armourer"],
    ["apothecary", "temple", "Apothecary"],
    ["apothecary", "market", "Potions & Remedies"],
    ["store", "market", "General Store"],
    ["store", "homes_s", "General Store"],
    ["tavern", "market", "Tavern"],
    ["tavern", "homes_w", "Tavern"],
]
const SHOP_TINT := {"blacksmith": Color(0.95, 0.55, 0.25), "armorer": Color(0.75, 0.80, 0.90),
    "apothecary": Color(0.55, 0.95, 0.55), "store": Color(0.95, 0.85, 0.55), "tavern": Color(0.95, 0.70, 0.45)}

func _fwd(plot: Dictionary) -> Vector3:
    var yaw: float = float(plot["yaw"])
    return Vector3(sin(yaw), 0.0, cos(yaw))

func _pick_shops() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 3131
    for row in SHOP_PLAN:
        var kind: String = row[0]
        var dist: String = row[1]
        var cands: Array = []
        for plot in plots:
            if plot.has("shop") or plot.has("landmark") or String(plot["district"]) != dist:
                continue
            # street-facing ones only (the back rank faces away from the road)
            var door: Vector3 = plot["pos"] + _fwd(plot) * (_plot_r(plot) + 1.0)
            if road_dist(door) > 3.5:
                continue
            cands.append(plot)
        if cands.is_empty():
            continue
        # shops crowd toward the market; craft trades anywhere in their quarter
        if kind == "store" or kind == "tavern" or kind == "apothecary":
            cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
                return _dist_to_market(a["pos"]) < _dist_to_market(b["pos"]))
        var placed := false
        for i in range(mini(cands.size(), 12)):
            var plot: Dictionary = cands[i] if kind != "blacksmith" and kind != "armorer" else cands[rng.randi() % cands.size()]
            var f := _fwd(plot)
            var side := Vector3(-f.z, 0.0, f.x)
            for sgn in [1.0, -1.0]:
                var yard: Vector3 = plot["pos"] + side * (float(sgn) * 9.0) + f * 1.0
                if road_dist(yard) < 4.6:
                    continue
                if _dist_to_market(yard) < 24.0:
                    continue
                if river_dist(yard.x, yard.z) < RIVER_W + RIVER_BANK + 4.0:
                    continue
                var clash := false
                for o in _objs:
                    if (o[0] as Vector3).distance_to(yard) < float(o[1]) + 6.0:
                        clash = true
                for other in plots:
                    if other != plot and other.has("shop") and (other["pos"] as Vector3).distance_to(yard) < 12.0:
                        clash = true
                if clash:
                    continue
                # clear the yard: any house standing on it goes
                var kept := []
                for other in plots:
                    var yr := [Vector2(yard.x, yard.z), Vector2(side.x, side.z), Vector2(f.x, f.z), Vector2(4.6, 4.6)]
                    if other == plot or not _rects_overlap(yr, _rect(other)):
                        kept.append(other)
                plots = kept
                plot["shop"] = kind
                plot["sign"] = row[2]
                plot["yard"] = yard
                plot["side"] = side * float(sgn)
                _objs.append([yard, 4.6])
                placed = true
                break
            if placed:
                break

func _dist_to_market(p: Vector3) -> float:
    return Vector2(p.x - _market_pos.x, p.z - _market_pos.z).length()

## place a prop in a yard's own frame: x along the street, z toward it
func _yard(nm: String, y: Vector3, side: Vector3, f: Vector3, x: float, z: float,
           yaw_off: float = 0.0, dir: String = PROPS) -> Node3D:
    var p := y + side * x + f * z
    var yaw := atan2(f.x, f.z) + yaw_off
    var path := dir + nm + ".gltf"
    if not ResourceLoader.exists(path):
        return null
    if not _scene.has(path):
        _scene[path] = load(path)
    var n: Node3D = _scene[path].instantiate()
    if dir == PROPS:
        n.scale = Vector3.ONE * PROP_SCALE
    n.position = Vector3(p.x, height_at(p.x, p.z), p.z)
    n.rotation.y = yaw
    add_child(n)
    if dir == MKPROPS:
        _dress(n, "red")
    _props_made += 1
    _solid_of(n)
    return n

## top of a placed model, so things can sit ON a table instead of in it
func _top(n: Node3D) -> float:
    var top := -1e9
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var mi: MeshInstance3D = c
            var ab: AABB = mi.global_transform * mi.get_aabb()
            top = maxf(top, ab.end.y)
        for g in c.get_children():
            st.append(g)
    return top

func _on_top(nm: String, table: Node3D, dx: float, dz: float, yaw: float = 0.0) -> void:
    if table == null:
        return
    var path := PROPS + nm + ".gltf"
    if not ResourceLoader.exists(path):
        return
    if not _scene.has(path):
        _scene[path] = load(path)
    var n: Node3D = _scene[path].instantiate()
    n.scale = Vector3.ONE * PROP_SCALE
    var b := table.global_transform.basis
    var p := table.global_position + b.x.normalized() * dx + b.z.normalized() * dz
    n.position = Vector3(p.x, _top(table) - 0.02, p.z)
    n.rotation.y = table.rotation.y + yaw
    add_child(n)
    _props_made += 1

func _glow(pos: Vector3, col: Color, energy: float, rng_m: float) -> void:
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = energy
    l.omni_range = rng_m
    l.position = pos
    add_child(l)

func _dress_shops() -> void:
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.uv1_scale = Vector3(0.35, 0.35, 0.35)
    wood.albedo_color = Color(0.62, 0.48, 0.36)
    for plot in plots:
        if not plot.has("shop"):
            continue
        var kind: String = plot["shop"]
        var y: Vector3 = plot["yard"]
        var side: Vector3 = plot["side"]
        var f := _fwd(plot)
        var g := height_at(y.x, y.z)
        shops.append([kind, y, f])
        _shop_frame[kind] = [y, side, f]
        # fence along the back and the far side of the yard
        for i in range(4):
            _yard("Prop_WoodenFence_Single", y, side, f, -3.0 + float(i) * 2.0, -4.2, 0.0, MKPROPS)
        for i in range(4):
            _yard("Prop_WoodenFence_Single", y, side, f, 4.2, -3.0 + float(i) * 2.0, PI * 0.5, MKPROPS)
        match kind:
            "blacksmith":
                _tier_rack(y + side * -1.8 + f * 1.4, f, side, "axe")
                # forge: stone hearth with live coals, a chimney behind it
                var hp := y + side * 1.5 + f * -2.6
                _box(Vector3(2.6, 1.1, 1.9), Vector3(hp.x, g + 0.55, hp.z), _stone(), atan2(f.x, f.z))
                var coal := StandardMaterial3D.new()
                coal.albedo_color = Color(0.2, 0.05, 0.0)
                coal.emission_enabled = true
                coal.emission = Color(1.0, 0.42, 0.08)
                coal.emission_energy_multiplier = 3.0
                _box(Vector3(1.9, 0.12, 1.3), Vector3(hp.x, g + 1.12, hp.z), coal, atan2(f.x, f.z))
                var cp := hp - f * 0.8
                _box(Vector3(1.1, 5.5, 1.0), Vector3(cp.x, g + 2.75, cp.z), _stone(), atan2(f.x, f.z))
                _glow(Vector3(hp.x, g + 1.8, hp.z), Color(1.0, 0.55, 0.2), 2.2, 7.0)
                _yard("Anvil", y, side, f, 0.6, 0.4, 0.4)
                _yard("Whetstone", y, side, f, -2.4, 0.2, 1.2)
                _yard("Barrel", y, side, f, 3.0, -2.6)
                _yard("Bucket_Wooden_1", y, side, f, 2.6, -1.2)
                _yard("Crate_Metal", y, side, f, -2.6, -2.8, 0.3)
                var wb := _yard("Workbench", y, side, f, -1.2, -3.0)
                _on_top("Pickaxe_Bronze", wb, 0.0, 0.0, 0.5)
            "armorer":
                _tier_rack(y + side * 0.6 + f * -1.6, f, side, "blade")
                _yard("WeaponStand", y, side, f, -2.4, -3.0)
                _yard("WeaponStand", y, side, f, 0.0, -3.1)
                _yard("Dummy", y, side, f, 2.4, -0.8, PI)
                _yard("Dummy", y, side, f, 2.4, 1.6, PI)
                _yard("Chest_Wood", y, side, f, -2.8, 0.6, 0.2)
                _yard("Peg_Rack", y, side, f, 2.8, -3.2)
                var tb := _yard("Table_Large", y, side, f, -0.6, 0.8)
                _on_top("Sword_Bronze", tb, -0.4, 0.0, 1.57)
                _on_top("Shield_Wooden", tb, 0.5, 0.0, 0.0)
                _on_top("Axe_Bronze", tb, 0.0, 0.25, 1.2)
            "apothecary":
                var cau := _yard("Cauldron", y, side, f, 1.2, -1.4)
                if cau != null:
                    var brew := StandardMaterial3D.new()
                    brew.albedo_color = Color(0.1, 0.6, 0.15)
                    brew.emission_enabled = true
                    brew.emission = Color(0.3, 1.0, 0.35)
                    brew.emission_energy_multiplier = 1.6
                    var disc := MeshInstance3D.new()
                    var dm := CylinderMesh.new()
                    var top := _top(cau)
                    dm.top_radius = 0.42 * PROP_SCALE
                    dm.bottom_radius = dm.top_radius
                    dm.height = 0.02
                    disc.mesh = dm
                    disc.material_override = brew
                    var cpos := cau.global_position
                    disc.position = Vector3(cpos.x, top - 0.12, cpos.z)
                    add_child(disc)
                    _glow(Vector3(cpos.x, top + 0.8, cpos.z), Color(0.4, 1.0, 0.45), 1.4, 5.0)
                # both are WALL shelves: hung on the back fence at hand height,
                # not stood on the dirt
                var sb := _yard("Shelf_Small_Bottles", y, side, f, -2.6, -3.95)
                if sb:
                    sb.position.y += 0.95
                var ss := _yard("Shelf_Simple", y, side, f, -0.6, -3.95)
                if ss:
                    ss.position.y += 0.8
                _shop_frame["apo_shelf"] = ss
                var t2 := _yard("Table_Large", y, side, f, -1.4, 0.9)
                _on_top("Potion_1", t2, -0.6, 0.0)
                _on_top("Potion_2", t2, -0.15, 0.1)
                _on_top("Potion_4", t2, 0.3, -0.05)
                _on_top("SmallBottles_1", t2, 0.7, 0.05)
                _yard("Vase_2", y, side, f, 2.8, 1.8)
                _yard("Pot_1", y, side, f, 3.0, -2.8)
            "store":
                _yard("Stall_Cart_Empty", y, side, f, 0.0, 0.6)
                _yard("Barrel_Apples", y, side, f, -2.6, -2.4)
                _yard("FarmCrate_Apple", y, side, f, -1.0, -3.0)
                _yard("FarmCrate_Carrot", y, side, f, 0.6, -3.1, 0.2)
                _yard("Bag", y, side, f, 2.4, -2.6)
                _yard("Bag", y, side, f, 3.0, -1.6, 1.1)
                _yard("Crate_Wooden", y, side, f, 2.8, 1.4, 0.4)
                _yard("Barrel", y, side, f, -2.8, 1.2)
            "tavern":
                for tz in [-1.6, 1.4]:
                    var tt := _yard("Table_Large", y, side, f, -0.6, float(tz))
                    _on_top("Mug", tt, -0.4, 0.0)
                    _on_top("Mug", tt, 0.4, 0.1, 1.0)
                    _yard("Stool", y, side, f, -2.2, float(tz))
                    _yard("Stool", y, side, f, 1.0, float(tz))
                # two chairs drawn up at the table ends (Fantasy Props MegaKit)
                _yard("Chair_1", y, side, f, -0.6, 2.9, PI)
                _yard("Chair_1", y, side, f, -0.6, -3.1)
                _yard("Barrel_Holder", y, side, f, 2.9, -2.6)
                _yard("Barrel", y, side, f, 3.0, 0.4)
                _yard("Barrel", y, side, f, 3.0, 1.6, 0.6)
        # the sign: a post at the street edge of the yard, board facing the road
        _signpost(y + f * 3.6 - side * 3.4, f, String(plot["sign"]), wood,
                  SHOP_TINT.get(kind, Color(1, 1, 1)))
        # a lantern on the post so the trade is lit at night
        _glow(y + f * 3.6 - side * 3.4 + Vector3(0, g + 3.0, 0), Color(1.0, 0.75, 0.45), 0.6, 6.0)

## The goods on show, tier by tier (Gear.WEAPONS): plain steel, fine steel,
## runed (smoulders), dragontooth (burns). Each on its own peg with its price,
## so a viewer can SEE what the next tier buys.
var _rack_items: Array = []
var _cloth: StandardMaterial3D

## Tiers the town cannot make yet (Roster.town_tier, old sync_unlocks) hang on
## the rack under a dark cloth, unlit, marked "not yet made in Bellmire";
## when the town grows the cloth comes off.
func show_tiers(tier: int) -> void:
    if _cloth == null:
        _cloth = StandardMaterial3D.new()
        _cloth.albedo_color = Color(0.14, 0.12, 0.11)
        _cloth.roughness = 1.0
    for it in _rack_items:
        var locked := int(it["t"]) > tier
        var n: Node3D = it["node"]
        if not is_instance_valid(n):
            continue
        for m in n.find_children("*", "MeshInstance3D", true, false):
            (m as MeshInstance3D).material_override = _cloth if locked else null
        if it["light"] != null and is_instance_valid(it["light"]):
            (it["light"] as OmniLight3D).visible = not locked
        if it["label"] != null and is_instance_valid(it["label"]):
            var lb: Label3D = it["label"]
            lb.text = (String(it["text"]).split("\n")[0] + "\nnot yet made in Bellmire") if locked else String(it["text"])
            lb.modulate = Color(0.55, 0.52, 0.5) if locked else (it["col"] as Color)

func _tier_rack(p: Vector3, f: Vector3, side: Vector3, family: String) -> void:
    var g := height_at(p.x, p.z)
    var yaw := atan2(f.x, f.z)
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    wood.albedo_color = Color(0.48, 0.36, 0.26)
    # a low board on two posts
    for sgn in [-1.0, 1.0]:
        var pp := p + side * (1.9 * float(sgn))
        _box(Vector3(0.14, 1.9, 0.14), Vector3(pp.x, g + 0.95, pp.z), wood, yaw)
    _box(Vector3(4.0, 0.12, 0.3), Vector3(p.x, g + 1.85, p.z), wood, yaw)
    _box(Vector3(4.0, 0.10, 0.24), Vector3(p.x, g + 0.35, p.z), wood, yaw)
    for t in range(1, 5):
        var path := Gear.weapon_path(family, t)
        if path == "" or not ResourceLoader.exists(path):
            continue
        var w: Dictionary = Gear.WEAPONS[t]
        var wp := p + side * (-1.5 + float(t - 1) * 1.0) + f * 0.12
        var n: Node3D = (load(path) as PackedScene).instantiate()
        n.scale = Vector3.ONE * float(w["scale"]) * 1.15
        n.position = Vector3(wp.x, g + 0.45, wp.z)
        n.rotation.y = yaw
        add_child(n)
        var item := {"t": t, "node": n, "light": null, "label": null, "text": "", "col": Color.WHITE}
        _rack_items.append(item)
        if float(w["glow"]) > 0.0:
            Gear.ignite(n, float(w["glow"]))
            var l := OmniLight3D.new()
            l.light_color = Color(1.0, 0.62, 0.22).lerp(Color(0.65, 0.85, 1.0), clampf(float(w["glow"]) - 0.5, 0.0, 1.0) * 0.7)
            l.light_energy = 0.6 * float(w["glow"])
            l.omni_range = 2.5
            l.position = Vector3(wp.x, g + 1.2, wp.z) + f * 0.4
            add_child(l)
            item["light"] = l
        var lb := Label3D.new()
        lb.text = "%s\n%dg" % [String(w["name"]), int(w["cost"])]
        lb.font_size = 34
        lb.pixel_size = 0.0045
        lb.outline_size = 10
        lb.modulate = [Color(0.9, 0.9, 0.88), Color(0.45, 0.95, 0.45), Color(0.4, 0.65, 1.0), Color(1.0, 0.66, 0.2)][t - 1]
        var lp := wp + f * 0.2
        lb.position = Vector3(lp.x, g + 2.15, lp.z)
        lb.rotation.y = yaw
        add_child(lb)
        item["label"] = lb
        item["text"] = lb.text
        item["col"] = lb.modulate
    _objs.append([p, 2.2])

func _signpost(p: Vector3, f: Vector3, text: String, wood: Material, col: Color) -> void:
    var g := height_at(p.x, p.z)
    var yaw := atan2(f.x, f.z)
    var side := Vector3(-f.z, 0.0, f.x)
    _box(Vector3(0.2, 3.4, 0.2), Vector3(p.x, g + 1.7, p.z), wood, yaw)
    var arm := p + side * 1.0
    _box(Vector3(2.2, 0.14, 0.14), Vector3(arm.x, g + 3.25, arm.z), wood, yaw)
    var bp := p + side * 1.15
    _box(Vector3(2.1, 0.8, 0.08), Vector3(bp.x, g + 2.65, bp.z), wood, yaw)
    for sgn in [1.0, -1.0]:
        var lb := Label3D.new()
        lb.text = text
        lb.font_size = 40
        lb.pixel_size = 0.0055
        lb.width = 360.0
        lb.autowrap_mode = TextServer.AUTOWRAP_WORD
        lb.modulate = col
        lb.outline_size = 10
        lb.outline_modulate = Color(0.08, 0.05, 0.02)
        lb.double_sided = false
        var lp := bp + f * (0.05 * float(sgn))
        lb.position = Vector3(lp.x, g + 2.65, lp.z)
        lb.rotation.y = yaw + (0.0 if sgn > 0.0 else PI)
        add_child(lb)

## ---------------------------------------------------------------- towers
## Watchtowers: two in the garrison, one on the near bank guarding the bridge.
## Each has a guard on top (see _spawn_people).
func _pick_towers() -> void:
    var gar: Array = []
    for plot in plots:
        if String(plot["district"]) == "garrison" and not plot.has("shop") and not plot.has("landmark"):
            gar.append(plot)
    gar.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return (a["pos"] as Vector3).length() > (b["pos"] as Vector3).length())
    var chosen: Array = []
    for plot in gar:
        if chosen.size() >= 2:
            break
        var ok := true
        for c in chosen:
            if (c as Vector3).distance_to(plot["pos"]) < 40.0:
                ok = false
        if ok:
            chosen.append(plot["pos"])
    for c in chosen:
        var cv: Vector3 = c
        var kept := []
        for plot in plots:
            if (plot["pos"] as Vector3).distance_to(cv) > 6.5:
                kept.append(plot)
        plots = kept
        towers.append(cv)
        _objs.append([cv, 4.0])

func _build_towers() -> void:
    # the bridge tower: town side of the river, beside the road
    for bx in [10.0, -10.0, 16.0, -16.0]:
        var bt := Vector3(float(bx), 0.0, _bridge_z - (RIVER_W + RIVER_BANK + 6.0))
        if is_clear(bt, 3.2):
            towers.append(bt)
            _objs.append([bt, 4.0])
            break
    for t in towers:
        _guard_tower(t)

const TOWER_H := 11.0
func _guard_tower(p: Vector3) -> void:
    var g := height_at(p.x, p.z)
    var st := _stone()
    _box(Vector3(4.6, TOWER_H + 1.0, 4.6), Vector3(p.x, g - 1.0 + (TOWER_H + 1.0) * 0.5, p.z), st)
    # corbelled top, wider than the shaft
    _box(Vector3(5.8, 0.7, 5.8), Vector3(p.x, g + TOWER_H + 0.35, p.z), st)
    for i in range(4):
        for k in range(3):
            var a := float(i) * PI * 0.5
            var dir := Vector3(cos(a), 0.0, sin(a))
            var sd := Vector3(-dir.z, 0.0, dir.x)
            var mp := p + dir * 2.6 + sd * (float(k) - 1.0) * 1.9
            _box(Vector3(0.9, 1.0, 0.9), Vector3(mp.x, g + TOWER_H + 1.2, mp.z), st)
    # door, arrow slits
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.08, 0.06, 0.05)
    _box(Vector3(1.4, 2.4, 0.1), Vector3(p.x, g + 1.2, p.z + 2.32), dark)
    for hy in [4.5, 8.0]:
        for i in range(4):
            var a := float(i) * PI * 0.5
            var o := Vector3(cos(a), 0.0, sin(a)) * 2.32
            _box(Vector3(0.25 if absf(o.x) < 0.1 else 0.1, 1.1, 0.25 if absf(o.z) < 0.1 else 0.1),
                 Vector3(p.x + o.x, g + float(hy), p.z + o.z), dark)
    # pennant
    var pole := p + Vector3(1.8, 0, -1.8)
    var wood: StandardMaterial3D = (_mat.get("MI_WoodTrim") as StandardMaterial3D).duplicate()
    wood.uv1_triplanar = true
    _box(Vector3(0.14, 4.0, 0.14), Vector3(pole.x, g + TOWER_H + 2.7, pole.z), wood)
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = Color(0.55, 0.12, 0.10)
    cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
    _box(Vector3(1.4, 0.8, 0.04), Vector3(pole.x + 0.75, g + TOWER_H + 4.2, pole.z), cloth)
    _glow(Vector3(p.x, g + TOWER_H + 2.0, p.z), Color(1.0, 0.7, 0.4), 0.8, 9.0)

## ---------------------------------------------------------------- people
## The old game's roster, unchanged: role, workplace, body, tint, headcount.
## Workplaces now map to Bellmire's districts instead of old building names.
const FIRST := ["Bran", "Edda", "Rolf", "Mira", "Talen", "Osric", "Hilda", "Cort",
    "Ysolde", "Garm", "Petra", "Aldric", "Nessa", "Dunn", "Wren", "Harl",
    "Sable", "Tove", "Rask", "Ingrid", "Corvin", "Maela"]
const LAST := ["of the Ford", "Stonehand", "Ashwood", "the Younger", "Quarryman",
    "Fenwick", "Thatcher", "Bramble", "Coalfoot", "Rivers", "Hollow"]
const ROSTER := [
    ["chief", "keep", "Mage.glb", 0.86, 0.74, 1.00, 1],
    ["guard", "garrison", "Knight.glb", 0.74, 0.82, 1.00, 5],
    ["farmer", "mill", "Rogue.glb", 0.93, 0.87, 0.52, 3],
    ["farmer", "homes_s", "Rogue.glb", 0.90, 0.92, 0.58, 2],
    ["lumberjack", "homes_w", "Barbarian.glb", 0.78, 0.60, 0.40, 3],
    ["miner", "craft", "Barbarian.glb", 0.66, 0.70, 0.76, 3],
    ["smith", "craft", "Barbarian.glb", 0.96, 0.60, 0.38, 2],
    ["healer", "temple", "Mage.glb", 0.68, 0.95, 0.84, 2],
    ["merchant", "market", "Rogue_Hooded.glb", 0.96, 0.80, 0.44, 3],
    ["trader", "market", "Rogue_Hooded.glb", 0.86, 0.72, 0.95, 2],
    ["miller", "mill", "Rogue.glb", 0.85, 0.90, 0.95, 1],
    ["fletcher", "garrison", "Rogue.glb", 0.72, 0.88, 0.62, 2],
    ["innkeeper", "market", "Barbarian.glb", 0.92, 0.78, 0.58, 1],
]

func _door_in(plot: Dictionary) -> Vector3:
    return plot.get("door_in", Vector3.ZERO)

func _door(plot: Dictionary) -> Vector3:
    if plot.has("door"):
        return plot["door"]
    var yaw: float = float(plot["yaw"])
    var pp: Vector3 = plot["pos"]
    return pp + Vector3(sin(yaw), 0.0, cos(yaw)) * 5.0

## who works inside which landmark
const ROLE_LANDMARK := {"chief": "lm_hall", "healer": "lm_chapel", "fletcher": "range",
    "farmer": "farm", "miller": "lm_windmill", "lumberjack": "lm_sawmill", "miner": "mine",
    "smith": "lm_workshop"}

## a street-facing house (back-rank doors open onto the block's interior)
func _home_for(rng: RandomNumberGenerator) -> Dictionary:
    for i in range(40):
        var pl: Dictionary = plots[rng.randi() % plots.size()]
        # D3: nobody is housed on a staked lot or in a hall the town has raised
        if not pl.has("back") and not pl.has("shop") and not pl.has("landmark") and pl.has("door") \
                and not pl.get("unbuilt", false) and not pl.has("special"):
            return pl
    return plots[rng.randi() % plots.size()]

func _spawn_people() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1997
    var by_district := {}
    for plot in plots:
        var d: String = plot["district"]
        if not by_district.has(d):
            by_district[d] = []
        (by_district[d] as Array).append(plot)
    var gates: Array = _wall_info.get("gates", [])
    var guard_posts: Array = []
    for g in gates:
        var gv: Vector3 = g
        var out := Vector3(gv.x, 0.0, gv.z).normalized()
        var side := Vector3(-out.z, 0.0, out.x)
        for sgn in [-1.0, 1.0]:
            guard_posts.append([gv + out * 4.0 + side * (4.2 * float(sgn)), atan2(out.x, out.z)])
    if _scar_info.has("post"):
        var sp: Vector3 = _scar_info["post"]
        var sf: Vector3 = _scar_info["fwd"]
        var ss := Vector3(-sf.z, 0, sf.x)
        for sgn in [-1.0, 1.0]:
            guard_posts.append([sp + ss * (3.6 * float(sgn)) - sf * 1.0, atan2(sf.x, sf.z)])
    var stall_i := 0
    var post_i := 0
    for row in ROSTER:
        var role: String = row[0]
        var dist: String = row[1]
        for k in range(int(row[6])):
            var v := Townsfolk.new()
            v.role = role
            v.model = row[2]
            v.tint = Color(float(row[3]), float(row[4]), float(row[5]))
            v.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
            v.town = self
            var pool: Array = by_district.get(dist, plots)
            if pool.is_empty():
                pool = plots
            var home_plot: Dictionary = _home_for(rng)
            var work_plot: Dictionary = pool[rng.randi() % pool.size()]
            var lmk: String = String(ROLE_LANDMARK.get(role, ""))
            for pl in plots:
                if lmk != "" and String(pl.get("landmark", "")) == lmk:
                    work_plot = pl
            for site in _sites:
                if lmk != "" and String(site["landmark"]) == lmk:
                    work_plot = site
            v.home = _door(home_plot)
            v.home_in = _door_in(home_plot)
            v.livery = LIVERY_BANNER.get(livery_of.get(String(work_plot.get("district", home_plot.get("district", ""))), "red"), Color(0.6, 0.15, 0.12))
            v.work = _door(work_plot)
            v.work_in = _door_in(work_plot)
            var start: Vector3 = v.home if rng.randf() < 0.5 else v.work
            if role == "merchant" and stall_i < _stalls.size():
                var st: Array = _stalls[stall_i]
                stall_i += 1
                var sp: Vector3 = st[0]
                var face: float = float(st[1])
                v.stay = true
                v.face_yaw = face
                start = sp - Vector3(sin(face), 0.0, cos(face)) * 1.3
            elif role == "guard" and post_i < guard_posts.size():
                var gp: Array = guard_posts[post_i]
                post_i += 1
                v.stay = true
                v.face_yaw = float(gp[1])
                v.gear_role = "gateguard"
                start = gp[0]
            elif role == "trader" or role == "innkeeper":
                # D4: on open ground - a spot inside a stall left them pressing into it
                v.work = _snap(_market_pos + Vector3(rng.randf_range(-7.0, 7.0), 0.0, rng.randf_range(-7.0, 7.0)))
                # D6b: an open-air spot has no door - the plot's inside point stayed
                # behind and the "door leg" ran 30-47 m through the houses to it
                v.work_in = Vector3.ZERO
            start.y = height_at(start.x, start.z)
            v.position = start
            add_child(v)
            people.append(v)
    # a lookout on every watchtower
    for t in towers:
        var tv: Vector3 = t
        var lk := Townsfolk.new()
        lk.role = "guard"
        lk.model = "Knight.glb"
        lk.tint = Color(0.74, 0.82, 1.00)
        lk.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
        lk.town = self
        lk.stay = true
        lk.gear_role = "lookout"
        lk.face_yaw = atan2(tv.x, tv.z)
        lk.position = Vector3(tv.x, height_at(tv.x, tv.z) + TOWER_H + 0.7, tv.z)
        add_child(lk)
        people.append(lk)
    # a keeper in every shop yard
    var keeper := {"blacksmith": ["Barbarian.glb", Color(0.96, 0.60, 0.38)],
                   "armorer": ["Knight.glb", Color(0.80, 0.80, 0.85)],
                   "apothecary": ["Mage.glb", Color(0.68, 0.95, 0.84)],
                   "store": ["Rogue_Hooded.glb", Color(0.96, 0.80, 0.44)],
                   "tavern": ["Barbarian.glb", Color(0.92, 0.78, 0.58)]}
    for sh in shops:
        var kp: Array = keeper.get(sh[0], ["Rogue.glb", Color(1, 1, 1)])
        var v2 := Townsfolk.new()
        v2.role = String(sh[0])
        v2.model = kp[0]
        v2.tint = kp[1]
        v2.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
        v2.town = self
        v2.stay = true
        var sf: Vector3 = sh[2]
        v2.face_yaw = atan2(sf.x, sf.z)
        var yp: Vector3 = sh[1]
        yp += sf * 2.2
        v2.position = Vector3(yp.x, height_at(yp.x, yp.z), yp.z)
        add_child(v2)
        people.append(v2)
    # a fisher at the end of every dock
    for di in range(docks.size()):
        var dk: Array = docks[di]
        var dend: Vector3 = dk[0]
        var dfw: Vector3 = dk[1]
        var fsh := Townsfolk.new()
        fsh.role = "fisher"
        fsh.model = "Rogue.glb" if di % 2 == 0 else "Rogue_Hooded.glb"
        fsh.tint = Color(0.70, 0.84, 0.92)
        fsh.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
        fsh.town = self
        fsh.stay = true
        fsh.face_yaw = atan2(dfw.x, dfw.z)
        fsh.position = dend - dfw * 0.9 + Vector3(0, DOCK_Y + 0.12, 0)
        add_child(fsh)
        people.append(fsh)
        var ang := Angler.new()
        ang.who = fsh.person_name
        ang.water_y = WATER_Y
        ang.demo = di == 0
        ang.target = dend + dfw * 7.5
        ang.target.y = WATER_Y
        ang.caught.connect(_on_caught)
        fsh.add_child(ang)
        anglers.append(ang)
    _more_folk(rng)
    notables = Notables.new()
    notables.name = "Notables"
    add_child(notables)
    notables.setup(self)
    # plain townsfolk: home -> market and back, so the streets are never empty
    for k in range(14):
        var v := Townsfolk.new()
        v.role = "peasant"
        v.model = "Rogue.glb" if k % 2 == 0 else "Rogue_Hooded.glb"
        v.tint = Color(rng.randf_range(0.7, 0.95), rng.randf_range(0.7, 0.92), rng.randf_range(0.6, 0.9))
        v.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
        v.town = self
        v.gear_seed = k
        var hp: Dictionary = _home_for(rng)
        v.home = _door(hp)
        v.home_in = _door_in(hp)
        v.livery = LIVERY_BANNER.get(livery_of.get(String(hp.get("district", "")), "red"), Color(0.6, 0.15, 0.12))
        v.work = _market_pos + Vector3(rng.randf_range(-9.0, 9.0), 0.0, rng.randf_range(-9.0, 9.0))
        var st2: Vector3 = v.home if k % 3 else v.work
        st2.y = height_at(st2.x, st2.z)
        v.position = st2
        add_child(v)
        people.append(v)

## ---------------------------------------------------------------- more folk
## Mr. E: "add more of them". Bellmire has 120-odd houses; this brings the
## street population to ~120 with trades the town visibly needs, and gives
## everyday folk a DAY (home -> work -> market -> tavern -> home) instead of a
## two-point shuttle. Bodies stay KayKit and unchanged.
const CRIER_LINES := ["MEASURE THE GRAIN. COUNT THE FLASKS. KEEP THE DOOR.",
    "The Guild is hiring! Delvers wanted at the north gate!",
    "Fresh bread at the market - two coppers the loaf!",
    "By order of the Chief: no fishing off the bridge!",
    "Heroes - mind the scar. Magic goes wrong down there.",
    "Market day! Market day! Trout, apples and good steel!"]

func _folk(role: String, model: String, tint: Color, rng: RandomNumberGenerator) -> Townsfolk:
    var v := Townsfolk.new()
    v.role = role
    v.model = model
    v.tint = tint
    v.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
    v.town = self
    v.gear_seed = rng.randi() % 5
    return v

func _put_folk(v: Townsfolk, at: Vector3) -> void:
    at.y = height_at(at.x, at.z)
    v.position = at
    add_child(v)
    people.append(v)

func _shop_door(kind: String) -> Array:
    for pl in plots:
        if String(pl.get("shop", "")) == kind and pl.has("door"):
            return [pl["door"], pl.get("door_in", Vector3.ZERO)]
    return [_market_pos, Vector3.ZERO]

func _lm_door(key: String) -> Array:
    for pl in plots:
        if String(pl.get("landmark", "")) == key and pl.has("door"):
            return [pl["door"], pl.get("door_in", Vector3.ZERO)]
    return [_market_pos, Vector3.ZERO]

func _near_market(rng: RandomNumberGenerator, r := 9.0) -> Vector3:
    var a := rng.randf() * TAU
    var q := _market_pos + Vector3(cos(a), 0, sin(a)) * rng.randf_range(4.0, r + 6.0)
    # stand in the open, not inside a stall or the well
    for i in range(8):
        if is_clear(q, 0.6, true) or q.distance_to(_market_pos) < 19.0 and road_dist(q) > -50.0 and not _in_house(q, 0.6):
            break
        a = rng.randf() * TAU
        q = _market_pos + Vector3(cos(a), 0, sin(a)) * rng.randf_range(4.0, r + 6.0)
    return q

func _more_folk(rng: RandomNumberGenerator) -> void:
    var tavern := _shop_door("tavern")
    var store := _shop_door("store")
    var chapel := _lm_door("lm_chapel")
    # 1. everyday folk with a full day - the bulk of the crowd
    var bodies := ["Rogue.glb", "Rogue_Hooded.glb", "Barbarian.glb", "Mage.glb", "Knight.glb"]
    for k in range(46):
        var v := _folk("peasant", bodies[k % 5] if k % 5 != 4 else "Rogue.glb",
                       Color(rng.randf_range(0.65, 0.98), rng.randf_range(0.62, 0.95), rng.randf_range(0.55, 0.9)), rng)
        var hp: Dictionary = _home_for(rng)
        var wp: Dictionary = plots[rng.randi() % plots.size()]
        v.livery = LIVERY_BANNER.get(livery_of.get(String(hp.get("district", "")), "red"), Color(0.6, 0.15, 0.12))
        v.stops = [[_door(hp), _door_in(hp), rng.randf_range(15.0, 35.0)],
                   [_door(wp), _door_in(wp), rng.randf_range(20.0, 40.0)],
                   [_near_market(rng), Vector3.ZERO, rng.randf_range(6.0, 14.0)]]
        if rng.randf() < 0.5:
            v.stops.append([tavern[0], tavern[1], rng.randf_range(15.0, 30.0)])
        if rng.randf() < 0.3:
            v.stops.append([chapel[0], chapel[1], rng.randf_range(10.0, 20.0)])
        v._stop_i = rng.randi() % v.stops.size()
        _put_folk(v, (v.stops[v._stop_i] as Array)[0])
    # 2. bakers: oven (the general store's back room) -> market with bread -> home
    for k in range(3):
        var v := _folk("baker", "Barbarian.glb", Color(0.98, 0.92, 0.82), rng)
        var hp: Dictionary = _home_for(rng)
        v.stops = [[store[0], store[1], 30.0], [_near_market(rng, 7.0), Vector3.ZERO, 20.0], [_door(hp), _door_in(hp), 25.0]]
        _put_folk(v, store[0])
    # 3. washerwomen at the river bank by the docks, home between loads
    for k in range(4):
        var v := _folk("washer", "Rogue_Hooded.glb", Color(0.82, 0.86, 0.92), rng)
        var hp: Dictionary = _home_for(rng)
        var bx := -30.0 + 64.0 * float(k % 2) + rng.randf_range(-6.0, 6.0)
        var bank := Vector3(bx, 0, river_z(bx) - RIVER_W - RIVER_BANK * 0.6)
        v.stops = [[bank, Vector3.ZERO, 35.0], [_door(hp), _door_in(hp), 20.0]]
        _put_folk(v, bank)
    # 4. children: run about the square and the streets near it, never indoors long
    for k in range(10):
        var v := _folk("child", ["Rogue.glb", "Rogue_Hooded.glb", "Mage.glb"][k % 3],
                       Color(rng.randf_range(0.75, 1.0), rng.randf_range(0.7, 1.0), rng.randf_range(0.6, 1.0)), rng)
        v.size_k = 0.68
        v.speed = 6.2
        for i in range(4):
            v.stops.append([_near_market(rng, 16.0), Vector3.ZERO, rng.randf_range(1.5, 5.0)])
        var hp: Dictionary = _home_for(rng)
        v.stops.append([_door(hp), _door_in(hp), 12.0])
        _put_folk(v, (v.stops[0] as Array)[0])
    # 5. the town crier on the square, calling the news
    var crier := _folk("crier", "Knight.glb", Color(0.95, 0.85, 0.6), rng)
    crier.stay = true
    crier.shout_lines = CRIER_LINES
    crier.face_yaw = 0.0
    _put_folk(crier, _market_pos + Vector3(0, 0, 4.2))
    # 6. a priest on the chapel steps
    var priest := _folk("priest", "Mage.glb", Color(0.95, 0.92, 0.82), rng)
    priest.stay = true
    for pl in plots:
        if String(pl.get("landmark", "")) == "lm_chapel":
            priest.face_yaw = float(pl["yaw"])
    _put_folk(priest, chapel[0])
    # 7. the WATCH: pairs walking a beat round the ring road and out to the gates
    var beat: Array = []
    if _wall_info.has("gates"):
        for g in _wall_info["gates"]:
            var gv: Vector3 = g
            beat.append([gv - Vector3(gv.x, 0, gv.z).normalized() * 8.0, Vector3.ZERO, 6.0])
    beat.append([_market_pos + Vector3(10, 0, 0), Vector3.ZERO, 4.0])
    for k in range(4):
        var a := _folk("watch", "Knight.glb", Color(0.74, 0.82, 1.0), rng)
        a.gear_role = "watch"
        a.stops = beat.duplicate()
        a._stop_i = k % maxi(beat.size(), 1)
        a.livery = LIVERY_BANNER.get(livery_of.get("garrison", "blue"), Color(0.16, 0.26, 0.62))
        _put_folk(a, (beat[a._stop_i] as Array)[0])
        var b := _folk("watch", "Knight.glb", Color(0.74, 0.82, 1.0), rng)
        b.gear_role = "watch"
        b.leader = a
        b.livery = a.livery
        _put_folk(b, (beat[a._stop_i] as Array)[0] + Vector3(1.3, 0, 0))
    # 8. carters hauling a wagon between the gates, the market and the mill
    var haul: Array = [[_market_pos + Vector3(-11, 0, 3), Vector3.ZERO, 12.0]]
    if landmarks.has("lm_granary"):
        haul.append([(landmarks["lm_granary"][0] as Vector3) + (landmarks["lm_granary"][1] as Vector3) * 9.0, Vector3.ZERO, 12.0])
    if _wall_info.has("gates"):
        for g in _wall_info["gates"]:
            haul.append([(g as Vector3) - Vector3((g as Vector3).x, 0, (g as Vector3).z).normalized() * 10.0, Vector3.ZERO, 8.0])
    for k in range(3):
        var v := _folk("carter", "Barbarian.glb", Color(0.85, 0.75, 0.6), rng)
        v.stops = haul.duplicate()
        v._stop_i = k % haul.size()
        v.speed = 3.4
        var at: Vector3 = (haul[v._stop_i] as Array)[0]
        _put_folk(v, at)
        var w := _spawn_raw(MKPROPS, "Prop_Wagon", Vector3(at.x, height_at(at.x, at.z), at.z - 2.6), PI * 0.5, 0.8)
        v.cart = w

## D6: a pedlar's cart (the carters' wagon), standing on the ground at `at`
func spawn_wagon(at: Vector3) -> Node3D:
    return _spawn_raw(MKPROPS, "Prop_Wagon", Vector3(at.x, height_at(at.x, at.z), at.z - 2.6), PI * 0.5, 0.8)

## ---------------------------------------------------------------- D4 the garrison
## Lore (the original town.gd _chief_spends): "standing garrison scales with how
## dangerous the valley has become" and each new man "is sworn into the watch."
## Bellmire HD grows its garrison with the town: every gate post is manned from
## the founding, each watchtower carries two crossbowmen (raids.gd: they shoot),
## more watch pairs walk more beats as the town rises, and once the Town Stables
## stand (level 4, D3) the MOUNTED WATCH rides the roads from them (Cavalry).
## Riders are town guards only - nobody else in Bellmire goes horsed.
const WATCH_BEATS_FROM := {"wall": 1, "market": 1, "bridge": 3, "wall_back": 5}
const RIDERS_FROM := [4, 4, 5, 6]
var garrison: Array = []       # [Townsfolk, level it appears at]
var cavalry: Array = []

func _guard_posts() -> Array:
    var posts: Array = []
    for g in _wall_info.get("gates", []):
        var gv: Vector3 = g
        var out := Vector3(gv.x, 0.0, gv.z).normalized()
        var side := Vector3(-out.z, 0.0, out.x)
        for sgn in [-1.0, 1.0]:
            posts.append([gv + out * 4.0 + side * (4.2 * float(sgn)), atan2(out.x, out.z)])
    if _scar_info.has("post"):
        var sp: Vector3 = _scar_info["post"]
        var sf: Vector3 = _scar_info["fwd"]
        var ss := Vector3(-sf.z, 0, sf.x)
        for sgn in [-1.0, 1.0]:
            posts.append([sp + ss * (3.6 * float(sgn)) - sf * 1.0, atan2(sf.x, sf.z)])
    return posts

## the nearest point a foot (or a hoof) may stand on
## (D6b: only once the navmesh is in the server's map - before that the town's own
## push-out of solids, never the origin)
func _snap(p: Vector3) -> Vector3:
    if nav != null and nav.synced():
        var q: Vector3 = nav.closest(Vector3(p.x, 0.0, p.z))
        return Vector3(q.x, 0.0, q.z)
    return keep_walkable(p)

func _beat(kind: String) -> Array:
    var beat: Array = []
    var ax := float(_wall_info.get("ax", 0.0))
    var az := float(_wall_info.get("az", 0.0))
    match kind:
        "wall", "wall_back":
            # inside the curtain wall, all the way round
            if ax > 30.0 and az > 30.0:
                for i in range(10):
                    var a := TAU * float(i) / 10.0
                    beat.append([_snap(Vector3(cos(a) * (ax - 15.0), 0.0, sin(a) * (az - 15.0))), Vector3.ZERO, 2.5])
            if kind == "wall_back":
                beat.reverse()
        "market":
            for i in range(6):
                var a := TAU * float(i) / 6.0 + 0.3
                beat.append([_snap(_market_pos + Vector3(cos(a), 0.0, sin(a)) * 17.0), Vector3.ZERO, 3.0])
            beat.insert(3, [_snap((_shop_door("tavern")[0] as Vector3)), Vector3.ZERO, 5.0])
        "bridge":
            beat.append([_snap(_market_pos + Vector3(0, 0, 14.0)), Vector3.ZERO, 3.0])
            beat.append([_snap(Vector3(0.0, 0.0, _bridge_z - (RIVER_W + RIVER_BANK + 5.0))), Vector3.ZERO, 6.0])
            beat.append([_snap(Vector3(0.0, 0.0, _bridge_z + RIVER_W + RIVER_BANK + 5.0)), Vector3.ZERO, 4.0])
            beat.append([_snap(Vector3(0.0, 0.0, _bridge_z - (RIVER_W + RIVER_BANK + 5.0))), Vector3.ZERO, 2.0])
    if beat.is_empty():
        beat.append([_snap(_market_pos + Vector3(10, 0, 0)), Vector3.ZERO, 4.0])
    return beat

func _spawn_garrison() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4404
    var blue: Color = LIVERY_BANNER.get(livery_of.get("garrison", "blue"), Color(0.16, 0.26, 0.62))
    # 1. every gate post manned (the old roster's five guards fill the first five)
    var posts := _guard_posts()
    var manned := 0
    for p in people:
        if is_instance_valid(p) and String((p as Townsfolk).gear_role) == "gateguard":
            manned += 1
    for i in range(manned, posts.size()):
        var gp: Array = posts[i]
        var g := _folk("guard", "Knight.glb", Color(0.74, 0.82, 1.00), rng)
        g.stay = true
        g.face_yaw = float(gp[1])
        g.gear_role = "gateguard"
        g.livery = blue
        _put_folk(g, gp[0])
        garrison.append([g, 1])
    # 2. a second crossbowman on every watchtower, at the parapet's far corner
    for t in towers:
        var tv: Vector3 = t
        var lk := _folk("guard", "Knight.glb", Color(0.74, 0.82, 1.00), rng)
        lk.stay = true
        lk.gear_role = "lookout"
        lk.livery = blue
        var at := tv + Vector3(-1.7, 0.0, 1.7)
        lk.face_yaw = atan2(at.x, at.z)
        lk.position = Vector3(at.x, height_at(tv.x, tv.z) + TOWER_H + 0.7, at.z)
        add_child(lk)
        people.append(lk)
        garrison.append([lk, 1])
    # 3. more watch pairs, more beats, as the town rises
    for kind in WATCH_BEATS_FROM:
        var beat := _beat(kind)
        var a := _folk("watch", "Knight.glb", Color(0.74, 0.82, 1.0), rng)
        a.gear_role = "watch"
        a.stops = beat
        a._stop_i = rng.randi() % beat.size()
        a.livery = blue
        _put_folk(a, (beat[a._stop_i] as Array)[0])
        var b := _folk("watch", "Knight.glb", Color(0.74, 0.82, 1.0), rng)
        b.gear_role = "watch"
        b.leader = a
        b.livery = blue
        _put_folk(b, (beat[a._stop_i] as Array)[0] + Vector3(1.3, 0, 0))
        garrison.append([a, int(WATCH_BEATS_FROM[kind])])
        garrison.append([b, int(WATCH_BEATS_FROM[kind])])
    # 4. the mounted watch: out of the Town Stables, round every gate and back
    var stable := _lm_door("lm_barracks")[0] as Vector3
    if growth != null and growth.specials.has("stables"):
        var sp: Dictionary = growth.specials["stables"]["plot"]
        # the yard in front of the open stalls, clear of the barn's footprint
        stable = _door(sp) + _fwd(sp) * 3.0
    stable = _snap(stable)
    var gates: Array = (_wall_info.get("gates", []) as Array).duplicate()
    gates.sort_custom(func(p: Vector3, q: Vector3) -> bool: return atan2(p.z, p.x) < atan2(q.z, q.x))
    var ride: Array = [[stable, Vector3.ZERO, 8.0]]
    for g in gates:
        var gv: Vector3 = g
        var out := Vector3(gv.x, 0.0, gv.z).normalized()
        ride.append([_snap(gv - out * 10.0), Vector3.ZERO, 0.5])
        ride.append([_snap(gv + out * 18.0), Vector3.ZERO, 3.0])
        ride.append([_snap(gv - out * 10.0), Vector3.ZERO, 0.5])
    ride.append([_snap(_market_pos + Vector3(0, 0, 15.0)), Vector3.ZERO, 2.0])
    ride.append([_snap(Vector3(0.0, 0.0, _bridge_z - (RIVER_W + RIVER_BANK + 5.0))), Vector3.ZERO, 3.0])
    for k in range(RIDERS_FROM.size()):
        var c := Cavalry.new()
        c.role = "guard"
        c.model = "Knight.glb"
        c.tint = Color(0.74, 0.82, 1.00)
        c.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
        c.town = self
        c.gear_role = "guard"
        c.gear_seed = rng.randi() % 5
        c.livery = blue
        c.speed = 7.5
        var loop: Array = ride.duplicate()
        if k % 2 == 1:
            loop.reverse()
        c.stops = loop
        c._stop_i = (k * 3) % loop.size()
        c.name = "Rider%d" % k
        _put_folk(c, stable + Vector3(float(k) * 1.8 - 2.7, 0.0, 0.0))
        cavalry.append(c)
        garrison.append([c, int(RIDERS_FROM[k])])
    _show_garrison(int(growth.level) if growth != null and int(growth.level) > 0 else 1, true)

## who of the garrison stands in Bellmire at this level; the rest wait unseen
func _show_garrison(lv: int, quiet := false) -> void:
    var sworn: Array = []
    var riders := 0
    for e in garrison:
        # D7: a guard who fell in a raid is freed - test before typing it
        if not is_instance_valid(e[0]):
            continue
        var v: Townsfolk = e[0]
        var on: bool = lv >= int(e[1])
        var was: bool = bool(v.get_meta("on_duty", true))
        v.set_meta("on_duty", on)
        if on == was and v.has_meta("placed"):
            continue
        v.set_meta("placed", true)
        v.visible = on
        v.inside = false
        v.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
        if not on:
            v._route = []
        elif not was:
            if v is Cavalry:
                riders += 1
            elif v.leader == null:
                sworn.append(v.person_name)
    if quiet:
        return
    for nm in sworn:
        feed.append("%s is sworn into the watch." % nm)
    if riders == 1:
        feed.append("Another rider joins the mounted watch on Bellmire's roads.")
    elif riders > 1:
        feed.append("The mounted watch rides out of the Town Stables: %d riders on Bellmire's roads." % riders)

## ---------------------------------------------------------------- the guild
## Viewers' heroes. Roster + ChatCmd are the old game's, ported verbatim (pure
## rules; replies go to the on-screen feed - nothing is posted to Twitch).
## Here they get bodies: !enlist raises a hero on the square, !forge / !armoury
## walks them to the smith / armourer, !fish to a dock (Fishing rolls the
## catch), !delve up the Delvers' Road to the guild post and the scar mouth.
func _start_guild() -> void:
    roster = Roster.new()
    add_child(roster)
    # heroes persist between streams (old rule: user://roster.json, saved every
    # 30 s). Test harnesses run with --script and must never touch the real save.
    persist = not OS.get_cmdline_args().has("--script")
    if persist:
        roster.load_all()
        for uid in roster.heroes:
            if roster.is_alive(String(uid)):
                call_deferred("_raise", String(uid))
    chat = ChatCmd.new(roster)
    add_child(chat)
    chat.say.connect(func(line: String, col: Color) -> void:
        feed.append(line)
        print("FEED ", line))
    chat.wants_delve.connect(_on_delve)
    chat.wants_fish.connect(_on_fish)
    chat.wants_shop.connect(_on_shop)
    chat.catches_of = func(who: String) -> Array:
        var out: Array = []
        for e in fishing_log:
            if String(e.get("who", "")) == who:
                out.append(e)
        return out

## the one entry point for chat - a fake feed in tests, Twitch IRC in play
func chat_line(user_id: String, display: String, msg: String) -> String:
    var out := chat.handle(user_id, display, msg)
    var h := roster.get_hero(user_id)
    if not h.is_empty() and roster.is_alive(user_id) and not heroes.has(user_id):
        _raise(user_id)
    if heroes.has(user_id):
        (heroes[user_id] as HeroBody).refresh()
    return out

func _raise(uid: String) -> void:
    var b := HeroBody.new()
    b.setup(roster, uid)
    b.town = self
    b.stay = true
    var a := TAU * float(heroes.size()) / 6.0
    var at := _market_pos + Vector3(cos(a), 0, sin(a)) * 6.5
    b.face_yaw = atan2(-cos(a), -sin(a))
    b.position = Vector3(at.x, height_at(at.x, at.z), at.z)
    add_child(b)
    heroes[uid] = b
    people.append(b)

func _on_shop(uid: String, kind: String) -> void:
    if not heroes.has(uid):
        return
    for sh in shops:
        if String(sh[0]) == kind:
            var y: Vector3 = sh[1]
            var f: Vector3 = sh[2]
            var b: HeroBody = heroes[uid]
            var slot := float(heroes.keys().find(uid) % 4) - 1.5
            b.go(y + f * 4.5 + Vector3(-f.z, 0, f.x) * slot * 1.4, kind, func() -> void:
                b.face_yaw = atan2(-f.x, -f.z)
                b.rotation.y = b.face_yaw
                b.refresh())
            return

func _on_fish(uid: String) -> void:
    if not heroes.has(uid) or docks.is_empty():
        return
    var b: HeroBody = heroes[uid]
    var d: Array = docks[heroes.keys().find(uid) % docks.size()]
    var end: Vector3 = d[0]
    var fw: Vector3 = d[1]
    var land := end - fw * 12.0
    b.go(land, "fish", func() -> void:
        # out along the dock to the end, then cast
        b.position = Vector3(end.x + 1.0, DOCK_Y + 0.12, end.z - fw.z * 1.5)
        b.face_yaw = atan2(fw.x, fw.z)
        b.rotation.y = b.face_yaw
        for old in b.get_children():
            if old is Angler:
                old.queue_free()          # one rod per hero
        var ang := Angler.new()
        ang.who = b.person_name
        ang.water_y = WATER_Y
        ang.demo = true
        # D9: the hero strikes the bite with their own DEX (+ proficiency for a
        # ranger or a druid, who know the river)
        var fh: Dictionary = roster.get_hero(uid) if roster else {}
        if not fh.is_empty():
            ang.hook_bonus = roster.mod(fh, "dex") + (roster.prof(fh) if String(fh.get("class", "")) in ["ranger", "druid"] else 0)
        ang.target = end + fw * 7.0 + Vector3(1.0, 0, 0)
        ang.target.y = WATER_Y
        ang.caught.connect(func(item: Dictionary, who: String) -> void:
            _on_caught(item, who)
            if int(item.get("strike", 0)) == 20:
                feed.append("%s rolls a 20 on the strike - a perfect hook!" % who)
            feed.append("%s lands a %s (%s)!" % [who, item.get("name"), item.get("rarity")])
            print("FEED ", feed.back()))
        b.add_child(ang))

func _on_delve(uid: String) -> void:
    if not heroes.has(uid) or not _scar_info.has("post"):
        return
    var b: HeroBody = heroes[uid]
    chat.away[uid] = "on the road to the scar"
    var post: Vector3 = _scar_info["post"]
    var mouth: Vector3 = _scar_info["mouth"]
    var gate: Vector3 = _scar_info.get("gate", post)
    var fw: Vector3 = _scar_info["fwd"]
    var k := heroes.keys().find(uid)
    var side := Vector3(-fw.z, 0, fw.x) * (float(k % 4) - 1.5) * 1.6
    b.go(gate, "delve", func() -> void:
        # past the guild post, up the track to wait at the mouth
        b._route = [post - fw * 3.0 + side, mouth + fw * (6.0 + float(k / 4) * 2.0) + side]
        b.stay = false
        b._route_done = func() -> void:
            b.face_yaw = atan2(-fw.x, -fw.z)
            b.rotation.y = b.face_yaw
            feed.append("%s stands at the mouth of the scar." % b.person_name)
            chat.away[uid] = "waiting at the mouth of the scar"
            print("FEED ", feed.back())
            _at_mouth.append(uid)
            if _muster_t < 0.0:
                _muster_t = 0.0
            _since_last = 0.0)

func _begin_delve() -> void:
    if delve != null or _at_mouth.is_empty():
        return
    delve = Delve.new()
    delve.town = self
    delve.roster = roster
    add_child(delve)
    for uid in _at_mouth:
        if heroes.has(uid):
            (heroes[uid] as Node3D).visible = false
    # old rule: the party draws half a set of gear each from the rack (+2 to
    # every blow), or goes without and the town notes the want
    if economy.take("gear", float(_at_mouth.size()) * 0.5):
        delve.kit_bonus = 2.0
        _stock_piles()
    for uid in _at_mouth:
        chat.away[uid] = "below, in the scar"
    delve.start(_at_mouth.duplicate())
    delve.ended.connect(func(survivors: Array) -> void:
        for uid in _at_mouth:
            chat.away.erase(uid)
            chat.delve_queue.erase(uid)
            if heroes.has(uid):
                var hb: HeroBody = heroes[uid]
                if survivors.has(uid):
                    # they climb out of the scar mouth and walk home to the square
                    hb.visible = true
                    var mo: Vector3 = _scar_info.get("mouth", _market_pos)
                    var fw: Vector3 = _scar_info.get("fwd", Vector3(0, 0, 1))
                    var k := survivors.find(uid)
                    var p := mo + fw * (2.5 + float(k / 2) * 1.6) + Vector3(-fw.z, 0, fw.x) * (float(k % 2) - 0.5) * 1.6
                    p.y = height_at(p.x, p.z)
                    hb.global_position = p
                    hb.rotation.y = atan2(fw.x, fw.z)
                    hb.refresh()
                    var a := randf() * TAU
                    var home := _market_pos + Vector3(cos(a), 0, sin(a)) * 6.0
                    hb.stay = false
                    hb.go(home, "home", func() -> void:
                        hb.stay = true)
                else:
                    # out of people too, or every walker of the list (economy,
                    # casters) meets a freed hero there
                    people.erase(hb)
                    hb.queue_free()
                    heroes.erase(uid)
        _at_mouth.clear()
        delve.queue_free()
        delve = null)


func _nearest_road(p: Vector3) -> Vector2i:
    var best := Vector2i(-1, -1)
    var bd := 1e18
    for cell in road_cells:
        var c: Vector3 = Hex.pos(cell.x, cell.y)
        var d: float = (c.x - p.x) * (c.x - p.x) + (c.z - p.z) * (c.z - p.z)
        if d < bd:
            bd = d
            best = cell
    return best

## Street route between two points: to the nearest road, along the road graph
## (breadth-first over road hexes), off the road to the destination. Walkers
## keep to the right of the centreline so two-way traffic does not collide.
func route(from: Vector3, to: Vector3) -> Array:
    if nav and nav.ready_ok:
        var pp := nav.path(from, to)
        if pp.size() > 0:
            var out: Array = []
            for i in range(1, pp.size()):
                out.append(pp[i])
            # only finish on the exact spot if it is walkable ground - or a
            # step or two beyond it with nothing solid between (a door spot
            # sits closer to its house than the navmesh's half-metre margin)
            var last: Vector3 = pp[pp.size() - 1]
            var gap := Vector2(to.x - last.x, to.z - last.z).length()
            if gap < 0.6 or (gap < 2.6 and _clear_line(last, to)):
                out.append(to)
            return out
    var a := _nearest_road(from)
    var b := _nearest_road(to)
    if a.x < 0 or b.x < 0:
        return [to]
    var prev := {a: a}
    var q: Array[Vector2i] = [a]
    while not q.is_empty():
        var c: Vector2i = q.pop_front()
        if c == b:
            break
        for n in Hex.neighbours(c):
            if road_cells.has(n) and not prev.has(n):
                prev[n] = c
                q.append(n)
    if not prev.has(b):
        return [to]
    var cells: Array[Vector2i] = []
    var cur := b
    while cur != a:
        cells.push_front(cur)
        cur = prev[cur]
    cells.push_front(a)
    var pts: Array = []
    for i in range(cells.size()):
        var p: Vector3 = Hex.pos(cells[i].x, cells[i].y)
        var nx: Vector3 = Hex.pos(cells[mini(i + 1, cells.size() - 1)].x, cells[mini(i + 1, cells.size() - 1)].y)
        var t := nx - p
        t.y = 0.0
        if t.length() > 0.1:
            t = t.normalized()
            p += Vector3(-t.z, 0.0, t.x) * 1.8
        pts.append(p)
    if _wall_info.has("ax"):
        var ax: float = float(_wall_info["ax"])
        var az: float = float(_wall_info["az"])
        if sqrt(pow(to.x / ax, 2.0) + pow(to.z / az, 2.0)) > 1.0:
            var gbest := Vector3.ZERO
            var gd := 1e9
            for g in _wall_info.get("gates", []):
                var gv: Vector3 = g
                if gv.distance_to(to) < gd:
                    gd = gv.distance_to(to)
                    gbest = gv
            if gd < 1e8:
                var out := Vector3(gbest.x, 0.0, gbest.z).normalized()
                pts.append(gbest - out * 6.0)
                pts.append(gbest + out * 10.0)
    pts.append(to)
    return pts

## ---- D1: people give each other room. A coarse 2 m grid of everyone out on
## the streets, rebuilt once a physics frame; crowd_push(v) is the shove away
## from whoever stands closer than CROWD_R (posted folk count as obstacles).
const CROWD_R := 0.75
var _crowd_f := -1
var _crowd: Dictionary = {}

func crowd_push(v: Node3D) -> Vector3:
    var f := Engine.get_physics_frames()
    if f != _crowd_f:
        _crowd_f = f
        _crowd.clear()
        for o in people:
            if not is_instance_valid(o) or not (o as Node3D).visible or bool(o.get("inside")):
                continue
            var op: Vector3 = (o as Node3D).global_position
            var key := Vector2i(floori(op.x * 0.5), floori(op.z * 0.5))
            if not _crowd.has(key):
                _crowd[key] = []
            (_crowd[key] as Array).append(o)
    var p := v.global_position
    var kx := floori(p.x * 0.5)
    var kz := floori(p.z * 0.5)
    var push := Vector3.ZERO
    for dx in range(-1, 2):
        for dz in range(-1, 2):
            var cell = _crowd.get(Vector2i(kx + dx, kz + dz))
            if cell == null:
                continue
            for o in cell:
                if o == v:
                    continue
                var op: Vector3 = (o as Node3D).global_position
                var d := Vector3(p.x - op.x, 0.0, p.z - op.z)
                var L := d.length()
                if L < CROWD_R:
                    if L < 0.01:
                        d = Vector3(cos(float(v.get_instance_id() % 628) * 0.01), 0.0, sin(float(v.get_instance_id() % 628) * 0.01))
                        L = 0.01
                    push += d / L * (CROWD_R - L) / CROWD_R
    return push

## nothing solid on the straight line a -> b (feet only, no margin)
func _clear_line(a: Vector3, b: Vector3) -> bool:
    var n := maxi(int(Vector2(b.x - a.x, b.z - a.z).length() / 0.25), 1)
    for i in range(n + 1):
        if not solid_at(a.lerp(b, float(i) / float(n)), 0.05).is_empty():
            return false
    return true

## where a walker may put its foot: pushed back out of any house, stall,
## table or wall section it stepped into (height from the ground). A 4 m grid
## of the solid footprints - nav.closest() is a scan of every polygon (0.3 ms)
## and far too dear for every walker every frame.
const SOLID_CELL := 4.0
const FOOT_R := 0.15
var _sgrid: Dictionary = {}
var _sgrid_key := ""
var _sgrid_f := -100000

func _solid_footprints() -> Array:
    var rects: Array = _solid_rects.duplicate()
    for plot in plots:
        var sh: String = String(plot.get("shape", "a"))
        if not _house_box.has(sh):
            continue
        var he: Vector2 = (_house_box[sh][0] as Vector2) * 1.04 + Vector2(0.15, 0.15)
        var off: Vector2 = _house_box[sh][1]
        var yaw: float = float(plot["yaw"])
        var ax := Vector2(cos(yaw), -sin(yaw))
        var az := Vector2(sin(yaw), cos(yaw))
        var pp: Vector3 = plot["pos"]
        rects.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, he])
    for w in _wall_solid:
        var wp: Vector3 = w[0]
        var tg: Vector3 = w[1]
        rects.append([Vector2(wp.x, wp.z), Vector2(tg.x, tg.z), Vector2(-tg.z, tg.x), Vector2(1.9, 1.1)])
    return rects

func _solid_grid() -> Dictionary:
    var f := Engine.get_physics_frames()
    if f - _sgrid_f < 600:
        return _sgrid
    _sgrid_f = f
    var key := "%d/%d/%d" % [_solid_rects.size(), plots.size(), _wall_solid.size()]
    if key == _sgrid_key:
        return _sgrid
    _sgrid_key = key
    _sgrid = {}
    for r in _solid_footprints():
        var c: Vector2 = r[0]
        var he: Vector2 = r[3]
        var ext: float = (r[1] as Vector2).abs().x * he.x + (r[2] as Vector2).abs().x * he.y
        var ezt: float = (r[1] as Vector2).abs().y * he.x + (r[2] as Vector2).abs().y * he.y
        for gx in range(floori((c.x - ext - FOOT_R) / SOLID_CELL), floori((c.x + ext + FOOT_R) / SOLID_CELL) + 1):
            for gz in range(floori((c.y - ezt - FOOT_R) / SOLID_CELL), floori((c.y + ezt + FOOT_R) / SOLID_CELL) + 1):
                var k := Vector2i(gx, gz)
                if not _sgrid.has(k):
                    _sgrid[k] = []
                (_sgrid[k] as Array).append(r)
    return _sgrid

## the solid footprint p stands in (with margin m), or [] if none
func solid_at(p: Vector3, m := 0.0) -> Array:
    var cell = _solid_grid().get(Vector2i(floori(p.x / SOLID_CELL), floori(p.z / SOLID_CELL)))
    if cell == null:
        return []
    for r in cell:
        var d := Vector2(p.x, p.z) - (r[0] as Vector2)
        var he: Vector2 = r[3]
        if absf(d.dot(r[1])) < he.x + m and absf(d.dot(r[2])) < he.y + m:
            return r
    return []

func keep_walkable(p: Vector3) -> Vector3:
    for i in range(3):
        var r := solid_at(p, FOOT_R)
        if r.is_empty():
            break
        var ax: Vector2 = r[1]
        var az: Vector2 = r[2]
        var he: Vector2 = r[3]
        var d := Vector2(p.x, p.z) - (r[0] as Vector2)
        var lx := d.dot(ax)
        var lz := d.dot(az)
        var gx := he.x + FOOT_R + 0.02 - absf(lx)
        var gz := he.y + FOOT_R + 0.02 - absf(lz)
        var mv := ax * signf(lx if lx != 0.0 else 1.0) * gx if gx < gz else az * signf(lz if lz != 0.0 else 1.0) * gz
        p.x += mv.x
        p.z += mv.y
    p.y = height_at(p.x, p.z)
    return p

func _count_inside() -> int:
    var n := 0
    for v in people:
        if v.inside:
            n += 1
    return n

func stats() -> Dictionary:
    var counts := {}
    for plot in plots:
        var id: String = plot["district"]
        counts[id] = int(counts.get(id, 0)) + 1
    var shapes := {}
    for plot in plots:
        var k: String = String(plot.get("shape", "?"))
        shapes[k] = int(shapes.get(k, 0)) + 1
    return {"bridge_z": snappedf(_bridge_z, 0.1), "wall": _wall_info, "landmarks": landmarks, "scar": _scar_info, "fields": _fields.map(func(f): return f[0]), "farms": farms, "animals": animals.size(), "pens": _pens, "furniture": _furniture, "docks": docks, "catches": fishing_log.size(), "inside": _count_inside(), "market": _market_pos, "people": people.size(), "shops": shops, "towers": towers, "rejected": _rejected, "overlap_dropped": _overlap_dropped, "house_box": _house_box, "shapes": shapes, "square": square.size(),
            "props": _props_made, "nature": _nature_made,
            "hexes": district_of.size(), "roads": road_cells.size(),
            "plots": plots.size(), "plots_per_district": counts,
            "livery": livery_of}

func _notification(what: int) -> void:
    if (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE) and persist and roster:
        roster.save_all()

## ================================ caravans =================================
## Ported from the old town._caravan: a caravan master comes in on the west
## road with a wagon, stands at the market, and after a while settles the trade
## against the town's prices - selling goods the town is short of (price above
## 1.12x base, treasury over 80), buying up anything over 90 in store - then
## heads back out. One every 70-120 s.
var _caravan_t := randf_range(70.0, 120.0)
var _caravans: Array = []       # {v, start, phase, t}

func _caravan() -> void:
    var gw := _gate(-1.0)
    var outw := Vector3(gw.x, 0, gw.z).normalized()
    var start := gw + outw * 45.0
    start.y = height_at(start.x, start.z)
    var v := Townsfolk.new()
    v.role = "caravan"
    v.model = "Rogue_Hooded.glb"
    v.tint = Color(0.62, 0.86, 0.66)
    v.person_name = "Caravan master"
    v.speed = 3.2
    v.town = self
    v.position = start
    add_child(v)
    var w := _spawn_raw(MKPROPS, "Prop_Wagon", Vector3(start.x, start.y, start.z) - outw * -2.6, PI * 0.5, 0.8)
    v.cart = w
    var stand := _market_pos + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
    v._route = route(start, stand)
    v._linger = 99999.0
    _caravans.append({"v": v, "start": start, "phase": "in", "t": 0.0, "wagon": w})
    feed.append("A trade caravan is sighted on the west road.")

func _caravan_pass(delta: float) -> void:
    _caravan_t -= delta
    if _caravan_t <= 0.0:
        _caravan_t = randf_range(70.0, 120.0)
        _caravan()
    for c in _caravans.duplicate():
        var v: Townsfolk = c["v"]
        if not is_instance_valid(v):
            _caravans.erase(c)
            continue
        match String(c["phase"]):
            "in":
                if v._route.is_empty():
                    c["phase"] = "trade"
                    c["t"] = 16.0
            "trade":
                c["t"] = float(c["t"]) - delta
                if float(c["t"]) <= 0.0:
                    _settle_trade()
                    v._route = route(v.global_position, c["start"])
                    c["phase"] = "out"
            "out":
                if v._route.is_empty():
                    if is_instance_valid(c["wagon"]):
                        (c["wagon"] as Node).queue_free()
                    v.queue_free()
                    _caravans.erase(c)

func _settle_trade() -> void:
    var spent := 0
    var sold := []
    var bought := []
    for g in Economy.GOODS:
        var pr: float = economy.price(g)
        var base_p: float = Economy.BASE_PRICE[g]
        var have: float = economy.stock.get(g, 0.0)
        if pr > base_p * 1.12 and economy.treasury > 80:
            var qty := 8.0
            economy.add(g, qty)
            var cost := int(qty * pr * 0.85)
            economy.treasury = max(0, economy.treasury - cost)
            spent += cost
            sold.append(g)
        elif have > 90.0:
            var qty2: float = min(30.0, have * 0.3)
            economy.take(g, qty2)
            economy.treasury += int(qty2 * maxf(pr, base_p * 0.5) * 0.9)
            bought.append(g)
    if not sold.is_empty():
        feed.append("Caravan sells the town %s for %d gold." % [", ".join(sold), spent])
    if not bought.is_empty():
        feed.append("Caravan buys up surplus %s." % ", ".join(bought))
    if sold.is_empty() and bought.is_empty():
        feed.append("The caravan finds nothing worth trading and moves on.")
    _stock_piles()

## ================================ settlers =================================
## old town._arrive: a newcomer walks in at the west gate and goes to work.
## Here they get a home and a workplace exactly as the founding ROSTER did.
func home_count() -> int:
    var n := 0
    for pl in plots:
        if not pl.has("back") and not pl.has("shop") and not pl.has("landmark") and pl.has("door"):
            n += 1
    return n

func arrive(role: String, blurb: String) -> Townsfolk:
    var row: Array = []
    for r in ROSTER:
        if String(r[0]) == role:
            row = r
            break
    if row.is_empty():
        return null
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var v := Townsfolk.new()
    v.role = role
    v.model = row[2]
    v.tint = Color(float(row[3]), float(row[4]), float(row[5]))
    v.person_name = "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
    v.town = self
    var pool: Array = []
    for pl in plots:
        if String(pl.get("district", "")) == String(row[1]):
            pool.append(pl)
    if pool.is_empty():
        pool = plots
    var home_plot: Dictionary = _home_for(rng)
    var work_plot: Dictionary = pool[rng.randi() % pool.size()]
    var lmk: String = String(ROLE_LANDMARK.get(role, ""))
    for pl in plots:
        if lmk != "" and String(pl.get("landmark", "")) == lmk:
            work_plot = pl
    for site in _sites:
        if lmk != "" and String(site["landmark"]) == lmk:
            work_plot = site
    v.home = _door(home_plot)
    v.home_in = _door_in(home_plot)
    v.work = _door(work_plot)
    v.work_in = _door_in(work_plot)
    if role == "trader":
        v.work = _market_pos + Vector3(rng.randf_range(-7.0, 7.0), 0.0, rng.randf_range(-7.0, 7.0))
    v.set_meta("hp", {"guard": 64.0, "chief": 40.0}.get(role, 28.0))
    var gw := _gate(-1.0)
    var start := gw + Vector3(gw.x, 0, gw.z).normalized() * 30.0
    start.y = height_at(start.x, start.z)
    v.position = start
    add_child(v)
    people.append(v)
    v._route = route(start, v.work)
    var line := blurb % v.person_name
    if _on_streets() > STREET_CAP and role != "guard":
        _keep_indoors(v)
    feed.append(line)
    print("FEED ", line)
    return v

## ---- D7: a population cap on the STREETS, not on the town. Past STREET_CAP
## walkers a newcomer still settles - a soul of Bellmire, counted for the town's
## level, fed and taxed - but keeps to the house (no body walking, no physics).
## When someone in the streets is buried, one of them steps out to take the place.
const STREET_CAP := 200
var indoor_souls := 0

func _on_streets() -> int:
    var n := 0
    for p in people:
        if is_instance_valid(p) and not p.has_meta("indoor_soul"):
            n += 1
    return n

func _keep_indoors(v: Townsfolk) -> void:
    v.set_meta("indoor_soul", true)
    v._route = []
    v.inside = true
    v.visible = false
    v.global_position = Vector3(v.home.x, height_at(v.home.x, v.home.z), v.home.z)
    v.process_mode = Node.PROCESS_MODE_DISABLED
    indoor_souls += 1

func _step_out() -> void:
    for p in people:
        if is_instance_valid(p) and p.has_meta("indoor_soul"):
            var v: Townsfolk = p
            v.remove_meta("indoor_soul")
            v.process_mode = Node.PROCESS_MODE_INHERIT
            v.inside = true          # comes out of the front door on its next trip
            v._wait = randf_range(1.0, 6.0)
            indoor_souls -= 1
            return

## a townsfolk dies: the line, the fall, and the body cleared after a while
func bury(v: Townsfolk, line: String) -> void:
    if not is_instance_valid(v):
        return
    people.erase(v)
    if v.has_meta("indoor_soul"):
        indoor_souls -= 1
    elif _on_streets() < STREET_CAP:
        _step_out()
    v.stay = true
    v._route = []
    Rig.play(v._anim, "Death_A")
    if economy:
        economy.dead += 1
    feed.append(line)
    print("FEED ", line)
    var vid := v.get_instance_id()           # D8: never capture a node that may be freed first
    get_tree().create_timer(25.0).timeout.connect(func() -> void:
        var o := instance_from_id(vid)
        if o != null and is_instance_valid(o):
            (o as Node).queue_free())

func npc_name() -> String:
    return "%s %s" % [FIRST[randi() % FIRST.size()], LAST[randi() % LAST.size()]]

## ---- HD: trodden ground only where feet go. The whole town used to be one
## dark dirt disc, so every block read as a void with houses dropped on it.
## This mask (red = trodden) is painted from the streets and the house plots:
## the street verges and each house's own footprint and doorstep are dirt,
## the middle of every block is grass - kitchen gardens and greens.
const MASK_HALF := 200.0
const MASK_N := 400
func _town_mask() -> ImageTexture:
    var img := Image.create(MASK_N, MASK_N, false, Image.FORMAT_L8)
    img.fill(Color(0, 0, 0))
    var px := float(MASK_N) / (MASK_HALF * 2.0)
    var paint := func(cx: float, cz: float, rad: float, d: Callable) -> void:
        var i0 := clampi(int((cx - rad + MASK_HALF) * px), 0, MASK_N - 1)
        var i1 := clampi(int((cx + rad + MASK_HALF) * px), 0, MASK_N - 1)
        var j0 := clampi(int((cz - rad + MASK_HALF) * px), 0, MASK_N - 1)
        var j1 := clampi(int((cz + rad + MASK_HALF) * px), 0, MASK_N - 1)
        for j in range(j0, j1 + 1):
            for i in range(i0, i1 + 1):
                var w := Vector3((float(i) + 0.5) / px - MASK_HALF, 0, (float(j) + 0.5) / px - MASK_HALF)
                var v: float = d.call(w)
                if v > img.get_pixel(i, j).r:
                    img.set_pixel(i, j, Color(v, v, v))
    for sg in _road_segs:
        var a: Vector3 = sg[0]
        var b2: Vector3 = sg[1]
        var hw: float = float(sg[2])
        var fall := 4.5
        paint.call((a.x + b2.x) * 0.5, (a.z + b2.z) * 0.5, a.distance_to(b2) * 0.5 + hw + fall,
            func(w: Vector3) -> float:
                return 1.0 - clampf((_seg_dist(w, a, b2) - hw) / fall, 0.0, 1.0))
    for plot in plots:
        var r: Array = _rect(plot)
        var c: Vector2 = r[0]
        var ax: Vector2 = r[1]
        var az: Vector2 = r[2]
        var he: Vector2 = r[3]
        paint.call(c.x, c.y, he.length() + 3.0,
            func(w: Vector3) -> float:
                var d := Vector2(w.x, w.z) - c
                var ox := maxf(absf(d.dot(ax)) - he.x, 0.0)
                var oz := maxf(absf(d.dot(az)) - he.y, 0.0)
                return 1.0 - clampf(Vector2(ox, oz).length() / 2.5, 0.0, 1.0))
    if _market_pos != Vector3.ZERO:
        paint.call(_market_pos.x, _market_pos.z, 26.0,
            func(w: Vector3) -> float:
                return 1.0 - clampf((Vector2(w.x - _market_pos.x, w.z - _market_pos.z).length() - 20.0) / 5.0, 0.0, 1.0))
    return ImageTexture.create_from_image(img)

## ---- HD: lived-in doorways (Fantasy Props MegaKit). A lantern on the wall
## beside every street door, and most houses keep something by the step - a
## barrel, a bucket, a crate of apples, a bench to sit on of an evening. All
## of it is solid: the navmesh walks people round it.
const DOOR_BITS := ["Barrel", "Bucket_Wooden_1", "FarmCrate_Apple", "FarmCrate_Carrot",
    "Crate_Wooden", "Bench", "Pot_1", "Barrel_Apples", "Bucket_Metal", "FarmCrate_Empty"]
var _doors_dressed := 0
func _dress_doors() -> void:
    for plot in plots:
        if plot.has("landmark") or plot.has("shop") or not plot.has("door"):
            continue
        var d: Vector3 = plot["door"]
        var f := _fwd(plot)
        var side := Vector3(f.z, 0.0, -f.x)
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("door:%d:%d" % [int(d.x * 10.0), int(d.z * 10.0)])
        var hand := 1.0 if rng.randf() < 0.5 else -1.0
        var lan := _yard("Lantern_Wall", d, side, f, 1.15 * hand, -0.45, PI)
        if lan:
            lan.position.y += 2.15
        if rng.randf() < 0.75:
            var nm: String = DOOR_BITS[rng.randi() % DOOR_BITS.size()]
            var yo := 0.0 if nm == "Bench" else rng.randf_range(-0.6, 0.6)
            _yard(nm, d, side, f, -1.9 * hand, 0.15, yo + (PI * 0.5 if nm == "Bench" else 0.0))
        _doors_dressed += 1

