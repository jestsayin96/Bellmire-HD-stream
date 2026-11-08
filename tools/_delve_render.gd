extends SceneTree
## Delve render: a fight on floor 1, then a separate party at floor 5 vs its lord.
var _d: Delve
var _r: Roster
var _cam: Camera3D
var _f := 0
var _phase := 0
func _env() -> void:
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.02, 0.02, 0.03)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.35, 0.33, 0.42)
    e.ambient_light_energy = 0.55
    e.glow_enabled = true
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    we.environment = e
    root.add_child(we)
func _party(start: int) -> void:
    if _d:
        _d.queue_free()
    _d = Delve.new()
    _d.roster = _r
    _d.start_floor = start
    _d.max_floors = start
    root.add_child(_d)
    var ids := []
    for v in [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "DawnCleric", "cleric"], ["1004", "BigAxe", "barbarian"]]:
        var h: Dictionary = _r.get_hero(v[0])
        if h.is_empty():
            h = _r.fresh(v[0], v[1], v[2])
        h["alive"] = true
        h["weapon"] = 3
        h["armour"] = 3
        ids.append(v[0])
    _d.start(ids)
func _initialize() -> void:
    _env()
    _r = Roster.new()
    root.add_child(_r)
    _cam = Camera3D.new()
    root.add_child(_cam)
    _cam.make_current()
    _cam.fov = 60.0
func _centre() -> Vector3:
    var c := Vector3.ZERO
    var n := 0
    for m in _d._alive():
        c += (m["body"] as Node3D).global_position
        n += 1
    return c / maxf(float(n), 1.0)
func _aim(focus: Vector3, back: float, up: float) -> void:
    # near-overhead: walls are 3 m, so a steep look clears them
    _cam.global_position = focus + Vector3(back * 0.15, up, back * 0.35)
    _cam.look_at(focus + Vector3(0, 0.5, 0), Vector3.UP)
func _front() -> Vector3:
    # the hero nearest any foe: that is where the fight is
    var best := 1e9
    var bp := _centre()
    for m in _d._alive():
        var hp := (m["body"] as Node3D).global_position
        for f in _d._foes():
            var dd := _d._flat(hp, (f as Node3D).global_position)
            if dd < best:
                best = dd
                bp = hp.lerp((f as Node3D).global_position, 0.5) if dd < 6.0 else hp
    bp.y = _centre().y
    return bp
var _cool := 0
var _total := 0
func _process(_dt: float) -> bool:
    _f += 1
    _total += 1
    if _total > 9000:
        print("GAVE UP phase ", _phase)
        return true
    if _f == 3:
        _party(1)
    if _d == null or _d.dun == null:
        return false
    if _d._alive().is_empty():
        return false
    var c := _centre()
    if _phase == 0:
        _aim(_front(), 7.0, 12.0)
        var near := 1e9
        for f in _d._foes():
            near = minf(near, _d._flat((f as Node3D).global_position, c))
        if (near < 3.0 and _f > 90) or _f > 1500:
            _phase = 1
            _f = 1000
    elif _phase == 1:
        _aim(_front(), 7.0, 12.0)
        if _f == 1025:
            print("CAM fight ", _cam.global_position, " party ", c)
            root.get_texture().get_image().save_png("user://delve_fight1.png")
            print("SAVED fight1")
            _phase = 2
            _party(5)
            _f = 2000
            _d.set_meta("render", true)
    elif _phase == 2 or _phase == 3:
        var lord: Monster = _d.dun.lord
        if lord and is_instance_valid(lord):
            var lp := lord.global_position
            _aim(lp.lerp(c, 0.3) if _d._flat(c, lp) < 12.0 else lp, 12.0, 15.0)
            if _phase == 2 and (_d._flat(c, lp) < 5.0 or _f > 4800):
                _phase = 3
                _f = 3000
            if _phase == 3 and _f == 3060:
                print("CAM lord ", _cam.global_position, " lord ", lp, " party ", c, " dist ", _d._flat(c, lp))
                root.get_texture().get_image().save_png("user://delve_lord5.png")
                print("SAVED lord5")
                return true
    return false
