extends SceneTree
## S179: the inn (the market tavern) at town levels 1, 5 and 9 from two eyes, with inn_tier_on
## forced true (INN_TIER_MESHES stays as committed). Verdict: S179_INN OK only if the three levels
## resolved town_inn_t1, t2, t3 in that order; anything else (flag ignored, no tavern plot, a tier
## missing) prints S179_INN FAIL. Windowed. -> renders/cycles/20261128_s179/
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _steps: Array = []
var _dir := ""
var _paths: Array = []

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/20261128_s179/")
	DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)

func _plan() -> bool:
	_t.set("inn_tier_on", true)
	var pl: Dictionary = {}
	for p in _t.get("plots"):
		if String(p.get("shop", "")) == "tavern" and is_instance_valid(p.get("node", null)):
			pl = p
			break
	if pl.is_empty():
		return false
	var h: Node3D = pl["node"]
	var w: Vector3 = h.global_position
	var fz: Vector3 = h.global_transform.basis.z.normalized()
	var sd: Vector3 = Vector3(-fz.z, 0, fz.x)
	print("INN_PLOT pos=", w, " yaw=", h.rotation.y, " yard=", pl.get("yard"), " side=", pl.get("side"))
	for lv in [1, 5, 9]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 3.0, 0), w + fz * 22.0 + sd * 10.0 + Vector3(0, 9.0, 0)), "inn_level%d" % lv, lv])
	for lv in [1, 5, 9]:
		_steps.append([func() -> void:
			_t.call("show_level", lv, true)
			_eye(w + Vector3(0, 2.0, 0), w + fz * 40.0 - sd * 26.0 + Vector3(0, 26.0, 0)), "wide_level%d" % lv, lv])
	return true

func _process(_d: float) -> bool:
	_f += 1
	if _f == 15:
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 60.0
		_t.get("raids").set("_raid_t", 99999.0)
		if not _plan():
			print("S179_INN FAIL no tavern plot")
			return true
	if _f > 15:
		(_t.get("economy") as Economy).clock = 12.5 / 24.0
	if _f >= 20:
		var i := int((_f - 20) / 25)
		var k := (_f - 20) % 25
		if i >= _steps.size():
			var want: Array = ["res://assets/buildings/town_inn_t1.glb", "res://assets/buildings/town_inn_t2.glb",
				"res://assets/buildings/town_inn_t3.glb"]
			var ok := _paths.size() == 3
			for j in range(mini(_paths.size(), 3)):
				if String(_paths[j]) != String(want[j]):
					ok = false
			print(("S179_INN OK " if ok else "S179_INN FAIL "), _paths)
			return true
		if k == 0:
			(_steps[i][0] as Callable).call()
		if k == 24:
			var nm: String = _steps[i][1]
			root.get_texture().get_image().save_png(_dir + nm + ".png")
			if nm.begins_with("inn_"):
				_paths.append(String(_t.get("_inn_path")))
			print("SAVED ", nm, " lv=", _steps[i][2], " inn=", _t.get("_inn_path"))
	return false
