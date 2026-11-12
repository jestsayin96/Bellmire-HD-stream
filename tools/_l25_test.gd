extends SceneTree
## L25: the dungeon's geometry (Mr. E: "looks like shit - stairs, objects clipping, people get
## stuck"). Prints L25_TEST OK / FAIL.
##  1. OVERLAP PROBE over 10 generated floors (1-10): every placed piece's real footprint (an
##     oriented box from its own meshes, FloorGen._box_of) against every other. 0 prop-prop and
##     0 prop-wall interpenetration deeper than 0.2 m (props = furniture, clusters, growth,
##     banners, columns, the stairs); nothing that stands on the floor sunk into it.
##  2. STAIRS: two flights a floor, each resting on the floor, its high end flush on a wall
##     (a gap under 0.1 m, not into it more than 0.2 m), inside its cell between the side walls,
##     one continuous flight (one piece, the steps rising to the wall).
##  3. A 10-FLOOR RUN: four delvers from floor 1 to 10; nobody on the move for 2 s without
##     getting 0.2 m anywhere (stuck), and no descent forced because someone never reached the
##     stairs. (L25_PROBE_ONLY=1 skips 3.)
var _t: Node3D
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _hist := {}            # body -> [pos, since]
var _stuck: Array = []
var _floors_seen := {}
const PEN := 0.2
const PROPS := ["prop", "scatter", "banner", "struct", "stairs"]

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	if OS.get_environment("L25_NO_FIT") == "1":
		FloorGen.fit_checks = false       # the "before": the same floors with no fit checks
	_probe()
	if OS.get_environment("L25_PROBE_ONLY") == "1":
		_end()
		return
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

