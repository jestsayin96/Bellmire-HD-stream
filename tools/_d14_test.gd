extends SceneTree
## D14: walkers pinned on a prop. Every 10 s count routed walkers (not posted,
## not indoors, a route left) that moved under 0.3 m; "pinned" = the same
## walker caught twice running (10 s apart). A walker caught once is mid-
## recovery (slide, re-route: a few seconds). Also counts slides round props + re-routes,
## and feet touching any solid with no margin (props included; 0.77% before
## D14 - _townwalk is the house/inside measure). PASS: pinned 0, stuck per sample <= 2 after 20 s,
## in_solid under 1% (no worse than before).
var _t: Node3D
var _f := 0
var _last := {}
var _prev_stuck := {}
var _pinned := 0
var _stuck_tot := 0
var _stuck_max := 0
var _samples := 0
var _in := 0
var _ex: Array = []

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _dbg(v) -> void:
    var p: Vector3 = v.global_position
    var tgt: Vector3 = v._route[0]
    var dir := Vector3(tgt.x - p.x, 0, tgt.z - p.z).normalized()
    print("DBG ", v.person_name, " p=", p, " tgt=", tgt, " kw(step)=", _t.keep_walkable(p + dir * 0.05), " push=", _t.crowd_push(v), " stuck_t=", v.get("_stuck_t"), " prog_t=", v.get("_prog_t"), " best=", v.get("_best_d"), " cart=", v.get("cart"), " leader=", v.leader, " meta=", v.get_meta_list(), " pm=", v.process_mode, " steps=", v.get("steps"), " role=", v.role, " work=", v.get("work"))
    for r in _t.get("_solid_rects"):
        if (r[0] as Vector2).distance_to(Vector2(p.x, p.z)) < 8.0:
            print("DBG_RECT ", r)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 2:
        _t.get("raids").set("_raid_t", 99999.0)
    if _f > 120 and _f % 30 == 0:
        for v in _t.get("people"):
            if not is_instance_valid(v) or v.inside or not v.visible or v.stay or v.leader != null:
                continue
            if v._route.size() == 1 and v.get("_enter_at") != Vector3.ZERO:
                continue
            _samples += 1
            if not (_t.call("solid_at", v.global_position, 0.0) as Array).is_empty():
                _in += 1
    if _f % 600 == 0:
        var stuck := 0
        var now := {}
        for v in _t.get("people"):
            if not is_instance_valid(v):
                continue
            var p: Vector3 = v.global_position
            if not v.inside and not v.stay and not v._route.is_empty() and v.leader == null \
                    and _last.has(v) and (_last[v] as Vector3).distance_to(p) < 0.3:
                stuck += 1
                now[v] = true
                if _prev_stuck.has(v):
                    _pinned += 1
                    if OS.get_environment("D14_DEBUG") != "" and _ex.size() < 2:
                        _dbg(v)
                    if _ex.size() < 8:
                        _ex.append("%s %s (%.1f,%.1f) next=%s n=%d lod=%d pace=%.2f speed=%.2f phys=%s vis=%s enter=%s wait=%.1f rr=%d" % [v.role, v.person_name, p.x, p.z, str(v._route[0]), v._route.size(), v.lod, v.pace, v.speed, str(v.is_physics_processing()), str(v.visible), str(v.get("_enter_at")), v.get("_wait"), v.get("reroutes")])
            _last[v] = p
        _prev_stuck = now
        if _f > 1200:
            _stuck_tot += stuck
            _stuck_max = maxi(_stuck_max, stuck)
        print("T=", _f / 60, "s stuck_on_route=", stuck)
    if _f >= 7200:
        var sl := 0
        var rr := 0
        for v in _t.get("people"):
            if is_instance_valid(v):
                sl += int(v.get("slides")) if v.get("slides") != null else 0
                rr += int(v.get("reroutes")) if v.get("reroutes") != null else 0
        var pct := 100.0 * float(_in) / maxf(float(_samples), 1.0)
        print("D14 pinned=", _pinned, " stuck_max=", _stuck_max, " stuck_tot=", _stuck_tot, " slides=", sl,
              " reroutes=", rr, " in_solid=%d/%d (%.3f%%)" % [_in, _samples, pct])
        print("PINNED_EX ", _ex)
        print("D14_TEST OK" if _pinned == 0 and _stuck_max <= 2 and pct < 1.0 else "D14_TEST FAIL")
        return true
    return false
