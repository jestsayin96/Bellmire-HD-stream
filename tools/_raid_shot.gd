extends SceneTree
## Render: bandits meeting the guard at the west gate, then a burning ruin.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _rd: Raids
var _fight_f := -1
var _ruin_f := -1
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://raid_%s.png" % nm)
    print("SAVED ", nm)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 15:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        _cam.fov = 55.0
        _rd = _t.get("raids")
        _rd.force_level = 3
        _rd.set("_raid_t", 99999.0)
        _rd.raid("road")
        Engine.time_scale = 3.0
    if _f < 16 or _rd == null:
        return false
    if _fight_f < 0 and not _rd.raiders.is_empty():
        # first raider within 3 m of a defender: that is the clash
        for r in _rd.raiders:
            var tg = r["target"]
            if tg != null and is_instance_valid(tg) and _rd._flat((r["node"] as Node3D).global_position, (tg as Node3D).global_position) < 2.5:
                _fight_f = _f
                Engine.time_scale = 1.0
                var c := ((r["node"] as Node3D).global_position + (tg as Node3D).global_position) * 0.5
                var gw: Vector3 = _t.call("_gate", -1.0)
                var outw := Vector3(gw.x, 0, gw.z).normalized()
                var side := Vector3(-outw.z, 0, outw.x)
                _cam.global_position = c + side * 7.0 - outw * 3.0 + Vector3(0, 4.0, 0)
                _cam.look_at(c + Vector3(0, 1.0, 0), Vector3.UP)
                print("CLASH at ", c, " gate ", gw)
                break
    if _fight_f > 0 and _f == _fight_f + 8:
        _snap("gate")
        # a breach: one house nearest a raider burns
        if not _rd.raiders.is_empty():
            _rd._wreck_a_building(true)
        _ruin_f = _f
    if _ruin_f > 0 and _f == _ruin_f + 2 and not _rd.ruins.is_empty():
        var pl: Dictionary = _rd.ruins[0]
        var c2: Vector3 = pl["pos"]
        var yaw := float(pl.get("yaw", 0.0))
        var fw := Vector3(sin(yaw), 0, cos(yaw))
        _cam.global_position = c2 + fw * 14.0 + Vector3(-fw.z, 0, fw.x) * 6.0 + Vector3(0, 8.0, 0)
        _cam.look_at(c2 + Vector3(0, 1.5, 0), Vector3.UP)
    if _ruin_f > 0 and _f == _ruin_f + 90:
        _snap("ruin")
        _t.get("economy").stock["wood"] = 80.0
        _t.get("economy").stock["stone"] = 60.0
        _rd._rebuild_pass(true)
    if _ruin_f > 0 and _f == _ruin_f + 100:
        _snap("rebuilt")
        print("FEEDTAIL ", (_t.get("feed") as Array).slice(-5))
        return true
    return _f > 60 * 120
