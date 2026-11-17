extends SceneTree
## D61.1 test: THE NUMBERS IN THE WORLD. A real town + RtsCamera, a party of four on floor 5 (a
## lord floor). Once the lord fights: (a) the ORGANIC fight has produced ordinary hits AND misses
## that say so (counted off every creature's results_shown); (b) two ordinary hits inside POOL_S
## POOL into one rising figure (5 + 5 -> "10", results_pooled moves, no second label); (c) a crit
## never pools and reads "CRIT"; (d) save / resist / vuln each produce their own label; (e) no
## creature ever holds more than LIVE_CAP numbers. Saves a 1080p frame of the burst to look at.
## Frame-counting gate: run WITHOUT --quit (it quits itself).
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _seen_at := -1
var _seen_ms := 0
var _burst_f := -1
var _tallied := false
var _synth := {}         # what the scripted burst itself added, taken off the organic tally
var _fails: Array = []
var _checks := 0
const OUT := "res://renders/cycles/d61a"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _check(ok: bool, what: String) -> void:
    _checks += 1
    print("D61_TEST %s %s" % ["pass" if ok else "FAIL", what])
    if not ok:
        _fails.append(what)

func _all_mons() -> Array:
    var out: Array = []
    if _d and _d.dun:
        for mon in _d.dun.monsters:
            if is_instance_valid(mon):
                out.append(mon)
        if _d.dun.lord and is_instance_valid(_d.dun.lord):
            out.append(_d.dun.lord)
    return out

func _tally() -> Dictionary:
    var t := {}
    for mon in _all_mons():
        var rs: Dictionary = (mon as Monster).results_shown
        for k in rs:
            t[k] = int(t.get(k, 0)) + int(rs[k])
    return t

func _labels(mon: Monster) -> Array:
    var out: Array = []
    for c in mon.get_children():
        if c is Label3D and not c.is_queued_for_deletion():
            out.append(c)
    return out

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        var r: Roster = _t.get("roster")
        var ids := []
        for v in [["6101", "D61Knight", "knight"], ["6102", "D61Mage", "mage"], ["6103", "D61Paladin", "paladin"], ["6104", "D61Monk", "monk"]]:
            var h: Dictionary = r.get_hero(v[0])
            if h.is_empty():
                h = r.fresh(v[0], v[1], v[2])
            h["alive"] = true
            h["weapon"] = 3
            h["armour"] = 3
            ids.append(v[0])
        _d = Delve.new()
        _d.town = _t
        _d.roster = r
        _d.start_floor = 5
        _d.max_floors = 5
        _t.add_child(_d)
        _d.start(ids)
        _eye.director._set_on(true)
    if _f > 30 and _seen_at < 0 and _d.lord_fighting() != null:
        _seen_at = _f
        _seen_ms = Time.get_ticks_msec()
        print("D61_TEST lord fighting at frame %d" % _f)
        # the resting 2x2 grid hides floating text in a quarter pane BY DESIGN (spotlight.gd _masks,
        # HUD-owned, L21) - so the capture folds the grid the way the Satchel does (L51) to see them
        var sp := Spotlight.of(_t)
        if sp:
            sp.suspend(true)
    if _seen_at > 0 and _burst_f < 0 and Time.get_ticks_msec() - _seen_ms >= 9000:
        _burst_f = _f
        # the burst goes on the live creature nearest the hero the camera is watching, so it is on screen
        var l: Monster = null
        var cam := root.get_viewport().get_camera_3d()
        var best := 1e9
        for mon in _all_mons():
            if (mon as Monster).state == Monster.S.DEAD or cam == null:
                continue
            var sp2 := cam.unproject_position((mon as Node3D).global_position)
            var d := sp2.distance_to(Vector2(960, 620))
            if not cam.is_position_behind((mon as Node3D).global_position) and d < best:
                best = d
                l = mon
        if l == null and _d.dun.lord and is_instance_valid(_d.dun.lord) and _d.dun.lord.state != Monster.S.DEAD:
            l = _d.dun.lord
        _check(l != null, "a live creature on screen for the burst (%s)" % (String(l.def.get("name", "")) if l else "-"))
        var pre: Dictionary = Monster.results_total.duplicate()
        if l:
            for lb in _labels(l):
                lb.queue_free()
            l._live_nums.clear()
            var p0 := l.results_pooled
            l.show_result("hit", 5.0)
            l.show_result("hit", 5.0)
            var nums: Array = l._live_nums
            _check(l.results_pooled == p0 + 1 and nums.size() == 1 and (nums[-1]["lb"] as Label3D).text == "10", "two hits inside POOL_S read as ONE climbing figure: '%s', %d live" % [(nums[-1]["lb"] as Label3D).text if not nums.is_empty() else "-", nums.size()])
            l.show_result("crit", 23.0)
            _check(l._live_nums.size() == 2 and (l._live_nums[-1]["lb"] as Label3D).text == "CRIT 23!", "a crit never pools and says CRIT: '%s'" % (l._live_nums[-1]["lb"] as Label3D).text)
            var seen := []
            for k in ["save", "resist", "vuln", "miss"]:
                l.show_result(k, 7.0)
                seen.append((l._live_nums[-1]["lb"] as Label3D).text)
            _check(seen == ["save 7", "resist 7", "7 x2!", "miss"], "save / resist / vuln / miss each read as themselves: %s" % str(seen))
            _check(l._live_nums.size() <= Monster.LIVE_CAP, "no creature holds more than %d numbers (%d)" % [Monster.LIVE_CAP, l._live_nums.size()])
            # the capture: one of each that matters, spread so they can be read
            for lb in _labels(l):
                lb.queue_free()
            l._live_nums.clear()
            l.show_result("crit", 31.0)
            l.show_result("save", 9.0)
            l.show_result("miss")
        for k in Monster.results_total:
            _synth[k] = int(Monster.results_total[k]) - int(pre.get(k, 0))
    if _seen_at > 0 and _burst_f > 0 and _f - _burst_f == 8:
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/burst_1080.png"))
        print("D61_TEST viewport %s" % str(root.get_texture().get_size()))
    if _burst_f > 0 and not _tallied and Time.get_ticks_msec() - _seen_ms >= 30000:
        _tallied = true
        var t := {}
        for k in Monster.results_total:
            t[k] = int(Monster.results_total[k]) - int(_synth.get(k, 0))
        print("D61_TEST organic tally %s" % str(t))
        _check(int(t.get("hit", 0)) + int(t.get("crit", 0)) > 0, "the fight itself raised numbers (%d hit, %d crit)" % [int(t.get("hit", 0)), int(t.get("crit", 0))])
        _check(int(t.get("miss", 0)) > 0, "a miss SAYS so in the real fight (%d misses)" % int(t.get("miss", 0)))
    if _tallied or _f > 40000:
        if _seen_at < 0:
            _fails.append("the lord never fought")
        print("D61_TEST %d checks, %d failed" % [_checks, _fails.size()])
        print("D61_TEST %s" % ("OK" if _fails.is_empty() else "FAIL " + str(_fails)))
        return true
    return false
