extends SceneTree
## S50 - look at the five System 8 shields as Godot imported them: one row, lit, front-on.
## WINDOWED (needs a renderer). Writes renders/cycles/s50/s50_shields.png. Prints S50_SHOT OK|FAIL.
const NAMES := ["shield_celtic_golden", "shield_heater", "shield_heater_2", "shield_round", "shield_round_2"]
var _f := 0
func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.34, 0.38)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	root.add_child(sun)
	var x := -5.0
	for n in NAMES:
		var ps := load("res://assets/gear/shields/%s.fbx" % n) as PackedScene
		if ps == null:
			print("S50_SHOT FAIL load %s" % n)
			quit()
			return
		var s := ps.instantiate() as Node3D
		s.position = Vector3(x, 0, 0)
		root.add_child(s)
		x += 2.5
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.2, 9.0), Vector3(0, 1.0, 0))
	cam.current = true
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var img := get_root().get_texture().get_image()
		var ok := img != null and img.save_png("res://renders/cycles/s50/s50_shields.png") == OK
		print("S50_SHOT OK" if ok else "S50_SHOT FAIL")
		quit()
	return false
