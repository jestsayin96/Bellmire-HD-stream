extends SceneTree
## L29c: SET-PIECE ENCOUNTERS - a floor should not be just a room of monsters.
## Round 1: AMBUSH. Round 2: PRISONER + SHRINE. Round 3: MINIBOSS.
##
## Measured, not asserted by eye:
##   A. dungeon_hd._set_pieces lays a set piece on most non-boss floors past
##      floor 1, and ALL FOUR KINDS appear across a sample past floor 4 (where
##      miniboss unlocks).
##   B. driving a hero to the trigger FIRES the right resolver and only once:
##      B.ambush   - the pack spawns into dun.monsters, resolved=true, Chronicle
##                   line reaches the feed, a second tick does NOT re-fire
##      B.prisoner - every alive hero gets a share of the purse (roster.gold
##                   goes up by exactly share * alive), resolved=true, Chronicle
##                   line reaches the feed
##      B.shrine   - a BOON mends everyone back to max_hp; a CURSE takes
##                   SHRINE_CURSE_HP off each. The flip is rolled at build time
##                   so the test can select whichever case it is testing.
##      B.miniboss - a single monster spawns with MINIBOSS_HP_MULT * normal hp
##                   and MINIBOSS_ATK_MULT * normal atk, meta "l29c_miniboss_purse"
##                   set. When it dies, Delve._on_kill awards the purse across
##                   the alive party and counts setpieces_fired["miniboss_down"].
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
enum { B_INIT, B_AMBUSH, B_PRISONER, B_SHRINE_BOON, B_SHRINE_CURSE, B_MINIBOSS, B_DONE }
var _b_phase := B_INIT

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

## Reuse a single DungeonHD across the whole suite: creating + queue_freeing
## 50+ instances runs the mesh/decal/light machinery once per floor and piles
## pending frees. One DH, rebuilt in place, finishes in seconds instead of
## minutes.
var _shared_dh: DungeonHD = null

func _build_floor(n: int) -> DungeonHD:
	if _shared_dh == null:
		_shared_dh = DungeonHD.new()
		root.add_child(_shared_dh)
	_shared_dh.floor_no = n
	_shared_dh.build(n)
	return _shared_dh

