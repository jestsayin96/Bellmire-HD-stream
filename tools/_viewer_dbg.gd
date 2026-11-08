extends SceneTree
var _t: Node3D
var _f := 0
var _seen := 0
var _ms := 0
var _step := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _process(_d: float) -> bool:
    _f += 1
    var feed: Array = _t.get("feed")
    while _seen < feed.size():
        print("FEED ", feed[_seen])
        _seen += 1
    if _f == 10:
        _t.get("raids").set("_raid_t", 99999.0)
        _t.get("adventurers").set("_party_t", 99999.0)
        _t.call("chat_line", "1001", "JestFan", "!enlist knight")
        _t.call("chat_line", "1002", "Fisher", "!enlist ranger")
        _ms = Time.get_ticks_msec()
        Engine.time_scale = 4.0
    if _step == 0 and _f > 10 and Time.get_ticks_msec() - _ms > 1800:
        print("CHAT -> ", _t.call("chat_line", "1001", "JestFan", "!delve"))
        _step = 1
    if _f % 600 == 0 and _f > 10:
        var hs: Dictionary = _t.get("heroes")
        for u in hs:
            var b: HeroBody = hs[u]
            if is_instance_valid(b):
                print("T", _f / 60, " ", b.person_name, " pos=", Vector2(b.global_position.x, b.global_position.z).snapped(Vector2.ONE), " route=", b._route.size(), " stay=", b.stay, " errand=", b.errand, " vis=", b.visible, " night=", _t.get("economy").is_night())
        print("   at_mouth=", _t.get("_at_mouth"), " delve=", _t.get("delve"))
    return _f > 60 * 140
