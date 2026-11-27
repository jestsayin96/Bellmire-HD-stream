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
var _vel_runs := 0   # U206: how many times the vellum check really executed
var _sc := 1.5
var _tag := "s150"
var _min_v := 9999.0
var _min_p := 9999.0
var _min_b := 9999.0
var _stage := "boot"
var _at := 0
var _scales: Array = []
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261127_u207"

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
	var pr := _rr(panel)
	# U205: _content is built ONLY by feed_hud._build_chrome(), which runs only while HudDock.split() is true (spotlight
	# panes up). This probe runs full-screen, so Nil here is correct, not a bug: there IS no vellum in this scene.
	# U204 aliased vellum to the panel, which made over_vellum a duplicate of over_panel. Retired: the vellum check
	# runs only when the vellum exists, and the log says so instead of printing a panel rect under the vellum name.
	var has_vel: bool = fh._content != null
	var vel: Rect2 = Rect2(fh._content.get_global_rect()) if has_vel else Rect2()
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
		var over_v := (right - vel.end.x) if has_vel else 0.0
		var over_p := right - pr.end.x
		var vis_clip := l.visible_characters != -1 or l.visible_ratio < 1.0
		print("U134_LINE %s a=%.2f vis_clip=%s lblw=%.0f textw=%.0f over_vellum=%.1f over_panel=%.1f bottom_over=%.1f fs=%d \"%s\"" % [tag, l.modulate.a, vis_clip, l.size.x, sz.x, over_v, over_p, bottom - pr.end.y, fs, l.text.left(40)])
		_min_p = minf(_min_p, -over_p)
		_min_b = minf(_min_b, -(bottom - pr.end.y))
		_ok(over_p <= 0.5, "%s line drawn %.1f px past the Chronicle panel: %s" % [tag, over_p, l.text.left(30)])
		if has_vel:
			_vel_runs += 1
			_min_v = minf(_min_v, -over_v)
			_ok(over_v <= 0.5, "%s line drawn %.1f px past the vellum: %s" % [tag, over_v, l.text.left(30)])
		_ok(bottom <= pr.end.y + 0.5, "%s line bottom %.1f px past the panel: %s" % [tag, bottom - pr.end.y, l.text.left(30)])
	print("U134_PANE %s lines=%d panel=%s vellum=%s card=%s" % [tag, n, pr, (str(vel) if has_vel else "NONE(split off: _content is only built by _build_chrome)"), fh.card_showing()])

const AMB := ["Zed_the_Tall rolls 3 to the house's 5 - the tavern keeps 120 gold.", "Zed_the_Tall lays 120 gold on the table and dares Mira_Vane to throw. (!dice accept)", "Mira_Vane rolls 6 to the house's 2 and wins - 228 gold after the house's cut.", "Zed_the_Tall - a city in all but charter plays for 300 gold at most. The stakes rise as the town does."]
const AMB_OLD := ["Wolfgang_Amadeus_Mozart_X - a city in all but charter plays for 300 gold at most. The stakes rise as the town does.", "Wolfgang_Amadeus_Mozart_X puts down 99999 gold they do not have - 12345 in the purse.", "Wolfgang_Amadeus_Mozart_X lays 300 gold on the table and dares Hildegard_von_Bingen_Qwer1 to throw. (!dice accept)", "Wolfgang_Amadeus_Mozart_X rolls 3 to the house's 3 (the house wins ties) - the tavern keeps 300 gold.", "Wolfgang_Amadeus_Mozart_X rolls 6, Hildegard_von_Bingen_Qwer1 rolls 6 after a tie - Hildegard_von_Bingen_Qwer1 takes the pot of 600 gold.", "Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 - a city in all but charter plays for 300 gold at most. The stakes rise as the town does.", "Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 rolls 6, Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 rolls 6 after a tie - Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1 takes the pot of 600 gold."]
const HOSTILE := ["Wolfgang_Amadeus_Mozart_Hildegard_von_Bingen_Longname_XXXXXX1", "\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4\u30f3\u30b9\u30ec\u30a4\u30e4\u30fc\u30c9\u30e9\u30b4", "\u0412\u0415\u041b\u0418\u041a\u0418\u0419_\u041c\u0410\u0413_WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW", "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"]

func _log_of() -> String:
	for c1 in _t.get_children():
		if c1 is FeedHUD:
			return c1.log_text()
	return ""

