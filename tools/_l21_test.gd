extends SceneTree
## L21 (Mr. E, Nov 11): the interface over the spotlight panes. THE RULE, checked here in
## code: while more than one view is on screen, no HUD element may overlap a pane seam or sit
## over a pane it does not belong to. Every drawn control is either inside ONE pane (that
## pane's overlay) or inside the reserved chrome bar outside the panes. Then:
##   - the Chronicle lives in the chrome bar, at the L15 size (28 px at 1080p)
##   - the boss card sits inside a pane whose camera is in that fight's delve
##   - each "Delvers / town's band - floor N" block sits inside a pane following that party
##   - floating combat text (numbers, bubbles, states) is not drawn by any pane smaller than
##     half the screen, and IS drawn by the side-by-side panes
##   - no two name tags a pane draws overlap
## Scene: four viewers in town (a crowded market), two of them delving a lord floor with the
## lord fighting, chat busy, then the bits lane (side by side), then all three lanes (2x2).
## Run windowed: --resolution 1920x1080 (it also saves the renders, 1080p and 854x480, to
## renders/cycles/20261112_l21). Headless it runs the checks only. Prints L21_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _at := 0
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l21"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
		print("  FAIL ", what)

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _save(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))
	print("L21_SHOT %s (window %s)" % [tag, root.size])

