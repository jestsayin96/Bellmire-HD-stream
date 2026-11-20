extends SceneTree
## S34_LOOK - LOOK at two miniboss ideas acting on a real built floor: the Stoker growing (three logs)
## and the Gaoler's hook reeling the far delver in. Before/after shots to renders/cycles/s34/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s34_look.gd
## Prints S34_LOOK OK|FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
var _b: HeroBody
var _key := "stoker"
var _m0 := {}
const OUT := "res://renders/cycles/s34/"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var r := Roster.new(); root.add_child(r)
	_dh = DungeonHD.new(); root.add_child(_dh)
	for f in range(4, 120):
		_dh.floor_no = f
		_dh.build(f)
		var sps: Array = _dh.info.get("set_pieces", [])
		if not sps.is_empty() and String((sps[0] as Dictionary).get("kind", "")) == "miniboss":
			_sp = sps[0]
			break
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.light_energy = 1.4
	root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.22, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	root.add_child(env)
	var fake := GDScript.new(); fake.source_code = "extends Node3D\nvar feed := []\n"; fake.reload()
	var town := Node3D.new(); town.set_script(fake); root.add_child(town)
	_d = Delve.new(); _d.roster = r; _d.floor_no = int(_dh.floor_no); _d.town = town; root.add_child(_d); _d.dun = _dh
	var h: Dictionary = r.fresh("s34look", "Hookbait", "knight")
	_b = HeroBody.new(); _b.setup(r, "s34look"); _b.town = _d; _b.stay = true; _d.add_child(_b)
	_d.party = [{"uid": "s34look", "h": h, "body": _b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}}]
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)
	# stood in _process, once the stage is in the tree (global transforms need it)

func _stand(k: String) -> void:
	_key = k
	if _mon != null and is_instance_valid(_mon):
		_mon.queue_free()
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = k
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	# the far delver: the furthest floor cell within 8 m of the miniboss
	var best: Vector3 = _mon.global_position
	for c in (_dh.info["cells"] as Dictionary).keys():
		var w := _d._cell_world(c)
		var dd := _d._flat(w, _mon.global_position)
		if dd < 8.0 and dd > _d._flat(best, _mon.global_position):
			best = w
	_b.global_position = Vector3(best.x, 0.0, best.z)
	var mid := (_mon.global_position + _b.global_position) * 0.5
	var side := (_b.global_position - _mon.global_position).normalized().cross(Vector3.UP)
	# high and steep: a floor of 4 m cells walls in any low camera
	set_meta("cam", [mid + side * 3.0 + Vector3(0, 10.0, 0), mid + Vector3(0, 0.8, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S34_SHOT ", n)

func _process(_dt: float) -> bool:
	_f += 1
	if _sp.is_empty():
		_fails.append("no miniboss floor"); return _finish()
	if _f == 2:
		_stand("stoker")
	if _mon == null:
		return false
	_mon.state = Monster.S.IDLE
	if has_meta("cam") and _cam.is_inside_tree():
		var cv: Array = get_meta("cam")
		_cam.position = cv[0]
		_cam.look_at(cv[1])
	if _f == 30:
		_m0["h"] = _mon.scale.x
		_shot("stoker_1before")
		for i in 3:
			_mon.set_meta("mb_way_t", 0.0)
			_d._mb_way_tick(_mon, _d.party, _d.party[0], 1.0)
	if _f == 45:
		_shot("stoker_2after3logs")
		_ok(_mon.scale.x > 1.2 and _m0["h"] == 1.0, "stoker stands taller after three logs (x%.2f)" % _mon.scale.x)
		_stand("gaoler")
	if _f == 75:
		_m0["d"] = _d._flat(_b.global_position, _mon.global_position)
		_shot("gaoler_1before")
		_mon.set_meta("mb_way_t", 0.0)
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 1.0)
	if _f == 90:
		var d1 := _d._flat(_b.global_position, _mon.global_position)
		_shot("gaoler_2hooked")
		_ok(float(_m0["d"]) > 4.0 and d1 < 2.0, "the hook reels the delver in (%.1f m -> %.1f m)" % [float(_m0["d"]), d1])
		print("  FEED: ", " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return String(x)))))
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 2:
		print("S34_LOOK OK (%d checks)" % _checks)
	else:
		print("S34_LOOK FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
