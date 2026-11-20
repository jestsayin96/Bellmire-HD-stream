extends SceneTree
## S47: ONE CLOSE RENDER OF bow_golden, to settle whether the string is there. bow_golden is the only one of
## the seven _Golden meshes whose third material is "White" (0.8,0.8,0.8). Plain file, NO game tint, NO
## smoulder. Prints the White surface's vertex count and AABB (a string is long on one axis, thin on the
## others) and frames the camera on the whole bow's AABB, front and side. Prints S47_BOW OK / FAIL.
var _f := 0
var _fails := 0
var _cam: Camera3D
var _c := Vector3.ZERO
var _r := 1.0
func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	_cam = Camera3D.new()
	_cam.fov = 30.0
	w.add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	w.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.13, 0.16)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	w.add_child(env)
	var ps: PackedScene = load("res://assets/gear/artifact/bow_golden.glb")
	if ps == null:
		print("S47_BOW FAIL: bow_golden.glb did not load"); _fails += 1; return
	var n: Node3D = ps.instantiate()
	w.add_child(n)
	var all := AABB()
	var first := true
	var white_found := false
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var mi: MeshInstance3D = c
			var xf := Transform3D()
			var q: Node = mi
			while q != null and q != w and q is Node3D:
				xf = (q as Node3D).transform * xf
				q = q.get_parent()
			for i in range(mi.mesh.get_surface_count()):
				var arr: Array = mi.mesh.surface_get_arrays(i)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var bb := AABB(xf * v[0], Vector3.ZERO)
				for p in v:
					bb = bb.expand(xf * p)
				all = bb if first else all.merge(bb)
				first = false
				var m := mi.get_active_material(i) as BaseMaterial3D
				var nm: String = m.resource_name if m else "<none>"
				var a: Color = m.albedo_color if m else Color.BLACK
				print("S47_BOW surface %d %s albedo(%.2f,%.2f,%.2f) verts=%d aabb_size=(%.3f,%.3f,%.3f)" % [i, nm, a.r, a.g, a.b, v.size(), bb.size.x, bb.size.y, bb.size.z])
				if nm == "White":
					white_found = true
					if v.size() < 3:
						print("S47_BOW FAIL: White surface has no geometry"); _fails += 1
		for g in c.get_children():
			st.append(g)
	print("S47_BOW bow aabb_size=(%.3f,%.3f,%.3f)" % [all.size.x, all.size.y, all.size.z])
	if not white_found:
		print("S47_BOW FAIL: no White surface"); _fails += 1
	_c = all.get_center()
	_r = all.size.length() * 0.5
	_cam.look_at_from_position(_c + Vector3(0, 0, _r * 3.9), _c)
func _shot(nm: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/s47"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/s47/%s.png" % nm))
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_shot("s47_bow_front")
		_cam.look_at_from_position(_c + Vector3(_r * 3.9, 0, 0.001), _c)
	elif _f == 40:
		_shot("s47_bow_side")
		_cam.look_at_from_position(_c + Vector3(_r * 2.8, _r * 0.4, _r * 2.8), _c)
	elif _f == 60:
		_shot("s47_bow_three_quarter")
		print("S47_BOW %s (3 shots, %d failures)" % ["OK" if _fails == 0 else "FAIL", _fails])
		return true
	return false
