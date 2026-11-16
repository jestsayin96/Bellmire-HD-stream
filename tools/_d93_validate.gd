extends SceneTree
## D93.5: the authored-town VALIDATOR. Reads a layout file (format
## "bellmire-town/1", default res://data/town/bellmire.json, or JESTS_D93_IN) and
## checks the five rules that make an authored town provably correct:
##   OVERLAP    no two building footprints overlap (oriented rectangles, exact SAT)
##   ON_ROAD    no footprint crosses a road (road = polyline swept by half its width)
##   ON_SQUARE  no footprint stands on the square
##   DOOR       every door touches a road (door within DOOR_TOL of a road's edge)
##   UNREACHED  every door and site joins the road network the square is on
##   PATCH      no ground patch (soil, dirt, cobble) overlaps a road
## Pure data - no scene, no Town - so it runs in a second and can gate CI.
## Prints one D93_VALIDATE line (PASS or FAIL) and the first defects of each kind;
## the full list goes to renders/cycles/d93/validate.txt.
## Optional: JESTS_D93_LEVEL=n checks only what stands at economy level n.

const DOOR_TOL := 2.0       # door to road EDGE, metres (a facade sits 1.5 m off the edge)
const ROAD_TOL := 0.05      # a footprint may kiss a road edge, not cross it
const SHOW := 12

var _roads: Array = []      # [{id, segs: [[a, b]...], hw}]
var _boxes: Array = []      # [{id, c, ax, az, he, door?}]
var _sq: PackedVector2Array

