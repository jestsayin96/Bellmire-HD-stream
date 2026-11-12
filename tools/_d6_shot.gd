extends SceneTree
## D6 renders: Bellmire's named people at their day's places, name and title
## over their heads. Windowed. -> renders/cycles/20261111_d6/
var _t: Node3D
var _n: Notables
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""
var _hour := 11.0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261111_d6/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    from.y = maxf(from.y, float(_t.call("height_at", from.x, from.z)) + 1.2)
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

## stand them at their slot's first outdoor place (the walk there is the test's job)
func _place(k: String) -> Townsfolk:
    var w := _n.by_key(k)
    for c in _n.cast:
        if c["who"] == w:
            var g: Vector3 = (c["goals"] as Array)[0]
            w.global_position = Vector3(g.x, float(_t.call("height_at", g.x, g.z)), g.z)
    w.inside = false
    w.visible = true
    w._route = []
    w._wait = 999.0
    w._enter_at = Vector3.ZERO
    return w

func _look_at_folk(w: Townsfolk, dist: float, up: float, ang: float) -> void:
    var p := w.global_position + Vector3(0, 1.1, 0)
    # turn round the subject until nothing solid stands between the eye and them
    var best := ang
    for i in range(16):
        var a := ang + TAU * float(i) / 16.0
        var clear := true
        for k in range(1, 9):
            var q := p + Vector3(cos(a), 0, sin(a)) * dist * float(k) / 8.0
            if not (_t.call("solid_at", q, 0.4) as Array).is_empty():
                clear = false
                break
        if clear:
            best = a
            break
    _eye(p, p + Vector3(cos(best) * dist, up, sin(best) * dist))

func _shot(hour: float, who: Array, aim: String, dist: float, up: float, ang: float, nm: String) -> void:
    _steps.append([hour, who, aim, dist, up, ang, nm])

func _plan() -> void:
    _shot(11.0, ["crier", "bard", "tove", "dunn", "pedlar", "beggar"], "crier", 11.0, 4.0, 0.9, "square_named")
    _shot(11.0, ["crier"], "crier", 4.2, 0.6, 1.4, "crier_reads")
    _shot(11.0, ["bard"], "bard", 3.6, 0.5, 2.2, "bard_plays")
    _shot(12.0, ["pedlar"], "pedlar", 6.0, 2.2, 0.4, "pedlar_cart")
    _shot(15.0, ["chief"], "chief", 4.0, 0.7, 2.6, "chief_east_market")
    _shot(9.0, ["smith"], "smith", 4.0, 0.8, 0.8, "smith_at_smithy")
    _shot(12.0, ["priest", "healer"], "priest", 5.5, 1.2, 1.9, "priest_chapel_steps")
    _shot(13.0, ["healer"], "healer", 4.0, 0.8, 0.3, "healer_rounds")
    _shot(3.0, ["drunk", "innkeeper"], "drunk", 4.5, 1.0, 1.2, "drunk_at_night")

func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.get("raids").set("_raid_t", 99999.0)
        _n = _t.get("notables")
        _plan()
    if _f > 15:
        (_t.get("economy") as Economy).clock = _hour / 24.0
    if _f < 200:
        return false
    if _steps.is_empty():
        print("D6_SHOTS DONE")
        return true
    var s: Array = _steps[0]
    if s.size() == 7:
        _hour = float(s[0])
        s.append(0)
        return false
    var k: int = int(s[7]) + 1
    s[7] = k
    if k == 4:
        for key in s[1]:
            _place(String(key))
        if (s[1] as Array).has("crier"):
            _n.by_key("crier")._shout_t = 0.05
    if k >= 4:
        _look_at_folk(_n.by_key(String(s[2])), float(s[3]), float(s[4]), float(s[5]))
    if k < 70:
        return false
    root.get_texture().get_image().save_png(_dir + String(s[6]) + ".png")
    print("SAVED ", s[6])
    _steps.pop_front()
    return false
