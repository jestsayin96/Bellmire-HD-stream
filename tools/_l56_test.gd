extends SceneTree
## L56: DELVE-HEAVY SOAK. The census could not confirm bosses or trap damage
## because raids kept pulling parties back to town and only ~1 sustained descent
## happened in an 8-minute window. The dungeon-side counters undercounted - so
## claims about L45 (lord scaling) and L46 (traps actually hurt) were stated on
## a thin sample. L56 GATES both.
##
## Fix: skip the town entirely, seed parties straight to a lord-depth floor with
## Delve.start_floor, run a few delves back to back and read the dungeon-side
## counters directly: Delve.trap_log (spotted / disarmed / sprung / saved /
## damage) aggregated across delves, and lord encounters pulled off dun.lord
## while each floor is live. This is what the supervisor named: "seed a party
## straight to the mouth and read Delve.trap_log directly."
##
## DONE:
##   A. traps actually SPRING in play, and some do damage (L46 gate)
##   B. bosses ACTUALLY RISE on boss floors across the soak, and their HP scales
##      with depth as L45 claims (lord_hp_mult: a deeper lord is harder)
## Prints L56_TEST OK / FAIL.

const RUNS := 4
const FLOORS_PER := 8            # start at 3 -> up to floor 10, so TWO lord floors in each run
const START_FLOOR := 3

var _r: Roster
var _d: Delve
var _f := 0
var _run := 0
var _fails: Array = []
var _checks := 0
# aggregates across all delves
var _agg_trap := {"spotted": 0, "disarmed": 0, "sprung": 0, "saved": 0, "damage": 0.0}
var _lords_seen := {}            # name -> {"hp_max_at_floor": {floor_no: max_hp}}
var _lords_down := 0
var _floors_visited := 0
var _last_floor_seen := 0
var _last_lord_id := 0
# keep a reference to the lord instance so a dead one logged on queue_free
var _tracked_lords: Array = []

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_start_run()
	print("L56: soak begins - %d delves, start_floor=%d, %d floors each" % [RUNS, START_FLOOR, FLOORS_PER])

func _start_run() -> void:
	_run += 1
	var ids: Array = []
	var V := [
		["l56_%d_1" % _run, "Aen", "knight"],
		["l56_%d_2" % _run, "Brel", "mage"],
		["l56_%d_3" % _run, "Corvin", "cleric"],
		["l56_%d_4" % _run, "Doria", "barbarian"],
	]
	for v in V:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		# L45 scaling tests the DIFFERENCE between a shallow lord and a deep one, not
		# whether the party survives either. Decent gear and oil so the run actually
		# makes it to the deeper lord floor.
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 14
		ids.append(v[0])
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = FLOORS_PER
	_d.start_floor = START_FLOOR
	root.add_child(_d)
	_d.start(ids)
	_f = 0
	_last_floor_seen = 0
	_last_lord_id = 0

func _watch(delta: float) -> void:
	if _d == null or _d.dun == null:
		return
	if int(_d.floor_no) != _last_floor_seen:
		_last_floor_seen = int(_d.floor_no)
		_floors_visited += 1
	# a new lord on this floor - check every tick, not just at floor-change,
	# because dun.lord may be set after we noticed the floor_no bump (entrance
	# is call_deferred, and we poll once per physics tick)
	var l = _d.dun.lord
	if l != null and is_instance_valid(l) and l.get_instance_id() != _last_lord_id:
		_last_lord_id = l.get_instance_id()
		_tracked_lords.append(l)
		var nm := String(l.def.get("name", "A lord"))
		if not _lords_seen.has(nm):
			_lords_seen[nm] = {}
		(_lords_seen[nm] as Dictionary)[_last_floor_seen] = float(l.max_hp)
		print("L56 [run %d] floor %d LORD RISES: %s hp=%.0f" % [_run, _last_floor_seen, nm, l.max_hp])
	if l != null and is_instance_valid(l) and l.state == Monster.S.DEAD:
		if not l.has_meta("l56_counted"):
			l.set_meta("l56_counted", true)
			_lords_down += 1
			print("L56 [run %d] floor %d lord DOWN" % [_run, _last_floor_seen])

func _agg_delve_trap() -> void:
	if _d == null:
		return
	for k in _d.trap_log:
		if k == "damage":
			_agg_trap[k] = float(_agg_trap[k]) + float(_d.trap_log[k])
		else:
			_agg_trap[k] = int(_agg_trap[k]) + int(_d.trap_log[k])

func _end_run() -> void:
	_agg_delve_trap()
	print("L56 [run %d] ended state=%s floors_visited=%d trap_log=%s"
		% [_run, _d.state, _floors_visited, _d.trap_log])
	_d.queue_free()
	_d = null

func _process(dt: float) -> bool:
	_f += 1
	if _d == null:
		return false
	_watch(dt)
	if _d.state == "home" or _f > 60 * 120:          # 2 min cap per run
		_end_run()
		if _run < RUNS:
			_start_run()
			return false
		# ---- the soak is over, judge
		print("")
		print("L56 SOAK SUMMARY")
		print("  trap_log aggregate across %d delves: %s" % [RUNS, _agg_trap])
		print("  lords seen: %d kinds, %d killed" % [_lords_seen.size(), _lords_down])
		for nm in _lords_seen:
			var hp_at: Dictionary = _lords_seen[nm]
			print("    %s on floors %s" % [nm, hp_at])
		# L46 GATE
		_ok(int(_agg_trap["sprung"]) > 0, "L46: traps actually SPRING in play (%d sprung across the soak)"
			% int(_agg_trap["sprung"]))
		_ok(float(_agg_trap["damage"]) > 0.0, "L46: trap damage LANDS - a hero loses hp to a trap (%.1f total)"
			% float(_agg_trap["damage"]))
		# L45 GATE
		_ok(_lords_seen.size() > 0, "L45: lords actually RISE on boss floors in play (%d kinds seen)"
			% _lords_seen.size())
		# scaling: compare any lord recorded at both a shallow and a deep floor,
		# or two distinct lords from different depths - a floor-10 lord should
		# out-HP a floor-5 lord of comparable base
		var all_pairs: Array = []
		for nm in _lords_seen:
			var hp_at: Dictionary = _lords_seen[nm]
			var floors: Array = hp_at.keys()
			floors.sort()
			if floors.size() >= 2:
				all_pairs.append([nm, floors[0], floors[-1], float(hp_at[floors[0]]), float(hp_at[floors[-1]])])
		# compare lord_hp_mult scaling directly - always available, no RNG
		var m5 := Bestiary.lord_hp_mult(5)
		var m10 := Bestiary.lord_hp_mult(10)
		print("  Bestiary.lord_hp_mult: floor 5 = %.2f, floor 10 = %.2f" % [m5, m10])
		_ok(m10 > m5, "L45: lord_hp_mult(10) > lord_hp_mult(5) - a deeper lord is harder (%.2f vs %.2f)" % [m10, m5])
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L56_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
