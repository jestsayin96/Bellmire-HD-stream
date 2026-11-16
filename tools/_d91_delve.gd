extends SceneTree
## D91 stages 2-4: bodies below ground, three-cell halls, the party in file.
##   D91_MODE=plan  : the plans only - every hall three across, rooms not paid for the halls
##   D91_MODE=soak  : D91_SECS of six-hero delves (default 1200), every body pair sampled every
##                    frame: frames with two centres closer than the sum of their body_r, bodies
##                    inside an obstacle, unsticks/forced descents, the slowest floor build
##   D91_MODE=shot  : windowed - a six-hero party down a hall meeting a monster line head-on,
##                    renders/cycles/d91/
const OUT := "res://renders/cycles/d91/"
var _mode := "soak"
var _r: Roster
var _d: Delve
var _f := 0
var _fail := 0
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
	print(("  ok   " if c else "  FAIL ") + what)

func _initialize() -> void:
	_mode = OS.get_environment("D91_MODE") if OS.get_environment("D91_MODE") != "" else "soak"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_r = Roster.new()
	root.add_child(_r)
	if _mode == "plan":
		_plan()
		quit()
	elif _mode == "shot":
		_shot_init()
	else:
		_secs = float(OS.get_environment("D91_SECS")) if OS.get_environment("D91_SECS") != "" else 1200.0

## ---------------------------------------------------------------- plan
func _run(cells: Dictionary, c: Vector2i, d: Vector2i) -> int:
	var n := 1
	var p := c + d
	while cells.has(p):
		n += 1
		p += d
	p = c - d
	while cells.has(p):
		n += 1
		p -= d
	return n

