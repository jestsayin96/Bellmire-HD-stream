extends SceneTree
## D19b shot sheet: the square across time AND weather - clear noon, overcast,
## rain, the dawn mist, dusk, a starry night, a rainy night, low-sun god-rays.
## Run WINDOWED for real lighting. Ends with a 240-frame FPS pass in the worst
## weather. -> renders/cycles/20261112_d19b/*.png
var _t: Node3D
var _cam: Camera3D
var _dl
var _f := 0
var _out := ""
var _shots: Array = []   # [name, hour, weather, cam_offset, look_offset]
var _i := 0
var _armed := -1
var _hold := 0
var _fps_n := 0
var _fps_sum := 0.0
var _fps_lo := 999999.0

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d19b")
	DirAccess.make_dir_recursive_absolute(_out)

func _plan() -> void:
	var over := Vector3(-6.0, 17.0, 24.0)
	var near := Vector3(-3.0, 6.5, 12.0)
	var wide := Vector3(-14.0, 24.0, 38.0)
	var look := Vector3(0, 0.0, -2.0)
	_shots.append(["0_noon_clear", 12.0, "clear", over, look])
	_shots.append(["1_noon_overcast", 12.0, "overcast", over, look])
	_shots.append(["2_noon_rain", 12.0, "rain", over, look])
	_shots.append(["3_dawn_mist", 6.3, "clear", wide, look])
	_shots.append(["4_morning_rays", 7.4, "clear", near, Vector3(6.0, 2.0, -8.0)])
	_shots.append(["5_dusk_clear", 18.5, "clear", over, look])
	_shots.append(["6_night_stars", 22.3, "clear", near, Vector3(0, 7.0, -14.0)])
	_shots.append(["7_night_rain", 22.0, "rain", near, Vector3(0, 1.0, -2.0)])
	_shots.append(["8_overcast_wide", 10.0, "overcast", wide, look])

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
		# hold 50 frames so clouds/volumetrics/rain fill, then save
		_hold += 1
		if _hold >= 50:
			root.get_texture().get_image().save_png(_out + "/%s.png" % sh[0])
			print("SAVED ", sh[0], " hour=", float(sh[1]), " wx=", String(sh[2]))
			_i += 1
		return false
	# FPS pass: noon rain (clouds + rain + volumetrics), the oblique camera
	if _fps_n == 0:
		if _dl:
			_dl.override_hour = 12.0
			_dl.set_weather("rain", true)
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
		print("D19B_FPS avg=%.1f min=%.1f over %d frames (noon rain)" % [_fps_sum / float(_fps_n - 60), _fps_lo, _fps_n - 60])
		return true
	return false
