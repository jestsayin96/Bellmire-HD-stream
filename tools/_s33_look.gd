extends SceneTree
## S33_LOOK - stand one wired miniboss beside the posed KayKit knight, fitted to MB_HERO_H*MB_FIT the
## way Monster fits a def "h", and shoot front / three-quarter / true-90 side to renders/cycles/s33/.
## Windowed, quits itself: <console> --path . --resolution 1920x1080 --script tools/_s33_look.gd
## S33_KEY picks the key (default comfitmaker). Derived from tools/_s32_fenman.gd's stage.
## Prints S33_LOOK OK|FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _shots := [["fenman_1front", Vector3(1.2, 1.6, 7.5), Vector3(1.2, 1.2, 0)], ["fenman_2side", Vector3(7.5, 1.6, 5.5), Vector3(1.2, 1.2, 0)],
	## 18 Nov: fenman_2side is a 48.9-degree three-quarter (camera horizontal (6.3, 5.5) off the
	## front axis), not a side - which is why its feet span matched the front. This is the TRUE 90:
	## on the +X axis through the Fenman itself, so the azimuth is exactly 90 from fenman_1front.
	["fenman_3side90", Vector3(9.9, 1.6, 0.0), Vector3(2.4, 1.2, 0.0)]]
var _si := 0
const OUT := "res://renders/cycles/s33/"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var a := mi.global_transform * mi.get_aabb()
		out = a if first else out.merge(a)
		first = false
	return out

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var key := OS.get_environment("S33_KEY")
	if key == "":
		key = "comfitmaker"
	var p := Delve.miniboss_model(key)
	_ok(p != "", "%s has a loadable body (%s)" % [key, p])
	if p == "":
		return
	var r := Delve.miniboss_ratio(key, p)
	_ok(absf(r - float(Delve.MB_FIT.get(key, -1.0))) < 0.0001, "ratio %.2f == MB_FIT (art's measured)" % r)
	set_meta("key", key)
	# stage: knight + the body on a ground plane
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(30, 30); g.mesh = pm
	root.add_child(g)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 35, 0); sun.light_energy = 1.3
	root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.32, 0.36, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	root.add_child(env)
	var k: Node3D = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES["knight"]["model"])) as PackedScene).instantiate()
	root.add_child(k)
	Gear.strip_props(k)
	var ap := Rig.find(k)
	if ap:
		Rig.prep(ap); Rig.play(ap, "Idle")
	var host := Node3D.new(); host.position = Vector3(2.4, 0, 0); root.add_child(host)
	var body: Node3D = (load(p) as PackedScene).instantiate()
	host.add_child(body)
	set_meta("host", host); set_meta("knight", k); set_meta("want_h", Delve.MB_HERO_H * r)
	_cam = Camera3D.new(); _cam.fov = 40.0; root.add_child(_cam)

func _process(_d: float) -> bool:
	_f += 1
	if not has_meta("host"):
		return _finish()
	if _f == 5:
		# fit the static body to MB_HERO_H*ratio and stand it on the floor, as a def "h" does
		var host: Node3D = get_meta("host")
		var a := _aabb(host)
		if a.size.y > 0.001:
			var s: float = float(get_meta("want_h")) / a.size.y
			host.scale = Vector3.ONE * s
			a = _aabb(host)
			host.position.y -= a.position.y
	if _f == 20:
		var a := _aabb(get_meta("host"))
		var kn := _aabb(get_meta("knight"))
		print("S33_MEASURE h=%.2f knight h=%.2f ratio_to_posed=%.2f min_y=%.3f" % [a.size.y, kn.size.y, a.size.y / Delve.MB_HERO_H, a.position.y])
		_ok(absf(a.size.y - float(get_meta("want_h"))) < 0.02, "fitted height %.2f == %.2f" % [a.size.y, float(get_meta("want_h"))])
		_ok(absf(a.position.y) < 0.02, "stands on the floor (min y %.3f)" % a.position.y)
		_ok(a.position.x > kn.end.x - 0.05 or a.end.x < kn.position.x + 0.05, "knight and body do not overlap in x (%.2f..%.2f vs %.2f..%.2f)" % [kn.position.x, kn.end.x, a.position.x, a.end.x])
	if _f >= 25 and _si < _shots.size():
		if _f % 6 == 1:
			var s: Array = _shots[_si]
			_cam.position = s[1]; _cam.look_at(s[2])
		elif _f % 6 == 5:
			var s: Array = _shots[_si]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s_%s.png" % [String(get_meta("key")), String(s[0]).trim_prefix("fenman_")]))
			print("S33_SHOT ", s[0])
			_si += 1
	if _si >= _shots.size():
		return _finish()
	if _f > 400:
		_fails.append("timeout"); return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 5:
		print("S33_LOOK OK (%d checks)" % _checks)
	else:
		print("S33_LOOK FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
