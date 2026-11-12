extends SceneTree
## D16b: the unstick watchdog. The town for 180 s (a raid at 4 s like
## _townwalk); every 0.5 s each walker with a route is sampled, and a walker
## whose feet went under 0.3 m in 6 s while on a route counts as STUCK (three
## watchdog windows - it had every chance to free itself). Prints what such a
## walker was doing so a failure can be read. Run with --fixed-fps 60;
## add `-- --wd-off` for the before figure (watchdog off).
var _t: Node3D
var _f := 0
var _hist := {}          # person -> Array of [frame, pos, route_size]
var _stuck := 0
var _stuck_ids := {}
var _ex: Array = []
var _onroute_samples := 0
const SECS := 180

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--wd-off"):
        Townsfolk.watchdog = false
        print("WATCHDOG OFF (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
    if _f > 120 and _f % 30 == 0:
        for v in _t.get("people"):
            if not is_instance_valid(v):
                continue
            var on_route: bool = not v._route.is_empty() and not v.inside and not v.stay and v.leader == null
            if not on_route:
                _hist.erase(v)
                continue
            _onroute_samples += 1
            var h: Array = _hist.get(v, [])
            h.append([_f, v.global_position, v._route.size()])
            while h.size() > 13:
                h.pop_front()
            _hist[v] = h
            if h.size() == 13:
                var span := 0.0
                for e in h:
                    span = maxf(span, Vector2((e[1] as Vector3).x - (h[0][1] as Vector3).x, (e[1] as Vector3).z - (h[0][1] as Vector3).z).length())
                if span < 0.3:
                    _stuck += 1
                    _stuck_ids[v] = true
                    if _ex.size() < 6:
                        var p: Vector3 = v.global_position
                        _ex.append("%s %s (%.1f,%.1f) lod=%d route=%d next=%s enter=%s wd_n=%d fires=%d proc=%s push=%s" % [v.role, v.person_name, p.x, p.z, v.lod, v._route.size(),
                            str(v._route.slice(0, 3)), str(v._enter_at), v._wd_n, v.wd_fires, str(v.is_physics_processing()), str(_t.call("crowd_push", v))])
                    h.clear()
    if _f % 1800 == 0:
        print("T=", _f / 60, "s stuck_events=", _stuck, " people_stuck=", _stuck_ids.size(), " on_route_samples=", _onroute_samples)
    if _f >= SECS * 60:
        var wd := [0, 0, 0, 0, 0]
        for v in _t.get("people"):
            wd[0] += v.wd_fires
            wd[1] += v.wd_close
            wd[2] += v.wd_repaths
            wd[3] += v.wd_nudges
            wd[4] += v.wd_giveups
        print("WATCHDOG fires=%d close=%d repath=%d nudge=%d giveup=%d" % wd)
        print("EX ", _ex)
        print("D16B_TEST stuck_events=%d people=%d over %d s %s" % [_stuck, _stuck_ids.size(), SECS, "PASS" if _stuck == 0 else "FAIL"])
        return true
    return false
