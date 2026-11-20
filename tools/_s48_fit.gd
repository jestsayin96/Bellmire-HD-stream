extends SceneTree
## S48_FIT - a newly wired miniboss body (default the Fuller, 35th) stood beside the posed KayKit
## knight at MB_HERO_H * Delve.MB_FIT[key], the way Monster fits a def "h". Windowed, quits itself:
## <console> --path . --resolution 1920x1080 --script tools/_s48_fit.gd     (S48_KEY=stackman for the 36th)
## Checks: loadable body; MB_FIT equals art's _fit_report.json pairs.<key>.ratio (0.005); fitted
## height; stands on the floor; no x overlap with the knight. The draw itself is S33_DRAW's job.
## Shots: front, three-quarter, true side to renders/cycles/s48/. Prints S48_FIT OK|FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _shots := [["1front", Vector3(1.2, 1.6, 7.5), Vector3(1.2, 1.2, 0)], ["2threequarter", Vector3(7.5, 1.6, 5.5), Vector3(1.2, 1.2, 0)],
	## 18 Nov: fenman_2side is a 48.9-degree three-quarter (camera horizontal (6.3, 5.5) off the
	## front axis), not a side - which is why its feet span matched the front. This is the TRUE 90:
	## on the +X axis through the Fenman itself, so the azimuth is exactly 90 from fenman_1front.
	["3side90", Vector3(9.9, 1.6, 0.0), Vector3(2.4, 1.2, 0.0)]]
var _si := 0
const OUT := "res://renders/cycles/s48/"
var _key := ""

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
	var key := OS.get_environment("S48_KEY")
	if key == "":
		key = "fuller"
	_key = key
	var p := Delve.miniboss_model(key)
	_ok(p != "", "%s has a loadable body (%s)" % [key, p])
	if p == "":
		return
	var r := Delve.miniboss_ratio(key, p)
	var fr: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://renders/art/minibosses/_fit_report.json"))
	var want := -1.0
	if fr is Dictionary and ((fr as Dictionary).get("pairs", {}) as Dictionary).has(key):
		want = float(((fr as Dictionary)["pairs"] as Dictionary)[key].get("ratio", -1.0))
	_ok(want > 0.0 and absf(r - want) <= 0.005, "MB_FIT %.2f == art's %.2f" % [r, want])
	# stage: knight + fenman on a ground plane
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
			# a wide body (the Fuller's trough is ~3.3 m) is stood clear of the knight, 0.3 m gap, so the
			# pair reads side by side - staging only, the engine never places them like this
			var kn0 := _aabb(get_meta("knight"))
			if a.position.x < kn0.end.x + 0.3:
				host.position.x += kn0.end.x + 0.3 - a.position.x
	if _f == 20:
		var a := _aabb(get_meta("host"))
		var kn := _aabb(get_meta("knight"))
		print("S48_MEASURE " + _key + " h=%.2f knight h=%.2f ratio_to_posed=%.2f min_y=%.3f" % [a.size.y, kn.size.y, a.size.y / Delve.MB_HERO_H, a.position.y])
		_ok(absf(a.size.y - float(get_meta("want_h"))) < 0.02, "fitted height %.2f == %.2f" % [a.size.y, float(get_meta("want_h"))])
		_ok(absf(a.position.y) < 0.02, "stands on the floor (min y %.3f)" % a.position.y)
		_ok(a.position.x > kn.end.x - 0.05 or a.end.x < kn.position.x + 0.05, "knight and body do not overlap in x (%.2f..%.2f vs %.2f..%.2f)" % [kn.position.x, kn.end.x, a.position.x, a.end.x])
	if _f >= 25 and _si < _shots.size():
		if _f % 6 == 1:
			var s: Array = _shots[_si]
			_cam.position = s[1]; _cam.look_at(s[2])
		elif _f % 6 == 5:
			var s: Array = _shots[_si]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s_%s.png" % [_key, s[0]]))
			print("S48_SHOT ", _key, " ", s[0])
			_si += 1
	if _si >= _shots.size():
		return _finish()
	if _f > 400:
		_fails.append("timeout"); return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 5:
		print("S48_FIT OK %s (%d checks)" % [_key, _checks])
	else:
		print("S48_FIT FAIL %s (%d checks) %s" % [_key, _checks, _fails])
	quit()
	return true
