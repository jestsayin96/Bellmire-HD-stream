extends SceneTree
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _ms := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _key(k: Key) -> void:
    for down in [true, false]:
        var e := InputEventKey.new()
        e.keycode = k
        e.physical_keycode = k
        e.pressed = down
        Input.parse_input_event(e)
func _click(at: Vector2) -> void:
    for down in [true, false]:
        var e := InputEventMouseButton.new()
        e.button_index = MOUSE_BUTTON_LEFT
        e.pressed = down
        e.position = at
        e.global_position = at
        Input.parse_input_event(e)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://sel_%s.png" % nm)
    var sel = _eye.selected
    print("SAVED ", nm, " selected=", (sel.person_name if sel is Townsfolk else (sel.def.get("name") if sel is Monster else "none")) if sel else "none", " following=", _eye._following)
func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        _t.get("raids").set("_raid_t", 99999.0)
        print("CHAT -> ", _t.call("chat_line", "local_mre", "MrE", "!enlist knight"))
        _ms = Time.get_ticks_msec()
    if _f == 30:
        _key(KEY_F)
    if _f == 70:
        _snap("follow_me")
    if _f == 80:
        # click the nearest ordinary townsfolk on screen
        var best: Node3D = null
        var bd := 1e9
        for n in _t.get("people"):
            if n is HeroBody or not (n as Node3D).is_visible_in_tree():
                continue
            var p: Vector3 = (n as Node3D).global_position + Vector3(0, 1, 0)
            if _eye.cam.is_position_behind(p):
                continue
            var sp := _eye.cam.unproject_position(p)
            var dd := sp.distance_to(Vector2(576, 324))
            if dd < bd:
                bd = dd
                best = n
        _click(_eye.cam.unproject_position(best.global_position + Vector3(0, 1, 0)))
        _key(KEY_N)
    if _f == 110:
        _snap("townsfolk_names")
    if _f == 115 and Time.get_ticks_msec() - _ms > 1600:
        print("CHAT -> ", _t.call("chat_line", "local_mre", "MrE", "!inventory"))
    if _f == 120:
        # follow a band hero; send the band down
        var adv: Adventurers = _t.get("adventurers")
        var b: Node3D = adv.bodies.values()[0]
        _eye._select(b)
        _eye._following = true
        adv.set("_party_t", 0.1)
        Engine.time_scale = 8.0
    if _f > 120 and _eye.selected and (_eye.selected as Node3D).global_position.y < -300 and not has_meta("down"):
        set_meta("down", _f)
        Engine.time_scale = 1.0
    if has_meta("down") and _f == int(get_meta("down")) + 40:
        _snap("followed_into_delve")
        return true
    return _f > 60 * 240
