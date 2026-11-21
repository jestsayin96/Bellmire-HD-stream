extends SceneTree
## D97_LORDS - the eight lords rise IN THEIR OWN BODIES with their numbers OUT OF THE FILE, and a
## written variant rises named. For each lord, twice (plain, then pinned to one of its own written
## uniques): the bag is set so the REAL Delve._next_floor builds the boss floor and raises it, the
## Chronicle must name it, the body must be art's model (assets/monsters/lords/<id>.glb) standing
## at art's measured height (renders/art/lords/_report.json size z) x LORD_SCALE, and hp / attack /
## speed must be the writer's number wherever data/bosses.json gives one. A 1920x1080 shot of each
## goes to renders/cycles/d97/. Run WINDOWED, no --quit; it quits itself:
## <console> --path . --resolution 1920x1080 --script tools/_d97_lords.gd
var _fails: Array = []
var _checks := 0
var _r: Roster
var _plan: Array = []
var _i := 0
var _wait := 0
var _el := 0.0
var _cam: Camera3D
var _cur: Dictionary = {}
var _rows: Array = []
var _art: Dictionary = {}
const OUT := "res://renders/cycles/d97/"

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var f := FileAccess.open("res://renders/art/lords/_report.json", FileAccess.READ)
	if f:
		_art = (JSON.parse_string(f.get_as_text()) as Dictionary).get("lords", {})
	# ---- the file rows: every lord row matches a canon lord, in the bag the code draws it from
	var rows := 0
	for k in Bestiary.BOSS_DEFS:
		var fr := Bestiary.lord_file_row(String(k))
		if not fr.is_empty():
			rows += 1
			var want_bag := "lesser" if Bestiary.LESSER.has(k) else "greater"
			_ok(String(fr["bag"]) == want_bag, "file: %s is in the %s bag in data/bosses.json and in the code" % [k, want_bag])
	_ok(rows == 8, "file: all eight lords have a row in data/bosses.json lesser/greater (%d)" % rows)
	_ok(Bestiary.lord_row_orphans.is_empty(), "file: no lord row the code cannot match (%s)" % str(Bestiary.lord_row_orphans))
	var pools := Bestiary.lord_uniques()
	for k in Bestiary.BOSS_DEFS:
		_plan.append([String(k), ""])
		var pool: Array = pools.get(String(k), [])
		if not pool.is_empty():
			_plan.append([String(k), String((pool[0] as Dictionary)["name"])])
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.2
	root.add_child(sun)

func _stage(id: String, uq: String) -> void:
	var greater := Bestiary.GREATER.has(id)
	var pool: Array = Bestiary.GREATER if greater else Bestiary.LESSER
	Bestiary._spent = pool.filter(func(x): return x != id)
	Bestiary._last_lord = ""
	Bestiary.pending_title = ""
	Bestiary.only_lord_unique = uq
	Bestiary.force_lord_unique = 0.0 if uq != "" else 0.99
	var fake := GDScript.new()
	fake.source_code = "extends Node3D\nvar feed := []\n"
	fake.reload()
	var town := Node3D.new()
	town.set_script(fake)
	root.add_child(town)
	var d := Delve.new()
	d.roster = _r
	d.floor_no = 9 if greater else 4
	d.start_floor = -1
	d.town = town
	root.add_child(d)
	var uid := "d97_%s_%d" % [id, _i]
	var h: Dictionary = _r.fresh(uid, "Fit" + id.capitalize().replace(" ", ""), "knight")
	var b := HeroBody.new()
	b.setup(_r, uid)
	b.town = d
	b.stay = true
	d.add_child(b)
	d.party = [{"uid": uid, "h": h, "body": b, "hp": 100.0, "max": 100.0, "saved": false, "swing": 0.0}]
	Bestiary.lord_no_model.clear()
	d._next_floor()
	Bestiary.only_lord_unique = ""
	Bestiary.force_lord_unique = -1.0
	_cur = {"id": id, "uq": uq, "d": d, "town": town, "b": b}
	var m: Monster = d.dun.lord if d.dun else null
	if m == null:
		return
	m.set_process(false); m.set_physics_process(false)
	b.set_process(false); b.set_physics_process(false)
	var p: Vector3 = m.global_position
	var lh := float(m.def.get("h", 4.0))
	b.global_position = p + Vector3(lh * 0.45 + 1.2, 0, lh * 0.25)
	# high and close: a deep floor's walls stand between a level camera and the lord
	_cam.global_position = p + Vector3(lh * 0.35, lh * 1.05 + 4.0, lh * 0.95 + 2.5)
	_cam.look_at(p + Vector3(lh * 0.15, lh * 0.4, 0))
	_cur["m"] = m

