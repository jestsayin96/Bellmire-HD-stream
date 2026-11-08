extends SceneTree
## Night raid at the west gate; then a viewers' party climbing out at dawn.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _rd: Raids
var _phase := 0
var _mark := -1
var _hour := 22.5
var _ended := -1
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://soak_%s.png" % nm)
    print("SAVED ", nm, " hour=", snappedf(_t.get("economy").hour(), 0.1))
func _process(_d: float) -> bool:
    _f += 1
    var eco: Economy = _t.get("economy")
    if eco:
        eco.clock = _hour / 24.0          # the hour is held for each shot
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _rd = _t.get("raids")
        _rd.force_level = 3
        _rd.set("_raid_t", 99999.0)
        _t.get("adventurers").set("_party_t", 99999.0)
        _rd.raid("road")
        Engine.time_scale = 3.0
    if _f < 16:
        return false
    if _phase == 0:
        for r in _rd.raiders:
            var tg = r["target"]
            if tg != null and is_instance_valid(tg) and _rd._flat((r["node"] as Node3D).global_position, (tg as Node3D).global_position) < 2.5:
                Engine.time_scale = 1.0
                var c := ((r["node"] as Node3D).global_position + (tg as Node3D).global_position) * 0.5
                var gw: Vector3 = _t.call("_gate", -1.0)
                var outw := Vector3(gw.x, 0, gw.z).normalized()
                var side := Vector3(-outw.z, 0, outw.x)
                _cam.global_position = c + side * 7.0 - outw * 3.5 + Vector3(0, 4.5, 0)
                _cam.look_at(c + Vector3(0, 1.0, 0), Vector3.UP)
                _phase = 1
                _mark = _f + 8
                break
    elif _phase == 1 and _f == _mark:
        _snap("night_raid")
        # the viewers' party: straight to the mouth, one flask each (a short delve)
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
        (_t.get("delve") as Delve).ended.connect(func(_s): _ended = _f)
        Engine.time_scale = 5.0
        _phase = 2
    elif _phase == 2 and _ended > 0:
        Engine.time_scale = 1.0
        _hour = 6.8                       # they climb out as the sun comes up
        _phase = 3
        _mark = _f + 70
    if _phase == 3:
        var hs: Dictionary = _t.get("heroes")
        var c := Vector3.ZERO
        var n := 0
        for v in V:
            var b = hs.get(v[0])
            if b and is_instance_valid(b) and (b as Node3D).visible:
                c += (b as Node3D).global_position
                n += 1
        var sc: Dictionary = _t.get("_scar_info")
        var mo: Vector3 = sc["mouth"]
        var fw: Vector3 = sc["fwd"]
        if n > 0:
            c /= float(n)
        else:
            c = mo
        _cam.global_position = c + fw * 15.0 + Vector3(-fw.z, 0, fw.x) * 6.0 + Vector3(0, 6.5, 0)
        _cam.look_at(c.lerp(mo, 0.5) + Vector3(0, 1.2, 0), Vector3.UP)
        if _f == _mark:
            _snap("dawn_return")
            print("FEEDTAIL ", (_t.get("feed") as Array).slice(-4))
            return true
    return _f > 60 * 240
