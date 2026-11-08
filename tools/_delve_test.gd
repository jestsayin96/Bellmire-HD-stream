extends SceneTree
var _d: Delve
var _r: Roster
var _f := 0
func _initialize() -> void:
    _r = Roster.new()
    root.add_child(_r)
    var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "DawnCleric", "cleric"], ["1004", "BigAxe", "barbarian"]]
    var ids := []
    for v in V:
        var h: Dictionary = _r.fresh(v[0], v[1], v[2])
        h["weapon"] = 2
        h["armour"] = 2
        h["oil"] = int(OS.get_environment("DELVE_OIL")) if OS.get_environment("DELVE_OIL") != "" else int(h.get("oil", 2))
        ids.append(v[0])
    _d = Delve.new()
    _d.roster = _r
    _d.max_floors = 6
    root.add_child(_d)
    _d.ended.connect(func(s): print("ENDED survivors=", s, " frames=", _f))
    _d.start(ids)
func _process(_dt: float) -> bool:
    _f += 1
    if _f % 600 == 0:
        var hp := []
        for m in _d.party:
            hp.append("%s %d/%d" % [m["h"]["name"], int(m["hp"]), int(m["max"])])
        if _d.dun:
            var hp0: Vector3 = (_d.party[0]["body"] as Node3D).global_position
            var ms := []
            for mo in _d._foes():
                ms.append([(mo as Node3D).global_position.snapped(Vector3.ONE * 0.1), mo.state])
        print("T", _f / 60, "s floor=", _d.floor_no, " state=", _d.state, " foes=", _d._foes().size() if _d.dun else -1, " ", hp)
    return _d.state == "home" or _f > 60 * 150
