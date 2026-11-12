extends SceneTree
## D16d render: a two-way crowd sent through the west gate or across the bridge
## on the spawn frame (as the town's folk are at the start of a stream), seen
## from above. -- --site gate|bridge [--old] -> renders/cycles/20261112_d16d.
## Run windowed with --fixed-fps 60.
const N := 60
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _walkers: Array = []
var _goal: Dictionary = {}
var _c := Vector3.ZERO
var _o := Vector3.ZERO
var _site := "gate"
var _tag := "new"
var _out := ""

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    for i in range(args.size()):
        if args[i] == "--site" and i + 1 < args.size():
            _site = args[i + 1]
        elif args[i] == "--old":
            Townsfolk.funnel_fix = false
            _tag = "old"
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d16d")
    DirAccess.make_dir_recursive_absolute(_out)

func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(_out + "/" + nm + ".png")
    print("SAVED ", nm)

func _spawn() -> void:
    var reach := 12.0
    if _site == "bridge":
        var k: Dictionary = _t.get_script().get_script_constant_map()
        var half := float(k.get("RIVER_W", 8.0)) + float(k.get("RIVER_BANK", 3.0)) + 1.5
        _c = Vector3(0.0, 0.0, float(_t.get("_bridge_z")))
        _o = Vector3(0, 0, 1)
        reach = half + 6.0
    else:
        _c = _t.call("_gate", -1.0)
        _o = Vector3(_c.x, 0.0, _c.z).normalized()
    var lat := Vector3(-_o.z, 0.0, _o.x)
    var nav = _t.get("nav")
    var per := N / 2
    var cols := 5 if _site == "gate" else 4
    for i in range(N):
        var side := 1.0 if i < per else -1.0
        var k := i % per
        var row := k / cols
        var lo := (k % cols - (cols - 1) * 0.5) * 1.1
        var a := _c + _o * side * (reach + row * 1.1) + lat * lo
        var b := _c - _o * side * (reach + 4.0 + row * 1.2) + lat * lo
        if nav:
            a = nav.closest(a)
            b = nav.closest(b)
        var v := Townsfolk.new()
        v.role = "peasant"
        v.person_name = "Funnel %d" % i
        v.town = _t
        v.home = b
        v.work = b
        v.position = _t.call("keep_walkable", a)
        _t.add_child(v)
        (_t.get("people") as Array).append(v)
        v._wait = 9999.0
        _walkers.append(v)
        _goal[v] = _t.call("keep_walkable", b)
    for v in _walkers:
        v._route = _t.call("route", (v as Node3D).global_position, _goal[v])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _spawn()
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        var lat := Vector3(-_o.z, 0, _o.x)
        if _site == "bridge":
            _cam.global_position = _c + lat * 22.0 + Vector3(0, 24, 0)
        else:
            _cam.global_position = _c - _o * 20.0 + lat * 3.0 + Vector3(0, 26, 0)
        _cam.look_at(_c + Vector3(0, 0.5, 0), Vector3.UP)
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    for k in [6, 9, 10, 11, 12, 13, 14, 16, 20, 26]:
        if _f == 60 + k * 60:
            _snap("%s_%s_%02ds" % [_site, _tag, k])
    return _f >= 60 + 26 * 60
