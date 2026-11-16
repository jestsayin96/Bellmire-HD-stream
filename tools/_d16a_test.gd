extends SceneTree
## D16a: local avoidance. 50 walkers funnelled head-on through the real west
## gate (25 from outside in, 25 from inside out). A pair standing closer than
## 0.3 m (centre to centre) for over 1 s straight is a SUSTAINED overlap.
## PASS: 0 sustained overlaps, under 0.5 pair-seconds under 0.3 m in all (the
## old shove let folk walk straight through each other for ~29 pair-s - brief
## each time, so never "sustained", but it is the clipping on stream) and at
## least 45 of 50 through (bodies yield, no deadlock). Run with --fixed-fps 60 so frames are sim time.
const N := 50
const OVER := 0.3
const SUSTAIN := 1.0
const RUN_S := 50.0
var _t: Node3D
var _f := 0
var _walkers: Array = []
var _goal: Dictionary = {}
var _run: Dictionary = {}          # pair key -> seconds under OVER
var _sustained: Dictionary = {}    # pair key -> longest run
var _max_run := 0.0
var _over_frames := 0
var _min_d := INF
var _clip_s := 0.0                 # pair-seconds closer than 0.45 m (shoulders inside shoulders)
var _arrive_t: Dictionary = {}
var _gate := Vector3.ZERO
var _t0 := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _spawn() -> void:
    _gate = _t.call("_gate", -1.0)
    var out := Vector3(_gate.x, 0.0, _gate.z).normalized()
    var lat := Vector3(-out.z, 0.0, out.x)
    var nav = _t.get("nav")
    for i in range(N):
        var side := 1.0 if i < N / 2 else -1.0
        var k := i % (N / 2)
        var row := k / 5
        var col := k % 5
        var a := _gate + out * side * (10.0 + row * 1.1) + lat * (col - 2) * 1.1
        var b := _gate - out * side * (12.0 + row * 1.2) + lat * (col - 2) * 1.2
        if nav:
            a = nav.closest(a)
            b = nav.closest(b)
        a = _t.call("keep_walkable", a)
        b = _t.call("keep_walkable", b)
        var v := Townsfolk.new()
        v.role = "peasant"
        v.person_name = "Funnel %d" % i
        v.town = _t
        v.home = b
        v.work = b
        v.position = a
        _t.add_child(v)
        (_t.get("people") as Array).append(v)
        v._wait = 9999.0
        _walkers.append(v)
        _goal[v] = b
    print("D16A spawned ", _walkers.size(), " at gate ", _gate)

## routes once the navmesh answers (a path asked for on the spawn frame can
## come back empty and fall back to the old road-hex route)
func _go() -> void:
    var sizes := []
    for v in _walkers:
        v._route = _t.call("route", (v as Node3D).global_position, _goal[v])
        sizes.append(v._route.size())
    print("D16A routes ", sizes)

func _process(delta: float) -> bool:
    _f += 1
    if _f == 60:
        _spawn()
        return false
    if _f == 120:
        _go()
        _t0 = _f
        return false
    if _f < 120:
        return false
    if _walkers.is_empty():
        return false
    var dt := 1.0 / 60.0
    # every visible person near the gate, the funnel's walkers among them
    var near: Array = []
    for p in _t.get("people"):
        if not is_instance_valid(p) or not (p as Node3D).visible or bool(p.get("inside")):
            continue
        var pp: Vector3 = (p as Node3D).global_position
        if Vector2(pp.x - _gate.x, pp.z - _gate.z).length() < 28.0:
            near.append(p)
    var seen := {}
    for i in range(near.size()):
        var a: Node3D = near[i]
        for j in range(i + 1, near.size()):
            var b: Node3D = near[j]
            # posted pairs (two gate guards on one post) are not the funnel
            if bool(a.get("stay")) and bool(b.get("stay")):
                continue
            var d := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
            var key := str(mini(a.get_instance_id(), b.get_instance_id())) + ":" + str(maxi(a.get_instance_id(), b.get_instance_id()))
            if _walkers.has(a) or _walkers.has(b):
                _min_d = minf(_min_d, d)
                if d < 0.45:
                    _clip_s += dt
            if d < OVER:
                _over_frames += 1
                var r := float(_run.get(key, 0.0)) + dt
                _run[key] = r
                seen[key] = true
                _max_run = maxf(_max_run, r)
                if r > SUSTAIN:
                    _sustained[key] = r
    for k in _run.keys():
        if not seen.has(k):
            _run.erase(k)
    for v in _walkers:
        if _arrive_t.has(v):
            continue
        var g: Vector3 = _goal[v]
        var vp: Vector3 = (v as Node3D).global_position
        if Vector2(vp.x - g.x, vp.z - g.z).length() < 1.6:
            _arrive_t[v] = float(_f - _t0) / 60.0
    if _f - _t0 >= int(RUN_S * 60.0):
        var times: Array = _arrive_t.values()
        times.sort()
        var med: float = times[times.size() / 2] if not times.is_empty() else -1.0
        var slides := 0
        var rer := 0
        for v in _walkers:
            slides += int(v.slides)
            rer += int(v.reroutes)
        var ok := _sustained.is_empty() and float(_over_frames) / 60.0 < 0.5 and _arrive_t.size() >= 45
        print("D16A_TEST sustained=%d max_run=%.2fs over_frames=%d min_d=%.2f clip_pair_s=%.1f arrived=%d/%d median_t=%.1fs last_t=%.1fs slides=%d reroutes=%d %s" % [
            _sustained.size(), _max_run, _over_frames, _min_d, _clip_s, _arrive_t.size(), N, med,
            (times.back() if not times.is_empty() else -1.0), slides, rer, "PASS" if ok else "FAIL"])
        return true
    return false
