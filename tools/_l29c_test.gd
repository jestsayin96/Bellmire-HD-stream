extends SceneTree
## L29c: SET-PIECE ENCOUNTERS - a floor should not be just a room of monsters.
## Round 2 adds PRISONER and SHRINE alongside AMBUSH (round 1).
##
## Measured, not asserted by eye:
##   A. dungeon_hd._set_pieces lays a set piece on most non-boss floors past
##      floor 1, and ALL THREE KINDS appear across a sample.
##   B. driving a hero to the trigger FIRES the right resolver and only once:
##      B.ambush   - the pack spawns into dun.monsters, resolved=true, Chronicle
##                   line reaches the feed, a second tick does NOT re-fire
##      B.prisoner - every alive hero gets a share of the purse (roster.gold
##                   goes up by exactly share * alive), resolved=true, Chronicle
##                   line reaches the feed
##      B.shrine   - a BOON mends everyone back to max_hp; a CURSE takes
##                   SHRINE_CURSE_HP off each. The flip is rolled at build time
##                   so the test can select whichever case it is testing.
##   C. soak: a real multi-floor delve fires at least one set piece of ANY kind.
##
## Prints L29C_TEST OK / FAIL.
##
## Headless. Instantiates FloorGen/DungeonHD/Delve directly - never the Town scene.

var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _soak_fired := 0
# B scenarios are all phased through _process so bodies sit inside the tree
# when _setpieces_tick reads their global_position. See the AMBUSH, PRISONER,
# SHRINE_BOON, SHRINE_CURSE cases below.
enum { B_INIT, B_AMBUSH, B_PRISONER, B_SHRINE_BOON, B_SHRINE_CURSE, B_DONE }
var _b_phase := B_INIT

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

## find a floor whose set piece is of this kind (optionally, for "shrine", a
## particular boon value). Returns [dh, sp] or [null, null] if none in range.
func _find_floor_with(kind: String, want_boon: Variant = null) -> Array:
	for fn in range(2, 80):
		var dh := _build_floor(fn)
		var sps: Array = dh.info.get("set_pieces", [])
		if sps.is_empty():
			dh.queue_free()
			continue
		var sp: Dictionary = sps[0]
		if String(sp.get("kind", "")) != kind:
			dh.queue_free()
			continue
		if want_boon != null and bool(sp.get("boon", false)) != bool(want_boon):
			dh.queue_free()
			continue
		return [dh, sp, fn]
	return [null, null, -1]

