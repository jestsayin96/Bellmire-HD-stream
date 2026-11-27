extends SceneTree
## S149_THATCH - the Thatcher ROOFS THE ROOM, measured through Delve._strike / _ward on a real built floor.
## A second creature is stood 3 m from the Thatcher and struck: while the Thatcher stands unbroken it
## takes 0; the Thatcher itself takes the blow; a creature beyond MB_THATCH_R takes it; once the
## Thatcher is BROKEN (hp under MB_BROKEN_FRAC) the neighbour takes it again; act tick voices it.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s149_thatch.gd
## Prints S149_THATCH OK|FAIL.  S149_RED=1 drops the Thatcher's mb_key before striking: must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
const OUT := "res://renders/cycles/s149/"

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
	var names := ["Roofer", "Reeder", "Sheafer"]
	for i in 3:
		var uid := "s149_%d" % i
		var h: Dictionary = r.fresh(uid, names[i], ["knight", "barbarian", "rogue"][i])
		var b := HeroBody.new(); b.setup(r, uid); b.town = _d; b.stay = true; _d.add_child(b)
		_d.party.append({"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}, "abil": []})
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

var _nb: Monster
var _far: Monster

func _stand() -> void:
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "thatcher"
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_mon.state = Monster.S.IDLE; _mon.roam = 0.0
	_mon.hp = 1000.0; _mon.max_hp = 1000.0
	var mp := _mon.global_position
	_nb = _d._call_one(_mon, {"type": "bones"}, mp + Vector3(3.0, 0, 0))
	_far = _d._call_one(_mon, {"type": "bones"}, mp + Vector3(Delve.MB_THATCH_R + 4.0, 0, 0))
	for x in [_nb, _far]:
		(x as Monster).state = Monster.S.IDLE; (x as Monster).roam = 0.0
		(x as Monster).hp = 500.0; (x as Monster).max_hp = 500.0
	for i in 3:
		var a := TAU * float(i) / 3.0
		var b: HeroBody = _d.party[i]["body"]
		b.global_position = Vector3(mp.x + cos(a) * 2.0, 0.0, mp.z + sin(a) * 2.0)
	set_meta("cam", [mp + Vector3(5.0, 7.0, 7.0), mp + Vector3(1.5, 0.5, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S149_SHOT ", n)

func _hit(t: Monster) -> float:
	var before := t.hp
	_d._strike(_d.party[0], t, 20.0, false)
	return before - t.hp

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
	if _f == 40:
		_shot("thatch_1standing")
		_ok(String(Delve.MB_WAYS.get("thatcher", "")) == "thatch", "MB_WAYS thatcher = thatch")
		var acts := Delve.miniboss_lines("thatcher", "act")
		_ok(not acts.is_empty(), "content's by_key.thatcher act lines on disk (%d)" % acts.size())
		_ok(String(_mon.get_meta("mb_key", "")) == "thatcher", "the stood miniboss carries mb_key thatcher")
		if OS.get_environment("S149_RED") == "1":
			_mon.remove_meta("mb_key")
		var dn := _hit(_nb)
		_mon.set_meta("mb_key", "thatcher")             # the RED arm only blinds the strike, not the act tick
		_ok(dn == 0.0, "UNDER THE ROOF: neighbour 3 m off took %.1f of a 20 blow (want 0)" % dn)
		var df := _hit(_far)
		_ok(df > 0.0, "beyond MB_THATCH_R: far creature took %.1f (want > 0)" % df)
		var dt := _hit(_mon)
		_ok(dt > 0.0, "the Thatcher itself is never roofed: took %.1f (want > 0)" % dt)
		_mon.set_meta("mb_way_t", 0.0)
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
		_ok(not bool(_mon.get_meta("mb_broken", false)), "an act tick does not break it")
		_mon.hp = _mon.max_hp * (Delve.MB_BROKEN_FRAC - 0.05)
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
		_ok(bool(_mon.get_meta("mb_broken", false)), "at MB_BROKEN_FRAC the tie is cut (mb_broken)")
		var dn2 := _hit(_nb)
		_ok(dn2 > 0.0, "ROOF OPEN: broken Thatcher, neighbour now took %.1f (want > 0)" % dn2)
	if _f == 60:
		_shot("thatch_2broken")
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty():
		print("S149_THATCH OK %d checks" % _checks)
	else:
		print("S149_THATCH FAIL %d of %d: %s" % [_fails.size(), _checks, str(_fails)])
	quit()
	return true
