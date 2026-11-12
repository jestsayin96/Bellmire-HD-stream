extends SceneTree
## D6b renders: the square right after start (just after the navmesh's first
## sync) and a few seconds later - nobody stacked on one spot, the watch on its
## beat. Windowed. -> renders/cycles/20261112_d6b/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261112_d6b/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 60.0
        _t.get("raids").set("_raid_t", 99999.0)
        (_t.get("economy") as Economy).clock = 10.0 / 24.0
        var mp: Vector3 = _t.get("_market_pos")
        _cam.global_position = mp + Vector3(-22, 18, 22)
        _cam.look_at(mp + Vector3(0, 0, 0), Vector3.UP)
    if _f == 60:
        root.get_texture().get_image().save_png(_dir + "square_f60.png")
        print("SAVED square_f60 synced=", _t.get("nav").synced())
    if _f == 400:
        root.get_texture().get_image().save_png(_dir + "square_f400.png")
        var mp: Vector3 = _t.get("_market_pos")
        _cam.global_position = mp + Vector3(30, 14, -10)
        _cam.look_at(mp + Vector3(0, 0, 8), Vector3.UP)
        print("SAVED square_f400")
    if _f == 460:
        root.get_texture().get_image().save_png(_dir + "square_f460_east.png")
        print("D6B_SHOTS DONE")
        return true
    return false
