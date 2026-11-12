extends SceneTree
## Off-floor audit: every hero and monster position checked against the floor
## cells every half second; prints how many samples were off the floor, and how
## many heroes (INPROP) and monsters (MON_INPROP) stood inside a prop.
var _d: Delve
var _r: Roster
var _f := 0
var _off := 0
var _inprop := 0
var _mon_inprop := 0
var _mon_n := 0
var _n := 0
func _initialize() -> void:
    _r = Roster.new()
    root.add_child(_r)
    var ids := []
    var cls := ["knight", "mage", "cleric", "barbarian", "ranger", "rogue", "sage", "duelist"]
    for i in 8:
        var h: Dictionary = _r.fresh("p%d" % i, "Hero%d" % i, cls[i])
        h["oil"] = 3
        ids.append("p%d" % i)
    _d = Delve.new()
    _d.roster = _r
    _d.max_floors = 4
    _d.lane = 1
    root.add_child(_d)
    Engine.time_scale = 4.0
    _d.start(ids)
func _process(_dt: float) -> bool:
    _f += 1
    if _d.dun and _f % 30 == 0:
        var cells: Dictionary = _d.dun.info["cells"]
        var o0: Vector3 = _d.dun.global_position
        for m in _d._alive():
            var bp: Vector3 = (m["body"] as Node3D).global_position
            for o in _d.dun.info.get("obstacles", []):
                if Vector2(bp.x - (o[0] as Vector3).x - o0.x, bp.z - (o[0] as Vector3).z - o0.z).length() < float(o[1]) - 0.05:
                    _inprop += 1
                    break
            _n += 1
            if not cells.has(_d._cell_of((m["body"] as Node3D).global_position)):
                _off += 1
                print("OFF hero state=", _d.state)
        for mo in _d._foes():
            _n += 1
            _mon_n += 1
            var mp: Vector3 = (mo as Node3D).global_position
            for o in _d.dun.info.get("obstacles", []):
                if Vector2(mp.x - (o[0] as Vector3).x - o0.x, mp.z - (o[0] as Vector3).z - o0.z).length() < float(o[1]) - 0.05:
                    _mon_inprop += 1
                    print("INPROP monster ", (mo as Monster).def.get("name"))
                    break
            if not cells.has(_d._cell_of((mo as Node3D).global_position)):
                _off += 1
                print("OFF monster ", (mo as Monster).def.get("name"), " state=", _d.state)
    if _d.state == "home" or _f > 60 * 200:
        print("OFFFLOOR ", _off, " of ", _n, " samples; INPROP ", _inprop, "; MON_INPROP ", _mon_inprop, " of ", _mon_n, "; floor reached ", _d.floor_no, " frames ", _f, " obstacles ", _d.dun.info.get("obstacles", []).size())
        return true
    return false
