extends Node3D
class_name RtsCamera
## The player's eye on the valley - a NEW RTS-style camera (nothing from the
## old game's interface). It orbits a point on the ground:
##   WASD / arrows   pan (Shift = fast)        mouse wheel   zoom
##   right-drag      rotate + tilt             Q / E         rotate
##   R / F           tilt                      middle-drag   pan
##   1 square  2 scar mouth  3 west gate  4 tavern  5 smithy  6 armourer  7 apothecary
##   Tab             cycle through delves running below (and back to town)
##   Space           pause / resume            [ / ]         slower / faster (1x 2x 4x 8x)
##   Enter           type a chat command as yourself (no Twitch: local only)
##   H               show / hide this help
var town: Node3D
var cam: Camera3D
var focus := Vector3.ZERO
var yaw := deg_to_rad(35.0)
var pitch := deg_to_rad(-48.0)
var dist := 34.0
var _drag_r := false
var _drag_m := false
var _speeds := [1.0, 2.0, 4.0, 8.0]
var _speed_i := 0
var _paused := false
var _delve_i := -1
var _help: Label
var _speed_lb: Label
var _chat: LineEdit
var _layer: CanvasLayer

func setup(t: Node3D) -> void:
    town = t
    cam = Camera3D.new()
    cam.fov = 55.0
    cam.far = 2000.0
    add_child(cam)
    cam.make_current()
    focus = t.get("_market_pos")
    _layer = CanvasLayer.new()
    _layer.layer = 30
    add_child(_layer)
    _help = Label.new()
    _help.text = "WASD pan · wheel zoom · right-drag rotate · Q/E turn · R/F tilt\n1 square · 2 scar · 3 gate · 4 tavern · 5 smithy · 6 armourer · 7 apothecary\nTab: jump into a delve · Space pause · [ ] speed · Enter chat · H hide"
    _help.add_theme_font_size_override("font_size", 15)
    _help.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
    _help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _help.add_theme_constant_override("outline_size", 6)
    _help.position = Vector2(16, 12)
    _layer.add_child(_help)
    _speed_lb = Label.new()
    _speed_lb.add_theme_font_size_override("font_size", 18)
    _speed_lb.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
    _speed_lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _speed_lb.add_theme_constant_override("outline_size", 6)
    _speed_lb.anchor_left = 1.0
    _speed_lb.anchor_right = 1.0
    _speed_lb.offset_left = -260
    _speed_lb.offset_top = 12
    _layer.add_child(_speed_lb)
    _chat = LineEdit.new()
    _chat.placeholder_text = "chat as MrE, e.g. !enlist knight   (Enter to send, Esc to close)"
    _chat.anchor_left = 0.5
    _chat.anchor_right = 0.5
    _chat.anchor_top = 1.0
    _chat.anchor_bottom = 1.0
    _chat.offset_left = -330
    _chat.offset_right = 330
    _chat.offset_top = -64
    _chat.offset_bottom = -30
    _chat.visible = false
    _chat.text_submitted.connect(_send_chat)
    _layer.add_child(_chat)
    _update_speed_label()

func _ground(p: Vector3) -> float:
    if _delve_i >= 0:
        return Delve.DELVE_Y
    return float(town.call("height_at", p.x, p.z))

func _process(delta: float) -> void:
    if cam == null:
        return
    var real := delta / maxf(Engine.time_scale, 0.001)    # camera moves in real time
    if not _chat.visible:
        var mv := Vector2.ZERO
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
        if mv != Vector2.ZERO:
            var spd := (12.0 + dist * 1.1) * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
            var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
            var right := Vector3(cos(yaw), 0, -sin(yaw))
            focus += (right * mv.x + fwd * -mv.y) * spd * real
        if Input.is_key_pressed(KEY_Q): yaw += 1.6 * real
        if Input.is_key_pressed(KEY_E): yaw -= 1.6 * real
        if Input.is_key_pressed(KEY_R): pitch = clampf(pitch - 1.0 * real, deg_to_rad(-85), deg_to_rad(-12))
        if Input.is_key_pressed(KEY_F): pitch = clampf(pitch + 1.0 * real, deg_to_rad(-85), deg_to_rad(-12))
    focus.y = lerpf(focus.y, _ground(focus), clampf(real * 8.0, 0.0, 1.0))
    var off := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
    cam.global_position = focus + off
    # never under the ground
    var gy := _ground(cam.global_position) + 1.5
    if cam.global_position.y < gy:
        cam.global_position.y = gy
    cam.look_at(focus + Vector3(0, 1.0, 0), Vector3.UP)

