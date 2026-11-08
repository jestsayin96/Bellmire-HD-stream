extends SceneTree
## The wizard's lamp-stand: a party in the dark; photograph the stand once lit.
var _d: Delve
var _r: Roster
var _cam: Camera3D
var _f := 0
var _lit_f := -1
var _tries := 0
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
func _go() -> void:
    if _d:
        _d.queue_free()
    _d = Delve.new()
    _d.roster = _r
    _d.max_floors = 2
    root.add_child(_d)
    var ids := []
    for v in [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "DawnCleric", "cleric"], ["1004", "BigAxe", "barbarian"]]:
        var h: Dictionary = _r.fresh(v[0], v[1], v[2])
        h["oil"] = 0
        ids.append(v[0])
    _d.start(ids)
    _tries += 1
func _initialize() -> void:
    _env()
    _r = Roster.new()
    root.add_child(_r)
    _cam = Camera3D.new()
    root.add_child(_cam)
    _cam.make_current()
    _cam.fov = 55.0
func _process(_dt: float) -> bool:
    _f += 1
    if _f == 3:
        _go()
        Engine.time_scale = 4.0
    if _d == null or _d.dun == null or not _d.dun.info.has("lamp"):
        return false
    var lamp: Vector3 = _d.dun.info["lamp"] + _d.dun.global_position
    _cam.global_position = lamp + Vector3(5.0, 9.0, 8.0)
    _cam.look_at(lamp + Vector3(0, 1.0, 0), Vector3.UP)
    if _lit_f < 0 and _d.lamps_lit > 0:
        Engine.time_scale = 1.0
        _lit_f = _f + 45
    if _f == _lit_f:
        root.get_texture().get_image().save_png("user://lamp_lit.png")
        print("SAVED lamp tries=", _tries)
        return true
    # nobody reached it this delve: try another party
    if _lit_f < 0 and (_d.state == "home") and _tries < 8:
        _go()
    return _f > 60 * 600
