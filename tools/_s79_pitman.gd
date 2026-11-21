extends SceneTree
## S79_PITMAN - the Pitman OPENS THE FLOOR, measured through Delve._mb_way_tick on a real built floor.
## HOLD arm first, on content's real data: by_key.pitman has no act lines, so an act opens no pit.
## Then the act lines are FED IN MEMORY ONLY (test strings, never written to data/): the act opens a
## pit under the nearest delver, who loses MB_PIT_BEAT off their swing; a second delver walking onto
## it goes in too, once per MB_PIT_CLIMB; pits are capped at MB_PIT_MAX; broken, no new pit opens but
## the old ones still take people (the pit stays). Shots to renders/cycles/s79/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s79_pitman.gd
## Prints S79_PITMAN OK|FAIL.  S79_RED=1 fills every pit in after each act: must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
const OUT := "res://renders/cycles/s79/"

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
	var names := ["Dugunder", "Walksin", "Standsoff"]
	for i in 3:
		var uid := "s79_%d" % i
		var h: Dictionary = r.fresh(uid, names[i], ["knight", "barbarian", "rogue"][i])
		var b := HeroBody.new(); b.setup(r, uid); b.town = _d; b.stay = true; _d.add_child(b)
		_d.party.append({"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}, "abil": []})
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _stand() -> void:
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "pitman"
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_mon.hp = _mon.max_hp * 50.0; _mon.max_hp = _mon.hp
	var mp := _mon.global_position
	for i in 3:
		var a := TAU * float(i) / 3.0
		var r := 1.6 if i < 2 else 6.0
		var b: HeroBody = _d.party[i]["body"]
		b.global_position = Vector3(mp.x + cos(a) * r, 0.0, mp.z + sin(a) * r)
	set_meta("cam", [mp + Vector3(5.0, 7.0, 5.0), mp + Vector3(0, 0.5, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S79_SHOT ", n)

func _sw() -> Array:
	return _d.party.map(func(m): return snappedf(float(m["swing"]), 0.01))

func _pits() -> int:
	return (_mon.get_meta("mb_pits", []) as Array).size()

func _act() -> void:
	_mon.set_meta("mb_way_t", 0.0)
	_d._mb_way_tick(_mon, _d.party, _d.party[0], 0.01)
	if OS.get_environment("S79_RED") == "1" and _mon.has_meta("mb_pits"):
		_mon.remove_meta("mb_pits")

func _idle(dt: float) -> void:
	_mon.set_meta("mb_way_t", 99.0)
	_d._mb_way_tick(_mon, _d.party, _d.party[0], dt)

func _zero() -> void:
	for m in _d.party:
		m["swing"] = 0.0

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
		_shot("pitman_1standing")
		_ok(String(Delve.MB_WAYS.get("pitman", "")) == "pit", "MB_WAYS pitman = pit")
		var hit_n := 0
		for n in 400:
			if DungeonHD.miniboss_for("crypt", n) == "pitman":
				hit_n += 1
		_ok(hit_n > 0, "the crypt draw still reaches the Pitman (%d of 400 n)" % hit_n)
		# HOLD arm, content's real rows: no act lines -> nothing is dug
		var real_act := Delve.miniboss_lines("pitman", "act")
		print("  content by_key.pitman act lines on disk: %d" % real_act.size())
		if real_act.is_empty():
			_act()
			_ok(_pits() == 0 and _sw() == [0.0, 0.0, 0.0] and Delve.pitman_fell == 0, "HOLD: no act lines on disk, no pit opens")
		else:
			_ok(true, "HOLD lifted: content's act lines are on disk (%d)" % real_act.size())
		# FED in memory only - test strings, never saved
		var bk: Dictionary = Delve.lore()["miniboss_feed"]["by_key"]
		if not (bk["pitman"] as Dictionary).has("act"):
			bk["pitman"]["act"] = ["[S79 TEST act] The floor goes from under {name}."]
			bk["pitman"]["broken"] = ["[S79 TEST broken] The pick snaps."]
		var acts0 := int(Delve.setpieces_fired.get("miniboss_act_pit", 0))
		_act()
		_ok(int(Delve.setpieces_fired.get("miniboss_act_pit", 0)) == acts0 + 1, "the act fires and is counted")
		_ok(_pits() == 1, "one pit opens (%d)" % _pits())
		var pv: Vector3 = (_mon.get_meta("mb_pits", [[Vector3.INF]]) as Array)[0][0]
		var b0 := (_d.party[0]["body"] as Node3D).global_position
		_ok(Vector2(pv.x - b0.x, pv.z - b0.z).length() < 0.05, "it opens UNDER the nearest delver")
		_ok(_sw()[0] == Delve.MB_PIT_BEAT and Delve.pitman_fell == 1, "the one dug under loses a beat (%s)" % str(_sw()))
		_ok(_sw()[1] == 0.0 and _sw()[2] == 0.0, "nobody else loses one")
		# the pit stays: the second delver walks onto it
		(_d.party[1]["body"] as Node3D).global_position = Vector3(pv.x + 0.3, 0.0, pv.z)
		_idle(0.01)
		_ok(_sw()[1] == Delve.MB_PIT_BEAT, "walking onto the open pit, a second delver goes in (%s)" % str(_sw()))
		_idle(0.5)
		_ok(_sw()[1] == Delve.MB_PIT_BEAT, "climbing out: no second fall inside MB_PIT_CLIMB")
		_idle(Delve.MB_PIT_CLIMB)
		_idle(0.01)
		_ok(_sw()[1] == Delve.MB_PIT_BEAT * 2.0, "still standing in it after the climb: in again (%s)" % str(_sw()))
		_ok(_sw()[2] == 0.0, "the delver standing off never goes in")
		(_d.party[1]["body"] as Node3D).global_position = b0 + Vector3(4.0, 0, 0)
		(_d.party[0]["body"] as Node3D).global_position = b0 + Vector3(0, 0, 1.8)   # off the mouth, so the shot shows it
	if _f == 26:
		_shot("pitman_2pit")
		print("  FEED: ", " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return String(x)))))
	if _f == 30:
		for i in 4:
			(_d.party[0]["body"] as Node3D).global_position += Vector3(0.0, 0.0, 2.2)
			_d.party[0]["pit_out"] = 0.0
			_act()
		_ok(_pits() == Delve.MB_PIT_MAX, "pits are capped at MB_PIT_MAX (%d)" % _pits())
		# broken: no new pit, but the old ones stay in the floor
		_zero()
		_mon.hp = _mon.max_hp * 0.2
		_act()
		_ok(bool(_mon.get_meta("mb_broken", false)), "broken at MB_BROKEN_FRAC")
		var n0 := _pits()
		(_d.party[0]["body"] as Node3D).global_position += Vector3(0.0, 0.0, 2.2)
		_act()
		_ok(_pits() == n0, "broken: it stops digging")
		var last: Vector3 = (_mon.get_meta("mb_pits", [[Vector3.INF]]) as Array).back()[0]
		_d.party[1]["pit_out"] = 0.0
		(_d.party[1]["body"] as Node3D).global_position = last
		_idle(0.01)
		_ok(_sw()[1] == Delve.MB_PIT_BEAT, "broken: the pit stays and still takes a delver (%s)" % str(_sw()))
		print("  FELL ", Delve.pitman_fell, " PITS ", _pits())
		Delve._lore = {}                               # drop the in-memory test lines
		print("  test lines dropped; lore reloads from disk: act lines %d" % Delve.miniboss_lines("pitman", "act").size())
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 15:
		print("S79_PITMAN OK (%d checks)" % _checks)
	else:
		print("S79_PITMAN FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
