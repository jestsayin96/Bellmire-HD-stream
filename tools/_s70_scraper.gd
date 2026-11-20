extends SceneTree
## S70 - the Scraper (Scourstone, 41st) stands on a CRYPT floor in its own body: a copy of D96_FIT's
## real set-piece spawn path narrowed to one key, plus a draw check that DungeonHD.miniboss_for
## actually puts `scraper` into the crypt pool (mesh + content's arrive lines). Windowed, no --quit:
## <console> --path . --resolution 1920x1080 --script tools/_s70_scraper.gd
## Prints S70_SCRAPER OK / S70_SCRAPER FAIL. Shot: renders/cycles/s70/scraper.png
var _fails: Array = []
var _checks := 0
var _r: Roster
var _keys: Array = []
var _i := 0
var _wait := 0
var _cam: Camera3D
var _cur: Dictionary = {}
var _rows: Array = []
const OUT := "res://renders/cycles/s70/"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_keys.append(["scraper", "crypt"])
	var drawn := 0
	for n in range(400):
		if DungeonHD.miniboss_for("crypt", n) == "scraper":
			drawn += 1
	print("S70 crypt draws of scraper over 400 rolls: %d" % drawn)
	_ok(drawn > 0, "scraper enters the crypt draw (%d of 400)" % drawn)
	_ok(Delve.miniboss_name("scraper") == "Scourstone", "scraper is named Scourstone (%s)" % Delve.miniboss_name("scraper"))
	_ok(absf(float(Delve.MB_FIT.get("scraper", 0.0)) - 1.04) < 0.0001, "MB_FIT scraper is art's register 1.04")
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.2
	root.add_child(sun)

