extends SceneTree
## S138 / System 13 (pet companions) step 1: can HeroPet carry the UAA Fox, Husky and Shiba Inu
## (Quaternius Ultimate Animated Animals, CC0, already in assets/animals/uaa since S108) at heel?
## Each pet stands beside a KayKit Knight. CONTROL = the shipped pets: pet_corgi (Corgi.glb 0.0017)
## and pet_fox (GobKit Red.glb 0.002). Measures the clips HeroPet picked and each pet's world height.
## Shot renders/cycles/s138/pets.png. Run WITH a window. Prints S138_PETS OK/FAIL.
const ADV := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
const PETS := [
	["corgi(ctl)", "res://assets/animals/Corgi.glb", 0.0017],
	["fox_red(ctl)", "res://assets/animals/Red.glb", 0.002],
	["fox_uaa", "res://assets/animals/uaa/Fox.gltf", 0.15],
	["husky_uaa", "res://assets/animals/uaa/Husky.gltf", 0.25],
	["shiba_uaa", "res://assets/animals/uaa/ShibaInu.gltf", 0.20],
]
var _f := 0
var _cam: Camera3D
var _pets := []

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
	var x := -5.0
	for p in PETS:
		var kn: Node3D = (load(ADV + "Knight.glb") as PackedScene).instantiate()
		kn.position = Vector3(x, 0, 0)
		root.add_child(kn)
		var pet := HeroPet.new()
		pet.owner_body = kn
		pet.model = p[1]
		pet.scale_f = p[2]
		kn.add_child(pet)
		_pets.append([p[0], pet])
		x += 2.5
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.6, 0) - Vector3(0, 2.6, 9.5), Vector3.UP), Vector3(0, 2.6, 9.5))
	_cam.make_current()

func _height(n: Node) -> float:
	var lo := INF
	var hi := -INF
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D:
			var bb: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
			lo = minf(lo, bb.position.y)
			hi = maxf(hi, bb.end.y)
		for g in c.get_children():
			st.append(g)
	return hi - lo if hi > lo else 0.0

func _process(_d: float) -> bool:
	_f += 1
	if _f == 40:
		var out := ProjectSettings.globalize_path("res://renders/cycles/s138/pets.png")
		print("S138_PETS shot rc=", root.get_texture().get_image().save_png(out))
		var bad := []
		for e in _pets:
			var pet: HeroPet = e[1]
			var h := _height(pet)
			print("S138_PETS %s walk=%s idle=%s h=%.2f m" % [e[0], pet._walk, pet._idle, h])
			if String(e[0]).ends_with("uaa"):
				if pet._walk == "" or pet._idle == "" or pet._idle.find("HitReact") >= 0 or h < 0.2 or h > 0.9:
					bad.append(e[0])
		if bad.is_empty():
			print("S138_PETS OK 3 UAA pets load in HeroPet with walk+idle clips and heel height 0.2-0.9 m")
		else:
			print("S138_PETS FAIL ", bad)
		return true
	return false
