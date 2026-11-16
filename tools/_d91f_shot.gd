extends SceneTree
## D91f LOOK (WINDOWED): the north store's door step on the market ring, after the stall's crate
## was moved off it. renders/cycles/d91f/door_*.png - one high, one at eye height. Read-only.
var _t: Node3D
var _cam: Camera3D
var _f := 0
const DOOR := Vector3(32.47, 0.88, -69.38)
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/cycles/d91f/"))
func _eye(frm: Vector3) -> void:
	frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
	_cam.global_position = frm
	_cam.look_at(DOOR + Vector3(0, 0.4, 0), Vector3.UP)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 3:
		_cam = Camera3D.new()
		_cam.fov = 55.0
		root.add_child(_cam)
		_cam.make_current()
	if _f == 4:
		_eye(DOOR + Vector3(3.0, 9.0, -7.0))
	if _f == 60:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/d91f/door_high.png"))
		print("SAVED door_high")
		_eye(DOOR + Vector3(2.5, 1.7, -6.5))
	if _f == 120:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://renders/cycles/d91f/door_eye.png"))
		print("SAVED door_eye")
		return true
	return false
