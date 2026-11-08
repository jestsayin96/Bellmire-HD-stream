extends SceneTree
## Floors 1, 5 and 9: top-down plan + two in-room views each.
var _f := 0
var _d: DungeonHD
var _cam: Camera3D
var _floors := [3, 6]
var _fi := 0
var _shot := 0
func _initialize() -> void:
    var we := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.02, 0.02, 0.03)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.35, 0.33, 0.42)
    e.ambient_light_energy = 0.5
    e.glow_enabled = true
    e.tonemap_mode = Environment.TONE_MAPPER_AGX
    e.ssao_enabled = true
    we.environment = e
    root.add_child(we)
    _cam = Camera3D.new()
    root.add_child(_cam)
    _cam.make_current()
func _next() -> void:
    if _d:
        _d.queue_free()
    _d = DungeonHD.new()
    _d.floor_no = _floors[_fi]
    root.add_child(_d)
func _process(_dt: float) -> bool:
    _f += 1
    if _f == 2:
        _next()
    if _f < 30:
        return false
    var step := (_f - 30) % (60 if _shot == 1 else 12)
    if step != 0:
        return false
    var fl: int = _floors[_fi]
    if _shot > 0:
        root.get_texture().get_image().save_png("user://floor%d_%d.png" % [fl, _shot - 1])
        print("SAVED floor", fl, "_", _shot - 1, " theme=", _d.info.get("theme"), " shape=", _d.info.get("shape"), " mons=", _d.monsters.size(), " lord=", _d.lord != null)
    if _shot == 0:
        var G: float = _d.info["grid"]
        var span: float = float(_d.info["w"]) * G
        _cam.fov = 60.0
        _cam.global_position = Vector3(0, span * 0.95, span * 0.35)
        _cam.look_at(Vector3(0, 0, 0), Vector3.UP)
    elif _shot <= 2:
        var tgt: Vector3
        if _shot == 1:
            tgt = _d.lord.global_position if _d.lord else (_d.monsters[0].global_position if not _d.monsters.is_empty() else _d.info["exit"])
        else:
            tgt = _d.info["entry"]
        # stand INSIDE: step from the target toward open floor (the nearest
        # occupied cell 2 cells away), eye height, looking back at it
        var G2: float = _d.info["grid"]
        var hw2 := (float(_d.info["w"]) - 1.0) * G2 * 0.5
        var hh2 := (float(_d.info["h"]) - 1.0) * G2 * 0.5
        var cells: Dictionary = _d.info["cells"]
        var tc := Vector2i(int(round((tgt.x + hw2) / G2)), int(round((tgt.z + hh2) / G2)))
        var best := tgt + Vector3(4, 0, 4)
        for d in [Vector2i(0, 2), Vector2i(2, 0), Vector2i(0, -2), Vector2i(-2, 0), Vector2i(2, 2), Vector2i(-2, 2), Vector2i(2, -2), Vector2i(-2, -2), Vector2i(0, 1), Vector2i(1, 0)]:
            var cc: Vector2i = tc + d
            if cells.has(cc) and cells.has(tc + Vector2i(d.x / 2, d.y / 2)):
                best = Vector3(float(cc.x) * G2 - hw2, 0, float(cc.y) * G2 - hh2)
                break
        _cam.fov = 70.0
        var up := 7.0 if _d.lord and _shot == 1 else 2.6
        _cam.global_position = best + Vector3(0, up, 0)
        _cam.look_at(tgt + Vector3(0, 1.2 if up < 5.0 else 3.0, 0), Vector3.UP)
    else:
        _fi += 1
        _shot = 0
        if _fi >= _floors.size():
            return true
        _next()
        _f = 3
        return false
    _shot += 1
    return false
