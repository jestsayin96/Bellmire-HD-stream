extends SceneTree
## L19: more lore. Prints L19_TEST OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
var _feed: Array = []

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _all_strings(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			_all_strings(x, out)
	elif v is Dictionary:
		for k in v:
			_all_strings(v[k], out)

func _initialize() -> void:
	var L := Delve.lore()
	for o in FloorGen.ORIGINS:
		_ok(((L["tells"] as Dictionary).get(o, []) as Array).size() >= 2, "origin %s has tells" % o)
	for k in Bestiary.BOSS_DEFS:
		_ok((L["lord_intros"] as Dictionary).has(k), "lord %s has an intro" % k)
	for k in Bestiary.UNIQUES:
		_ok((L["unique_intros"] as Dictionary).has(k), "unique %s has an intro" % k)
	var strs: Array = []
	_all_strings(L, strs)
	var rx := RegEx.new()
	rx.compile("(?i)(\\d+\\s+floors|floor count|last floor|final floor|bottom of the dungeon)")
	var bad: Array = strs.filter(func(s): return rx.search(String(s)) != null and not String(s).begins_with("L19"))
	_ok(bad.is_empty(), "no line states a floor count (%d lines checked) %s" % [strs.size(), bad])
	_r = Roster.new()
	root.add_child(_r)
	_r.fresh("e1", "Edda", "knight", "human")
	_r.get_hero("e1")["gold"] = 999
	var out := _r.buy_weapon("e1", "")
	_ok(out.contains("Bellmire iron"), "the forge has a word: %s" % out)
	_r.kill("e1", "the dark below", 4, 1)
	_ok(String(_r.fallen[0].get("epitaph", "")) != "", "the fallen carry an epitaph: %s" % _r.fallen[0]["epitaph"])
	var cc := ChatCmd.new(_r)
	out = cc.handle("x", "X", "!memorial")
	_ok(out.contains(String(_r.fallen[0]["epitaph"])), "!memorial reads it: %s" % out)
	var ids := []
	for i in 3:
		var h: Dictionary = _r.fresh("q%d" % i, "D%d" % i, ["knight", "cleric", "barbarian"][i], "human")
		h["weapon"] = 3
		h["armour"] = 3
		h["oil"] = 6
		ids.append("q%d" % i)
	Bestiary._spent = Bestiary.LESSER.duplicate()
	Bestiary._spent.erase("grubmother")
	var town := Node3D.new()
	town.set("feed", [])
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = 4
	_d.max_floors = 5
	root.add_child(_d)
	_d.start(ids)

func _process(_dt: float) -> bool:
	_f += 1
	if _d == null:
		return false
	if _d.state == "home" or _f > 60 * 150:
		print("ended ", _d.state, " floor ", _d.floor_no)
		print("L19_TEST checks in the FEED lines above (tell on floor 4 only, the Grubmother's intro)")
		return true
	return false
