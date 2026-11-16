extends SceneTree
## D16c: dynamic obstacles. Every prop in town with a body (a stall, a cart, a
## bench, a fence, a barrel - anything instanced from the prop kits that stands
## >= 0.35 m and is wider than 0.4 m) is found FROM THE SCENE TREE, not from the
## town's own footprint list, so a prop the town forgot to register counts too.
## The wagons that move (carters, travellers, the pedlar) are re-measured at
## every sample. The town runs SECS s (a raid at 4 s like _townwalk); every
## 0.25 s each walker out of doors (townsfolk, heroes, the watch, riders,
## animals, raiders) is tested:
##   THROUGH  - the feet inside a prop's footprint (shrunk 0.12 m so brushing an
##              edge is not counted). Counted once per walker+prop meeting.
##   STUCK    - on a route, under 0.3 m in 6 s, within 0.6 m of a prop (6 s =
##              three D16b watchdog windows, the D16b test's own bar; a 4 s
##              pause - freed on the watchdog's second try - is printed as
##              PAUSE4 for information).
## A carter and his own wagon are not a meeting. Static audit first: props
## with a body that are NOT in town._solid_rects (the navmesh / solid_at list).
## Run with --fixed-fps 60; `-- --dyn-off` turns D16c off (the before figure).
var _t: Node3D
var _f := 0
const SECS := 150
const KITS := ["res://assets/props/", "res://assets/mkprops/", "res://assets/fishing/"]
var _static: Array = []          # prop nodes that stand still
var _wagons: Array = []          # moving: nodes
var _grid: Dictionary = {}       # 4 m cells -> [rect]
var _through := 0
var _through_samples := 0
var _meet: Dictionary = {}       # "walker/prop" -> last frame inside
var _ex: Array = []
var _by_prop: Dictionary = {}
var _hist: Dictionary = {}
var _stuck := 0
var _stuck_ex: Array = []
var _pause4 := 0
var _samples := 0

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--dyn-off"):
        print("D16C OFF (before)")
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    if OS.get_cmdline_user_args().has("--dyn-off") and "dyn_obstacles" in _t:
        _t.set("dyn_obstacles", false)

## the prop's footprint as town._solid_of measures it, in world space
## [centre, ax, az, half extents, name] or [] for flat / tiny things
func _rect_of(n: Node3D) -> Array:
    var box := AABB()
    var first := true
    var inv := n.global_transform.affine_inverse()
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var ab: AABB = (inv * (c as MeshInstance3D).global_transform) * (c as MeshInstance3D).get_aabb()
            box = ab if first else box.merge(ab)
            first = false
        for g in c.get_children():
            st.append(g)
    if first:
        return []
    var sc := n.global_transform.basis.get_scale().x
    var he := Vector2(box.size.x, box.size.z) * 0.5 * sc
    if box.size.y * sc < 0.35 or maxf(he.x, he.y) < 0.2:
        return []
    var b := n.global_transform.basis.orthonormalized()
    var ax := Vector2(b.x.x, b.x.z).normalized()
    var az := Vector2(b.z.x, b.z.z).normalized()
    var cen := box.get_center() * sc
    var c2 := Vector2(n.global_position.x, n.global_position.z) + ax * cen.x + az * cen.z
    return [c2, ax, az, he, String(n.name)]

func _is_kit(n: Node) -> bool:
    var sp := n.scene_file_path
    if sp == "":
        return false
    for k in KITS:
        if sp.begins_with(k):
            return true
    return false

func _collect() -> void:
    var carts := {}
    for v in _t.get("people"):
        if is_instance_valid(v) and v.cart and is_instance_valid(v.cart):
            carts[v.cart] = true
    var st: Array = [_t]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Townsfolk or c.get("float_y") != null:
            continue
        if c is Node3D and _is_kit(c):
            if not carts.has(c):
                _static.append(c)
            continue
        for g in c.get_children():
            st.append(g)
    for k in carts.keys():
        _wagons.append(k)

func _registered(r: Array) -> bool:
    var c: Vector2 = r[0]
    for s in _t.get("_solid_rects"):
        if (s[0] as Vector2).distance_to(c) < 0.6:
            return true
    return false

func _audit() -> void:
    var unreg := {}
    var n_body := 0
    for n in _static:
        var r := _rect_of(n)
        if r.is_empty():
            continue
        n_body += 1
        if not _registered(r):
            var nm: String = (n as Node).scene_file_path.get_file().get_basename()
            unreg[nm] = int(unreg.get(nm, 0)) + 1
    var tot := 0
    for k in unreg:
        tot += int(unreg[k])
    print("D16C_AUDIT props_with_body=%d unregistered=%d moving_wagons=%d %s" % [n_body, tot, _wagons.size(), str(unreg)])

func _add(r: Array) -> void:
    var c: Vector2 = r[0]
    var he: Vector2 = r[3]
    var e := he.length() + 0.7
    for gx in range(floori((c.x - e) / 4.0), floori((c.x + e) / 4.0) + 1):
        for gz in range(floori((c.y - e) / 4.0), floori((c.y + e) / 4.0) + 1):
            var k := Vector2i(gx, gz)
            if not _grid.has(k):
                _grid[k] = []
            (_grid[k] as Array).append(r)

func _build_grid() -> void:
    _grid.clear()
    for n in _static + _wagons:
        if is_instance_valid(n) and (n as Node3D).is_visible_in_tree():
            var r := _rect_of(n)
            if not r.is_empty():
                r.append(n)
                _add(r)

