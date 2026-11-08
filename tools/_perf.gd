extends SceneTree
var _t: Node3D
var _f := 0
var _t0 := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 30:
        _t0 = Time.get_ticks_usec()
        var roles := {}
        for v in _t.get("people"):
            roles[v.role] = int(roles.get(v.role, 0)) + 1
        print("PEOPLE ", _t.get("people").size(), " ", roles)
    if _f == 330:
        var ms := float(Time.get_ticks_usec() - _t0) / 300.0 / 1000.0
        var walking := 0
        var inside := 0
        for v in _t.get("people"):
            if v.inside:
                inside += 1
            elif not v._route.is_empty() or v.leader != null:
                walking += 1
        print("PERF avg_frame_ms=", snappedf(ms, 0.01), " fps~", snappedf(1000.0 / ms, 0.1), " walking=", walking, " inside=", inside)
        return true
    return false
