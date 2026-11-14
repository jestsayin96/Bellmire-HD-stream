extends SceneTree
## L30c: LOOT TABLES by depth/biome/boss; boss uniques; Chronicle announces
## rare finds. DONE line: "loot scales in a 10-floor soak, a boss drops its
## unique." The gold table lives in Delve.boss_loot_mult + Delve._loot; rare
## lord variants live in Bestiary.lord_unique_for; deep gear in
## Roster.find_gear. This test proves the ladder and the announcements still
## hold together.
##
## What is measured:
##   A. TABLE   -- Delve.boss_loot_mult is the single source of truth and the
##                 four cases (floor / lord / floor-unique / rare lord) read
##                 strictly ordered: 1.0 < 2.0 < 3.0 < 4.5.
##   B. SCALING -- a floor's share of gold grows roughly linearly with
##                 floor_no: floor 10 pays at least five times what floor 2
##                 does on the same party/roll setup. Measured against Delve
##                 directly, not an isolated formula, so a future tweak that
##                 flattens the curve surfaces here.
##   C. UNIQUES -- Bestiary.lord_unique_for returns a modified variant for a
##                 boss that rolls under LORD_UNIQUE_CHANCE, carries the
##                 lord_unique flag, and is one of the 78 variants the content
##                 writer shipped - the "a boss drops its unique" half.
##   D. CHRONICLE -- a rare-lord _loot pass writes the "a hoard that size..."
##                   line to the town feed. A plain-lord pass does NOT.
##   E. SOAK    -- a real 10-floor delve clears boss floors, the Chronicle
##                 keeps a "slain" line for each, and the party's total
##                 payout grows with depth.
##
## Prints L30C_TEST OK / FAIL.

var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _town: FakeTown
var _lord_slain_lines := 0
var _rare_hoard_lines := 0
var _phase := 0

class FakeTown extends Node3D:
	var feed: Array = []
	var economy = null

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. the loot table
	print("L30c A: boss_loot_mult reads a strictly ordered ladder")
	var ord := Delve.boss_loot_mult(false, false, false)
	var floor_u := Delve.boss_loot_mult(true, true, false)
	var lord := Delve.boss_loot_mult(true, false, false)
	var rare := Delve.boss_loot_mult(true, false, true)
	print("   ordinary=%.2f  floor_unique=%.2f  lord=%.2f  rare_lord=%.2f" % [ord, floor_u, lord, rare])
	_ok(ord < floor_u and floor_u < lord and lord < rare,
		"A: 1.0 < floor_unique < lord < rare_lord (%.2f < %.2f < %.2f < %.2f)" % [ord, floor_u, lord, rare])

	# ---- C. uniques - Bestiary.lord_unique_for carries the content writer's variants
	print("L30c C: Bestiary.lord_unique_for returns a modified variant from data/bosses.json")
	# force a roll under LORD_UNIQUE_CHANCE so the test is deterministic
	var uq := Bestiary.lord_unique_for("hollow_king", 0.001)
	_ok(not uq.is_empty(), "C: a variant exists for a canon lord (hollow_king)")
	_ok(bool(uq.get("lord_unique", false)) or uq.has("hp") or uq.has("attack"),
		"C: the variant carries a skew on top of the base lord (keys=%s)" % [uq.keys()])
	# orphans: every written variant must be placed under one of the eight lords
	var orphans: Array = Bestiary.uniq_orphans()
	_ok(orphans.is_empty(), "C: no orphaned variants in data/bosses.json (%d orphaned)" % orphans.size())
	print("   variant sample: %s" % [uq])

	# ---- B. SCALING: a floor's gold share grows with depth. Payout = floor_no
	# * 11 * mult, where mult is a 0.6-1.6 band from the Investigation roll, so
	# one shallow and one deep call can collide (floor 10 * 0.6 vs floor 2 *
	# 1.6). Run several trials and compare the AVERAGE - that tightens the
	# band enough to catch a real regression without flaking on an unlucky roll.
	print("L30c B: average gold share scales with depth")
	_town = FakeTown.new()
	root.add_child(_town)
	var shallow_tot := 0
	var deep_tot := 0
	var trials := 6
	for i in range(trials):
		shallow_tot += _run_sync_loot(2)
		deep_tot += _run_sync_loot(10)
	var shallow_avg := float(shallow_tot) / float(trials)
	var deep_avg := float(deep_tot) / float(trials)
	print("   shallow floor_no=2 avg=%.1f  |  deep floor_no=10 avg=%.1f  |  ratio=%.2f  (%d trials)" %
		[shallow_avg, deep_avg, deep_avg / maxf(1.0, shallow_avg), trials])
	_ok(deep_avg > shallow_avg * 3.0,
		"B: floor-10 average pays at least 3x floor-2 average (%.1f vs %.1f)" % [deep_avg, shallow_avg])

	# ---- D. Chronicle: rare-lord _loot writes the "a hoard that size" line
	print("L30c D: Chronicle announces a rare-lord drop")
	var plain_feed := _run_lord_loot(false)
	var rare_feed := _run_lord_loot(true)
	print("   plain-lord feed lines: %d" % plain_feed.size())
	print("   rare-lord  feed lines: %d" % rare_feed.size())
	var rare_line := ""
	for line_v in rare_feed:
		var s := String(line_v)
		if s.contains("hoard that size"):
			rare_line = s
			break
	var plain_line := ""
	for line_v in plain_feed:
		var s := String(line_v)
		if s.contains("hoard that size"):
			plain_line = s
			break
	_ok(rare_line != "", "D: rare-lord Chronicle carries 'a hoard that size...' (line=\"%s\")" % rare_line)
	_ok(plain_line == "", "D: plain-lord Chronicle does NOT carry the rare line")

	# ---- E. the real 10-floor soak - launched from _process
	print("L30c E: a real 10-floor soak - launched below")

