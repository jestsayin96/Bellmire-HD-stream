extends SceneTree
## FAKE CHAT FEED - nothing posted. Four heroes go into the scar with one flask
## each (a short delve), then: the party climbing out of the mouth, and the
## party home on the square, with the chronicle HUD on screen.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _ended := -1
var _done := 0
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://return_%s.png" % nm)
    print("SAVED ", nm)
func _bodies() -> Array:
    var out: Array = []
    var hs: Dictionary = _t.get("heroes")
    for v in V:
        var b = hs.get(v[0])
        if b and is_instance_valid(b) and (b as Node3D).visible:
            out.append(b)
    return out
func _mid(bs: Array) -> Vector3:
    var c := Vector3.ZERO
    for b in bs:
        c += (b as Node3D).global_position
    return c / maxf(1.0, float(bs.size()))
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        var ids := []
        for v in V:
            _t.call("chat_line", v[0], v[1], "!enlist " + v[2])
            var h: Dictionary = _t.get("roster").get_hero(v[0])
            h["oil"] = 1
            h["weapon"] = 3
            h["armour"] = 3
            ids.append(v[0])
        (_t.get("_at_mouth") as Array).append_array(ids)
        _t.call("_begin_delve")
        var dv = _t.get("delve")
        dv.ended.connect(func(_s): _ended = _f)
        Engine.time_scale = 5.0
    if _f > 20 and _ended < 0:
        if _f > 20 + 60 * 120:
            print("GAVE UP")
            return true
        return false
    if _ended > 0 and _f == _ended + 1:
        Engine.time_scale = 1.0
    if _ended > 0 and _f >= _ended + 2 and _f <= _ended + 70:
        var bs := _bodies()
        var sc: Dictionary = _t.call("stats").get("scar", {})
        var mo: Vector3 = sc.get("mouth", _mid(bs))
        var fw: Vector3 = sc.get("fwd", Vector3(0, 0, 1))
        var c := _mid(bs) if not bs.is_empty() else mo
        var pos := c + fw * 13.0 + Vector3(-fw.z, 0, fw.x) * 3.0
        pos.y = c.y + 9.0
        _cam.global_position = pos
        _cam.look_at(c.lerp(mo, 0.4) + Vector3(0, 0.8, 0), Vector3.UP)
        if _f == _ended + 70:
            print("CAM mouth ", pos, " party ", c, " n=", bs.size())
            _snap("mouth")
            Engine.time_scale = 6.0
    if _ended > 0 and _f > _ended + 70:
        var bs := _bodies()
        var walking := 0
        for b in bs:
            if not (b as HeroBody)._route.is_empty():
                walking += 1
        if (walking == 0 and _f > _ended + 400) or _f > _ended + 60 * 60:
            if _done == 0:
                _done = _f
                Engine.time_scale = 1.0
        if _done > 0:
            var m: Vector3 = _t.get("_market_pos")
            _cam.global_position = m + Vector3(0, 7.0, 15.0)
            _cam.look_at(m + Vector3(0, 1.0, 0), Vector3.UP)
            if _f == _done + 30:
                print("SQUARE walking=", walking, " n=", bs.size())
                _snap("square")
                return true
    return false