func _initialize() -> void:
    var path := OS.get_environment("JESTS_D93_IN")
    if path == "":
        path = "res://data/town/bellmire.json"
    var txt := FileAccess.get_file_as_string(path)
    var data = JSON.parse_string(txt)
    if typeof(data) != TYPE_DICTIONARY:
        print("D93_VALIDATE FAIL cannot read ", path)
        quit(1)
        return
    var lv_env := OS.get_environment("JESTS_D93_LEVEL")
    var at_lv := int(lv_env) if lv_env != "" else 999
    var stands := func(e: Dictionary) -> bool: return int(e.get("level", 1)) <= at_lv
    for rd in data.get("roads", []):
        if not stands.call(rd):
            continue
        var pts: Array = []
        for p in rd["pts"]:
            pts.append(Vector2(float(p[0]), float(p[1])))
        var segs: Array = []
        if pts.size() == 1:
            segs.append([pts[0], pts[0]])
        for i in range(pts.size() - 1):
            segs.append([pts[i], pts[i + 1]])
        _roads.append({"id": String(rd["id"]), "segs": segs, "hw": float(rd["width"]) * 0.5})
    for p in (data.get("square", {}) as Dictionary).get("poly", []):
        _sq.append(Vector2(float(p[0]), float(p[1])))
    var no_door: Array = []
    for b in data.get("buildings", []):
        if not stands.call(b):
            continue
        var yaw := deg_to_rad(float(b["yaw"]))
        var ax := Vector2(cos(yaw), -sin(yaw))      # local +X on the ground (town.gd _rect)
        var az := Vector2(sin(yaw), cos(yaw))       # local +Z, the street side
        var off: Array = b.get("off", [0.0, 0.0])
        var c := Vector2(float(b["pos"][0]), float(b["pos"][1])) + ax * float(off[0]) + az * float(off[1])
        var e := {"id": String(b["id"]), "c": c, "ax": ax, "az": az,
                  "he": Vector2(float(b["half"][0]), float(b["half"][1])),
                  "tag": String(b.get("landmark", b.get("shop", b.get("shape", ""))))}
        if b.has("door"):
            e["door"] = Vector2(float(b["door"][0]), float(b["door"][1]))
        else:
            no_door.append(e["id"])
        _boxes.append(e)
    var sites: Array = []
    for s in data.get("sites", []):
        if stands.call(s):
            sites.append({"id": String(s["id"]), "p": Vector2(float(s["door"][0]), float(s["door"][1]))})

    var bad := {"OVERLAP": [], "ON_ROAD": [], "ON_SQUARE": [], "DOOR": [], "UNREACHED": [], "PATCH": []}
    # OVERLAP
    for i in _boxes.size():
        for j in range(i + 1, _boxes.size()):
            var pen := _sat(_boxes[i], _boxes[j])
            if pen > 0.0:
                bad["OVERLAP"].append("%s(%s) x %s(%s) by %.2f m" % [_boxes[i]["id"], _boxes[i]["tag"],
                    _boxes[j]["id"], _boxes[j]["tag"], pen])
    # ON_ROAD, ON_SQUARE
    for b in _boxes:
        for rd in _roads:
            var d := _box_road(b, rd)
            if d < -ROAD_TOL:
                bad["ON_ROAD"].append("%s(%s) on %s by %.2f m" % [b["id"], b["tag"], rd["id"], -d])
        if _sq.size() >= 3 and _box_poly(b, _sq):
            bad["ON_SQUARE"].append("%s(%s)" % [b["id"], b["tag"]])
    # DOOR
    for b in _boxes:
        if not b.has("door"):
            continue
        var d := _edge_dist(b["door"])
        if d[0] > DOOR_TOL:
            bad["DOOR"].append("%s(%s) door %.2f m from a road" % [b["id"], b["tag"], d[0]])
    # UNREACHED: roads joined where their swept shapes touch; the square's network is home
    var comp := _components()
    var home := -1
    if _sq.size() >= 3:
        for k in _roads.size():
            if _road_poly(_roads[k], _sq):
                home = comp[k]
                break
    if home < 0 and not _roads.is_empty():
        var count := {}
        for k in comp:
            count[k] = int(count.get(k, 0)) + 1
        var best := -1
        for k in count:
            if best < 0 or int(count[k]) > int(count[best]):
                best = k
        home = best
    var ends: Array = []
    for b in _boxes:
        if b.has("door"):
            ends.append([b["id"], b["door"]])
    for s in sites:
        ends.append([s["id"], s["p"]])
    for en in ends:
        var d := _edge_dist(en[1])
        if d[1] < 0 or d[0] > DOOR_TOL + 1.0 or comp[d[1]] != home:
            bad["UNREACHED"].append("%s (nearest road %s, %.1f m)" % [en[0],
                _roads[d[1]]["id"] if d[1] >= 0 else "-", d[0]])
    # PATCH
    for pt in data.get("patches", []):
        if not stands.call(pt):
            continue
        var poly := PackedVector2Array()
        for p in pt["poly"]:
            poly.append(Vector2(float(p[0]), float(p[1])))
        for rd in _roads:
            if _road_poly(rd, poly):
                bad["PATCH"].append("%s on %s" % [pt.get("id", "?"), rd["id"]])

    var lines: Array = []
    var total := 0
    for k in bad:
        total += (bad[k] as Array).size()
    var head := "D93_VALIDATE %s overlap=%d on_road=%d on_square=%d door=%d unreached=%d patch=%d | roads=%d buildings=%d sites=%d no_door=%d components=%d%s" % [
        "PASS" if total == 0 else "FAIL", bad["OVERLAP"].size(), bad["ON_ROAD"].size(),
        bad["ON_SQUARE"].size(), bad["DOOR"].size(), bad["UNREACHED"].size(), bad["PATCH"].size(),
        _roads.size(), _boxes.size(), sites.size(), no_door.size(), _ncomp(comp),
        (" level<=%d" % at_lv) if at_lv < 999 else ""]
    print(head)
    lines.append(head)
    for k in bad:
        var arr: Array = bad[k]
        for i in arr.size():
            if i < SHOW:
                print("  ", k, " ", arr[i])
            lines.append("%s %s" % [k, arr[i]])
    if not no_door.is_empty():
        lines.append("NO_DOOR " + ", ".join(PackedStringArray(no_door)))
    var rp := ProjectSettings.globalize_path("res://renders/cycles/d93")
    DirAccess.make_dir_recursive_absolute(rp)
    var fa := FileAccess.open(rp + "/validate.txt", FileAccess.WRITE)
    if fa:
        fa.store_string("\n".join(PackedStringArray(lines)) + "\n")
        fa.close()
    quit(0 if total == 0 else 1)