## how deep p stands inside a rect (< 0 = outside)
func _depth(p: Vector3, r: Array) -> float:
    var d := Vector2(p.x, p.z) - (r[0] as Vector2)
    var he: Vector2 = r[3]
    return minf(he.x - absf(d.dot(r[1])), he.y - absf(d.dot(r[2])))

func _walkers() -> Array:
    var out: Array = []
    for v in _t.get("people"):
        if is_instance_valid(v) and (v as Node3D).visible and not v.inside:
            out.append(v)
    for c in _t.get("cavalry"):
        if is_instance_valid(c) and (c as Node3D).visible:
            out.append(c)
    for a in _t.get("animals"):
        if is_instance_valid(a) and (a as Node3D).visible and float(a.get("float_y")) == INF:
            out.append(a)
    var rd = _t.get("raids")
    if rd:
        for r in rd.get("raiders"):
            if is_instance_valid(r["node"]) and (r["node"] as Node3D).visible:
                out.append(r["node"])
    return out

func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        _collect()
        _audit()
    if _f == 240:
        var rd = _t.get("raids")
        if rd:
            rd.force_level = 5
            rd.call("raid", "west")
    if _f > 120 and _f % 15 == 0:
        # carts sent out later (valley travellers) join the moving list
        for v in _t.get("people"):
            if is_instance_valid(v) and v.cart and is_instance_valid(v.cart) and not _wagons.has(v.cart):
                _wagons.append(v.cart)
        _build_grid()
        for v in _walkers():
            var p: Vector3 = (v as Node3D).global_position
            _samples += 1
            var own = v.get("cart")
            var cell = _grid.get(Vector2i(floori(p.x / 4.0), floori(p.z / 4.0)))
            var near := false
            var near_nm := ""
            if cell != null:
                for r in cell:
                    if not is_instance_valid(r[5]) or absf((r[5] as Node3D).global_position.y - p.y) > 2.5:
                        continue
                    if own != null and r[5] == own:
                        continue
                    var dep := _depth(p, r)
                    if dep > -0.6:
                        near = true
                        near_nm = (r[5] as Node).scene_file_path.get_file().get_basename() + ("(moving)" if _wagons.has(r[5]) else "")
                    if dep > 0.12:
                        _through_samples += 1
                        var key := "%d/%d" % [v.get_instance_id(), (r[5] as Node).get_instance_id()]
                        if _f - int(_meet.get(key, -1000)) > 60:
                            _through += 1
                            var nm: String = (r[5] as Node).scene_file_path.get_file().get_basename()
                            _by_prop[nm] = int(_by_prop.get(nm, 0)) + 1
                            if _ex.size() < 14:
                                var who: String = String(v.get("role")) + " " + String(v.get("person_name")) if v.get("role") != null else (v.get_script().resource_path.get_file() if v.get_script() else v.get_class())
                                _ex.append("%s in %s (%.1f,%.1f) depth=%.2f T=%d" % [who, nm, p.x, p.z, dep, _f / 60])
                        _meet[key] = _f
            # STUCK by a prop: on a route, under 0.3 m over 4 s
            var rt = v.get("_route")
            var on_route: bool = rt != null and not (rt as Array).is_empty() and not bool(v.get("stay")) and v.get("leader") == null
            if not on_route:
                _hist.erase(v)
                continue
            var h: Array = _hist.get(v, [])
            h.append(p)
            while h.size() > 25:
                h.pop_front()
            _hist[v] = h
            if h.size() >= 17 and near:
                var s4 := 0.0
                for i in range(h.size() - 17, h.size()):
                    s4 = maxf(s4, Vector2((h[i] as Vector3).x - (h[h.size() - 17] as Vector3).x, (h[i] as Vector3).z - (h[h.size() - 17] as Vector3).z).length())
                if s4 < 0.3 and v.get_meta("d16c_p4", -1000) < _f - 240:
                    _pause4 += 1
                    v.set_meta("d16c_p4", _f)
            if h.size() == 25:
                var span := 0.0
                for e in h:
                    span = maxf(span, Vector2((e as Vector3).x - (h[0] as Vector3).x, (e as Vector3).z - (h[0] as Vector3).z).length())
                if span < 0.3 and near:
                    _stuck += 1
                    if _stuck_ex.size() < 8:
                        _stuck_ex.append("%s %s (%.1f,%.1f) T=%d by %s route=%d next=%s" % [v.get("role"), v.get("person_name"), p.x, p.z, _f / 60, near_nm, (rt as Array).size(), str((rt as Array)[0])])
                    h.clear()
    if _f % 1800 == 0:
        print("T=", _f / 60, "s through=", _through, " (samples ", _through_samples, "/", _samples, ") stuck_by_prop=", _stuck, " wagons=", _wagons.size())
    if _f >= SECS * 60:
        print("BY_PROP ", _by_prop)
        print("EX ", _ex)
        print("STUCK_EX ", _stuck_ex)
        print("PAUSE4 %d (on a route, under 0.3 m for 4 s by a prop - information)" % _pause4)
        print("D16C_TEST through=%d stuck_by_prop=%d samples=%d over %d s %s" % [_through, _stuck, _samples, SECS,
              "PASS" if _through == 0 and _stuck == 0 else "FAIL"])
        return true
    return false
