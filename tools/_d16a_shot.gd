extends SceneTree
## D16a render: the 50-body funnel at the west gate (see _d16a_test.gd) from
## above, as the two streams meet and pass.
const N := 50
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _walkers: Array = []
var _goal: Dictionary = {}
var _gate := Vector3.ZERO
var _out := ""
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d16a")
    DirAccess.make_dir_recursive_absolute(_out)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(_out + "/" + nm + ".png")
    print("SAVED ", nm)
func _spawn() -> void:
    _gate = _t.call("_gate", -1.0)
    var out := Vector3(_gate.x, 0.0, _gate.z).normalized()
    var lat := Vector3(-out.z, 0.0, out.x)
    var nav = _t.get("nav")
    for i in range(N):
        var side := 1.0 if i < N / 2 else -1.0
        var k := i % (N / 2)
        var row := k / 5
        var col := k % 5
        var a := _gate + out * side * (10.0 + row * 1.1) + lat * (col - 2) * 1.1
        var b := _gate - out * side * (12.0 + row * 1.2) + lat * (col - 2) * 1.2
        if nav:
            a = nav.closest(a)
            b = nav.closest(b)
        a = _t.call("keep_walkable", a)
        b = _t.call("keep_walkable", b)
        var v := Townsfolk.new()
        v.role = "peasant"
        v.person_name = "Funnel %d" % i
        v.town = _t
        v.home = b
        v.work = b
        v.position = a
        _t.add_child(v)
        (_t.get("people") as Array).append(v)
        v._wait = 9999.0
        _walkers.append(v)
        _goal[v] = b
    print("D16A spawned ", _walkers.size(), " at gate ", _gate)

## routes once the navmesh answers (a path asked for on the spawn frame can
## come back empty and fall back to the old road-hex route)
func _go() -> void:
    var sizes := []
    for v in _walkers:
        v._route = _t.call("route", (v as Node3D).global_position, _goal[v])
        sizes.append(v._route.size())
    print("D16A routes ", sizes)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _spawn()
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 50.0
        var o := Vector3(_gate.x, 0, _gate.z).normalized()
        var lat := Vector3(-o.z, 0, o.x)
        _cam.global_position = _gate - o * 20.0 + lat * 3.0 + Vector3(0, 26, 0)
        _cam.look_at(_gate + Vector3(0, 0.5, 0), Vector3.UP)
    if _f == 120:
        _go()
    for k in [3, 4, 5, 6, 8]:
        if _f == 120 + k * 60:
            _snap("funnel_%02ds" % k)
    return _f >= 120 + 8 * 60
