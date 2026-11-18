extends SceneTree
## S38_RAMMER - the Rammer DROPS ON THE COUNT, measured through Delve._mb_way_tick on a real built
## floor: two delvers on the pile, one standing off. The haul strikes nobody; the whole blow lands
## after MB_DROP_HOLD, only on the pile; broken mid-hold, the iron never comes down. Also proves the
## flooded draw now reaches the Rammer (miniboss_for). Shots to renders/cycles/s38/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s38_rammer.gd
## Prints S38_RAMMER OK|FAIL.  S38_RED=1 loses the count (clears the hold): must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
const OUT := "res://renders/cycles/s38/"

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
	var names := ["Onpile", "Alsopile", "Standsoff"]
	for i in 3:
		var uid := "s38_%d" % i
		var h: Dictionary = r.fresh(uid, names[i], ["knight", "barbarian", "rogue"][i])
		var b := HeroBody.new(); b.setup(r, uid); b.town = _d; b.stay = true; _d.add_child(b)
		_d.party.append({"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}, "abil": []})
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _stand() -> void:
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "rammer"
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
	print("S38_SHOT ", n)

func _hps() -> Array:
	return _d.party.map(func(m): return float(m["hp"]))

func _drops() -> int:
	return int(Delve.setpieces_fired.get("miniboss_drop", 0))

func _haul() -> void:
	_mon.set_meta("mb_way_t", 0.0)
	_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
	if OS.get_environment("S38_RED") == "1" and _mon.has_meta("mb_drop_t"):
		_mon.remove_meta("mb_drop_t")

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
		_shot("rammer_1standing")
		var hit_n := 0
		for n in 400:
			if DungeonHD.miniboss_for("flooded", n) == "rammer":
				hit_n += 1
		_ok(hit_n > 0, "the flooded draw reaches the Rammer (%d of 400 n)" % hit_n)
		_ok(Delve.miniboss_ratio("rammer", Delve.miniboss_model("rammer")) == 1.12, "MB_FIT rammer 1.12")
		var d0 := _drops()
		var h0 := _hps()
		_haul()
		_ok(_mon.has_meta("mb_drop_t"), "the haul: the iron is up and holding")
		for i in 3:
			_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.5)
		_ok(_drops() == d0 and _hps() == h0, "nothing lands during the hold (1.5 s of %.1f)" % Delve.MB_DROP_HOLD)
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.6)
		_ok(_drops() == d0 + 1, "it comes down on the count (%d)" % (_drops() - d0))
		_ok(float(_d.party[2]["hp"]) == float(h0[2]), "the delver standing off is untouched")
		for k in 7:
			for m in _d.party:
				m["hp"] = 100.0
			_haul()
			_d._mb_way_tick(_mon, _d.party, _d.party[0], 2.1)
			_ok(float(_d.party[2]["hp"]) == 100.0, "drop %d: off the pile, untouched" % (k + 2))
		print("  DROPS ", _drops() - d0, " STRUCK ", Delve.rammer_struck, " READ ", Delve.rammer_read)
		_ok(Delve.rammer_struck >= 1, "the count strikes someone on the pile (%d)" % Delve.rammer_struck)
		_ok(Delve.rammer_struck + Delve.rammer_read == 2 * (_drops() - d0), "every on-pile delver is struck or read it (%d+%d vs 2x%d)" % [Delve.rammer_struck, Delve.rammer_read, _drops() - d0])
	if _f == 40:
		_shot("rammer_2after")
		print("  FEED: ", " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return String(x)))))
		# S39: one drop that RESOLVES ON CAMERA - repeat until the count strikes someone, then shoot it
		var s0 := Delve.rammer_struck
		var r0 := _rings()
		for k in 12:
			for m in _d.party:
				m["hp"] = 100.0
			_haul()
			_d._mb_way_tick(_mon, _d.party, _d.party[0], 2.1)
			if Delve.rammer_struck > s0:
				break
		_ok(Delve.rammer_struck > s0, "S39: a drop on camera struck someone on the pile")
		_ok(_rings() > r0, "S39: the count is seen - a shock ring spawned (%d)" % (_rings() - r0))
		_ok(_hps().any(func(x): return x < 100.0), "S39: a delver is hurt in the drop shot")
	if _f == 48:
		_shot("rammer_3drop")
	if _f == 49:
		# broken mid-hold: the rope parts and the iron never comes down
		_haul()
		var d1 := _drops()
		_mon.hp = _mon.max_hp * 0.2
		_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
		_ok(not _mon.has_meta("mb_drop_t"), "broken: the hold is cleared")
		for i in 6:
			_d._mb_way_tick(_mon, _d.party, _d.party[0], 1.0)
		_ok(_drops() == d1, "broken: no drop after the rope parts")
		_ok(not Delve.setpieces_fired.has("order_held"), "order_held is not in setpieces_fired")
		return _finish()
	return false

func _rings() -> int:
	var n := 0
	for c in root.find_children("*", "MeshInstance3D", true, false):
		if (c as MeshInstance3D).mesh is TorusMesh:
			n += 1
	return n

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 10:
		print("S38_RAMMER OK (%d checks)" % _checks)
	else:
		print("S38_RAMMER FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
