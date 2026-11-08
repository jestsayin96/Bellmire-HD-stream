extends SceneTree
## FPS in a real window at 1x: the full town from 17:00 through dusk into night,
## with the band and a raid going. One sample a second.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _samples: Array = []
var _acc := 0.0
var _t0 := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(dt: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 60.0
        var m: Vector3 = _t.get("_market_pos")
        _cam.global_position = m + Vector3(-6.0, 17.0, 24.0)
        _cam.look_at(m, Vector3.UP)
        _t.get("economy").clock = 17.0 / 24.0
        _t.get("raids").force_level = 3
        _t.get("raids").raid()
        _t0 = Time.get_ticks_msec()
    if _f < 60:
        return false
    _acc += dt
    if _acc >= 1.0:
        _acc = 0.0
        _samples.append(Engine.get_frames_per_second())
    if Time.get_ticks_msec() - _t0 > 45000:
        var mn := 1e9
        var sm := 0.0
        for x in _samples:
            mn = minf(mn, float(x))
            sm += float(x)
        print("FPS min=", mn, " avg=", snappedf(sm / maxf(1.0, float(_samples.size())), 0.1), " n=", _samples.size(), " hour_end=", snappedf(_t.get("economy").hour(), 0.1), " people=", (_t.get("people") as Array).size(), " samples=", _samples)
        return true
    return false
