extends SceneTree
## S50 - System 8: the five Quaternius shields in assets/gear/shields/ LOAD as PackedScene,
## instantiate with a mesh, and report their AABB size (metres) so the off-hand scale can be set
## from a number, not a guess. Headless, quits itself.
## Prints S50_LOAD OK n=5 | S50_LOAD FAIL <names>.
const NAMES := ["shield_celtic_golden", "shield_heater", "shield_heater_2", "shield_round", "shield_round_2"]
func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_aabb(c, t, acc)
func _initialize() -> void:
	var bad: Array = []
	for n in NAMES:
		var p := "res://assets/gear/shields/%s.fbx" % n
		var ps := load(p) as PackedScene if ResourceLoader.exists(p) else null
		var meshes := 0
		var size := Vector3.ZERO
		if ps != null:
			var node := ps.instantiate()
			meshes = node.find_children("*", "MeshInstance3D", true, false).size()
			var acc := [null]
			_aabb(node, Transform3D.IDENTITY, acc)
			if acc[0] != null:
				size = (acc[0] as AABB).size
			node.free()
		print("  %s %s meshes=%d size=%.3f x %.3f x %.3f" % ["ok  " if meshes > 0 else "FAIL", n, meshes, size.x, size.y, size.z])
		if meshes == 0:
			bad.append(n)
	print("S50_LOAD OK n=%d" % NAMES.size() if bad.is_empty() else "S50_LOAD FAIL %s" % str(bad))
	quit()
