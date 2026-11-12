extends SceneTree
## D16d: DOORWAY / GATE / BRIDGE FUNNELING. A two-way crowd (N/2 each way) is
## sent head-on through a real choke - the west gate arch or the river bridge
## deck - and the test watches whether it QUEUES AND PASSES or PILES UP.
##   PILE   = seconds a walker on a route, not yet through, in the funnel zone
##            (10 m round the gate; the deck + 4 m for the bridge), made under 0.15 m/s progress (summed over walkers)
##   BACK   = seconds a walker in the zone was shoved backwards (> 0.3 m/s)
##   JERK   = walker-s in the zone whose heading flipped > 100 deg in a frame
##   OVER   = pair-seconds closer than 0.3 m in the zone (D16a's bar), SUSTAINED > 1 s
## PASS: walked/straight < 1.35 (no detour out through the gate and back), all through, 0 sustained, OVER < 0.5 pair-s, PILE per walker < 1.5 s,
## BACK per walker < 0.5 s. Run with --fixed-fps 60 (frames = sim time):
##   -- --site gate|bridge  [--n 60]  [--early = route on the spawn frame]
##      [--old = no D16d re-route of pre-sync routes, the before figure]
const OVER := 0.3
const SUSTAIN := 1.0
const RUN_S := 60.0
var _t: Node3D
var _f := 0
var _n := 60
var _site := "gate"
var _walkers: Array = []
var _goal: Dictionary = {}
var _gdir: Dictionary = {}
var _last: Dictionary = {}
var _run: Dictionary = {}
var _sustained: Dictionary = {}
var _over_frames := 0
var _min_d := INF
var _clip_s := 0.0             # pair-s closer than 0.45 m (shoulder in shoulder)
var _jerk_s := 0.0             # walker-s turned > 100 deg/frame-pair (shoved about)
var _lastv: Dictionary = {}
var _pile_s := 0.0
var _back_s := 0.0
var _peak_pile := 0
var _arrive_t: Dictionary = {}
var _c := Vector3.ZERO        # the choke's centre
var _zone := 10.0             # m round it that count as the funnel
var _t0 := 0
var _starts: Array = []
var _diag := 0
var _early := false           # route on the spawn frame, as the town's own folk do at start
var _walked: Dictionary = {}
var _straight := 0.0
var _ends: Array = []

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    for i in range(args.size()):
        if args[i] == "--site" and i + 1 < args.size():
            _site = args[i + 1]
        elif args[i] == "--n" and i + 1 < args.size():
            _n = int(args[i + 1])
        elif args[i] == "--old":
            Townsfolk.funnel_fix = false
        elif args[i] == "--early":
            _early = true
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _spawn() -> void:
    var out := Vector3.ZERO
    var reach := 12.0
    if _site == "bridge":
        var k: Dictionary = _t.get_script().get_script_constant_map()
        var half := float(k.get("RIVER_W", 8.0)) + float(k.get("RIVER_BANK", 3.0)) + 1.5
        _c = Vector3(0.0, 0.0, float(_t.get("_bridge_z")))
        out = Vector3(0, 0, 1)
        reach = half + 6.0
        _zone = half + 4.0
    else:
        _c = _t.call("_gate", -1.0)
        out = Vector3(_c.x, 0.0, _c.z).normalized()
    var lat := Vector3(-out.z, 0.0, out.x)
    var nav = _t.get("nav")
    var per := _n / 2
    var cols := 5 if _site == "gate" else 4
    var gap := 1.1 if _site == "gate" else 1.0
    for i in range(_n):
        var side := 1.0 if i < per else -1.0
        var k := i % per
        var row := k / cols
        var col := k % cols
        var lo := (col - (cols - 1) * 0.5) * gap
        var a := _c + out * side * (reach + row * 1.1) + lat * lo
        var b := _c - out * side * (reach + 4.0 + row * 1.2) + lat * lo
        if nav:
            a = nav.closest(a)
            b = nav.closest(b)
        a = _t.call("keep_walkable", a)
        b = _t.call("keep_walkable", b)
        # where the ground is narrow two spawns (or two goals) can snap onto one
        # spot - step the later one further out until it has room
        a = _room(a, out * side, _starts, nav)
        b = _room(b, -out * side, _ends, nav)
        _starts.append(a)
        _ends.append(b)
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
    print("D16D site=%s spawned %d at %s fix=%s" % [_site, _walkers.size(), _c, Townsfolk.funnel_fix])

func _room(q: Vector3, away: Vector3, taken: Array, nav) -> Vector3:
    for _i in range(12):
        var ok := true
        for o in taken:
            if Vector2(q.x - (o as Vector3).x, q.z - (o as Vector3).z).length() < 0.8:
                ok = false
                break
        if ok:
            return q
        q += away * 0.9
        if nav:
            q = nav.closest(q)
        q = _t.call("keep_walkable", q)
    return q

func _idle(o: Node3D) -> bool:
    var r = o.get("_route")
    return not (r is Array) or (r as Array).is_empty()

func _go() -> void:
    var sizes := []
    for v in _walkers:
        v._route = _t.call("route", (v as Node3D).global_position, _goal[v])
        sizes.append(v._route.size())
        _last[v] = (v as Node3D).global_position
        _walked[v] = 0.0
        _straight += Vector2(_goal[v].x - (v as Node3D).global_position.x, _goal[v].z - (v as Node3D).global_position.z).length()
    print("D16D routes ", sizes)
    var r0: Array = _walkers[0]._route
    print("D16D route0 ", r0.map(func(q): return Vector2(snappedf(q.x, 0.1), snappedf(q.z, 0.1))))

