extends SceneTree
## D83: THE TRAPS ARE STUCK. MEASURE FIRST. Two modes (env D83_MODE):
##  fire (default) - a REAL delve (Delve.start, the real floor, the real party). On the floor it
##     lays one of every trap kind in Delve.TRAPS (the portcullis is D88's and has its own probe;
##     here only its drop/raise is checked for leftovers) right where the lead delver stands and
##     SPRINGS IT TWICE, the second time while the first animation is still running. Then:
##       - every creature the trap let up must MOVE within 20 s (logged every second, floor-relative
##         height too: a creature 400 m above its floor or sunk into the stone is "stuck" as well);
##       - the trap node carries the same nodes after as before (no orphaned darts);
##       - the spikes / plate / blade / boards / jet are back at their ARMED state.
##     The swarm is sprung in all three states a floor can be in when a delver steps on it
##     (fight, search, descend) - the walk to the stairs is where most of a floor is crossed.
##     Prints D83_FIRE OK / FAIL.
##  shot - windowed: a swarm grate sprung on the WALK TO THE STAIRS (the case that was broken),
##     the creatures on the stone, the party turned back to fight them, and the walk resumed.
##     Saves renders/cycles/d83/*.png.
##  soak - 10 game minutes of real delves (time_scale 4). For every floor: the node count under
##     its traps when it is built and when it is left must match, and no Monster under the floor
##     is missing from dun.monsters (an orphan nobody fights). Prints D83_SOAK OK / FAIL.
const SOAK_SECS := 600.0
var _mode := ""
var _f := 0
var _fail := 0
var _checks := 0
var _r: Roster
var _d: Delve
var _uid := 0
var _sprung := 0
var _swarms := 0
var _rejoins := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

static func count_nodes(n: Node) -> int:
	var k := 1
	for c in n.get_children():
		k += count_nodes(c)
	return k

func _initialize() -> void:
	_mode = OS.get_environment("D83_MODE")
	_r = Roster.new()
	root.add_child(_r)
	if _mode == "soak":
		Engine.time_scale = 4.0
		Delve.force_trap_spot = 0          # every ordinary trap is missed: they all spring

func _new_delve(floor_n: int) -> void:
	if _d:
		_sprung += int(_d.trap_log.get("sprung", 0))
		_swarms += int(_d.trap_log.get("swarms", 0))
		_rejoins += _d.rejoined
		root.remove_child(_d)
		_d.queue_free()
	var cls := ["knight", "rogue", "cleric"]
	var ids := []
	for i in 3:
		_uid += 1
		var h: Dictionary = _r.fresh("t%d" % _uid, "Trap%d" % _uid, cls[i], "human")
		h["oil"] = 3
		h["level"] = 12
		ids.append("t%d" % _uid)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = floor_n
	_d.max_floors = floor_n + 3
	root.add_child(_d)
	_d.start(ids)
	_d.turn_back_at = 0.0
	for m in _d.party:
		m["max"] = float(m["max"]) * 20.0
		m["hp"] = m["max"]

func _process(delta: float) -> bool:
	_f += 1
	if _mode == "soak":
		return _soak_tick(delta)
	if _mode == "shot":
		return _shot_tick(delta)
	return _fire_tick(delta)

## ---------------------------------------------------------------- fire
var _queue: Array = []        # [kind, ctx]
var _cur := {}                # the trial in progress
var _tt := 0.0

func _factory(kind: String) -> Node3D:
	match kind:
		"SpikeTrap": return DungeonParts.spike_trap()
		"PressurePlate": return DungeonParts.pressure_plate()
		"FireTrap": return DungeonParts.fire_trap()
		"DartTrap": return DungeonParts.dart_trap()
		"BladeTrap": return DungeonParts.blade_trap()
		"PitTrap": return DungeonParts.pit_trap()
		"PoisonDart": return DungeonParts.poison_dart()
		"SwarmTrap": return DungeonParts.swarm_trap()
		"Portcullis": return DungeonParts.portcullis(3.0, 4.0, 1)
	return null

## the transforms that make a trap "armed": every one must be back here once it has finished
func _pose(n: Node3D) -> Array:
	var out: Array = []
	var st: Array = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is Node3D and c != n:
			out.append([String(n.get_path_to(c)), (c as Node3D).position, (c as Node3D).rotation])
		if c is GPUParticles3D:
			out.append([String(n.get_path_to(c)) + ":emit", (c as GPUParticles3D).emitting, false])
		for g in c.get_children():
			st.append(g)
	return out

