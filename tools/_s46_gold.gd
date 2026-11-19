extends SceneTree
## S46: the seven artifact .glb (assets/gear/artifact/) with NO game tint and NO tier-5 smoulder - only the
## file's own materials, to prove the colour is IN THE MESH. Checks every surface's imported albedo is not
## the glTF default white, and that every surface named Golden reads gold (r > b by a margin). One windowed
## shot, renders/cycles/s46/s46_gold_plain.png. Prints S46_GOLD lines and S46_GOLD OK / FAIL.
const FILES := ["sword_golden", "sword_big_golden", "dagger_golden", "axe_small_golden",
	"axe_double_golden", "hammer_double_golden", "bow_golden"]
var _f := 0
var _fails := 0
func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.2, 9.0), Vector3(0, 1.0, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.29, 0.31, 0.35)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	w.add_child(env)
	var x := -6.0
	for nm in FILES:
		var ps: PackedScene = load("res://assets/gear/artifact/%s.glb" % nm)
		if ps == null:
			print("S46_GOLD FAIL %s: did not load" % nm); _fails += 1; continue
		var n: Node3D = ps.instantiate()
		w.add_child(n)
		n.position = Vector3(x, 0, 0)
		x += 2.0
		var mats := []
		var st: Array = [n]
		while not st.is_empty():
			var c: Node = st.pop_back()
			if c is MeshInstance3D and (c as MeshInstance3D).mesh:
				var mi: MeshInstance3D = c
				for i in range(mi.mesh.get_surface_count()):
					var m := mi.get_active_material(i) as BaseMaterial3D
					if m == null:
						print("S46_GOLD FAIL %s surface %d: no material" % [nm, i]); _fails += 1; continue
					var a: Color = m.albedo_color
					mats.append("%s(%.2f,%.2f,%.2f m%.1f)" % [m.resource_name, a.r, a.g, a.b, m.metallic])
					if a.is_equal_approx(Color.WHITE):
						print("S46_GOLD FAIL %s %s: albedo is default WHITE" % [nm, m.resource_name]); _fails += 1
					if m.resource_name == "Golden" and not (a.r > a.b + 0.2):
						print("S46_GOLD FAIL %s Golden: albedo does not read gold" % nm); _fails += 1
			for g in c.get_children():
				st.append(g)
		print("S46_GOLD %s | %s" % [nm, " ".join(mats)])
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/s46"))
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/s46/s46_gold_plain.png"))
		print("S46_GOLD %s (7 files, %d failures)" % ["OK" if _fails == 0 else "FAIL", _fails])
		return true
	return false
