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
    # every floor: a few traps on the open floor, debris in proportion to depth
    var traps := [DungeonParts.spike_trap, DungeonParts.pressure_plate, DungeonParts.fire_trap,
                  DungeonParts.dart_trap, DungeonParts.blade_trap, DungeonParts.pit_trap]
    for i in range(1 + mini(floor_no / 3, 3)):
        var c: Vector2i = take.call()
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
            lord.def = Bestiary.boss_def(b) if u.is_empty() else Bestiary.unique_def(u, floor_no)
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