func _unhandled_input(ev: InputEvent) -> void:
    if _chat.visible:
        if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
            _chat.visible = false
            _chat.release_focus()
        return
    if ev is InputEventMouseButton:
        var mb: InputEventMouseButton = ev
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
            dist = clampf(dist * 0.88, 6.0, 260.0)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
            dist = clampf(dist / 0.88, 6.0, 260.0)
        elif mb.button_index == MOUSE_BUTTON_RIGHT:
            _drag_r = mb.pressed
        elif mb.button_index == MOUSE_BUTTON_MIDDLE:
            _drag_m = mb.pressed
    elif ev is InputEventMouseMotion:
        var mm: InputEventMouseMotion = ev
        if _drag_r:
            yaw -= mm.relative.x * 0.005
            pitch = clampf(pitch - mm.relative.y * 0.004, deg_to_rad(-85), deg_to_rad(-12))
        elif _drag_m:
            var k := dist * 0.0022
            var right := Vector3(cos(yaw), 0, -sin(yaw))
            var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
            focus += (-right * mm.relative.x + fwd * mm.relative.y) * k
    elif ev is InputEventKey and ev.pressed and not ev.echo:
        match ev.keycode:
            KEY_1: _jump(town.get("_market_pos"), 34.0)
            KEY_2: _jump_scar()
            KEY_3: _jump(town.call("_gate", -1.0), 30.0)
            KEY_4: _jump_shop("tavern")
            KEY_5: _jump_shop("blacksmith")
            KEY_6: _jump_shop("armorer")
            KEY_7: _jump_shop("apothecary")
            KEY_TAB: _cycle_delve()
            KEY_SPACE:
                _paused = not _paused
                town.get_tree().paused = false
                Engine.time_scale = 0.0001 if _paused else float(_speeds[_speed_i])
                _update_speed_label()
            KEY_BRACKETLEFT:
                _speed_i = maxi(0, _speed_i - 1)
                _set_speed()
            KEY_BRACKETRIGHT:
                _speed_i = mini(_speeds.size() - 1, _speed_i + 1)
                _set_speed()
            KEY_H: _help.visible = not _help.visible
            KEY_ENTER, KEY_KP_ENTER:
                _chat.visible = true
                _chat.text = "!"
                _chat.grab_focus()
                _chat.caret_column = 1

func _set_speed() -> void:
    _paused = false
    Engine.time_scale = float(_speeds[_speed_i])
    _update_speed_label()

func _update_speed_label() -> void:
    var eco = town.get("economy")
    var clock := ""
    if eco:
        var h: float = eco.hour()
        clock = "  Day %d  %02d:%02d" % [eco.day, int(h), int(fmod(h, 1.0) * 60.0)]
    _speed_lb.text = ("PAUSED" if _paused else "%dx" % int(_speeds[_speed_i])) + clock

func _physics_process(_d: float) -> void:
    if _speed_lb:
        _update_speed_label()

func _jump(p: Vector3, d: float) -> void:
    _delve_i = -1
    focus = p
    dist = d

func _jump_scar() -> void:
    var sc: Dictionary = town.get("_scar_info")
    if sc.has("mouth"):
        _jump(sc["mouth"] + (sc["fwd"] as Vector3) * 8.0, 30.0)

func _jump_shop(kind: String) -> void:
    var fr: Array = (town.get("_shop_frame") as Dictionary).get(kind, [])
    if not fr.is_empty():
        _jump(fr[0], 20.0)

## Tab: every delve under way, in turn, then back to the square
func _cycle_delve() -> void:
    var ds: Array = []
    for c in town.get_children():
        if c is Delve and (c as Delve).dun != null and is_instance_valid((c as Delve).dun):
            ds.append(c)
    if ds.is_empty() or _delve_i + 1 >= ds.size():
        _jump(town.get("_market_pos"), 34.0)
        return
    _delve_i += 1
    var d: Delve = ds[_delve_i]
    var alive: Array = d._alive()
    focus = (alive[0]["body"] as Node3D).global_position if not alive.is_empty() else d.dun.global_position
    dist = 22.0
    pitch = deg_to_rad(-62.0)

func _send_chat(text: String) -> void:
    _chat.visible = false
    _chat.release_focus()
    if text.strip_edges().length() > 1:
        var out: String = town.call("chat_line", "local_mre", "MrE", text.strip_edges())
        print("CHAT MrE: ", text, " -> ", out)
