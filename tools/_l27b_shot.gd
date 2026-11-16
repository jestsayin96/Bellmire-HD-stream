extends SceneTree
## L27b: one skeleton warrior per strain lined up and photographed (windowed), so
## every tell - tint, glow, scale, particles, scarborn's wandering hue - is judged
## by eye. Saves renders/cycles/20261112_l27/b_*.png.
## Run: --script tools/_l27b_shot.gd --resolution 1920x1080
const OUT := "res://renders/cycles/20261112_l27"
var _cam: Camera3D
var _stage: Node3D
var _f := 0
var _i := 0
var _shots: Array = []
var _ids: Array = []

func _initialize() -> void:
	_stage = Node3D.new()
	root.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.12, 0.13, 0.20)
	sm.sky_horizon_color = Color(0.30, 0.27, 0.36)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.glow_enabled = true
	e.glow_intensity = 0.5
	we.environment = e
	_stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	_stage.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 60)
	floor.mesh = pm
	var fm: StandardMaterial3D = load("res://assets/kit/materials/MI_Cobble.tres")
	floor.material_override = fm
	_stage.add_child(floor)
	_cam = Camera3D.new()
	_stage.add_child(_cam)
	_cam.make_current()
	# plain first for reference, then every named strain in table order
	_ids = ["plain"]
	for id in Bestiary.STRAINS:
		if id != "plain":
			_ids.append(id)
	for i in _ids.size():
		var x := float(i) * 3.6 - float(_ids.size() - 1) * 1.8
		var d := Bestiary.make("warrior", String(_ids[i]))
		if String(_ids[i]) == "plain":
			d["name"] = "plain (1.8 m)"
		_spawn(d, Vector3(x, 0, 0))
	_shots = [["b_lineup", Vector3(0, 3.4, -17.0), Vector3(0, 1.3, 0)],
			  ["b_left", Vector3(-11.0, 2.2, -7.0), Vector3(-11.0, 1.1, 0)],
			  ["b_mid", Vector3(0.0, 2.2, -7.0), Vector3(0.0, 1.1, 0)],
			  ["b_right", Vector3(11.0, 2.2, -7.0), Vector3(11.0, 1.1, 0)],
			  # a beat later: scarborn's hue has wandered, the particles have spread
			  ["b_lineup_later", Vector3(0, 3.4, -17.0), Vector3(0, 1.3, 0)]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _spawn(d: Dictionary, p: Vector3) -> void:
	var m := Monster.new()
	m.def = d
	m.state = Monster.S.IDLE
	m.position = p
	m.rotation.y = PI
	_stage.add_child(m)
	print("L27B_SPAWN ", d.get("name"), " particle=", d.get("particle", "-"))

var _next := 60

func _process(_dt: float) -> bool:
	_f += 1
	if _f < _next:
		return false
	if _i > 0:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s_1080.png" % [OUT, _shots[_i - 1][0]]))
		print("L27B_SHOT ", _shots[_i - 1][0])
	if _i >= _shots.size():
		print("L27B_SHOTS DONE")
		return true
	var s: Array = _shots[_i]
	_cam.fov = 55.0
	_cam.global_position = s[1]
	_cam.look_at(s[2], Vector3.UP)
	_i += 1
	# the final frame dwells ~3 s so the wild hue and the motes have visibly moved
	_next = _f + (180 if _i == _shots.size() else 12)
	return false
