extends SceneTree
## S81 probe (tier-4 shield richness question from the 04:0x TAKE THIS NEXT): lists every surface material of the
## five Quaternius shields with its albedo colour and texture, so "which pair is painted" is read off the files.
## Headless: <console> --headless --path . --script tools/_s81_shieldmat.gd   Prints S81_SHIELDMAT OK|FAIL.
func _walk(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m:
			for s in m.get_surface_count():
				var mat = (n as MeshInstance3D).get_active_material(s)
				if mat is BaseMaterial3D:
					var c: Color = (mat as BaseMaterial3D).albedo_color
					out.append("%s:%s rgb(%.2f,%.2f,%.2f) metal %.2f tex=%s" % [n.name, String(mat.resource_name), c.r, c.g, c.b, (mat as BaseMaterial3D).metallic, str((mat as BaseMaterial3D).albedo_texture != null)])
				else:
					out.append("%s:surf%d %s" % [n.name, s, str(mat)])
	for ch in n.get_children():
		_walk(ch, out)

func _init() -> void:
	var bad := 0
	for f in ["shield_heater", "shield_heater_2", "shield_round", "shield_round_2", "shield_celtic_golden"]:
		var ps = load("res://assets/gear/shields/%s.fbx" % f)
		if ps == null:
			print("  FAIL load ", f)
			bad += 1
			continue
		var inst: Node = (ps as PackedScene).instantiate()
		var out: Array = []
		_walk(inst, out)
		print("== %s (%d surfaces)" % [f, out.size()])
		for l in out:
			print("    ", l)
		inst.free()
	print("S81_SHIELDMAT %s (5 files, %d load failures)" % ["OK" if bad == 0 else "FAIL", bad])
	quit()
