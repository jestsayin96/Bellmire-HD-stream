extends SceneTree
## The town's own band gathering at the scar mouth.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _adv: Adventurers
var _snap_f := -1
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _adv = _t.get("adventurers")
        _t.get("raids").set("_raid_t", 99999.0)
        _adv.set("_party_t", 0.1)
        Engine.time_scale = 6.0
    if _adv == null or _f < 20:
        return false
    var sc: Dictionary = _t.get("_scar_info")
    var mo: Vector3 = sc["mouth"]
    var fw: Vector3 = sc["fwd"]
    var near := 0
    for u in _adv.bodies:
        var b: Node3D = _adv.bodies[u]
        if is_instance_valid(b) and b.visible and Vector2(b.global_position.x - mo.x, b.global_position.z - mo.z).length() < 12.0:
            near += 1
    if _snap_f < 0 and near >= 4:
        Engine.time_scale = 1.0
        _snap_f = _f + 10
    if _snap_f > 0:
        var look := mo + fw * 7.0
        look.y = float(_t.call("height_at", look.x, look.z)) + 1.0
        var cp := mo + fw * 17.0 + Vector3(-fw.z, 0, fw.x) * 5.0
        cp.y = float(_t.call("height_at", cp.x, cp.z)) + 5.5
        _cam.global_position = cp
        _cam.look_at(look, Vector3.UP)
    if _f == _snap_f:
        root.get_texture().get_image().save_png("user://band_mouth.png")
        print("SAVED near=", near)
        return true
    return _f > 60 * 120
