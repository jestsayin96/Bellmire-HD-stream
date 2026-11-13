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
const DECAL_TEX := "res://assets/dungeon_look/decal_%s.png"
const THEME_DECAL := {"wood": "moss", "grassland": "moss", "flooded": "moss",
    "firepit": "soot", "workshop": "soot", "prison": "blood", "barracks": "blood", "crypt": "blood"}
const SCAR_VEIN := Color(0.62, 0.32, 1.0)
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
    var veins := 0 if floor_no < 6 else mini(floor_no - 4, 6)
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
        if not walls.is_empty() and kind != "blood" and r.randf() < 0.45:
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
            var s2 := r.randf_range(2.6, 3.8) * (0.85 if kind == "blood" else 1.0)
            d.position = base + Vector3(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 1.0))
            d.rotation.y = r.randf() * TAU
            d.size = Vector3(s2, 0.7, s2)
            d.normal_fade = 0.35
        d.upper_fade = 0.2
        d.lower_fade = 0.2
        match String(kind):
            "veins":
                d.modulate = SCAR_VEIN
                d.texture_emission = _decal_tex("veins_glow")
                d.emission_energy = 2.4
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
        if Vector2(at.x - (o[0] as Vector3).x, at.z - (o[0] as Vector3).z).length() < r + float(o[1]):
            return false
    return true

## pieces that stand up block the way; traps and plates are walked over
func _place_solid(node: Node3D, c: Vector2i, r: float, yaw := 0.0) -> void:
    _place(node, c, yaw)
    (info["obstacles"] as Array).append([_cell_pos(c), r])

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
    var traps := [DungeonParts.spike_trap, DungeonParts.pressure_plate, DungeonParts.fire_trap,
                  DungeonParts.dart_trap, DungeonParts.blade_trap, DungeonParts.pit_trap]
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
                    _place_solid(DungeonParts.cell(3.0, 3.0, 2.8, i == 0), c, 1.9, float(_rng.randi() % 4) * PI * 0.5)
        "crypt", "shrine", "treasury":
            var c: Vector2i = take.call()
            if c.x > -999:
                _place_solid(DungeonParts.portcullis(), c, 1.2)
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
        var n := 1 + mini(int((d.get("ways", {}) as Dictionary).get("pack", 0)), count - placed - 1)
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
