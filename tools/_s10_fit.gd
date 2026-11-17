extends SceneTree
## S10_FIT - SYSTEM 10's game-build half. The twelve shared-mesh creatures spawn in their OWN
## bodies (assets/monsters/creatures/), at art's height (scale factor 1.000 in the register),
## with no clip names, no KayKit props, and a procedural step / lunge / fall so none slides as a
## statue. Lines them up beside a posed knight and saves renders/cycles/s10/lineup.png.
## Run WINDOWED, no --quit; it quits itself:
## <console> --path . --resolution 1920x1080 --script tools/_s10_fit.gd
const KEYS := ["sentinel", "hewer", "bowman", "cutthroat", "gravecaller", "silkmother",
	"spiderling", "scarrat", "lurker", "pitwyrm", "gloombat", "slimeling"]
var _fails: Array = []
var _checks := 0
var _mons: Array = []
var _f := 0
var _cam: Camera3D

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.34, 0.38)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	root.add_child(env)
	var x := 0.0
	for k in KEYS:
		var d := Bestiary.make(k)
		_ok(String(d["path"]) == Bestiary.CREATURE_DIR + k + ".glb", "%s: own body path (%s)" % [k, String(d["path"]).get_file()])
		_ok((d["anims"] as Dictionary).is_empty() and String(d.get("hand", "")) == "" and String(d.get("off", "")) == "", "%s: no clip names, no props" % k)
		var m := Monster.new()
		m.def = d
		root.add_child(m)
		var w: float = maxf(1.2, float(d["h"]) * (1.6 if k in ["pitwyrm", "silkmother"] else 0.8))
		x += w * 0.5
		m.position = Vector3(x, 0, 0)
		x += w * 0.5 + 0.4
		_mons.append([k, m])
	var kn := Monster.new()
	kn.def = {"path": "res://addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb", "anims": {}, "h": 2.45}
	root.add_child(kn)
	kn.position = Vector3(-1.4, 0, 0)
	_cam.look_at_from_position(Vector3(x * 0.5 - 1.2, 3.6, 27.0), Vector3(x * 0.5 - 1.2, 1.3, 0))

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 3:
		for e in _mons:
			var k: String = e[0]
			var m: Monster = e[1]
			_ok(m._body != null and m._ap == null, "%s: static body loaded, unrigged" % k)
			if m._body:
				var hh := m._local_bounds(m._body).size.y * m._body.scale.y
				var want := float(m.def["h"])
				_ok(absf(hh - want) <= 0.03 and absf(m._body.scale.y - 1.0) <= 0.02, "%s: stands %.2fm vs bestiary h %.2f, scale %.3f" % [k, hh, want, m._body.scale.y])
			m.state = Monster.S.IDLE
	if _f == 20:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/s10/lineup.png"))
		var m: Monster = _mons[0][1]
		m._play("attack")
		_ok(m.lunges == 1, "sentinel: an unrigged swing lunges (lunges=%d)" % m.lunges)
		var b: Monster = _mons[2][1]
		b.state = Monster.S.PATROL
	if _f == 50:
		var b: Monster = _mons[2][1]
		_ok(absf(b._body.rotation.z) > 0.001 or b._body.position.y > 0.001, "bowman: walking body steps (rot.z %.3f, y %.3f)" % [b._body.rotation.z, b._body.position.y])
		if _checks < 50:  ## S11: measured 50; fewer means something stopped being checked
			_fails.append("check floor: %d checks is under 50" % _checks)
		if _fails.is_empty():
			print("S10_FIT OK %d checks, 12 creatures in their own bodies" % _checks)
		else:
			print("S10_FIT FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
		quit(0 if _fails.is_empty() else 1)
		return true
	return false
