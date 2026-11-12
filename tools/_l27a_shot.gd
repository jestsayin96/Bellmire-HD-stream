extends SceneTree
## L27a: the nine new creatures lined up and photographed (windowed), with a 1.8 m
## skeleton warrior for scale. Saves renders/cycles/20261112_l27/a_lineup_1080.png
## and a close pair per creature. Run: --script tools/_l27a_shot.gd --resolution 1920x1080
const NEW := ["hewer", "cutthroat", "silkmother", "spiderling", "scarrat", "lurker", "pitwyrm", "ashwight", "gloombat"]
const OUT := "res://renders/cycles/20261112_l27"
var _cam: Camera3D
var _stage: Node3D
var _f := 0
var _i := 0
var _shots: Array = []

func _initialize() -> void:
	_stage = Node3D.new()
	root.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.20, 0.22, 0.32)
	sm.sky_horizon_color = Color(0.45, 0.40, 0.50)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.2
	we.environment = e
	_stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	_stage.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 60)
	floor.mesh = pm
	var fm: StandardMaterial3D = load("res://assets/kit/materials/MI_Cobble.tres")
	floor.material_override = fm
	_stage.add_child(floor)
	_cam = Camera3D.new()
	_stage.add_child(_cam)
	_cam.make_current()
	for i in NEW.size():
		var x := float(i) * 4.2 - float(NEW.size() - 1) * 2.1
		_spawn(Bestiary.make(NEW[i], "plain"), Vector3(x, 0, 0))
	var ref := Bestiary.make("warrior", "plain")
	ref["name"] = "(1.8 m)"
	_spawn(ref, Vector3(float(NEW.size()) * 2.1 + 3.0, 0, 0))
	_shots = [["a_lineup", Vector3(0, 3.6, -16.0), Vector3(0, 1.2, 0)],
			  ["a_left", Vector3(-12.0, 2.6, -8.0), Vector3(-12.0, 1.0, 0)],
			  ["a_right", Vector3(12.0, 2.6, -8.0), Vector3(12.0, 1.2, 0)]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _spawn(d: Dictionary, p: Vector3) -> void:
	var m := Monster.new()
	m.def = d
	m.state = Monster.S.IDLE
	m.position = p
	m.rotation.y = PI
	_stage.add_child(m)
	print("L27A_SPAWN ", d.get("name"))

func _process(_dt: float) -> bool:
	_f += 1
	if _f < 50:
		return false
	if (_f - 50) % 12 == 0:
		if _i > 0:
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s_1080.png" % [OUT, _shots[_i - 1][0]]))
			print("L27A_SHOT ", _shots[_i - 1][0])
		if _i >= _shots.size():
			print("L27A_SHOTS DONE")
			return true
		var s: Array = _shots[_i]
		_cam.fov = 55.0
		_cam.global_position = s[1]
		_cam.look_at(s[2], Vector3.UP)
		_i += 1
	return false
