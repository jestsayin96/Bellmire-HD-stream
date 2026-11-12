extends SceneTree
## D5 renders: hens in their run, a cat on the street, the sheepdog with its
## flock, the paddock's horses and foal, crows over a field, a farm from above.
## Windowed. -> renders/cycles/20261111_d5/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261111_d5/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    # never under the hill: keep the eye above the ground it stands over
    from.y = maxf(from.y, float(_t.call("height_at", from.x, from.z)) + 1.2)
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

func _first(kind: String, nth := 0) -> Animal:
    var n := 0
    for a in _t.get("animals"):
        if (a as Animal).kind == kind:
            if n == nth:
                return a
            n += 1
    return null

func _near(a: Animal, dist: float, up: float, ang: float, look_up := 0.3) -> void:
    if a == null:
        return
    var p := a.global_position
    _eye(p + Vector3(0, look_up, 0), p + Vector3(cos(ang) * dist, up, sin(ang) * dist))

func _plan() -> void:
    _steps.append([func() -> void: _near(_first("Hen", 2), 2.6, 1.3, 0.6), "hens_close", 60])
    _steps.append([func() -> void:
        var h := _first("Hen", 0)
        if h:
            _eye(h.global_position, h.global_position + Vector3(-5.0, 6.0, -4.0)), "hen_run", 20])
    _steps.append([func() -> void: _near(_first("Cat", 0), 1.8, 0.9, 1.2, 0.2), "cat_close", 60])
    _steps.append([func() -> void: _near(_first("Cat", 3), 2.2, 1.0, 2.4, 0.2), "cat_street", 30])
    _steps.append([func() -> void:
        for a in _t.get("animals"):
            if (a as Animal).edge:
                _eye(a.global_position, a.global_position + Vector3(-9.0, 7.0, -8.0))
                return, "sheepdog_flock", 30])
    _steps.append([func() -> void:
        var f := _first("Foal")
        if f:
            _eye(f.global_position + Vector3(0, 0.6, 0), f.global_position + Vector3(6.0, 3.0, 5.0)), "paddock_foal", 30])
    _steps.append([func() -> void:
        var f := _first("Foal")
        if f:
            _eye(f.centre, f.centre + Vector3(18.0, 14.0, 16.0)), "paddock", 20])
    _steps.append([func() -> void:
        var fl: Array = _t.get("_fields")
        var c: Vector3 = fl[0][0]
        var g: float = _t.call("height_at", c.x, c.z)
        _eye(Vector3(c.x, g + 12.0, c.z), Vector3(c.x + 30.0, g + 6.0, c.z + 30.0)), "crows_field", 30])
    _steps.append([func() -> void:
        var ff: Array = _t.get("_farm_frames")
        var hp: Vector3 = ff[0][0]
        hp.y = _t.call("height_at", hp.x, hp.z)
        _eye(hp, hp + Vector3(28.0, 36.0, 28.0)), "farm_above", 20])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.get("raids").set("_raid_t", 99999.0)
        _plan()
    if _f > 15:
        (_t.get("economy") as Economy).clock = 12.5 / 24.0
    if _f < 200:
        return false
    if _steps.is_empty():
        print("D5_SHOTS DONE")
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
