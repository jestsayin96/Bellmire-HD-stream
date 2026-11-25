extends SceneTree
## S83 / SYSTEM 9 row (a): THE MINIBOSS PURSE LANDS ON THE FLOOR AND A DELVER WALKS TO IT.
## WINDOWED. A real delve (Delve.start). In the first live fight one standing monster is given
## the L29c purse meta and felled through Delve._on_kill. Then, measured:
##   1. a PursePile node is on the floor where it fell, registered in dun.info.chests with a purse
##   2. NO gold is paid at the kill (the purse is on the floor, not in a pocket)
##   3. within 60 s the party clears the floor, a delver walks to the pile (search state), the pile
##      is gathered (purses_taken 1, node freed) and every alive delver's gold rose by the share
## Renders renders/cycles/s83/s83_1_purse_on_floor.png and s83_2_walked_to_it.png.
## Prints S83_PURSE OK / FAIL. Quits itself - run WITHOUT --quit.
const OUT := "res://renders/cycles/s83/"
var _f := 0
var _t := 0.0
var _r: Roster
var _d: Delve
var _cam: Camera3D
var _fail := 0
var _checks := 0
var _phase := "wait"
var _pile: Node3D = null
var _pile_at := Vector3.ZERO
var _gold0 := {}
var _snapped2 := false
var _kneel_seen := false

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
	_cam.global_position = at + Vector3(1.5, 2.1, 2.0)
	_cam.look_at(at + Vector3(0, 0.3, 0), Vector3.UP)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_r = Roster.new()
	root.add_child(_r)

func _finish() -> bool:
	print("S83_PURSE %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
	return true

func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		var ids := []
		var cls := ["knight", "rogue", "cleric"]
		for i in 3:
			var h: Dictionary = _r.fresh("p%d" % i, "Purse%d" % i, cls[i], "human")
			h["oil"] = 3
			h["level"] = 12
			ids.append("p%d" % i)
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
		_cam.fov = 55.0
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
				var foes: Array = _d._foes()
				if foes.is_empty():
					return false
				var mon: Monster = foes[0]
				for m in _d._alive():
					_gold0[String(m["uid"])] = int(m["h"].get("gold", 0))
				mon.set_meta("l29c_miniboss_purse", 120)
				mon.hp = 0
				mon.state = Monster.S.DEAD
				_d._on_kill(mon)
				# test artifact, named: this gate fells the body by setting DEAD, which skips the death
				# animation, so the corpse would stand over the pile. Hide it so the frame shows the floor.
				mon.visible = false
				for c in _d.dun.info.get("chests", []):
					if (c as Dictionary).has("purse"):
						_pile = c["node"]
				_ok(_pile != null and is_instance_valid(_pile), "a PursePile is registered on the floor with its purse")
				_ok(_d.purses_dropped == 1, "purses_dropped == 1 (%d)" % _d.purses_dropped)
				var paid := false
				for m in _d._alive():
					if int(m["h"].get("gold", 0)) != int(_gold0[String(m["uid"])]):
						paid = true
				_ok(not paid, "no gold is paid at the kill - the purse is on the floor")
				if _pile == null:
					return _finish()
				_pile_at = _pile.global_position
				_ok(absf(_pile_at.y - _d.dun.global_position.y) < 0.05, "the pile sits on the floor (dy %.3f)" % (_pile_at.y - _d.dun.global_position.y))
				_phase = "shot1"
				_t = 0.0
		"shot1":
			_aim(_pile_at)
			if _t > 0.4:
				_snap("s83_1_purse_on_floor")
				_phase = "walk"
		"walk":
			if is_instance_valid(_pile) and _d.state == "search":
				for m in _d._alive():
					var b: Node3D = m["body"]
					if is_instance_valid(b) and _d._flat(b.global_position, _pile_at) <= Delve.SEARCH_REACH:
						_kneel_seen = true
						if not _snapped2 and _d._search_t > 0.6:
							_aim(_pile_at)
							_snapped2 = true
							_snap("s83_2_walked_to_it")
			if _d.purses_taken >= 1:
				_ok(_kneel_seen, "a delver stood within reach of the pile in the search state before it was taken")
				_ok(_snapped2, "the walked-to-it frame was rendered")
				_ok(not is_instance_valid(_pile) or _pile.is_queued_for_deletion(), "the pile is gathered up (node freed)")
				var alive: Array = _d._alive()
				var share := maxi(1, 120 / maxi(1, alive.size()))
				var all_up := true
				for m in alive:
					var g0 := int(_gold0.get(String(m["uid"]), 0))
					if int(m["h"].get("gold", 0)) < g0 + share:
						all_up = false
				_ok(all_up, "every alive delver's gold rose by at least the share (%d)" % share)
				return _finish()
	return false
