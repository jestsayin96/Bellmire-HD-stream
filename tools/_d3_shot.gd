extends SceneTree
## D3 renders: Bellmire at levels 1, 3, 5 and 6 from the same eye, then each new
## building and one house close up. Windowed. -> renders/cycles/20261111_d3/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _dir = ProjectSettings.globalize_path("res://renders/cycles/20261111_d3/")
    DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
    _cam.global_position = from
    _cam.look_at(at, Vector3.UP)

func _plan() -> void:
    var g = _t.get("growth")
    var m: Vector3 = _t.get("_market_pos")
    var over := func() -> void: _eye(m + Vector3(0, 0, -10), m + Vector3(-55.0, 62.0, 70.0))
    for lv in [1, 3, 5, 6]:
        _steps.append([func() -> void:
            g.show_level(lv, true)
            over.call(), "overview_level%d" % lv])
    for key in ["market_hall", "stables", "guild", "bathhouse", "mage_tower"]:
        if not g.specials.has(key):
            continue
        var plot: Dictionary = g.specials[key]["plot"]
        var p: Vector3 = plot["pos"]
        p.y = _t.call("height_at", p.x, p.z)
        var f: Vector3 = _t.call("_fwd", plot)
        var side := Vector3(-f.z, 0.0, f.x)
        var up := 3.0 if key != "mage_tower" else 9.0
        var back := 20.0 if key != "mage_tower" else 34.0
        _steps.append([func() -> void:
            g.show_level(6, true)
            _eye(p + Vector3(0, up, 0), p + f * back + side * 7.0 + Vector3(0, up + 5.0, 0)), key])
    # one house: hamlet and seat of the valley
    var hp: Dictionary = g.houses[2]
    var q: Vector3 = hp["pos"]
    q.y = _t.call("height_at", q.x, q.z)
    var hf: Vector3 = _t.call("_fwd", hp)
    var hs := Vector3(-hf.z, 0.0, hf.x)
    for lv in [1, 3, 4, 6]:
        _steps.append([func() -> void:
            g.show_level(lv, true)
            _eye(q + Vector3(0, 3.5, 0), q + hf * 17.0 + hs * 9.0 + Vector3(0, 8.0, 0)), "house_level%d" % lv])
    # a staked lot
    for plot in g.houses:
        if int(plot["grow"]) == 6:
            var lp: Vector3 = plot["pos"]
            lp.y = _t.call("height_at", lp.x, lp.z)
            var lf: Vector3 = _t.call("_fwd", plot)
            _steps.append([func() -> void:
                g.show_level(1, true)
                _eye(lp, lp + lf * 14.0 + Vector3(4.0, 9.0, 0)), "lot"])
            break
    # the wall: palisade, then stone
    var gates: Array = _t.get("_wall_info").get("gates", [])
    if not gates.is_empty():
        var gp: Vector3 = gates[0]
        gp.y = _t.call("height_at", gp.x, gp.z)
        var out := Vector3(gp.x, 0, gp.z).normalized()
        for lv in [3, 4]:
            _steps.append([func() -> void:
                g.show_level(lv, true)
                _eye(gp + Vector3(0, 4.0, 0), gp + out * 30.0 + Vector3(12.0, 12.0, 0)), "wall_level%d" % lv])

func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 60.0
        _t.get("raids").set("_raid_t", 99999.0)
        _plan()
    if _f > 15:
        (_t.get("economy") as Economy).clock = 12.5 / 24.0
    if _f >= 20:
        var i := int((_f - 20) / 25)
        var k := (_f - 20) % 25
        if i >= _steps.size():
            print("D3_SHOTS DONE ", _steps.size())
            return true
        if k == 0:
            (_steps[i][0] as Callable).call()
        if k == 24:
            var nm: String = _steps[i][1]
            root.get_texture().get_image().save_png(_dir + nm + ".png")
            print("SAVED ", nm)
    return false