func _plan() -> void:
	var narrow := 0
	var halls_n := 0
	var short := 0
	var wants := 0
	var placed := 0
	var sizes := {}
	for fl in range(1, 61):
		var boss: bool = Bestiary.is_boss_floor(fl)
		var srng := RandomNumberGenerator.new()
		srng.seed = hash("floorsize:%d" % fl)
		var w: int = srng.randi_range(27, 33) if not boss else srng.randi_range(31, 35)
		var h: int = srng.randi_range(27, 33) if not boss else srng.randi_range(31, 35)
		sizes["%dx%d" % [w, h]] = true
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("floor:%d" % fl)
		var shape := FloorGen.shape_for(fl)
		var plan: Dictionary = FloorGen._layout(shape, w, h, rng)
		var cells: Dictionary = plan["cells"]
		var halls: Dictionary = plan["halls"]
		var want := int(FloorGen.PLANS[shape]["rooms"])
		wants += want
		placed += (plan["rooms"] as Array).size()
		if (plan["rooms"] as Array).size() < want:
			short += 1
		for c0 in halls:
			var c: Vector2i = c0
			halls_n += 1
			var wd := mini(_run(cells, c, Vector2i(1, 0)), _run(cells, c, Vector2i(0, 1)))
			if wd < 3:
				narrow += 1
		for c1 in cells:
			var cc: Vector2i = c1
			if cc.x < 0 or cc.y < 0 or cc.x >= w or cc.y >= h:
				narrow += 1000
	print("D91 plan: 60 floors, %d hall cells, %d narrower than three, rooms %d/%d wanted, %d floors short a room, sizes %s" % [halls_n, narrow, placed, wants, short, ", ".join(sizes.keys())])
	_ok(narrow == 0, "every hall cell is three or more across, and every cell inside the grid (%d narrow)" % narrow)
	_ok(short <= 3, "the halls did not cost rooms: %d of 60 floors short of their plan (%d/%d rooms)" % [short, placed, wants])
	_ok(sizes.size() >= 3, "floors vary in size (%d sizes)" % sizes.size())
	print("D91_PLAN %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])

## ---------------------------------------------------------------- soak
var _secs := 1200.0
var _game := 0.0
var _uid := 0
var _start := 1
var _frames := 0
var _ov_frames := 0          # frames with any pair closer than the sum of their body_r
var _ov_frames_cm := 0       # ... by more than 1 cm
var _ov_worst := 0.0
var _in_obs := 0             # body-frames with a centre inside an obstacle
var _pairs := 0
var _unsticks := 0
var _forced := 0
var _file_frames := 0
var _floors := 0
var _last_floor := -1
var _slow_ms := 0.0
var _tick_us := 0
var _delves := 0
var _maxn := 0

func _next() -> void:
	if _d:
		_close()
	var cls := ["knight", "rogue", "cleric", "barbarian", "ranger", "mage"]
	var ids := []
	for i in 6:
		_uid += 1
		var hh: Dictionary = _r.fresh("q%d" % _uid, "File%d" % _uid, cls[i], "human")
		hh["oil"] = 4
		hh["level"] = 20
		ids.append("q%d" % _uid)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = _start
	_d.max_floors = _start + 2
	_start += 3
	if _start > 40:
		_start = 1
	root.add_child(_d)
	_d.start(ids)
	_d.turn_back_at = 0.0
	for m in _d.party:
		m["max"] = float(m["max"]) * 10.0
		m["hp"] = m["max"]
	_delves += 1
	_last_floor = -1

func _close() -> void:
	_unsticks += _d.unsticks
	_forced += _d.forced
	_file_frames += _d.file_frames
	root.remove_child(_d)
	_d.queue_free()
	_d = null

func _sample() -> void:
	var bodies: Array = _d._crowd_bodies()
	_maxn = maxi(_maxn, bodies.size())
	var any := false
	var cm := false
	for i in range(bodies.size()):
		var a: Node3D = bodies[i]
		for j in range(i + 1, bodies.size()):
			var b: Node3D = bodies[j]
			if absf(a.global_position.y - b.global_position.y) > 3.0:
				continue
			_pairs += 1
			var L := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
			var o := Crowd.body_r(a) + Crowd.body_r(b) - L
			if o > 0.0:
				any = true
				_ov_worst = maxf(_ov_worst, o)
				if o > 0.01:
					cm = true
	if any:
		_ov_frames += 1
	if cm:
		_ov_frames_cm += 1
	var o0: Vector3 = _d.dun.global_position
	for b2 in bodies:
		var p: Vector3 = (b2 as Node3D).global_position
		for ob in _d.dun.info.get("obstacles", []):
			if FloorGen.obst_gap(ob, p.x - o0.x, p.z - o0.z) < 0.0:
				_in_obs += 1
				break

func _soak_tick(delta: float) -> bool:
	_game += delta
	var now := Time.get_ticks_usec()
	if _tick_us > 0 and _d and _d.floor_no != _last_floor:
		_slow_ms = maxf(_slow_ms, float(now - _tick_us) / 1000.0)
	_tick_us = now
	if _d == null or _d.state == "home" or _d._alive().is_empty() or _d.dun == null or not is_instance_valid(_d.dun):
		if _game >= _secs:
			if _d:
				_close()
			_report()
			return true
		_next()
		return false
	if _d.floor_no != _last_floor:
		_last_floor = _d.floor_no
		_floors += 1
	_frames += 1
	_sample()
	if _frames % 3000 == 0:
		print("  t=%.0fs delves=%d floors=%d frames=%d overlap_frames=%d (>1cm %d, worst %.3f) in_obstacle=%d bodies<=%d file=%d" % [_game, _delves, _floors, _frames, _ov_frames, _ov_frames_cm, _ov_worst, _in_obs, _maxn, _file_frames + _d.file_frames])
	return false

func _report() -> void:
	print("D91 soak: %.0f s, %d delves, %d floors, %d frames, %d pair-samples, up to %d bodies" % [_game, _delves, _floors, _frames, _pairs, _maxn])
	print("  overlap frames %d (>1 cm: %d), worst %.3f m; body-frames in an obstacle %d; unsticks %d, forced descents %d; frames in file %d; slowest floor change %.0f ms" % [_ov_frames, _ov_frames_cm, _ov_worst, _in_obs, _unsticks, _forced, _file_frames, _slow_ms])
	_ok(_frames > 1000, "the soak ran (%d frames)" % _frames)
	_ok(_ov_frames_cm == 0, "no frame with two bodies' centres closer than the sum of their body_r by more than 1 cm (%d frames)" % _ov_frames_cm)
	_ok(_ov_frames == 0, "no frame with any overlap at all (%d frames, worst %.4f m)" % [_ov_frames, _ov_worst])
	_ok(_in_obs == 0, "no body centre inside an obstacle (%d body-frames)" % _in_obs)
	_ok(_file_frames > 0, "the party walked in file in the halls (%d frames)" % _file_frames)
	print("D91_SOAK %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])

## ---------------------------------------------------------------- shot
var _cam: Camera3D
var _hall: Array = []        # [start cell, axis]
var _placed := false
var _shots := 0
var _t0 := 0.0

func _shot_init() -> void:
	var cls := ["knight", "rogue", "cleric", "barbarian", "ranger", "mage"]
	var names := ["Brannoc", "Wisp", "Odile", "Hrothga", "Fenn", "Ysmay"]
	var ids := []
	for i in 6:
		var hh: Dictionary = _r.fresh("v%d" % i, names[i], cls[i], "human")
		hh["level"] = 20
		ids.append("v%d" % i)
	_d = Delve.new()
	_d.roster = _r
	var fl := int(OS.get_environment("D91_FLOOR")) if OS.get_environment("D91_FLOOR") != "" else 2
	_d.start_floor = fl
	_d.max_floors = fl
	root.add_child(_d)
	_d.start(ids)
	_d.turn_back_at = 0.0
	for m in _d.party:
		m["max"] = float(m["max"]) * 10.0
		m["hp"] = m["max"]
	_cam = Camera3D.new()
	_cam.fov = 58.0
	root.add_child(_cam)

## the longest straight hall run: [first cell, last cell, axis]
func _find_hall() -> Array:
	var cells: Dictionary = _d.dun.info["cells"]
	var halls: Dictionary = _d.dun.info.get("halls", {})
	var best: Array = []
	var best_n := 0
	for c0 in halls:
		var c: Vector2i = c0
		for ax: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			if halls.has(c - ax):
				continue
			var side := Vector2i(ax.y, ax.x)
			# the centre lane of a three-wide band
			if not (halls.has(c + side) and halls.has(c - side)):
				continue
			var n := 0
			var p := c
			while halls.has(p) and halls.has(p + side) and halls.has(p - side):
				n += 1
				p += ax
			if n > best_n:
				best_n = n
				best = [c, p - ax, ax]
	return best

func _shot_tick(delta: float) -> bool:
	_f += 1
	if _f < 20 or _d.dun == null:
		return _f > 3000
	if not _placed:
		_hall = _find_hall()
		if _hall.is_empty():
			print("D91 shot: no straight hall on this floor")
			return true
		var a: Vector3 = _d._cell_world(_hall[0])
		var b: Vector3 = _d._cell_world(_hall[1])
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var y: float = (_d.party[0]["body"] as Node3D).global_position.y
		var i := 0
		for m in _d._alive():
			var bd: Node3D = m["body"]
			bd.global_position = Vector3(a.x, y, a.z) + dir * (2.0 + float(i) * 1.8) + side * (0.4 if i % 2 == 0 else -0.4)
			i += 1
		var k := 0
		for mon in _d._foes():
			var mn: Monster = mon
			mn.global_position = Vector3(b.x, mn.global_position.y, b.z) - dir * (float(k / 3) * 1.6) + side * (float(k % 3) - 1.0) * 2.2
			k += 1
			if k >= 6:
				break
		print("D91 shot: hall %s -> %s, %d foes moved" % [_hall[0], _hall[1], k])
		_placed = true
		_t0 = 0.0
		return false
	_t0 += delta
	var a2: Vector3 = _d._cell_world(_hall[0])
	var b2: Vector3 = _d._cell_world(_hall[1])
	var dir2 := (b2 - a2).normalized()
	var mid := Vector3.ZERO
	for m in _d._alive():
		mid += (m["body"] as Node3D).global_position
	mid /= float(maxi(1, _d._alive().size()))
	_cam.make_current()
	if _d.dun.env():
		_cam.environment = _d.dun.env()
	_cam.global_position = mid - dir2 * 9.0 + Vector3(0, 8.0, 0) + Vector3(-dir2.z, 0, dir2.x) * 2.5
	_cam.look_at(mid + dir2 * 6.0 + Vector3(0, 0.5, 0), Vector3.UP)
	for at in [1.0, 2.5, 4.0, 6.0]:
		if _shots < 4 and _t0 >= at and _shots == [1.0, 2.5, 4.0, 6.0].find(at):
			var nm := "d91_hall_%d" % _shots
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm + ".png"))
			var wst: float = _d.crowd_worst
			print("SAVED %s  state=%s foes=%d settle_worst=%.3f" % [nm, _d.state, _d._foes().size(), wst])
			_shots += 1
	return _shots >= 4 or _f > 3000

func _process(delta: float) -> bool:
	if _mode == "shot":
		return _shot_tick(delta)
	return _soak_tick(delta)
