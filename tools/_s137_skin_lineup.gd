extends SceneTree
## S137: the UACP skin override (Townsfolk.UACP_SKIN, ON since S137) on a PICTURE, with its control beside it.
##   back row  (z -2.5): KayKit Rogue/Knight/Mage + UACP bodies at pack-native skin  = the CONTROL (override OFF)
##   front row (z  0.0): the same bodies with Townsfolk.uacp_skin(UACP_SKIN)          = override ON
## Two shots: renders/cycles/s137/lineup_close.png (13 m) and lineup_rts.png (the town camera's ~24 m pitch).
## Run WITH a window. Prints S137_LINEUP OK/FAIL.
const UACP := "res://assets/characters/uacp/"
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
var _f := 0
var _cam: Camera3D
var _skinned := 0
var _bad := []

func _put(path: String, x: float, z: float, k: float, skin: bool) -> void:
	var ps = load(path)
	if ps == null:
		_bad.append(path)
		return
	var n: Node3D = (ps as PackedScene).instantiate()
	n.scale = Vector3.ONE * k
	n.position = Vector3(x, 0, z)
	root.add_child(n)
	if skin:
		var c := Townsfolk.uacp_skin(n, Townsfolk.UACP_SKIN)
		if c == 0:
			_bad.append(path + ":no Skin surface")
		_skinned += c

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
	pm.size = Vector2(60, 60)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.5, 0.33)
	fl.material_override = fm
	root.add_child(fl)
	for row in [[-2.5, false], [0.0, true]]:
		var xs := -6.4
		for nm in ["Rogue", "Knight", "Mage"]:
			_put(ADV + nm + ".glb", xs, row[0], 1.0, false)
			xs += 1.6
		for nm in ["Worker_Male", "Worker_Female", "Chef_Female", "OldClassy_Male", "Viking_Male", "Viking_Female"]:
			_put(UACP + nm + ".glb", xs, row[0], Townsfolk.UACP_K, row[1])
			xs += 1.6
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_aim(Vector3(0.8, 2.4, 13.0), Vector3(0.8, 1.0, -1.2))

func _aim(cp: Vector3, at: Vector3) -> void:
	_cam.transform = Transform3D(Basis.looking_at(at - cp, Vector3.UP), cp)
	_cam.make_current()

func _shot(nm: String) -> void:
	var out := ProjectSettings.globalize_path("res://renders/cycles/s137/" + nm)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	print("S137_LINEUP shot ", nm, " rc=", root.get_texture().get_image().save_png(out))

func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		_shot("lineup_close.png")
		_aim(Vector3(0.8, 17.0, 17.0), Vector3(0.8, 0.6, -1.2))
	if _f == 40:
		_shot("lineup_rts.png")
		if _bad.is_empty() and _skinned > 0 and Townsfolk.UACP_SKIN.a > 0.0:
			print("S137_LINEUP OK %d Skin surfaces overridden on 6 UACP bodies, control row pack-native, switch ON (%s)" % [_skinned, str(Townsfolk.UACP_SKIN)])
		else:
			print("S137_LINEUP FAIL skinned=%d bad=%s switch_a=%.0f" % [_skinned, str(_bad), Townsfolk.UACP_SKIN.a])
		return true
	return false
