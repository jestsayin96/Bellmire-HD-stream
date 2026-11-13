extends SceneTree
## D24 grain kill: before/after stills + an FPS pass at the resting stream camera.
## Run WINDOWED. Tag the run with a user arg: `-- before` or `-- after`.
## Reports the active AA settings so before/after are unambiguous.
## -> renders/cycles/20261112_d24/<tag>_*.png
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
var _fps_n := 0
var _fps_sum := 0.0
var _fps_lo := 999999.0

func _initialize() -> void:
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 0:
		_tag = String(ua[0])
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d24")
	DirAccess.make_dir_recursive_absolute(_out)

func _plan() -> void:
	var clutter := Vector3(-3.0, 6.5, 12.0)
	var over := Vector3(-6.0, 17.0, 24.0)
	var wide := Vector3(-14.0, 24.0, 38.0)
	var look := Vector3(0, 0.0, -2.0)
	# noon, clear - the worst case for the grain per Mr. E (cluttered town geometry)
	_shots.append(["clutter_noon", 12.0, "clear", clutter, Vector3(2.0, 1.0, -6.0)])
	_shots.append(["square_noon", 12.0, "clear", over, look])
	_shots.append(["wide_noon", 12.0, "clear", wide, look])
	_shots.append(["morning", 8.0, "clear", over, look])

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r:
			r.set("_raid_t", 999999.0)
		_cam = Camera3D.new()
		_cam.fov = 58.0
		_cam.far = 900.0
		_t.add_child(_cam)
		var vp := root.get_viewport()
		print("D24_AA tag=%s use_taa=%s msaa_3d=%d ssaa=%d" % [_tag, str(vp.use_taa), int(vp.msaa_3d), int(vp.screen_space_aa)])
		_plan()
	if _cam == null:
		return false
	if _cam != root.get_viewport().get_camera_3d():
		_cam.make_current()
	var m: Vector3 = _t.get("_market_pos")
	if _i < _shots.size():
		var sh: Array = _shots[_i]
		if _armed != _i:
			if _dl:
				_dl.override_hour = float(sh[1])
				_dl.set_weather(String(sh[2]), true)
			_cam.global_position = m + (sh[3] as Vector3)
			_cam.look_at(m + (sh[4] as Vector3), Vector3.UP)
			_armed = _i
			_hold = 0
			return false
		# hold 60 frames so TAA converges and volumetrics fill, then save
		_hold += 1
		if _hold >= 60:
			root.get_texture().get_image().save_png(_out + "/%s_%s.png" % [_tag, sh[0]])
			print("SAVED ", _tag, "_", sh[0], " hour=", float(sh[1]))
			_i += 1
		return false
	# FPS pass at the resting stream camera, noon clear
	if _fps_n == 0:
		if _dl:
			_dl.override_hour = 12.0
			_dl.set_weather("clear", true)
		_cam.global_position = m + Vector3(-6.0, 17.0, 24.0)
		_cam.look_at(m + Vector3(0, 0, -2.0), Vector3.UP)
	if _fps_n < 60:
		_fps_n += 1
		return false
	var fps := Engine.get_frames_per_second()
	_fps_sum += fps
	_fps_lo = minf(_fps_lo, fps)
	_fps_n += 1
	if _fps_n >= 300:
		print("D24_FPS tag=%s avg=%.1f min=%.1f over %d frames (noon clear, resting cam)" % [_tag, _fps_sum / float(_fps_n - 60), _fps_lo, _fps_n - 60])
		return true
	return false
