extends SceneTree
# tools/art/_timberman_load.gd - ART LANE, tools/art/ only.
# The 61st body (timberman) got its .glb.import generated this run. Generating a
# sibling is NOT proof that the resource resolves, so this loads it and counts
# its meshes, with a control that already had its sibling before this run.
# RED ON EMPTY: a run that checks zero bodies is a FAIL, not a silent pass.
func _init():
	var owed := ["timberman"]
	var control := ["crimp", "pledgeman"]
	var fails := 0
	var checked := 0
	for group in [["OWED", owed], ["CONTROL", control]]:
		for n in group[1]:
			var p: String = "res://assets/monsters/minibosses/%s.glb" % n
			checked += 1
			if not ResourceLoader.exists(p):
				print("LOADCHECK FAIL %s %s - ResourceLoader.exists false" % [group[0], n])
				fails += 1
				continue
			var ps = load(p)
			if ps == null:
				print("LOADCHECK FAIL %s %s - load() returned null" % [group[0], n])
				fails += 1
				continue
			var inst = ps.instantiate()
			if inst == null:
				print("LOADCHECK FAIL %s %s - instantiate() null" % [group[0], n])
				fails += 1
				continue
			var meshes := 0
			var stack: Array = [inst]
			while not stack.is_empty():
				var node = stack.pop_back()
				if node is MeshInstance3D:
					meshes += 1
				for c in node.get_children():
					stack.append(c)
			if meshes <= 0:
				print("LOADCHECK FAIL %s %s - loaded with ZERO MeshInstance3D" % [group[0], n])
				fails += 1
			else:
				print("LOADCHECK OK %s %s - %d meshes" % [group[0], n, meshes])
			inst.queue_free()
	if checked == 0:
		print("LOADCHECK FAIL - RED ON EMPTY: zero bodies checked")
		fails += 1
	print("LOADCHECK DONE checked=%d fails=%d" % [checked, fails])
	quit(1 if fails > 0 else 0)