func _check_and_clear() -> void:
	var id: String = _cur["id"]
	var uq: String = _cur["uq"]
	var tag := id + (" / " + uq if uq != "" else "")
	var feed: Array = _cur["town"].get("feed")
	var m: Monster = _cur.get("m")
	_ok(m != null, "%s: a lord rose on the boss floor" % tag)
	if m == null:
		return _free()
	_ok(String(m.def.get("id", "")) == id, "%s: it is the lord the bag was set for (%s)" % [tag, m.def.get("id", "")])
	var path := String(m.def.get("path", ""))
	_ok(path == Bestiary.LORD_DIR + id + ".glb", "%s: rises in ITS OWN model (%s)" % [tag, path.get_file()])
	_ok(m._body != null, "%s: the model loaded" % tag)
	var mh := 0.0
	if m._body:
		## S11: measure at REST scale. A hit landing during the wait squashes the body to 0.86 y for
		## 0.3 s (L26a flinch), and one 05:10 run read the Pale Duchess 4% short off that - a flaky gate.
		var sy: float = m._base_scale.y if m._base_scale != Vector3.ZERO else m._body.scale.y
		mh = m._local_bounds(m._body).size.y * sy
	var art_z := float(((_art.get(id, {}) as Dictionary).get("size", [0, 0, 0]) as Array)[2])
	var size := float(m.def.get("uniq_size", 1.0))
	var want := art_z * Bestiary.LORD_SCALE * size
	_ok(art_z > 0.0 and absf(mh - want) <= want * 0.03, "%s: stands %.2fm vs art's %.2fm x %.1f x size %.2f = %.2fm" % [tag, mh, art_z, Bestiary.LORD_SCALE, size, want])
	## S88 (Mr. E, 21 Nov 10:17 directive): the boss title leaves the HUD, so the lord's NAME OVER
	## ITS OWN HEAD is now the only place a viewer reads it. Gate it: the tag exists, is shown,
	## leads with the lord's own name, and stands ABOVE the body (not inside a scaled-up lord).
	var nt := m.get_node_or_null("name_tag") as Label3D
	_ok(nt != null, "%s: S88 carries a name_tag over its head" % tag)
	if nt:
		var first_line := nt.text.split("\n")[0]
		_ok(nt.visible, "%s: S88 the name_tag is visible" % tag)
		_ok(first_line == String(m.def.get("name", "")), "%s: S88 the tag leads with its name (\"%s\")" % [tag, first_line])
		_ok(not nt.text.contains("\n"), "%s: S88 the tag is ONE line - the name, no epithet riding the bar" % tag)
		_ok(nt.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM, "%s: S88 the tag grows up, away from the bar" % tag)
		_ok(nt.position.y >= mh, "%s: S88 the tag stands at %.2fm, above the %.2fm body" % [tag, nt.position.y, mh])
		var hb_y := -1.0
		for c in m.get_children():
			if c is HealthBar3D:
				hb_y = (c as Node3D).position.y
		_rows.append("S88 %s tag y %.2f body %.2f bar y %.2f text %s" % [tag, nt.position.y, mh, hb_y, nt.text.replace("\n", " | ")])
	# the numbers: the writer's where the file has them
	var fr := Bestiary.lord_file_row(id)
	var src := uq if uq != "" else ""
	var row: Dictionary = fr
	if uq != "":
		for v in (Bestiary.lord_uniques().get(id, []) as Array):
			if String((v as Dictionary)["name"]) == uq:
				row = v
	var fn: int = _cur["d"].floor_no
	if row.has("hp"):
		_ok(absf(float(m.def["boss_hp"]) - float(row["hp"]) * Bestiary.lord_hp_mult(fn)) < 0.01, "%s: hp is the FILE's %d x depth" % [tag, int(row["hp"])])
	if row.has("attack"):
		_ok(absf(float(m.def["boss_atk"]) - float(row["attack"]) * Bestiary.lord_atk_mult(fn)) < 0.01, "%s: attack is the FILE's %d x depth" % [tag, int(row["attack"])])
	if row.has("speed"):
		_ok(absf(float(m.def.get("spd", 0)) - float(row["speed"])) < 0.01, "%s: speed is the FILE's %.1f" % [tag, float(row["speed"])])
	var nm := String(m.def.get("name", ""))
	var rose := false
	var guild := false
	for l in feed:
		if String(l).begins_with(nm + " rises."):
			rose = true
		if String(l).begins_with("The guild has put down"):
			guild = true
	_ok(rose, "%s: the Chronicle names it as it rises (\"%s rises.\")" % [tag, nm])
	if uq != "":
		_ok(nm == uq, "%s: it rises AS the written variant" % tag)
		_ok(guild, "%s: the Chronicle marks it as a version of the lord" % tag)
	_rows.append("%s floor %d model %s %.2fm hp %d atk %d spd %.1f %s" % [tag, fn, path.get_file(), mh, int(m.def["boss_hp"]), int(m.def["boss_atk"]), float(m.def.get("spd", 0)), "(file row: " + str(row.keys()) + ")"])
	_free()

func _free() -> void:
	for n in ["d", "town"]:
		(_cur[n] as Node).queue_free()
	_cur = {}

func _process(_dt: float) -> bool:
	if _cur.is_empty():
		if _i >= _plan.size():
			print("D97 ROWS:")
			for r in _rows:
				print("  " + r)
			print("D97 no-model lords: %s" % str(Bestiary.lord_no_model))
			if _checks < 139:  ## S11: measured 139; fewer means something stopped being checked
				_fails.append("check floor: %d checks is under 139" % _checks)
			if _fails.is_empty():
				print("D97_LORDS OK %d checks, %d risings" % [_checks, _plan.size()])
			else:
				print("D97_LORDS FAIL %d of %d: %s" % [_fails.size(), _checks, _fails])
			quit(0 if _fails.is_empty() else 1)
			return true
		var st: Array = _plan[_i]
		_i += 1
		_stage(st[0], st[1])
		_wait = 0
		_el = 0.0
		return false
	_wait += 1
	_el += _dt
	# Monster.entrance() raises a lord out of the floor over 2.2 s: shoot once it is fully up
	if _el >= 2.8 and not _cur.has("shot"):
		_cur["shot"] = true
		var nm := String(_cur["id"]) + ("_uniq" if String(_cur["uq"]) != "" else "")
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s.png" % nm))
		_check_and_clear()
	return false
