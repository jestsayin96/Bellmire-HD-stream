extends SceneTree
## D88: THE PORTCULLIS. Three modes (env D88_MODE):
##  probe (default) - 50 floors of each theme that can spawn one (crypt, shrine, treasury). For
##     every portcullis: (a) it spans wall to wall (a line of 1-3 cells across a passage, stone at
##     both ends, floor both sides, the grid turned across the way through); raised it registers
##     no obstacle; (b) DROPPED, a body walking straight at it from either side, at every 0.2 m
##     across its width, never gets through (Delve._step, the real mover) and no route (Delve._bfs)
##     uses its cells; (c) no walkable cell within 3 m became unreachable - raised, from the entry;
##     dropped, from one side or the other. Prints D88_PROBE OK / FAIL.
##  soak - 20 game minutes of delves on gated floors with every portcullis forced to DROP
##     (Delve.force_gate_spot = 0): zero watchdog lifts and zero forced descents while a gate is
##     down or after it, zero wedged walkers (on the move, not waiting at a gate, < 0.2 m in 4 s),
##     every dropped gate resolved (wedged up or shut with a way round). Prints D88_SOAK OK / FAIL.
##  shot - windowed: a gate hanging raised over the party's way, then down with the party split,
##     then forced. Saves renders/cycles/d88/*.png.
const THEMES := ["crypt", "shrine", "treasury"]
const OUT := "res://renders/cycles/d88/"
var _fail := 0
var _checks := 0
var _mode := ""
var _f := 0

func _ok(c: bool, what: String, quiet := false) -> void:
	_checks += 1
	if not c or not quiet:
		print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	_mode = OS.get_environment("D88_MODE")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if _mode == "soak":
		_soak_init()
	elif _mode == "shot":
		_shot_init()
	elif _mode == "flow":
		_r = Roster.new()
		root.add_child(_r)

