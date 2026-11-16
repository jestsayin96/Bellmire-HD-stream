extends SceneTree
## D19a full-day timelapse: the square through the day (Daylight.override_hour
## holds each hour still). Shows the sun arc + colour, dawn/dusk warmth, real
## night dark, and the lamps/windows + night bloom after dark.
## Run WINDOWED for real lighting. -> renders/cycles/20261112_d19a/*.png
var _t: Node3D
var _cam: Camera3D
var _dl
var _f := 0
var _out := ""
var _shots: Array = []   # [name, hour, cam_offset, look_offset]
var _i := 0
var _armed := -1

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d19a")
	DirAccess.make_dir_recursive_absolute(_out)

func _plan() -> void:
	var over := Vector3(-6.0, 17.0, 24.0)       # oblique over the square
	var near := Vector3(-3.0, 6.5, 12.0)        # lower, closer - reads the bloom
	var look := Vector3(0, 0.0, -2.0)
	_shots.append(["0_0400_night", 4.0, over, look])
	_shots.append(["1_0600_dawn", 6.0, over, look])
	_shots.append(["2_0800_morning", 8.0, over, look])
	_shots.append(["3_1200_noon", 12.0, over, look])
	_shots.append(["4_1600_afternoon", 16.0, over, look])
	_shots.append(["5_1830_dusk", 18.5, over, look])
	_shots.append(["6_2000_evening", 20.0, over, look])
	_shots.append(["7_2200_night", 22.0, over, look])
	_shots.append(["8_2230_night_close", 22.5, near, Vector3(0, 1.0, -2.0)])

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r: r.set("_raid_t", 999999.0)
		_cam = Camera3D.new()
		_cam.fov = 58.0
		_cam.far = 900.0
		_t.add_child(_cam)
		_plan()
	if _cam == null:
		return false
	if _cam != root.get_viewport().get_camera_3d():
		_cam.make_current()
	if _i >= _shots.size():
		return _f > 160
	var sh: Array = _shots[_i]
	var m: Vector3 = _t.get("_market_pos")
	if _armed != _i:
		if _dl: _dl.override_hour = float(sh[1])
		_cam.global_position = m + (sh[2] as Vector3)
		_cam.look_at(m + (sh[3] as Vector3), Vector3.UP)
		_armed = _i
		return false
	# hold a few frames so the sky/shadows/glow settle, then save
	if (_f % 10) == 0:
		root.get_texture().get_image().save_png(_out + "/%s.png" % sh[0])
		print("SAVED ", sh[0], " hour=", float(sh[1]), " night=", _dl.nightness(float(sh[1])))
		_i += 1
	return false
