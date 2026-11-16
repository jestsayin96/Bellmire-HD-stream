extends SceneTree
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
    if _f == 60:
        _cam = Camera3D.new(); _cam.fov = 42.0
        _t.add_child(_cam)
    if _f < 90:
        return false
    var anglers: Array = _t.get("anglers")
    if anglers.is_empty():
        print("NO ANGLERS"); return true
    var a = anglers[0]
    var hand: Vector3 = a._rod_mount.global_position
    var tip: Vector3 = a._rod_tip.global_position
    var b: Vector3 = a.get_parent().global_position
    var mid := (hand + tip) * 0.5
    mid.y = (b.y + maxf(hand.y, tip.y)) * 0.5   # center between feet and rod top
    _cam.global_position = Vector3(b.x + 4.2, b.y + 1.9, b.z + 3.0)
    _cam.look_at(Vector3(b.x, b.y + 1.5, b.z + 0.6), Vector3.UP)
    _kill_other_cams()
    _cam.make_current()
    if _f < 95:
        return false
    root.get_texture().get_image().save_png("user://d51_grip.png")
    print("SAVED state=", a.state, " hand=", hand, " tip=", tip, " body=", b)
    return true
