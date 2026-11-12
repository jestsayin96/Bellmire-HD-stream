extends SceneTree
## D16b render: the spots where walkers were pinned before the watchdog
## (Nessa by the ford-side street, Dunn east of the market), seen from above
## at 20 / 40 / 60 s of a town day. Windowed, --fixed-fps 60.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
const SPOTS := [Vector3(33.0, 0.0, -71.0), Vector3(72.8, 0.0, -63.2)]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d16b")
    DirAccess.make_dir_recursive_absolute(_out)
    _cam = Camera3D.new()
    _cam.fov = 50.0
    root.add_child(_cam)

func _aim(s: Vector3) -> void:
    var c := s + Vector3(0.0, 0.0, 0.0)
    c.y = float(_t.call("height_at", c.x, c.z))
    _cam.global_position = c + Vector3(-9.0, 15.0, 13.0)
    _cam.look_at(c, Vector3.UP)
    _cam.make_current()

func _process(_d: float) -> bool:
    _f += 1
    for k in [20, 40, 60]:
        for i in SPOTS.size():
            if _f == k * 60 - 2 + i * 0:
                _aim(SPOTS[i])
            if _f == k * 60 + i * 3 - 3:
                _aim(SPOTS[i])
            if _f == k * 60 + i * 3:
                root.get_texture().get_image().save_png(_out + "/spot%d_%02ds.png" % [i, k])
                print("SAVED spot%d_%02ds" % [i, k])
    if _f >= 60 * 60 + 10:
        var wd := 0
        for v in _t.get("people"):
            wd += v.wd_fires
        print("SHOT done watchdog_fires=", wd)
        return true
    return false
