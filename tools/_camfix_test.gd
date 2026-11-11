extends SceneTree
## Camera fixes test (cycle 56): real town + RtsCamera.
## 1. Follow a townsfolk among the houses with a low camera, orbiting: count
##    frames the camera sits inside a house, pull-in off (baseline) then on (0).
## 2. Night: the soft fill light is on the followed one; by day it fades out.
## 3. Tight party: four bars over one spot stand one above the next.
## 4. A delve: follow a delver, orbit low; camera inside a dungeon wall,
##    pull-in off (baseline) then on (0). Frames to renders/cycles/20261111_camfix.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _off_hits := 0
var _on_hits := 0
var _on_n := 0
var _dun_f := -1
var _doff := 0
var _don := 0
var _don_n := 0
var _dummies: Array = []
const OUT := "res://renders/cycles/20261111_camfix"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _check(ok: bool, what: String) -> void:
    _checks += 1
    print("CAMFIX_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _shot(n: String) -> void:
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/" + n + ".png"))

func _busiest() -> Node3D:
    var best: Node3D = null
    var bn := -1
    var rects := _eye._house_rects()
    for v in _t.get("people"):
        if v.inside or not v.visible or v is HeroBody:
            continue
        var p: Vector3 = v.global_position
        var n := 0
        for r in rects:
            if Vector2(p.x, p.z).distance_to(r[0]) < 14.0:
                n += 1
        if n > bn:
            bn = n
            best = v
    print("CAMFIX_TEST follow a townsfolk with %d houses within 14 m" % bn)
    return best

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        (_t.get("economy")).clock = 0.5
    if _f == 25:
        _eye._select(_busiest())
        _eye._following = true
        _eye.dist = 22.0
        _eye.pitch = deg_to_rad(-16.0)
        _eye.pull_in = false
    if _f >= 25 and _f < 640:
        _eye.yaw += 0.021
        if _f == 330:
            _eye.pull_in = true
        if _f > 32 and _eye.selected != null:
            if _f < 330:
                _off_hits += 1 if _eye.camera_solid() else 0
            elif _f > 334:
                _on_n += 1
                if _eye.camera_solid():
                    _on_hits += 1
                    if _on_hits <= 5:
                        var piv := _eye.focus + Vector3(0, 1, 0)
                        var keep := _eye._near
                        _eye._near = _eye._house_rects()
                        print("CAMFIX_TEST hit: pivot solid=%s cam=%s focus=%s pull_d=%.1f dist=%.1f" % [_eye._solid_at(piv), _eye.cam.global_position, _eye.focus, _eye._pull_d, _eye.dist])
                        _eye._near = keep
        if _f == 500:
            _shot("town_follow_low")
    if _f == 640:
        print("CAMFIX_TEST town: camera in a house %d frames with pull-in off, %d of %d with it on" % [_off_hits, _on_hits, _on_n])
        _check(_on_hits == 0, "town follow camera never inside a house (%d)" % _on_hits)
        (_t.get("economy")).clock = 0.92
        _eye.pitch = deg_to_rad(-30.0)
    if _f == 760:
        _check(_eye.fill != null and _eye.fill.visible and _eye.fill.light_energy > 0.5, "night: fill light on the followed one (%.2f)" % (_eye.fill.light_energy if _eye.fill else -1.0))
        _shot("night_follow")
        (_t.get("economy")).clock = 0.5
    if _f == 900:
        _check(_eye.fill == null or not _eye.fill.visible, "day: fill light faded out")
        # tight party bars
        var at: Vector3 = _t.get("_market_pos")
        for i in 4:
            var n := Node3D.new()
            _t.add_child(n)
            n.global_position = at + Vector3(0.15 * i, 0.0, 0.1 * i)
            _dummies.append(n)
        for pass_i in 2:
            for n in _dummies:
                var hb := HealthBar3D.on(n, 2.05, false)
                hb._stack_t = 0.0
                hb.set_hp(6.0, 10.0, true)
        var ys: Array = []
        for n in _dummies:
            ys.append(snappedf((n.get_node("hpbar") as Node3D).position.y, 0.01))
        var uniq := {}
        for y in ys:
            uniq[y] = true
        _check(uniq.size() == 4, "tight party: four bars at four heights %s" % str(ys))
        var far := Node3D.new()
        _t.add_child(far)
        far.global_position = at + Vector3(6, 0, 0)
        var fb := HealthBar3D.on(far, 2.05, false)
        fb.set_hp(6.0, 10.0, true)
        _check(is_equal_approx(fb.position.y, 2.05), "a lone bar is not lifted (%.2f)" % fb.position.y)
        _eye._following = false
        _eye.focus = at
        _eye.dist = 9.0
        _eye.pitch = deg_to_rad(-12.0)
        _eye.yaw = deg_to_rad(90.0)
    if _f == 910:
        _shot("tight_bars")
        for n in _dummies:
            n.queue_free()
        var r: Roster = _t.get("roster")
        var ids := []
        for v in [["3001", "CamKnight", "knight"], ["3002", "CamMage", "mage"], ["3003", "CamCleric", "cleric"], ["3004", "CamRogue", "rogue"]]:
            var h: Dictionary = r.get_hero(v[0])
            if h.is_empty():
                h = r.fresh(v[0], v[1], v[2])
            h["alive"] = true
            h["oil"] = 4
            ids.append(v[0])
        _d = Delve.new()
        _d.town = _t
        _d.roster = r
        _d.max_floors = 2
        _t.add_child(_d)
        _d.start(ids)
    if _f > 910 and _dun_f < 0 and _d.dun != null and not _d.party.is_empty() and is_instance_valid(_d.party[0]["body"]) \
            and (_d.party[0]["body"] as Node3D).global_position.y < Delve.DELVE_Y * 0.5:
        _dun_f = _f
        _eye._select(_d.party[0]["body"])
        _eye._following = true
        _eye.dist = 18.0
        _eye.pitch = deg_to_rad(-12.0)
        _eye.pull_in = false
    if _dun_f > 0:
        var k := _f - _dun_f
        _eye.yaw += 0.018
        if k == 300:
            _eye.pull_in = true
        if k > 6 and k < 300:
            _doff += 1 if _eye.camera_solid() else 0
        elif k > 304 and k < 660:
            _don_n += 1
            _don += 1 if _eye.camera_solid() else 0
        if k == 200:
            _shot("dungeon_pull_off")
        if k == 480:
            for m in _d.party:
                if is_instance_valid(m["body"]):
                    var hb := HealthBar3D.on(m["body"], 2.05, false)
                    hb._stack_t = 0.0
                    hb.set_hp(float(m["max"]) * 0.6, float(m["max"]), true)
        if k == 482:
            _shot("dungeon_pull_on")
        if k == 660:
            print("CAMFIX_TEST dungeon: camera in a wall %d frames with pull-in off, %d of %d with it on" % [_doff, _don, _don_n])
            _check(_don == 0, "dungeon follow camera never inside a wall (%d)" % _don)
    if (_dun_f > 0 and _f - _dun_f > 662) or _f > 5000:
        if _dun_f < 0:
            _fails.append("no delve body to follow")
        print("CAMFIX_TEST %d checks, %d failed" % [_checks, _fails.size()])
        print("CAMFIX_TEST %s" % ("OK" if _fails.is_empty() else "FAIL " + str(_fails)))
        return true
    return false
