extends SceneTree
## S108 renders: System 11 UAA animals - Bull, Donkey, Alpaca in the paddock; Husky, Shiba
## on the square; Fox, Deer, Stag, Wolf at the woods edge. Prints S108_SHOTS OK|FAIL n/m.
## Windowed. -> renders/cycles/20261124_s108/
## S108b (06:1x): the committed file stopped at _near() - no _process, no quit, no verdict, so the
## window idled forever. That, not the desktop, was the 05:1x hang. Completed below.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261124_s108/")
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


const KINDS := ["Bull", "Donkey", "Alpaca", "Husky", "Shiba", "Fox", "Deer", "Stag", "Wolf"]
const REF := ["Horse", "Llama", "Pug", "Corgi"]
var _ok := 0
var _n := 0
var _lines: Array = []

func _aabb(n: Node) -> AABB:
    var out := AABB()
    var first := true
    for m in n.find_children("*", "MeshInstance3D", true, false):
        var mi := m as MeshInstance3D
        if not mi.is_visible_in_tree():
            continue
        var b := mi.global_transform * mi.get_aabb()
        if first:
            out = b
            first = false
        else:
            out = out.merge(b)
    return out

func _measure(kind: String) -> String:
    var a := _first(kind)
    if a == null:
        return "%s MISSING" % kind
    var b := _aabb(a)
    var g := float(_t.call("height_at", a.global_position.x, a.global_position.z))
    return "%s h=%.2f len=%.2f wid=%.2f foot_gap=%.2f" % [kind, b.size.y, maxf(b.size.x, b.size.z), minf(b.size.x, b.size.z), b.position.y - g]

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 2:
        _cam = Camera3D.new()
        _cam.fov = 50.0
        root.add_child(_cam)
        _cam.make_current()
    if _f == 150:
        for k in REF + KINDS:
            var m := _measure(k)
            _lines.append(m)
            print("S108_MEASURE ", m)
        for k in KINDS:
            _steps.append(k)
    if _f >= 150 and not _steps.is_empty():
        var k: String = _steps[0]
        var ph := (_f - 150) % 20
        if ph == 1:
            var a := _first(k)
            var d := 3.0 if k in ["Fox", "Shiba", "Husky"] else 5.5
            _near(a, d, 1.4, 0.7, 0.4)
        elif ph == 15:
            _n += 1
            var a := _first(k)
            if a != null:
                var img := root.get_texture().get_image()
                var fp := _dir + "%s.png" % k
                if img.save_png(fp) == OK:
                    _ok += 1
            _steps.pop_front()
    if _f > 150 and _steps.is_empty():
        print("S108_SHOTS %s %d/%d" % ["OK" if _ok == KINDS.size() else "FAIL", _ok, KINDS.size()])
        return true
    if _f > 900:
        print("S108_SHOTS FAIL timeout %d/%d" % [_ok, KINDS.size()])
        return true
    return false
