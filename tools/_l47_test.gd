extends SceneTree
## L47 (Mr. E marked this the PRIORITY): ADVENTURERS MUST THINK FOR THEMSELVES. Delvers read as
## mindless - they must make decisions a VIEWER CAN SEE, and the Chronicle must say why.
## Headless on purpose: this is delve LOGIC, not HUD layout (COORDINATION 4 sends UI windowed).
## Three parts, each a thing Mr. E actually asked for:
##   A. A SOAK: over several floors the party takes a RANGE of real decisions (not one kind
##      firing over and over), every one of them announced in the Chronicle with its reason.
##   B. A HURT PARTY RETREATS RATHER THAN DYING IN PLACE - the DONE criterion, scripted rather
##      than waited for: the party is slammed to near death mid-fight with foes still up, and
##      must break off, run for the way up, and come home with survivors.
##   C. TARGETS MAKE SENSE: a wounded foe further away is chosen over a healthy nearer one.
## Prints L47_TEST OK / FAIL.
var _r: Roster
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _part := "A"
var _feed: Array = []
var _soak_kinds := {}
var _soak_decisions := 0
var _b_hurt := false        # reused by part D (reset between parts)
var _b_saw_flee := false
var _b_survivors := -1
var _c_done := false

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
	var V := [["4701", "Ashvein", "knight"], ["4702", "Brelda", "mage"],
			  ["4703", "Corrin", "cleric"], ["4704", "Dunmar", "barbarian"]]
	var ids: Array = []
	for v in V:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 9
		ids.append(v[0])
	_d.start(ids)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_new_delve(5)

func _drop() -> void:
	if _d != null and is_instance_valid(_d):
		_d.queue_free()

func _process(_dt: float) -> bool:
	_f += 1
	match _part:
		"A":
			# ---- A. the soak: let a real delve run and watch what the party decides
			for k in _d.decided.keys():
				_soak_kinds[k] = int(_d.decided[k])
			_soak_decisions = maxi(_soak_decisions, _d.decisions)
			if _d.state == "home" or _f > 60 * 150:
				print("L47 soak decisions=%d kinds=%s" % [_soak_decisions, str(_soak_kinds)])
				_ok(_soak_decisions > 0, "A: the party made decisions over a soak (%d)" % _soak_decisions)
				_ok(_soak_kinds.size() >= 2,
					"A: a RANGE of decisions, not one kind repeating (%d kinds: %s)" % [_soak_kinds.size(), str(_soak_kinds.keys())])
				_drop()
				_part = "B"
				_f = 0
				_new_delve(5)
			return false
		"B":
			# ---- B. a hurt party must RETREAT, not die in place
			if not _b_hurt:
				# wait for a real fight with foes up, then take them to the brink
				if _d.state == "fight" and _d.dun != null and _d._foes().size() > 0 and _d._alive().size() >= 2:
					for m in _d._alive():
						m["hp"] = float(m["max"]) * 0.10
					_b_hurt = true
					print("L47 part B: party slammed to 10%% hp with %d foes up" % _d._foes().size())
				elif _f > 60 * 120:
					_ok(false, "B: never reached a fight to test the retreat")
					_drop()
					_part = "C"
					_f = 0
					_new_delve(3)
				return false
			if _d.state == "flee":
				_b_saw_flee = true
			if _d.state == "home" or _f > 60 * 150:
				_b_survivors = _d._alive().size()
				_ok(_b_saw_flee, "B: the hurt party BROKE OFF the fight (state 'flee' was entered)")
				_ok(int(_d.decided.get("party_retreat", 0)) > 0, "B: the retreat was announced in the Chronicle")
				_ok(_b_survivors > 0, "B: they retreated rather than dying in place (%d survivors)" % _b_survivors)
				_drop()
				_part = "C"
				_f = 0
				_new_delve(3)
			return false
		"C":
			# ---- C. a target chosen on sense: wound a FAR foe and it should be preferred
			if _c_done:
				_drop()
				_part = "D"
				_f = 0
				_b_hurt = false          # part D does its own hurting
				_new_delve(3)
				return false
			if _d.state == "fight" and _d.dun != null and _d._alive().size() > 0:
				var foes := _d._foes()
				if foes.size() >= 2:
					var b: Node3D = _d._alive()[0]["body"]
					# sort by distance so we can wound the FURTHER one
					var sorted := foes.duplicate()
					sorted.sort_custom(func(x, y):
						return (x as Node3D).global_position.distance_to(b.global_position) \
							 < (y as Node3D).global_position.distance_to(b.global_position))
					var near_foe: Monster = sorted[0]
					var far_foe: Monster = sorted[sorted.size() - 1]
					near_foe.hp = near_foe.max_hp                   # healthy and close
					far_foe.hp = far_foe.max_hp * 0.15              # nearly down, further off
					var pick := _d._pick_target(b, foes)
					_ok(pick == far_foe,
						"C: the wounded foe further off is chosen over the healthy near one (picked %s)"
						% [String(pick.def.get("name", "?")) if pick != null else "nothing"])
					_c_done = true
			if _f > 60 * 120 and not _c_done:
				_ok(false, "C: never reached a fight with two foes to test targeting")
				_c_done = true
			return false
		"D":
			# ---- D. ONE hero breaking off alone. Part B can never reach this: there the whole
			# party is dying, so the PARTY-level retreat fires first and returns before any
			# individual thinks. So hurt exactly one delver, with no brew to fall back on, and
			# leave the rest healthy - the party stays and fights, that one gets out.
			if not _b_hurt:
				if _d.state == "fight" and _d.dun != null and _d._foes().size() > 0 and _d._alive().size() >= 3:
					var victim: Dictionary = _d._alive()[0]
					victim["hp"] = float(victim["max"]) * 0.08
					for k in Delve.HEAL_ORDER:            # strip the brews: no way out but out
						var n := _r.brew_count(victim["h"], k)
						if n > 0:
							_r.add_brew(victim["h"], k, -n)
					_b_hurt = true
					print("L47 part D: %s at 8%% hp, no brews, %d allies healthy"
						% [victim["h"]["name"], _d._alive().size() - 1])
				elif _f > 60 * 120:
					_ok(false, "D: never reached a fight to test one hero breaking off")
					_c_done = false
					_part = "END"
				return false
			if int(_d.decided.get("flee", 0)) > 0:
				_ok(true, "D: the lone hurt delver broke off and ran for the way up")
				_ok(not _d._alive().is_empty(), "D: they were still alive when they ran (%d up)" % _d._alive().size())
				_part = "END"
			elif _d.state == "home" or _f > 60 * 150:
				_ok(false, "D: the lone hurt delver never broke off (decided=%s)" % str(_d.decided))
				_part = "END"
			return false
		"END":
			print("L47 decisions seen across all parts: ", _d.decided if _d != null and is_instance_valid(_d) else {})
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L47_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
