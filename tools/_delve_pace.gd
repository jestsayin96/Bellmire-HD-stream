extends SceneTree
## Delve pace probe: N heroes, time scale TS, lane L. Prints game-seconds per floor and state.
var _d: Delve
var _r: Roster
var _f := 0
var _gt := 0.0
var _last_floor := 0
var _floor_t := 0.0
var _state_t := {}
func _initialize() -> void:
    _r = Roster.new()
    root.add_child(_r)
    var n := int(OS.get_environment("PACE_N")) if OS.get_environment("PACE_N") != "" else 4
    var ids := []
    var cls := ["knight", "mage", "cleric", "barbarian", "ranger", "rogue", "sage", "duelist"]
    for i in n:
        var id := "p%d" % i
        var h: Dictionary = _r.fresh(id, "Hero%d" % i, cls[i % cls.size()])
        h["oil"] = 3
        ids.append(id)
    _d = Delve.new()
    _d.roster = _r
    _d.max_floors = 4
    _d.lane = int(OS.get_environment("PACE_L")) if OS.get_environment("PACE_L") != "" else 0
    root.add_child(_d)
    Engine.time_scale = float(OS.get_environment("PACE_TS")) if OS.get_environment("PACE_TS") != "" else 1.0
    _d.start(ids)
func _process(dt: float) -> bool:
    _f += 1
    _gt += dt
    if _d.dun:
        _state_t[_d.state] = float(_state_t.get(_d.state, 0.0)) + dt
    if _d.floor_no != _last_floor:
        print("FLOOR ", _d.floor_no, " reached at game t=", snappedf(_gt, 0.1), " states=", _state_t)
        _state_t = {}
        _last_floor = _d.floor_no
    if _f % 600 == 0 and _d.state == "fight":
        var stuck := []
        for m in _d._alive():
            stuck.append(int(_d._flat((m["body"] as Node3D).global_position, (_d._foes()[0] as Node3D).global_position)) if not _d._foes().is_empty() else -1)
        print("  t=", snappedf(_gt, 0.1), " foes=", _d._foes().size(), " hero->foe0 dist=", stuck)
    return _d.state == "home" or _gt > 900.0
