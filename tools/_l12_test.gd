extends SceneTree
## L12: potions and states. Prints L12_TEST OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
var _seen := {}
var _drunk := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var ps: Dictionary = Roster.potions().get("potions", {})
	print("A: the data and the apothecary")
	_ok(ps.size() == 12, "12 brews in data/potions.json")
	_ok(Roster.potion_key("haste") == "quickwater" and Roster.potion_key("Owl-eye Drops") == "owl" and Roster.potion_key("antidote") == "antidote", "names and aliases resolve")
	var r := Roster.new()
	root.add_child(r)
	var h: Dictionary = r.fresh("p1", "Pip", "rogue", "halfling")
	h["gold"] = 5000
	Roster.town_tier = 1
	var out := r.buy_brew("p1", "quickwater", 1)
	_ok(r.brew_count(h, "quickwater") == 0 and out.contains("cannot brew"), "a hamlet's apothecary cannot brew Quickwater: %s" % out)
	Roster.town_tier = 4
	var cc := ChatCmd.new(r)
	out = cc.handle("p1", "Pip", "!brew haste 2")
	_ok(r.brew_count(h, "quickwater") == 2, "!brew haste 2: %s" % out)
	cc._last.clear()
	out = cc.handle("p1", "Pip", "!brew 3")
	_ok(int(h["potions"]) == 4, "!brew 3 still buys Mending: %s" % out)
	cc._last.clear()
	out = cc.handle("p1", "Pip", "!inventory")
	_ok(out.contains("Quickwater") and out.contains("Mending"), "!inventory lists the brews: %s" % out)
	print("B: drinking and states")
	var d := Delve.new()
	d.roster = r
	d._rng.randomize()
	var m := {"uid": "p1", "h": h, "body": HeroBody.new(), "hp": 50.0, "max": 100.0}
	var lo := 999
	var hi := 0
	for i in 400:
		m["hp"] = 1.0
		r.add_brew(h, "supreme", 1)
		d.drink(m, "supreme")
		lo = mini(lo, int(m["hp"]) - 1)
		hi = maxi(hi, int(m["hp"]) - 1)
	_ok(lo >= 30 and hi <= 60 and hi - lo > 15, "Supreme Mending heals 10d4+20: %d..%d" % [lo, hi])
	m["hp"] = 100.0
	d._give(m, "poisoned", 5.0)
	_ok(d.has_st(m, "poisoned") and d._hero_adv(m) == -1, "poisoned: disadvantage")
	r.add_brew(h, "antidote", 1)
	m["hp"] = 100.0
	m["quaff_t"] = 0.0
	_ok(d._quaff(m) and not d.has_st(m, "poisoned"), "a poisoned delver drinks Bitterleaf and is cured")
	m["quaff_t"] = 0.0
	r.add_brew(h, "bravecup", 1)
	d.drink(m, "bravecup")
	d._give(m, "frightened", 6.0)
	_ok(not d.has_st(m, "frightened") and float(m["hp"]) > 100.0, "Bravecup: cannot be frightened, +10 temporary")
	m["st"] = {}
	r.add_brew(h, "emberward", 1)
	d.drink(m, "emberward")
	d._give(m, "burning", 3.0)
	_ok(not d.has_st(m, "burning") and d._resist(m, "fire") == 0.5, "Emberward: no burning, half fire")
	m["st"] = {}
	m["hp"] = 100.0
	d._give(m, "burning", 3.0)
	for i in 200:
		d._status_tick(m, 1.0 / 60.0)
	_ok(float(m["hp"]) < 100.0 and float(m["hp"]) >= 88.0, "burning 1d4 a second for 3 s (100 -> %d)" % int(m["hp"]))
	m["st"] = {"invisible": 20.0}
	_ok(d._hero_adv(m) == 1, "unseen: advantage")
	m["st"] = {}
	m["hp"] = 20.0
	h["potions"] = 1
	m["quaff_t"] = 0.0
	_ok(d._quaff(m) and int(h["potions"]) == 0 and float(m["hp"]) > 20.0, "a delver under a third drinks their Mending")
	(m["body"] as Node3D).free()
	d.free()
	print("C: a lord floor")
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	for i in 4:
		var hh: Dictionary = _r.fresh("q%d" % i, "D%d" % i, ["knight", "rogue", "cleric", "barbarian"][i], "human")
		hh["weapon"] = 2
		hh["armour"] = 2
		hh["oil"] = 4
		hh["potions"] = 3
		hh["brews"] = {"ogre": 1, "antidote": 1, "emberward": 1}
		ids.append("q%d" % i)
	Bestiary._spent = Bestiary.LESSER.duplicate()
	Bestiary._spent.erase("nightwing")
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = 5
	_d.max_floors = 5
	root.add_child(_d)
	_d.start(ids)
	for mm in _d.party:
		mm["max"] = float(mm["max"]) * 3.0
		mm["hp"] = mm["max"]

func _process(_dt: float) -> bool:
	_f += 1
	if _d == null:
		return false
	for mm in _d.party:
		for s in _d.statuses(mm):
			_seen[String(s[0])] = true
	if _d.state == "home" or _f > 60 * 150:
		var used := 0
		for mm in _d.party:
			used += 3 - int(mm["h"].get("potions", 0)) + (1 - _r.brew_count(mm["h"], "ogre"))
		print("  states seen: ", _seen.keys())
		_ok(_seen.size() >= 2, "states show on the delvers below (%d kinds)" % _seen.size())
		_ok(used > 0, "potions were drunk below (%d)" % used)
		print("L12_TEST OK" if _fail == 0 else "L12_TEST FAIL %d" % _fail)
		return true
	return false
