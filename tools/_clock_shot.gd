extends SceneTree
## The square at noon, dusk and night (economy.clock drives everything).
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _at(h: float) -> void:
    _t.get("economy").clock = h / 24.0
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://clock_%s.png" % nm)
    print("SAVED ", nm, " hour=", _t.get("economy").hour(), " night=", _t.get("economy").is_night())
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 60.0
        _t.get("raids").set("_raid_t", 99999.0)
        var m: Vector3 = _t.get("_market_pos")
        _cam.global_position = m + Vector3(-6.0, 17.0, 24.0)
        _cam.look_at(m + Vector3(0, 0.0, -2.0), Vector3.UP)
        _at(12.0)
    if _f == 40:
        _snap("noon")
        _at(18.6)
    if _f == 70:
        _snap("dusk")
        _at(22.0)
    if _f == 100:
        _snap("night")
        print("GLASS ", _t.get("daylight")._glass.size(), " LIGHTS ", _t.get("daylight")._lights.size())
        return true
    if _f > 15 and _f < 100:
        # hold the hour still while we look
        var e: Economy = _t.get("economy")
        e.clock = (12.0 if _f < 40 else (18.6 if _f < 70 else 22.0)) / 24.0
    return false
