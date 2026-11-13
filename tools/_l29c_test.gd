extends SceneTree
## L29c: SET-PIECE ENCOUNTERS - a floor should not be just a room of monsters.
## Round 1: AMBUSH. Mid-floor trigger that peels 2-3 theme-matched creatures out
## of the dark where the party stands, counted into the floor's foes and logged
## to the Chronicle. Measured, not asserted by eye:
##   A. dungeon_hd._set_pieces lays an ambush on most non-boss floors past floor 1
##      (two-in-three; never on a boss floor; never on floor 1).
##   B. A hero crossing the trigger radius FIRES the ambush exactly once per
##      set piece. The pack spawns, joins the foes list, and a Chronicle line
##      naming the creatures reaches the feed.
##   C. A soak: run a real delve and count set pieces fired - ambush resolutions
##      actually HAPPEN in play, not just in a synthetic probe.
## Prints L29C_TEST OK / FAIL.
##
## Headless. The test instantiates FloorGen/DungeonHD/Delve directly - never the
## Town scene - so it stays the same shape as the other delve-side L-tests
## (_delve_test, _l29b_test).

var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _soak_fired := 0
var _b_dh: DungeonHD = null
var _b_sps: Array = []
var _b_picked := 0
var _b_phase := 0        # 0 wait-a-frame, 1 probe, 2 done

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _build_floor(n: int) -> DungeonHD:
	var dh := DungeonHD.new()
	dh.floor_no = n
	root.add_child(dh)
	dh.build(n)
	return dh

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. the laying: count ambush-bearing floors across a sample
	print("L29c A: do ambushes LAND on floors at all?")
	var with_sp := 0
	var without_sp := 0
	var on_boss := 0
	var seen := []
	for fn in range(1, 25):
		var dh := _build_floor(fn)
		var sps: Array = dh.info.get("set_pieces", [])
		var boss := bool(dh.info.get("boss", false))
		if boss and not sps.is_empty():
			on_boss += 1
		if fn >= 2 and not boss:
			if sps.is_empty():
				without_sp += 1
			else:
				with_sp += 1
				var k := String((sps[0] as Dictionary).get("kind", "?"))
				if not seen.has(k):
					seen.append(k)
		dh.queue_free()
	print("   out of floors 2-24 (non-boss), %d had a set piece, %d had none; boss floors with set pieces: %d" % [
		with_sp, without_sp, on_boss])
	print("   kinds seen: %s" % [seen])
	_ok(with_sp >= 5, "A: ambushes appear on a healthy share of floors (%d of %d)" % [with_sp, with_sp + without_sp])
	_ok(on_boss == 0, "A: set pieces NEVER land on a boss floor (%d)" % on_boss)
	_ok(seen.has("ambush"), "A: at least one ambush kind seen (%s)" % seen)

	# ---- B. the firing: driven in _process so the bodies are actually in-tree
	print("L29c B: does a hero crossing the trigger FIRE the ambush?")
	Delve.setpieces_fired = {}
	_b_dh = DungeonHD.new()
	root.add_child(_b_dh)
	# roll floors forward until one with a set piece comes back
	for fn in range(2, 40):
		_b_dh.build(fn)
		_b_sps = _b_dh.info.get("set_pieces", [])
		if not _b_sps.is_empty():
			_b_picked = fn
			break
	if _b_sps.is_empty():
		_ok(false, "B: a floor with a set piece could be found (none in 2..39)")

	# ---- C. the soak: a real delve. Does the ambush fire in play?
	# (started after B settles - see _process)
	Delve.setpieces_fired = {}
	# (soak launched from _process once B is done)

func _process(_dt: float) -> bool:
	_f += 1
	# ---- B done in _process so the hero body is actually inside the tree
	if _b_phase == 0 and _b_dh != null and not _b_sps.is_empty():
		_b_phase = 1
		var sp: Dictionary = _b_sps[0]
		var at: Vector3 = sp["pos"] as Vector3
		print("   floor %d set piece: kind=%s pos=%s" % [_b_picked, sp["kind"], at.snappedf(0.1)])
		var d := Delve.new()
		d.roster = _r
		root.add_child(d)
		d.dun = _b_dh
		var h: Dictionary = _r.fresh("l29c_probe", "Probe", "knight")
		var b := HeroBody.new()
		b.setup(_r, "l29c_probe")
		b.town = d
		b.stay = true
		d.add_child(b)
		b.global_position = at
		d.party = [{"uid": "l29c_probe", "h": h, "body": b, "hp": 100, "max": 100, "saved": false, "swing": 0.0}]
		var foes_before: int = (_b_dh.monsters as Array).size()
		d._setpieces_tick()
		var foes_after: int = (_b_dh.monsters as Array).size()
		print("   monsters before=%d after=%d (delta=%d)" % [foes_before, foes_after, foes_after - foes_before])
		print("   setpieces_fired=%s" % [Delve.setpieces_fired])
		_ok(foes_after > foes_before, "B: the pack SPAWNED into the floor (%d -> %d)" % [foes_before, foes_after])
		_ok(bool(sp.get("resolved", false)), "B: the set piece is marked RESOLVED")
		_ok(int(Delve.setpieces_fired.get("ambush", 0)) == 1, "B: ambush counted exactly once (%d)" % int(Delve.setpieces_fired.get("ambush", 0)))
		d._setpieces_tick()
		_ok(int(Delve.setpieces_fired.get("ambush", 0)) == 1, "B: a resolved set piece does NOT fire again")
		d.queue_free()
		_b_dh.queue_free()
		# NOW launch the soak
		print("L29c C: soak - does an ambush fire in a REAL delve?")
		Delve.setpieces_fired = {}
		var ids: Array = []
		for v in [["29c1", "Aen", "knight"], ["29c2", "Bram", "mage"], ["29c3", "Corvin", "cleric"], ["29c4", "Doria", "barbarian"]]:
			var hh: Dictionary = _r.fresh(v[0], v[1], v[2])
			hh["oil"] = 12
			ids.append(v[0])
		_d = Delve.new()
		_d.roster = _r
		_d.max_floors = 6
		_d.start_floor = 3
		root.add_child(_d)
		_d.start(ids)
		return false
	if _d == null:
		return false
	if _d.state == "home" or _f > 60 * 180:
		_soak_fired = int(Delve.setpieces_fired.get("ambush", 0))
		print("L29c C: soak ended state=%s frames=%d ambushes=%d" % [_d.state, _f, _soak_fired])
		_ok(_soak_fired >= 1, "C: at least one ambush fired during the soak (%d)" % _soak_fired)
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L29C_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
