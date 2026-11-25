extends SceneTree
## S76 - the Pitman (44th, Underfoot in art's CANON, tag crypt - field 5). Built in the shape S72
## taught: every hold arm is asserted AGAINST A NAMED CONDITION, and the post-hold arm sits next to
## it. FED is read off content's own data (data/lore_lines.json miniboss_feed.by_key.pitman), so
## when content writes the pitman feed (C-152 or later) the gate flips BY ITSELF to the post-hold
## arms - and those arms then demand the game build's MB_NAME["pitman"] row, so the gate goes RED
## until S51's name lands. Nothing here asserts a bare absence. Windowed, no --quit:
## <console> --path . --resolution 1920x1080 --script tools/_s76_pitman.gd
## Prints S76_PITMAN OK / S76_PITMAN FAIL. Shot: renders/cycles/s76/pitman_static.png (+ pitman.png once FED)
var _fails: Array = []
var _checks := 0
var _r: Roster
var _keys: Array = []
var _i := 0
var _wait := 0
var _cam: Camera3D
var _cur: Dictionary = {}
var _rows: Array = []
var FED := false
const OUT := "res://renders/cycles/s76/"
const K := "pitman"
const NAME := "Underfoot"   # art's CANON title (minibosses.py:15251); MB_NAME waits on content (S51)

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _fed() -> bool:
	# the NAMED CONDITION: content's feed row exists for this key. Read off the file, not off Delve,
	# so the hold is judged by content's data and not by the code under test.
	var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	return ((d.get("miniboss_feed", {}) as Dictionary).get("by_key", {}) as Dictionary).has(K)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	FED = _fed()
	print("S76 condition: content feed row by_key.pitman %s" % ("PRESENT (post-hold arms)" if FED else "absent - no feed rows yet (hold arms)"))
	if FED:
		_keys.append([K, "crypt"])   # the REAL delve spawn path, only once content has lines
	var drawn := 0
	for n in range(400):
		if DungeonHD.miniboss_for("crypt", n) == K:
			drawn += 1
	print("S76 crypt draws of pitman over 400 rolls: %d" % drawn)
	var arrive_n := Delve.miniboss_lines(K, "arrive").size()
	var fall_n := Delve.miniboss_lines(K, "fall").size()
	# --- arms that hold in BOTH shapes ---
	_ok(ResourceLoader.exists("res://assets/monsters/minibosses/pitman.glb"), "pitman.glb loads (so any hold is the lines, not the mesh)")
	_ok(absf(float(Delve.MB_FIT.get(K, 0.0)) - 0.94) < 0.0001, "MB_FIT pitman is art's register 0.94 (%s)" % str(Delve.MB_FIT.get(K, "missing")))
	_ok((DungeonHD.THEME_MINIBOSS_MORE.get("crypt", []) as Array).has(K), "pitman is in the crypt row under art's tag (field 5)")
	# --- each arm: hold shape and post-hold shape side by side, chosen by the named condition ---
	if FED:
		_ok(drawn > 0, "pitman enters the crypt draw (%d of 400)" % drawn)
		_ok(Delve.miniboss_name(K) == NAME, "pitman is named %s (%s) - S51's MB_NAME row" % [NAME, Delve.miniboss_name(K)])
		_ok(arrive_n > 0 and fall_n > 0, "content's pitman lines read: arrive %d / fall %d" % [arrive_n, fall_n])
	else:
		_ok(drawn == 0, "no feed rows yet, so miniboss_for holds pitman out of the crypt draw (%d of 400)" % drawn)
		_ok(not Delve.MB_NAME.has(K), "no feed rows yet, so S51 holds MB_NAME pitman (CANON says %s)" % NAME)
		_ok(arrive_n == 0 and fall_n == 0, "no feed rows yet agrees with Delve's read: arrive %d / fall %d" % [arrive_n, fall_n])
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.2
	root.add_child(sun)
	# a static look at the body at its MB_FIT height, in both shapes
	var ps := load("res://assets/monsters/minibosses/pitman.glb") as PackedScene
	_ok(ps != null, "pitman.glb instantiates")
	if ps:
		var body := ps.instantiate() as Node3D
		root.add_child(body)
		var ab := _aabb(body, Transform3D.IDENTITY)
		var want_h := Delve.MB_HERO_H * float(Delve.MB_FIT.get(K, 1.0))
		if ab.size.y > 0.001:
			body.scale = Vector3.ONE * (want_h / ab.size.y)
		print("S76 pitman native h %.3f -> shot at %.2fm (MB_HERO_H %.2f x 0.94)" % [ab.size.y, want_h, Delve.MB_HERO_H])
		_cam.look_at_from_position(Vector3(3.2, want_h * 0.7, 5.2), Vector3(0, want_h * 0.5, 0))

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
	var uid := "s76_" + k
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
	if FED:
		_ok(not feed.is_empty() and arrive.has(feed[0]), "%s: arrive line fired with the body present" % k)
	else:
		_ok(false, "%s: staged while unfed - the hold arm should have kept this off the floor" % k)
	var n0 := feed.size()
	m.hp = 0
	m.state = Monster.S.DEAD
	d._on_kill(m)
	var fall: Array = Delve.miniboss_lines(k, "fall")
	var has_fall := false
	for l in feed.slice(n0):
		if fall.has(l):
			has_fall = true
	_ok(has_fall, "%s: fall line on the kill" % k)   # only reached when FED (staging is FED-only)
	_rows.append("%s floor %d (%s) model %s ratio %.2f/%.2f live-hero %.2fm" % [k, _cur["fn"], _cur["theme"], path.get_file(), got, want, hh])
	for n in ["d", "town", "dh"]:
		(_cur[n] as Node).queue_free()
	_cur = {}

func _aabb(n: Node, xf: Transform3D) -> AABB:
	var t := xf * (n as Node3D).transform if n is Node3D else xf
	var out := AABB()
	var got := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).get_aabb()
		got = true
	for c in n.get_children():
		var a := _aabb(c, t)
		if a.size != Vector3.ZERO:
			out = a if not got else out.merge(a)
			got = true
	return out

var _shot := 0
## S74: --headless has no framebuffer, so get_image() is null there. Skip the picture, never the checks.
func _snap(path: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("S76 no framebuffer (headless) - picture skipped: " + path.get_file())
		return
	img.save_png(ProjectSettings.globalize_path(path))
func _process(_dt: float) -> bool:
	if _cur.is_empty():
		if _i >= _keys.size() and _shot < 8:
			_shot += 1
			if _shot == 8:
				_snap(OUT + "pitman_static.png")
			return false
		if _i >= _keys.size():
			print("S76 ROWS:")
			for r in _rows:
				print("  " + r)
			var floor_n := 11 if FED else 7
			if _checks < floor_n:
				_fails.append("check floor: %d checks is under %d" % [_checks, floor_n])
			if _fails.is_empty():
				if FED:
					print("S76_PITMAN OK %d checks, Underfoot stands on a crypt floor in its own body (post-hold shape, FED)" % _checks)
				else:
					print("S76_PITMAN OK %d checks, pitman is fitted (0.94), in the crypt row and HELD OUT: no feed rows yet (by_key.pitman absent)" % _checks)
			else:
				print("S76_PITMAN FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
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
		_snap(OUT + "%s.png" % _cur["k"])
		_check_and_clear()
	return false
