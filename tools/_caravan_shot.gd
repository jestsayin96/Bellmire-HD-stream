extends SceneTree
## A caravan on the west road and at the market; the apothecary's wall shelf.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _shot := {}
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://caravan_%s.png" % nm)
    print("SAVED ", nm)
func _cv() -> Dictionary:
    var cs: Array = _t.get("_caravans")
    return cs[0] if not cs.is_empty() else {}
func _follow(v: Node3D, back: float, up: float) -> void:
    var fw := Vector3(sin(v.rotation.y), 0, cos(v.rotation.y))
    var side := Vector3(-fw.z, 0, fw.x)
    _cam.global_position = v.global_position + fw * back + side * back * 0.6 + Vector3(0, up, 0)
    _cam.look_at(v.global_position + Vector3(0, 1.0, 0) - fw * 1.2, Vector3.UP)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _t.set("_caravan_t", 9999.0)
        _t.call("_caravan")
    var c := _cv()
    if _f > 15 and c.is_empty() and not _shot.has("market"):
        print("NO CARAVAN")
        return true
    if c.is_empty():
        return _f > 40
    var v: Node3D = c["v"]
    if _f == 60:
        _follow(v, 6.0, 3.0)
    if _f == 62:
        _snap("road")
        Engine.time_scale = 6.0
    if _f > 62 and String(c["phase"]) == "trade" and not _shot.has("market"):
        Engine.time_scale = 1.0
        _follow(v, 6.5, 3.5)
        if not _shot.has("m0"):
            _shot["m0"] = _f
        elif _f - int(_shot["m0"]) == 3:
            _snap("market")
            _shot["market"] = true
            # the apothecary shelf, from the yard
            var fr: Array = (_t.get("_shop_frame") as Dictionary).get("apothecary", [])
            if not fr.is_empty():
                var y: Vector3 = fr[0]
                var sd: Vector3 = fr[1]
                var fw: Vector3 = fr[2]
                var focus := y + sd * -1.4 + fw * -3.9
                focus.y = float(_t.call("height_at", focus.x, focus.z)) + 1.0
                _cam.global_position = focus + fw * 3.4 + Vector3(0, 0.9, 0)
                _cam.look_at(focus, Vector3.UP)
            _shot["shelf_at"] = _f + 3
            _t.call("_settle_trade")
    if _shot.has("shelf_at") and _f == int(_shot["shelf_at"]):
        _snap("shelf")
        print("FEEDTAIL ", (_t.get("feed") as Array).slice(-4))
        print("LEVEL ", _t.get("economy").town_level, " ", _t.get("economy").town_name, " score ", _t.get("economy").town_score())
        return true
    return _f > 60 * 200
