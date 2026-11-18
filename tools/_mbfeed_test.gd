extends SceneTree
## MBFEED_TEST - the miniboss_feed READER (game build, 16 Nov).
## data/lore_lines.json carries feed lines for all fourteen art-lane minibosses
## (miniboss_feed.by_key[key][arrive|act|broken|fall]); this gate proves the game
## READS them: every floorgen theme maps to one key (dungeon_hd THEME_MINIBOSS),
## every key has all four phases, a miniboss set piece carries its key, and a
## real spawn + kill writes an arrive line and a fall line FROM THE POOL to the feed.
## Headless. Run: <console> --headless --path . --script tools/_mbfeed_test.gd

var _fails: Array = []
var _checks := 0
var _r: Roster
var _done := false

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

func _process(_dt: float) -> bool:
	if _done:
		return true
	_done = true
	print("MBFEED A: the map and the pool")
	var themes: Array = FloorGen.all_themes().keys()
	var keys := {}
	for t in themes:
		var k := String(DungeonHD.THEME_MINIBOSS.get(t, ""))
		_ok(k != "", "theme %s maps to a miniboss key (%s)" % [t, k])
		keys[k] = true
	_ok(keys.size() == 14, "fourteen distinct keys (%d)" % keys.size())
	for k in keys:
		for ph in ["arrive", "act", "broken", "fall"]:
			var n := Delve.miniboss_lines(String(k), ph).size()
			_ok(n > 0, "%s.%s readable (%d lines)" % [k, ph, n])

	print("MBFEED B: a real spawn and kill")
	var dh := DungeonHD.new()
	root.add_child(dh)
	var sp: Dictionary = {}
	var fn := -1
	for f in range(4, 120):
		dh.floor_no = f
		dh.build(f)
		var sps: Array = dh.info.get("set_pieces", [])
		if not sps.is_empty() and String((sps[0] as Dictionary).get("kind", "")) == "miniboss":
			sp = sps[0]; fn = f
			break
	_ok(fn > 0, "a floor with a miniboss set piece (floor %d)" % fn)
	if fn < 0:
		return _finish()
	var key := String(sp.get("mb_key", ""))
	var theme := String(dh.info.get("theme", ""))
	_ok(key == DungeonHD.miniboss_for(theme, fn), "set piece carries its theme's key (%s on %s)" % [key, theme])   # S32: the theme's draw, which is THEME_MINIBOSS until a second candidate has lines
	var fake := GDScript.new()
	fake.source_code = "extends Node3D\nvar feed := []\n"
	fake.reload()
	var town := Node3D.new()
	town.set_script(fake)
	root.add_child(town)
	var d := Delve.new()
	d.roster = _r
	d.floor_no = fn
	d.town = town
	root.add_child(d)
	d.dun = dh
	var h: Dictionary = _r.fresh("mbf1", "Hunter", "knight")
	var b := HeroBody.new()
	b.setup(_r, "mbf1")
	b.town = d
	b.stay = true
	d.add_child(b)
	b.global_position = sp["pos"]
	d.party = [{"uid": "mbf1", "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0}]
	Delve.setpieces_fired.clear()
	d._setpieces_tick()
	var feed: Array = town.get("feed")
	var arrive: Array = Delve.miniboss_lines(key, "arrive")
	_ok(not feed.is_empty() and arrive.has(feed[0]), "first feed line is an arrive line from the pool: %s" % [feed[0] if not feed.is_empty() else "<none>"])
	var spawned: Monster = (dh.monsters as Array).back()
	_ok(String(spawned.def.get("name", "")) == key.capitalize(), "the elite carries the miniboss's name (%s)" % spawned.def.get("name", ""))
	_ok(feed.size() >= 2 and String(feed[1]).begins_with("The " + key.capitalize() + " holds"), "hold line names it: %s" % [feed[1] if feed.size() > 1 else "<none>"])
	var n0 := feed.size()
	spawned.hp = 0
	spawned.state = Monster.S.DEAD
	d._on_kill(spawned)
	var tail := feed.slice(n0)
	var fall: Array = Delve.miniboss_lines(key, "fall")
	var has_fall := false
	for l in tail:
		if fall.has(l):
			has_fall = true
	_ok(has_fall, "a fall line from the pool on the kill")
	_ok(int(Delve.setpieces_fired.get("miniboss_feed_arrive", 0)) == 1 and int(Delve.setpieces_fired.get("miniboss_feed_fall", 0)) == 1, "arrive and fall each counted once")
	_ok(int(Delve.setpieces_fired.get("miniboss_down", 0)) == 1, "the purse still pays (miniboss_down)")
	var joined := " | ".join(PackedStringArray(feed.map(func(x): return String(x))))
	_ok(not joined.contains("{name}"), "no unfilled {name}")
	print("  FEED: " + joined)
	return _finish()

func _finish() -> bool:
	if _checks < 80:  ## S11: measured 80; fewer means something stopped being checked
		_fails.append("check floor: %d checks is under 80" % _checks)
	if _fails.is_empty():
		print("MBFEED_TEST OK %d checks" % _checks)
	else:
		print("MBFEED_TEST FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
	quit(0 if _fails.is_empty() else 1)
	return true
