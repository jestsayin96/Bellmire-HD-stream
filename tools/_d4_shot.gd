extends SceneTree
## D4 renders: the mounted watch on the road, the riders close up, the tower
## crossbowmen, a gate post and a raid with the riders in it. Windowed.
## -> renders/cycles/20261111_d4/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261111_d4/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

func _rider(i: int) -> Cavalry:
    var cav: Array = _t.get("cavalry")
    return cav[i % cav.size()]

func _behind(c: Node3D, back: float, up: float, side: float) -> void:
    var f := c.global_transform.basis.z
    var s := c.global_transform.basis.x
    _eye(c.global_position + Vector3(0, 1.5, 0), c.global_position - f * back + s * side + Vector3(0, up, 0))

func _plan() -> void:
    var towers: Array = _t.get("towers")
    var posts: Array = _t.call("_guard_posts")
    # riders: front three-quarter, side, from above with the street
    _steps.append([func() -> void: _behind(_rider(0), -6.5, 2.2, 3.5), "rider_front", 90])
    _steps.append([func() -> void: _behind(_rider(0), 0.0, 1.6, 7.0), "rider_side", 30])
    _steps.append([func() -> void: _behind(_rider(1), 14.0, 9.0, 6.0), "rider_road", 60])
    _steps.append([func() -> void:
        var c := _rider(2)
        _eye(c.global_position, c.global_position + Vector3(25.0, 32.0, 25.0)), "patrol_above", 60])
    if not towers.is_empty():
        var tv: Vector3 = towers[0]
        tv.y = _t.call("height_at", tv.x, tv.z) + 11.7
        _steps.append([func() -> void: _eye(tv, tv + Vector3(9.0, 3.0, 10.0)), "tower_archers", 20])
    if not posts.is_empty():
        var gp: Vector3 = posts[posts.size() - 1][0]
        gp.y = _t.call("height_at", gp.x, gp.z)
        _steps.append([func() -> void: _eye(gp + Vector3(0, 1.4, 0), gp + Vector3(7.0, 3.5, 7.0)), "gate_post", 20])
    # a raid: bandits on the west road, riders go to meet them
    _steps.append([func() -> void:
        var raids = _t.get("raids")
        raids.set("force_level", 5)
        raids.call("raid", "west")
        var rs: Array = raids.get("raiders")
        var at: Vector3 = (rs[0]["node"] as Node3D).global_position
        _eye(at, at + Vector3(20.0, 16.0, 20.0)), "raid_start", 30])
    _steps.append([func() -> void: _behind(_rider(0), 9.0, 5.0, 5.0), "raid_ride", 240])
    _steps.append([func() -> void: _behind(_rider(1), 7.0, 4.0, -5.0), "raid_fight", 200])
    _steps.append([func() -> void: _behind(_rider(0), 6.0, 3.0, 6.0), "raid_fight2", 120])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.get("raids").set("_raid_t", 99999.0)
        _t.call("show_level", 6, true)
        _plan()
    if _f > 15:
        (_t.get("economy") as Economy).clock = 12.5 / 24.0
    if _f < 300:
        return false   # let the riders leave the stables
    if _steps.is_empty():
        print("D4_SHOTS DONE")
        return true
    # [aim Callable, name, frames to wait]; raid_start aims once (it starts the raid),
    # the rest re-aim every frame so the camera rides with the riders
    var s: Array = _steps[0]
    var wait: int = int(s[2])
    if String(s[1]) != "raid_start" or s.size() == 3:
        if s.size() == 3:
            s.append(true)
        if String(s[1]) != "raid_start" or wait == int(s[2]):
            (s[0] as Callable).call()
    s[2] = wait - 1
    if wait > 0:
        return false
    root.get_texture().get_image().save_png(_dir + String(s[1]) + ".png")
    print("SAVED ", s[1])
    _steps.pop_front()
    return false
