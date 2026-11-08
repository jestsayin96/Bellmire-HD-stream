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

func _ready() -> void:
    if info.is_empty():
        build(floor_no)

func build(n: int) -> void:
    floor_no = n
    for c in get_children():
        c.queue_free()
    monsters.clear()
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

## a spawn point clear of furniture AND on the floor: the nearest floor cell
## centre that no prop covers (a push out of a table must not cross a wall)
func _out_of_props(at: Vector3) -> Vector3:
    if _clear_of_props(at, 0.6) and _on_floor(at):
        return at
    var best := at
    var bd := 1e9
    for c in info["cells"]:
        var cp := _cell_pos(c)
        if not _clear_of_props(cp, 0.6):
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
    var traps := [DungeonParts.spike_trap, DungeonParts.pressure_plate, DungeonParts.fire_trap]
    for i in range(1 + mini(floor_no / 3, 3)):
        var c: Vector2i = take.call()
        if c.x > -999:
            _place((traps[_rng.randi() % traps.size()] as Callable).call(), c)
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
    for i in range(mini(count, pts.size())):
        var p: Vector3 = _out_of_props(pts[i])
        var m := Monster.new()
        m.def = Bestiary.pick(floor_no)
        m.state = Monster.S.PATROL
        m.roam = 3.0
        m.position = Vector3(p.x, 0.0, p.z)
        root.add_child(m)
        monsters.append(m)
    if bool(info.get("boss", false)):
        var b := Bestiary.next_boss(floor_no)
        if not b.is_empty():
            lord = Monster.new()
            lord.def = Bestiary.boss_def(b)
            lord.state = Monster.S.IDLE
            # the lord holds the open interior cell farthest from where the party
            # comes in - never the stairs, never a corridor
            var entry: Vector3 = info["entry"]
            var far := Vector3.ZERO
            var fd := -1.0
            for c in _open_cells():
                var cp := _cell_pos(c)
                var d := cp.distance_to(entry)
                if d > fd:
                    fd = d
                    far = cp
            lord.position = far
            root.add_child(lord)
            lord.call_deferred("entrance")
