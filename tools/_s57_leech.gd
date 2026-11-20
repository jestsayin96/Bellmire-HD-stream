extends SceneTree
## S57_LEECH - the third bestiary-carried miniboss, the Leech (bestiary.gd "leech", art's Gulworth body,
## h 2.32 from CANON / _fit_leech_register.json). ITS ONE IDEA, measured through the real Delve arms:
## while it stands untipped, a heal to a delver (_bless "heal") lands in its basin and NOT on the delver;
## _lord_tick drinks the basin back into the Leech; at `tip` (0.30) of its hp the basin goes over and
## healing lands on the delver again. Windowed, quits itself:
##   <console> --path . --resolution 1920x1080 --script tools/_s57_leech.gd
## Prints S57_LEECH OK n=<checks> | S57_LEECH FAIL <what> | S57_LEECH NO VERDICT.
## S57_RED=1 strips `basin` from the def: must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _dh: DungeonHD
var _d: Delve
var _mon: Monster
var _hero: HeroBody
var _done := false
const OUT := "res://renders/cycles/s57/"

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
	var h: Dictionary = r.fresh("s57_k", "Measure", "knight")
	_hero = HeroBody.new(); _hero.setup(r, "s57_k"); _hero.town = _d; _hero.stay = true; _d.add_child(_hero)
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _lid_underside() -> float:
	for mi in _dh.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh is BoxMesh and is_equal_approx((m.mesh as BoxMesh).size.y, 1.0) \
				and m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			return m.global_position.y - 0.5
	return -1.0

func _stand() -> void:
	var def: Dictionary = Bestiary.make("leech")
	_ok(String(def.get("name", "")) == "The Leech", "def name The Leech (%s)" % def.get("name", ""))
	_ok(ResourceLoader.exists(String(def["path"])) and load(String(def["path"])) is PackedScene, "art's glb loads as PackedScene")
	_ok(is_equal_approx(float(def["h"]), 2.32), "h is art's CANON height 2.32 (%.2f)" % float(def["h"]))
	if OS.get_environment("S57_RED") == "1":
		(def["ways"] as Dictionary).erase("basin")
		print("  S57_RED: basin stripped")
	var pos := Vector3.ZERO
	var spawns: Array = _dh.info.get("spawns", [])
	if not spawns.is_empty() and spawns[0] is Vector3:
		pos = spawns[0]
	_mon = _d._spawn_on_floor(def, pos)
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_hero.global_position = _mon.global_position + Vector3(2.2, 0.0, 1.0)
	set_meta("cam", [_mon.global_position + Vector3(5.0, 3.4, 5.0), _mon.global_position + Vector3(0, 1.2, 0)])

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S57_SHOT ", n)

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
		print("  measured: leech %.2f m, knight %.2f m, ratio %.2f" % [mh, hh, mh / maxf(hh, 0.01)])
		_ok(absf(mh - 2.32) < 0.24, "stands within 10%% of 2.32 m (%.2f)" % mh)
		# The knight's visible height is NOT a stable instrument at frame 40 (1.98 m in one run, 2.54 m
		# in the next - its pose is still settling), so the ratio is printed, not gated. Art's ratio
		# 0.95 is against its posed hero_h 2.45; the leech's own 2.32 is gated above.
		print("  ratio vs art's hero_h 2.45: %.2f (art 0.95)" % (mh / 2.45))
		_ok(_d._leech_basin() == _mon or OS.get_environment("S57_RED") == "1", "the floor finds it as the standing basin")
	if _f == 60:
		_shot("s57_leech_standing")
		var ways: Dictionary = _mon.def.get("ways", {})
		var o := {"hp": 10.0, "max": 40.0}
		_d._bless(o, "heal", 12.0)
		_ok(is_equal_approx(float(o["hp"]), 10.0), "heal while it stands: delver gets nothing (hp %.1f)" % float(o["hp"]))
		_ok(is_equal_approx(float(_mon.get_meta("basin", 0.0)), 12.0), "the 12 went into the basin (%.1f)" % float(_mon.get_meta("basin", 0.0)))
		_mon.hp = _mon.max_hp * 0.60
		var hp0 := _mon.hp
		_d._lord_tick(_mon, ways, [], {}, 1.0)
		_ok(is_equal_approx(_mon.hp - hp0, 4.0), "it drinks 4 hp/s from the basin (+%.2f)" % (_mon.hp - hp0))
		_ok(is_equal_approx(float(_mon.get_meta("basin", 0.0)), 8.0), "basin down to 8 (%.1f)" % float(_mon.get_meta("basin", 0.0)))
		_mon.hp = _mon.max_hp * 0.25
		_d._lord_tick(_mon, ways, [], {}, 1.0)
		_ok(bool(_mon.get_meta("basin_tipped", false)), "at 0.25 hp (tip 0.30) the basin goes over")
		_ok(is_equal_approx(float(_mon.get_meta("basin", -1.0)), 0.0), "tipped basin holds nothing")
		_ok(is_equal_approx(_mon.hp, _mon.max_hp * 0.25), "tipped: it drinks nothing more")
		_d._bless(o, "heal", 12.0)
		_ok(is_equal_approx(float(o["hp"]), 22.0), "tipped: the heal lands on the delver again (hp %.1f)" % float(o["hp"]))
		var o2 := {"hp": 39.0, "max": 40.0}
		_ok(is_equal_approx(_d._mend(o2, 5.0), 1.0) and is_equal_approx(float(o2["hp"]), 40.0), "_mend caps at max and returns what landed")
	if _f == 70:
		return _finish()
	return false

func _finish() -> bool:
	if _done:
		return true
	_done = true
	if _checks < 10:
		print("S57_LEECH NO VERDICT checks=%d %s" % [_checks, str(_fails)])
	elif _fails.is_empty():
		print("S57_LEECH OK n=%d" % _checks)
	else:
		print("S57_LEECH FAIL %s" % str(_fails))
	quit()
	return true
