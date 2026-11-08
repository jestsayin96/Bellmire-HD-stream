extends SceneTree
## 10 valley days (90 s each) at 8x: souls, level, stock, deaths, the chronicle.
var _t: Node3D
var _f := 0
var _seen := 0
var _t0 := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _t0 = Time.get_ticks_msec()
func _process(_d: float) -> bool:
    _f += 1
    if _f == 5:
        Engine.time_scale = 8.0
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        var l := String(feed[_seen])
        if l.begins_with("Day ") or l.contains("killed") or l.contains("starved") or l.contains("level") or l.contains("chief") or l.contains("Hunger") or l.contains("coffer") or l.contains("boil") or l.contains("bandits") or l.contains("burning") or l.contains("set out") or l.contains("come home") or l.contains("bounty") or l.contains("tavern") or l.contains("falls on floor") or l.contains("Floor ") or l.contains("keeps them"):
            print("FEED ", l)
        if false and not l.begins_with("The forge") and not l.begins_with("No gear") and not l.begins_with("Gear prices"):
            print("FEED ", l)
        _seen += 1
    var eco: Economy = _t.get("economy")
    if eco and eco.day > 10:
        print("END souls=", eco.population(), " lvl=", eco.town_level, " treasury=", eco.treasury, " dead=", eco.dead, " renown=", eco.renown)
        print("STOCK ", eco.stock)
        var adv: Adventurers = _t.get("adventurers")
        print("ADV alive=", adv.count(), " made=", adv._n, " delving=", adv._delving.size())
        print("HOMES ", _t.call("home_count"), " real_s=", (Time.get_ticks_msec() - _t0) / 1000)
        return true
    return (Time.get_ticks_msec() - _t0) > 330000
