extends SceneTree
## S36_ORDER - LOOK at the Beadle calling the order on a real built floor, and MEASURE it through the
## real fight loop (Delve._fight_body): three delvers at its side, it calls one, and for the next
## frames only the called hero swings while the other two hold. Shots to renders/cycles/s36/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s36_order.gd
## Prints S36_ORDER OK|FAIL.  S36_RED=1 breaks the order (clears the call each frame): must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
var _swings := {}
var _last := {}
const OUT := "res://renders/cycles/s36/"

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
	var names := ["Called", "Holdfast", "Waiting"]
	for i in 3:
		var uid := "s36_%d" % i
		var h: Dictionary = r.fresh(uid, names[i], ["knight", "barbarian", "rogue"][i])
		var b := HeroBody.new(); b.setup(r, uid); b.town = _d; b.stay = true; _d.add_child(b)
		_d.party.append({"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}, "abil": []})
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _stand() -> void:
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "beadle"
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_mon.hp = _mon.max_hp * 50.0; _mon.max_hp = _mon.hp        # it must outlast the measurement
	var mp := _mon.global_position
	for i in 3:
		var a := TAU * float(i) / 3.0
		var b: HeroBody = _d.party[i]["body"]
		b.global_position = Vector3(mp.x + cos(a) * 1.4, 0.0, mp.z + sin(a) * 1.4)
	set_meta("cam", [mp + Vector3(4.0, 7.0, 4.0), mp + Vector3(0, 1.0, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S36_SHOT ", n)

func _process(_dt: float) -> bool:
	_f += 1
	if _sp.is_empty():
		_fails.append("no miniboss floor"); return _finish()
	if _f == 2:
		_stand()
	if _mon == null:
		return false
	if has_meta("cam") and _cam.is_inside_tree():
		var cv: Array = get_meta("cam")
		_cam.position = cv[0]
		_cam.look_at(cv[1])
	if _f == 20:
		_shot("beadle_1standing")
		_mon.set_meta("mb_way_t", 0.0)
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 1.0)       # it calls the nearest: party[0]
		_ok(_d._order_uid == "s36_0", "the Beadle called a hero (%s)" % _d._order_uid)
	if _f > 20 and _f <= 140:
		if OS.get_environment("S36_RED") == "1":
			_d._order_uid = ""
		_mon.state = Monster.S.IDLE
		for m in _d.party:
			_last[m["uid"]] = float(m["swing"])
		_d._fight_body(0.1, _d.party.duplicate(), [_mon])
		for m in _d.party:
			if float(m["swing"]) > float(_last[m["uid"]]):
				_swings[m["uid"]] = int(_swings.get(m["uid"], 0)) + 1
	if _f == 141:
		_shot("beadle_2order")
		print("  SWINGS: ", _swings)
		print("  FEED: ", " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return String(x)))))
		_ok(int(_swings.get("s36_0", 0)) >= 3, "the called hero swings (%d)" % int(_swings.get("s36_0", 0)))
		_ok(int(_swings.get("s36_1", 0)) == 0 and int(_swings.get("s36_2", 0)) == 0,
			"the other two hold (%d, %d)" % [int(_swings.get("s36_1", 0)), int(_swings.get("s36_2", 0))])
		_ok(Delve.order_held_frames > 0 and not Delve.setpieces_fired.has("order_held"),
			"S38: holds counted in order_held_frames (%d), not in setpieces_fired" % Delve.order_held_frames)
		# break it: the order lapses and the rest act again
		_mon.hp = _mon.max_hp * 0.2
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 1.0)
		_swings.clear()
		for i in 60:
			for m in _d.party:
				_last[m["uid"]] = float(m["swing"])
			_mon.state = Monster.S.IDLE
			_d._fight_body(0.1, _d.party.duplicate(), [_mon])
			for m in _d.party:
				if float(m["swing"]) > float(_last[m["uid"]]):
					_swings[m["uid"]] = int(_swings.get(m["uid"], 0)) + 1
		print("  SWINGS AFTER BROKEN: ", _swings)
		_ok(int(_swings.get("s36_1", 0)) >= 1 and int(_swings.get("s36_2", 0)) >= 1, "broken: the rest act again")
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 4:
		print("S36_ORDER OK (%d checks)" % _checks)
	else:
		print("S36_ORDER FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
