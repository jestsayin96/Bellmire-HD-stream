extends SceneTree
## A settler walking in through the west gate, chronicle on screen.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _v: Node3D
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
        _cam.fov = 52.0
        _t.get("raids").set("_raid_t", 99999.0)
        _v = _t.call("arrive", "farmer", "%s settles in Bellmire, looking for work.")
        Engine.time_scale = 3.0
    if _v == null:
        return _f > 30
    var gw: Vector3 = _t.call("_gate", -1.0)
    var d := Vector2(_v.global_position.x - gw.x, _v.global_position.z - gw.z).length()
    if _snap_f < 0 and d < 9.0:
        Engine.time_scale = 1.0
        _snap_f = _f + 6
    if _snap_f > 0:
        # inside the town, looking back out at the settler coming through the gate
        var inw := -Vector3(gw.x, 0, gw.z).normalized()
        var side := Vector3(-inw.z, 0, inw.x)
        var cp := gw + inw * 14.0 + side * 4.0
        cp.y = float(_t.call("height_at", cp.x, cp.z)) + 4.0
        _cam.global_position = cp
        _cam.look_at(_v.global_position + Vector3(0, 1.0, 0), Vector3.UP)
    if _f == _snap_f:
        root.get_texture().get_image().save_png("user://settler_gate.png")
        print("SAVED settler d=", d)
        return true
    return _f > 60 * 90
