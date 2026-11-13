extends SceneTree
## D27 assessment/sweep: brightness across the day (incl. an overcast morning) and
## the empty-grass angles. Run WINDOWED. `-- before/after`.
## -> renders/cycles/20261112_d27/<tag>_*.png
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
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d27")
	DirAccess.make_dir_recursive_absolute(_out)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r: r.set("_raid_t", 999999.0)
		_cam = Camera3D.new(); _cam.fov = 58.0; _cam.far = 1400.0
		_t.add_child(_cam)
		var m: Vector3 = _t.get("_market_pos")
		var rest := Vector3(-6.0, 17.0, 24.0)
		var look := Vector3(0, 0, -2.0)
		var wide := Vector3(0, 70.0, 95.0)
		var back := Vector3(30.0, 26.0, 40.0)
		# brightness across the day at the resting stream cam
		_shots.append(["rest_08_overcast", 8.0, "overcast", m + rest, m + look])
		_shots.append(["rest_08_clear", 8.0, "clear", m + rest, m + look])
		_shots.append(["rest_12_clear", 12.0, "clear", m + rest, m + look])
		_shots.append(["rest_12_overcast", 12.0, "overcast", m + rest, m + look])
		_shots.append(["rest_18_clear", 18.0, "clear", m + rest, m + look])
		_shots.append(["rest_22_clear", 22.0, "clear", m + rest, m + look])
		# emptiness: the hex plots + behind-house grass
		_shots.append(["plots_wide", 12.0, "clear", m + wide, m])
		_shots.append(["back_grass", 12.0, "clear", m + back, m + Vector3(20, 0, 20)])
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