func _process(_delta: float) -> bool:
    _f += 1
    if _f == 60:
        _spawn()
        if _early:
            _go()
            _t0 = _f
        return false
    if _f == 120 and not _early:
        _go()
        _t0 = _f
        return false
    if _t0 == 0 or _walkers.is_empty():
        return false
    var dt := 1.0 / 60.0
    var near: Array = []
    for p in _t.get("people"):
        if not is_instance_valid(p) or not (p as Node3D).visible or bool(p.get("inside")):
            continue
        var pp: Vector3 = (p as Node3D).global_position
        if Vector2(pp.x - _c.x, pp.z - _c.z).length() < 34.0:
            near.append(p)
    var seen := {}
    for i in range(near.size()):
        var a: Node3D = near[i]
        for j in range(i + 1, near.size()):
            var b: Node3D = near[j]
            if bool(a.get("stay")) and bool(b.get("stay")):
                continue
            if not (_walkers.has(a) or _walkers.has(b)):
                continue
            # two who have both arrived and stand at their stops are not the funnel
            # (the far rows' goals can snap together where the ground is narrow)
            if _idle(a) and _idle(b):
                continue
            var d := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
            if _f - _t0 < 60:
                continue                # the first second: spawn placement, not the funnel
            if Vector2(a.global_position.x - _c.x, a.global_position.z - _c.z).length() > _zone:
                continue                # the far ends (a packed crowd standing at its stops) are not the funnel
            _min_d = minf(_min_d, d)
            if d < 0.45:
                _clip_s += dt
            if d < OVER:
                _over_frames += 1
                var key := str(mini(a.get_instance_id(), b.get_instance_id())) + ":" + str(maxi(a.get_instance_id(), b.get_instance_id()))
                var r := float(_run.get(key, 0.0)) + dt
                _run[key] = r
                if r < dt * 1.5 and _diag < 25:
                    _diag += 1
                    print("D16D over t=%.1f %s|%s at %s from_c=%.1f d=%.2f" % [float(_f - _t0) / 60.0, a.get("person_name"), b.get("person_name"),
                        Vector2(snappedf(a.global_position.x, 0.1), snappedf(a.global_position.z, 0.1)),
                        Vector2(a.global_position.x - _c.x, a.global_position.z - _c.z).length(), d])
                seen[key] = true
                if r > SUSTAIN:
                    _sustained[key] = r
    for k in _run.keys():
        if not seen.has(k):
            _run.erase(k)
    var piled := 0
    for v in _walkers:
        var vp: Vector3 = (v as Node3D).global_position
        var g: Vector3 = _goal[v]
        var lp: Vector3 = _last[v]
        _last[v] = vp
        if not _arrive_t.has(v):
            _walked[v] = float(_walked[v]) + Vector2(vp.x - lp.x, vp.z - lp.z).length()
        if _arrive_t.has(v):
            continue
        if Vector2(vp.x - g.x, vp.z - g.z).length() < 1.6:
            _arrive_t[v] = float(_f - _t0) / 60.0
            continue
        var to_g := Vector3(g.x - vp.x, 0.0, g.z - vp.z).normalized()
        var vel := Vector3(vp.x - lp.x, 0.0, vp.z - lp.z) / dt
        var prog := vel.dot(to_g)
        var lv: Vector3 = _lastv.get(v, Vector3.ZERO)
        _lastv[v] = vel
        var in_zone := Vector2(vp.x - _c.x, vp.z - _c.z).length() < _zone
        if in_zone and vel.length() > 0.3 and lv.length() > 0.3 and vel.normalized().dot(lv.normalized()) < -0.17:
            _jerk_s += dt
        if in_zone and prog < -0.3:
            _back_s += dt
        if in_zone and not (v._route as Array).is_empty() and prog < 0.15:
            _pile_s += dt
            piled += 1
    _peak_pile = maxi(_peak_pile, piled)
    if _f - _t0 >= int(RUN_S * 60.0) or _arrive_t.size() == _walkers.size():
        var times: Array = _arrive_t.values()
        times.sort()
        var med: float = times[times.size() / 2] if not times.is_empty() else -1.0
        var nn := float(_walkers.size())
        var wsum := 0.0
        for v in _walkers:
            wsum += float(_walked[v])
        var detour := wsum / maxf(_straight, 1.0)
        var ok := detour < 1.35 and _arrive_t.size() == _walkers.size() and _sustained.is_empty() and float(_over_frames) / 60.0 < 0.5 \
            and _pile_s / nn < 1.5 and _back_s / nn < 0.5
        print("D16D_TEST site=%s fix=%s early=%s walked/straight=%.2f presync_reroutes=%d arrived=%d/%d median_t=%.1fs last_t=%.1fs pile_s=%.1f (%.2f/walker, peak %d) back_s=%.1f (%.2f/walker) over_pair_s=%.2f clip_pair_s=%.1f jerk_s=%.2f sustained=%d min_d=%.2f %s" % [
            _site, Townsfolk.funnel_fix, _early, detour, Townsfolk.presync_reroutes, _arrive_t.size(), _walkers.size(), med,
            (times.back() if not times.is_empty() else -1.0), _pile_s, _pile_s / nn, _peak_pile,
            _back_s, _back_s / nn, float(_over_frames) / 60.0, _clip_s, _jerk_s, _sustained.size(), _min_d, "PASS" if ok else "FAIL"])
        return true
    return false
