extends SceneTree
## FAKE CHAT FEED - no Twitch, nothing posted. Six viewers enlist, buy, fish,
## delve; photographs each beat.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _t0 := 0
var _step := 0
var _plan := [[0, "!forge"], [3, "!forge"], [1, "!fish"], [2, "!fish"], [0, "!forge"], [3, "!forge"], [0, "!forge"]]
var V := [["1001", "JestFan", "knight"], ["1002", "MossyMage", "mage"], ["1003", "QuietArrow", "ranger"],
          ["1004", "BigAxe", "barbarian"], ["1005", "DawnCleric", "cleric"], ["1006", "Stabbity", "rogue"]]
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _say(i: int, msg: String) -> void:
    var v: Array = V[i]
    var out: String = _t.call("chat_line", v[0], v[1], msg)
    print("CHAT ", v[1], ": ", msg, "  ->  ", out)
func _hero(i: int) -> Node3D:
    return (_t.get("heroes") as Dictionary).get(V[i][0])
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://hero_%s.png" % nm)
    print("SAVED ", nm)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 20:
        _cam = Camera3D.new()
        _t.add_child(_cam)
        _cam.make_current()
        for i in range(V.size()):
            _say(i, "!enlist " + V[i][2])
        # give the knight and the barbarian some purse for the forge
        for i in [0, 3]:
            var h: Dictionary = _t.get("roster").get_hero(V[i][0])
            h["gold"] = 2000
    if _f == 40:
        var m: Vector3 = _t.get("_market_pos")
        _cam.fov = 55.0
        _cam.global_position = m + Vector3(0, 6.0, 15.0)
        _cam.look_at(m + Vector3(0, 1.0, 0), Vector3.UP)
    if _f == 50:
        _snap("party_square")
        _f = 51
        Engine.time_scale = 1.0
    if _f == 52:
        _f += 0
    # the old 1.5 s per-viewer cooldown is wall-clock, so commands are spaced in real ms
    if _f == 60:
        _t0 = Time.get_ticks_msec()
    if _f > 60 and _step < _plan.size() and Time.get_ticks_msec() - _t0 > 1700 * (_step + 1):
        var pl: Array = _plan[_step]
        _say(int(pl[0]), String(pl[1]))
        _step += 1
    if _f > 60 and _f < 3400 and _f != 900 and _f != 912:
        Engine.time_scale = 6.0
    if _f == 900:
        Engine.time_scale = 1.0
        var b := _hero(0)
        if b:
            var p := b.global_position
            var fw := Vector3(sin(b.rotation.y), 0, cos(b.rotation.y))
            _cam.fov = 52.0
            _cam.global_position = p + fw * 3.2 + Vector3(-fw.z, 0, fw.x) * 1.6 + Vector3(0, 1.8, 0)
            _cam.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
    if _f == 912:
        _snap("forge")
        var b := _hero(1)
        if b:
            var p := b.global_position
            _cam.fov = 55.0
            _cam.global_position = p + Vector3(6, 3.5, -3)
            _cam.look_at(p + Vector3(0, 2.0, 4), Vector3.UP)
    if _f == 960:
        _snap("fishing")
    if _f == 980:
        for i in [0, 3, 4, 5]:
            _say(i, "!delve")
    if _f == 3300:
        Engine.time_scale = 1.0
        var sc: Dictionary = _t.call("stats").get("scar", {})
        var mo: Vector3 = sc.get("mouth", Vector3.ZERO)
        var fw2: Vector3 = sc.get("fwd", Vector3(0, 0, 1))
        var pos := mo + fw2 * 18.0 + Vector3(-fw2.z, 0, fw2.x) * 6.0
        pos.y = float(_t.call("height_at", pos.x, pos.z)) + 5.0
        var look := mo + fw2 * 6.0
        look.y = float(_t.call("height_at", look.x, look.z)) + 1.5
        _cam.fov = 58.0
        _cam.global_position = pos
        _cam.look_at(look, Vector3.UP)
    if _f == 3312:
        _snap("scar_mouth")
        print("FEEDLOG ", _t.get("feed"))
        return true
    return false
