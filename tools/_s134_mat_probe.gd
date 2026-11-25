extends SceneTree
## S134: why does a UACP body that loads and measures fine draw NOTHING in the lineup? Dump its
## mesh instances, visibility, skin and materials.
func _initialize() -> void:
	var n: Node = (load("res://assets/characters/uacp/Worker_Male.glb") as PackedScene).instantiate()
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		var line := "S134_MAT %s %s" % [c.get_class(), c.name]
		if c is Node3D:
			line += " vis=%s scale=%s" % [(c as Node3D).visible, (c as Node3D).scale]
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			line += " aabb=%s skin=%s skel=%s surf=%d" % [mi.get_aabb(), mi.skin != null, mi.skeleton, mi.mesh.get_surface_count() if mi.mesh else -1]
			if mi.mesh:
				for s in mi.mesh.get_surface_count():
					var m = mi.get_active_material(s)
					if m is BaseMaterial3D:
						var b := m as BaseMaterial3D
						line += " | s%d albedo=%s transp=%d cull=%d" % [s, b.albedo_color, b.transparency, b.cull_mode]
					else:
						line += " | s%d mat=%s" % [s, m]
		print(line)
		for g in c.get_children():
			st.append(g)
	n.free()
	quit()
