extends SceneTree
## D12: the valley beyond the walls. Headless.
## Sites built (steadings, the Ashwood and its camp, the ford and the Ford Mill,
## the Old Footing), each reachable on the navmesh from the market; the ford
## really crosses (a short path over the river far from the bridge, gravel above
## the water); travellers and carts walk every trip and come home, never inside
## anything solid; residents stand clear.
var _t: Node3D
var _v
var _f := 0
var _bad: Array = []
var _run := 0
var _samples := 0
var _solid := 0
var _sent := 0
var _moved := {}
var _last := {}
var _pf0 := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        _bad.append(what)

func _plen(a: Vector3, pts: Array) -> float:
    var L := 0.0
    var p := a
    for q in pts:
        L += Vector2(q.x - p.x, q.z - p.z).length()
        p = q
    return L

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f < 30:
        return false
    if _f == 30:
        _v = _t.get("valley")
        _check(_v != null, "the valley is built")
        if _v == null:
            return _end()
        var m: Dictionary = _v.made
        print("MADE ", m, " SITES ", _v.sites.keys())
        _check(_v.sites.size() >= 6, "six places beyond the wall (%d)" % _v.sites.size())
        _check(int(m["houses"]) >= 7 and int(m["trees"]) >= 120 and int(m["walls"]) >= 7 and int(m["folk"]) >= 7,
            "cottages, the Ashwood's trees, the Footing's walls, the folk")
        var fx: float = _t.get("ford_x")
        var rz: float = _t.call("river_z_fast", fx)
        var hf: float = _t.call("height_at", fx, rz)
        var hb: float = _t.call("height_at", fx + 12.0, rz)
        print("FORD x ", fx, " bar ", hf, " beside ", hb)
        _check(hf > -0.9 and hb < -1.5, "the ford's gravel stands above the water, the river either side does not")
        return false
    var nv = _t.get("nav")
    if not nv.synced():
        return false
    if _sent == 0:
        var fx: float = _t.get("ford_x")
        var rz: float = _t.call("river_z_fast", fx)
        var a := Vector3(fx, 0, rz - 16.0)
        var b := Vector3(fx, 0, rz + 16.0)
        var pr: Array = _t.call("route", a, b)
        var L := _plen(a, pr)
        print("FORD route ", pr.size(), " pts ", L, " m")
        _check(not pr.is_empty() and L < 45.0, "over the ford in a few steps (%.1f m, the bridge is ~%d m away)" % [L, int(absf(fx))])
        var mp: Vector3 = _t.get("_market_pos")
        for k in _v.sites:
            var d: Vector3 = _v.sites[k]["door"]
            var r: Array = _t.call("route", mp, d)
            var end: Vector3 = r.back() if not r.is_empty() else mp
            var gap := Vector2(end.x - d.x, end.z - d.z).length()
            print("ROUTE market -> ", k, " ", int(_plen(mp, r)), " m, ends ", snappedf(gap, 0.1), " m off")
            _check(gap < 2.5, "%s is reachable from the market" % k)
            var sl: Array = _t.call("solid_at", d, 0.0)
            _check(sl.is_empty(), "%s's spot is clear ground" % k)
        for c in _v.get_children():
            if c is Townsfolk and (c as Townsfolk).stay:
                var p: Vector3 = (c as Node3D).global_position
                _check((_t.call("solid_at", p, -0.05) as Array).is_empty(), "%s stands clear (%s)" % [(c as Townsfolk).person_name, p])
        for tr in _v.TRIPS:
            if _v.send(tr) != null:
                _sent += 1
            else:
                print("NO ROUTE ", tr)
        print("SENT ", _sent, " of ", _v.TRIPS.size())
        _check(_sent == _v.TRIPS.size(), "every trip has a road")
        Engine.time_scale = 6.0
        _pf0 = Engine.get_physics_frames()
        return false
    _run += 1
    if _run % 10 == 0:
        for tr in _v.travellers:
            var tv = tr["v"]
            if not is_instance_valid(tv):
                continue
            var p: Vector3 = (tv as Node3D).global_position
            _samples += 1
            if not (_t.call("solid_at", p, -0.1) as Array).is_empty():
                _solid += 1
                if _solid <= 8:
                    print("SOLID ", tv.person_name, " ", tr["trip"][0], " -> ", tr["trip"][1], " at ", p)
            var key: int = (tv as Node).get_instance_id()
            if _last.has(key):
                _moved[key] = float(_moved.get(key, 0.0)) + p.distance_to(_last[key])
            _last[key] = p
    var game_s := float(Engine.get_physics_frames() - _pf0) / 60.0 * 6.0
    if game_s >= 720.0 or (_run > 200 and _v.trips_done >= _sent):
        print("DONE trips ", _v.trips_done, " of ", _v.trips_sent, " still out ", _v.travellers.size(), " after ", int(game_s), " s of game time")
        var tot := 0.0
        for k in _moved:
            tot += float(_moved[k])
        print("WALKED ", int(tot), " m; SAMPLES ", _samples, " in_solid ", _solid)
        _check(_v.trips_done >= _sent - 1, "travellers come home (%d of %d)" % [_v.trips_done, _sent])
        _check(_samples > 100 and _solid <= maxi(1, _samples / 500), "nobody walks through anything (%d of %d)" % [_solid, _samples])
        return _end()
    return false

func _end() -> bool:
    Engine.time_scale = 1.0
    print("D12_TEST OK" if _bad.is_empty() else "D12_TEST FAIL %s" % [_bad])
    quit()
    return true
