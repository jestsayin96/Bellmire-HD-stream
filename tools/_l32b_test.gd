extends SceneTree
## L32b: the Chronicle at the CENTRE of the 2x2 - a full-width strip at the cross of
## the four panes - with calm pacing. Windowed --resolution 1920x1080 (the capture is
## the point); headless it runs the geometry/pacing checks only. Checks:
##   - the strip sits between the two pane rows, full width, and the Chronicle panel
##     is inside it (home "centre"), readable at the L15 size (28 px lines)
##   - the pane rows sit flush above and below the strip (no pane under it)
##   - CALM PACING: 40 feed lines land at once; the strip reveals at most one new
##     line per PACE_S (newest-visible text changes <= 7 in 4 s), and within 10 s it
##     has skipped ahead to the LATEST lines (never racing the whole backlog)
##   - 1080p capture with the grid up and the Chronicle at the centre
## Prints L32B_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _t0 := 0.0
var _newest := ""
var _changes := 0
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l32"

func _initialize() -> void:
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
		print("  FAIL ", what)

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _hud() -> FeedHUD:
	for c in _t.get_children():
		if c is FeedHUD:
			return c
	return null

func _newest_text() -> String:
	var h := _hud()
	if h == null or h._box == null:
		return ""
	var kids := h._box.get_children()
	for i in range(kids.size() - 1, -1, -1):
		if kids[i] is Label and not (kids[i] as Label).is_queued_for_deletion():
			return (kids[i] as Label).text
	return ""

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
				for v in [["3201", "Hale", "!enlist knight dwarf"], ["3202", "Moss", "!enlist mage elf"]]:
					_say(v[0], v[1], v[2])
				_eye.director._set_on(true)
				_stage = "settle"
				_t0 = _now()
		"settle":
			# let the strip build and the enlist lines pace in
			if _now() - _t0 >= 6.0:
				var hud := _hud()
				var s := Spotlight.of(_t)
				var strip := HudDock.centre(_t)
				_ok(hud != null and hud._panel != null and hud._panel.visible, "the Chronicle is up")
				_ok(strip.size.y >= root.size.y * 0.07 and strip.size.x >= root.size.x * 0.98, "the centre strip is full width (%s)" % strip)
				var pr := hud._panel.get_global_rect()
				_ok(HudDock.region_of(hud._panel) == "centre", "the Chronicle's home is 'centre' (got '%s')" % HudDock.region_of(hud._panel))
				_ok(pr.position.y >= strip.position.y - 1.0 and pr.end.y <= strip.end.y + 1.0 and pr.position.x >= strip.position.x - 1.0 and pr.end.x <= strip.end.x + 1.0, "the Chronicle panel is inside the strip (%s in %s)" % [pr, strip])
				# the pane rows part flush around the strip
				var dr := s.pane_rect("director")
				var sr := s.pane_rect("subs")
				_ok(absf(dr.end.y - strip.position.y) <= 2.0, "the top row ends at the strip (%0.f vs %.0f)" % [dr.end.y, strip.position.y])
				_ok(absf(sr.position.y - strip.end.y) <= 2.0, "the bottom row starts under the strip (%.0f vs %.0f)" % [sr.position.y, strip.end.y])
				var fs := 0
				for lb in hud._box.get_children():
					if lb is Label:
						fs = maxi(fs, (lb as Label).get_theme_font_size("font_size"))
				_ok(fs >= UiTheme.px(28) - 1, "Chronicle lines at the L15 size (%d px)" % fs)
				# the busy moment: 40 lines at once
				var feed: Array = _t.get("feed")
				for i in 40:
					feed.append("Busy line %d - the town will not scroll like crazy." % i)
				_newest = _newest_text()
				_changes = 0
				_stage = "pace"
				_t0 = _now()
		"pace":
			var nt := _newest_text()
			if nt != _newest:
				_newest = nt
				_changes += 1
			if _now() - _t0 >= 4.0:
				# <= one reveal per PACE_S: 4 s / 0.8 + 2 slack
				_ok(_changes >= 2 and _changes <= 7, "calm pacing: %d newest-line changes in 4 s (want 2-7)" % _changes)
				_stage = "caught"
				_t0 = _now()
		"caught":
			var nt := _newest_text()
			if nt != _newest:
				_newest = nt
				_changes += 1
			if _now() - _t0 >= 10.0:
				# the town kept narrating during the wait, so "latest" = within the last
				# FLOOD-and-a-bit lines of the live feed, never stuck back in the backlog
				var src: Array = _t.get("feed")
				var tail: Array = src.slice(maxi(0, src.size() - FeedHUD.FLOOD - 3))
				_ok(tail.has(_newest), "the flood skipped ahead to the LATEST lines (newest '%s')" % _newest.substr(0, 40))
				if _shots:
					var img := root.get_texture().get_image()
					img.save_png(ProjectSettings.globalize_path(OUT + "/b_centre_1080.png"))
					print("L32B_SHOT b_centre (window %s)" % root.size)
				print("L32B_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
				return true
	return false
