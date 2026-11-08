extends SceneTree
var _t: Node3D
var _cam: Camera3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 25:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
    var m: Vector3 = _t.get("_market_pos")
    if _f == 200:
        _cam.fov = 58.0
        _cam.global_position = m + Vector3(-20, 13, 20)
        _cam.look_at(m + Vector3(0, 1, 0), Vector3.UP)
    if _f == 212:
        root.get_texture().get_image().save_png("user://folk_square.png")
        _cam.fov = 60.0
        _cam.global_position = m + Vector3(2.5, 2.6, 10.5)
        _cam.look_at(m + Vector3(0, 2.0, 4.2), Vector3.UP)
    if _f == 224:
        root.get_texture().get_image().save_png("user://folk_crier.png")
        # a watch pair, wherever they are now
        for v in _t.get("people"):
            if v.role == "watch" and v.leader == null and not v.inside:
                var p: Vector3 = v.global_position
                _cam.fov = 55.0
                _cam.global_position = p + Vector3(6, 3.5, 6)
                _cam.look_at(p + Vector3(0, 1, 0), Vector3.UP)
                break
    if _f == 236:
        root.get_texture().get_image().save_png("user://folk_watch.png")
        for v in _t.get("people"):
            if v.role == "carter":
                var p: Vector3 = v.global_position
                _cam.fov = 55.0
                _cam.global_position = p + Vector3(-6, 4, 6)
                _cam.look_at(p + Vector3(0, 1, 0), Vector3.UP)
                break
    if _f == 248:
        root.get_texture().get_image().save_png("user://folk_carter.png")
        _cam.fov = 64.0
        _cam.global_position = Vector3(-60, 3.2, -6)
        _cam.look_at(Vector3(10, 1.5, -4), Vector3.UP)
    if _f == 260:
        root.get_texture().get_image().save_png("user://folk_street.png")
        return true
    return false