func _stage(k: String, theme: String) -> bool:
	# cheap theme lookup first (FloorGen.theme_for), then build at most 8 floors of that theme.
	# A floor whose own roll gave a miniboss set piece is used as-is; otherwise the chamber is
	# taken from any set piece on that floor (else the entry) and the row is made exactly as
	# dungeon_hd does it - Bestiary.pick + the theme's key - so the REAL delve spawn path runs.
	var dh: DungeonHD = null
	var sp: Dictionary = {}
	var fn := -1
	var tries := 0
	for f in range(4, 600):
		if FloorGen.theme_for(f) != theme:
			continue
		if dh:
			dh.free()
		dh = DungeonHD.new()
		root.add_child(dh)
		dh.floor_no = f
		dh.build(f)
		tries += 1
		if bool(dh.info.get("boss", false)):
			continue
		var sps: Array = dh.info.get("set_pieces", [])
		# S67: a floor whose own roll drew a DIFFERENT elite (first run: floor 8 drew tallyman) is
		# not this key's proof - the S65 copy took it as-is and would have gated the wrong body.
		# Every staged chamber is rebuilt for THIS key below, natural set piece or not.
		if tries >= 8 or not sps.is_empty():
			var at: Vector3 = (sps[0] as Dictionary)["pos"] if not sps.is_empty() else dh.info["entry"]
			sp = {"kind": "miniboss", "pos": at, "r": 3.0, "resolved": false,
				"def": Bestiary.pick(f, theme), "purse": 60, "mb_key": k}
			dh.info["set_pieces"] = [sp]
			fn = f
			break
	if fn < 0:
		_ok(false, "%s: no %s floor found" % [k, theme])
		return false
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
	var uid := "s70_" + k
	var h: Dictionary = _r.fresh(uid, "Fit" + k.capitalize(), "knight")
	var b := HeroBody.new()
	b.setup(_r, uid)
	b.town = d
	b.stay = true
	d.add_child(b)
	var p: Vector3 = sp["pos"]
	b.global_position = p
	d.party = [{"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0}]
	Delve.setpieces_fired.clear()
	Delve.miniboss_no_model.clear()
	d._setpieces_tick()
	var m: Monster = (dh.monsters as Array).back()
	m.set_process(false); m.set_physics_process(false)
	b.set_process(false); b.set_physics_process(false)
	b.global_position = p + Vector3(1.6, 0, 0)
	m.global_position = Vector3(p.x, m.global_position.y, p.z)
	_cur = {"k": k, "theme": theme, "fn": fn, "dh": dh, "d": d, "town": town, "m": m, "b": b, "p": p}
	_cam.global_position = p + Vector3(0.8, 5.0, 6.0)
	_cam.look_at(p + Vector3(0.8, 1.0, 0))
	return true

func _check_and_clear() -> void:
	var k: String = _cur["k"]
	var m: Monster = _cur["m"]
	var b: HeroBody = _cur["b"]
	var d: Delve = _cur["d"]
	var feed: Array = _cur["town"].get("feed")
	var path := String(m.def.get("path", ""))
	_ok(path.begins_with(Delve.MB_DIR), "%s: spawns with its own model (%s)" % [k, path.get_file()])
	_ok(path.get_file().begins_with(k), "%s: the model is %s's own body, not another elite's (%s)" % [k, k, path.get_file()])
	_ok(m._body != null, "%s: the model loaded" % k)
	var mh := 0.0
	var hh := 0.0
	if m._body:
		## S11: measure at REST scale. A hit landing during the wait squashes the body to 0.86 y for
		## 0.3 s (L26a flinch), and one 05:10 run read the Pale Duchess 4% short off that - a flaky gate.
		var sy: float = m._base_scale.y if m._base_scale != Vector3.ZERO else m._body.scale.y
		mh = m._local_bounds(m._body).size.y * sy
	if b._mdl:
		hh = m._local_bounds(b._mdl).size.y * b._mdl.scale.y
	# the gate holds the MINIBOSS to art's number against art's hero (2.45 m, posed knight, no
	# weapon). The live hero's bounds are printed but not gated: they include the held weapon,
	# shield and idle pose, so they wander 1.98-2.70 m between runs and would be a lying ruler.
	var want := Delve.miniboss_ratio(k, path)
	var got := mh / Delve.MB_HERO_H
	_ok(absf(got - want) <= 0.03, "%s: stands %.2fm = %.2f x hero vs art register %.2f (live hero bounds incl. weapon %.2fm, info only)" % [k, mh, got, want, hh])
	var arrive: Array = Delve.miniboss_lines(k, "arrive")
	_ok(not feed.is_empty() and arrive.has(feed[0]), "%s: arrive line fired with the body present" % k)
	var n0 := feed.size()
	m.hp = 0
	m.state = Monster.S.DEAD
	d._on_kill(m)
	var fall: Array = Delve.miniboss_lines(k, "fall")
	var has_fall := false
	for l in feed.slice(n0):
		if fall.has(l):
			has_fall = true
	_ok(has_fall, "%s: fall line on the kill" % k)
	_rows.append("%s floor %d (%s) model %s ratio %.2f/%.2f live-hero %.2fm" % [k, _cur["fn"], _cur["theme"], path.get_file(), got, want, hh])
	for n in ["d", "town", "dh"]:
		(_cur[n] as Node).queue_free()
	_cur = {}

func _process(_dt: float) -> bool:
	if _cur.is_empty():
		if _i >= _keys.size():
			print("S70 ROWS:")
			for r in _rows:
				print("  " + r)
			if _checks < 9:
				_fails.append("check floor: %d checks is under 9" % _checks)
			if _fails.is_empty():
				print("S70_SCRAPER OK %d checks, Scourstone stands on a crypt floor in its own body" % _checks)
			else:
				print("S70_SCRAPER FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
			quit(0 if _fails.is_empty() else 1)
			return true
		var kt: Array = _keys[_i]
		_i += 1
		if not _stage(kt[0], kt[1]):
			return false
		_wait = 0
		return false
	_wait += 1
	if _wait == 8:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s.png" % _cur["k"]))
		_check_and_clear()
	return false
