extends SceneTree
## D44c probe: who stands still on a route near the (74,-63.5) hotspot, and why.
## Same boot and raid timing as _townwalk.gd; prints each walker's leg state.
var _t: Node3D
var _f := 0
var _last := {}
var _n := 0
const SPOT := Vector3(74.0, 0.0, -63.5)
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _process(_d: float) -> bool:
    _f += 1
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
    if _f > 120 and _f % 120 == 0:
        for v in _t.get("people"):
            var p: Vector3 = v.global_position
            if v.inside or v._route.is_empty():
                _last[v] = p
                continue
            if Vector2(p.x - SPOT.x, p.z - SPOT.z).length() < 4.0 and _last.has(v) and (_last[v] as Vector3).distance_to(p) < 0.3:
                _n += 1
                if _n <= 12:
                    var near: Array = []
                    for o in _t.get("people"):
                        if o != v and not o.inside and o.visible and (o.global_position as Vector3).distance_to(p) < 2.2:
                            near.append("%s/%s stay=%s route=%d" % [o.role, o.person_name, str(o.stay), o._route.size()])
                    print("D44C f=%d %s %s (%.2f,%.2f) route=%d r0=%s back=%s flee=%s raid=%s enter=%s door_out=%s seat=%d wait=%.1f lod=%d leader=%s prog=%.2f best=%.2f rer=%d wd_n=%d near=%s" % [
                        _f, v.role, v.person_name, p.x, p.z, v._route.size(), str(v._route[0]), str(v._route.back()), str(v._fleeing),
                        str(_t.call("is_raid_on")), str(v._enter_at), str(v._door_out), v._seat_i, v._wait, v.lod, str(v.leader != null),
                        v._prog_t, v._best_d, v._rerouted, v._wd_n, str(near)])
            _last[v] = p
    if _f >= 7300:
        print("D44C_DONE stuck_samples=%d" % _n)
        quit()
    return false
