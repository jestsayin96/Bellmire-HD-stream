extends SceneTree
## S137 (copy of _s136_town_shot with the override ON): look at the UACP walkers IN the town, not on a test floor. Loads Town.tscn, waits for the walkers,
## frames the first uacp townsfolk from 5 m and saves renders/cycles/s137/in_town_skin_on.png. Run WITH a window.
var _f := 0
var _cam: Camera3D

func _initialize() -> void:
	root.add_child((load("res://Town.tscn") as PackedScene).instantiate())

func _process(_d: float) -> bool:
	_f += 1
	if _f == 600:
		var n := 0
		var tgt: Node3D = null
		for t in root.find_children("*", "Townsfolk", true, false):
			if String(t.model).begins_with("uacp/"):
				n += 1
				if tgt == null or (t.global_position.y < 0.5 and String(t.model).contains("Chef")):
					tgt = t
		print("S137_TOWN uacp walkers=", n)
		if tgt == null:
			print("S137_TOWN FAIL no uacp walker in town")
			return true
		_cam = Camera3D.new()
		root.add_child(_cam)
		var p: Vector3 = tgt.global_position
		var fw: Vector3 = -tgt.global_transform.basis.z
		var cp: Vector3 = p + Vector3(2.5, 6.5, 4.5)
		_cam.global_transform = Transform3D(Basis.looking_at(p + Vector3(0, 0.9, 0) - cp, Vector3.UP), cp)
		_cam.fov = 45.0
		_cam.make_current()
		print("S137_TOWN framing ", tgt.person_name, " ", tgt.model, " role ", tgt.role)
	if _f == 610:
		var img := root.get_texture().get_image()
		var out := ProjectSettings.globalize_path("res://renders/cycles/s137/in_town_skin_on.png")
		print("S137_TOWN shot rc=", img.save_png(out))
		return true
	return false
