extends SceneTree
## L57 (Mr. E, Nov 13): "NOW WATCHING" goes ABOVE EACH PANE, not one global banner -
## "just have the now watching above each of the split screen for whoever that specific
## screen is watching." Every pane in the 2x2 grid must carry its own label naming the
## subject it follows, and the labels must not cross a pane seam or touch the centre
## Chronicle box (L40). Judged WINDOWED (1920x1080 - a HUD cannot be judged headless,
## COORDINATION 4). Three lanes get paid spotlights on known heroes and the director is
## driven onto a fourth, so all four labels are deterministic; then the lanes are cleared
## to show the ambient labels too. Leaves 1080p shots in renders/cycles/20261113_u7_l57.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261113_u7_l57"
var _crew := {"7101": ["Ashvein", "knight"], "7102": ["Brelda", "mage"], "7103": ["Corin", "rogue"], "7104": ["Dax", "ranger"]}

func _initialize() -> void:
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	_t.call("chat_line", uid, nm, msg)

func _sp() -> Spotlight:
	return Spotlight.of(_t)

func _label(k: String) -> Label:
	return (_sp()._panes[k] as Dictionary)["label"] as Label

func _grab(tag: String) -> void:
	if not _shots:
		return
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)
		for uid in _crew:
			_say(uid, _crew[uid][0], "!enlist " + _crew[uid][1])
		return false
	if _f < 80:
		return false

	match _stage:
		"boot":
			var sp := _sp()
			sp.put("7101", "bits", 90.0, "cheered 100 bits")
			sp.put("7102", "subs", 90.0, "subscribed")
			sp.put("7103", "points", 90.0, "redeemed a look")
			_eye.director._set_on(true)
			_say("7104", _crew["7104"][0], "!hero")
			_stage = "settle"
			_f = 80
		"settle":
			if _f < 170:
				if _f % 30 == 0:
					_say("7104", _crew["7104"][0], "!hero")   # keep the director on our hero
				return false
			var sp := _sp()
			var box := HudDock.centre(_t)
			_ok(sp.mode_now() == "grid", "the 2x2 grid is the resting state (mode=%s)" % sp.mode_now())
			var seen := 0
			for k in ["director", "bits", "subs", "points"]:
				var pr := sp.pane_rect(k)
				var lb := _label(k)
				var has := lb.visible and String(lb.text).strip_edges() != ""
				_ok(has, "%s pane carries a now-watching label (\"%s\")" % [k, lb.text])
				if not has:
					continue
				seen += 1
				_ok(String(lb.text).begins_with("Now watching"), "%s reads 'Now watching...' (\"%s\")" % [k, lb.text])
				var lr := lb.get_global_rect()
				_ok(not lr.intersects(box), "%s label clears the Chronicle box" % k)
				_ok(pr.grow(2.0).encloses(lr), "%s label stays inside its own pane (no seam cross)" % k)
			_ok(seen == 4, "all four panes are labelled (%d/4)" % seen)
			_ok(String(_label("bits").text).contains("Ashvein"), "bits names its paid hero (\"%s\")" % _label("bits").text)
			_ok(String(_label("subs").text).contains("Brelda"), "subs names its paid hero (\"%s\")" % _label("subs").text)
			_ok(String(_label("points").text).contains("Corin"), "points names its paid hero (\"%s\")" % _label("points").text)
			var rects: Array = []
			for k in ["director", "bits", "subs", "points"]:
				var lb := _label(k)
				if lb.visible:
					rects.append(lb.get_global_rect())
			var clash := 0
			for i in rects.size():
				for j in range(i + 1, rects.size()):
					if (rects[i] as Rect2).intersects(rects[j]):
						clash += 1
			_ok(clash == 0, "no two pane labels overlap each other (%d clashes)" % clash)
			_grab("grid_labels_1080")
			# F10 hides every pane label with the rest of the chrome
			sp.set_labels(false)
			var hidden := 0
			for k in ["director", "bits", "subs", "points"]:
				if not _label(k).visible:
					hidden += 1
			_ok(hidden == 4, "F10 hides every pane label (%d/4)" % hidden)
			sp.set_labels(true)
			# now clear the paid lanes so they fall back to ambient town life, and look again
			for l in Spotlight.LANES:
				(sp.lanes[l] as Dictionary)["cur"] = {}
				(sp.lanes[l] as Dictionary)["q"] = []
			sp._relayout(true)
			_stage = "ambient"
			_f = 170
		"ambient":
			if _f < 320:
				return false
			var sp := _sp()
			var box := HudDock.centre(_t)
			var amb := 0
			for k in ["director", "bits", "subs", "points"]:
				var lb := _label(k)
				if lb.visible and String(lb.text).strip_edges() != "":
					amb += 1
					_ok(String(lb.text).begins_with("Now watching"), "%s (ambient) reads 'Now watching...' (\"%s\")" % [k, lb.text])
					_ok(not lb.get_global_rect().intersects(box), "%s (ambient) label clears the Chronicle box" % k)
			_ok(amb >= 2, "ambient lanes relabel to their own subjects (%d panes labelled)" % amb)
			_grab("grid_ambient_1080")
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L57_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	if _f > 4000:
		print("L57_TEST timed out at ", _stage)
		print("L57_TEST FAIL")
		return true
	return false
