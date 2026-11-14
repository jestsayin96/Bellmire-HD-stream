extends SceneTree
## D37: close-up of E3PO at his post with a line shouted above him.
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _kill_other_cams() -> void:
    var st: Array = [root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Camera3D and c != _cam:
            (c as Camera3D).current = false
        for g in c.get_children():
            st.append(g)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 90:
        _cam = Camera3D.new(); _cam.fov = 40.0
        _t.add_child(_cam)
    if _f < 130:
        return false
    var nb = _t.get("notables")
    var e = nb.by_key("e3po") if nb else null
    if e == null:
        print("NO E3PO"); return true
    # force a recognizable shout to show the bubble
    e.shout_lines = ["Hold the wall. Bellmire does not break."]
    var b: Vector3 = e.global_position
    _cam.global_position = b + Vector3(3.0, 1.4, 3.0)
    _cam.look_at(b + Vector3(0, 1.35, 0), Vector3.UP)
    _kill_other_cams()
    _cam.make_current()
    if _f < 170:          # let the shout bubble appear
        return false
    root.get_texture().get_image().save_png("user://d37_e3po.png")
    print("SAVED e3po pos=", b, " title=", e.notable_title)
    return true