## ------------------------------------------------------------------ geometry
func _corners(b: Dictionary) -> PackedVector2Array:
    var c: Vector2 = b["c"]
    var x: Vector2 = b["ax"] * (b["he"] as Vector2).x
    var z: Vector2 = b["az"] * (b["he"] as Vector2).y
    return PackedVector2Array([c - x - z, c + x - z, c + x + z, c - x + z])

## separating-axis test on two oriented rectangles: the smallest penetration, or 0
func _sat(a: Dictionary, b: Dictionary) -> float:
    var ca := _corners(a)
    var cb := _corners(b)
    var best := INF
    for axis in [a["ax"], a["az"], b["ax"], b["az"]]:
        var amin := INF
        var amax := -INF
        var bmin := INF
        var bmax := -INF
        for p in ca:
            var d: float = p.dot(axis)
            amin = minf(amin, d)
            amax = maxf(amax, d)
        for p in cb:
            var d: float = p.dot(axis)
            bmin = minf(bmin, d)
            bmax = maxf(bmax, d)
        var o := minf(amax, bmax) - maxf(amin, bmin)
        if o <= 0.0:
            return 0.0
        best = minf(best, o)
    return best

func _seg_pt(p: Vector2, a: Vector2, b: Vector2) -> float:
    return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))

func _seg_seg(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
    if a.distance_to(b) > 0.0001 and c.distance_to(d) > 0.0001 and Geometry2D.segment_intersects_segment(a, b, c, d) != null:
        return 0.0
    return minf(minf(_seg_pt(a, c, d), _seg_pt(b, c, d)), minf(_seg_pt(c, a, b), _seg_pt(d, a, b)))

## signed clearance between a footprint and a road: negative = the road crosses it
func _box_road(b: Dictionary, rd: Dictionary) -> float:
    var poly := _corners(b)
    var best := INF
    for sg in rd["segs"]:
        var a: Vector2 = sg[0]
        var e: Vector2 = sg[1]
        if Geometry2D.is_point_in_polygon(a, poly) or Geometry2D.is_point_in_polygon(e, poly):
            return -float(rd["hw"])
        for i in 4:
            best = minf(best, _seg_seg(a, e, poly[i], poly[(i + 1) % 4]))
    return best - float(rd["hw"])

func _box_poly(b: Dictionary, poly: PackedVector2Array) -> bool:
    return not Geometry2D.intersect_polygons(_corners(b), poly).is_empty()

## does a road's swept shape touch a polygon
func _road_poly(rd: Dictionary, poly: PackedVector2Array) -> bool:
    var hw: float = rd["hw"]
    for sg in rd["segs"]:
        if Geometry2D.is_point_in_polygon(sg[0], poly) or Geometry2D.is_point_in_polygon(sg[1], poly):
            return true
        for i in poly.size():
            if _seg_seg(sg[0], sg[1], poly[i], poly[(i + 1) % poly.size()]) < hw:
                return true
    return false

## [distance from p to the nearest road edge (0 if on a road), that road's index]
func _edge_dist(p: Vector2) -> Array:
    var best := INF
    var at := -1
    for k in _roads.size():
        for sg in _roads[k]["segs"]:
            var d := maxf(0.0, _seg_pt(p, sg[0], sg[1]) - float(_roads[k]["hw"]))
            if d < best:
                best = d
                at = k
    return [best, at]

func _components() -> Array:
    var parent: Array = []
    for k in _roads.size():
        parent.append(k)
    var find := func(f: Callable, x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for i in _roads.size():
        for j in range(i + 1, _roads.size()):
            var reach: float = float(_roads[i]["hw"]) + float(_roads[j]["hw"])
            var touch := false
            for s1 in _roads[i]["segs"]:
                for s2 in _roads[j]["segs"]:
                    if _seg_seg(s1[0], s1[1], s2[0], s2[1]) < reach:
                        touch = true
                        break
                if touch:
                    break
            if touch:
                var ri: int = find.call(find, i)
                var rj: int = find.call(find, j)
                if ri != rj:
                    parent[ri] = rj
    var out: Array = []
    for k in _roads.size():
        out.append(find.call(find, k))
    return out

func _ncomp(comp: Array) -> int:
    var s := {}
    for c in comp:
        s[c] = true
    return s.size()