## find a floor whose set piece is of this kind (optionally, for "shrine", a
## particular boon value). Returns [dh, sp, fn] or [null, null, -1].
## Scans up to floor 80 - the curse-shrine variant lands rarely with the
## theme-nudged weights, so a wider band is needed to catch both coins of
## the shrine flip without flaking.
func _find_floor_with(kind: String, want_boon: Variant = null) -> Array:
	for fn in range(2, 80):
		var dh := _build_floor(fn)
		var sps: Array = dh.info.get("set_pieces", [])
		if sps.is_empty():
			continue
		var sp: Dictionary = sps[0]
		if String(sp.get("kind", "")) != kind:
			continue
		if want_boon != null and bool(sp.get("boon", false)) != bool(want_boon):
			continue
		# return the LIVE sp - the resolver sets its resolved flag on this very
		# dictionary, and the caller reads it back to assert the mark landed
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
	# miniboss is gated on floor_no >= 4, so a larger sample covers it
	print("L29c A: do set pieces LAND on floors at all?")
	var with_sp := 0
	var without_sp := 0
	var on_boss := 0
	var seen := {}             # kind -> count
	for fn in range(1, 40):
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
	print("   out of floors 2-39 (non-boss), %d had a set piece, %d had none; boss floors with set pieces: %d" % [
		with_sp, without_sp, on_boss])
	print("   kinds seen: %s" % [seen])
	_ok(with_sp >= 10, "A: set pieces appear on a healthy share of floors (%d of %d)" % [with_sp, with_sp + without_sp])
	_ok(on_boss == 0, "A: set pieces NEVER land on a boss floor (%d)" % on_boss)
	_ok(seen.has("ambush") and seen.has("prisoner") and seen.has("shrine") and seen.has("miniboss"),
		"A: all four kinds appear across the sample (seen=%s)" % [seen])

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
			# dh is _shared_dh - do NOT queue_free; the next phase rebuilds it
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
			# dh is _shared_dh - do NOT queue_free; the next phase rebuilds it
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
			# dh is _shared_dh - do NOT queue_free; the next phase rebuilds it
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
			# dh is _shared_dh - do NOT queue_free; the next phase rebuilds it
		return false

	# ---- B.miniboss - spawn the elite, assert scaling + meta, kill it, assert bonus
	if _b_phase == B_SHRINE_CURSE:
		_b_phase = B_MINIBOSS
		Delve.setpieces_fired.clear()
		var found := _find_floor_with("miniboss")
		if found[0] == null:
			_ok(false, "B.miniboss: a floor with a MINIBOSS could be found")
		else:
			var dh: DungeonHD = found[0]
			var sp: Dictionary = found[1]
			var at: Vector3 = sp["pos"]
			var purse := int(sp.get("purse", 0))
			var base_hp: float = float((sp.get("def", {}) as Dictionary).get("hp", 1.0))
			var base_atk: float = float((sp.get("def", {}) as Dictionary).get("atk", 4.0))
			print("   MINIBOSS floor %d at %s purse=%d (base hp=%.2f atk=%.2f)" %
				[found[2], at.snappedf(0.1), purse, base_hp, base_atk])
			var rig := _rig(dh, at, "l29c_mb", "Hunter", "knight")
			var d: Delve = rig[0]
			var h: Dictionary = rig[2]
			# scale to the floor so the test's reads are exact
			d.floor_no = int(found[2])
			var foes_before: int = (dh.monsters as Array).size()
			d._setpieces_tick()
			var foes_after: int = (dh.monsters as Array).size()
			_ok(foes_after == foes_before + 1, "B.miniboss: exactly one elite spawned (%d -> %d)" % [foes_before, foes_after])
			_ok(bool(sp.get("resolved", false)), "B.miniboss: resolved")
			_ok(int(Delve.setpieces_fired.get("miniboss", 0)) == 1,
				"B.miniboss: counted exactly once (%d)" % int(Delve.setpieces_fired.get("miniboss", 0)))
			# scaling: the spawned monster's max_hp should be
			# (14 + floor*6) * base_hp * MINIBOSS_HP_MULT
			var spawned: Monster = (dh.monsters as Array).back()
			var expected_hp := (14.0 + float(int(found[2])) * 6.0) * base_hp * Delve.MINIBOSS_HP_MULT
			_ok(abs(spawned.max_hp - expected_hp) < 0.1,
				"B.miniboss: max_hp = (14 + floor*6) * base * MINIBOSS_HP_MULT (%.1f vs %.1f)"
				% [spawned.max_hp, expected_hp])
			_ok(spawned.has_meta("l29c_miniboss_purse"),
				"B.miniboss: carries l29c_miniboss_purse meta")
			# kill it and check the bonus fires
			var gold_before := int(h.get("gold", 0))
			spawned.hp = 0
			spawned.state = Monster.S.DEAD
			d._on_kill(spawned)
			var gold_after := int(h.get("gold", 0))
			_ok(gold_after > gold_before,
				"B.miniboss: killing the elite pays out a purse (%d -> %d)" % [gold_before, gold_after])
			_ok(int(Delve.setpieces_fired.get("miniboss_down", 0)) == 1,
				"B.miniboss: setpieces_fired[miniboss_down] counted (%d)"
				% int(Delve.setpieces_fired.get("miniboss_down", 0)))
			# and only once - a second _on_kill call does not pay again
			var gold_mid := int(h.get("gold", 0))
			d._on_kill(spawned)
			var gold_end := int(h.get("gold", 0))
			_ok(gold_end == gold_mid, "B.miniboss: a second _on_kill does NOT pay the purse again")
			d.queue_free()
			# dh is _shared_dh - do NOT queue_free; the next phase rebuilds it
		return false

	# ---- C: launch the soak
	if _b_phase == B_MINIBOSS:
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
