extends SceneTree
## D1 render: people on the streets keep to the streets - the market from
## above, a street between houses, and a raid coming in by the west gate.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _rd: Raids
var _out := ""
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261111_d1")
    DirAccess.make_dir_recursive_absolute(_out)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(_out + "/" + nm + ".png")
    print("SAVED ", nm)
func _aim(from: Vector3, at: Vector3) -> void:
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)
func _process(_d: float) -> bool:
    _f += 1
    var m: Vector3 = _t.get("_market_pos")
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _rd = _t.get("raids")
        _rd.set("_raid_t", 99999.0)
        var eco = _t.get("economy")
        if eco and eco.has_method("hour"):
            pass
        Engine.time_scale = 3.0
        _aim(m + Vector3(0, 30, 22), m)
    if _f == 600:
        Engine.time_scale = 1.0
    if _f == 640:
        _snap("market_above")
        # a street: the first house plot near the market, looking along its front
        var best: Dictionary = {}
        var bd := 1e9
        for pl in _t.get("plots"):
            if pl.has("landmark") or not pl.has("door"):
                continue
            var d: float = (pl["pos"] as Vector3).distance_to(m)
            if d > 14.0 and d < bd:
                bd = d
                best = pl
        if not best.is_empty():
            var dp: Vector3 = best["door"]
            var yaw: float = float(best["yaw"])
            var fw := Vector3(sin(yaw), 0, cos(yaw))
            var side := Vector3(-fw.z, 0, fw.x)
            _aim(dp + fw * 9.0 + side * 9.0 + Vector3(0, 7, 0), dp - side * 4.0)
    if _f == 900:
        _snap("street")
        _rd.force_level = 5
        _rd.raid("road")
        Engine.time_scale = 3.0
    if _f > 900 and _f < 3000 and not _rd.raiders.is_empty():
        var r: Node3D = _rd.raiders[0]["node"]
        if is_instance_valid(r):
            var p := r.global_position
            var gw: Vector3 = _t.call("_gate", -1.0)
            if p.distance_to(gw) < 9.0:
                Engine.time_scale = 1.0
                var outw := Vector3(gw.x, 0, gw.z).normalized()
                _aim(gw - outw * 10.0 + Vector3(-outw.z, 0, outw.x) * 8.0 + Vector3(0, 9, 0), gw)
                _f = 3000
    if _f == 3006:
        _snap("raid_gate")
    if _f == 3200:
        _snap("raid_inside")
        return true
    return _f > 60 * 90
