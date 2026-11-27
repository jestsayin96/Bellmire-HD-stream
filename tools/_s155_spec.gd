extends SceneTree
## S155: SYSTEM 40 - CLASS SPECIALIZATION, engine half (roster.gd). Headless. Prints
## S155_SPEC OK / FAIL. Every calling splits two ways; a path is chosen once at SPEC_AT and is
## permanent; it hands over a gift at 10, 15 and 20; each gift is a real ability that changes a
## number in delve; the name replaces the calling on the sheet; and the choice survives a save.
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

	# ---- A. the tree covers every calling, two roads each, no name collides with a calling
	var missing: Array = []
	var bad_count: Array = []
	var collide: Array = []
	var seen := {}
	var dup: Array = []
	for c in Roster.CLASSES:
		if not Roster.SPECS.has(c):
			missing.append(c)
			continue
		var opts: Dictionary = Roster.SPECS[c]
		if opts.size() != 2:
			bad_count.append(c)
		for k in opts:
			if Roster.CLASSES.has(k) or Roster.CLASSES.has(String(opts[k]["name"]).to_lower()):
				collide.append(k)
			if seen.has(k):
				dup.append(k)
			seen[k] = true
	print("S155 A: %d callings, %d paths" % [Roster.CLASSES.size(), seen.size()])
	_ok(missing.is_empty(), "A: every calling has paths (missing %s)" % str(missing))
	_ok(bad_count.is_empty(), "A: every calling splits exactly two ways (%s)" % str(bad_count))
	_ok(collide.is_empty(), "A: no path name is also a calling (%s)" % str(collide))
	_ok(dup.is_empty(), "A: path keys are unique across callings (%s)" % str(dup))

	# ---- B. every gift is a named ability, three per path, none already in the calling's kit
	var unnamed: Array = []
	var redundant: Array = []
	var short: Array = []
	for c in Roster.SPECS:
		var kit := {}
		var base := String(Roster.CLASSES[c].get("ability", ""))
		if base != "":
			kit[base] = true
		for at in (Roster.CLASS_UNLOCKS.get(c, {}) as Dictionary):
			kit[String(Roster.CLASS_UNLOCKS[c][at])] = true
		for k in Roster.SPECS[c]:
			var g: Array = Roster.SPECS[c][k]["gifts"]
			if g.size() != Roster.SPEC_GIFTS_AT.size():
				short.append(k)
			for x in g:
				if Roster.ability_word(String(x)) == String(x) or Roster.ability_blurb(String(x)) == "":
					unnamed.append("%s:%s" % [k, x])
				if kit.has(String(x)):
					redundant.append("%s:%s" % [k, x])
	_ok(short.is_empty(), "B: every path has three gifts (%s)" % str(short))
	_ok(unnamed.is_empty(), "B: every gift has a word and a blurb (%s)" % str(unnamed))
	_ok(redundant.is_empty(), "B: no gift repeats the calling's own kit (%s)" % str(redundant))

	# ---- C. the gate, the gifts by level, and the announcement seam
	var h: Dictionary = _r.fresh("15501", "Tess", "knight", "human")
	h["level"] = 9
	var said := _r.specialize("15501", "crusader")
	_ok(Roster.spec_of(h) == "", "C: refused below level %d -> %s" % [Roster.SPEC_AT, said])
	h["level"] = 10
	var before := Roster.abilities_of(h)
	said = _r.specialize("15501", "crusader")
	print("  said: ", said)
	_ok(Roster.spec_of(h) == "crusader", "C: chosen at level 10")
	var after := Roster.abilities_of(h)
	_ok(after.has("smite") and not before.has("smite"), "C: first gift (smite) arrives with the choice")
	_ok(not after.has("backstab"), "C: the third gift is NOT given early")
	_ok(Roster.unlocked_at(h, 15).has("rage"), "C: level 15 announces the second gift (%s)" % str(Roster.unlocked_at(h, 15)))
	_ok(Roster.unlocked_at(h, 20).has("backstab"), "C: level 20 announces the third gift")
	_ok(not Roster.unlocked_at(h, 10).has("smite"), "C: level 10 does not re-announce the first gift")
	h["level"] = 20
	var full := Roster.abilities_of(h)
	_ok(full.has("smite") and full.has("rage") and full.has("backstab"), "C: level 20 holds all three (%s)" % str(full))

	# ---- D. permanence and the name
	said = _r.specialize("15501", "guardian")
	_ok(Roster.spec_of(h) == "crusader", "D: a second choice is refused -> %s" % said)
	said = _r.respec("15501", "rogue", true)
	_ok(String(h["class"]) == "knight" and Roster.spec_of(h) == "crusader", "D: retrain refused once on a path -> %s" % said)
	_ok(Roster.calling_of(h) == "Crusader", "D: called Crusader, not knight")
	_ok(_r.describe("15501").find("Crusader") >= 0, "D: !me sheet reads the path name")
	var h2: Dictionary = _r.fresh("15502", "Odo", "rogue", "elf")
	h2["level"] = 12
	said = _r.specialize("15502", "pyromancer")
	_ok(Roster.spec_of(h2) == "" and said.find("Shadow") >= 0, "D: an unknown road is refused and names the real two -> %s" % said)
	_ok(_r.paths_line("15502").find("Tracker") >= 0, "D: !paths reads both roads -> %s" % _r.paths_line("15502"))
	h2["spec"] = "guardian"   # a key from another calling's tree must not count
	_ok(Roster.spec_of(h2) == "", "D: a path from another calling is ignored")

	# ---- E. the gift changes a number in delve (crusader smite vs the dead)
	var dead_thing := Monster.new()
	dead_thing.def = {"family": "undead"}
	dead_thing.max_hp = 100.0
	dead_thing.hp = 100.0
	var plain: Dictionary = _r.fresh("15503", "Pell", "knight", "human")
	plain["level"] = 10
	var k_plain := _d._ability_mult(Roster.abilities_of(plain), dead_thing)
	var k_spec := _d._ability_mult(Roster.abilities_of(h), dead_thing)
	_ok(k_spec > k_plain * 1.5, "E: a Crusader hits the dead harder in delve (%.2f vs %.2f)" % [k_spec, k_plain])
	dead_thing.free()

	# ---- F. the choice survives the save format
	var back: Variant = JSON.parse_string(JSON.stringify(h))
	_ok(typeof(back) == TYPE_DICTIONARY and Roster.spec_of(back) == "crusader", "F: spec survives a JSON round-trip")

	print("CHECKS ", _checks, " FAILS ", _fails.size())
	for x in _fails:
		print("  - ", x)
	print("S155_SPEC ", "OK" if _fails.is_empty() else "FAIL")
	quit()
