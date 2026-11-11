extends SceneTree
## HD walking audit: houses on roads, people inside solids, people frozen.
var _t: Node3D
var _f := 0
var _last := {}
var _moved := {}
var _samples := 0
var _in_solid := 0
var _bad: Array = []
## D1: raiders and the defenders fighting them (they are not routed walkers)
var _r_samples := 0
var _r_in := 0
var _houses: Array = []
var _stuck_ex: Array = []
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _inside_rect(p: Vector3, r: Array, shrink: float) -> bool:
    var d := Vector2(p.x, p.z) - (r[0] as Vector2)
    var he: Vector2 = r[3]
    return absf(d.dot(r[1])) < he.x - shrink and absf(d.dot(r[2])) < he.y - shrink

func _house_rects() -> Array:
    var out: Array = []
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
        out.append([Vector2(pp.x, pp.z) + ax * off.x + az * off.y, ax, az, hb[sh][0]])
    return out

func _own_centre(plot: Dictionary) -> Vector2:
    var hb: Dictionary = _t.get("_house_box")
    var sh: String = String(plot.get("shape", "a"))
    if not hb.has(sh):
        return Vector2(INF, INF)
    var yaw: float = float(plot["yaw"])
    var pp: Vector3 = plot["pos"]
    var off: Vector2 = hb[sh][1]
    return Vector2(pp.x, pp.z) + Vector2(cos(yaw), -sin(yaw)) * off.x + Vector2(sin(yaw), cos(yaw)) * off.y

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
        _houses = _house_rects()
    if _f == 30:
        var nav = _t.get("nav")
        # doors: the door spot on walkable street, the door -> inside leg
        # through no other house
        var door_off := 0
        var door_through := 0
        var doors := 0
        for plot in _t.get("plots"):
            if not plot.has("door") or not plot.has("door_in"):
                continue
            doors += 1
            var dp: Vector3 = plot["door"]
            var di: Vector3 = plot["door_in"]
            var dc: Vector3 = nav.closest(dp) if nav else dp
            if Vector2(dc.x - dp.x, dc.z - dp.z).length() > 2.5:
                door_off += 1
            var mine: Vector2 = _own_centre(plot)
            for k in range(1, 10):
                var q := dp.lerp(di, float(k) / 10.0)
                var hitme := false
                for r in _houses:
                    if (r[0] as Vector2).distance_to(mine) < 0.01:
                        continue
                    if _inside_rect(q, r, 0.6):
                        hitme = true
                        break
                if hitme:
                    door_through += 1
                    break
        print("DOORS ", doors, " door_off_ground=", door_off, " door_leg_through_other_house=", door_through)
        _houses = _house_rects()
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
            print("RAID started raiders=", (rd.get("raiders") as Array).size())
    if _f > 240 and _f % 10 == 0:
        var rd2 = _t.get("raids")
        if rd2:
            var nodes: Array = []
            for r in rd2.get("raiders"):
                nodes.append(r["node"])
            for d in (rd2.get("_fighters") as Dictionary).keys():
                nodes.append(d)
            var rects2: Array = _t.get("_solid_rects")
            for n in nodes:
                if not is_instance_valid(n) or not (n as Node3D).visible:
                    continue
                var p2: Vector3 = (n as Node3D).global_position
                _r_samples += 1
                var hit2 := false
                for r in _houses:
                    if _inside_rect(p2, r, 0.6):
                        hit2 = true
                        break
                if not hit2:
                    for r in rects2:
                        if _inside_rect(p2, r, 0.15):
                            hit2 = true
                            break
                if hit2:
                    _r_in += 1
                    if _bad.size() < 12:
                        _bad.append("RAID %s (%.1f,%.1f)" % [n.name, p2.x, p2.z])
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
        var stuck := 0
        for v in _t.get("people"):
            var p: Vector3 = v.global_position
            if v.inside:
                inside += 1
            elif _last.has(v) and (_last[v] as Vector3).distance_to(p) < 0.3:
                still += 1
                if v.stay:
                    stays += 1
                elif not v._route.is_empty():
                    stuck += 1
                    if _stuck_ex.size() < 6:
                        var sr: Array = _t.call("solid_at", p, 0.25)
                        var nc: Vector3 = _t.get("nav").closest(p)
                        _stuck_ex.append("%s %s (%.1f,%.1f) next=%s route=%d solid=%s navoff=%.2f push=%s" % [v.role, v.person_name, p.x, p.z, str(v._route[0]), v._route.size(),
                            str(sr.slice(0, 1)) + str(sr.slice(3, 4)) if not sr.is_empty() else "-", Vector2(nc.x - p.x, nc.z - p.z).length(), str(_t.call("crowd_push", v))])
            else:
                walking += 1
            _last[v] = p
        print("T=", _f / 60, "s walking=", walking, " still=", still, " (posted=", stays, ") inside=", inside,
              " in_solid=", _in_solid, "/", _samples, " stuck_on_route=", stuck)
    if _f >= 4800:
        var pct := 100.0 * float(_in_solid) / maxf(float(_samples), 1.0)
        var rpct := 100.0 * float(_r_in) / maxf(float(_r_samples), 1.0)
        print("TOWNWALK in_solid=%d/%d (%.3f%%) raid_in_solid=%d/%d (%.3f%%) %s" % [_in_solid, _samples, pct, _r_in, _r_samples, rpct,
              "PASS" if pct < 0.2 and rpct < 0.2 else "FAIL"])
        print("BAD ", _bad)
        print("STUCK_EX ", _stuck_ex)
        return true
    return false
