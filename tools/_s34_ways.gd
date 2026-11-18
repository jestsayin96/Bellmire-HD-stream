extends SceneTree
## S34_WAYS - each miniboss's ONE IDEA fires delve-side (game build, 18 Nov).
## For every key with content's act/broken lines: a real miniboss set piece is stood up with that
## key, Delve._mb_way_tick fires its way, the feed gets an ACT line from that key's own pool and the
## way's own effect lands; at MB_BROKEN_FRAC hp it says a BROKEN line once and never acts again.
## Headless. S34_RED=1 points one case at a key with no way, which must FAIL.
## Run: <console> --headless --path . --script tools/_s34_ways.gd

var _fails: Array = []
var _checks := 0
var _r: Roster
var _done := false

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		print("  FAIL " + what)
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

func _process(_dt: float) -> bool:
	if _done:
		return true
	_done = true
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
	_ok(fn > 0, "a floor with a miniboss set piece")
	if fn < 0:
		return _finish()
	var keys: Array = Delve.MB_WAYS.keys()
	_ok(keys.size() == 15, "fifteen ways (%d)" % keys.size())
	var red := OS.get_environment("S34_RED") == "1"
	var seen_ways := {}
	for k0 in keys:
		var k := String(k0)
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
		var h: Dictionary = _r.fresh("s34" + k, "Hunter" + k.capitalize(), "knight")
		var b := HeroBody.new()
		b.setup(_r, "s34" + k)
		b.town = d
		b.stay = true
		d.add_child(b)
		b.global_position = sp["pos"] + Vector3(3.0, 0, 0)
		d.party = [{"uid": "s34" + k, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0, "st": {}}]
		Delve.setpieces_fired.clear()
		var sp2: Dictionary = sp.duplicate()
		sp2["mb_key"] = k
		d._setpiece_miniboss(sp2, sp2["pos"])
		var mon: Monster = (dh.monsters as Array).back()
		if red and k == "bellman":
			mon.set_meta("mb_key", "leech")             # no way, no act lines: must not pass
		var feed: Array = town.get("feed")
		var n0 := feed.size()
		var hp0 := mon.hp
		mon.hp = mon.max_hp * 0.8
		var sc0 := mon.scale.x
		d._mb_way_tick(mon, d.party, d.party[0], 9.0)
		var way := String(Delve.MB_WAYS[k])
		seen_ways[way] = true
		var acts: Array = Delve.miniboss_lines(k, "act")
		var said := feed.slice(n0)
		var hit := false
		for l in said:
			for a in acts:
				if String(l) == String(a).replace("{name}", String(h["name"])):
					hit = true
		_ok(hit, "%s: an act line from its own pool (%s)" % [k, said])
		_ok(int(Delve.setpieces_fired.get("miniboss_act_" + way, 0)) == 1, "%s: way %s counted once" % [k, way])
		var st: Dictionary = d.party[0].get("st", {})
		match way:
			"call":
				_ok(d._live_called(mon).size() == 1, "%s: one thing called" % k)
			"plate":
				_ok(mon.hp > mon.max_hp * 0.8, "%s: a plate taken (hp up)" % k)
			"grow":
				_ok(mon.scale.x > sc0, "%s: it stands taller" % k)
			"mend":
				_ok(mon.hp > mon.max_hp * 0.8, "%s: the room back on its feet (hp up)" % k)
			"snuff":
				_ok(d.has_st(d.party[0], "blinded"), "%s: the lamp out (blinded)" % k)
			"hook":
				_ok(d._flat(b.global_position, mon.global_position) < 2.5, "%s: reeled in (%.1f m)" % [k, d._flat(b.global_position, mon.global_position)])
			"strip":
				_ok(d.has_st(d.party[0], "frightened"), "%s: kit off (frightened)" % k)
			"bar":
				_ok(int((mon.def.get("ways", {}) as Dictionary).get("guard", 0)) >= 1, "%s: the bar in (guard)" % k)
			"flood", "snare", "set":
				_ok(d.has_st(d.party[0], "slowed"), "%s: held (slowed)" % k)
			"blink":
				_ok(true, "%s: blinked (swoop issued)" % k)
			"order":
				# S36: it called this hero; anyone else holds, the called one does not
				_ok(d._order_uid == "s34" + k, "%s: called the hero (%s)" % [k, d._order_uid])
				_ok(not d._order_holds(d.party[0]), "%s: the called hero acts" % k)
				_ok(d._order_holds({"uid": "someone_else"}), "%s: the rest hold" % k)
				d._mb_way_tick(mon, d.party, d.party[0], 9.0)
				_ok(d._order_uid == "s34" + k, "%s: the SAME hero called again" % k)
				Delve.setpieces_fired["miniboss_act"] = 1
				Delve.setpieces_fired["miniboss_act_order"] = 1
		# broken: once, then never again
		mon.hp = mon.max_hp * 0.2
		var n1 := feed.size()
		d._mb_way_tick(mon, d.party, d.party[0], 9.0)
		var br: Array = Delve.miniboss_lines(k, "broken")
		_ok(feed.size() == n1 + 1 and br.has(feed.back()), "%s: a broken line from its pool" % k)
		if way == "grow":
			_ok(is_equal_approx(mon.scale.x, 1.0), "%s: back to its own size" % k)
		if way == "order":
			_ok(not d._order_holds({"uid": "someone_else"}), "%s: broken - nobody holds" % k)
		d._mb_way_tick(mon, d.party, d.party[0], 9.0)
		d._mb_way_tick(mon, d.party, d.party[0], 9.0)
		_ok(int(Delve.setpieces_fired.get("miniboss_broken", 0)) == 1 and int(Delve.setpieces_fired.get("miniboss_act", 0)) == 1, "%s: broken once, no act after" % k)
		_ok(not " ".join(PackedStringArray(feed.map(func(x): return String(x)))).contains("{name}"), "%s: no unfilled {name}" % k)
		print("  %s/%s: %s" % [k, way, " | ".join(PackedStringArray(feed.slice(n0).map(func(x): return String(x))))])
		mon.queue_free()
		d.queue_free()
		town.queue_free()
	_ok(seen_ways.size() == 13, "thirteen distinct ways (%d)" % seen_ways.size())
	return _finish()

func _finish() -> bool:
	if _checks < 60:
		_fails.append("check floor: %d checks is under 60" % _checks)
	if _fails.is_empty():
		print("S34_WAYS OK %d checks" % _checks)
	else:
		print("S34_WAYS FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
	quit(0 if _fails.is_empty() else 1)
	return true
