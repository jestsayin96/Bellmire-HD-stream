extends SceneTree
## L55: FORGING MAY NOT RAISE GEAR TIERS. Found by the census, not reported by anyone: weapon and
## armour stayed w0/a0 for all six heroes through a 7-minute soak despite 17 forge lines and
## survivors with 4 and 8 kills. The supervisor named two candidates - forging never raises the
## tier, or death resets it. VERIFY WHICH, then fix; do not guess.
##   A. DOES THE FORGE WORK AT ALL? A hero with gold in hand buys up a tier. If this passes, the
##      forging code is fine and the fault is that nobody is calling it.
##   B. DOES DEATH RESET IT? Gear is checked across kill() and reroll().
##   C. THE SOAK, which is the actual DONE criterion: run real delves and see whether a SURVIVING
##      hero's tier climbs. This is the one that was failing in the field.
## Headless: roster/gear arithmetic and delve logic. Prints L55_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _part := "A"
var _start_tiers := {}
var _peak_gold := {}
var _round := 1
var _climb_r1 := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _tier_line(h: Dictionary) -> String:
	return "w%d/a%d %dg" % [int(h.get("weapon", 0)), int(h.get("armour", 0)), int(h.get("gold", 0))]

func _new_delve(floors: int) -> void:
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = floors
	root.add_child(_d)
	var ids: Array = []
	for v in [["5501", "Ashvein", "knight"], ["5502", "Brelda", "mage"],
			  ["5503", "Corrin", "cleric"], ["5504", "Dunmar", "barbarian"]]:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["oil"] = 9
		ids.append(v[0])
		_start_tiers[v[0]] = [int(h["weapon"]), int(h["armour"])]
	_d.start(ids)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

	# ---- A. does the forge raise a tier when it is actually called with gold in hand?
	var h: Dictionary = _r.fresh("5500", "Probe", "knight")
	h["gold"] = 5000
	var w0 := int(h["weapon"])
	var msg := _r.buy_weapon("5500", "")
	var w1 := int(h["weapon"])
	print("L55 A: forge with 5000g: w%d -> w%d  |  %s" % [w0, w1, msg])
	_ok(w1 > w0, "A: the forge DOES raise a weapon tier when called with gold (w%d -> w%d)" % [w0, w1])
	var a0 := int(h["armour"])
	var amsg := _r.buy_armour("5500")
	print("L55 A: armour: a%d -> a%d  |  %s" % [a0, int(h["armour"]), amsg])
	_ok(int(h["armour"]) > a0, "A: the forge DOES raise an armour tier (a%d -> a%d)" % [a0, int(h["armour"])])
	print("   town_tier = %d (tier 1 costs %d gold)" % [Roster.town_tier, int(Roster.WEAPONS[1]["cost"])])

	# ---- the poor hero: this is what a refusal looks like, and it is what the census counted
	var p: Dictionary = _r.fresh("5599", "Pauper", "knight")
	p["gold"] = 0
	var pw := int(p["weapon"])
	var pmsg := _r.buy_weapon("5599", "")
	print("L55 A: forge with 0g: w%d -> w%d  |  %s" % [pw, int(p["weapon"]), pmsg])
	_ok(int(p["weapon"]) == pw, "A: a hero with no gold is REFUSED and stays put - a 'forge line' is not a purchase")

	# ---- B. does death or a reroll wipe the gear?
	var d: Dictionary = _r.fresh("5598", "Doomed", "knight")
	d["gold"] = 5000
	_r.buy_weapon("5598", "")
	_r.buy_armour("5598")
	var bw := int(d["weapon"])
	var ba := int(d["armour"])
	_r.kill("5598", "a probe", 3, 1)
	print("L55 B: after kill(): w%d/a%d alive=%s" % [int(d["weapon"]), int(d["armour"]), str(d.get("alive"))])
	_ok(int(d["weapon"]) == bw and int(d["armour"]) == ba,
		"B: kill() does NOT strip the gear off the hero record (w%d/a%d kept)" % [int(d["weapon"]), int(d["armour"])])
	_r.reroll("5598", true)
	_ok(int(d["weapon"]) == bw and int(d["armour"]) == ba,
		"B: reroll() rerolls STATS only and keeps the gear (w%d/a%d)" % [int(d["weapon"]), int(d["armour"])])
	# the real reset: coming back is a FRESH hero, and fresh() starts at w0/a0
	var again: Dictionary = _r.fresh("5598", "Doomed II", "knight")
	print("L55 B: a hero who comes back via fresh(): %s" % _tier_line(again))
	_ok(int(again["weapon"]) == 0, "B: coming back after death IS a fresh hero at w0 - that is the reset, and it is by design")

	# a SHORT delve on purpose: the kit-up happens when they come HOME, so the run has to
	# actually finish. An 8-floor run hit the frame cap in state "descend" and never reached
	# _finish(), which made the first version of this test look like the fix had failed.
	_new_delve(3)

