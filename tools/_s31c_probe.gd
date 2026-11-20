extends SceneTree
## S31c probe: where do the KayKit knight's hands go during Use_Item (the clip delve.drink() plays)?
## Prints S31C_PROBE lines: t, handslot.r / handslot.l height and forward reach (+z), head height.
var _f := 0
var m: Node3D
var ap: AnimationPlayer
var sk: Skeleton3D
func _initialize() -> void:
	m = (load("res://addons/kaykit_character_pack_adventures/Characters/gltf/" + String(Roster.CLASSES["knight"]["model"])) as PackedScene).instantiate()
	root.add_child(m)
	ap = Rig.find(m)
	sk = Rig.skeleton(m)
func _bone(nm: String) -> Vector3:
	var i := sk.find_bone(nm)
	if i < 0:
		return Vector3(-9, -9, -9)
	return (sk.global_transform * sk.get_bone_global_pose(i)).origin
func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	if ap == null or sk == null or not ap.has_animation("Use_Item"):
		print("S31C_PROBE FAIL no rig/clip")
		return true
	var a := ap.get_animation("Use_Item")
	print("S31C_PROBE len %.2f" % a.length)
	ap.play("Use_Item")
	var t := 0.0
	while t <= a.length + 0.001:
		ap.seek(t, true)
		sk.force_update_all_bone_transforms()
		var r := _bone("handslot.r")
		var l := _bone("handslot.l")
		var h := _bone("head")
		print("S31C_PROBE t %.2f R y %.2f z %.2f x %.2f | L y %.2f z %.2f x %.2f | head y %.2f z %.2f" % [t, r.y, r.z, r.x, l.y, l.z, l.x, h.y, h.z])
		t += 0.1
	print("S31C_PROBE OK")
	return true
