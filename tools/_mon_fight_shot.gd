extends SceneTree
## Monster animation render: the real town (its light), a party on floor 5 with
## its lord, three more creature kinds called in beside the lord; a camera of our
## own close on the fight. Saves a frame whenever the lord is mid-swing (and two
## of the fight) to renders/cycles/20261111_monanims.
var _t: Node3D
var _d: Delve
var _f := 0
var _cam: Camera3D
var _n := 0
var _added := false
var _last_shot := -999
const OUT := "res://renders/cycles/20261111_monanims"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		var r: Roster = _t.get("roster")
		var ids := []
		for v in [["2101", "JestFan", "knight"], ["2102", "MossyMage", "mage"], ["2103", "DawnCleric", "cleric"], ["2104", "BigAxe", "barbarian"]]:
			var h: Dictionary = r.fresh(v[0], v[1], v[2], "human")
			h["weapon"] = 1
			h["armour"] = 4
			h["oil"] = 4
			ids.append(v[0])
		Bestiary._spent = Bestiary.LESSER.duplicate()
		Bestiary._spent.erase("rattling_host")
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 5
		_d.max_floors = 5
		_t.add_child(_d)
		_d.start(ids)
		for m in _d.party:
			m["max"] = float(m["max"]) * 6.0
			m["hp"] = m["max"]
		_cam = Camera3D.new()
		_cam.fov = 50.0
		_t.add_child(_cam)
	if _d == null or _d.dun == null or not is_instance_valid(_d.dun):
		return false
	var lord: Monster = _d.dun.lord if _d.dun.lord and is_instance_valid(_d.dun.lord) else null
	if lord == null:
		return _f > 7000
	if not _added and not lord._entering():
		_added = true
		var i := 0
		for k in ["bowman", "spider", "sentinel"]:
			var a := float(i) * 2.1
			_d._spawn_on_floor(Bestiary.make(k, "plain"), lord.global_position + Vector3(cos(a), 0, sin(a)) * 3.0)
			i += 1
	# the camera sits off the lord, looking at it and the nearest delver
	var near: Vector3 = lord.global_position
	var nd := 1e9
	for m in _d._alive():
		var p: Vector3 = (m["body"] as Node3D).global_position
		if p.distance_to(lord.global_position) < nd:
			nd = p.distance_to(lord.global_position)
			near = p
	var mid := (lord.global_position + near) * 0.5 + Vector3(0, 1.6, 0)
	var side := (near - lord.global_position).cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3(1, 0, 0)
	_cam.global_position = mid + side * 15.0 + Vector3(0, 12.0, 0)
	_cam.look_at(mid, Vector3.UP)
	_cam.make_current()
	var an: Dictionary = lord.def.get("anims", {})
	var swinging := lord._ap != null and String(lord._ap.current_animation) == String(an.get("attack", "?"))
	if swinging and nd < 9.0 and _f - _last_shot > 40 and _n < 4:
		_last_shot = _f
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/lord_swing_%d.png" % _n))
		print("MONSHOT lord swing %d: %s playing %s, %d foes" % [_n, lord.def.get("name"), lord._ap.current_animation, _d._foes().size()])
		_n += 1
	if _n >= 4 or _f > 7000 or lord.state == Monster.S.DEAD:
		print("MONSHOT done %d frames" % _n)
		return true
	return false
