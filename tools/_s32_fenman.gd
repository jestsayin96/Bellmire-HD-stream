extends SceneTree
## S32_FENMAN - the 30th miniboss, wired. Windowed (needs a framebuffer), quits itself:
## <console> --path . --resolution 1920x1080 --script tools/_s32_fenman.gd
## Checks: Delve.miniboss_model("fenman") answers a real loadable body; Delve.miniboss_ratio answers
## art's measured 1.03; the body stood beside the posed KayKit knight and fitted to MB_HERO_H*ratio
## the way Monster fits a def "h" measures that height in the engine; the fogbound draw holds ONLY
## the Bellman while the Fenman has no arrive lines, and takes the Fenman on some floors the moment
## lines exist (proved with an in-memory line, the data file is not touched). Shots: front and side
## to renders/cycles/s32/. Prints S32_FENMAN OK|FAIL. S32_KEY overrides the key (red proof only).
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
const OUT := "res://renders/cycles/s32/"

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
	var key := OS.get_environment("S32_KEY")
	if key == "":
		key = "fenman"
	var p := Delve.miniboss_model(key)
	_ok(p != "", "%s has a loadable body (%s)" % [key, p])
	if p == "":
		return
	var r := Delve.miniboss_ratio(key, p)
	_ok(absf(r - 1.03) < 0.0001, "ratio %.2f == art's 1.03" % r)
	# the draw: fogbound with no Fenman lines is the Bellman on every floor
	var lines: Array = Delve.miniboss_lines("fenman", "arrive")
	var seen := {}
	for n in range(1, 61):
		seen[DungeonHD.miniboss_for("fogbound", n)] = true
	if lines.is_empty():
		_ok(seen.keys() == ["bellman"], "no Fenman lines yet -> fogbound draws only %s" % [seen.keys()])
	# with a line in memory the Fenman enters the draw
	var lore: Dictionary = Delve.lore()
	var bk: Dictionary = (lore.get("miniboss_feed", {}) as Dictionary).get("by_key", {})
	var had := bk.has("fenman")
	var saved = bk.get("fenman")
	bk["fenman"] = {"arrive": ["The Fenman comes up the boards."]}
	seen = {}
	for n in range(1, 61):
		seen[DungeonHD.miniboss_for("fogbound", n)] = true
	_ok(seen.has("fenman") and seen.has("bellman"), "with lines fogbound draws both %s" % [seen.keys()])
	if had: bk["fenman"] = saved
	else: bk.erase("fenman")
	_ok(DungeonHD.miniboss_for("barracks", 7) == "drillmaster", "a one-candidate theme is unchanged (barracks -> drillmaster)")
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
	if _f == 20:
		var a := _aabb(get_meta("host"))
		var kn := _aabb(get_meta("knight"))
		print("S32_MEASURE fenman h=%.2f knight h=%.2f ratio_to_posed=%.2f min_y=%.3f" % [a.size.y, kn.size.y, a.size.y / Delve.MB_HERO_H, a.position.y])
		_ok(absf(a.size.y - float(get_meta("want_h"))) < 0.02, "fitted height %.2f == %.2f" % [a.size.y, float(get_meta("want_h"))])
		_ok(absf(a.position.y) < 0.02, "stands on the floor (min y %.3f)" % a.position.y)
		_ok(a.position.x > kn.end.x - 0.05 or a.end.x < kn.position.x + 0.05, "knight and fenman do not overlap in x (%.2f..%.2f vs %.2f..%.2f)" % [kn.position.x, kn.end.x, a.position.x, a.end.x])
	if _f >= 25 and _si < _shots.size():
		if _f % 6 == 1:
			var s: Array = _shots[_si]
			_cam.position = s[1]; _cam.look_at(s[2])
		elif _f % 6 == 5:
			var s: Array = _shots[_si]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s.png" % s[0]))
			print("S32_SHOT ", s[0])
			_si += 1
	if _si >= _shots.size():
		return _finish()
	if _f > 400:
		_fails.append("timeout"); return _finish()
	return false

func _finish() -> bool:
	if _fails.is_empty() and _checks >= 7:
		print("S32_FENMAN OK (%d checks)" % _checks)
	else:
		print("S32_FENMAN FAIL (%d checks) %s" % [_checks, _fails])
	quit()
	return true
