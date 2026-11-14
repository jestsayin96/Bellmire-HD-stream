extends SceneTree
## D20c LOOK: the horse herd grazing/drifting in the paddock (with its sheepdog),
## a town dog trailing a townsperson, and a bird flock wheeling overhead.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261113_d20c/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    from.y = maxf(from.y, float(_t.call("height_at", from.x, from.z)) + 1.2)
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

func _follow_dog() -> Animal:
    for a in _t.get("animals"):
        if (a as Animal).follow:
            return a
    return null

func _plan() -> void:
    _steps.append([func() -> void:
        var pad: Array = _t.get("_paddock")
        var c: Vector3 = pad[0]
        _eye(c, c + Vector3(20.0, 17.0, 20.0)), "paddock_herd", 40])
    _steps.append([func() -> void:
        var d := _follow_dog()
        if d:
            var p := d.global_position
            _eye(p + Vector3(0, 0.6, 0), p + Vector3(4.5, 3.2, 4.5)), "dog_follow", 40])
    _steps.append([func() -> void:
        var fls: Array = _t.get("_flocks")
        var c: Vector3 = fls[0]["centre"]
        _eye(c, c + Vector3(float(fls[0]["r"]) + 25.0, -6.0, 10.0)), "flock_wheel", 30])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 58.0
        _t.get("raids").set("_raid_t", 99999.0)
        _plan()
    if _f > 15:
        (_t.get("economy") as Economy).clock = 12.5 / 24.0
    if _f < 240:
        return false
    if _steps.is_empty():
        print("D20C_SHOTS DONE")
        return true
    var s: Array = _steps[0]
    var wait: int = int(s[2])
    (s[0] as Callable).call()
    s[2] = wait - 1
    if wait > 0:
        return false
    root.get_texture().get_image().save_png(_dir + String(s[1]) + ".png")
    print("SAVED ", s[1])
    _steps.pop_front()
    return false
