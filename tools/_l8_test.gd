extends SceneTree
## L8: wild magic below. Misfire rates against the exact 5e odds for a strong and
## a weak caster, shallow and deep; nat 1 always, nat 20 never; the casting
## ability per calling; and misfires in a real delve. Prints L8_TEST OK.
var _fail := 0
var _d2: Delve
var _r2: Roster
var _f := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _expect(bonus: int, dc: int) -> float:
	var miss := 1
	for d in range(2, 20):
		if d + bonus < dc:
			miss += 1
	return float(miss) / 20.0

func _rate(d: Delve, m: Dictionary, fl: int, n: int) -> float:
	d.floor_no = fl
	var before := d.scar_misfires
	for i in n:
		d._scar_check(m, "bolt")
	return float(d.scar_misfires - before) / float(n)

func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)
	var d := Delve.new()
	d.roster = r
	d.town = null
	d._rng.randomize()
	var strong: Dictionary = r.fresh("s", "Strong", "mage", "human")
	strong["stats"]["int"] = 20
	strong["level"] = 9
	var weak: Dictionary = r.fresh("w", "Weak", "mage", "human")
	weak["stats"]["int"] = 8
	weak["level"] = 1
	var ms := {"uid": "s", "h": strong}
	var mw := {"uid": "w", "h": weak}
	print("A: rates vs the exact odds (12000 casts each)")
	for fl in [1, 6, 14, 30]:
		var dc := Delve.scar_dc(fl)
		for pair in [[ms, "strong"], [mw, "weak"]]:
			var m: Dictionary = pair[0]
			var b: int = r.mod(m["h"], "int") + r.prof(m["h"])
			var got := _rate(d, m, fl, 12000)
			var want := _expect(b, dc)
			_ok(absf(got - want) < 0.02, "floor %d DC %d, %s caster (+%d): misfire %.3f, expected %.3f" % [fl, dc, pair[1], b, got, want])
	_ok(Delve.scar_dc(40) == 20, "the DC caps at 20")
	print("B: the edges")
	var god: Dictionary = r.fresh("g", "God", "mage", "human")
	god["stats"]["int"] = 40
	_ok(absf(_rate(d, {"uid": "g", "h": god}, 1, 6000) - 0.05) < 0.015, "a natural 1 always misfires (an unbeatable caster still ~5%)")
	var dud: Dictionary = r.fresh("x", "Dud", "mage", "human")
	dud["stats"]["int"] = 1
	_ok(absf(_rate(d, {"uid": "x", "h": dud}, 30, 6000) - 0.95) < 0.015, "a natural 20 never misfires (a hopeless caster at DC 20 still ~95%)")
	print("C: the casting ability per calling")
	for cls in ["cleric", "warlock", "paladin", "druid", "necromancer", "sage"]:
		var h: Dictionary = r.fresh("c_" + cls, cls, cls, "human")
		for s in Roster.STATS:
			h["stats"][s] = 1
		var want := String(Delve.CAST_STAT[cls])
		h["stats"][want] = 40
		_ok(_rate(d, {"uid": "c_" + cls, "h": h}, 1, 2000) < 0.08, "%s casts on %s" % [cls, want.to_upper()])
	d.free()
	print("D: a real delve")
	_r2 = Roster.new()
	root.add_child(_r2)
	var ids := []
	for i in 4:
		var h: Dictionary = _r2.fresh("q%d" % i, "Caster%d" % i, ["mage", "cleric", "warlock", "sage"][i], "human")
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 5
		ids.append("q%d" % i)
	_d2 = Delve.new()
	_d2.roster = _r2
	_d2.start_floor = 6
	_d2.max_floors = 7
	root.add_child(_d2)
	_d2.start(ids)
	for m in _d2.party:
		m["max"] = float(m["max"]) * 4.0
		m["hp"] = m["max"]

func _process(_dt: float) -> bool:
	_f += 1
	if _d2 == null:
		return false
	if _d2.state == "home" or _f > 60 * 120:
		_ok(_d2.scar_casts > 10 and _d2.scar_misfires > 0, "spells were checked below: %d casts, %d misfired (DC %d)" % [_d2.scar_casts, _d2.scar_misfires, Delve.scar_dc(_d2.floor_no)])
		print("L8_TEST OK" if _fail == 0 else "L8_TEST FAIL %d" % _fail)
		return true
	return false
