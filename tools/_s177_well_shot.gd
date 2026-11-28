extends SceneTree
## S177: the square's well at town levels 1, 3 and 6 from one eye, with WELL_TIER_MESHES on.
## Verdict: S177_WELL OK only if every level resolved a tier mesh AND the paths are not all the same
## (the well must visibly change). Windowed. -> renders/cycles/20261128_s177/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""
var _paths: Array = []

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/20261128_s177/")
	DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)

func _plan() -> void:
	var w: Vector3 = _t.get("_well_at")
	for lv in [1, 3, 6]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 1.2, 0), w + Vector3(7.0, 5.0, 9.0)), "well_level%d" % lv, lv])
	for lv in [1, 3, 6]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 1.0, 0), w + Vector3(-22.0, 16.0, 26.0)), "square_level%d" % lv, lv])

func _process(_d: float) -> bool:
	_f += 1
	if _f == 15:
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 60.0
		_t.get("raids").set("_raid_t", 99999.0)
		_plan()
	if _f > 15:
		(_t.get("economy") as Economy).clock = 12.5 / 24.0
	if _f >= 20:
		var i := int((_f - 20) / 25)
		var k := (_f - 20) % 25
		if i >= _steps.size():
			var ok := true
			for p in _paths:
				if String(p) == "":
					ok = false
			var distinct := {}
			for p in _paths:
				distinct[p] = true
			if distinct.size() < 2:
				ok = false
			print(("S177_WELL OK " if ok else "S177_WELL FAIL "), _paths)
			return true
		if k == 0:
			(_steps[i][0] as Callable).call()
		if k == 24:
			var nm: String = _steps[i][1]
			root.get_texture().get_image().save_png(_dir + nm + ".png")
			if nm.begins_with("well_"):
				_paths.append(String(_t.get("_well_path")))
			print("SAVED ", nm, " lv=", _steps[i][2], " well=", _t.get("_well_path"))
	return false
