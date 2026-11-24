extends SceneTree
## S58_SPAN - the span term (second half of the supervisor's 01:16 corridor ruling). bestiary.gd carries
## art's T-pose span_x for broodglut (10.4063) and lastcuff (6.4807); Bestiary.make refuses any strain
## upscale that would draw the body wider than the corridor clear READ out of FloorGen (11.0 m).
## Windowed, quits itself:
##   <console> --path . --resolution 1920x1080 --script tools/_s58_span.gd
## Prints S58_SPAN OK n=<checks> | S58_SPAN FAIL <what> | S58_SPAN NO VERDICT | S58_SPAN WINDOWED-ONLY <why>.
## S58_RED=1 blinds the guard (corridor_clear_override = 100) and checks the drawn span against the
## REAL 11.0 m: a forced upscale past x1.057 must cross the corridor, so it must FAIL.
var _fails: Array = []
var _checks := 0
var _f := 0
var _cam: Camera3D
var _stage: Node3D
var _mons: Array = []
var _red := false
var _refused := false
const OUT := "res://renders/cycles/s58/"
const CLEAR := 11.0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _vis_w(n: Node) -> Vector2:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var a: AABB = m.global_transform * m.get_aabb()
		lo = lo.min(a.position)
		hi = hi.max(a.end)
	return Vector2(maxf(hi.x - lo.x, hi.z - lo.z), hi.y - lo.y) if hi.y > lo.y else Vector2.ZERO

## S104: this gate writes into res://renders/cycles/s58/, which is TRACKED. Run headless (or on the dummy
## renderer) there is no real frame, and the old gate went RED and overwrote the committed renders on the
## way down. Refuse up front with a verdict line and write NOTHING - not the directory, not a png.
func _windowless() -> String:
	if DisplayServer.get_name() == "headless":
		return "display server is headless"
	if RenderingServer.get_current_rendering_driver_name() in ["", "dummy"]:
		return "rendering driver is dummy"
	return ""

func _refuse(why: String) -> void:
	_refused = true
	print("S58_SPAN WINDOWED-ONLY %s - refused, nothing written (run: <console> --path . --resolution 1920x1080 --script tools/_s58_span.gd)" % why)
	quit()

func _initialize() -> void:
	var why := _windowless()
	if why != "":
		_refuse(why)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_red = OS.get_environment("S58_RED") == "1"
	var real := Bestiary.corridor_clear()
	_ok(is_equal_approx(real, CLEAR), "corridor clear read out of FloorGen G*HALL_W-2*WALL_IN = %.3f" % real)
	_ok(is_equal_approx(snappedf(real / 10.4063, 0.0001), 1.0571), "broodglut cap x%.4f (11.0/10.4063)" % (real / 10.4063))
	if _red:
		Bestiary.corridor_clear_override = 100.0
		print("  S58_RED: guard blinded, clear override 100")
	Bestiary.span_refused = 0
	# [type, strain, expect_refused]
	var cases := [["broodglut", "plain", false], ["broodglut", "drowned", false], ["broodglut", "mossbacked", true],
		["broodglut", "gorged", true], ["broodglut", "hollowed", false], ["lastcuff", "gorged", false],
		["warrior", "gorged", false], ["leech", "gorged", false], ["leech", "plain", false]]
	_stage = Node3D.new(); root.add_child(_stage)
	var x := -22.0
	for c in cases:
		var base: Dictionary = Bestiary.def_of(String(c[0]))
		var d: Dictionary = Bestiary.make(String(c[0]), String(c[1]))
		var k := float(d["h"]) / float(base["h"])
		var refused := d.has("upscale_refused")
		_ok(refused == bool(c[2]) or _red, "%s %s refused=%s (expected %s) h %.3f" % [c[0], c[1], refused, c[2], float(d["h"])])
		if base.has("span"):
			var drawn := float(base["span"]) * k
			_ok(drawn <= CLEAR, "%s %s drawn T-pose span %.3f <= real corridor %.1f" % [c[0], c[1], drawn, CLEAR])
		elif String(c[1]) == "gorged":
			_ok(is_equal_approx(k, 1.35), "%s (no span) still takes gorged x1.35 (x%.3f)" % [c[0], k])
		if String(c[0]) == "broodglut" and String(c[1]) in ["plain", "drowned", "mossbacked"]:
			var m := Monster.new(); m.def = d; m.state = Monster.S.IDLE
			m.position = Vector3(x, 0, 0); m.rotation.y = PI
			_stage.add_child(m); _mons.append([m, c[1], k]); x += 15.0
	# S60: the Leech now carries art's MEASURED span, so its gorged case above took the same span check as
	# the other two. Prove the key is art's number, copied: read the register live and compare.
	var lk: Dictionary = Bestiary.def_of("leech")
	_ok(lk.has("span"), "leech carries a span key")
	var reg = JSON.parse_string(FileAccess.get_file_as_string("res://renders/art/minibosses/_fit_leech_register.json"))
	var art_span := -1.0
	if reg is Dictionary and reg.get("pairs", {}).get("leech", {}).has("span_x"):
		art_span = float(reg["pairs"]["leech"]["span_x"])
	_ok(art_span > 0.0 and is_equal_approx(float(lk.get("span", -2.0)), art_span), "leech span %.4f == art's register span_x %.4f (copied, not re-derived)" % [float(lk.get("span", -2.0)), art_span])
	if not _red:
		_ok(Bestiary.span_refused == 2, "span_refused counted 2 (%d)" % Bestiary.span_refused)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 30, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.22, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	root.add_child(env)
	_cam = Camera3D.new(); _cam.fov = 50.0; root.add_child(_cam)
	_cam.look_at_from_position(Vector3(-7, 5, -34), Vector3(-7, 3.3, 0))

func _process(_d: float) -> bool:
	if _refused:
		return true
	_f += 1
	if _f == 40:
		var plain_w := 0.0
		for e in _mons:
			var wh := _vis_w(e[0])
			print("  MEASURED broodglut %s k=%.3f mesh h %.3f, mesh w %.3f" % [e[1], e[2], wh.y, wh.x])
			if e[1] == "plain":
				plain_w = wh.x
			_ok(wh.y > 0.0, "broodglut %s has visible mesh" % e[1])
		for e in _mons:
			if plain_w > 0.0 and e[1] != "plain":
				var wh := _vis_w(e[0])
				_ok(absf(wh.x / plain_w - float(e[2])) < 0.02, "broodglut %s mesh width ratio %.3f matches k %.3f" % [e[1], wh.x / plain_w, e[2]])
		var tex := root.get_texture()
		var img: Image = tex.get_image() if tex != null else null
		if img == null or img.is_empty():
			_refuse("viewport texture gave no image")
			return true
		img.save_png(ProjectSettings.globalize_path(OUT + ("s58_red.png" if _red else "s58_span.png")))
		if _checks == 0:
			print("S58_SPAN NO VERDICT")
		elif _fails.is_empty():
			print("S58_SPAN OK n=%d" % _checks)
		else:
			print("S58_SPAN FAIL %s" % "; ".join(_fails))
		quit()
	return false
