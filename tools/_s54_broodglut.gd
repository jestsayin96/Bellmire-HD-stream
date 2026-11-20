extends SceneTree
## S54_BROOD - the first pack-variant miniboss, Broodglut (bestiary.gd "broodglut"), stood up on a
## real built floor beside a knight and MEASURED: it loads (art's glb, native scale), it stands at
## art's h (6.60 m, normalised by Monster), it towers over the hero, and its ONE IDEA works through
## the real Delve arms - _call_tick calls puglins, and while any stands _ward() is 0.5; with them
## down it is 1.0 again. Shot to renders/cycles/s54/. Windowed, quits itself:
##   <console> --path . --resolution 1920x1080 --script tools/_s54_broodglut.gd
## Prints S54_BROOD OK n=<checks> | S54_BROOD FAIL <what> | S54_BROOD NO VERDICT.
## S54_RED=1 strips `ward` from the def before standing it up: must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _d: Delve
var _mon: Monster
var _hero: HeroBody
var _done := false
const OUT := "res://renders/cycles/s54/"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _vis_h(n: Node) -> float:
	var lo := INF
	var hi := -INF
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var a: AABB = m.global_transform * m.get_aabb()
		lo = minf(lo, a.position.y)
		hi = maxf(hi, a.end.y)
	return hi - lo if hi > lo else 0.0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var r := Roster.new(); root.add_child(r)
	_dh = DungeonHD.new(); root.add_child(_dh)
	_dh.floor_no = 6
	_dh.build(6)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.light_energy = 1.4
	root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.22, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	root.add_child(env)
	var fake := GDScript.new(); fake.source_code = "extends Node3D\nvar feed := []\n"; fake.reload()
	var town := Node3D.new(); town.set_script(fake); root.add_child(town)
	_d = Delve.new(); _d.roster = r; _d.floor_no = 6; _d.town = town; root.add_child(_d); _d.dun = _dh
	var h: Dictionary = r.fresh("s54_k", "Measure", "knight")
	_hero = HeroBody.new(); _hero.setup(r, "s54_k"); _hero.town = _d; _hero.stay = true; _d.add_child(_hero)
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _stand() -> void:
	var def: Dictionary = Bestiary.make("broodglut")
	_ok(String(def.get("name", "")) == "Broodglut", "def name Broodglut (%s)" % def.get("name", ""))
	_ok(ResourceLoader.exists(String(def["path"])) and load(String(def["path"])) is PackedScene, "art's glb loads as PackedScene")
	_ok(is_equal_approx(float(def["h"]), 6.60), "h is art's register height 6.60 (%.2f)" % float(def["h"]))
	if OS.get_environment("S54_RED") == "1":
		(def["ways"] as Dictionary).erase("ward")
		print("  S54_RED: ward stripped")
	var pos := Vector3.ZERO
	var spawns: Array = _dh.info.get("spawns", [])
	if not spawns.is_empty() and spawns[0] is Vector3:
		pos = spawns[0]
	_mon = _d._spawn_on_floor(def, pos)
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_hero.global_position = _mon.global_position + Vector3(2.6, 0.0, 1.2)
	set_meta("cam", [_mon.global_position + Vector3(9.0, 6.0, 9.0), _mon.global_position + Vector3(0, 2.6, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S54_SHOT ", n)

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 2:
		_stand()
	if _mon == null:
		return _f > 300 and _finish()
	if has_meta("cam") and _cam.is_inside_tree():
		var c: Array = get_meta("cam")
		_cam.global_position = c[0]
		_cam.look_at(c[1])
		_mon.state = Monster.S.IDLE
	if _f == 40:
		var mh := _vis_h(_mon)
		var hh := _vis_h(_hero)
		print("  measured: broodglut %.2f m, knight %.2f m, ratio %.2f" % [mh, hh, mh / maxf(hh, 0.01)])
		_ok(absf(mh - 6.60) < 0.66, "stands within 10%% of 6.60 m (%.2f)" % mh)
		_ok(hh > 0.5 and mh / hh >= 2.0, "towers over the knight, >= 2x (%.2f)" % (mh / maxf(hh, 0.01)))
		_ok(is_equal_approx(_d._ward(_mon), 1.0), "no pack yet: ward 1.0 (%.2f)" % _d._ward(_mon))
		var spec: Dictionary = (_mon.def["ways"] as Dictionary)["summon"]
		_mon.set_meta("raise_t", 0.0)
		_d._call_tick(_mon, spec, 0.1)
		var live: Array = _d._live_called(_mon)
		_ok(live.size() >= 1, "it calls the pack: %d puglin(s)" % live.size())
		_ok(live.size() >= 1 and String((live[0] as Monster).def.get("type", "")) == "puglin", "the called are puglins")
		_ok(is_equal_approx(_d._ward(_mon), 0.5), "pack standing: ward 0.5 (%.2f)" % _d._ward(_mon))
	if _f == 70:
		_shot("s54_broodglut_pack")
		for m in _d._live_called(_mon):
			(m as Monster).state = Monster.S.DEAD
			(m as Monster).queue_free()
	if _f == 80:
		_ok(is_equal_approx(_d._ward(_mon), 1.0), "pack down: ward 1.0 again (%.2f)" % _d._ward(_mon))
		_shot("s54_broodglut")
		return _finish()
	return false

func _finish() -> bool:
	if _done:
		return true
	_done = true
	if _checks < 8:
		print("S54_BROOD NO VERDICT checks=%d %s" % [_checks, str(_fails)])
	elif _fails.is_empty():
		print("S54_BROOD OK n=%d" % _checks)
	else:
		print("S54_BROOD FAIL %s" % str(_fails))
	quit()
	return true