func _process(_dt: float) -> bool:
	_f += 1
	for m in _d.party:
		var uid := String(m["uid"])
		var hh := _r.get_hero(uid)
		if not hh.is_empty():
			_peak_gold[uid] = maxi(int(_peak_gold.get(uid, 0)), int(hh.get("gold", 0)))
	if _d.state == "home" or _f > 60 * 240:
		print("L55 C: after a multi-floor delve -")
		var climbed := 0
		var survivors := 0
		var could_afford := 0
		for m in _d.party:
			var uid := String(m["uid"])
			var hh := _r.get_hero(uid)
			if hh.is_empty():
				continue
			var was: Array = _start_tiers.get(uid, [0, 0])
			var alive := bool(hh.get("alive", true))
			if alive:
				survivors += 1
			if int(hh["weapon"]) > int(was[0]) or int(hh["armour"]) > int(was[1]):
				climbed += 1
			if int(_peak_gold.get(uid, 0)) >= int(Roster.WEAPONS[1]["cost"]):
				could_afford += 1
			print("   %-9s %s  (started w%d/a%d, peak gold %d, alive=%s, kills %d)"
				% [hh["name"], _tier_line(hh), int(was[0]), int(was[1]),
				   int(_peak_gold.get(uid, 0)), str(alive), int(hh.get("kills", 0))])
		print("   survivors %d, climbed a tier %d, ever able to afford tier 1 %d" % [survivors, climbed, could_afford])
		print("   [diag] delve state=%s frames=%d (timeout would be %d)" % [_d.state, _f, 60 * 240])
		# did the kit-up simply never get called, or is it refusing?
		for m in _d.party:
			var uid2 := String(m["uid"])
			var h2 := _r.get_hero(uid2)
			if h2.is_empty():
				continue
			var line := _r.kit_up_after_delve(uid2)
			print("   [diag] kit_up(%s) with %dg -> %s" % [h2["name"], int(h2.get("gold", 0)), line if line != "" else "(refused)"])
		_ok(survivors > 0, "C: somebody came home (%d)" % survivors)
		_ok(could_afford > 0, "C: heroes DO earn enough to afford the forge (%d of them could)" % could_afford)
		# Whether anyone can afford the forge after ONE short delve is loot luck - measured at
		# 0-1 of 4. The DONE criterion is "a SOAK where surviving heroes visibly climb tiers",
		# and a soak is the session, not a single run, so the climb is asserted once both delves
		# are done. Round one only reports. Asserting it on round one would be a flaky test
		# dressed up as a product failure.
		if _round == 2:
			_ok(climbed > 0, "C: SURVIVING heroes visibly climbed tiers over the session (%d of %d) - the L55 DONE criterion" % [climbed, survivors])
		else:
			print("   (round 1 climbed %d of %d - loot luck; the criterion is judged after round 2)" % [climbed, survivors])
		# D. one delve proves it can happen; a stream is many delves. Send the SAME heroes down
		# again and require the tiers to keep climbing, because "it fired once" is not the same
		# as "heroes get better over a session", which is what Mr. E will actually be watching.
		if _round == 1:
			_round = 2
			_f = 0
			var again: Array = []
			for m in _d.party:
				var uid3 := String(m["uid"])
				var h3 := _r.get_hero(uid3)
				if not h3.is_empty() and bool(h3.get("alive", true)):
					h3["oil"] = 9
					again.append(uid3)
			_climb_r1 = climbed
			if again.size() >= 2:
				print("L55 D: sending the same %d heroes down again -" % again.size())
				_d.queue_free()
				_d = Delve.new()
				_d.roster = _r
				_d.max_floors = 3
				root.add_child(_d)
				_d.start(again)
				return false
		else:
			_ok(climbed > _climb_r1,
				"D: tiers keep climbing over a SECOND delve, so heroes improve across a session (%d -> %d climbed)"
				% [_climb_r1, climbed])
		print("CHECKS ", _checks, " FAILS ", _fails.size())
		for f in _fails:
			print("  - ", f)
		print("L55_TEST ", "OK" if _fails.is_empty() else "FAIL")
		return true
	return false
