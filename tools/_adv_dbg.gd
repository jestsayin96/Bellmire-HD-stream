extends SceneTree
var _t: Node3D
var _f := 0
var _adv: Adventurers
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        _adv = _t.get("adventurers")
        _t.get("raids").set("_raid_t", 99999.0)
    if _f > 5 and _f % 300 == 0:
        var mo: Vector3 = _t.get("_scar_info")["mouth"]
        var rows := []
        for u in _adv.bodies:
            var b: HeroBody = _adv.bodies[u]
            if not is_instance_valid(b):
                continue
            rows.append("%s d%d r%d st%s vis%s in%s er%s" % [u, int(Vector2(b.global_position.x - mo.x, b.global_position.z - mo.z).length()), b._route.size(), b.stay, b.visible, b.inside, b.errand])
        print("T", _f / 60, " pend=", _adv._pending.size(), " ", rows)
    return _f > 60 * 75
