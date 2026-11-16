extends SceneTree
## D93 stage 1: snapshot the town the generator builds TODAY into the authored
## layout format (data/town/bellmire.json, format "bellmire-town/1").
##
## This is a STARTING POINT for hand authoring, not the authored town. It is
## what is drawn now, collisions and all - tools/_d93_validate.gd then lists every
## defect so the layout can be corrected by hand, in the data, where it is
## diffable and reviewable. Nothing in the game reads this file yet (the loader
## is D93.4). Re-running this tool OVERWRITES the file, so once hand edits begin
## run it only with JESTS_D93_OUT pointing somewhere else.
##
## Levels are ECONOMY levels 1..12 (economy.TOWN_LEVELS, Mr. E: "aim for 12").
## growth.gd today has six visual stages and maps two economy tiers per stage,
## so a house that stands from stage g is tagged level 2g-1.
var _t: Node3D
var _f := 0

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _r(v: float) -> float:
    return snappedf(v, 0.01)

func _xz(p: Vector3) -> Array:
    return [_r(p.x), _r(p.z)]

func _process(_dt: float) -> bool:
    _f += 1
    if _f < 5:
        return false
    var out := {
        "format": "bellmire-town/1",
        "levels": 12,
        "units": "metres; positions are [x, z] on the ground plane; yaw in degrees, 0 = facing +Z",
        "source": "exported from the town generator by tools/_d93_export.gd (D93 stage 1) - a baseline to hand-correct, not yet the authored town",
        "roads": _roads(),
        "square": _square(),
        "buildings": _buildings(),
        "sites": _sites(),
        "patches": [],
    }
    var path := OS.get_environment("JESTS_D93_OUT")
    if path == "":
        path = "res://data/town/bellmire.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var fa := FileAccess.open(path, FileAccess.WRITE)
    fa.store_string(JSON.stringify(out, "  ", false) + "\n")
    fa.close()
    print("D93_EXPORT roads=%d buildings=%d sites=%d square_pts=%d -> %s" % [
        (out["roads"] as Array).size(), (out["buildings"] as Array).size(),
        (out["sites"] as Array).size(), ((out["square"] as Dictionary)["poly"] as Array).size(), path])
    return true

## Road segments chained into polylines through every node of degree two, so a
## street reads as one line in the file instead of a dozen hex-to-hex stubs.
func _roads() -> Array:
    var segs: Array = []
    var pins: Array = []                 # zero-length segs: paved patches at lone road cells
    for sg in _t.get("_road_segs"):
        var a: Vector3 = sg[0]
        var b: Vector3 = sg[1]
        if Vector2(a.x - b.x, a.z - b.z).length() < 0.01:
            pins.append(sg)
        else:
            segs.append(sg)
    var key := func(p: Vector3, w: float) -> String:
        return "%d,%d|%d" % [roundi(p.x * 10.0), roundi(p.z * 10.0), roundi(w * 100.0)]
    var adj := {}                        # node key -> [seg index...]
    for i in segs.size():
        for e in [0, 1]:
            var k: String = key.call(segs[i][e], float(segs[i][2]))
            if not adj.has(k):
                adj[k] = []
            (adj[k] as Array).append(i)
    var used := {}
    var out: Array = []
    var walk := func(i: int, from_end: int) -> Array:
        # follow seg i starting at its from_end, through degree-2 nodes
        var pts: Array = [segs[i][from_end]]
        var cur := i
        var at := 1 - from_end
        while true:
            used[cur] = true
            var p: Vector3 = segs[cur][at]
            pts.append(p)
            var k: String = key.call(p, float(segs[cur][2]))
            var nb: Array = adj.get(k, [])
            if nb.size() != 2:
                break
            var nxt: int = nb[0] if nb[1] == cur else nb[1]
            if used.has(nxt):
                break
            var nk0: String = key.call(segs[nxt][0], float(segs[nxt][2]))
            at = 1 if nk0 == k else 0
            cur = nxt
        return pts
    # start at ends and junctions first, then sweep any closed loops
    for i in segs.size():
        if used.has(i):
            continue
        for e in [0, 1]:
            var k: String = key.call(segs[i][e], float(segs[i][2]))
            if (adj[k] as Array).size() != 2 and not used.has(i):
                out.append({"pts": walk.call(i, e), "half_width": _r(float(segs[i][2]))})
    for i in segs.size():
        if not used.has(i):
            out.append({"pts": walk.call(i, 0), "half_width": _r(float(segs[i][2]))})
    var roads: Array = []
    var n := 0
    for rd in out:
        n += 1
        var pts: Array = []
        for p in rd["pts"]:
            pts.append(_xz(p))
        roads.append({"id": "road_%03d" % n, "pts": pts, "width": _r(float(rd["half_width"]) * 2.0),
                      "level": 1})
    # a lone paved cell no segment already covers
    for sg in pins:
        var p: Vector3 = sg[0]
        var covered := false
        for s2 in segs:
            if _t.call("_seg_dist", p, s2[0], s2[1]) < float(s2[2]) * 0.5:
                covered = true
                break
        if not covered:
            n += 1
            roads.append({"id": "road_%03d" % n, "pts": [_xz(p)], "width": _r(float(sg[2]) * 2.0), "level": 1})
    return roads

