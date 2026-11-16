extends SceneTree
## D50 LOOK (WINDOWED): is the town visibly alive? Market square (where folk
## "congregate not doing anything") + a closer crop. Clock pinned to midday.
var _t
var _cam: Camera3D
var _f := 0
var _dir := ""
var _shots: Array = []
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/d50/")
	DirAccess.make_dir_recursive_absolute(_dir)
func _eye(at: Vector3, frm: Vector3) -> void:
	frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
	_cam.global_position = frm
	_cam.look_at(at, Vector3.UP)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 12:
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 55.0
		var rd = _t.get("raids")
		if rd != null:
			rd.set("_raid_t", 99999.0)
		var mk: Vector3 = _t.get("_market_pos")
		_shots = [
			[mk, mk + Vector3(14, 11, 14), "square_over", 300],
			[mk, mk + Vector3(7, 3.4, 7), "square_close", 430],
		]
	var ec = _t.get("economy")
	if ec != null:
		ec.clock = 12.3 / 24.0
	if _shots.is_empty():
		if _f > 30:
			print("D50_SHOTS DONE")
			return true
		return false
	var s: Array = _shots[0]
	if _f % 15 == 0:
		_eye(s[0], s[1])
	if _f < int(s[3]):
		return false
	_eye(s[0], s[1])
	root.get_texture().get_image().save_png(_dir + String(s[2]) + ".png")
	print("SAVED ", s[2])
	_shots.pop_front()
	return false
