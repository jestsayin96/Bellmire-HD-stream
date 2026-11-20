extends SceneTree
## S56_LAST - the second pack-variant miniboss, Lastcuff (bestiary.gd "lastcuff"), and the raised lid
## (floorgen.gd, supervisor's 02:12 ruling: lid 7.0 -> 10.0). Measured: art's glb loads, stands at
## art's h 6.20, its ONE IDEA works through Delve._lord_tick - each hp mark sheds an iron, pace climbs
## 1.0 -> 2.10 via _mon_pace, Imp_Chains hides at the 4th and Imp_SpikedCollar at the 5th - and the
## floor's lid underside clears both tall bodies (6.60 broodglut, 6.20 lastcuff).
##   <console> --path . --resolution 1920x1080 --script tools/_s56_lastcuff.gd
## Prints S56_LAST OK n=<checks> | S56_LAST FAIL <what> | S56_LAST NO VERDICT.
## S56_RED=1 strips `irons` from the def: must FAIL.
## (header below kept from S54 for the shared scaffolding)
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
const OUT := "res://renders/cycles/s56/"

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
	var h: Dictionary = r.fresh("s56_k", "Measure", "knight")
	_hero = HeroBody.new(); _hero.setup(r, "s56_k"); _hero.town = _d; _hero.stay = true; _d.add_child(_hero)
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)

func _lid_underside() -> float:
	for mi in _dh.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh is BoxMesh and is_equal_approx((m.mesh as BoxMesh).size.y, 1.0) \
				and m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			return m.global_position.y - 0.5
	return -1.0

func _stand() -> void:
	var def: Dictionary = Bestiary.make("lastcuff")
	_ok(String(def.get("name", "")) == "Lastcuff", "def name Lastcuff (%s)" % def.get("name", ""))
	_ok(ResourceLoader.exists(String(def["path"])) and load(String(def["path"])) is PackedScene, "art's glb loads as PackedScene")
	_ok(is_equal_approx(float(def["h"]), 6.20), "h is art's register height 6.20 (%.2f)" % float(def["h"]))
	var lu := _lid_underside()
	print("  lid underside %.2f m" % lu)
	_ok(lu >= 9.0, "lid raised: underside >= 9.0 m (%.2f)" % lu)
	_ok(lu > 6.60 + 1.0, "lid clears broodglut 6.60 with >= 1 m (%.2f)" % (lu - 6.60))
	if OS.get_environment("S56_RED") == "1":
		(def["ways"] as Dictionary).erase("irons")
		print("  S56_RED: irons stripped")
	var pos := Vector3.ZERO
	var spawns: Array = _dh.info.get("spawns", [])
	if not spawns.is_empty() and spawns[0] is Vector3:
		pos = spawns[0]
	_mon = _d._spawn_on_floor(def, pos)
	_mon.state = Monster.S.IDLE
	_mon.roam = 0.0
	_hero.global_position = _mon.global_position + Vector3(2.6, 0.0, 1.2)
	set_meta("cam", [_mon.global_position + Vector3(9.0, 6.0, 9.0), _mon.global_position + Vector3(0, float(def["h"]) * 0.5, 0)])

func _box(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var a: AABB = m.global_transform * m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

func _in_frame(_mh: float) -> bool:
	# Every corner of the body's world AABB must project inside the viewport. The pivot column is
	# not enough: the body leans forward, so its head is not above its feet (S55 found that the
	# column check passed the old 2.6 aim that cut the head off).
	var rect := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	var box := _box(_mon)
	if box.size == Vector3.ZERO:
		return false
	if OS.get_environment("S56_RED_AIM") == "1":  # red arm: the old literal 2.6 aim that cut the head off
		_cam.global_position = _mon.global_position + Vector3(9.0, 6.0, 9.0)
		_cam.look_at(_mon.global_position + Vector3(0, 2.6, 0))
	for k in 8:
		var w: Vector3 = box.get_endpoint(k)
		if _cam.is_position_behind(w) or not rect.has_point(_cam.unproject_position(w)):
			print("  off frame: corner %d %s -> %s" % [k, str(w), str(_cam.unproject_position(w))])
			return false
	print("  in frame: all 8 AABB corners on screen, top y %.2f" % box.end.y)
	return true

func _shot(n: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + n + ".png"))
	print("S56_SHOT ", n)

func _vis(name: String) -> bool:
	var n := _mon.find_child(name, true, false)
	return n is Node3D and (n as Node3D).is_visible_in_tree()

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
		print("  measured: lastcuff %.2f m, knight %.2f m, ratio %.2f" % [mh, hh, mh / maxf(hh, 0.01)])
		var bc: Vector3 = _box(_mon).get_center()
		var k := maxf(1.0, mh / 4.4)
		set_meta("cam", [_mon.global_position + Vector3(9.0, 6.0, 9.0) * k, Vector3(bc.x, _mon.global_position.y + mh * 0.5, bc.z)])
		_ok(absf(mh - 6.20) < 0.62, "stands within 10%% of 6.20 m (%.2f)" % mh)
		_ok(hh > 0.5 and mh / hh >= 2.0, "towers over the knight, >= 2x (%.2f)" % (mh / maxf(hh, 0.01)))
		_ok(_lid_underside() > _box(_mon).end.y + 1.0, "lid underside above its head by >= 1 m (%.2f vs %.2f)" % [_lid_underside(), _box(_mon).end.y])
		_ok(_vis("Imp_Chains") and _vis("Imp_SpikedCollar"), "in irons: Imp_Chains and Imp_SpikedCollar shown")
		_ok(is_equal_approx(_d._mon_pace(_mon), 1.0), "full hp: pace 1.0 (%.2f)" % _d._mon_pace(_mon))
	if _f == 70:
		_ok(_in_frame(_vis_h(_mon)), "whole body in frame, head and feet both on screen")
		_shot("s56_lastcuff_irons")
		var ways: Dictionary = _mon.def.get("ways", {})
		_mon.hp = _mon.max_hp * 0.80
		_d._lord_tick(_mon, ways, [], {}, 0.1)
		_ok(is_equal_approx(_d._mon_pace(_mon), 1.22), "first iron off at 0.80 hp: pace 1.22 (%.2f)" % _d._mon_pace(_mon))
		_mon.hp = _mon.max_hp * 0.20
		for i in 3:
			_d._lord_tick(_mon, ways, [], {}, 0.1)
		_ok(not _vis("Imp_Chains") and _vis("Imp_SpikedCollar"), "fourth iron: cuffs hidden, collar still on")
		_d._lord_tick(_mon, ways, [], {}, 0.1)
		_d._lord_tick(_mon, ways, [], {}, 0.1)   # a sixth tick sheds nothing more
		_ok(not _vis("Imp_SpikedCollar"), "fifth iron: collar hidden")
		_ok(is_equal_approx(_d._mon_pace(_mon), 2.10), "all five off: pace 2.10 (%.2f)" % _d._mon_pace(_mon))
		_ok(int(_mon.get_meta("irons_n", 0)) == 5, "exactly five shed (%d)" % int(_mon.get_meta("irons_n", 0)))
	if _f == 80:
		_shot("s56_lastcuff_free")
		return _finish()
	return false

func _finish() -> bool:
	if _done:
		return true
	_done = true
	if _checks < 12:
		print("S56_LAST NO VERDICT checks=%d %s" % [_checks, str(_fails)])
	elif _fails.is_empty():
		print("S56_LAST OK n=%d" % _checks)
	else:
		print("S56_LAST FAIL %s" % str(_fails))
	quit()
	return true
