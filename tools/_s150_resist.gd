extends SceneTree
## S150_RESIST - a blow the Thatcher's roof zeroes is LABELLED "resist" on every path, not only the swing.
## (S149 setup reused.) Cleave, thorns and luck each strike a roofed creature; its D61.1 result counter must
## read "resist", never "hit". S150_RED=1 opens the roof (drops mb_key) before cleave: must FAIL.
## A second creature is stood 3 m from the Thatcher and struck: while the Thatcher stands unbroken it
## takes 0; the Thatcher itself takes the blow; a creature beyond MB_THATCH_R takes it; once the
## Thatcher is BROKEN (hp under MB_BROKEN_FRAC) the neighbour takes it again; act tick voices it.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s150_resist.gd
## Prints S150_RESIST OK|FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _sp: Dictionary
var _d: Delve
var _mon: Monster
const OUT := "res://renders/cycles/s150/"

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

var _mark: Monster

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S150_SHOT ", n)

func _n(t: Monster, k: String) -> int:
	return int(t.results_shown.get(k, 0))

func _process(_dt: float) -> bool:
	_f += 1
	if _sp.is_empty():
		_fails.append("no miniboss floor"); return _finish()
	if _f == 2:
		_stand()
		_mark = _d._call_one(_mon, {"type": "bones"}, _mon.global_position + Vector3(4.0, 0, 0))
		_mark.state = Monster.S.IDLE; _mark.roam = 0.0; _mark.hp = 5000.0; _mark.max_hp = 5000.0
		_nb.hp = 5000.0; _nb.max_hp = 5000.0
	if _mon == null:
		return false
	if has_meta("cam") and _cam.is_inside_tree():
		var cv: Array = get_meta("cam")
		_cam.position = cv[0]
		_cam.look_at(cv[1])
	if _f == 40:
		_shot("resist_1roofed")
		_ok(_d._thatch(_nb) == 0.0 and _d._thatch(_mark) == 0.0, "both neighbours stand under the roof")
		if OS.get_environment("S150_RED") == "1":
			_mon.remove_meta("mb_key")
		var r0 := _n(_nb, "resist"); var h0 := _n(_nb, "hit"); var hp0 := _nb.hp
		_d._ability_hit_one("cleave", _d.party[0], _mark, 20.0, [_mark, _nb])
		_ok(_n(_nb, "resist") == r0 + 1 and _n(_nb, "hit") == h0, "CLEAVE into a roofed foe reads resist (resist +%d, hit +%d)" % [_n(_nb, "resist") - r0, _n(_nb, "hit") - h0])
		_mon.set_meta("mb_key", "thatcher")
		_ok(_nb.hp == hp0, "and still deals 0 (took %.1f)" % (hp0 - _nb.hp))
		r0 = _n(_nb, "resist"); h0 = _n(_nb, "hit")
		_d._ability_hit_one("thorns", _d.party[0], _mark, 20.0, [_mark, _nb])
		_ok(_n(_nb, "resist") == r0 + 1 and _n(_nb, "hit") == h0, "THORNS onto a roofed foe reads resist (resist +%d, hit +%d)" % [_n(_nb, "resist") - r0, _n(_nb, "hit") - h0])
		var mr := _n(_mark, "resist"); var mh := _n(_mark, "hit")
		for i in 400:
			_d._ability_hit_one("luck", _d.party[0], _mark, 20.0, [_mark])
		_ok(_n(_mark, "resist") > mr and _n(_mark, "hit") == mh, "LUCK on a warded/roofed foe reads resist (resist +%d, hit +%d of 400 tries)" % [_n(_mark, "resist") - mr, _n(_mark, "hit") - mh])
		var fr := _n(_far, "resist"); var fh := _n(_far, "hit")
		_far.global_position = _mon.global_position + Vector3(Delve.MB_THATCH_R + 4.0, 0, 0)
		var m2 := _d._call_one(_mon, {"type": "bones"}, _far.global_position + Vector3(1.0, 0, 0))
		m2.state = Monster.S.IDLE; m2.roam = 0.0; m2.hp = 5000.0; m2.max_hp = 5000.0
		_d._ability_hit_one("cleave", _d.party[0], m2, 20.0, [m2, _far])
		_ok(_n(_far, "hit") == fh + 1 and _n(_far, "resist") == fr, "beyond the roof a cleave still reads hit (hit +%d, resist +%d)" % [_n(_far, "hit") - fh, _n(_far, "resist") - fr])
	if _f == 60:
		_shot("resist_2after")
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty():
		print("S150_RESIST OK %d checks" % _checks)
	else:
		print("S150_RESIST FAIL %d of %d: %s" % [_fails.size(), _checks, str(_fails)])
	quit()
	return true
