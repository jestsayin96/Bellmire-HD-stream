extends SceneTree
var _cam: Camera3D
var _f := 0
var _out := ""
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 800))
	_out = ProjectSettings.globalize_path("res://renders/cycles/d56")
	DirAccess.make_dir_recursive_absolute(_out)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.55, 0.70)
	env.ambient_light_color = Color(0.62, 0.64, 0.62); env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-50, -36, 0); dl.light_energy = 1.4
	root.add_child(dl)
	var grass := load("res://assets/kit/materials/MI_Grass.tres")
	var dirt := load("res://assets/kit/materials/MI_Dirt.tres")
	for item in [[grass, -11.0], [dirt, 11.0]]:
		var pm := PlaneMesh.new(); pm.size = Vector2(20, 20)
		var mi := MeshInstance3D.new(); mi.mesh = pm
		mi.material_override = item[0]; mi.position = Vector3(item[1], 0, 0)
		root.add_child(mi)
	_cam = Camera3D.new(); _cam.fov = 48; _cam.far = 400
	_cam.position = Vector3(0, 19, 17)
	_cam.rotation_degrees = Vector3(-46.6, 0, 0)
	root.add_child(_cam)
func _process(_d: float) -> bool:
	_f += 1
	if _cam and _cam != root.get_viewport().get_camera_3d(): _cam.make_current()
	if _f == 55:
		root.get_texture().get_image().save_png(_out + "/swatch.png")
		print("SAVED swatch"); return true
	return false
