extends SceneTree
## L49 (Mr. E: "no chests, no drops, nobody searching"). The loot ROLL already existed - it fired
## invisibly the instant a floor was cleared, with no chest, nobody walking anywhere and nothing
## to watch. This checks the thing he actually asked for: something physical to search, a delver
## visibly doing it, and BOTH outcomes reading out in his words.
##   A. CHESTS EXIST and are placed on floors.
##   B. A DELVER VISIBLY SEARCHES: the delve enters the "search" state, the seeker goes to the
##      chest, and the chest is opened (its lid tween fires) rather than looted from thin air.
##   C. BOTH OUTCOMES, in his words: "Successfully found loot!!" and "...no loot...". Driven over
##      many rolls so neither is a fluke, and a find must actually pay gold.
## Headless: delve logic. The Chronicle lines print as FEED ... - they are the capture evidence.
## Prints L49_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _part := "A"
var _saw_search_state := false
var _saw_seeker_near := false
var _lid_opened := 0
var _chests_seen := 0

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
	for v in [["4901", "Ashvein", "knight"], ["4902", "Brelda", "mage"],
			  ["4903", "Corrin", "cleric"], ["4904", "Dunmar", "barbarian"]]:
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
			if _d.dun != null and _d.dun.info.has("chests"):
				_chests_seen = maxi(_chests_seen, (_d.dun.info["chests"] as Array).size())
			if _d.state == "search":
				_saw_search_state = true
				# is the seeker actually walking to the chest, or is loot still teleporting in?
				for cd in _d.dun.info.get("chests", []):
					var c: Dictionary = cd
					if not is_instance_valid(c["node"]):
						continue
					for m in _d._alive():
						var b = m["body"]
						if is_instance_valid(b) and \
								(b as Node3D).global_position.distance_to((c["node"] as Node3D).global_position) < 2.2:
							_saw_seeker_near = true
					# the lid tween only runs once the search finishes
					var lid = (c["node"] as Node3D).get_node_or_null("lid")
					if lid != null and absf((lid as Node3D).rotation.x) > 0.2:
						_lid_opened = maxi(_lid_opened, 1)
			if _d.state == "home" or _f > 60 * 200:
				print("L49 soak: chests on a floor %d, search state seen %s, seeker reached a chest %s, "
					% [_chests_seen, str(_saw_search_state), str(_saw_seeker_near)]
					+ "found %d, empty %d, lid opened %d" % [_d.chests_found, _d.chests_empty, _lid_opened])
				_ok(_chests_seen > 0, "A: chests are placed on the floors (%d on one floor)" % _chests_seen)
				_ok(_saw_search_state, "B: the delve entered the SEARCH state - the party stops to look")
				_ok(_saw_seeker_near, "B: a delver actually walked to the chest (within 2.2 m)")
				_ok(_d.chests_found + _d.chests_empty > 0,
					"B: chests were searched (%d found, %d empty)" % [_d.chests_found, _d.chests_empty])
				_ok(_lid_opened > 0, "B: the chest visibly OPENS when the search finishes")
				_part = "C"
				_f = 0
			return false
		"C":
			# ---- both outcomes, over enough rolls that neither is luck, and a find pays gold
			if _d.dun == null:
				_part = "END"
				return false
			var found := 0
			var empty := 0
			var paid := 0
			var m: Dictionary = _d._alive()[0] if not _d._alive().is_empty() else {}
			if m.is_empty():
				_ok(false, "C: no delver left alive to search with")
				_part = "END"
				return false
			var before_found := _d.chests_found
			var before_empty := _d.chests_empty
			for i in 80:
				var node := DungeonParts.chest()
				_d.dun.add_child(node)
				var cd := {"node": node, "searched": false}
				var g0 := int(_r.get_hero(String(m["uid"])).get("gold", 0))
				var f0 := _d.chests_found
				_d._open_chest(m, cd)
				if _d.chests_found > f0:
					found += 1
					if int(_r.get_hero(String(m["uid"])).get("gold", 0)) > g0:
						paid += 1
				else:
					empty += 1
				node.queue_free()
			print("L49 outcomes over 80 searches: found %d (paid gold %d), empty %d" % [found, paid, empty])
			_ok(found > 0, "C: \"Successfully found loot!!\" happens (%d of 80)" % found)
			_ok(empty > 0, "C: \"...no loot...\" happens too - not every chest pays (%d of 80)" % empty)
			_ok(paid == found, "C: every find actually awarded gold (%d of %d)" % [paid, found])
			_ok(_d.chests_found - before_found == found and _d.chests_empty - before_empty == empty,
				"C: both outcomes are counted for the census (found +%d, empty +%d)"
				% [_d.chests_found - before_found, _d.chests_empty - before_empty])
			_part = "END"
			return false
		"END":
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L49_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
