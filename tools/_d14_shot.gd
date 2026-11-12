extends SceneTree
## D14 renders: the adventurers' yard (fence + benches + stools) and the stall
## corner by the market where walkers used to stand pinned all stream. Shots at
## 40 s and 80 s - the yard should not keep anyone pressed on the fence.
## Windowed. -> renders/cycles/20261112_d14/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261112_d14/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _aim(at: Vector3, off: Vector3) -> void:
    at.y = _t.height_at(at.x, at.z)
    _cam.global_position = at + off
    _cam.look_at(at, Vector3.UP)

func _near(c: Vector3, r: float) -> int:
    var n := 0
    for v in _t.get("people"):
        if is_instance_valid(v) and v.visible and not v.inside and Vector2(v.global_position.x - c.x, v.global_position.z - c.z).length() < r:
            n += 1
    return n

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.get("raids").set("_raid_t", 99999.0)
        (_t.get("economy") as Economy).clock = 11.0 / 24.0
    var yard := Vector3(87.5, 0, 38.0)
    var stall := Vector3(76.0, 0, -63.0)
    if _f == 2380:
        _aim(yard, Vector3(-9, 11, -10))
    if _f == 2400:
        root.get_texture().get_image().save_png(_dir + "yard_40s.png")
        print("SAVED yard_40s near=", _near(yard, 6.0))
        _aim(stall, Vector3(9, 10, 9))
    if _f == 2420:
        root.get_texture().get_image().save_png(_dir + "stall_40s.png")
        print("SAVED stall_40s near=", _near(stall, 5.0))
    if _f == 4780:
        _aim(yard, Vector3(-9, 11, -10))
    if _f == 4800:
        root.get_texture().get_image().save_png(_dir + "yard_80s.png")
        print("SAVED yard_80s near=", _near(yard, 6.0))
        _aim(stall, Vector3(9, 10, 9))
    if _f == 4820:
        root.get_texture().get_image().save_png(_dir + "stall_80s.png")
        print("SAVED stall_80s near=", _near(stall, 5.0))
        print("D14_SHOTS DONE")
        return true
    return false
