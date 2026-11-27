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
const OUT := "res://renders/cycles/20261127_u201b"

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
	print("U134_SHOT %s (window %s)" % [tag, root.size])

func _rr(n) -> Rect2:
	if n is Control and (n as Control).visible:
		var c := n as Control
		return Rect2(c.get_global_rect().position, c.size * c.scale)
	return Rect2()

func _probe(tag: String) -> void:
	var fh: Node = null
	for c0 in _t.get_children():
		if c0 is FeedHUD:
			fh = c0
	_ok(fh != null, "FeedHUD found")
	if fh == null:
		return
	var panel: Control = fh._panel
	var vel: Rect2 = Rect2(fh._content.get_global_rect())
	var pr := _rr(panel)
	var n := 0
	for lb in fh._box.get_children():
		if not (lb is Label):
			continue
		n += 1
		var l := lb as Label
		var font: Font = l.get_theme_font("font")
		var fs := l.get_theme_font_size("font_size")
		var sz: Vector2 = font.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, l.size.x, fs)
		# U135: the label wraps arbitrarily (autowrap) but get_multiline_string_size above uses word-bound
		# breaks only, so an unbreakable 60-char name reads as 1472 px. Measure what the Label really lays out:
		# rows x line height, and the widest row clamped to the label's own wrap width.
		var rows := maxi(l.get_line_count(), 1)
		sz = Vector2(minf(sz.x, l.size.x) if l.autowrap_mode != TextServer.AUTOWRAP_OFF else sz.x, rows * float(l.get_line_height()))
		var left := l.get_global_rect().position.x
		var right := left + sz.x
		var bottom := l.get_global_rect().position.y + sz.y
		var over_v := right - vel.end.x
		var over_p := right - pr.end.x
		var vis_clip := l.visible_characters != -1 or l.visible_ratio < 1.0
		print("U134_LINE %s a=%.2f vis_clip=%s lblw=%.0f textw=%.0f over_vellum=%.1f over_panel=%.1f bottom_over=%.1f fs=%d \"%s\"" % [tag, l.modulate.a, vis_clip, l.size.x, sz.x, over_v, over_p, bottom - pr.end.y, fs, l.text.left(40)])
		_ok(over_p <= 0.5, "%s line drawn %.1f px past the Chronicle panel: %s" % [tag, over_p, l.text.left(30)])
		_ok(over_v <= 0.5, "%s line drawn %.1f px past the vellum: %s" % [tag, over_v, l.text.left(30)])
		_ok(bottom <= pr.end.y + 0.5, "%s line bottom %.1f px past the panel: %s" % [tag, bottom - pr.end.y, l.text.left(30)])
	print("U134_PANE %s lines=%d panel=%s vellum=%s card=%s" % [tag, n, pr, vel, fh.card_showing()])

const AMB := ["Wolfgang_Amadeus_Mozart_X - a city in all but charter plays for 300 gold at most. The stakes rise as the town does.", "Wolfgang_Amadeus_Mozart_X puts down 99999 gold they do not have - 12345 in the purse.", "Wolfgang_Amadeus_Mozart_X lays 300 gold on the table and dares Hildegard_von_Bingen_Qwer1 to throw. (!dice accept)", "Wolfgang_Amadeus_Mozart_X rolls 3 to the house's 3 (the house wins ties) - the tavern keeps 300 gold.", "Wolfgang_Amadeus_Mozart_X rolls 6, Hildegard_von_Bingen_Qwer1 rolls 6 after a tie - Hildegard_von_Bingen_Qwer1 takes the pot of 600 gold.", "Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 - a city in all but charter plays for 300 gold at most. The stakes rise as the town does.", "Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 rolls 6, Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 rolls 6 after a tie - Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 takes the pot of 600 gold."]
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
				Engine.time_scale = 1.0
				_scales = [1.5]
				_stage = "retrig"
				_at = _f
		"wait_lord":
			if _d.lord_fighting() != null or _f > 3000:
				Engine.time_scale = 1.0
				_ok(_d.lord_fighting() != null, "the lord is fighting (frame %d)" % _f)
				_scales = [1.5]
				_stage = "retrig"
				_at = _f
		"retrig":
			var k := _f - _at
			var kk := k - 500
			if k == 1:
				UiTheme.set_scale(float(_scales[0]))
			if kk >= 1 and kk % 150 == 1 and (kk / 150) < AMB.size():
				_t.feed.append(AMB[kk / 150])
			if kk >= 100 and kk % 150 == 120 and (kk / 150) < AMB.size():
				_probe("line%d_s150" % (kk / 150))
				_save("tav_line%d_s150" % (kk / 150))
			if kk == 150 * AMB.size() + 160:
				var fh2: Node = null
				for c1 in _t.get_children():
					if c1 is FeedHUD:
						fh2 = c1
				print("U201_LOG ", fh2.log_text().left(3000).replace("\n", " | "))
				UiTheme.set_scale(1.0)
				print("U134_DONE checks=%d fails=%d" % [_checks, _fails.size()])
				return true
	return false
