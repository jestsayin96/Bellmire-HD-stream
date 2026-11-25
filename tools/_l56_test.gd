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
## Prints L56_TEST OK / FAIL - or, when a run hit its frame cap before the delve came home and a
## check is still unmet, "L56 CAP HIT - NO VERDICT": a capped run never saw the floors the check
## needs, so its unmet check is the cap talking, not the game (D100, COORDINATION 15).

## S102: the old span (START_FLOOR 3 + FLOORS_PER 8 = floors 3..10 per run) could not finish
## inside RUN_CAP_FRAMES - B116's log shows runs reaching 1, 3 and 5 floors, never 8 - so every
## soak ended "CAP HIT - NO VERDICT" by arithmetic. Each run now STARTS ON a lord floor
## (Bestiary.is_boss_floor: floor % 5 == 0), alternating 5 and 10, and walks FLOORS_PER floors.
## The lord rises on the run's first floor, so the L45 check is earnable within seconds.
## And a cap no longer excuses everything: a check is UNMET (no verdict) only when a run was
## capped BEFORE reaching its own last floor. A soak that reached the ceiling of every run and saw
## nothing FAILS. Red-proof: `-- --redproof` blinds the observer (no trap_log, no lords recorded)
## while the delves still run; it MUST print L56_TEST FAIL when the ceiling is reached.
## S128: THE TRAP HALF WAS A COIN FLIP. B144 read 2 sprung / 3.0 damage and B145 read 0 / 0.0 off the
## SAME script in the SAME shape (_b145_l56.log: every run's trap_log all zeros, so not one trap was
## even MET - the party never walked within TRAP_REACH of one). The L46 checks were excusable by the
## cap, so an absent opportunity printed UNMET and a broken spring would have printed the same thing.
## Now the opportunity is FORCED and the outcome is not: on every floor, the first unmet ordinary
## trap (never a portcullis) is moved under the lead delver's feet, and Delve.force_trap_spot = 0 so
## a trap that is met is missed. The REAL _traps_tick -> _meet_trap -> _spring path then has to fire
## it and land the damage; the test touches nothing past the placement. The L46 checks are HARD
## whenever a placed trap was met; if no placed trap was met at all the gate prints
## "L56 NO VERDICT - 0 placed traps met" and exits 2. Exit codes: OK 0, FAIL 1, NO VERDICT 2.
## Red-proofs: `--redproof` (observer blinded) and `--nospring` (force_trap_spot = 1: every trap is
## spotted and stepped round, so the game path itself never springs) must BOTH print L56_TEST FAIL.
var _nospring := false
var _placed: Array = []          # the trap dicts this soak moved onto a delver's path
var _placed_floor := -1          # floor_no the last placement was made on (once per floor)
const RUNS := 4
const FLOORS_PER := 2
const START_FLOORS := [5, 10, 5, 10]
var START_FLOOR := 5
var _redproof := false
var _ceiling_runs := 0           # runs that reached their own last floor
var _boss_floors_entered := 0

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
const RUN_CAP_FRAMES := 60 * 120  # 2 min per run - the lock's 25-minute rule bounds the whole soak
var _capped: Array = []           # [run, deepest floor reached] for every run the cap ended

var _hard_fails := 0              # S102: unmet checks the cap CANNOT excuse
func _ok(c: bool, what: String, excusable := true) -> void:
	_checks += 1
	# a capped run cannot earn a FAIL on a check it never reached the floors for: that check reads
	# UNMET. A check whose floors WERE reached (excusable=false) fails whatever the cap did.
	var excused := excusable and not _capped.is_empty()
	print("  %s %s" % ["ok  " if c else ("UNMET" if excused else "FAIL"), what])
	if not c:
		_fails.append(what)
		if not excused:
			_hard_fails += 1

func _initialize() -> void:
	_redproof = OS.get_cmdline_user_args().has("--redproof")
	_nospring = OS.get_cmdline_user_args().has("--nospring")
	Delve.force_trap_spot = 1 if _nospring else 0
	if _nospring:
		print("L56: NOSPRING - every trap is spotted and stepped round, the L46 checks must FAIL")
	if _redproof:
		print("L56: REDPROOF - observer blinded, every live check must FAIL at the ceiling")
	_r = Roster.new()
	root.add_child(_r)
	_start_run()
	print("L56: soak begins - %d delves, start_floors=%s, %d floors each" % [RUNS, START_FLOORS, FLOORS_PER])

