extends SceneTree
## HD walking audit: houses on roads, people inside solids, people frozen.
var _t: Node3D
var _f := 0
var _last := {}
var _moved := {}
var _samples := 0
var _in_solid := 0
var _bad: Array = []
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _inside_rect(p: Vector3, r: Array, shrink: float) -> bool:
    var d := Vector2(p.x, p.z) - (r[0] as Vector2)
    var he: Vector2 = r[3]
    return absf(d.dot(r[1])) < he.x - shrink and absf(d.dot(r[2])) < he.y - shrink

func _process(_d: float) -> bool:
    _f += 1
    if _f == 3:
        var nav = _t.get("nav")
        print("NAV ready=", nav.ready_ok if nav else null, " bake_ms=", nav.bake_ms if nav else -1,
              " obstructions=", nav.n_obstructions if nav else 0, " solids=", (_t.get("_solid_rects") as Array).size(),
              " plots=", (_t.get("plots") as Array).size(), " road_dropped=", _t.get("_road_dropped"),
              " people=", (_t.get("people") as Array).size())
        # houses on roads after the fix
        var on_road := 0
        for plot in _t.get("plots"):
            if plot.has("landmark"):
                continue
            if _t.call("_rect_on_road", _t.call("_rect", plot)):
                on_road += 1
        print("HOUSES_ON_ROAD ", on_road)
    if _f > 120 and _f % 30 == 0:
        var houses: Array = []
        var hb: Dictionary = _t.get("_house_box")
        for plot in _t.get("plots"):
            var sh: String = String(plot.get("shape", "a"))
            if not hb.has(sh):
                continue
            var yaw: float = float(plot["yaw"])
            var ax := Vector2(cos(yaw), -sin(yaw))
            var az := Vector2(sin(yaw), cos(yaw))
            var pp: Vector3 = plot["pos"]
            var off: Vector2 = hb[sh][1]
            houses.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, hb[sh][0]])
        var rects: Array = _t.get("_solid_rects")
        for v in _t.get("people"):
            if v.inside or not v.visible:
                continue
            var p: Vector3 = v.global_position
            # standing at a door is not standing in a house: skip near endpoints
            var ends: Array = [v.home, v.work, v.home_in, v.work_in, v._enter_at]
            for st in v.stops:
                ends.append(st[0])
            var near_end := false
            for e in ends:
                if e is Vector3 and e != Vector3.ZERO and Vector2(p.x - e.x, p.z - e.z).length() < 3.0:
                    near_end = true
            if near_end or v._route.is_empty():
                continue
            _samples += 1
            var hit := false
            for r in houses:
                # _rect is inflated ~10% + 0.4 m for eaves: shrink back to walls
                if _inside_rect(p, r, 0.6):
                    hit = true
                    break
            if not hit:
                for r in rects:
                    if _inside_rect(p, r, 0.15):
                        hit = true
                        break
            if hit:
                _in_solid += 1
                if _bad.size() < 8:
                    _bad.append("%s %s (%.1f,%.1f) route=%d next=%s" % [v.role, v.person_name, p.x, p.z, v._route.size(), str(v._route[0]) if not v._route.is_empty() else "-"])
    if _f % 600 == 0:
        var still := 0
        var stays := 0
        var walking := 0
        var inside := 0
        for v in _t.get("people"):
            var p: Vector3 = v.global_position
            if v.inside:
                inside += 1
            elif _last.has(v) and (_last[v] as Vector3).distance_to(p) < 0.3:
                still += 1
                if v.stay:
                    stays += 1
            else:
                walking += 1
            _last[v] = p
        print("T=", _f / 60, "s walking=", walking, " still=", still, " (posted=", stays, ") inside=", inside,
              " in_solid=", _in_solid, "/", _samples)
    if _f >= 4800:
        print("BAD ", _bad)
        return true
    return false
