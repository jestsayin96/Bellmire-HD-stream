extends SceneTree
## Health bars: count how many are up during a delve (heroes / monsters).
var _d: Delve
var _r: Roster
var _f := 0
var _seen_h := 0
var _seen_m := 0
func _initialize() -> void:
    _r = Roster.new()
    root.add_child(_r)
    var ids := []
    for v in [["1", "A", "knight"], ["2", "B", "mage"], ["3", "C", "cleric"], ["4", "D", "barbarian"]]:
        _r.fresh(v[0], v[1], v[2])
        ids.append(v[0])
    _d = Delve.new()
    _d.roster = _r
    _d.max_floors = 2
    root.add_child(_d)
    Engine.time_scale = 3.0
    _d.start(ids)
func _process(_dt: float) -> bool:
    _f += 1
    if _f % 30 == 0 and _d.dun:
        for m in _d.party:
            var hb = (m["body"] as Node).get_node_or_null("hpbar")
            if hb and hb.visible:
                _seen_h += 1
        for mo in _d._foes():
            var hb2 = (mo as Node).get_node_or_null("hpbar")
            if hb2 and hb2.visible:
                _seen_m += 1
    if _d.state == "home" or _f > 60 * 90:
        print("BARS hero-samples-visible=", _seen_h, " monster-samples-visible=", _seen_m)
        return true
    return false
