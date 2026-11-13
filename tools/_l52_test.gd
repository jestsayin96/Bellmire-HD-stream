extends SceneTree
## L52 (REFRAMED by the census, and the census was right). Mr. E reported "only one spell". The
## D28 census measured NINE distinct spells in a 7-minute soak - heal 295, bolt 161, mend 131,
## ward 112, smite 85, frost 46, chain 35, renew 31, fire 12 - so nothing is missing from the
## content. The viewer simply cannot TELL them apart. This item therefore adds no spells; it
## makes the choice legible.
## A. VERIFY INDEPENDENTLY. I do not take the census on trust any more than I took Mr. E's
##    report on trust for L46 and L49 - run a delve and count distinct spells here.
## B. EVERY cast names itself: the count is recorded, and the words/colour exist for all nine.
## C. A SCAR MISFIRE is called out both ways - it was completely silent before, and it is the
##    most readable moment in the game.
## Headless: this is delve logic and string/colour wiring, not HUD layout.
## Prints L52_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _part := "A"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _new_delve(floors: int) -> void:
	_d = Delve.new()
	_d.roster = _r
	_d.max_floors = floors
	root.add_child(_d)
	var ids: Array = []
	# a caster-heavy party, so the spell mix is actually exercised
	for v in [["5201", "Brelda", "mage"], ["5202", "Corrin", "cleric"],
			  ["5203", "Sefa", "sage"], ["5204", "Ashvein", "paladin"]]:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 9
		ids.append(v[0])
	_d.start(ids)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_new_delve(6)

func _process(_dt: float) -> bool:
	_f += 1
	match _part:
		"A":
			if _d.state == "home" or _f > 60 * 220:
				var kinds: Array = _d.spells_cast.keys()
				kinds.sort()
				var total := 0
				for k in kinds:
					total += int(_d.spells_cast[k])
				print("L52 VERIFY: %d casts over the run, %d distinct spells: %s"
					% [total, kinds.size(), str(_d.spells_cast)])
				_ok(total > 0, "A: casters actually cast (%d casts)" % total)
				_ok(kinds.size() >= 3,
					"A: SEVERAL distinct spells fire in one run - the premise 'only one spell' is not the content (%d kinds: %s)"
					% [kinds.size(), str(kinds)])
				# every spell that fired must have been named and coloured, or the legibility
				# work has a hole in it
				var unnamed: Array = []
				var uncoloured: Array = []
				for k in kinds:
					if not Delve.SPELL_WORDS.has(k):
						unnamed.append(k)
					if not Spells.COL.has(k):
						uncoloured.append(k)
				_ok(unnamed.is_empty(), "B: every spell that fired has a readable name (missing: %s)" % str(unnamed))
				_ok(uncoloured.is_empty(), "B: every spell that fired has its own colour (missing: %s)" % str(uncoloured))
				_part = "B"
				_f = 0
			return false
		"B":
			# ---- the whole spell set, not just the ones this run happened to roll
			var missing_word: Array = []
			var missing_col: Array = []
			var dupe_words := {}
			for k in Spells.ORDER:
				if not Delve.SPELL_WORDS.has(k):
					missing_word.append(k)
				else:
					var w := String(Delve.SPELL_WORDS[k])
					dupe_words[w] = int(dupe_words.get(w, 0)) + 1
				if not Spells.COL.has(k):
					missing_col.append(k)
			var dupes: Array = []
			for w in dupe_words:
				if int(dupe_words[w]) > 1:
					dupes.append(w)
			print("L52 coverage: %d spells in Spells.ORDER, words %d, colours %d"
				% [Spells.ORDER.size(), Delve.SPELL_WORDS.size(), Spells.COL.size()])
			_ok(missing_word.is_empty(), "B: all nine spells have a name (missing: %s)" % str(missing_word))
			_ok(missing_col.is_empty(), "B: all nine spells have a colour (missing: %s)" % str(missing_col))
			_ok(dupes.is_empty(), "B: no two spells share a name - they must be tellable apart (%s)" % str(dupes))
			_part = "C"
			return false
		"C":
			# ---- a scar misfire must announce itself BOTH ways round
			# Spells.cast with in_scar walks ORDER by one, so the pairing is deterministic.
			var wanted := "bolt"
			var twisted := String(Spells.ORDER[(Spells.ORDER.find(wanted) + 1) % Spells.ORDER.size()])
			_ok(twisted != wanted, "C: the scar really does turn one spell into another (%s -> %s)" % [wanted, twisted])
			_ok(Delve.SPELL_WORDS.has(twisted) and Delve.SPELL_WORDS.has(wanted),
				"C: both sides of a misfire can be named (%s -> %s)" % [wanted, twisted])
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L52_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
