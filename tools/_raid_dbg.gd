extends SceneTree
var _t: Node3D
var _f := 0
var _rd: Raids
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        _rd = _t.get("raids")
        _rd.force_level = 3
        _rd.set("_raid_t", 99999.0)
        _t.get("economy").renown = 40
        _rd.raid("road")
    if _f > 10 and _f % 300 == 0:
        var rs := []
        for r in _rd.raiders:
            rs.append("%d@%s" % [int(r["hp"]), str(Vector2((r["node"] as Node3D).global_position.x, (r["node"] as Node3D).global_position.z).snapped(Vector2.ONE))])
        var ds := []
        for d in _rd._fighters:
            var st: Dictionary = _rd._fighters[d]
            var tg = st["target"]
            var dist := -1.0
            if tg != null and _rd.raiders.has(tg):
                dist = _rd._flat((d as Node3D).global_position, (tg["node"] as Node3D).global_position)
            ds.append("%s hp%d d%d" % [String((d as Townsfolk).gear_role if (d as Townsfolk).gear_role != "" else (d as Townsfolk).role), int(st["hp"]), int(dist)])
        print("T", _f / 60, " R=", rs, " D=", ds)
    return _f > 60 * 90 or (_f > 60 and _rd.raiders.is_empty())
