extends SceneTree
## L9: the roll audit, dungeon side. Prints L9_TEST OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
var _phase := 0
var _feed: Array = []

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)
	r.rng.randomize()
	var d := Delve.new()
	d.roster = r
	d._rng.randomize()
	print("A: damage dice keep the old averages")
	for t in range(0, 6):
		var h: Dictionary = r.fresh("k%d" % t, "K%d" % t, "knight", "human")
		h["weapon"] = t
		var old := r.attack(h) * 0.75
		var sm := 0.0
		var lo := 1e9
		var hi := -1e9
		for i in 20000:
			var v := d._hero_damage(h, false)
			sm += v
			lo = minf(lo, v)
			hi = maxf(hi, v)
		var mean := sm / 20000.0
		var dd := r.weapon_dice(h)
		var spread := float(int(dd[0]) * int(dd[1]) - int(dd[0]))
		_ok(absf(mean - old) / old < 0.03 and absf((hi - lo) - spread) < 0.01, "tier %d %s: mean %.2f (old %.2f), spread %.0f = the dice's %.0f" % [t, r.dice_str(h), mean, old, hi - lo, spread])
	var hk: Dictionary = r.get_hero("k3")
	var sc := 0.0
	for i in 20000:
		sc += d._hero_damage(hk, true) - d._hero_damage(hk, false)
	_ok(sc / 20000.0 > 3.0, "a crit rolls the dice twice (+%.1f on average)" % (sc / 20000.0))
	var ms := 0.0
	for i in 20000:
		ms += d._mdice(10.0, false)
	_ok(absf(ms / 20000.0 - 8.0) < 0.1, "a creature's blow on 2d6 keeps its mean (%.2f of 10, was 8.0)" % (ms / 20000.0))
	print("B: haggling is a CHA check")
	var hb: Dictionary = r.fresh("b1", "Haggler", "knight", "human")
	hb["stats"]["cha"] = 10
	var n20 := 0
	var n1 := 0
	var off := 0
	var lst := 0
	for i in 8000:
		var p := r.haggle(hb, 100)
		if p == 75: n20 += 1
		elif p == 110: n1 += 1
		elif p < 100: off += 1
		else: lst += 1
	# CHA +0, not a talker: off on d20 12..19 = 8/20, list on 2..11 = 10/20
	_ok(absf(n20 / 8000.0 - 0.05) < 0.012 and absf(n1 / 8000.0 - 0.05) < 0.012 and absf(off / 8000.0 - 0.40) < 0.02 and absf(lst / 8000.0 - 0.50) < 0.02,
		"CHA +0: 20s %.3f, 1s %.3f, haggled %.3f, list %.3f (5%%/5%%/40%%/50%%)" % [n20 / 8000.0, n1 / 8000.0, off / 8000.0, lst / 8000.0])
	_ok(r.price_mult(hb) == 1.0, "no flat CHA cut on the list price any more")
	hb["gold"] = 5000
	var out := r.buy_potion("b1", 1)
	_ok(out.contains("Now carrying"), "a purchase says how the haggle went: %s" % out)
	print("C: spell saves")
	var caster: Dictionary = r.fresh("c1", "Caster", "mage", "human")
	caster["stats"]["int"] = 16
	var mon := Monster.new()
	mon.def = Bestiary.make("minion")
	d.floor_no = 6
	var saved := 0
	for i in 8000:
		if d._mon_saves(mon, {"uid": "c1", "h": caster}, 0):
			saved += 1
	# DC 8 + 2 + 3 = 13; save d20 + 2 (floor 6 / 3): saves on 11..20 = 10/20
	_ok(absf(saved / 8000.0 - 0.50) < 0.02, "a minion on floor 6 saves vs DC 13 at %.3f (expected 0.500)" % (saved / 8000.0))
	mon.free()
	print("D: the sheet")
	_ok(r.describe("k3").contains("(1d10)"), "the hero sheet shows the weapon's dice: %s" % r.describe("k3").substr(0, 120))
	d.free()
	print("E: a real delve - initiative, traps, Investigation")
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	for i in 4:
		var h: Dictionary = _r.fresh("q%d" % i, "Delver%d" % i, ["rogue", "knight", "cleric", "mage"][i], "human")
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 5
		ids.append("q%d" % i)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = 4
	_d.max_floors = 6
	root.add_child(_d)
	_d.start(ids)
	for m in _d.party:
		m["max"] = float(m["max"]) * 3.0
		m["hp"] = m["max"]

func _process(_dt: float) -> bool:
	_f += 1
	if _d == null:
		return false
	if _phase == 0 and _d.dun and _d.state == "fight":
		_phase = 1
		var sw: Array = []
		for m in _d.party:
			sw.append(snappedf(float(m["swing"]), 0.01))
		_ok(sw.max() <= 1.6 and sw.min() >= 0.15, "initiative set the first swings %s" % [sw])
		# walk the first delver onto every trap on the floor
		var tr: Array = _d.dun.info.get("traps", [])
		_ok(tr.size() > 0, "the floor has %d traps on record" % tr.size())
		for t in tr:
			(_d.party[0]["body"] as Node3D).global_position = (t["node"] as Node3D).global_position
			_d._traps_tick()
		var tl: Dictionary = _d.trap_log
		_ok(int(tl["spotted"]) + int(tl["sprung"]) == tr.size(), "every trap was rolled for: %s" % [tl])
	if _d.state == "home" or _f > 60 * 150:
		var feed: Array = []
		var fl := 0
		for l in _d.party:
			pass
		_ok(_d.trap_log["spotted"] + _d.trap_log["sprung"] > 0, "traps rolled in the delve: %s" % [_d.trap_log])
		print("ended ", _d.state, " floor ", _d.floor_no)
		print("L9_TEST OK" if _fail == 0 else "L9_TEST FAIL %d" % _fail)
		return true
	return false
