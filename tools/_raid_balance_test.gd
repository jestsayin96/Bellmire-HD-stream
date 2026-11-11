extends SceneTree
## Raid balance test (cycle 55): real town, the RtsCamera. Three fresh viewer
## heroes (level 1) and one veteran (level 5) are in Bellmire when a raid
## boils out of the scar. Before the breach the green heroes hold the square
## (no target beyond arm's reach) while the veteran goes out; once raiders are
## inside the walls the green heroes fight too. The grace: a green hero's
## first fall is a knock-out (alive, graced), the second is death.
## Renders to renders/cycles/20261111_raidbal.
var _t: Node3D
var _eye: RtsCamera
var _rd: Raids
var _f := 0
var _fails: Array = []
var _green := ["2001", "2002", "2003"]
var _vet := "2004"
var _far_green := 0          # samples: a green hero chasing far before the breach
var _vet_out := false
var _green_fight_breach := false
var _held := 0               # samples: green heroes standing near the square before the breach
var _pre := 0
var _raid_f := -1
var _shot := 0
var _breach_f := -1
var _snap_at := -1
const OUT := "res://renders/cycles/20261111_raidbal"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _check(ok: bool, what: String) -> void:
    print("RAIDBAL_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _body(u: String) -> Node3D:
    var hs: Dictionary = _t.get("heroes")
    return hs.get(u) if hs.has(u) and is_instance_valid(hs[u]) else null

func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/" + nm + ".png"))

func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        for u in _green + [_vet]:
            _t.chat_line(u, "Viewer" + u, "!enlist knight")
        _rd = _t.get("raids")
        _rd.force_level = 3
        _rd.set("_raid_t", 99999.0)
    if _f == 40:
        var r: Roster = _t.get("roster")
        r.get_hero(_vet)["level"] = 5
        for u in _green + [_vet]:
            print("HERO ", u, " body=", _body(u) != null, " lvl=", r.get_hero(u).get("level"))
        _check(_body(_green[0]) != null and _body(_vet) != null, "heroes have bodies in town")
        seed(11)
        _rd.raid("scar")
        _raid_f = _f
        Engine.time_scale = 3.0
    if _raid_f > 0 and _f > _raid_f + 5 and _f % 10 == 0 and not _rd.raiders.is_empty():
        var centre: Vector3 = _t.get("_market_pos")
        for u in _green:
            var b := _body(u)
            if b == null or not _rd._fighters.has(b):
                continue
            var st: Dictionary = _rd._fighters[b]
            var tg = st["target"]
            if not _rd.breached:
                _pre += 1
                if tg != null and _rd._flat((tg["node"] as Node3D).global_position, b.global_position) > Raids.HOLD_REACH * 1.5 + 0.5:
                    _far_green += 1
                if _rd._flat(b.global_position, centre) < 12.0:
                    _held += 1
            elif tg != null:
                _green_fight_breach = true
        var vb := _body(_vet)
        if vb and _rd._fighters.has(vb) and _rd._fighters[vb]["target"] != null:
            _vet_out = true
        if _shot == 0 and _held > 30 and not _rd.breached:
            _eye.selected = _body(_green[0])
            _shot = 1
        elif _shot == 1:
            _shot = 2
        elif _shot == 2:
            _snap("hold_square")
            _shot = 3
    if _raid_f > 0 and (_rd.raiders.is_empty() or _f > _raid_f + 60 * 160) and _f > _raid_f + 30:
        Engine.time_scale = 1.0
        _check(_pre > 0, "green heroes sampled before the breach (%d)" % _pre)
        _check(_far_green == 0, "green heroes never chase far before the breach (%d)" % _far_green)
        _check(_held > 0, "green heroes hold the market square (%d samples)" % _held)
        _check(_vet_out, "the veteran goes out to fight")
        # phase 2: a raid that is already inside the walls
        _raid_f = -999
        _rd.raid("scar")
        var centre2: Vector3 = _t.get("_market_pos")
        var k := 0
        for rr in _rd.raiders:
            var q: Vector3 = centre2 + Vector3(sin(k * 1.7), 0, cos(k * 1.7)) * 16.0
            q.y = float(_t.call("height_at", q.x, q.z))
            (rr["node"] as Node3D).global_position = q
            k += 1
        _breach_f = _f
        Engine.time_scale = 2.0
        return false
    if _breach_f > 0:
        if _f % 10 == 0:
            for u in _green:
                var b2 := _body(u)
                if b2 and _rd._fighters.has(b2) and _rd.breached and _rd._fighters[b2]["target"] != null:
                    if not _green_fight_breach:
                        _eye.selected = b2
                        _snap_at = _f + 40
                    _green_fight_breach = true
        if _f == _snap_at:
            _snap("breach_fight")
        if _rd.raiders.is_empty() or _f > _breach_f + 60 * 120:
            Engine.time_scale = 1.0
            _check(_green_fight_breach, "green heroes fight once the town is breached")
            _breach_f = -1
            _grace()
        return false
    if _f > 60 * 300:
        _check(false, "timed out")
        print("RAIDBAL_TEST FAIL")
        return true
    return false

func _grace() -> void:
    var r: Roster = _t.get("roster")
    # pick a green hero still standing
    var u := ""
    for g in _green:
        if r.is_alive(g) and _body(g) != null and not bool(r.get_hero(g).get("graced", false)):
            u = g
            break
    if u == "":
        for g in _green:
            if r.is_alive(g) and _body(g) != null:
                u = g
    _check(u != "", "a green hero left to test the grace")
    if u == "":
        print("RAIDBAL_TEST FAIL")
        return
    var b := _body(u)
    r.get_hero(u)["graced"] = false
    var st := {"hp": 0.0, "max": 10.0, "saved": true, "target": null, "post": b.global_position, "yaw": 0.0, "stay": true, "green": true}
    _rd._fighters[b] = st
    _rd._defender_falls(b, st, "a test blade")
    _check(r.is_alive(u) and bool(st.get("ko", false)) and bool(r.get_hero(u).get("graced", false)), "first fall of a fresh hero is a knock-out (alive=%s)" % r.is_alive(u))
    _eye.selected = b
    for i in 3:
        await process_frame
    _snap("knocked_out")
    st.erase("ko")
    st["saved"] = true
    _rd._defender_falls(b, st, "a test blade")
    _check(not r.is_alive(u), "the second fall is death")
    var v := _body(_vet)
    var vst := {"hp": 0.0, "max": 10.0, "saved": true, "target": null, "post": Vector3.ZERO, "yaw": 0.0, "stay": true}
    if v:
        _rd._fighters[v] = vst
        _rd._defender_falls(v, vst, "a test blade")
        _check(not r.is_alive(_vet), "a level 5 hero gets no grace")
    print("RAIDBAL_TEST %s" % ("OK" if _fails.is_empty() else "FAIL " + str(_fails)))
    quit()