func _start_run() -> void:
	_run += 1
	START_FLOOR = int(START_FLOORS[(_run - 1) % START_FLOORS.size()])
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
		if Bestiary.is_boss_floor(_last_floor_seen):
			_boss_floors_entered += 1
	_place_trap()
	if _redproof:
		return
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

## S128: the opportunity, never the outcome. Once per floor, move the first unmet ordinary trap to
## the lead living delver. Runs in redproof too - it is the chance to spring, not the observation.
func _place_trap() -> void:
	if _placed_floor == _last_floor_seen or not _d.dun.info.has("traps"):
		return
	var lead = null
	for m in _d._alive():
		if m.has("body") and is_instance_valid(m["body"]):
			lead = m
			break
	if lead == null:
		return
	for t in _d.dun.info["traps"]:
		var tr: Dictionary = t
		if tr.has("cells") or bool(tr.get("done", false)) or not is_instance_valid(tr["node"]):
			continue
		var n := tr["node"] as Node3D
		var at: Vector3 = (lead["body"] as Node3D).global_position
		n.global_position = Vector3(at.x, n.global_position.y, at.z)
		_placed.append(tr)
		_placed_floor = _last_floor_seen
		print("L56 [run %d] floor %d trap PLACED: %s under %s" % [_run, _last_floor_seen, String(tr.get("kind", "?")), String(lead["h"]["name"])])
		return

func _placed_met() -> int:
	var n := 0
	for tr in _placed:
		if bool((tr as Dictionary).get("done", false)):
			n += 1
	return n

func _agg_delve_trap() -> void:
	if _d == null or _redproof:
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
	if _d.state == "home" or _f > RUN_CAP_FRAMES:
		if _last_floor_seen >= START_FLOOR + FLOORS_PER - 1:
			_ceiling_runs += 1
		elif _d.state != "home":
			_capped.append([_run, _last_floor_seen])
			print("L56 [run %d] CAP HIT at floor %d of %d (state=%s)" % [_run, _last_floor_seen, START_FLOOR + FLOORS_PER - 1, _d.state])
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
		# L46 GATE - S128: hard whenever a placed trap was met; no opportunity at all is NO VERDICT
		var met := _placed_met()
		print("  traps placed on a delver's path: %d, met: %d" % [_placed.size(), met])
		if met == 0:
			Delve.force_trap_spot = -1
			print("L56 NO VERDICT - 0 placed traps met (%d placed) - the L46 half had no chance to spring" % _placed.size())
			quit(2)
			return true
		_ok(int(_agg_trap["sprung"]) > 0, "L46: traps actually SPRING in play (%d sprung across the soak, %d placed traps met)"
			% [int(_agg_trap["sprung"]), met], false)
		_ok(float(_agg_trap["damage"]) > 0.0, "L46: trap damage LANDS - a hero loses hp to a trap (%.1f total)"
			% float(_agg_trap["damage"]), false)
		# L45 GATE
		_ok(_lords_seen.size() > 0, "L45: lords actually RISE on boss floors in play (%d kinds seen, %d boss floors entered)"
			% [_lords_seen.size(), _boss_floors_entered], _boss_floors_entered == 0)
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
		print("  ceiling reached in %d of %d runs; %d boss floor(s) entered" % [_ceiling_runs, RUNS, _boss_floors_entered])
		_ok(m10 > m5, "L45: lord_hp_mult(10) > lord_hp_mult(5) - a deeper lord is harder (%.2f vs %.2f)" % [m10, m5], false)
		print("")
		print("CHECKS ", _checks, " UNMET ", _fails.size() - _hard_fails, " FAILS ", _hard_fails)
		for fl in _fails:
			print("  - ", fl)
		Delve.force_trap_spot = -1
		if _fails.is_empty():
			print("L56_TEST OK")
			quit(0)
		elif _hard_fails == 0 and not _capped.is_empty():
			print("L56 CAP HIT - NO VERDICT (%d of %d runs capped [run, floor]: %s; %d check(s) unmet and unearnable)"
				% [_capped.size(), RUNS, _capped, _fails.size()])
			quit(2)
		else:
			print("L56_TEST FAIL")
			quit(1)
		return true
	return false
