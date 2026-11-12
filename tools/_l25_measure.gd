extends SceneTree
## L25 helper: the local bounds of kit pieces (min / max), to place them right.
static func bounds(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var x := (n as Node3D).global_transform.affine_inverse() * (c as MeshInstance3D).global_transform
			var a := x * (c as MeshInstance3D).get_aabb()
			out = a if first else out.merge(a)
			first = false
		for g in c.get_children():
			st.append(g)
	return out

func _initialize() -> void:
	var root3 := Node3D.new()
	root.add_child(root3)
	for k in ["stairs_narrow", "rubble_half", "barrier_half", "shelf_small", "crates_stacked", "box_stacked", "keg_decorated", "trunk_large_A", "bed_floor", "barrier_corner", "barrier_column", "sword_shield", "keyring_hanging", "chest_gold", "coin_stack_large", "table_long_broken", "table_medium_tablecloth", "barrel_large", "torch_mounted", "plate_food_B"]:
		var n := FloorGen._put(root3, k, Vector3.ZERO)
		if n:
			var b := bounds(n)
			print("M %-34s min %s  max %s" % [k, b.position.snappedf(0.01), b.end.snappedf(0.01)])
	quit()
