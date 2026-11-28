extends SceneTree
## S178: the Chief's Hall at town levels 1, 5 and 9 (content's hall tier_levels) from two eyes,
## with HALL_TIER_MESHES on. Verdict: S178_HALL OK only if every level resolved a tier mesh AND all
## three paths match the expected tier mapping (the hall must visibly change). Windowed. -> renders/cycles/20261128_s178/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""
var _paths: Array = []

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/20261128_s178/")
	DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)

func _plan() -> void:
	var h: Node3D = _t.get("_hall_node")
	var w: Vector3 = h.global_position
	var fz: Vector3 = h.global_transform.basis.z.normalized()
	var sd: Vector3 = Vector3(-fz.z, 0, fz.x)
	for lv in [1, 5, 9]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 3.0, 0), w + fz * 26.0 + sd * 12.0 + Vector3(0, 11.0, 0)), "hall_level%d" % lv, lv])
	for lv in [1, 5, 9]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 2.0, 0), w + fz * 44.0 - sd * 30.0 + Vector3(0, 28.0, 0)), "wide_level%d" % lv, lv])

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
			# exact mapping: L1 -> t1, L5 -> t2, L9 -> lm_hall ("" while HALL_T3_FITS is false).
			# Flag off gives ["", "", ""] and fails; a missing tier gives a wrong path and fails.
			var want: Array = ["res://assets/buildings/town_hall_t1.glb", "res://assets/buildings/town_hall_t2.glb",
				"res://assets/buildings/town_hall_t3.glb" if bool(_t.get("HALL_T3_FITS")) else ""]
			var ok := _paths.size() == 3
			for j in range(mini(_paths.size(), 3)):
				if String(_paths[j]) != String(want[j]):
					ok = false
			print(("S178_HALL OK " if ok else "S178_HALL FAIL "), _paths)
			return true
		if k == 0:
			(_steps[i][0] as Callable).call()
		if k == 24:
			var nm: String = _steps[i][1]
			root.get_texture().get_image().save_png(_dir + nm + ".png")
			if nm.begins_with("hall_"):
				_paths.append(String(_t.get("_hall_path")))
			print("SAVED ", nm, " lv=", _steps[i][2], " hall=", _t.get("_hall_path"))
	return false