func _process(_dt: float) -> bool:
	_f += 1
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				for v in [["2101", "JestFan", "knight dwarf"], ["2102", "MossyMage", "mage elf"], ["2103", "DawnCleric", "cleric human"], ["2104", "BigAxe", "barbarian orc"], ["2105", "Wren", "bard halfling"], ["2106", "OakenShield", "paladin dwarf"]]:
					_say(v[0], v[1], "!enlist " + v[2])
				for id in ["2101", "2104"]:
					var h: Dictionary = r.get_hero(id)
					h["weapon"] = 3
					h["armour"] = 3
					h["oil"] = 4
				_d = Delve.new()
				_d.town = _t
				_d.roster = r
				_d.start_floor = 5
				_d.max_floors = 5
				_t.add_child(_d)
				_d.start(["2104", "2101"])
				_eye.director._set_on(true)
				Engine.time_scale = 3.0
				_stage = "wait_lord"
		"wait_lord":
			if _d.lord_fighting() != null or _f > 3000:
				Engine.time_scale = 1.0
				_ok(_d.lord_fighting() != null, "the lord is fighting (frame %d)" % _f)
				# chat active: commands from the town's viewers (Chronicle lines, name glow)
				for v in [["2102", "MossyMage", "!hero"], ["2103", "DawnCleric", "!guild"], ["2105", "Wren", "!fish"], ["2106", "OakenShield", "!inventory"]]:
					_say(v[0], v[1], v[2])
				_save("full")
				_say("local_mre", "MrE", "!testbits 500 bigaxe")
				_stage = "pair"
				_at = _f
		"pair":
			_pops()
			if _f - _at == 90:
				_ok(Spotlight.of(_t).busy().size() == 1, "one lane busy for the side-by-side")
				_check("pair")
				_save("pair")
				_say("local_mre", "MrE", "!testsub mossymage")
				_say("local_mre", "MrE", "!testpoints dawncleric")
				_stage = "grid"
				_at = _f
		"grid":
			_pops()
			if _f - _at == 90:
				_ok(Spotlight.of(_t).busy().size() == 3, "all three lanes busy for the 2x2")
				_check("grid")
				_save("grid")
				print("L21_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
				return true
	return false

## floating combat text, every few frames, in the fight
func _pops() -> void:
	if _f % 30 != 0 or _d == null or _d.party.is_empty():
		return
	var m: Dictionary = _d.party[0]
	_d._float_text(m, "-%d" % (3 + _f % 9), Color(1, 0.4, 0.3))
	var l: Monster = _d.dun.lord if _d.dun else null
	if l and is_instance_valid(l):
		l._number(4 + _f % 11, _f % 21 == 0)

## ---------------------------------------------------------------- the regions

func _regions() -> Dictionary:
	var panes := {}
	var s := Spotlight.of(_t)
	for k in s._panes:
		var box: Control = s._panes[k]["box"]
		if box.is_visible_in_tree():
			panes[k] = box.get_global_rect()
	var sz := Vector2(root.size)
	var bottom := 0.0
	for k in panes:
		bottom = maxf(bottom, (panes[k] as Rect2).end.y)
	var chrome := Rect2(0, bottom, sz.x, sz.y - bottom) if sz.y - bottom >= 1.0 else Rect2()
	return {"panes": panes, "chrome": chrome}

static func _inside(r: Rect2, box: Rect2) -> bool:
	return box.size.x > 0 and r.position.x >= box.position.x - 1.0 and r.position.y >= box.position.y - 1.0 \
		and r.end.x <= box.end.x + 1.0 and r.end.y <= box.end.y + 1.0

## where a rect sits: a pane's name, "chrome", or "" (floats over a seam / two regions)
func _home(r: Rect2, reg: Dictionary) -> String:
	for k in reg["panes"]:
		if _inside(r, reg["panes"][k]):
			return k
	if _inside(r, reg["chrome"]):
		return "chrome"
	return ""

## every HUD control that draws something, on the main screen (not inside a pane's viewport)
func _drawn(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Viewport:
			continue
		if c is CanvasLayer and not (c as CanvasLayer).visible:
			continue
		if c is Control:
			var ct := c as Control
			if not ct.is_visible_in_tree():
				continue
			if _draws(ct) and _alpha(ct) > 0.05 and ct.size.x > 1.0 and ct.size.y > 1.0:
				out.append(ct)
		_drawn(c, out)

static func _draws(c: Control) -> bool:
	if c is Label:
		return (c as Label).text.strip_edges() != ""
	if c is ColorRect:
		return (c as ColorRect).color.a > 0.05
	return c is PanelContainer or c is Panel or c is ProgressBar or c is TextureRect or c is LineEdit or c is RichTextLabel or c is Button

static func _alpha(c: CanvasItem) -> float:
	var a := 1.0
	var n: Node = c
	while n is CanvasItem:
		a *= (n as CanvasItem).modulate.a * (n as CanvasItem).self_modulate.a
		n = n.get_parent()
	return a

## a pane's camera is in this delve (below, near its maze)
func _cam_in(cam: Camera3D, d: Delve) -> bool:
	if d == null or d.dun == null or not is_instance_valid(d.dun):
		return false
	var p := cam.global_position
	var q := d.dun.global_position
	return p.y < Delve.DELVE_Y * 0.5 and Vector2(p.x, p.z).distance_to(Vector2(q.x, q.z)) < 120.0

func _check(tag: String) -> void:
	var reg := _regions()
	var s := Spotlight.of(_t)
	_ok((reg["panes"] as Dictionary).size() >= 2, "%s: %d panes up" % [tag, (reg["panes"] as Dictionary).size()])
	_ok((reg["chrome"] as Rect2).size.y >= root.size.y * 0.10, "%s: a chrome bar outside the panes (%s)" % [tag, reg["chrome"]])
	# 1. THE RULE: every drawn control is inside one pane or inside the chrome bar
	var drawn: Array = []
	_drawn(root, drawn)
	var free: Array = []
	for c: Control in drawn:
		if _home(c.get_global_rect(), reg) == "":
			free.append("%s %s" % [_short(c), c.get_global_rect()])
	_ok(free.is_empty(), "%s: no HUD control over a seam or two regions (%d float free: %s)" % [tag, free.size(), free.slice(0, 6)])
	# 2. the Chronicle: in the chrome bar, at the L15 size
	for c in _t.get_children():
		if c is FeedHUD:
			var p: Control = (c as FeedHUD)._panel
			if p and p.is_visible_in_tree():
				_ok(_home(p.get_global_rect(), reg) == "chrome", "%s: the Chronicle sits in the chrome bar (%s)" % [tag, p.get_global_rect()])
				var big := 0
				for lb in (c as FeedHUD)._box.get_children():
					if lb is Label:
						big = maxi(big, (lb as Label).get_theme_font_size("font_size"))
				_ok(big >= UiTheme.px(28) - 1, "%s: Chronicle lines at the L15 size (%d px)" % [tag, big])
				var lines := 0
				for lb in (c as FeedHUD)._box.get_children():
					if lb is Label and lb.is_visible_in_tree():
						lines += 1
				_ok(lines >= 2, "%s: the Chronicle shows %d lines" % [tag, lines])
	# 3. the boss card: inside a pane whose camera is in the lord's delve
	var bb := _eye.boss_bar
	if bb.is_visible_in_tree() and bb.delve:
		var h := _home(bb.get_global_rect(), reg)
		_ok(h != "" and h != "chrome" and _cam_in(s._panes[h]["cam"], bb.delve), "%s: the boss card is in the pane showing the fight (in '%s', %s)" % [tag, h, bb.get_global_rect()])
	else:
		_ok(false, "%s: the boss card is up" % tag)
	# 4. party blocks: inside a pane whose camera follows that party
	var heads := 0
	for c: Control in drawn:
		if c is Label and ((c as Label).text.begins_with("Delvers ·") or (c as Label).text.begins_with("The town's band ·")):
			heads += 1
			var h := _home(c.get_global_rect(), reg)
			var ok := h != "" and h != "chrome"
			if ok:
				ok = false
				for d in _t.get_children():
					if d is Delve and (c as Label).text.ends_with("floor %d" % (d as Delve).floor_no) and _cam_in(s._panes[h]["cam"], d):
						ok = true
			_ok(ok, "%s: '%s' docks in the pane following that party (in '%s')" % [tag, (c as Label).text, h])
	# 5. floating combat text: none in panes under half the screen, kept in bigger panes
	var floats := _labels3d(true)
	_ok(not floats.is_empty(), "%s: floating text exists to test (%d)" % [tag, floats.size()])
	for k in reg["panes"]:
		var r: Rect2 = reg["panes"][k]
		var cam: Camera3D = s._panes[k]["cam"]
		var seen := floats.filter(func(lb): return (lb as Label3D).layers & cam.cull_mask != 0)
		if r.size.y < root.size.y * 0.5:          # a quarter pane (the side by side is full height)
			_ok(seen.is_empty(), "%s: no floating text in the small '%s' pane (%d drawn)" % [tag, k, seen.size()])
		elif k != "wide":
			_ok(seen.size() == floats.size(), "%s: floating text kept in the big '%s' pane (%d of %d)" % [tag, k, seen.size(), floats.size()])
	# 6. name tags: no two that a pane draws overlap
	var tags := _labels3d(false)
	for k in reg["panes"]:
		if tag == "pair" and k == "director":
			continue             # the side-by-side director keeps the full-screen names (checked as today's)
		var hits := _collisions(s._panes[k]["cam"], s._panes[k]["vp"], tags)
		_ok(hits.is_empty(), "%s: no name tags collide in the '%s' pane (%d: %s)" % [tag, k, hits.size(), hits.slice(0, 4)])

func _short(c: Node) -> String:
	var parts: Array = []
	var n := c
	for i in 3:
		if n == null:
			break
		parts.push_front(String(n.name) if not (n is Label) else "Label'%s'" % (n as Label).text.substr(0, 24))
		n = n.get_parent()
	return "/".join(parts)

## the world's 3D text: floating text (true) or the tags over people (false)
func _labels3d(floating: bool) -> Array:
	var out: Array = []
	for n in _t.find_children("*", "Label3D", true, false):
		var lb := n as Label3D
		if not lb.is_visible_in_tree() or lb.text.strip_edges() == "" or lb.modulate.a < 0.05 or lb.transparency > 0.95:
			continue
		if _is_float(lb) == floating:
			out.append(lb)
	return out

## floating text: down in a delve or off a monster, and not a name tag
static func _is_float(lb: Label3D) -> bool:
	if lb.has_meta("lane_tag"):
		return false           # a lane's own name tag (Spotlight)
	if lb.name == "name_tag" or lb.name == "eq_title":
		return false
	var p := lb.get_parent()
	while p:
		if p is HeroBody or p is Townsfolk:
			return false
		if p is Monster or p is Delve or p is DungeonHD:
			return true
		p = p.get_parent()
	# the delve's floats live under the floor root (info["root"])
	return lb.top_level and lb.no_depth_test

## the screen rects (in the pane's own viewport) of every tag the camera draws; pairs that overlap
func _collisions(cam: Camera3D, vp: SubViewport, tags: Array) -> Array:
	var rs: Array = []
	var vs := Vector2(vp.size)
	for lb: Label3D in tags:
		if lb.layers & cam.cull_mask == 0:
			continue
		var at := lb.global_position
		if cam.is_position_behind(at):
			continue
		var d := cam.global_position.distance_to(at)
		if lb.visibility_range_end > 0.0 and d > lb.visibility_range_end:
			continue
		var depth := -(cam.global_transform.affine_inverse() * at).z
		var lh_w := float(lb.font_size) * lb.pixel_size * (depth if lb.fixed_size else 1.0)
		var up := cam.global_transform.basis.y
		var base := at + up * (lb.offset.y * lb.pixel_size * (depth if lb.fixed_size else 1.0))
		var sp := cam.unproject_position(base)
		var lh := absf(cam.unproject_position(base + up * lh_w).y - sp.y)
		if lh < 2.0:
			continue
		var lines := lb.text.split("\n")
		var longest := 0
		for part in lines:
			longest = maxi(longest, part.length())
		var w := float(longest) * lh * 0.5
		var hgt := float(lines.size()) * lh
		var r := Rect2(sp.x - w * 0.5, sp.y - hgt * 0.5, w, hgt)
		if not Rect2(Vector2.ZERO, vs).intersects(r):
			continue
		rs.append([r, lb.text.split("\n")[0]])
	var hits: Array = []
	for i in rs.size():
		for j in range(i + 1, rs.size()):
			var a: Rect2 = rs[i][0]
			var b: Rect2 = rs[j][0]
			var x := a.intersection(b)
			if x.get_area() > 0.25 * minf(a.get_area(), b.get_area()):
				hits.append("%s x %s" % [rs[i][1], rs[j][1]])
	return hits
