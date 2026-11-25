extends SceneTree
## S134: look at the UACP scale before wiring it. Two rows on a plain floor, KayKit ADV bodies
## (what townsfolk.gd draws today) beside UACP bodies:
##   front row: UACP at k_head 0.5728 (head bone matched to KayKit's, hat-free)
##   back row:  UACP at S133's 0.7249 constant (AABB-mean, counts hats)
## Run WITH a window (not --headless). Saves renders/cycles/s134/lineup.png and quits.
const UACP := "res://assets/characters/uacp/"
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
var _f := 0

func _put(path: String, x: float, z: float, k: float) -> void:
	var ps = load(path)
	if ps == null:
		print("S134_SHOT missing ", path)
		return
	var n: Node3D = (ps as PackedScene).instantiate()
	n.scale = Vector3.ONE * k
	n.position = Vector3(x, 0, z)
	root.add_child(n)

func _initialize() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	fl.mesh = pm
	root.add_child(fl)
	# a 1 m tick pole at each end, so height reads off the picture
	for px in [-7.0, 7.0]:
		var pole := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 2.0, 0.08)
		pole.mesh = bm
		pole.position = Vector3(px, 1.0, 0)
		root.add_child(pole)
	var xs := -5.5
	for nm in ["Rogue", "Knight", "Mage"]:
		_put(ADV + nm + ".glb", xs, 0.0, 1.0)
		xs += 1.6
	for nm in ["Worker_Male", "Chef_Female", "OldClassy_Male", "Viking_Male", "Witch"]:
		_put(UACP + nm + ".glb", xs, 0.0, 0.5728)
		_put(UACP + nm + ".glb", xs, -3.0, 0.7249)
		xs += 1.6
	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	var cp := Vector3(0, 2.2, 13.0)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 1.1, -1.0) - cp, Vector3.UP), cp)
	cam.make_current()

func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var img := root.get_texture().get_image()
		var out := ProjectSettings.globalize_path("res://renders/cycles/s134/lineup.png")
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		print("S134_SHOT saved rc=", img.save_png(out), " ", out)
		return true
	return false
