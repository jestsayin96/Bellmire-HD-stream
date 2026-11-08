extends SceneTree
## A handful of town views for a quick look (aerial, low aerial, street, square).
var _f := 0
var _t: Node3D
var _cam: Camera3D
var _shots: Array = []
var _i := 0
var _t0 := 0
func _initialize() -> void:
    _t0 = Time.get_ticks_msec()
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    print("BUILD_MS ", Time.get_ticks_msec() - _t0)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 240:
        var m: Vector3 = _t.call("stats").get("market", Vector3.ZERO)
        _shots = [["aerial", Vector3(0, 250, 265), Vector3.ZERO, 50.0],
                  ["low_aerial", Vector3(-40, 70, 120), Vector3(10, 0, 20), 55.0],
                  ["street_low", Vector3(-60, 2.6, -6), Vector3(10, 2.0, -4), 66.0],
                  ["square", m + Vector3(17, 8.5, 17), m + Vector3(0, 1.5, 0), 62.0],
                  ["block", Vector3(30, 28, 40), Vector3(10, 0, -10), 58.0]]
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
    if _f >= 240 and (_f - 240) % 12 == 0:
        if _i > 0:
            root.get_texture().get_image().save_png("user://tq_%s.png" % _shots[_i - 1][0])
            print("SAVED ", _shots[_i - 1][0])
        if _i >= _shots.size():
            return true
        var s: Array = _shots[_i]
        _cam.fov = float(s[3])
        _cam.global_position = s[1]
        _cam.look_at(s[2], Vector3.UP)
        _i += 1
    return false
