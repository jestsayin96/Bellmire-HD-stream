extends SceneTree
## D7 TEST (headless). Far-away LOD and the street cap.
## 1) LOD tiers follow the camera distance (heroes and riders always full).
## 2) Far walkers keep their pace (summed-time steps).
## 3) Past STREET_CAP a settler keeps indoors, still counts as a soul; a burial
##    on the streets brings one out.
## 4) Script time per frame with LOD on vs off, the town filled past the cap.
var _t: Node3D
var _f := 0
var _cam: Camera3D
var _fail := 0
var _walker: Townsfolk
var _w_from := Vector3.ZERO
var _w_route: Array = []
var _w_last := Vector3.ZERO
var _w_len := 0.0
var _w_res: Array = []
var _w_pf := 0
var _blk := {}
var _st0 := 0
var _pf0 := 0
var _steps := {}
var _nblk := {}
var _ms := {"on": [], "off": []}

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _k(nm: String) -> float:
    return float((_t.get_script() as Script).get_script_constant_map()[nm])

func _check(ok: bool, what: String) -> void:
    print(("  ok   " if ok else "  FAIL ") + what)
    if not ok:
        _fail += 1

func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        var m: Vector3 = _t.get("_market_pos")
        _cam.global_position = m + Vector3(0, 30, 25)
        _cam.make_current()
        _t.call("_lod_pass")
        var bad := 0
        var tiers := [0, 0, 0]
        var full_ok := true
        for p in _t.get("people"):
            var v: Townsfolk = p
            var d := _cam.global_position.distance_to(v.global_position)
            var want := 2 if d > _k("LOD_FAR") else (1 if d > _k("LOD_NEAR") else 0)
            if v is HeroBody or v is Cavalry:
                want = 0
                if v.lod != 0:
                    full_ok = false
            if v.lod != want:
                bad += 1
            tiers[v.lod] += 1
        print("D7 lod tiers near/mid/far=", tiers, " counts=", _t.get("lod_counts"))
        _check(bad == 0, "every walker's LOD matches its distance (%d wrong)" % bad)
        _check(full_ok, "heroes and the mounted watch run full")
        _check(tiers[2] > 10 and tiers[0] > 5, "the town has near and far walkers")
        _t.set("_lod_t", 1e9)          # hold the LOD passes: this test sets them by hand
        for p in _t.get("people"):
            var v: Townsfolk = p
            if not (v is HeroBody) and not (v is Cavalry) and not v.stay and v.leader == null and v.visible and not v.inside:
                _walker = v
                break
        _w_from = _t.call("keep_walkable", (_t.get("_market_pos") as Vector3) + Vector3(4, 0, 4))
        _w_route = _t.call("route", _w_from, _t.call("_gate", -1.0))
        print("D7 pace walker=%s route=%d points" % [_walker.person_name, _w_route.size()])
    # 2) the same walk twice: every tick (lod 0), then every 4th tick (lod 2)
    for ph in [[70, 0], [440, 2]]:
        if _f == ph[0]:
            _walker.set_lod(ph[1])
            _walker.global_position = _w_from
            _walker._route = _w_route.duplicate()
            _walker._wait = 0.0
            _walker.inside = false
            _walker.visible = true
            _w_last = _w_from
            _w_len = 0.0
            _w_pf = Engine.get_physics_frames()
        if _f > ph[0] and _f <= ph[0] + 360:
            var q := _walker.global_position
            _w_len += Vector2(q.x - _w_last.x, q.z - _w_last.z).length()
            _w_last = q
        if _f == ph[0] + 360:
            _w_res.append(_w_len / maxf(1.0, float(Engine.get_physics_frames() - _w_pf)) * 60.0)
    if _f == 820:
        print("D7 pace (m per 60 physics ticks): every tick %.2f, every 4th tick %.2f" % [_w_res[0], _w_res[1]])
        _check(_w_res[0] > 1.0 and absf(_w_res[1] - _w_res[0]) < _w_res[0] * 0.1, "a far walker keeps the near pace (within 10%)")
        _walker.set_lod(0)
        _t.set("_lod_t", 0.0)
        # 3) the cap
        var eco: Economy = _t.get("economy")
        var pop0 := eco.population()
        var made: Array = []
        var n := 0
        while int(_t.get("indoor_souls")) == 0 and n < 300:
            made.append(_t.call("arrive", "farmer", "%s settles (D7 test)."))
            n += 1
        var streets := int(_t.call("_on_streets"))
        var indoor := int(_t.get("indoor_souls"))
        for i in 4:
            made.append(_t.call("arrive", "farmer", "%s settles (D7 test)."))
        var indoor2 := int(_t.get("indoor_souls"))
        var hid := 0
        for v in made.slice(made.size() - 4):
            if not (v as Node3D).visible and (v as Node).process_mode == Node.PROCESS_MODE_DISABLED and v.has_meta("indoor_soul"):
                hid += 1
        print("D7 cap streets=%d indoor=%d -> %d, souls %d -> %d" % [streets, indoor, indoor2, pop0, eco.population()])
        _check(streets <= int(_k("STREET_CAP")), "no more than STREET_CAP on the streets (%d)" % streets)
        _check(indoor2 == indoor + 4 and hid == 4, "settlers past the cap keep indoors, hidden and still")
        _check(eco.population() == pop0 + made.size(), "every settler counts as a soul of Bellmire")
        var g: Townsfolk = _t.call("arrive", "guard", "%s is sworn in (D7 test).")
        _check(g != null and not g.has_meta("indoor_soul"), "a new guard always walks the streets")
        var before := int(_t.get("indoor_souls"))
        var buried := 0
        for v in made:
            if buried < 2 and is_instance_valid(v) and not v.has_meta("indoor_soul") and (v as Townsfolk).visible:
                _t.call("bury", v, "D7 test: a walker is buried.")
                buried += 1
        print("D7 burials %d: indoor %d -> %d, streets %d" % [buried, before, int(_t.get("indoor_souls")), int(_t.call("_on_streets"))])
        _check(int(_t.get("indoor_souls")) < before and int(_t.call("_on_streets")) <= int(_k("STREET_CAP")) + 1, "burials on the streets bring indoor souls out, never past the cap")
    # 4) script time, alternating 100-frame blocks off / on after a settle
    if _f > 1000 and _f <= 1800:
        var blk := (_f - 1001) / 100
        var k := "off" if blk % 2 == 0 else "on"
        if (_f - 1001) % 100 == 0:
            _t.set("lod_on", k == "on")
            _t.call("_lod_pass")
            _st0 = Townsfolk.steps
            _pf0 = Engine.get_physics_frames()
        if (_f - 1001) % 100 == 99:
            _steps[k] = float(_steps.get(k, 0.0)) + float(Townsfolk.steps - _st0) / maxf(1.0, float(Engine.get_physics_frames() - _pf0))
            _nblk[k] = int(_nblk.get(k, 0)) + 1
        elif (_f - 1001) % 100 > 10:
            var pr := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
            var ph := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
            (_ms[k] as Array).append(pr + ph)
            _blk[blk] = [_blk.get(blk, [0.0, 0.0, 0])[0] + pr, _blk.get(blk, [0.0, 0.0, 0])[1] + ph, _blk.get(blk, [0.0, 0.0, 0])[2] + 1]
        if (_f - 1001) % 100 == 99:
            var e: Array = _blk[blk]
            print("D7 block %d %s: process %.2f ms, physics %.2f ms" % [blk, k, e[0] / e[2], e[1] / e[2]])
    if _f == 1800:
        var on := 0.0
        var off := 0.0
        for x in _ms["on"]:
            on += x
        for x in _ms["off"]:
            off += x
        on /= maxf(1.0, (_ms["on"] as Array).size())
        off /= maxf(1.0, (_ms["off"] as Array).size())
        print("D7 script ms/frame with %d people: lod on %.2f, off %.2f (%.0f%% saved)" % [(_t.get("people") as Array).size(), on, off, 100.0 * (1.0 - on / maxf(0.01, off))])
        var son: float = _steps["on"] / _nblk["on"]
        var soff: float = _steps["off"] / _nblk["off"]
        print("D7 walker steps per physics tick: lod on %.1f, off %.1f (%.0f%% fewer); script ms is noisy headless - FPS: tools/_d7_fps.gd" % [son, soff, 100.0 * (1.0 - son / soff)])
        _check(son < soff * 0.8, "LOD takes at least a fifth fewer walker steps")
        print("D7_TEST OK" if _fail == 0 else "D7_TEST FAIL %d" % _fail)
        return true
    return false
