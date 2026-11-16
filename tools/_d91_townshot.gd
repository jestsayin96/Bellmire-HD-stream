extends SceneTree
## D91c LOOK (WINDOWED): the town half of D91, renders/cycles/d91c/.
##  a/b  the horse paddock with the late settle OFF, then the same camera with it ON
##  c    the tavern keeper, now set down beside the large table instead of inside it
##  d/e  whoever on the street stands nearest a bush, twice - Mr. E's wizard-in-a-bush
## Clock pinned to midday, raids suppressed.
var _t: Node3D
var _cam: Camera3D
var _f := 0
var _dir := ""
var _h: Array = []
var _shots := 0

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	_t.set("settle_on", false)
	_dir = ProjectSettings.globalize_path("res://renders/cycles/d91c/")
	DirAccess.make_dir_recursive_absolute(_dir)

func _eye(at: Vector3, frm: Vector3) -> void:
	frm.y = maxf(frm.y, float(_t.call("height_at", frm.x, frm.z)) + 1.0)
	_cam.global_position = frm
	_cam.look_at(at + Vector3(0, 0.6, 0), Vector3.UP)

func _snap(tag: String) -> void:
	root.get_texture().get_image().save_png(_dir + tag + ".png")
	print("SAVED " + tag)
	_shots += 1

func _horses() -> Array:
	var hs: Array = []
	for a in _t.get("animals"):
		if is_instance_valid(a) and String(a.get("kind")) in ["Horse", "Llama", "Cow", "Sheep"]:
			hs.append(a)
	var best: Array = []
	var bo := 0.0
	for i in range(hs.size()):
		for j in range(i + 1, hs.size()):
			var a: Node3D = hs[i]
			var b: Node3D = hs[j]
			var L := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
			var o := Crowd.body_r(a) + Crowd.body_r(b) - L
			if o > bo:
				bo = o
				best = [a, b]
	return best

func _gap(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length() - Crowd.body_r(a) - Crowd.body_r(b)

func _bush_pick() -> Array:
	var bushes: Array = []
	for ch in _t.get_children():
		if ch is Node3D and String(ch.scene_file_path).get_file().begins_with("Bush"):
			bushes.append(ch)
	var best: Array = []
	var bd := 1e9
	for o in _t.get("people"):
		if not is_instance_valid(o) or not (o as Node3D).visible or o.get("inside") == true:
			continue
		for bu in bushes:
			var d := Vector2((o as Node3D).global_position.x - (bu as Node3D).global_position.x, (o as Node3D).global_position.z - (bu as Node3D).global_position.z).length()
			if d < bd:
				bd = d
				best = [o, bu, d]
	return best

func _process(_d: float) -> bool:
	_f += 1
	var ec = _t.get("economy")
	if ec != null:
		ec.clock = 12.3 / 24.0
	var rd = _t.get("raids")
	if rd != null:
		rd.set("_raid_t", 99999.0)
	if _f == 12:
		_cam = Camera3D.new()
		_t.add_child(_cam)
		_cam.make_current()
		_cam.fov = 45.0
	if _f == 240:
		_h = _horses()
		if _h.is_empty():
			print("D91T_SHOT no overlapping beasts with the settle off")
		else:
			var a: Node3D = _h[0]
			var b: Node3D = _h[1]
			print("D91T_SHOT before: %s + %s gap %.2f m (negative = inside each other)" % [a.get("kind"), b.get("kind"), _gap(a, b)])
	if _f > 240 and not _h.is_empty() and _f < 400:
		var mid: Vector3 = ((_h[0] as Node3D).global_position + (_h[1] as Node3D).global_position) * 0.5
		_eye(mid, mid + Vector3(5.5, 3.2, 5.5))
	if _f == 250 and not _h.is_empty():
		_snap("a_beasts_settle_off")
		_t.set("settle_on", true)
	if _f == 330 and not _h.is_empty():
		print("D91T_SHOT after: gap %.2f m" % _gap(_h[0], _h[1]))
		_snap("b_beasts_settle_on")
	if _f == 420:
		for o in _t.get("people"):
			if is_instance_valid(o) and String(o.get("role")) == "tavern":
				var p: Vector3 = (o as Node3D).global_position
				var r: Array = _t.call("solid_at", p, 0.0)
				print("D91T_SHOT tavern keeper at %s in a footprint: %s" % [str(p), str(not r.is_empty())])
				var fw := Vector3(sin(float(o.get("face_yaw"))), 0, cos(float(o.get("face_yaw"))))
				_eye(p, p + fw * 6.0 + Vector3(2.5, 3.5, 0))
				break
	if _f == 430:
		_snap("c_tavern_keeper")
	for k in [[900, "d_nearest_bush_1"], [1500, "e_nearest_bush_2"]]:
		if _f >= int(k[0]) - 8 and _f <= int(k[0]):
			var bp := _bush_pick()
			if not bp.is_empty():
				var o: Node3D = bp[0]
				var bu: Node3D = bp[1]
				var mid := (o.global_position + bu.global_position) * 0.5
				_eye(mid, mid + Vector3(3.2, 2.2, 3.2))
				if _f == int(k[0]):
					var r: Array = _t.call("solid_at", o.global_position, 0.0)
					print("D91T_SHOT %s: %s %s centre %.2f m from the bush, inside a footprint: %s" % [k[1], o.get("role"), o.get("person_name"), float(bp[2]), str(not r.is_empty())])
					_snap(String(k[1]))
	if _f > 1520:
		print("D91T_SHOT %d shots" % _shots)
		return true
	return false
