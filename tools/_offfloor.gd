extends SceneTree
## Off-floor audit: every hero and monster position checked against the floor
## cells every half second; prints how many samples were off the floor.
var _d: Delve
var _r: Roster
var _f := 0
var _off := 0
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
        for m in _d._alive():
            _n += 1
            if not cells.has(_d._cell_of((m["body"] as Node3D).global_position)):
                _off += 1
        for mo in _d._foes():
            _n += 1
            if not cells.has(_d._cell_of((mo as Node3D).global_position)):
                _off += 1
    if _d.state == "home" or _f > 60 * 200:
        print("OFFFLOOR ", _off, " of ", _n, " samples; floor reached ", _d.floor_no)
        return true
    return false
