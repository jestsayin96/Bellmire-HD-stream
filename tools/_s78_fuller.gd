extends SceneTree
## S78_FULLER - the Fuller KEEPS EVERY BLOW and gives them back at once, measured through
## Delve._mb_way_tick on a real built floor: two delvers under the stocks, one standing off. Acts
## below MB_WRING_FULL hurt nobody; the act that fills the trough wrings it on those under it only
## and empties it; broken, the store is spilled and never given back. Also proves the fogbound
## draw reaches the Fuller. Shots to renders/cycles/s78/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s78_fuller.gd
## Prints S78_FULLER OK|FAIL.  S78_RED=1 spills the trough after every act: must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
const OUT := "res://renders/cycles/s78/"

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
	var names := ["Understocks", "Alsounder", "Standsoff"]
	for i in 3:
		var uid := "s78_%d" % i
		var h: Dictionary = r.fresh(uid, names[i], ["knight", "barbarian", "rogue"][i])
		var b := HeroBody.new(); b.setup(r, uid); b.town = _d; b.stay = true; _d.add_child(b)
		_d.party.append({"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}, "abil": []})
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _stand() -> void:
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "fuller"
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_mon.hp = _mon.max_hp * 50.0; _mon.max_hp = _mon.hp
	var mp := _mon.global_position
	for i in 3:
		var a := TAU * float(i) / 3.0
		var r := 1.4 if i < 2 else 6.0
		var b: HeroBody = _d.party[i]["body"]
		b.global_position = Vector3(mp.x + cos(a) * r, 0.0, mp.z + sin(a) * r)
	set_meta("cam", [mp + Vector3(6.0, 8.0, 6.0), mp + Vector3(0, 1.0, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S78_SHOT ", n)

func _hps() -> Array:
	return _d.party.map(func(m): return float(m["hp"]))

func _wrings() -> int:
	return int(Delve.setpieces_fired.get("miniboss_wring", 0))

func _act() -> void:
	_mon.set_meta("mb_way_t", 0.0)
	_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
	if OS.get_environment("S78_RED") == "1":
		_mon.set_meta("mb_store", 0.0)

func _heal() -> void:
	for m in _d.party:
		m["hp"] = 100.0

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
		_shot("fuller_1standing")
		var hit_n := 0
		for n in 400:
			if DungeonHD.miniboss_for("fogbound", n) == "fuller":
				hit_n += 1
		_ok(hit_n > 0, "the fogbound draw reaches the Fuller (%d of 400 n)" % hit_n)
		_ok(Delve.miniboss_ratio("fuller", Delve.miniboss_model("fuller")) == 1.09, "MB_FIT fuller 1.09")
		_ok(String(Delve.MB_WAYS.get("fuller", "")) == "wring", "MB_WAYS fuller = wring")
		var w0 := _wrings()
		var acts0 := int(Delve.setpieces_fired.get("miniboss_act_wring", 0))
		_act()
		_ok(_wrings() == w0 and _hps() == [100.0, 100.0, 100.0], "an act with nothing landed wrings nothing")
		_ok(int(Delve.setpieces_fired.get("miniboss_act_wring", 0)) == acts0 + 1, "the act fires and is counted")
		_mon.hp -= _mon.max_hp * 0.10
		_act()
		_ok(_wrings() == w0 and _hps() == [100.0, 100.0, 100.0], "10% landed: kept, not given back")
		_ok(absf(float(_mon.get_meta("mb_store", 0.0)) - _mon.max_hp * 0.10) < 0.5, "the trough holds the 10%% (%.0f)" % float(_mon.get_meta("mb_store", 0.0)))
		_mon.hp -= _mon.max_hp * 0.12
		_act()
		_ok(_wrings() == w0 + 1, "22%% landed: the trough is full and it wrings (%d)" % (_wrings() - w0))
		_ok(float(_d.party[0]["hp"]) < 100.0 and float(_d.party[1]["hp"]) < 100.0, "both under the stocks are struck (%s)" % str(_hps()))
		_ok(float(_d.party[2]["hp"]) == 100.0, "the delver standing off is untouched")
		_ok(float(_mon.get_meta("mb_store", -1.0)) == 0.0, "the trough is empty after the wring")
		_heal()
		_act()
		_ok(_hps() == [100.0, 100.0, 100.0] and _wrings() == w0 + 1, "the act after the wring gives nothing back")
		# the wring again, for the camera: fill it and shoot the ring
		_mon.hp -= _mon.max_hp * 0.25
		_act()
		_ok(_wrings() == w0 + 2, "filled again, it wrings again")
		print("  WRINGS ", _wrings() - w0, " STRUCK ", Delve.fuller_struck, " HPS ", _hps())
	if _f == 26:
		_shot("fuller_2wring")
		print("  FEED: ", " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return String(x)))))
	if _f == 30:
		# broken with a store in the trough: spilled, never given back
		_heal()
		_mon.hp -= _mon.max_hp * 0.15
		_act()
		_ok(float(_mon.get_meta("mb_store", 0.0)) > 0.0, "a store is in the trough before it breaks")
		var w1 := _wrings()
		_mon.hp = _mon.max_hp * 0.2
		_act()
		_ok(bool(_mon.get_meta("mb_broken", false)) and not _mon.has_meta("mb_store"), "broken: the trough cracks, the store is spilled")
		for i in 4:
			_mon.hp -= _mon.max_hp * 0.02
			_act()
		_ok(_wrings() == w1 and _hps() == [100.0, 100.0, 100.0], "broken: nothing is wrung after the crack")
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 12:
		print("S78_FULLER OK (%d checks)" % _checks)
	else:
		print("S78_FULLER FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
