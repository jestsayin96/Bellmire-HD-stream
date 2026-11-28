extends SceneTree
## S166: a solo delver below on its own negative lane while the open party is on lane 0. Saves renders/s166/solo_*.png.
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 120:
        _t.get("raids").set("_raid_t", 99999.0)
        _t.call("chat_line", "s1", "Lonewolf", "!enlist knight")
        _t.call("chat_line", "s2", "Crowd", "!enlist mage")
        print("SOLO_SHOT solo=", _t.call("_on_solo", "s1"))
        _t.call("_solo_enter", "s1")
        _t.call("_on_delve", "s2")
        (_t.get("_at_mouth") as Array).append("s2")
        _t.call("_begin_delve")
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.fov = 60.0
    if _f == 600 or _f == 610:
        var d = (_t.get("solo_delves") as Dictionary).get("s1")
        var o = _t.get("delve")
        var which = d if _f == 600 else o
        var b: Node3D = which.party[0]["body"]
        _cam.make_current()
        _cam.global_position = b.global_position + Vector3(0, 9, 7)
        _cam.look_at(b.global_position, Vector3.UP)
    if _f == 605 or _f == 615:
        var tag := "solo_lane" if _f == 605 else "open_lane0"
        root.get_texture().get_image().save_png("res://renders/s166/%s.png" % tag)
        var d = (_t.get("solo_delves") as Dictionary).get("s1")
        print("SOLO_SHOT saved %s solo_lane=%d solo_floor=%d open_lane=%d" % [tag, d.lane, d.floor_no, _t.get("delve").lane])
    return _f > 620
