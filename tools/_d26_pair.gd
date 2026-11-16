extends SceneTree
## D26 true A/B: same green-livery roof, old tint vs new tint, by toggling the
## shared _roof["green"] material color at runtime. Run WINDOWED.
## -> renders/cycles/20261112_d26/pair_green_{old,new}.png
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _out := ""
var _stage := 0
var _hold := 0
var _gpos := Vector3.ZERO

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261112_d26")
	DirAccess.make_dir_recursive_absolute(_out)

func _green_pos() -> Vector3:
	var plots: Array = _t.get("plots")
	var lo: Dictionary = _t.get("livery_of")
	for p in plots:
		if String(lo.get(p.get("district"), "")) == "green":
			return p.get("pos") as Vector3
	return Vector3.ZERO

func _set_green(c: Color) -> void:
	var roof: Dictionary = _t.get("_roof")
	if roof.has("green"):
		(roof["green"] as StandardMaterial3D).albedo_color = c

func _process(_d: float) -> bool:
	_f += 1
	if _f == 90:
		var dl = _t.get("daylight")
		if dl:
			dl.override_hour = 12.0
			dl.set_weather("clear", true)
		var r = _t.get("raids")
		if r: r.set("_raid_t", 999999.0)
		_gpos = _green_pos()
		_cam = Camera3D.new()
		_cam.fov = 42.0
		_cam.far = 900.0
		_t.add_child(_cam)
		_cam.global_position = _gpos + Vector3(5.0, 15.0, 15.0)
		_cam.look_at(_gpos + Vector3(0, 5.0, 0), Vector3.UP)
		_cam.make_current()
		print("D26PAIR green_pos=", _gpos)
	if _cam == null:
		return false
	if _stage == 0:
		_set_green(Color(0.62, 0.84, 0.60))   # old
	elif _stage == 2:
		_set_green(Color(0.78, 0.85, 0.74))   # new
	_hold += 1
	if _hold >= 45:
		_hold = 0
		if _stage == 0:
			root.get_texture().get_image().save_png(_out + "/pair_green_old.png"); print("SAVED pair_green_old"); _stage = 2
		elif _stage == 2:
			root.get_texture().get_image().save_png(_out + "/pair_green_new.png"); print("SAVED pair_green_new"); return true
	return false
