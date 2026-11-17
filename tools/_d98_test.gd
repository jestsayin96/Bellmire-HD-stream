extends SceneTree
## D98_TEST - the three _alt lore pools are READ (game build, 17 Nov).
## lord_intros / unique_intros / forge hold ONE STRING per key; their C-8 / C-12 _alt pools hold a
## LIST for the same key. The pick rule content wrote is [live] + alt, then draw. This gate proves:
##   A. every key's pool is the live line PLUS every alt line (sizes counted off the file, not typed)
##   B. the draw stays inside the pool, reaches the alt lines AND the live line, and spreads
##   C. the REAL path: Delve._next_floor raises a lord and the Chronicle line it speaks is one of
##      that lord's pool; six risings of one lord do not all speak the same line
##   D. Roster.forge_flavour (the !forge reader) draws from [forge[t]] + forge_alt[t]
## Headless. Run: <console> --headless --path . --script tools/_d98_test.gd
var _fails: Array = []
var _checks := 0
var _r: Roster
var _done := false

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _lore() -> Dictionary:
	var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) as Dictionary

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)

func _spread(tag: String, pool: Array, live: String, alt: Array, draw: Callable) -> void:
	var seen := {}
	var outside := 0
	for i in 600:
		var s := String(draw.call())
		if not pool.has(s):
			outside += 1
		seen[s] = true
	_ok(outside == 0, "%s: 600 draws, none outside the pool (%d outside)" % [tag, outside])
	_ok(seen.has(live), "%s: the live line is still drawn" % tag)
	var alt_seen := 0
	for a in alt:
		if seen.has(String(a)):
			alt_seen += 1
	_ok(alt_seen >= alt.size() - 1, "%s: the alt lines are drawn (%d of %d seen)" % [tag, alt_seen, alt.size()])

func _process(_dt: float) -> bool:
	if _done:
		return true
	_done = true
	var L := _lore()
	print("D98 A+B: the intro pools")
	var total := {"lord_intros_alt": 0, "unique_intros_alt": 0, "forge_alt": 0}
	for uniq in [false, true]:
		var base := "unique_intros" if uniq else "lord_intros"
		var live_d: Dictionary = L[base]
		var alt_d: Dictionary = L[base + "_alt"]
		for id in live_d:
			var alt: Array = alt_d.get(id, [])
			total[base + "_alt"] += alt.size()
			var pool := Delve.intro_pool(uniq, String(id))
			_ok(alt.size() > 0, "%s %s: has an alt list in the file (%d)" % [base, id, alt.size()])
			_ok(pool.size() == 1 + alt.size(), "%s %s: pool is live + alt = %d (%d)" % [base, id, 1 + alt.size(), pool.size()])
			_spread("%s %s" % [base, id], pool, String(live_d[id]), alt, func(): return Delve.intro_line(uniq, String(id)))
		for id in alt_d:
			if not String(id).begins_with("_"):
				_ok(live_d.has(id), "%s_alt %s: keys a lord the live pool knows" % [base, id])
	_ok(Delve.intro_line(false, "no_such_lord") == "", "an unknown id gets \"\" (the caller skips it)")
	print("D98 C: the REAL rising")
	var id := "hollow_king"
	var pool := Delve.intro_pool(false, id)
	var spoken := {}
	for n in 6:
		Bestiary._spent = Bestiary.LESSER.filter(func(x): return x != id)
		Bestiary._last_lord = ""
		Bestiary.pending_title = ""
		Bestiary.force_lord_unique = 0.99   # roll high: the plain lord, not a written variant
		Bestiary.only_lord_unique = ""
		var fake := GDScript.new()
		fake.source_code = "extends Node3D\nvar feed := []\n"
		fake.reload()
		var town := Node3D.new()
		town.set_script(fake)
		root.add_child(town)
		var d := Delve.new()
		d.roster = _r
		d.floor_no = 4
		d.start_floor = -1
		d.town = town
		root.add_child(d)
		var uid := "d98_%d" % n
		var h: Dictionary = _r.fresh(uid, "IntroFan%d" % n, "knight")
		var b := HeroBody.new()
		b.setup(_r, uid)
		b.town = d
		b.stay = true
		d.add_child(b)
		d.party = [{"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0}]
		d._next_floor()
		var m: Monster = d.dun.lord if d.dun else null
		var got := ""
		for l in town.get("feed"):
			if pool.has(String(l)):
				got = String(l)
		if m != null and String(m.def.get("id", "")) == id and not bool(m.def.get("unique", false)):
			_ok(got != "", "rising %d: %s rose and the Chronicle spoke a line from its pool" % [n, id])
			spoken[got] = true
		else:
			_ok(m != null, "rising %d: a lord rose (%s)" % [n, String(m.def.get("id", "")) if m else "none"])
		Bestiary.force_lord_unique = -1.0
		d.queue_free()
		town.queue_free()
	_ok(spoken.size() >= 2, "six risings of %s spoke %d different lines, not one" % [id, spoken.size()])
	print("D98 D: the forge")
	var fl: Dictionary = L["forge"]
	var fa: Dictionary = L["forge_alt"]
	for t in fl:
		var alt: Array = fa.get(t, [])
		total["forge_alt"] += alt.size()
		var p := Roster.forge_pool(int(t))
		_ok(p.size() == 1 + alt.size(), "forge tier %s: pool is live + alt = %d (%d)" % [t, 1 + alt.size(), p.size()])
		_spread("forge tier %s" % t, p, String(fl[t]), alt, func(): return Roster.forge_flavour(int(t)))
	print("D98 alt lines now reachable: %s" % str(total))
	if _fails.is_empty():
		print("D98_TEST OK %d checks" % _checks)
	else:
		print("D98_TEST FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
	quit(0 if _fails.is_empty() else 1)
	return true
