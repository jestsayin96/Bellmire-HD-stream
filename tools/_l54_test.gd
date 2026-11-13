extends SceneTree
## L54 (raised by the content writer): Scarwater displays and does nothing.
## VERIFIED BEFORE WRITING A LINE, the way L46 and L52 were: data/potions.json has given the
## state "scar_touched" for a while - Scarwater, tier 4, 300 gold, 20 s, "its next spell is
## doubled - or misfires; the scar decides" - and the only scar_touched anywhere in scripts/ was
## fishing.gd's unrelated scar_touched_chance. The draught was bought, drunk, shown on the hero
## and did exactly nothing.
##   A. THE DATA still says what we are implementing (read from potions.json, not from memory):
##      Scarwater gives scar_touched, and the state is declared.
##   B. DRINKING IT applies the state.
##   C. THE SCAR DECIDES: over many casts a scar-touched hero gets BOTH outcomes - doubled and
##      taken - and the state is SPENT either way, never lingering for a second free cast.
##   D. A hero WITHOUT the state is untouched by any of it.
## Headless: delve/roster logic. Prints L54_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_d = Delve.new()
	_d.roster = _r
	root.add_child(_d)

	# ---- A. what does the DATA actually promise?
	var f := FileAccess.open("res://data/potions.json", FileAccess.READ)
	var gives := ""
	var has_state := false
	var secs := 0.0
	if f != null:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary:
			var d: Dictionary = j
			for sect in d.keys():
				var s = d[sect]
				if s is Dictionary and (s as Dictionary).has("scarwater"):
					var sw: Dictionary = (s as Dictionary)["scarwater"]
					gives = String(sw.get("gives", ""))
					secs = float(sw.get("secs", 0.0))
				if s is Dictionary and (s as Dictionary).has("scar_touched"):
					has_state = true
	print("L54 A: potions.json - scarwater gives '%s' for %.0fs; state declared: %s" % [gives, secs, str(has_state)])
	_ok(gives == "scar_touched", "A: Scarwater still gives scar_touched in the data ('%s')" % gives)
	_ok(has_state, "A: the scar_touched state is declared in the data")

	# ---- B. drinking it applies the state
	var h: Dictionary = _r.fresh("5401", "Sefa", "mage")
	var body := Node3D.new()
	root.add_child(body)
	var m := {"uid": "5401", "h": h, "hp": 60.0, "max": 60.0, "swing": 0.0, "saved": false, "st": {}, "body": body}
	_r.add_brew(h, "scarwater", 2)
	_d.drink(m, "scarwater")
	_ok(_d.has_st(m, "scar_touched"), "B: drinking Scarwater applies scar_touched")

	# ---- C. the scar decides, and the draught is SPENT either way
	var doubled := 0
	var taken := 0
	var lingered := 0
	for i in 60:
		m["st"] = {"scar_touched": 99.0}        # scar-touched again for this cast
		m["scar_double"] = false
		var misfired := _d._scar_check(m, "bolt")
		if misfired:
			taken += 1
		elif bool(m.get("scar_double", false)):
			doubled += 1
		# whichever way it fell, the state must be GONE - otherwise one draught would buy a
		# doubled spell every cast for its whole 20 seconds
		if _d.has_st(m, "scar_touched"):
			lingered += 1
	print("L54 C: over 60 scar-touched casts - doubled %d, taken by the scar %d, state lingered %d"
		% [doubled, taken, lingered])
	_ok(doubled > 0, "C: the scar DOUBLES some casts (%d of 60)" % doubled)
	_ok(taken > 0, "C: the scar TAKES some casts (%d of 60)" % taken)
	_ok(doubled + taken == 60, "C: every scar-touched cast is decided one way or the other (%d of 60)" % [doubled + taken])
	_ok(lingered == 0, "C: the draught is SPENT on one cast - the state never lingers (%d lingered)" % lingered)
	_ok(_d.scar_touched_spells >= 60, "C: the casts are counted for a census (%d)" % _d.scar_touched_spells)
	_ok(_d.scar_doubles == doubled, "C: the doubles are counted too (%d)" % _d.scar_doubles)

	# ---- D. a hero without the draught is untouched by any of this
	var h2: Dictionary = _r.fresh("5402", "Plain", "mage")
	var body2 := Node3D.new()
	root.add_child(body2)
	var m2 := {"uid": "5402", "h": h2, "hp": 60.0, "max": 60.0, "swing": 0.0, "saved": false, "st": {}, "body": body2}
	var before_touched := _d.scar_touched_spells
	for i in 20:
		m2["scar_double"] = false
		_d._scar_check(m2, "bolt")
		if bool(m2.get("scar_double", false)):
			_ok(false, "D: a hero WITHOUT Scarwater was given a doubled spell")
			break
	_ok(_d.scar_touched_spells == before_touched,
		"D: a hero without the draught never enters the scar-touched path (%d unchanged)" % before_touched)

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L54_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()