## The square as drawn: the convex hull of the paving quads over the square cells.
func _square() -> Dictionary:
    var pts := PackedVector2Array()
    var hw: float = Hex.COL_W * 1.1 * 0.5
    var hd: float = Hex.ROW_H * 1.25 * 0.5
    for cell in _t.get("square"):
        var c: Vector3 = Hex.pos(cell.x, cell.y)
        for s in [Vector2(-hw, -hd), Vector2(hw, -hd), Vector2(hw, hd), Vector2(-hw, hd)]:
            pts.append(Vector2(c.x, c.z) + s)
    var hull := Geometry2D.convex_hull(pts)
    var poly: Array = []
    for i in range(hull.size() - 1):        # convex_hull repeats the first point
        poly.append([_r(hull[i].x), _r(hull[i].y)])
    var mp: Vector3 = _t.get("_market_pos")
    return {"id": "square", "poly": poly, "centre": _xz(mp), "level": 1}

func _buildings() -> Array:
    var hb: Dictionary = _t.get("_house_box")
    var growth = _t.get("growth")
    var specs: Array = []                # [plot, key] - matched by identity, not by value
    var unlock: Dictionary = {}
    if growth != null:
        unlock = growth.get_script().get_script_constant_map().get("UNLOCK", {})
        for k in growth.specials:
            specs.append([(growth.specials[k] as Dictionary)["plot"], String(k)])
    var out: Array = []
    var n := 0
    for plot in _t.get("plots"):
        if not plot.has("node") or not is_instance_valid(plot["node"]):
            continue
        n += 1
        var sh: String = String(plot.get("shape", "a"))
        var node: Node3D = plot["node"]
        var half := Vector2(5.0, 5.0)
        var off := Vector2.ZERO
        if hb.has(sh):
            half = hb[sh][0]
            off = hb[sh][1]
        half = Vector2(half.x * node.scale.x, half.y * node.scale.z)
        off = Vector2(off.x * node.scale.x, off.y * node.scale.z)
        var lv := 1
        if plot.has("grow"):
            lv = 2 * int(plot["grow"]) - 1
        var e := {
            "id": "b%03d" % n,
            "shape": sh,
            "district": String(plot.get("district", "")),
            "pos": _xz(plot["pos"]),
            "yaw": _r(rad_to_deg(float(plot["yaw"]))),
            "half": [_r(half.x), _r(half.y)],
            "off": [_r(off.x), _r(off.y)],
            "level": lv,
        }
        if plot.has("door"):
            e["door"] = _xz(plot["door"])
        if plot.has("back"):
            e["back"] = true
        if plot.has("landmark"):
            e["landmark"] = String(plot["landmark"])
        if plot.has("shop"):
            e["shop"] = String(plot["shop"])
        for sp in specs:
            if is_same(sp[0], plot):
                var key: String = sp[1]
                e["special"] = key
                e["special_level"] = 2 * int(unlock.get(key, 1)) - 1
        out.append(e)
    return out

func _sites() -> Array:
    var out: Array = []
    var n := 0
    for s in _t.get("_sites"):
        n += 1
        out.append({"id": "site_%03d" % n, "landmark": String(s.get("landmark", "")),
                    "door": _xz(s["door"]), "level": 1})
    return out
