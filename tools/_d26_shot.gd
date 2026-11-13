extends SceneTree
## D26 roof decal/tint check. Overview of the districts' roofs + a close-up on a
## GREEN-livery roof (the "moss paint" Mr. E flagged). Run WINDOWED. `-- before/after`.
## -> renders/cycles/20261112_d26/<tag>_*.png
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
	if ua.size() > 0:
		_tag = String(ua[0])
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d26")
	DirAccess.make_dir_recursive_absolute(_out)

func _green_roof_pos() -> Vector3:
	var plots: Array = _t.get("plots")
	var livery_of: Dictionary = _t.get("livery_of")
	for p in plots:
		var d = p.get("district")
		if String(livery_of.get(d, "")) == "green":
			var pos = p.get("pos")
			return pos as Vector3
	return Vector3.ZERO

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		_dl = _t.get("daylight")
		var r = _t.get("raids")
		if r:
			r.set("_raid_t", 999999.0)
		_cam = Camera3D.new()
		_cam.fov = 55.0
		_cam.far = 1200.0
		_t.add_child(_cam)
		var m: Vector3 = _t.get("_market_pos")
		var g := _green_roof_pos()
		print("D26 green_roof_pos=", g)
		# overview looking down over the districts
		_shots.append(["overview", 12.0, m + Vector3(0, 70.0, 95.0), m])
		# close-up on a green-livery roof
		if g != Vector3.ZERO:
			_shots.append(["green_roof", 12.0, g + Vector3(8.0, 10.0, 12.0), g + Vector3(0, 3.0, 0)])
		# a second overview from the opposite side to catch more roofs
		_shots.append(["overview2", 12.0, m + Vector3(-90.0, 55.0, -40.0), m])
	if _cam == null:
		return false
	if _cam != root.get_viewport().get_camera_3d():
		_cam.make_current()
	if _i < _shots.size():
		var sh: Array = _shots[_i]
		if _armed != _i:
			if _dl:
				_dl.override_hour = float(sh[1])
				_dl.set_weather("clear", true)
			_cam.global_position = sh[2] as Vector3
			_cam.look_at(sh[3] as Vector3, Vector3.UP)
			_armed = _i
			_hold = 0
			return false
		_hold += 1
		if _hold >= 55:
			root.get_texture().get_image().save_png(_out + "/%s_%s.png" % [_tag, sh[0]])
			print("SAVED ", _tag, "_", sh[0])
			_i += 1
		return false
	return true