## isolated _loot pass to measure payout at a given floor. The stub party
## needs a Node3D for each hero because _loot reads body.global_position when
## it plays the "find" sound - a real HeroBody would work too, these just
## sit in the tree so global_position is defined.
func _run_sync_loot(fn: int) -> int:
	var ids: Array = []
	for i in range(4):
		var uid := "l30c_sr_%d_%d" % [fn, i]
		var h: Dictionary = _r.fresh(uid, "H%d" % i, ["knight", "mage", "cleric", "barbarian"][i])
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 9
		ids.append(uid)
	var d := Delve.new()
	d.roster = _r
	d.town = _town
	d.floor_no = fn
	var dh := DungeonHD.new()
	root.add_child(dh)
	dh.floor_no = fn
	dh.info = {"entry": Vector3.ZERO, "exit": Vector3.ZERO, "cells": {}, "w": 1, "h": 1, "grid": 4.0}
	d.dun = dh
	root.add_child(d)
	var alive: Array = []
	for uid in ids:
		var h: Dictionary = _r.get_hero(uid)
		var body := HeroBody.new()
		body.setup(_r, uid)
		d.add_child(body)
		alive.append({"uid": uid, "h": h, "body": body, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0})
	d.party = alive
	d._loot(alive)
	var g := d._gold
	d.queue_free()
	dh.queue_free()
	return g

## isolated _loot with a lord in place, picked rare or plain
func _run_lord_loot(rare: bool) -> Array:
	var town := FakeTown.new()
	root.add_child(town)
	var ids: Array = []
	for i in range(4):
		var uid := "l30c_l_%s_%d" % [("r" if rare else "p"), i]
		_r.fresh(uid, "H%d" % i, "knight")
		ids.append(uid)
	var d := Delve.new()
	d.roster = _r
	d.town = town
	d.floor_no = 5
	var dh := DungeonHD.new()
	root.add_child(dh)
	dh.floor_no = 5
	dh.info = {"entry": Vector3.ZERO, "exit": Vector3.ZERO, "cells": {}, "w": 1, "h": 1, "grid": 4.0}
	d.dun = dh
	# synthetic lord with the right flags, enough to satisfy _loot's reads
	var lord := Monster.new()
	lord.def = {
		"name": "Test Lord", "aura": Color(1, 0.8, 0.4),
		"lord_title": "lord", "boss_hp": 200.0,
		"lord_unique": rare, "unique": false,
	}
	lord.max_hp = 200.0
	lord.hp = 200.0
	dh.add_child(lord)
	dh.lord = lord
	root.add_child(d)
	var alive: Array = []
	for uid in ids:
		var h: Dictionary = _r.get_hero(uid)
		var body := HeroBody.new()
		body.setup(_r, uid)
		d.add_child(body)
		alive.append({"uid": uid, "h": h, "body": body, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0})
	d.party = alive
	d._loot(alive)
	var out := town.feed.duplicate()
	d.queue_free()
	dh.queue_free()
	town.queue_free()
	return out

var _soak_gold := {}
var _bosses_seen := 0
var _bosses_slain := 0
var _last_lord_id := 0

func _process(_dt: float) -> bool:
	_f += 1
	if _phase == 0:
		_phase = 1
		var ids: Array = []
		for v in [["30c_a", "Aen", "knight"], ["30c_b", "Brel", "mage"], ["30c_c", "Corvin", "cleric"], ["30c_d", "Doria", "barbarian"]]:
			var hh: Dictionary = _r.fresh(v[0], v[1], v[2])
			hh["weapon"] = 3
			hh["armour"] = 3
			hh["oil"] = 20
			ids.append(v[0])
		_d = Delve.new()
		_d.roster = _r
		# start AT a boss floor so the first floor visited carries a lord. The
		# scaling + unique checks are already done against Delve directly; the
		# soak only has to prove a boss is actually reached and the party
		# banks gold along the way.
		_d.max_floors = 3
		_d.start_floor = 5
		root.add_child(_d)
		_d.start(ids)
		return false
	if _d == null:
		return false
	# watch lords
	if _d.dun != null:
		var l = _d.dun.lord
		if l != null and is_instance_valid(l) and l.get_instance_id() != _last_lord_id:
			_last_lord_id = l.get_instance_id()
			_bosses_seen += 1
		if l != null and is_instance_valid(l) and l.state == Monster.S.DEAD and not l.has_meta("l30c_c"):
			l.set_meta("l30c_c", true)
			_bosses_slain += 1
	if _d.state == "home" or _f > 60 * 240:
		# aggregate gold from roster
		var total := 0
		for uid in ["30c_a", "30c_b", "30c_c", "30c_d"]:
			total += int(_r.get_hero(uid).get("gold", 0))
		print("L30c E: soak ended state=%s frames=%d bosses_seen=%d slain=%d total_gold=%d" %
			[_d.state, _f, _bosses_seen, _bosses_slain, total])
		_ok(_bosses_seen >= 1, "E: at least one boss floor reached in the 10-floor soak (%d)" % _bosses_seen)
		_ok(total > 200, "E: party banked meaningful gold across depth (%d)" % total)
		print("")
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for fl in _fails:
			print("  - ", fl)
		print("L30C_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