## every tagged piece a floor placed
func _pieces(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Node3D and c.has_meta("fg_kind"):
			out.append(c)
		else:
			_pieces(c, out)

func _probe() -> void:
	print("== 1-2. overlap probe, stairs, reachability, floors 1-12")
	var host := Node3D.new()
	root.add_child(host)
	var pp: Array = []
	var pw: Array = []
	var sunk: Array = []
	var stairs_bad: Array = []
	var void_: Array = []
	var n_props := 0
	var rejected := 0
	var unreach: Array = []
	var blockers: Array = []
	var landings: Array = []
	for fl in range(1, 13):
		var info := FloorGen.build(host, fl, Vector3(0, -200.0 * fl, 0))
		rejected += int(info.get("rejected", 0))
		var ps: Array = []
		_pieces(info["root"], ps)
		var boxes: Array = []
		for n: Node3D in ps:
			var kind := String(n.get_meta("fg_kind"))
			if kind in ["floor", "torch", ""]:
				continue
			var b := FloorGen._box_of(n, String(n.get_meta("fg_asset")))
			b["kind"] = kind
			b["grp"] = int(n.get_meta("fg_grp"))
			boxes.append(b)
			if kind in PROPS:
				n_props += 1
				var hv: Vector2 = info["half"]
				var cell := Vector2i(roundi((n.position.x + hv.x) / FloorGen.G), roundi((n.position.z + hv.y) / FloorGen.G))
				if not (info["cells"] as Dictionary).has(cell) and kind != "stairs":
					void_.append("f%d %s" % [fl, n.get_meta("fg_asset")])
			if kind in ["prop", "scatter", "struct", "stairs"] and float(b["y0"]) < -0.05:
				sunk.append("f%d %s %.2f" % [fl, b["asset"], float(b["y0"])])
		for i in boxes.size():
			var a: Dictionary = boxes[i]
			if not (String(a["kind"]) in PROPS):
				continue
			for j in boxes.size():
				if j == i:
					continue
				var b: Dictionary = boxes[j]
				var p := FloorGen.pen(a, b)
				if p <= PEN:
					continue
				if String(b["kind"]) == "wall":
					pw.append("f%d %s into wall %.2f" % [fl, a["asset"], p])
				elif String(b["kind"]) in PROPS and j > i:
					pp.append("f%d %s x %s %.2f" % [fl, a["asset"], b["asset"], p])
		# L25d: every cell reachable from the entry; L25b: no prop on a doorway / corridor cell or the
		# entry-to-exit route; L25a: each flight's foot lands on open floor
		var cells: Dictionary = info["cells"]
		var hv2: Vector2 = info["half"]
		var to_cell := func(p: Vector3) -> Vector2i: return Vector2i(roundi((p.x + hv2.x) / FloorGen.G), roundi((p.z + hv2.y) / FloorGen.G))
		var cen := func(c: Vector2i) -> Vector2: return Vector2(float(c.x) * FloorGen.G - hv2.x, float(c.y) * FloorGen.G - hv2.y)
		var start: Vector2i = to_cell.call(Vector3((info["entry"] as Vector3).x, 0, (info["entry"] as Vector3).z))
		var goal: Vector2i = to_cell.call(Vector3((info["exit"] as Vector3).x, 0, (info["exit"] as Vector3).z))
		var prev := {start: start}
		var q: Array = [start]
		while not q.is_empty():
			var c: Vector2i = q.pop_front()
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nb: Vector2i = c + dv
				if cells.has(nb) and not prev.has(nb):
					prev[nb] = c
					q.append(nb)
		if prev.size() != cells.size():
			unreach.append("f%d: %d of %d cells reachable" % [fl, prev.size(), cells.size()])
		# the route the floor keeps clear (the way from stair to stair, round the lamp) and the corridors
		var keep_clear := {}
		for c: Vector2i in cells:
			if FloorGen._is_corridor(cells, c):
				keep_clear[c] = "corridor"
		for c: Vector2i in (info.get("keep_clear", {}) as Dictionary):
			keep_clear[c] = "route" if not keep_clear.has(c) else keep_clear[c]
		_ok_route(info, keep_clear, fl)
		for b: Dictionary in boxes:
			if not (String(b["kind"]) in ["prop", "scatter", "banner"]):
				continue
			for c: Vector2i in keep_clear:
				var pt := {"o": cen.call(c), "ux": Vector2(1, 0), "uz": Vector2(0, 1), "hx": 0.45, "hz": 0.45, "y0": 0.0, "y1": 1.8}
				if FloorGen.pen(b, pt) > 0.05:
					blockers.append("f%d %s on a %s cell" % [fl, b["asset"], keep_clear[c]])
					break
		# the stairs
		var flights: Array = boxes.filter(func(b): return String(b["kind"]) == "stairs")
		if flights.size() != 2:
			stairs_bad.append("f%d: %d flights" % [fl, flights.size()])
		for s: Dictionary in flights:
			var n: Node3D = s["node"]
			var into := 0.0
			var gap := 99.0
			for b: Dictionary in boxes:
				if String(b["kind"]) != "wall":
					continue
				into = maxf(into, FloorGen.pen(s, b))
				gap = minf(gap, _sep(s, b))
			var rests := absf(float(s["y0"])) < 0.05
			# the steps rise toward the wall: the high end (local z = 0) is the end nearest a wall
			var hi := Vector2(n.position.x, n.position.z)
			var lo := hi + Vector2(sin(n.rotation.y), cos(n.rotation.y)) * 4.0 * n.scale.x
			var near_hi := 99.0
			var near_lo := 99.0
			for b: Dictionary in boxes:
				if String(b["kind"]) == "wall":
					near_hi = minf(near_hi, (b["o"] as Vector2).distance_to(hi))
					near_lo = minf(near_lo, (b["o"] as Vector2).distance_to(lo))
			var foot := Vector3(lo.x, 0, lo.y) + Vector3(sin(n.rotation.y), 0, cos(n.rotation.y)) * 0.6
			var fc: Vector2i = to_cell.call(foot)
			var clear := cells.has(fc)
			var fpt := {"o": Vector2(foot.x, foot.z), "ux": Vector2(1, 0), "uz": Vector2(0, 1), "hx": 0.35, "hz": 0.35, "y0": 0.0, "y1": 1.8}
			for b: Dictionary in boxes:
				if String(b["kind"]) in ["prop", "scatter", "struct"] and FloorGen.pen(b, fpt) > 0.05:
					clear = false
			if not clear:
				landings.append("f%d %s foot at %s" % [fl, s["asset"], foot.snappedf(0.1)])
			if not rests or into > PEN or gap > 0.1 or near_hi > near_lo:
				stairs_bad.append("f%d %s rests %s, into wall %.2f, gap %.2f, high end to a wall %.1f / foot %.1f" % [fl, s["asset"], rests, into, gap, near_hi, near_lo])
		info["root"].queue_free()
	print("  %d props placed over 10 floors; %d pieces left out because they did not fit" % [n_props, rejected])
	_ok(pp.is_empty(), "0 prop-prop interpenetration > %.1f m over 12 floors (%d: %s)" % [PEN, pp.size(), pp.slice(0, 6)])
	_ok(pw.is_empty(), "0 prop-wall interpenetration > %.1f m over 12 floors (%d: %s)" % [PEN, pw.size(), pw.slice(0, 6)])
	_ok(unreach.is_empty(), "every room is reachable from the entrance on 12 floors (%s)" % [unreach])
	_ok(blockers.is_empty(), "0 props blocking a doorway, a corridor or the entry-to-exit route (%d: %s)" % [blockers.size(), blockers.slice(0, 6)])
	_ok(_route_bad.is_empty(), "the kept-clear way runs unbroken from the entry stairs to the exit stairs on 12 floors (broken: %s)" % [_route_bad])
	_ok(landings.is_empty(), "every flight lands on open floor at its foot (%s)" % [landings.slice(0, 6)])
	_ok(void_.is_empty(), "nothing is placed off the floor, in the void (%d: %s)" % [void_.size(), void_.slice(0, 6)])
	_ok(sunk.is_empty(), "nothing that stands on the floor is sunk into it (%d: %s)" % [sunk.size(), sunk.slice(0, 6)])
	_ok(stairs_bad.is_empty(), "two flights a floor, each on the floor, its high end flush on a wall, inside its cell (%s)" % [stairs_bad.slice(0, 6)])
	host.queue_free()

## the gap between two footprints (negative = overlapping): the largest separation on any axis
static func _sep(a: Dictionary, b: Dictionary) -> float:
	var d: Vector2 = b["o"] - a["o"]
	var best := -99.0
	for ax: Vector2 in [a["ux"], a["uz"], b["ux"], b["uz"]]:
		var ra := float(a["hx"]) * absf((a["ux"] as Vector2).dot(ax)) + float(a["hz"]) * absf((a["uz"] as Vector2).dot(ax))
		var rb := float(b["hx"]) * absf((b["ux"] as Vector2).dot(ax)) + float(b["hz"]) * absf((b["uz"] as Vector2).dot(ax))
		best = maxf(best, absf(d.dot(ax)) - ra - rb)
	return best

## ---------------------------------------------------------------- 3. the run
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		print("== 3. a 10-floor run")
		var r: Roster = _t.get("roster")
		var ids := ["2501", "2502", "2503", "2504"]
		for v in [[ids[0], "Ash", "knight"], [ids[1], "Bree", "ranger"], [ids[2], "Cole", "barbarian"], [ids[3], "Dawn", "cleric"]]:
			var h: Dictionary = r.get_hero(v[0])
			if h.is_empty():
				h = r.fresh(v[0], v[1], v[2])
			h["alive"] = true
			h["weapon"] = 4
			h["armour"] = 4
			h["level"] = 12
			h["oil"] = 20
			h["potions"] = 20
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 1
		_d.max_floors = 10
		_t.add_child(_d)
		_d.start(ids)
		Engine.time_scale = 4.0
	if _d == null:
		return false
	_floors_seen[_d.floor_no] = true
	var now := float(Time.get_ticks_msec()) / 1000.0 * Engine.time_scale     # sim seconds
	var fr := Engine.get_process_frames()
	for m in _d.party:
		var b = m.get("body")
		if not is_instance_valid(b) or float(m["hp"]) <= 0.0:
			continue
		var moving := int(_d.travel.get(b, -10)) >= fr - 1
		var p: Vector3 = (b as Node3D).global_position
		var hst: Array = _hist.get(b, [])
		if not moving or hst.is_empty() or p.distance_to(hst[0]) > 0.2 or absf(p.y - (hst[0] as Vector3).y) > 5.0:
			_hist[b] = [p, now]
		elif now - float(hst[1]) > 2.0:
			_stuck.append("floor %d %s at %s (%s)" % [_d.floor_no, m["h"]["name"], p.snappedf(0.1), _d.state])
			_hist[b] = [p, now]
	if _d.state == "home" or _f > 60000:
		Engine.time_scale = 1.0
		_ok(_floors_seen.size() >= 10 or _d.floor_no >= 10, "the run reached floor 10 (floors seen %s)" % [_floors_seen.keys()])
		var by := {}
		for s in _stuck:
			var k := String(s).get_slice(" at ", 0).get_slice(" ", 1) + " " + String(s).get_slice("(", 2).trim_suffix(")")
			by[k] = int(by.get(k, 0)) + 1
		print("  stuck by floor / state: ", by)
		_ok(_stuck.is_empty(), "0 stuck delvers in the run (%d: %s)" % [_stuck.size(), _stuck.slice(0, 6)])
		for u in _d.unstick_log: print("  nudge ", u)
		_ok(_d.unsticks <= 10, "the watchdog had to set a stuck delver free at most once a floor (%d times in 10 floors)" % _d.unsticks)
		_ok(_d.forced == 0, "no descent forced because someone never reached the stairs (%d)" % _d.forced)
		_end()
		return true
	return false

func _end() -> void:
	print("L25_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
	if OS.get_environment("L25_PROBE_ONLY") == "1":
		quit()

## the kept-clear route really joins the two stairs (cell to neighbouring cell)
var _route_bad: Array = []
func _ok_route(info: Dictionary, kc: Dictionary, fl: int) -> void:
	var route: Dictionary = info.get("keep_clear", {})
	var hv: Vector2 = info["half"]
	var a := Vector2i(roundi(((info["entry"] as Vector3).x + hv.x) / FloorGen.G), roundi(((info["entry"] as Vector3).z + hv.y) / FloorGen.G))
	var b := Vector2i(roundi(((info["exit"] as Vector3).x + hv.x) / FloorGen.G), roundi(((info["exit"] as Vector3).z + hv.y) / FloorGen.G))
	var seen := {a: true}
	var q: Array = [a]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dv
			if (route.has(n) or n == b) and not seen.has(n):
				seen[n] = true
				q.append(n)
	if not seen.has(b):
		_route_bad.append("f%d" % fl)