func _fire_tick(delta: float) -> bool:
	if _f == 2:
		for k in Delve.TRAPS:
			_queue.append([String(k), "fight"])
		_queue.append(["SwarmTrap", "search"])
		_queue.append(["SwarmTrap", "descend"])
		_queue.append(["SwarmTrap", "fight"])
		return false
	if _f < 2:
		return false
	if _cur.is_empty():
		if _queue.is_empty():
			print("D83_FIRE %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
			return true
		var q: Array = _queue.pop_front()
		_new_delve(4)
		_cur = {"kind": q[0], "ctx": q[1], "phase": "wait"}
		_tt = 0.0
		return false
	_tt += delta
	match String(_cur["phase"]):
		"wait":
			if _d.dun != null and is_instance_valid(_d.dun) and _d.state == "fight" and _f > 4:
				_lay()
		"fired":
			_watch()
		"done":
			_cur = {}
	return false

func _lay() -> void:
	var kind := String(_cur["kind"])
	var m: Dictionary = _d._alive()[0]
	var b: Node3D = m["body"]
	var rootn: Node3D = _d.dun.info["root"]
	var tn := _factory(kind)
	tn.position = rootn.to_local(b.global_position) * Vector3(1, 0, 1) + Vector3(0, 0.05, 0)
	rootn.add_child(tn)
	_cur["node"] = tn
	_cur["pre_nodes"] = count_nodes(tn)
	_cur["pre_pose"] = _pose(tn)
	_cur["mons_before"] = (_d.dun.monsters as Array).duplicate()
	_d.state = String(_cur["ctx"])
	if _cur["ctx"] == "descend":
		_d._t = 0.0
	if kind == "Portcullis":
		(tn.get_meta("drop") as Callable).call()
		_cur["t_second"] = 0.2
	else:
		var tr := {"node": tn, "kind": kind, "done": true}
		_cur["tr"] = tr
		_d._spring(m, tr, Delve.TRAPS[kind], _d.trap_dc())
	_cur["phase"] = "fired"
	_cur["t0"] = _tt
	_cur["fired2"] = false
	_cur["track"] = {}
	_cur["last_s"] = -1

func _watch() -> void:
	var kind := String(_cur["kind"])
	var tn: Node3D = _cur["node"]
	var since := _tt - float(_cur["t0"])
	# the second firing lands mid-animation of the first
	if not bool(_cur["fired2"]) and since >= 0.2:
		_cur["fired2"] = true
		if kind == "Portcullis":
			(tn.get_meta("raise") as Callable).call(0.8)
		elif _d._alive().size() > 0:
			_d._spring(_d._alive()[0], _cur["tr"], Delve.TRAPS[kind], _d.trap_dc())
	# log every creature the trap let up, once a second
	var s := int(since)
	if s != int(_cur["last_s"]):
		_cur["last_s"] = s
		var before: Array = _cur["mons_before"]
		if _d.dun != null and is_instance_valid(_d.dun):
			for mon in _d.dun.monsters:
				if before.has(mon) or not is_instance_valid(mon):
					continue
				var M: Monster = mon
				var tr2: Dictionary = _cur["track"]
				var key := M.get_instance_id()      # never key on a node that may be freed
				if not tr2.has(key):
					tr2[key] = {"name": String(M.def.get("name", "?")), "p": []}
				var fy := M.global_position.y - _d.dun.global_position.y
				var near := 1e9
				for pm in _d._alive():
					near = minf(near, (pm["body"] as Node3D).global_position.distance_to(M.global_position))
				(tr2[key]["p"] as Array).append([s, M.global_position, fy, M.state, M.hp, near])
	var done_t := 20.5 if kind == "SwarmTrap" else 4.0
	if since < done_t and _d.dun != null and is_instance_valid(_d.dun):
		return
	_cur["phase"] = "done"          # an error inside the report must not re-run it every frame
	_report()
	_cur = {}

func _report() -> void:
	var kind := String(_cur["kind"])
	var ctx := String(_cur["ctx"])
	var tag := "%s/%s" % [kind, ctx]
	var tn: Node3D = _cur["node"]
	if not is_instance_valid(tn):
		_ok(false, "%s: the trap node itself is gone (the floor was left before the trial finished)" % tag)
		return
	var now := count_nodes(tn)
	_ok(now == int(_cur["pre_nodes"]), "%s: trap carries %d nodes after two firings, %d before (no orphans)" % [tag, now, int(_cur["pre_nodes"])])
	var pre: Array = _cur["pre_pose"]
	var post := _pose(tn)
	var moved: Array = []
	var pmap := {}
	for e in post:
		pmap[e[0]] = e
	for e in pre:
		var a: Array = e
		if not pmap.has(a[0]):
			continue
		var bb: Array = pmap[a[0]]
		if a[1] is Vector3:
			if (a[1] as Vector3).distance_to(bb[1]) > 0.01 or (a[2] as Vector3).distance_to(bb[2]) > 0.01:
				moved.append("%s %s->%s" % [a[0], a[1], bb[1]])
		elif a[1] != bb[1]:
			moved.append("%s %s->%s" % [a[0], a[1], bb[1]])
	if kind == "Portcullis":
		print("    (portcullis: dropped then raised - wheel turns are cumulative, pose is D88's to test)")
	elif kind == "SwarmTrap":
		print("    (swarm grate after springing: %d bars down - sprung grates stay open by design)" % moved.size())
	else:
		_ok(moved.is_empty(), "%s: back to ARMED pose after two firings%s" % [tag, "" if moved.is_empty() else " - NOT: " + ", ".join(moved.slice(0, 4))])
	if kind != "SwarmTrap":
		return
	var tr2: Dictionary = _cur["track"]
	if ctx != "fight":
		_ok(_d.rejoined >= 1, "%s: the party turned to fight what came up (rejoined %d)" % [tag, _d.rejoined])
	_ok(tr2.size() >= 2, "%s: the grate let creatures up (%d)" % [tag, tr2.size()])
	for rec_v in tr2.values():
		var rec: Dictionary = rec_v
		var ps: Array = rec["p"]
		var p0: Vector3 = ps[0][1]
		var far := 0.0
		var ymin := 1e9
		var ymax := -1e9
		var dead := false
		for e in ps:
			far = maxf(far, Vector2(p0.x - (e[1] as Vector3).x, p0.z - (e[1] as Vector3).z).length())
			if int(e[3]) == Monster.S.DEAD:
				dead = true            # a dead creature sinks into the stone on purpose
				continue
			ymin = minf(ymin, float(e[2]))
			ymax = maxf(ymax, float(e[2]))
		if ymin > ymax:
			ymin = 0.0
			ymax = 0.0
		var line := ""
		for e in ps:
			line += " %ds:(%.1f,%.1f) y%+.2f st%d" % [int(e[0]), (e[1] as Vector3).x, (e[1] as Vector3).z, float(e[2]), int(e[3])]
		print("    %s:%s" % [rec["name"], line])
		var engaged := float(ps[ps.size() - 1][5]) < 2.6
		_ok(far > 0.3 or dead or engaged, "%s: %s moved %.2f m in 20 s%s" % [tag, rec["name"], far, " (killed)" if dead else (" (toe to toe with a delver)" if engaged else "")])
		_ok(ymin > -0.3 and ymax < 1.5 + 3.0, "%s: %s stays on its floor (height above floor %.2f..%.2f m)" % [tag, rec["name"], ymin, ymax])

## ---------------------------------------------------------------- soak
var _game := 0.0
var _floor_rec := {}          # current dun -> {start, last}
var _cur_dun: DungeonHD = null
var _cur_key := ""
var _floors := 0
var _bad_floors := 0
var _orphans := 0

func _trap_nodes(dun: DungeonHD) -> int:
	var k := 0
	for t in dun.info.get("traps", []):
		if is_instance_valid(t["node"]):
			k += count_nodes(t["node"])
	return k

func _orphan_monsters(dun: DungeonHD) -> int:
	var k := 0
	var st: Array = [dun]
	while not st.is_empty():
		var c: Node = st.pop_back()
		if c is Monster and c != dun.lord and not (dun.monsters as Array).has(c):
			k += 1
		for g in c.get_children():
			if not g is Monster:
				st.append(g)
			elif g != dun.lord and not (dun.monsters as Array).has(g):
				k += 1
	return k

func _soak_tick(delta: float) -> bool:
	_game += delta
	if _d == null or _d.state == "home" or _d._alive().is_empty() or _d.dun == null or not is_instance_valid(_d.dun):
		if _cur_key != "":
			_close_floor()
		if _game >= SOAK_SECS:
			if _d:
				_sprung += int(_d.trap_log.get("sprung", 0))
				_swarms += int(_d.trap_log.get("swarms", 0))
				_rejoins += _d.rejoined
			print("D83 soak: %d floors, %d with trap-node drift, %d orphan creatures; %d traps sprung, %d swarms, %d mid-walk fights" % [_floors, _bad_floors, _orphans, _sprung, _swarms, _rejoins])
			_ok(_floors >= 5, "soak covered %d floors" % _floors)
			_ok(_sprung >= 5, "traps actually sprang (%d)" % _sprung)
			_ok(_bad_floors == 0, "no floor ends with more or fewer trap nodes than it was built with")
			_ok(_orphans == 0, "no creature under a floor that the fight loop does not know")
			print("D83_SOAK %s (%d checks, %d failed)" % ["OK" if _fail == 0 else "FAIL", _checks, _fail])
			return true
		_new_delve(1 + (_uid / 3) % 8)
		return false
	var key := "%d:%d" % [_d.get_instance_id(), _d.floor_no]
	if key != _cur_key:
		if _cur_key != "":          # (the old floor is already freed: a freed node reads as null)
			_close_floor()
		_cur_key = key
		_cur_dun = _d.dun
		_floor_rec = {"start": _trap_nodes(_d.dun), "last": _trap_nodes(_d.dun), "no": _d.floor_no, "orph": 0, "kinds": []}
		for t in _d.dun.info.get("traps", []):
			(_floor_rec["kinds"] as Array).append(String(t.get("kind", "")))
	else:
		_floor_rec["last"] = _trap_nodes(_d.dun)
		_floor_rec["orph"] = maxi(int(_floor_rec["orph"]), _orphan_monsters(_d.dun))
	return false

func _close_floor() -> void:
	_floors += 1
	var drift := int(_floor_rec["last"]) != int(_floor_rec["start"])
	if drift:
		_bad_floors += 1
	_orphans += int(_floor_rec["orph"])
	if drift or int(_floor_rec["orph"]) > 0:
		print("  floor %d %s: trap nodes %d -> %d, orphans %d" % [int(_floor_rec["no"]), _floor_rec["kinds"], int(_floor_rec["start"]), int(_floor_rec["last"]), int(_floor_rec["orph"])])
	_cur_dun = null
	_cur_key = ""

## ---------------------------------------------------------------- shot
const OUT := "res://renders/cycles/d83/"
var _cam: Camera3D
var _sk := -1
var _trap: Node3D
var _snaps := 0

func _snap(nm: String) -> void:
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + nm + ".png"))
	print("SAVED ", nm, " state=", _d.state, " foes=", _d._foes().size())

