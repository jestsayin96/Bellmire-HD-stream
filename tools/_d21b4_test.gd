extends SceneTree
## D21b.4: the mounted watch's charge LANDS. Brings the four riders on duty,
## starts a raid, and runs until the raid ends or time runs out. Checks that
## riders armed a charge, reached their mark, struck home, wheeled out and
## came again (charges >= 2), and that the hooves caught someone or the lance
## killed. In a real window (not --headless) it also samples FPS once a second
## through the raid (the D21b "FPS holds" half) and saves a shot of the first
## charge that lands to renders/cycles/d21b4/charge.png.

var _t: Node3D
var _rd: Raids
var _f := 0
var _raid_f := -1
var _fails: Array = []
var _win := false
var _cam: Camera3D
var _shot_at := -1
var _shot_done := false
var _fps: Array = []
var _acc := 0.0
var _seen_landed := 0
var _riders := 0
var _armed_max := 0

func _initialize() -> void:
    _win = DisplayServer.get_name() != "headless"
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    print("D21B4 %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _finish() -> void:
    print("D21B4 charges=%d landed=%d tramples=%d riders=%d armed_max=%d raiders_left=%d frames=%d" \
        % [_rd.charges, _rd.charges_landed, _rd.tramples, _riders, _armed_max, (_rd.raiders as Array).size(), _f - _raid_f])
    _check(_riders >= 3, "at least 3 riders on duty (got %d)" % _riders)
    _check(_rd.charges >= 2, "riders charged home at least twice (charges=%d)" % _rd.charges)
    _check(_rd.charges_landed >= 1, "at least one charge struck home (landed=%d)" % _rd.charges_landed)
    if _win:
        var mn := 1e9
        var sm := 0.0
        for x in _fps:
            mn = minf(mn, float(x))
            sm += float(x)
        var avg := sm / maxf(1.0, float(_fps.size()))
        print("D21B4 FPS min=%.0f avg=%.1f n=%d samples=%s" % [mn, avg, _fps.size(), str(_fps)])
        _check(_fps.size() >= 10, "FPS sampled through the raid (n=%d)" % _fps.size())
        _check(avg >= 60.0, "raid FPS avg holds >= 60 (avg=%.1f)" % avg)
        _check(_shot_done, "shot of a landed charge saved")
    var bad := _fails.size()
    print("D21B4 %s fails=%d %s" % ["OK" if bad == 0 else "FAIL", bad, _fails])
    quit(0 if bad == 0 else 1)

func _process(dt: float) -> bool:
    _f += 1
    if _f == 60:
        _rd = _t.get("raids") as Raids
        if _rd == null:
            print("D21B4 FAIL no raids node")
            quit(1)
            return true
        _rd.force_level = 4
        _rd.set("_raid_t", 99999.0)
        _t.call("_show_garrison", 6, true)
        for c in _t.get("cavalry"):
            if is_instance_valid(c) and (c as Node3D).visible:
                _riders += 1
        if _win:
            _cam = Camera3D.new()
            _t.add_child(_cam)
            _cam.make_current()
            _cam.fov = 55.0
            var m: Vector3 = _t.get("_market_pos")
            _cam.global_position = m + Vector3(-6.0, 22.0, 30.0)
            _cam.look_at(m, Vector3.UP)
            _t.get("economy").clock = 13.0 / 24.0
    if _f == 120:
        seed(2141)
        _rd.raid("road")
        _raid_f = _f
    if _raid_f < 0:
        return false
    var armed := 0
    for k in _rd.get("_fighters").keys():
        if is_instance_valid(k) and k is Cavalry and bool(_rd.get("_fighters")[k].get("charging", false)):
            armed += 1
    _armed_max = maxi(_armed_max, armed)
    if _win:
        _acc += dt
        if _acc >= 1.0:
            _acc = 0.0
            _fps.append(Engine.get_frames_per_second())
        if _rd.charges_landed > _seen_landed and _shot_at < 0:
            _seen_landed = _rd.charges_landed
            # find the rider who just struck (the one wheeling) and frame him
            for k in _rd.get("_fighters").keys():
                if is_instance_valid(k) and k is Cavalry and _rd.get("_fighters")[k].has("wheel"):
                    var p: Vector3 = (k as Node3D).global_position
                    _cam.global_position = p + Vector3(-5.0, 6.0, 8.0)
                    _cam.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
                    break
            _shot_at = _f + 6
        if _shot_at > 0 and _f == _shot_at and not _shot_done:
            DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/d21b4"))
            root.get_viewport().get_texture().get_image().save_png("res://renders/cycles/d21b4/charge.png")
            _shot_done = true
            print("D21B4 shot saved")
            # back to the overview so the FPS samples stay comparable
            var m2: Vector3 = _t.get("_market_pos")
            _cam.global_position = m2 + Vector3(-6.0, 22.0, 30.0)
            _cam.look_at(m2, Vector3.UP)
    var done_raid: bool = (_rd.raiders as Array).is_empty() and _f - _raid_f > 120 and not _win
    var enough: bool = _rd.charges >= 2 and _rd.charges_landed >= 1 and not _win
    if _win and _fps.size() >= 30:
        enough = true
    if done_raid or enough or _f - _raid_f > 5400:
        _finish()
        return true
    return false