func _process(delta: float) -> bool:
	_f += 1
	if _mode == "soak":
		return _soak_tick(delta)
	if _mode == "shot":
		return _shot_tick()
	if _mode == "flow":
		if _f == 3:
			_flow()
			print("D88_FLOW %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
			return true
		return false
	if _f == 2:
		_probe()
		print("D88_PROBE %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
		return true
	return false

## ---------------------------------------------------------------- probe
func _gated_floors(per_theme: int) -> Array:
	var out: Array = []
	var got := {}
	for n in range(1, 4000):
		var th := FloorGen.theme_for(n)
		if th in THEMES and int(got.get(th, 0)) < per_theme:
			got[th] = int(got.get(th, 0)) + 1
			out.append(n)
		if out.size() >= per_theme * THEMES.size():
			break
	return out

func _probe() -> void:
	var dl := Delve.new()
	var body := Node3D.new()
	root.add_child(body)
	var stats := {"floors": 0, "gated": 0, "none": 0, "w1": 0, "w2": 0, "w3": 0, "longway": 0, "choke": 0, "on_route": 0}
	var t0 := Time.get_ticks_msec()
	for n in _gated_floors(50):
		var d := DungeonHD.new()
		d.floor_no = n
		root.add_child(d)
		stats["floors"] += 1
		var gates: Array = d.info.get("gates", [])
		if gates.is_empty():
			stats["none"] += 1
			print("  f%d %s: no passage fit for a portcullis - none placed" % [n, d.info.get("theme")])
		for g in gates:
			stats["gated"] += 1
			_check_gate(d, g, dl, body, stats)
		root.remove_child(d)
		d.free()
	body.free()
	dl.free()
	print("D88 probe: %d floors (%s), %d portcullises, %d floors with no fit spot; widths 1/2/3 cells = %d/%d/%d; on the way through %d; a long way round exists %d, a true choke %d; %.1f s" % [
		stats["floors"], "/".join(THEMES), stats["gated"], stats["none"], stats["w1"], stats["w2"], stats["w3"],
		stats["on_route"], stats["longway"], stats["choke"], float(Time.get_ticks_msec() - t0) / 1000.0])
	_ok(stats["gated"] > stats["floors"] / 2, "most crypt/shrine/treasury floors get a portcullis (%d of %d)" % [stats["gated"], stats["floors"]])

func _check_gate(d: DungeonHD, g: Dictionary, dl: Delve, body: Node3D, stats: Dictionary) -> void:
	var n := d.floor_no
	var cells: Dictionary = d.info["cells"]
	var G: float = d.info["grid"]
	var line: Array = g["cells"]
	var dv: Vector2i = g["d"]
	var p := Vector2i(dv.y, dv.x)
	var a0: Vector2i = line[0]
	var a1: Vector2i = line[-1]
	stats["w%d" % line.size()] = int(stats.get("w%d" % line.size(), 0)) + 1
	var route: Dictionary = d.info.get("keep_clear", {})
	for lc in line:
		if route.has(lc):
			stats["on_route"] += 1
			break
	# (a) wall to wall
	var walls := not cells.has(a0 - p) and not cells.has(a1 + p)
	var contig := true
	for i in range(1, line.size()):
		if line[i] != (line[i - 1] as Vector2i) + p:
			contig = false
	var sides := true
	for lc: Vector2i in line:
		if not cells.has(lc + dv) or not cells.has(lc - dv):
			sides = false
	var span := float(g["span"])
	var span_ok := line.size() <= 3 and absf(span - (float(line.size()) * G - 1.0)) < 0.01
	var node: Node3D = g["node"]
	var zax := node.global_transform.basis.z.normalized()
	var orient := absf(zax.dot(Vector3(dv.x, 0, dv.y))) > 0.99
	_ok(walls and contig and sides and span_ok and orient, "f%d %s: spans wall to wall (%d cell%s, %.1f m clear, stone both ends %s, floor both sides %s, turned across %s)" % [
		n, d.info.get("theme"), line.size(), "" if line.size() == 1 else "s", span, walls, sides, orient])
	_ok(not (d.info["obstacles"] as Array).has(g["box"]) and String(g.get("state")) == "up", "f%d raised: hangs still, registers no obstacle" % n, true)
	var grid: Node3D = node.get_node("grid")
	_ok(grid.position.y > 3.0, "f%d raised: the grid hangs up (%.2f)" % [n, grid.position.y], true)
	# the cells to watch: every floor cell within 3 m of the gate, bar its own
	var near: Array = []
	for c: Vector2i in cells:
		if line.has(c):
			continue
		var cp := d._cell_pos(c)
		if FloorGen.obst_gap(g["box"], cp.x, cp.z) <= 3.0 and d._clear_of_props(cp, 0.45):
			near.append(c)
	# (c) raised: all reachable from the entry
	d._reach = {}
	var reach := d._reachable()
	var lost := 0
	for c in near:
		if not reach.has(c):
			lost += 1
	_ok(lost == 0, "f%d raised: %d of %d walkable cells within 3 m unreachable from the entry" % [n, lost, near.size()], true)
	# (b) DROP IT (what Delve._gate_drop does to the floor)
	dl.dun = d
	(d.info["obstacles"] as Array).append(g["box"])
	var hard := {}
	for lc in line:
		hard[lc] = true
	d.info["hard"] = hard
	dl._gate_nav_changed()
	var crossed := 0
	var entered := 0
	var samples := 0
	var y0 := d.global_position.y + 0.05
	var lx := -span * 0.5
	while lx <= span * 0.5 + 0.001:
		for s in [-1.0, 1.0]:
			samples += 1
			body.global_position = dl._gate_w(g, lx, s * (G * 0.5 + 0.6), y0)
			body.set_meta("slide", 1.0)
			var to := dl._gate_w(g, lx, -s * (G * 0.5 + 0.6), y0)
			var deepest := 9.0
			for k in 240:
				dl._step(body, to, 5.0, 1.0 / 60.0)
				var l := dl._gate_l(g, body.global_position)
				deepest = minf(deepest, absf(l.y) if signf(l.y) == s else -absf(l.y))
			if deepest < 0.0:
				crossed += 1
			elif deepest < 0.45 - 0.01:
				entered += 1
		lx += 0.2
	_ok(crossed == 0 and entered == 0, "f%d dropped: %d straight walks at it (every 0.2 m across %.1f m, both ways) - %d got through, %d into the bars" % [n, samples, span, crossed, entered])
	var path: Array = dl._bfs(a0 - dv, a0 + dv)
	var through := 0
	for wp: Vector3 in path:
		if line.has(dl._cell_of(wp)):
			through += 1
	_ok(through == 0, "f%d dropped: no route uses its cells (%s)" % [n, "a long way round, %d cells" % path.size() if not path.is_empty() else "no way round - a true choke"], true)
	if path.is_empty():
		stats["choke"] += 1
	else:
		stats["longway"] += 1
	# (c) dropped: everything near it still reachable from ONE side or the other
	var A := dl._gate_flood(a0 - dv)
	var B := dl._gate_flood(a0 + dv)
	var orphan := 0
	for c in near:
		if not A.has(c) and not B.has(c):
			orphan += 1
	_ok(orphan == 0, "f%d dropped: %d walkable cells within 3 m cut off from both sides" % [n, orphan], true)
	(d.info["obstacles"] as Array).erase(g["box"])
	d.info.erase("hard")
	dl._gate_nav_changed()

## ---------------------------------------------------------------- soak
var _r: Roster
var _d: Delve
var _floors: Array = []
var _fi := 0
var _game := 0.0
const SOAK_SECS := 1200.0
var _hist := {}
var _wedged: Array = []
var _uns0 := 0
var _unsticks := 0
var _forced := 0
var _drops := 0
var _gate_uns := 0
var _seen := {}
var _unresolved: Array = []
var _story: Array = []
var _tl := {}
var _delves := 0
var _uid := 0

func _soak_init() -> void:
	Engine.time_scale = 4.0
	Delve.force_gate_spot = 0
	_r = Roster.new()
	root.add_child(_r)
	# the shallowest gated floors, so a party lives long enough to meet the gate
	_floors = _gated_floors(5)
	_floors.sort()

func _soak_next() -> void:
	if _d:
		_soak_close()
	var cls := ["knight", "rogue", "cleric", "barbarian", "ranger", "mage"]
	var ids := []
	for i in 5:
		_uid += 1
		var h: Dictionary = _r.fresh("s%d" % _uid, "Soak%d" % _uid, cls[(_uid + i) % cls.size()], "human")
		h["oil"] = 3
		h["level"] = 20
		ids.append("s%d" % _uid)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = int(_floors[_fi % _floors.size()])
	_d.max_floors = _d.start_floor + 1      # cross the gated floor to its stairs, one more below
	_fi += 1
	root.add_child(_d)
	_d.start(ids)
	_d.turn_back_at = 0.0
	for m in _d.party:              # sturdy enough to reach the gate and walk the floor
		m["max"] = float(m["max"]) * 10.0
		m["hp"] = m["max"]
	_delves += 1
	_hist.clear()

func _soak_close() -> void:
	_unsticks += _d.unsticks
	_forced += _d.forced
	for k in _d.trap_log:
		_tl[k] = float(_tl.get(k, 0.0)) + float(_d.trap_log[k])
	_story.append_array(_d.gate_story)
	root.remove_child(_d)
	_d.queue_free()
	_d = null

func _gate_active() -> bool:
	if _d == null or _d.dun == null or not is_instance_valid(_d.dun):
		return false
	for g in _d.dun.info.get("gates", []):
		if bool(g.get("done", false)) and String(g.get("state", "up")) != "up":
			return true
	return false

func _soak_tick(delta: float) -> bool:
	_game += delta
	if _d == null or _d.state == "home" or _d._alive().is_empty() or not is_instance_valid(_d.dun):
		if _game >= SOAK_SECS:
			if _d:
				_soak_close()
			_soak_report()
			return true
		_soak_next()
		return false
	# the watchdog and forced descents, attributed while a gate is down or after it
	if _gate_active() and _d.unsticks > _uns0:
		_gate_uns += _d.unsticks - _uns0
		for i in range(maxi(0, _d.unstick_log.size() - (_d.unsticks - _uns0)), _d.unstick_log.size()):
			print("  GATE UNSTICK ", _d.unstick_log[i])
	_uns0 = _d.unsticks
	# every dropped gate must come to a decision and see it through: a gate still down, being
	# forced or wound 40 s after it fell, with the party still on its floor, is a hang
	for g in _d.dun.info.get("gates", []):
		if not bool(g.get("done", false)) or String(g.get("state", "up")) == "up":
			continue
		var id: int = (g["node"] as Node).get_instance_id()
		var st := String(g["state"])
		var rec: Dictionary = _seen.get(id, {})
		if rec.is_empty():
			rec = {"since": _game, "state": st, "floor": _d.floor_no}
			_seen[id] = rec
		rec["state"] = st
		if st in ["wedged", "shut"]:
			continue
		if _game - float(rec["since"]) > 40.0 and not rec.has("hung"):
			rec["hung"] = true
			_unresolved.append("f%d %s for %.0f s" % [_d.floor_no, st, _game - float(rec["since"])])
	# wedged walkers: on the move this frame, not waiting at a gate, < 0.2 m in 4 s
	var fr := Engine.get_process_frames()
	for m in _d._alive():
		var b: Node3D = m["body"]
		var moving := int(_d.travel.get(b, -9)) >= fr - 1
		var held := int(_d.gate_held.get(b, -99)) >= fr - 2
		if not moving or held:
			_hist.erase(b)
			continue
		var hs: Array = _hist.get(b, [])
		if hs.is_empty() or b.global_position.distance_to(hs[0]) > 0.2:
			_hist[b] = [b.global_position, _game]
		elif _game - float(hs[1]) > 4.0:
			_wedged.append("f%d %s at %s (%s)" % [_d.floor_no, m["h"]["name"], b.global_position.snappedf(0.1), _d.state])
			_hist[b] = [b.global_position, _game]
	return false

func _soak_report() -> void:
	print("D88 soak: %.0f game s, %d delves, gate drops %d, splits %d, forced %d, winched %d, long way %d, stayed behind %d, heaves %d (strain %d hp), wedged-by-spotting %d" % [
		_game, _delves, int(_tl.get("gate_drops", 0)), int(_tl.get("gate_splits", 0)), int(_tl.get("gate_forced", 0)), int(_tl.get("gate_winched", 0)),
		int(_tl.get("gate_longway", 0)), int(_tl.get("gate_behind", 0)), int(_tl.get("gate_heaves", 0)), int(_tl.get("gate_strain", 0)), int(_tl.get("gate_wedged", 0))])
	print("D88 soak: watchdog lifts %d (%d while a gate was down or after), forced descents %d, wedged walkers %d" % [_unsticks, _gate_uns, _forced, _wedged.size()])
	for s in _story.slice(0, 30):
		print("  story: ", s)
	for w in _wedged.slice(0, 20):
		print("  WEDGED ", w)
	_ok(int(_tl.get("gate_drops", 0)) >= 5, "the soak dropped portcullises (%d)" % int(_tl.get("gate_drops", 0)))
	_ok(_gate_uns == 0, "zero watchdog lifts while a gate was down or after (%d)" % _gate_uns)
	_ok(_wedged.is_empty(), "zero wedged walkers (%d)" % _wedged.size())
	var fin := 0
	var mid := 0
	for id in _seen:
		if String(_seen[id]["state"]) in ["wedged", "shut"]:
			fin += 1
		else:
			mid += 1
	_ok(_unresolved.is_empty(), "no gate hung mid-choice (%d of %d dropped/spotted gates ended wedged up or shut, %d were mid-choice when the party left the floor; hung: %s)" % [fin, _seen.size(), mid, ", ".join(_unresolved)])
	print("D88_SOAK %s (%d checks, %d failed; forced descents %d reported, not gated)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail, _forced])

## ---------------------------------------------------------------- shot
var _cam: Camera3D
var _g: Dictionary
var _step_i := 0

func _shot_init() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	var cls := ["knight", "rogue", "cleric", "barbarian"]
	for i in 4:
		var h: Dictionary = _r.fresh("v%d" % i, ["Brannoc", "Wisp", "Odile", "Hrothga"][i], cls[i], "human")
		ids.append("v%d" % i)
	_d = Delve.new()
	_d.roster = _r
	# floor 13 (crypt): a one-cell choke with no winch, so the party has to force it
	var fl := int(OS.get_environment("D88_FLOOR")) if OS.get_environment("D88_FLOOR") != "" else 13
	_d.start_floor = fl
	_d.max_floors = fl
	root.add_child(_d)
	_d.start(ids)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	root.add_child(_cam)
	print("D88 shot floor ", fl)

func _shot_place(lz_base: float) -> void:
	var i := 0
	for m in _d._alive():
		var b: Node3D = m["body"]
		var lx := (float(i % 2) - 0.5) * 1.4
		b.global_position = _d._gate_w(_g, lx, lz_base - float(i / 2) * 1.6 - float(i % 2) * 0.4, b.global_position.y)
		b.look_at(_d._gate_w(_g, lx, 6.0, b.global_position.y), Vector3.UP, true)
		i += 1

func _shot_cam() -> void:
	var G: float = _d.dun.info["grid"]
	var y := _d.dun.global_position.y
	_cam.make_current()
	if _d.dun.env():
		_cam.environment = _d.dun.env()
	_cam.global_position = _d._gate_w(_g, 0.6, -G * 2.2, y + 6.5)
	_cam.look_at(_d._gate_w(_g, 0.0, 0.8, y + 1.4), Vector3.UP)

func _snap(nm: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm + ".png"))
	print("SAVED ", nm)

func _shot_tick() -> bool:
	if _f < 30 or _d.dun == null:
		return _f > 4000
	if _g.is_empty():
		_g = (_d.dun.info.get("gates", []) as Array)[0]
		_d.set_process(false)
		for f in _d._foes():
			(f as Node3D).visible = false
			(f as Node3D).set_process(false)
		_shot_place(-2.0)
		_shot_cam()
		_step_i = _f
	var k := _f - _step_i
	if k == 40:
		_snap("d88_1_raised")
		_shot_place(-1.0)
		var lead: Dictionary = _d._alive()[0]
		(lead["body"] as Node3D).global_position = _d._gate_w(_g, 0.0, -0.3, (lead["body"] as Node3D).global_position.y)
		_d._meet_gate(lead, _g, 0)
	if k == 80:
		_snap("d88_2_dropped")
		print("D88 shot story: ", _d.gate_story)
		# the other side of the bars
		var G: float = _d.dun.info["grid"]
		var y := _d.dun.global_position.y
		_cam.global_position = _d._gate_w(_g, -0.6, G * 2.2, y + 6.5)
		_cam.look_at(_d._gate_w(_g, 0.0, -0.8, y + 1.4), Vector3.UP)
	if k == 110:
		_snap("d88_3_other_side")
		_shot_cam()
		_d._gt += 10.0
		_d._gates_tick()
		for i in 10:
			if String(_g["state"]) == "forcing":
				_d._gt += 3.0
				_d._gates_tick()
		print("D88 shot: gate state after the choice: ", _g["state"], " ", _d.gate_story)
	if k == 200:
		_snap("d88_4_after")
		return true
	return false

## ---------------------------------------------------------------- flow
## The trap itself, on real delves with the creatures cleared away: spotted -> wedged and nothing
## blocks; dropped on a choke -> the party is split by name and the strongest body forces it
## (each heave costs strain) until it is up, after which a route runs through it again; dropped
## where the floor still joins up -> the long way round, the gate stays a wall.
func _flow() -> void:
	var dl := Delve.new()
	var chokes: Array = []
	var loops: Array = []
	for n in _gated_floors(12):
		var pr := DungeonHD.new()
		pr.floor_no = n
		root.add_child(pr)
		var gs: Array = pr.info.get("gates", [])
		if not gs.is_empty():
			var g: Dictionary = gs[0]
			dl.dun = pr
			var hard := {}
			for lc in g["cells"]:
				hard[lc] = true
			pr.info["hard"] = hard
			var dv: Vector2i = g["d"]
			var a0: Vector2i = (g["cells"] as Array)[0]
			(chokes if not dl._gate_flood(a0 - dv).has(a0 + dv) else loops).append([n, int(g.get("winch", 0))])
		root.remove_child(pr)
		pr.free()
	dl.free()
	print("D88 flow: choke floors ", chokes, " loop floors ", loops)
	var trials: Array = []
	for c in chokes:
		if int(c[1]) == 0 and trials.size() < 6:
			trials.append([int(c[0]), "choke"])
	if not loops.is_empty():
		trials.append([int(loops[0][0]), "loop"])
	trials.append([int(chokes[0][0]) if not chokes.is_empty() else int(loops[0][0]), "spot"])
	var forced_seen := 0
	for t in trials:
		_flow_trial(int(t[0]), String(t[1]))
		if String(t[1]) == "choke" and _last_forced:
			forced_seen += 1
	_ok(forced_seen > 0, "the force branch ran on a real delve (%d trials)" % forced_seen)

var _last_forced := false
func _flow_trial(n: int, kind: String) -> void:
	_last_forced = false
	var ids := []
	var cls := ["cleric", "rogue", "barbarian", "mage"]
	for i in 4:
		_uid += 1
		_r.fresh("f%d" % _uid, ["Odile", "Wisp", "Hrothga", "Ysmay"][i] + str(_uid), cls[i], "human")
		ids.append("f%d" % _uid)
	var d := Delve.new()
	d.roster = _r
	d.start_floor = n
	d.max_floors = n
	root.add_child(d)
	d.start(ids)
	d.set_process(false)
	for mon in d.dun.monsters:
		if is_instance_valid(mon):
			(mon as Node).queue_free()
	d.dun.monsters.clear()
	if d.dun.lord:
		d.dun.lord.queue_free()
		d.dun.lord = null
	var g: Dictionary = (d.dun.info["gates"] as Array)[0]
	var G: float = d.dun.info["grid"]
	var y := d.dun.global_position.y + 0.05
	var al := d._alive()
	# the party walks up to it from the entry's side, the leader on the line
	var ent: Vector3 = d.dun.info["entry"] + d.dun.global_position
	var near := signf(d._gate_l(g, ent).y)
	if near == 0.0:
		near = -1.0
	for i in al.size():
		(al[i]["body"] as Node3D).global_position = d._gate_w(g, 0.0, near * (0.3 if i == 0 else G * 0.5 + 0.8 + float(i)), y)
	var lead: Dictionary = al[0]
	var obs: Array = d.dun.info["obstacles"]
	if kind == "spot":
		d._meet_gate(lead, g, 1)
		_ok(String(g["state"]) == "wedged" and not obs.has(g["box"]) and (d.dun.info.get("hard", {}) as Dictionary).is_empty(),
			"f%d spotted: wedged open, nothing blocks (%s)" % [n, g["state"]])
		d.queue_free()
		return
	var hp0 := 0.0
	for m in al:
		hp0 += float(m["hp"])
	d._meet_gate(lead, g, 0)
	var off := true
	for m in al:
		if (g["cells"] as Array).has(d._cell_of((m["body"] as Node3D).global_position)):
			off = false
	_ok(String(g["state"]) == "down" and obs.has(g["box"]) and off, "f%d dropped: down, a wall-to-wall box, nobody left standing in its cells" % n)
	var crossed := signf(d._gate_l(g, (lead["body"] as Node3D).global_position).y) != near
	var dove := int(d.trap_log["saved"]) > 0
	_ok(crossed == dove, "f%d the crosser %s and ended on the %s side" % [n, "dove clear" if dove else "took the fall", "far" if crossed else "near"])
	var story := " / ".join(d.gate_story)
	if dove:
		_ok(story.contains(String(lead["h"]["name"])) and story.contains(String(al[1]["h"]["name"])), "f%d the split names who is where: %s" % [n, story])
	var picks: Array = []
	for i in 30:
		d._gt += 1.0
		d._gates_tick()
		if not picks.has(String(g["state"])):
			picks.append(String(g["state"]))
		if String(g["state"]) in ["wedged", "shut"]:
			break
	var st := String(g["state"])
	var dv: Vector2i = g["d"]
	var a0: Vector2i = (g["cells"] as Array)[0]
	var path: Array = d._bfs(a0 - dv, a0 + dv)
	var uses := false
	for wp: Vector3 in path:
		if (g["cells"] as Array).has(d._cell_of(wp)):
			uses = true
	print("  f%d %s: %s -> %s; %s" % [n, kind, " -> ".join(picks), st, " / ".join(d.gate_story)])
	if kind == "loop":
		_ok(st == "shut" and obs.has(g["box"]) and not path.is_empty() and not uses, "f%d a way round exists: the gate stays a wall and the route goes round (%d cells)" % [n, path.size()])
	else:
		if st == "wedged":
			_last_forced = int(d.trap_log.get("gate_forced", 0)) > 0
			var spent := hp0
			for m in al:
				spent -= float(m["hp"])
			_ok(_last_forced and not obs.has(g["box"]) and uses and int(d.trap_log.get("gate_heaves", 0)) >= 1,
				"f%d no way round: forced in %d heave(s) for %.0f strain (%.0f hp off the party), and the route runs through it again" % [n, int(d.trap_log.get("gate_heaves", 0)), float(d.trap_log.get("gate_strain", 0.0)), spent])
		else:
			_ok(st == "shut" and int(d.trap_log.get("gate_behind", 0)) == 1, "f%d no way round but nobody needs one (all on the stairs' side): it stays down behind them" % n)
	d.queue_free()
