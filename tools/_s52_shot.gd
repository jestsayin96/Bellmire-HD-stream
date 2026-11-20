extends SceneTree
## S52_SHOT (cut of S51_SHOT) - LOOK at the strickler standing on a real built floor under its
## directive name: def.name is Murkspit and the chamber line reads "Murkspit holds this chamber
## alone" with no "The" and no trade word. Shot to renders/cycles/s52/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s52_shot.gd
## Prints S52_SHOT OK|FAIL.
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
const OUT := "res://renders/cycles/s52/"

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
	var sp2: Dictionary = _sp.duplicate(); sp2["mb_key"] = "strickler"
	_d._setpiece_miniboss(sp2, sp2["pos"])
	_mon = (_dh.monsters as Array).back()
	_ok(String(_mon.def.get("name", "")) == "Murkspit", "S52: the strickler stands up as Murkspit (%s)" % _mon.def.get("name", ""))
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	var mp := _mon.global_position
	for i in 3:
		var a := TAU * float(i) / 3.0
		var b: HeroBody = _d.party[i]["body"]
		b.global_position = Vector3(mp.x + cos(a) * 1.4, 0.0, mp.z + sin(a) * 1.4)
	set_meta("cam", [mp + Vector3(4.0, 7.0, 4.0), mp + Vector3(0, 1.0, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S52_SHOT_FILE ", n)

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
	if _f == 24:
		_shot("strickler_murkspit")
		var feed := " | ".join(PackedStringArray((_d.town.get("feed") as Array).map(func(x): return str(x))))
		print("  FEED: ", feed)
		_ok(feed.contains("Murkspit holds this chamber alone"), "the hold line names Murkspit")
		_ok(not feed.contains("The Murkspit") and not feed.contains("Strickler holds"), "no The, no trade word on the hold line")
		_ok(_mon.is_inside_tree() and _mon.get_child_count() > 0, "the body stands (children %d)" % _mon.get_child_count())
		return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 4:
		print("S52_SHOT OK (%d checks)" % _checks)
	else:
		print("S52_SHOT FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
