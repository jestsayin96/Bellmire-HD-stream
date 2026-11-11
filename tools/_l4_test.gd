extends SceneTree
## L4 (work plan 2): the six new callings. Each enlists by chat, has two 5e
## saves, a primary stat that rolls highest, a weapon of its family at tier 1,
## its ability works in the numbers, and a mixed party of all six delves.
## Prints L4_TEST OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
const NEW := ["paladin", "necromancer", "monk", "druid", "warlock", "bard"]

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var cc := ChatCmd.new(_r)
	print("A: enlist, saves, stats, weapons")
	var i := 0
	for c in NEW:
		var uid := "n%d" % i
		var out := cc.handle(uid, "Hero%d" % i, "!enlist " + c)
		var h := _r.get_hero(uid)
		_ok(not h.is_empty() and String(h["class"]) == c, "!enlist %s: %s" % [c, out])
		if h.is_empty():
			continue
		_ok((Roster.SAVES.get(c, []) as Array).size() == 2, "%s saves %s (%s)" % [c, Roster.SAVES.get(c, []), _r.save_line(h)])
		var prim := String(Roster.CLASSES[c]["primary"])
		var best := 0
		for s in Roster.STATS:
			best = maxi(best, int(h["stats"][s]))
		# the best roll goes to the primary; a species bonus (up to +2) may lift another past it
		_ok(int(h["stats"][prim]) >= best - 2, "%s rolls best in %s" % [c, prim])
		h["weapon"] = 1
		var fam := String(Roster.CLASSES[c]["family"])
		_ok(Gear.kinds_of(fam).size() >= 2 and Gear.kinds_of(fam).has(String(Roster.CLASSES[c]["kind"])), "%s carries a %s (kinds %s)" % [c, _r.weapon_name(h), Gear.kinds_of(fam)])
		_ok(String(Roster.CLASSES[c].get("ability", "")) != "" and Roster.CLASSES[c].has("cape"), "%s has an ability (%s) and a cloak" % [c, Roster.CLASSES[c]["ability"]])
		i += 1
	print("B: abilities in the numbers")
	var pal: Dictionary = _r.get_hero("n0")
	var monk: Dictionary = _r.get_hero("n2")
	_ok(_r.heal_power(pal) > 0.0, "a paladin lays on hands (%.1f)" % _r.heal_power(pal))
	monk["armour"] = 0
	var plain := 10 + _r.mod(monk, "dex")
	_ok(_r.armour_class(monk) == plain + maxi(0, _r.mod(monk, "wis")), "a monk's unarmoured defence adds WIS (AC %d)" % _r.armour_class(monk))
	var d := Delve.new()
	d.roster = _r
	var undead := Monster.new()
	undead.def = Bestiary.make("minion")
	var beast := Monster.new()
	beast.def = Bestiary.make("rat")
	_ok(d._ability_mult("smite", undead) == 2.0 and d._ability_mult("smite", beast) == 1.0, "smite doubles on the dead only")
	_ok(d._ability_mult("flurry", beast) < 1.0, "a flurry hits light")
	beast.set_meta("hex_t", 99.0)
	_ok(d._ability_mult("", beast) > 1.0, "a hexed thing takes more from everyone")
	d.free()
	undead.free()
	beast.free()
	_ok(cc.handle("zz", "Nobody", "!enlist necromancer") != "" and _r.get_hero("zz")["class"] == "necromancer", "a fresh viewer can enlist a necromancer")
	print("C: a party of all six delves")
	var ids := []
	for k in range(6):
		var h := _r.get_hero("n%d" % k)
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 4
		ids.append("n%d" % k)
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = 3
	root.add_child(_d)
	_d.start(ids)

func _process(_dt: float) -> bool:
	_f += 1
	if _d == null:
		return false
	if _d.state == "home" or _f > 60 * 120:
		_ok(_d.state == "home", "the six came home or fell (state %s, floor %d, kills %d)" % [_d.state, _d.floor_no, _d._kills])
		_ok(_d._kills > 0, "they killed something")
		print("L4_TEST OK" if _fail == 0 else "L4_TEST FAIL %d" % _fail)
		return true
	return false