func _aim(at: Vector3, back: Vector3) -> void:
	_cam.make_current()
	if _d.dun.env():
		_cam.environment = _d.dun.env()
	_cam.global_position = at + back
	_cam.look_at(at + Vector3(0, 0.6, 0), Vector3.UP)

func _shot_tick(_delta: float) -> bool:
	if _f == 2:
		_new_delve(4)
		_cam = Camera3D.new()
		_cam.fov = 55.0
		root.add_child(_cam)
		return false
	if _d == null or _d.dun == null or not is_instance_valid(_d.dun) or _f < 30:
		return _f > 6000
	var lead: Dictionary = _d._alive()[0]
	var lb: Node3D = lead["body"]
	if _sk < 0:
		# the floor is won: clear it so the party is on the walk to the stairs
		for f in _d._foes():
			(f as Monster).hp = 0.0
			(f as Monster).die()
		_d.state = "descend"
		_d._t = 0.0
		_sk = _f
		return false
	var k := _f - _sk
	if k == 60:
		var rootn: Node3D = _d.dun.info["root"]
		_trap = DungeonParts.swarm_trap()
		_trap.position = rootn.to_local(lb.global_position) * Vector3(1, 0, 1) + Vector3(0, 0.05, 0)
		rootn.add_child(_trap)
		var tr := {"node": _trap, "kind": "SwarmTrap", "done": true}
		_d._spring(lead, tr, Delve.TRAPS["SwarmTrap"], _d.trap_dc())
		print("D83 shot: sprung on the way to the stairs, state now ", _d.state, " rejoined ", _d.rejoined)
	if k >= 61:
		_aim(_trap.global_position, Vector3(2.0, 10.0, 3.0))   # high, over the walls
	if k == 80:
		_snap("d83_1_up_through_the_grate")
	if k == 150:
		_snap("d83_2_turned_to_fight")
	if k > 150 and _d.state == "descend" and _snaps == 0:
		_snaps = 1
		_snap("d83_3_back_on_the_walk")
		var hi := -1e9
		var lo := 1e9
		for mon in _d.dun.monsters:
			if is_instance_valid(mon):
				hi = maxf(hi, (mon as Node3D).global_position.y - _d.dun.global_position.y)
				lo = minf(lo, (mon as Node3D).global_position.y - _d.dun.global_position.y)
		print("D83 shot: creature heights above the floor ", lo, "..", hi)
		print("D83_SHOT DONE")
		return true
	return k > 2400
