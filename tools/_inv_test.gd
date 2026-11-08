extends SceneTree
var _t: Node3D
var _f := 0
var _ms := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        print("CHAT -> ", _t.call("chat_line", "local_mre", "MrE", "!enlist ranger"))
        _t.call("go_fish", "MrE")
        _t.call("go_fish", "MrE")
        _t.call("go_fish", "MrE")
        _ms = Time.get_ticks_msec()
    if _f > 5 and _ms > 0 and Time.get_ticks_msec() - _ms > 1700:
        print("CHAT -> ", _t.call("chat_line", "local_mre", "MrE", "!inventory"))
        return true
    return false
