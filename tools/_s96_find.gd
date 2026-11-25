extends SceneTree
## S96 / SYSTEM 9 row (b): A DEEP-FLOOR WEAPON FIND LIES ON THE FLOOR IN ITS OWN MODEL BEFORE IT IS TAKEN.
## WINDOWED. A real delve (Delve.start). In the first live fight the delve's own _loot is called (the real
## wiring, not a copy of it) with the floor number raised so find_gear can fire; the finder's armour is set
## level with the weapon so a find is a WEAPON. Repeated until a find lands (dice are the delve's own).
## Measured:
##   1. a FoundWeapon node exists the frame after the find (finds_shown 1)
##   2. its mesh is roster.weapon_mesh(hero) - the path the hand now carries, and it loads
##   3. it sits on the floor (dy under 0.15 m) in front of the finder
##   4. it is gone again within 5 s (lifted and freed)
## Test artifacts, named: _loot pays its gold/xp each call and the lord (if any) is held aside for the calls.
## Renders renders/cycles/s96/s96_1_find_on_floor.png. Prints S96_FIND OK / FAIL. Quits itself - run WITHOUT --quit.
const OUT := "res://renders/cycles/s96/"
var _f := 0
var _t := 0.0
var _r: Roster
var _d: Delve
var _cam: Camera3D
var _fail := 0
var _checks := 0
var _phase := "wait"
var _w: Node3D = null
var _w_at := Vector3.ZERO
var _fb: Node3D = null

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _snap(nm: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm + ".png"))
	print("SAVED ", nm, " state=", _d.state)

func _aim(at: Vector3) -> void:
	_cam.make_current()
	if _d.dun.env():
		_cam.environment = _d.dun.env()
	# over the finder's shoulder, looking down past them at the stones in front - inside the room, never a wall
	var back := Vector3(0, 0, -1)
	if _fb != null and is_instance_valid(_fb):
		var fz := _fb.global_transform.basis.z
		back = -Vector3(fz.x, 0, fz.z).normalized()
		_cam.global_position = _fb.global_position + back * 0.9 + Vector3(0, 2.2, 0)
	else:
		_cam.global_position = at + Vector3(0, 2.4, 0.4)
	_cam.look_at(at, Vector3.UP)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_r = Roster.new()
	root.add_child(_r)

func _finish() -> bool:
	print("S96_FIND %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
	return true

func _find_node() -> Node3D:
	var host: Node = _d.dun.info["root"] if _d.dun and _d.dun.info.has("root") else _d
	for c in host.get_children():
		if String(c.name).begins_with("FoundWeapon") and not c.is_queued_for_deletion():
			return c
	return null

func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		var ids := []
		var cls := ["rogue", "knight", "cleric"]
		for i in 3:
			var h: Dictionary = _r.fresh("f%d" % i, "Find%d" % i, cls[i], "human")
			h["oil"] = 3
			h["level"] = 12
			ids.append("f%d" % i)
		_d = Delve.new()
		_d.roster = _r
		_d.start_floor = 5
		_d.max_floors = 6
		root.add_child(_d)
		_d.start(ids)
		_d.turn_back_at = 0.0
		for m in _d.party:
			m["max"] = float(m["max"]) * 20.0
			m["hp"] = m["max"]
		_cam = Camera3D.new()
		_cam.fov = 50.0
		root.add_child(_cam)
		return false
	if _f < 3 or _d == null:
		return false
	_t += delta
	if _t > 90.0:
		_ok(false, "finished inside 90 s (phase %s)" % _phase)
		return _finish()
	match _phase:
		"wait":
			if _d.dun != null and is_instance_valid(_d.dun) and _d.state == "fight" and _f > 6:
				var alive: Array = _d._alive()
				for m in alive:
					m["h"]["armour"] = int(m["h"].get("weapon", 0))
				var lord = _d.dun.lord
				_d.dun.lord = null
				var fl := _d.floor_no
				_d.floor_no = 24
				var tries := 0
				while _d.finds_shown == 0 and tries < 60:
					for m in alive:
						m["h"]["armour"] = int(m["h"].get("weapon", 0))
					_d._loot(alive)
					tries += 1
				_d.floor_no = fl
				_d.dun.lord = lord
				_ok(_d.finds_shown == 1, "a weapon find was shown on the floor (finds_shown %d, %d _loot calls)" % [_d.finds_shown, tries])
				_w = _find_node()
				_ok(_w != null, "a FoundWeapon node is in the scene")
				if _w == null:
					return _finish()
				var path := String(_w.get_meta("find_path", ""))
				var finder_mesh := ""
				for m in alive:
					if _r.weapon_mesh(m["h"]) == path:
						finder_mesh = path
						_fb = m["body"]
				_ok(path != "" and path == finder_mesh, "its mesh is the finder's own weapon_mesh (%s)" % path)
				_ok(ResourceLoader.exists(path), "that mesh loads")
				_w_at = _w.global_position
				_ok(absf(_w_at.y - _d.dun.global_position.y) < 0.15, "it lies on the floor (dy %.3f)" % (_w_at.y - _d.dun.global_position.y))
				for f in _d._foes():
					(f as Node3D).visible = false      # test artifact, named: the fight is frozen-in-place behind the shot
				_phase = "shot1"
				_t = 0.0
		"shot1":
			if is_instance_valid(_w):
				_aim(_w_at)
			if _t > 0.5:
				_snap("s96_1_find_on_floor")
				_phase = "gone"
				_t = 0.0
		"gone":
			if _find_node() == null:
				_ok(_t < 5.0, "the find is lifted and freed inside 5 s (%.1f s)" % (_t + 0.5))
				return _finish()
			if _t > 6.0:
				_ok(false, "the find is lifted and freed inside 5 s")
				return _finish()
	return false
