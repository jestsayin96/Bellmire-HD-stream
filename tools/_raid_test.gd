extends SceneTree
## Raid test: level forced to 3, one raid from the scar and one bandit raid.
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
        var sc: Dictionary = _t.get("_scar_info")
        print("INSIDE market=", _rd._inside_walls(_t.get("_market_pos")), " mouth=", _rd._inside_walls(sc.get("mouth", Vector3(999, 0, 999))), " wall=", _t.get("_wall_info").get("ax"), ",", _t.get("_wall_info").get("az"), " market=", _t.get("_market_pos"))
        seed(7)
        _rd.raid()
    if _f > 10 and _f % 600 == 0:
        print("T", _f / 60, "s raiders=", _rd.raiders.size(), " fighters=", _rd._fighters.size(), " ruins=", _rd.ruins.size(), " people=", (_t.get("people") as Array).size())
    if _f == 60 * 70:
        _rd.raid()   # second raid (random source)
    if _f == 60 * 150:
        _t.get("economy").stock["wood"] = 80.0
        _t.get("economy").stock["stone"] = 60.0
    return _f > 60 * 200
