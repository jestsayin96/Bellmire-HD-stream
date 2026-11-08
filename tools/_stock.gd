extends SceneTree
## Stock piles: smithy ore, armourer gear, apothecary potions - before and
## after a delve's haul comes home. FAKE data, nothing posted.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _shots := []
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _frame(kind: String, near: float) -> void:
    var fr: Array = (_t.get("_shop_frame") as Dictionary).get(kind, [])
    if fr.is_empty():
        print("NO FRAME ", kind)
        return
    var y: Vector3 = fr[0]
    var side: Vector3 = fr[1]
    var f: Vector3 = fr[2]
    var focus: Vector3
    match kind:
        "blacksmith": focus = y + side * -2.9 + f * -1.3
        "armorer": focus = y + side * -2.3 + f * -1.4
        _: focus = y + side * -0.6 + f * -3.4
    focus.y = float(_t.call("height_at", focus.x, focus.z)) + 0.3
    # steep, from the street side: clears fences, folk and signboards
    var cp := focus + f * near * 0.55 + side * near * 0.25
    cp.y = focus.y + near
    _cam.global_position = cp
    _cam.look_at(focus, Vector3.UP)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://stock_%s.png" % nm)
    print("SAVED ", nm, " stock ", (_t.get("economy") as Economy).stock)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 50.0
        print("FRAMES ", (_t.get("_shop_frame") as Dictionary).keys())
    var plan := [[40, "blacksmith", 5.0, "ore_before"], [60, "armorer", 5.5, "gear_before"], [80, "apothecary", 3.6, "potion_before"]]
    for pl in plan:
        if _f == int(pl[0]) - 10:
            _frame(String(pl[1]), float(pl[2]))
        if _f == int(pl[0]):
            _snap(String(pl[3]))
    if _f == 90:
        _t.call("receive_haul", {"ore": 30.0, "stone": 6.0, "gear": 3.0, "potion": 5.0})
    var plan2 := [[120, "blacksmith", 5.0, "ore_after"], [140, "armorer", 5.5, "gear_after"], [160, "apothecary", 3.6, "potion_after"]]
    for pl in plan2:
        if _f == int(pl[0]) - 10:
            _frame(String(pl[1]), float(pl[2]))
        if _f == int(pl[0]):
            _snap(String(pl[3]))
    return _f > 165