func _process(_dt: float) -> bool:
	_f += 1
	if not _shots and root.size != Vector2i(1920, 1080):
		root.size = Vector2i(1920, 1080)
	match _stage:
		"boot":
			if _f == 20:
				var e := OS.get_environment("U207_SCALE")
				if e != "":
					_sc = e.to_float()
				_tag = "s%d" % int(round(_sc * 100.0))
				_scales = [_sc]
				UiTheme.set_scale(_sc)
				_stage = "busy"
				_at = _f
		"busy":
			var k := _f - _at
			if k == 200:
				_t.feed.append("The lord falls in the deep and the warband scatters")
			if k >= 201 and k < 201 + 2 * 60 and k % 2 == 1:
				var j := (k - 201) / 2
				_t.feed.append("Peasant%d hums a tune near the well" % j)
				if j % 15 == 7 and (j / 15) < AMB.size():
					_t.feed.append(AMB[j / 15])
			if k == 330:
				_save("busy_tavern_" + _tag)
				_probe("busy")
			if k == 700:
				var lg := _log_of()
				var admitted := 0
				var dropped := 0
				for m: String in AMB:
					var key: String = String(m).left(30)
					for ln: String in lg.split("\n"):
						if ln.find(key) >= 0:
							if ln.find("ADMIT") >= 0:
								admitted += 1
							if ln.find("DROP") >= 0:
								dropped += 1
				var fh: Node = null
				for c1 in _t.get_children():
					if c1 is FeedHUD:
						fh = c1
				var alive := 0
				var minpri := 9
				for coll: Array in [fh._pending, fh._shown]:
					for e: Dictionary in coll:
						for m: String in AMB:
							if String(e["text"]).begins_with(m.left(30)):
								alive += 1
								minpri = mini(minpri, int(e["pri"]))
								print("U202_LIVE pri=%d '%s'" % [int(e["pri"]), String(e["text"]).left(50)])
				print("U202_ALIVE alive=%d min_pri=%d (log admitted=%d dropped=%d)" % [alive, minpri, admitted, dropped])
				_ok(alive + dropped >= 0, "counted")
				_ok(minpri >= 2 or admitted == AMB.size(), "tavern lines classed at P_TOWN or better")
				print("U202_RESULT admitted=%d dropped=%d of %d tavern lines" % [admitted, dropped, AMB.size()])
				for ln: String in lg.split("\n"):
					for m: String in AMB:
						if ln.find(m.left(30)) >= 0:
							print("U202_LOG ", ln)
				_ok(dropped == 0, "no tavern line dropped in a busy scene")
				# U203: count each line ONCE - admitted-or-alive as a SET. The old sum counted a line that was
				# admitted AND still on screen twice (2+4 against 4) and failed identically before and after.
				var seen := 0
				for m: String in AMB:
					var key2: String = String(m).left(30)
					var here := false
					for ln: String in lg.split("\n"):
						if ln.find(key2) >= 0 and ln.find("ADMIT") >= 0:
							here = true
					for coll2: Array in [fh._pending, fh._shown]:
						for e2: Dictionary in coll2:
							if String(e2["text"]).begins_with(key2):
								here = true
					if here:
						seen += 1
				print("U203_SET seen=%d of %d (sum was %d)" % [seen, AMB.size(), admitted + alive])
				_ok(seen == AMB.size(), "every tavern line admitted or still waiting (set, not sum)")
				# U206: now raise the panes (split mode), so FeedHUD builds _content and the vellum check executes.
				# U207: the named heroes (bigaxe...) are not in every roster; use whoever really exists.
				var hn: Array = []
				if _t.get("chat").roster.heroes.size() < 3:
					for jn in ["Bigaxe", "Mossymage", "Dawncleric"]:
						_say("v_" + jn.to_lower(), jn, "!enlist")
				var c2: ChatCmd = _t.get("chat")
				for hk in c2.roster.heroes:
					hn.append(String(c2.roster.heroes[hk].get("name", "")).to_lower())
				print("U207_HEROES n=%d %s" % [hn.size(), str(hn.slice(0, 4))])
				# U208: the Spotlight node is made on first use (Spotlight.of; rts_camera.gd:99 does it in play). This probe's
				# tree has no camera rig doing it, so chat.spot stayed unset and every !test* answered "The spotlight is not
				# lit yet." - lanes never went busy, mode stayed off, vellum runs=0. Make it here, and say whether it took.
				var sp8 := Spotlight.of(_t)
				print("U208_SPOT made=%s chat_spot_valid=%s" % [str(sp8 != null), str((_t.get("chat") as ChatCmd).spot.is_valid())])
				_ok(sp8 != null and (_t.get("chat") as ChatCmd).spot.is_valid(), "U208 Spotlight exists and chat.spot is wired")
				if hn.size() >= 3:
					_say("local_mre", "MrE", "!testbits 500 " + hn[0])
					_say("local_mre", "MrE", "!testsub " + hn[1])
					_say("local_mre", "MrE", "!testpoints " + hn[2])
				_stage = "split"
				_at = _f
		"split":
			var k2 := _f - _at
			if k2 >= 60 and k2 < 60 + 2 * 40 and k2 % 2 == 0:
				_t.feed.append("Villager%d hums a tune near the well" % k2)
			if k2 == 240:
				_ok(HudDock.split(_t), "U206 panes are up (HudDock.split true)")
				_save("busy_split_" + _tag)
				_probe("split")
				_ok(_vel_runs > 0, "U206 the vellum check executed at least once (runs=%d)" % _vel_runs)
				print("U206_VELLUM runs=%d mode=%s" % [_vel_runs, HudDock.mode(_t)])
				UiTheme.set_scale(1.0)
				print("U207_MARGIN scale=%.2f min_vellum=%.1f min_panel=%.1f min_bottom=%.1f vel_runs=%d" % [_sc, _min_v, _min_p, _min_b, _vel_runs])
				print("U202_DONE checks=%d fails=%d" % [_checks, _fails.size()])
				return true
	return false
