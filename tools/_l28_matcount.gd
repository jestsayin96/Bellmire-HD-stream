extends SceneTree
## L28a: distinct materials on one built floor, kit look off vs on (the old tint duplicated
## a material per tinted piece; the kit surface shares one per theme/tint/steel)
func _initialize() -> void:
	for look in [false, true]:
		FloorGen.kit_look = look
		var tot := 0
		for f in [2, 5, 9]:
			var host := Node3D.new()
			root.add_child(host)
			FloorGen.build(host, f, Vector3.ZERO)
			var mats := {}
			var st: Array = [host]
			while st.size() > 0:
				var c: Node = st.pop_back()
				if c is MeshInstance3D:
					var mi: MeshInstance3D = c
					if mi.mesh:
						for i in mi.mesh.get_surface_count():
							var m = mi.get_active_material(i)
							if m:
								mats[m.get_rid()] = true
				for g in c.get_children():
					st.append(g)
			print("L28_MATS look=%s floor=%d theme=%s distinct=%d" % [look, f, FloorGen.theme_for(f), mats.size()])
			host.free()
	quit()
