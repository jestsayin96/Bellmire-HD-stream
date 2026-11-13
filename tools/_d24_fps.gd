extends SceneTree
## D24 uncapped FPS at the resting stream camera, noon clear, 1080p, vsync OFF.
## `-- before` forces TAA/MSAA off; `-- after` forces TAA on + MSAA 2x (the shipped
## project.godot values). Lets before/after be compared without reverting the project.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _tag := "run"
var _n := 0
var _sum := 0.0
var _lo := 1e9

func _initialize() -> void:
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 0:
		_tag = String(ua[0])
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		var vp := root.get_viewport()
		if _tag == "before":
			vp.use_taa = false
			vp.msaa_3d = Viewport.MSAA_DISABLED
		else:
			vp.use_taa = true
			vp.msaa_3d = Viewport.MSAA_2X
		var dl = _t.get("daylight")
		if dl:
			dl.override_hour = 12.0
			dl.set_weather("clear", true)
		var r = _t.get("raids")
		if r:
			r.set("_raid_t", 999999.0)
		_cam = Camera3D.new()
		_cam.fov = 58.0
		_cam.far = 900.0
		_t.add_child(_cam)
		var m: Vector3 = _t.get("_market_pos")
		_cam.global_position = m + Vector3(-6.0, 17.0, 24.0)
		_cam.look_at(m + Vector3(0, 0, -2.0), Vector3.UP)
		_cam.make_current()
		print("D24FPS_AA tag=%s use_taa=%s msaa_3d=%d" % [_tag, str(vp.use_taa), int(vp.msaa_3d)])
	if _cam == null:
		return false
	# settle 60 frames after camera set, then sample 300
	if _f < 150:
		return false
	var fps := Engine.get_frames_per_second()
	if fps > 0.0:
		_sum += fps
		_lo = minf(_lo, fps)
		_n += 1
	if _n >= 300:
		print("D24FPS tag=%s avg=%.1f min=%.1f over %d frames (noon clear, resting cam, vsync off, 1080p)" % [_tag, _sum / float(_n), _lo, _n])
		return true
	return false
