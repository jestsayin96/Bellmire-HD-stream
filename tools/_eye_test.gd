extends SceneTree
## Drives the player camera with real input events and photographs it.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
func _key(k: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = k
    e.physical_keycode = k
    e.pressed = down
    Input.parse_input_event(e)
func _wheel(up: bool) -> void:
    var e := InputEventMouseButton.new()
    e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
    e.pressed = true
    Input.parse_input_event(e)
func _snap(nm: String) -> void:
    root.get_texture().get_image().save_png("user://eye_%s.png" % nm)
    print("SAVED ", nm, " focus=", _eye.focus.snapped(Vector3.ONE), " dist=", snappedf(_eye.dist, 0.1))
func _process(_d: float) -> bool:
    _f += 1
    if _f == 10:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
    if _f == 40: _snap("start")
    if _f == 45: _key(KEY_2, true)
    if _f == 46: _key(KEY_2, false)
    if _f == 75: _snap("scar")
    if _f == 80:
        for i in 6: _wheel(false)
        _key(KEY_Q, true)
    if _f == 110:
        _key(KEY_Q, false)
        _key(KEY_W, true)
    if _f == 150:
        _key(KEY_W, false)
    if _f == 170: _snap("zoomed_out")
    if _f == 175:
        _key(KEY_ENTER, true)
    if _f == 176:
        _key(KEY_ENTER, false)
    if _f == 180:
        print("CHATBOX visible=", _eye._chat.visible)
        _eye._send_chat("!enlist knight")
        _key(KEY_1, true)
    if _f == 181: _key(KEY_1, false)
    if _f == 230:
        _snap("square_with_hero")
        return true
    return false
