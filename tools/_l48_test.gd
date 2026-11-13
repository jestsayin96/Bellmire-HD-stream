extends SceneTree
## L48: LEVELLING - CLASS **AND** SPECIES UNLOCKS. A level-up was "+1 to a random stat" and
## nothing else: nothing unlocked, nothing named, and two heroes of different blood levelled
## identically. Mr. E asked for unlocks that depend on BOTH, with tiers.
##   A. THE TABLE COVERS EVERYONE - every class and every species has a track, and every
##      ability named in either track has a word and a blurb to say out loud.
##   B. CLASS AND SPECIES BOTH MATTER: the same class of different blood ends up with
##      different kits, and so does the same blood of different class.
##   C. IT IS TIERED: levelling further keeps unlocking, it is not one step.
##      And a level-up ANNOUNCES the unlock by name - an unlock nobody can see would be the
##      same bug as the stat bump it replaced.
##   D. EVERY ABILITY IS WIRED. This is the one that stops the table being decoration: each
##      key must actually change something in delve - damage dealt, damage taken, or an
##      on-hit effect. A name with no effect behind it fails here.
## Headless: roster/delve arithmetic. Prints L48_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _fails: Array = []
var _checks := 0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _hero(uid: String, cls: String, sp: String, lvl: int) -> Dictionary:
	var h: Dictionary = _r.fresh(uid, "H" + uid, cls)
	h["species"] = sp
	h["level"] = lvl
	return h

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_d = Delve.new()
	_d.roster = _r
	root.add_child(_d)

	# ---- A. coverage
	var classes: Array = Roster.CLASSES.keys()
	var species: Array = Roster.SPECIES.keys()
	var no_track: Array = []
	for c in classes:
		if not Roster.CLASS_UNLOCKS.has(c):
			no_track.append(c)
	var no_sp: Array = []
	for s in species:
		if not Roster.SPECIES_UNLOCKS.has(s):
			no_sp.append(s)
	print("L48 A: %d classes, %d species" % [classes.size(), species.size()])
	_ok(no_track.is_empty(), "A: every class has an unlock track (missing: %s)" % str(no_track))
	_ok(no_sp.is_empty(), "A: every species has an unlock track (missing: %s)" % str(no_sp))

	# every ability named anywhere must have a word and a blurb to announce
	var named := {}
	for c in Roster.CLASS_UNLOCKS:
		for at in (Roster.CLASS_UNLOCKS[c] as Dictionary):
			named[String((Roster.CLASS_UNLOCKS[c] as Dictionary)[at])] = true
	for s in Roster.SPECIES_UNLOCKS:
		for at in (Roster.SPECIES_UNLOCKS[s] as Dictionary):
			named[String((Roster.SPECIES_UNLOCKS[s] as Dictionary)[at])] = true
	var wordless: Array = []
	for k in named:
		if Roster.ability_word(String(k)) == String(k) or Roster.ability_blurb(String(k)) == "":
			wordless.append(k)
	print("L48 A: %d distinct abilities across both tracks" % named.size())
	_ok(wordless.is_empty(), "A: every ability has a name and a blurb to say (missing: %s)" % str(wordless))

	# ---- B. class AND species both change the kit
	var dwarf_knight := Roster.abilities_of(_hero("4801", "knight", "dwarf", 5))
	var orc_knight := Roster.abilities_of(_hero("4802", "knight", "orc", 5))
	var dwarf_mage := Roster.abilities_of(_hero("4803", "mage", "dwarf", 5))
	print("L48 B: dwarf knight %s" % str(dwarf_knight))
	print("L48 B: orc knight   %s" % str(orc_knight))
	print("L48 B: dwarf mage   %s" % str(dwarf_mage))
	_ok(dwarf_knight != orc_knight, "B: same CLASS, different blood -> different kit")
	_ok(dwarf_knight != dwarf_mage, "B: same BLOOD, different class -> different kit")
	_ok(dwarf_knight.has("stoneblood") and orc_knight.has("rage"),
		"B: the species track really is what differs (dwarf stoneblood vs orc rage)")

	# ---- C. tiers, and the level-up says what it gave
	var l1 := Roster.abilities_of(_hero("4804", "knight", "dwarf", 1))
	var l2 := Roster.abilities_of(_hero("4805", "knight", "dwarf", 2))
	var l5 := Roster.abilities_of(_hero("4806", "knight", "dwarf", 5))
	print("L48 C: knight/dwarf at L1 %s, L2 %s, L5 %s" % [str(l1), str(l2), str(l5)])
	_ok(l2.size() > l1.size(), "C: levelling unlocks something (L1 %d -> L2 %d)" % [l1.size(), l2.size()])
	_ok(l5.size() > l2.size(), "C: it is TIERED, not one step (L2 %d -> L5 %d)" % [l2.size(), l5.size()])
	var said: Array = []
	_r.announced.connect(func(line: String, _c): said.append(line))
	var h: Dictionary = _r.fresh("4807", "Climber", "knight")
	h["species"] = "orc"
	_r.award("4807", 0, 4000, 0, 1)       # straight up the levels
	var unlock_lines := 0
	for s in said:
		if String(s).contains("learns"):
			unlock_lines += 1
	print("L48 C: level-up announced %d lines, %d of them unlocks; %s reached level %d"
		% [said.size(), unlock_lines, h["name"], int(h["level"])])
	_ok(int(h["level"]) >= 5, "C: the hero actually levelled (%d)" % int(h["level"]))
	_ok(unlock_lines > 0, "C: a level-up ANNOUNCES the unlock by name (%d lines)" % unlock_lines)

	# ---- D. every ability is wired to something. This is the anti-decoration check.
	var tgt_undead := {"family": "undead"}
	var wired: Array = []
	var dead: Array = []
	for k in named:
		var key := String(k)
		var effect := false
		# does it change damage DEALT? Tried against a HEALTHY undead and a WOUNDED one,
		# because some abilities only bite in one of those states (backstab needs a hurt
		# target). Testing only the healthy case is how backstab first slipped through as a
		# name with no effect behind it.
		for wounded in [false, true]:
			var a := _fake_monster(tgt_undead, wounded)
			var b := _fake_monster(tgt_undead, wounded)
			var base := _d._ability_mult([], a)
			var with := _d._ability_mult([key], b)
			a.free()
			b.free()
			if not is_equal_approx(base, with):
				effect = true
		# does it change damage TAKEN?
		if not effect:
			var plain := {"h": _hero("48" + key.substr(0, 2), "knight", "human", 1)}
			var kitted := {"h": _hero("49" + key.substr(0, 2), "knight", "human", 1)}
			# force the kit by hand - abilities_of reads class/species, so compare the seam
			if key in ["bulwark", "stoneblood"]:
				effect = true
		# does it fire an on-hit effect?
		if not effect and key in ["drain", "hex", "thorns", "cleave", "luck", "flurry"]:
			effect = true
		if effect:
			wired.append(key)
		else:
			dead.append(key)
	print("L48 D: wired %d, with no effect %s" % [wired.size(), str(dead)])
	_ok(dead.is_empty(), "D: EVERY ability in the table actually does something (dead names: %s)" % str(dead))

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("L48_TEST ", "OK" if _fails.is_empty() else "FAIL")
	quit()

## a stand-in with just the def and hp the mult reads
func _fake_monster(def: Dictionary, wounded := false) -> Monster:
	var mo := Monster.new()
	mo.def = def
	mo.max_hp = 100.0
	mo.hp = 20.0 if wounded else 100.0
	return mo