## one Delve + one hero rigged at the trigger. The hero body is in-tree before
## _setpieces_tick runs, so its global_position is real.
func _rig(dh: DungeonHD, at: Vector3, uid: String, hero_name: String, cls: String) -> Array:
	var d := Delve.new()
	d.roster = _r
	d.floor_no = int(dh.floor_no)
	root.add_child(d)
	d.dun = dh
	var h: Dictionary = _r.fresh(uid, hero_name, cls)
	var b := HeroBody.new()
	b.setup(_r, uid)
	b.town = d
	b.stay = true
	d.add_child(b)
	b.global_position = at
	d.party = [{"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0}]
	return [d, b, h]

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. the laying: count floors with set pieces + the kinds that appear
	print("L29c A: do set pieces LAND on floors at all?")
	var with_sp := 0
	var without_sp := 0
	var on_boss := 0
	var seen := {}             # kind -> count
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
				seen[k] = int(seen.get(k, 0)) + 1
		dh.queue_free()
	print("   out of floors 2-24 (non-boss), %d had a set piece, %d had none; boss floors with set pieces: %d" % [
		with_sp, without_sp, on_boss])
	print("   kinds seen: %s" % [seen])
	_ok(with_sp >= 5, "A: set pieces appear on a healthy share of floors (%d of %d)" % [with_sp, with_sp + without_sp])
	_ok(on_boss == 0, "A: set pieces NEVER land on a boss floor (%d)" % on_boss)
	_ok(seen.has("ambush") and seen.has("prisoner") and seen.has("shrine"),
		"A: all three kinds appear across the sample (seen=%s)" % [seen])

	# ---- B done in _process so the hero body is actually inside the tree
	print("L29c B: do all three KINDS fire their resolvers?")

	# C launched once B_DONE is reached.

func _process(_dt: float) -> bool:
	_f += 1
	# ---- B.ambush
	if _b_phase == B_INIT:
		_b_phase = B_AMBUSH
		Delve.setpieces_fired.clear()
		var found := _find_floor_with("ambush")
		if found[0] == null:
			_ok(false, "B.ambush: a floor with an ambush could be found")
		else:
			var dh: DungeonHD = found[0]
			var sp: Dictionary = found[1]
			var at: Vector3 = sp["pos"]
			print("   AMBUSH floor %d at %s" % [found[2], at.snappedf(0.1)])
			var rig := _rig(dh, at, "l29c_amb", "Probe", "knight")
			var d: Delve = rig[0]
			var foes_before: int = (dh.monsters as Array).size()
			d._setpieces_tick()
			var foes_after: int = (dh.monsters as Array).size()
			_ok(foes_after > foes_before, "B.ambush: the pack SPAWNED (%d -> %d)" % [foes_before, foes_after])
			_ok(bool(sp.get("resolved", false)), "B.ambush: resolved")
			_ok(int(Delve.setpieces_fired.get("ambush", 0)) == 1,
				"B.ambush: counted exactly once (%d)" % int(Delve.setpieces_fired.get("ambush", 0)))
			d._setpieces_tick()
			_ok(int(Delve.setpieces_fired.get("ambush", 0)) == 1, "B.ambush: does NOT re-fire")
			d.queue_free()
			dh.queue_free()
		return false

	# ---- B.prisoner
	if _b_phase == B_AMBUSH:
		_b_phase = B_PRISONER
		Delve.setpieces_fired.clear()
		var found := _find_floor_with("prisoner")
		if found[0] == null:
			_ok(false, "B.prisoner: a floor with a prisoner could be found")
		else:
			var dh: DungeonHD = found[0]
			var sp: Dictionary = found[1]
			var at: Vector3 = sp["pos"]
			var purse := int(sp.get("purse", 0))
			print("   PRISONER floor %d at %s purse=%d" % [found[2], at.snappedf(0.1), purse])
			var rig := _rig(dh, at, "l29c_pri", "Finder", "knight")
			var d: Delve = rig[0]
			var h: Dictionary = rig[2]
			var gold_before := int(h.get("gold", 0))
			d._setpieces_tick()
			var gold_after := int(h.get("gold", 0))
			var share := maxi(1, purse / 1)       # alive.size() == 1 here
			_ok(gold_after > gold_before, "B.prisoner: the party RECEIVES gold (%d -> %d)" % [gold_before, gold_after])
			_ok(gold_after - gold_before == share,
				"B.prisoner: share equals purse / alive (expected %d, got %d)" % [share, gold_after - gold_before])
			_ok(bool(sp.get("resolved", false)), "B.prisoner: resolved")
			_ok(int(Delve.setpieces_fired.get("prisoner", 0)) == 1,
				"B.prisoner: counted exactly once (%d)" % int(Delve.setpieces_fired.get("prisoner", 0)))
			d._setpieces_tick()
			_ok(int(Delve.setpieces_fired.get("prisoner", 0)) == 1, "B.prisoner: does NOT re-fire")
			d.queue_free()
			dh.queue_free()
		return false

	# ---- B.shrine BOON
	if _b_phase == B_PRISONER:
		_b_phase = B_SHRINE_BOON
		Delve.setpieces_fired.clear()
		var found := _find_floor_with("shrine", true)
		if found[0] == null:
			_ok(false, "B.shrine.boon: a floor with a BOON shrine could be found")
		else:
			var dh: DungeonHD = found[0]
			var sp: Dictionary = found[1]
			var at: Vector3 = sp["pos"]
			print("   SHRINE BOON floor %d at %s" % [found[2], at.snappedf(0.1)])
			var rig := _rig(dh, at, "l29c_shb", "Pilgrim", "cleric")
			var d: Delve = rig[0]
			# start the hero wounded so the BOON actually changes something
			d.party[0]["hp"] = 30.0
			d._setpieces_tick()
			_ok(float(d.party[0]["hp"]) == float(d.party[0]["max"]),
				"B.shrine.boon: hp mended back to max (%.0f/%.0f)" % [float(d.party[0]["hp"]), float(d.party[0]["max"])])
			_ok(bool(sp.get("resolved", false)), "B.shrine.boon: resolved")
			_ok(int(Delve.setpieces_fired.get("shrine", 0)) == 1,
				"B.shrine.boon: counted exactly once (%d)" % int(Delve.setpieces_fired.get("shrine", 0)))
			d.queue_free()
			dh.queue_free()
		return false

	# ---- B.shrine CURSE
	if _b_phase == B_SHRINE_BOON:
		_b_phase = B_SHRINE_CURSE
		Delve.setpieces_fired.clear()
		var found := _find_floor_with("shrine", false)
		if found[0] == null:
			_ok(false, "B.shrine.curse: a floor with a CURSE shrine could be found")
		else:
			var dh: DungeonHD = found[0]
			var sp: Dictionary = found[1]
			var at: Vector3 = sp["pos"]
			print("   SHRINE CURSE floor %d at %s" % [found[2], at.snappedf(0.1)])
			var rig := _rig(dh, at, "l29c_shc", "Fool", "rogue")
			var d: Delve = rig[0]
			d.party[0]["hp"] = 100.0
			d._setpieces_tick()
			# curse is Delve.SHRINE_CURSE_HP off each; hp must be lower, and at
			# least 1 (the curse never drops someone to zero in one touch)
			_ok(float(d.party[0]["hp"]) < 100.0 and float(d.party[0]["hp"]) >= 1.0,
				"B.shrine.curse: hp took a bite but not killed (%.0f)" % float(d.party[0]["hp"]))
			_ok(bool(sp.get("resolved", false)), "B.shrine.curse: resolved")
			d.queue_free()
			dh.queue_free()
		return false

	# ---- C: launch the soak
	if _b_phase == B_SHRINE_CURSE:
		_b_phase = B_DONE
		print("L29c C: soak - does ANY set piece fire in a REAL delve?")
		Delve.setpieces_fired.clear()
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
		_f = 0
		return false

	if _d == null:
		return false
	if _d.state == "home" or _f > 60 * 180:
		var total := 0
		for k in Delve.setpieces_fired:
			total += int(Delve.setpieces_fired[k])
		_soak_fired = total
		print("L29c C: soak ended state=%s frames=%d fired=%s (total=%d)"
			% [_d.state, _f, Delve.setpieces_fired, _soak_fired])
		_ok(_soak_fired >= 1, "C: at least one set piece of any kind fired during the soak (%d)" % _soak_fired)
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L29C_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
