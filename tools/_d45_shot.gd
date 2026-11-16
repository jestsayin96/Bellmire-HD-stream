extends SceneTree
## D45 grass assessment: frame the ground at stream distance + a low close-up so
## we can judge whether it reads as grass or sand. Run WINDOWED. `-- <tag>`.
## -> renders/cycles/d45/<tag>_*.png
var _t: Node3D
var _cam: Camera3D
var _dl
var _f := 0
var _out := ""
var _tag := "run"
var _shots: Array = []
var _i := 0
var _armed := -1
var _hold := 0

func _initialize() -> void:
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 0: _tag = String(ua[0])
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/d45")
	DirAccess.make_dir_recursive_absolute(_out)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r: r.set("_raid_t", 999999.0)
		_cam = Camera3D.new(); _cam.fov = 55.0; _cam.far = 1600.0
		_t.add_child(_cam)
		var m: Vector3 = _t.get("_market_pos")
		# low close-up over a grass island between the radial roads
		_shots.append(["grass_close", 12.0, "clear", m + Vector3(46.0, 2.2, 6.0), m + Vector3(30.0, 0.4, 2.0)])
		# behind-house grass, pane distance
		_shots.append(["back_grass", 12.0, "clear", m + Vector3(34.0, 7.0, 44.0), m + Vector3(22.0, 0.3, 24.0)])
		# the open valley field south of the walls
		_shots.append(["valley_field", 12.0, "clear", Vector3(0.0, 6.0, 150.0), Vector3(0.0, 0.3, 118.0)])
		# wide resting-cam view of the town greens
		_shots.append(["greens_wide", 12.0, "clear", m + Vector3(0.0, 60.0, 92.0), m])
	if _cam == null: return false
	if _cam != root.get_viewport().get_camera_3d(): _cam.make_current()
	if _i < _shots.size():
		var sh: Array = _shots[_i]
		if _armed != _i:
			if _dl:
				_dl.override_hour = float(sh[1]); _dl.set_weather(String(sh[2]), true)
			_cam.global_position = sh[3] as Vector3
			_cam.look_at(sh[4] as Vector3, Vector3.UP)
			_armed = _i; _hold = 0
			return false
		_hold += 1
		if _hold >= 55:
			root.get_texture().get_image().save_png(_out + "/%s_%s.png" % [_tag, sh[0]])
			print("SAVED ", _tag, "_", sh[0]); _i += 1
		return false
	return true
