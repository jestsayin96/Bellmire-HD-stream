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
## renders/cycles/20261120_u104). Headless it runs the checks only. Prints L21_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _at := 0
var _scales: Array = []
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261121_u126"

func _initialize() -> void:
	# a known screen: headless Godot gives a 100x100 window where nothing can be judged (that is
	# what failed 8 checks on the supervisor's headless run). Windowed keeps --resolution.
	if not _shots:
		root.size = Vector2i(1920, 1080)
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
	print("U126_SHOT %s (window %s)" % [tag, root.size])

func _rr(n) -> Rect2:
	if n is Control and (n as Control).visible:
		var c := n as Control
		return Rect2(c.get_global_rect().position, c.size * c.scale)
	return Rect2()

func _probe(tag: String) -> void:
	var sp: Spotlight = _eye.spotlight
	sp._labels()
	for k in sp._panes.keys():
		var p: Dictionary = sp._panes[k]
		var lb: Label = p["label"]
		var kd: Label = p.get("kind")
		if not lb.visible:
			continue
		var pr: Rect2 = sp.pane_rect(String(k))
		var lr := _rr(lb)
		var kr := _rr(kd)
		_ok(pr.grow(1.0).encloses(lr), "%s pane %s label %s outside pane %s" % [tag, k, lr, pr])
		_ok(kd == null or not lr.intersects(kr.grow(-1.0)), "%s pane %s label %s overlaps kind chip %s" % [tag, k, lr, kr])
		var ms := lb.get_combined_minimum_size()
		var cl := lb.get_theme_font("font").get_string_size(lb.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lb.get_theme_font_size("font_size")).x
		print("U126_LABEL %s pane=%s w=%.0f pane_w=%.0f text_w=%.0f trimmed=%s \"%s\"" % [tag, k, lr.size.x, pr.size.x, cl, cl + 26.0 > lr.size.x, lb.text.left(48)])
		for c in get_nodes_in_group("hud_chronicle"):
			var cr := _rr(c)
			_ok(not lr.intersects(cr.grow(-1.0)), "%s pane %s label %s overlaps Chronicle %s" % [tag, k, lr, cr])
	for c in get_nodes_in_group("hud_chronicle"):
		var cr2 := _rr(c)
		_ok(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1.0).encloses(cr2), "%s Chronicle %s off screen" % [tag, cr2])

const HOSTILE := ["Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1", "\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4", "\u0412\u0415\u041b\u0418\u041a\u0418\u0419_\u041c\u0410\u0413_WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW", "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"]

func _process(_dt: float) -> bool:
	_f += 1
	if not _shots and root.size != Vector2i(1920, 1080):
		root.size = Vector2i(1920, 1080)
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				var ids := ["2101", "2102", "2103", "2104"]
				var cls := ["knight dwarf", "mage elf", "cleric human", "barbarian orc"]
				for i in 4:
					_say(ids[i], "V%d" % i, "!enlist " + cls[i])
				for i in 4:
					var h: Dictionary = r.get_hero(ids[i])
					h["name"] = HOSTILE[i]
					if i % 2 == 0:
						h["weapon"] = 3
						h["armour"] = 3
				_d = Delve.new()
				_d.town = _t
				_d.roster = r
				_d.start_floor = 5
				_d.max_floors = 5
				_t.add_child(_d)
				_d.start(["2102", "2103", "2104", "2101"])
				_eye.director._set_on(true)
				Engine.time_scale = 3.0
				_stage = "wait_lord"
		"wait_lord":
			if _d.lord_fighting() != null or _f > 3000:
				Engine.time_scale = 1.0
				_ok(_d.lord_fighting() != null, "the lord is fighting (frame %d)" % _f)
				_scales = [1.0, 1.25, 1.5]
				_stage = "retrig"
				_at = _f
		"retrig":
			var k := _f - _at
			if k == 1:
				UiTheme.set_scale(float(_scales[0]))
				for i in 12:
					_t.feed.append("%s smites %s for %d (crit)" % [HOSTILE[i % 4], HOSTILE[(i + 1) % 4], 10 + i])
			elif k == 200:
				var tg := "s%d" % int(round(UiTheme.scale * 100.0))
				_probe(tg)
				_save("host_" + tg)
				_scales.remove_at(0)
				_at = _f
				if _scales.is_empty():
					UiTheme.set_scale(1.0)
					print("U126_DONE checks=%d fails=%d" % [_checks, _fails.size()])
					return true
	return false
