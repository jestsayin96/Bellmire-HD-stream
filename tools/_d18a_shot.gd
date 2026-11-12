extends SceneTree
## D18a shot sheet: coherence of wall/gates/bridge/roads, buildings on ground,
## docks over water, the scar mouth crag, an outlying hillside farmstead.
## Windowed, --fixed-fps 60 -> renders/cycles/20261112_d18a/<name>.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _shots: Array = []
var _n := 0
var _log: FileAccess
const BASE := 150
const STEP := 10
func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    _out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d18a")
    DirAccess.make_dir_recursive_absolute(_out)
    DisplayServer.window_set_size(Vector2i(1366, 768))
    _log = FileAccess.open("user://d18a_log.txt", FileAccess.WRITE)
    _log.store_line("init ok")
    _log.flush()
func _g(x: float, z: float) -> float:
    return _t.call("height_at", x, z)
func _build_shots() -> void:
    # [name, cam pos, look-at]
    _shots.append(["west_gate", Vector3(-200, 10, -5), Vector3(-170, 4, -5)])
    _shots.append(["bridge", Vector3(26, 8, 129.5), Vector3(0, 2.5, 129.5)])
    _shots.append(["market_square", Vector3(49, 14, -44), Vector3(49, 1.5, -68)])
    _shots.append(["street", Vector3(5, 8, -28), Vector3(45, 1.5, -64)])
    _shots.append(["scar_mouth", Vector3(19.8, 42, -205), Vector3(19.8, 34, -233)])
    _shots.append(["docks", Vector3(-48, 7, 108), Vector3(-30, 1.5, 119)])
    _shots.append(["town_aerial", Vector3(60, 135, 70), Vector3(0, 0, -50)])
    _shots.append(["farmstead_slope", Vector3(272, 16, -18), Vector3(235, 6, -35)])
    _shots.append(["hamlet_north", Vector3(62, 18, 256), Vector3(32, 6, 240)])
func _process(_d: float) -> bool:
    _f += 1
    if _f == 60:
        _cam = Camera3D.new()
        _cam.fov = 48.0
        _t.add_child(_cam)
        _build_shots()
    if _cam and _f > 60 and _cam != root.get_viewport().get_camera_3d():
        _cam.make_current()
    if _cam and _n < _shots.size():
        var when := BASE + _n * STEP
        if _f == when:
            var s: Array = _shots[_n]
            _cam.global_position = s[1]
            _cam.look_at(s[2], Vector3.UP)
        if _f == when + STEP - 2:
            RenderingServer.force_draw(false)
            var img: Image = root.get_texture().get_image()
            if img == null:
                print("NULL IMG ", _shots[_n][0])
            else:
                img.save_png(_out + "/%s.png" % _shots[_n][0])
                print("SAVED ", _shots[_n][0], " ", img.get_width(), "x", img.get_height())
                if _log: _log.store_line("SAVED %s %dx%d" % [_shots[_n][0], img.get_width(), img.get_height()]); _log.flush()
            _n += 1
    return (_shots.size() > 0 and _n >= _shots.size()) or _f > 60 * 90
