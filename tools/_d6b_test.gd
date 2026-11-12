extends SceneTree
## D6b: the town's snap never answers the origin. Headless.
## From the very first frame town._snap(p) and nav.closest(p) for points spread
## over the town must come back near p (a standing place within a few metres),
## never (0,0,0) - before the navmesh's first sync they fall back to the town's
## own push-out of solids. Then the watch's beats, the riders' loops and everyone
## standing on the square must not be stacked on one spot.
var _t: Node3D
var _f := 0
var _bad: Array = []
var _zero := 0
var _far := 0
var _calls := 0
var _first_sync := -1

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _check(ok: bool, what: String) -> void:
    if not ok:
        _bad.append(what)
        print("FAIL ", what)

func _probe() -> void:
    var nav = _t.get("nav")
    var mp: Vector3 = _t.get("_market_pos")
    var pts: Array = [mp + Vector3(9, 0, 3), mp + Vector3(-12, 0, 8), Vector3(40, 0, -30), Vector3(-55, 0, 20), mp + Vector3(3, 0, -15)]
    for p in pts:
        var q: Vector3 = _t.call("_snap", p)
        _calls += 1
        if Vector2(q.x, q.z).length() < 0.01:
            _zero += 1
            if _zero <= 5:
                print("ZERO _snap f=%d p=%s" % [_f, str(p)])
        elif Vector2(q.x - p.x, q.z - p.z).length() > 6.0:
            _far += 1
            if _far <= 5:
                print("FAR _snap f=%d p=%s -> %s" % [_f, str(p), str(q)])
        if nav != null:
            var c: Vector3 = nav.closest(p)
            _calls += 1
            if Vector2(c.x, c.z).length() < 0.01:
                _zero += 1
                if _zero <= 5:
                    print("ZERO closest f=%d p=%s" % [_f, str(p)])
    if nav != null and _first_sync < 0 and nav.has_method("synced") and nav.synced():
        _first_sync = _f

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f <= 60:
        _probe()
        return false
    if _f == 61:
        print("D6b probes=%d zero=%d far=%d first_sync_frame=%d" % [_calls, _zero, _far, _first_sync])
        _check(_zero == 0, "snap/closest never answer the origin (%d)" % _zero)
        _check(_far == 0, "snap stays near the asked point (%d far)" % _far)
        # the watch's beats and the riders' loops: no point at the origin, not all one spot
        var beats := 0
        var bad_pts := 0
        for p in _t.get("people"):
            if not (p is Townsfolk):
                continue
            var b = p.get("stops")
            var w = p.get("work")
            if String(p.get("role")) in ["trader", "innkeeper"] and not bool(p.get("stay")):
                if Vector2((w as Vector3).x, (w as Vector3).z).length() < 0.01:
                    bad_pts += 1
                    print("WORK at origin: ", p.get("person_name"))
            if b is Array and not (b as Array).is_empty():
                beats += 1
                var spots := {}
                for st in b:
                    var v: Vector3 = st[0]
                    if Vector2(v.x, v.z).length() < 0.01:
                        bad_pts += 1
                    spots[str(v.snapped(Vector3.ONE))] = true
                if (b as Array).size() >= 3 and spots.size() < 2:
                    bad_pts += 1
        print("D6b beats=%d bad_points=%d" % [beats, bad_pts])
        _check(bad_pts == 0, "no patrol beat point at the origin or collapsed (%d)" % bad_pts)
        _stack0 = _stacked(true)
        return false
    if _f == 900:
        var st := _stacked(false)
        print("D6b stacked_pairs start=%d after_15s=%d" % [_stack0, st])
        _check(st <= 4, "nobody stays stacked on one spot (%d pairs)" % st)
        print("D6B_TEST OK" if _bad.is_empty() else "D6B_TEST FAIL %d" % _bad.size())
        return true
    return false

var _stack0 := 0

## walkers outdoors closer than 0.3 m to another (pairs); and nobody at the origin
func _stacked(first: bool) -> int:
        var pos: Array = []
        var who: Array = []
        for p in _t.get("people"):
            if p is Node3D and (p as Node3D).visible and not bool(p.get("inside")):
                pos.append((p as Node3D).global_position)
                who.append("%s/%s/%s" % [p.get("role"), p.get("gear_role"), p.name])
        var stacked := 0
        for i in range(pos.size()):
            for j in range(i + 1, pos.size()):
                if (pos[i] as Vector3).distance_to(pos[j]) < 0.3:
                    stacked += 1
                    if stacked <= 6:
                        print("STACK %s %s + %s" % [str((pos[i] as Vector3).snapped(Vector3.ONE * 0.1)), who[i], who[j]])
        var at_origin := 0
        for v in pos:
            if Vector2(v.x, v.z).length() < 0.5:
                at_origin += 1
        print("D6b people_out=%d stacked_pairs=%d at_origin=%d" % [pos.size(), stacked, at_origin])
        _check(at_origin == 0, "nobody standing at the origin (%d)" % at_origin)
        return stacked
