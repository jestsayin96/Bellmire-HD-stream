extends SceneTree
## FAKE CHAT. Four viewers !delve; photograph them gathered at the mouth; a
## !fish while waiting must be refused.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _ms := 0
var _i := 0
var _snapped := false
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 50.0
        _t.get("raids").set("_raid_t", 99999.0)
        _t.get("adventurers").set("_party_t", 99999.0)
        for v in V:
            _t.call("chat_line", v[0], v[1], "!enlist " + v[2])
        _ms = Time.get_ticks_msec()
    if _f > 10 and _i < V.size() and Time.get_ticks_msec() - _ms > 1700:
        print("CHAT !delve -> ", _t.call("chat_line", V[_i][0], V[_i][1], "!delve"))
        _i += 1
        _ms = Time.get_ticks_msec()
        if _i == V.size():
            Engine.time_scale = 5.0
    var am: Array = _t.get("_at_mouth")
    if not _snapped and am.size() >= 1 and am.size() < V.size() and Time.get_ticks_msec() - _ms > 1700:
        print("CHAT !fish while ", am[0], " waits -> ", _t.call("chat_line", am[0], "x", "!fish"))
        _ms = Time.get_ticks_msec() + 99999
    if not _snapped and am.size() >= V.size():
        Engine.time_scale = 1.0
        _snapped = true
        var sc: Dictionary = _t.get("_scar_info")
        var mo: Vector3 = sc["mouth"]
        var fw: Vector3 = sc["fwd"]
        var c := mo + fw * 7.0
        c.y = float(_t.call("height_at", c.x, c.z))
        _cam.global_position = c + fw * 9.0 + Vector3(-fw.z, 0, fw.x) * 3.0 + Vector3(0, 3.2, 0)
        _cam.look_at(c + Vector3(0, 1.6, 0), Vector3.UP)
        _f = 100000
    if _f == 100010:
        root.get_texture().get_image().save_png("user://labels_mouth.png")
        print("SAVED labels")
        return true
    return _f > 60 * 200 and _f < 100000
