extends SceneTree
## D58 LOOK (WINDOWED, 1920x1080): the market square with folk walking. An
## overview, a close shot, and a 6-frame close strip 0.1 s apart (stride read).
## Prints how many folk within 30 m of the market are walking at each shot.
var _t
var _cam: Camera3D
var _f := 0
var _dir := ""
var _shots: Array = []
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/d58/")
	DirAccess.make_dir_recursive_absolute(_dir)
func _eye(at: Vector3, frm: Vector3) -> void:
	frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
	_cam.global_position = frm
	_cam.look_at(at, Vector3.UP)
func _walkers(mk: Vector3) -> int:
	var n := 0
	for p in _t.get("people"):
		if is_instance_valid(p) and p is Townsfolk and not p.inside and p.visible \
				and (p.global_position - mk).length() < 30.0 and float(p.get("_vs")) > 0.4:
			n += 1
	return n
func _process(_d: float) -> bool:
	_f += 1
	if _f == 12:
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 50.0
		var rd = _t.get("raids")
		if rd != null:
			rd.set("_raid_t", 99999.0)
		var mk: Vector3 = _t.get("_market_pos")
		_shots = [[mk, mk + Vector3(16, 12, 16), "square_over_1080", 600],
			[mk, mk + Vector3(8, 3.2, 8), "square_close_1080", 700]]
		for i in 6:
			_shots.append([mk, mk + Vector3(6, 2.4, 6), "strip_%d" % i, 760 + i * 6])
	var ec = _t.get("economy")
	if ec != null:
		ec.clock = 12.3 / 24.0
	if _shots.is_empty():
		if _f > 30:
			print("D58_SHOTS DONE")
			return true
		return false
	var s: Array = _shots[0]
	_eye(s[0], s[1])
	if _f < int(s[3]):
		return false
	root.get_texture().get_image().save_png(_dir + String(s[2]) + ".png")
	print("SAVED %s walkers_near_market=%d" % [s[2], _walkers(s[0])])
	_shots.pop_front()
	return false
