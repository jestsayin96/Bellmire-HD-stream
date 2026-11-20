extends SceneTree
## S49 - the five System 7 shells in assets/gear/armour/ LOAD as PackedScene and instantiate with a
## mesh. Headless, quits itself. Prints S49_LOAD OK n=5 | S49_LOAD FAIL <names>.
const NAMES := ["armor_black", "armor_golden", "armor_leather", "armor_metal", "armor_metal2"]
func _initialize() -> void:
	var bad: Array = []
	for n in NAMES:
		var p := "res://assets/gear/armour/%s.glb" % n
		var ps := load(p) as PackedScene if ResourceLoader.exists(p) else null
		var meshes := 0
		if ps != null:
			var node := ps.instantiate()
			meshes = node.find_children("*", "MeshInstance3D", true, false).size()
			node.free()
		print("  %s %s meshes=%d" % ["ok  " if meshes > 0 else "FAIL", n, meshes])
		if meshes == 0:
			bad.append(n)
	print("S49_LOAD OK n=%d" % NAMES.size() if bad.is_empty() else "S49_LOAD FAIL %s" % str(bad))
	quit()
