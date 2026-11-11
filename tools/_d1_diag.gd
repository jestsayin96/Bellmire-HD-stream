extends SceneTree
## D1 diagnostic: solid footprints the navmesh did not carve
var _t: Node3D
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)

func _on(nav, x: float, z: float) -> float:
    var c: Vector3 = nav.closest(Vector3(x, 0, z))
    return Vector2(c.x - x, c.z - z).length()

func _process(_d: float) -> bool:
    _f += 1
    if _f < 20:
        return false
    var nav = _t.get("nav")
    var rects: Array = _t.get("_solid_rects")
    var unc := 0
    var ex: Array = []
    for r in rects:
        var c: Vector2 = r[0]
        if _on(nav, c.x, c.y) < 0.05:
            unc += 1
            if ex.size() < 10:
                ex.append("(%.1f,%.1f) he=%s" % [c.x, c.y, str(r[3])])
    print("RECTS ", rects.size(), " uncarved_centres=", unc, " ", ex)
    var hb: Dictionary = _t.get("_house_box")
    var hu := 0
    var hex: Array = []
    for plot in _t.get("plots"):
        var sh: String = String(plot.get("shape", "a"))
        if not hb.has(sh):
            continue
        var yaw: float = float(plot["yaw"])
        var pp: Vector3 = plot["pos"]
        var off: Vector2 = hb[sh][1]
        var c2 := Vector2(pp.x, pp.z) + Vector2(cos(yaw), -sin(yaw)) * off.x + Vector2(sin(yaw), cos(yaw)) * off.y
        if _on(nav, c2.x, c2.y) < 0.05:
            hu += 1
            hex.append("%s (%.1f,%.1f)" % [String(plot.get("landmark", plot.get("shop", sh))), c2.x, c2.y])
        if plot.has("door"):
            var dp: Vector3 = plot["door"]
            if hex.size() < 40:
                hex.append("door %.2f" % _on(nav, dp.x, dp.z))
    print("HOUSES uncarved=", hu, " ", hex)
    var t0 := Time.get_ticks_usec()
    for i in range(1000):
        nav.closest(Vector3(randf_range(-80, 80), 0, randf_range(-80, 80)))
    print("CLOSEST_US ", float(Time.get_ticks_usec() - t0) / 1000.0, " polys=", nav.navigation_mesh.get_polygon_count())
    print("MARKET ", _t.get("_market_pos"))
    return true
