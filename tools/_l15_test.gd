extends SceneTree
## L15: stream readability. Viewer-facing text at least ~28 px at 1080p (100%);
## F11 cycles 100/125/150%; every panel restyles. Prints L15_TEST OK.
## (The look is checked by tools/_l15_shot.gd: 1080p and a 854x480 phone frame.)
var _fail := 0
var _f := 0
var _feed := FeedHUD.new()
var _board := LeaderboardPanel.new()
var _r: Roster

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _fs(c: Control) -> int:
	return c.get_theme_font_size("font_size")

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	_r.fresh("a", "Ash", "knight", "human")
	_feed.source = ["A line for the Chronicle.", "Another, a little longer, for the wrap."]
	root.add_child(_feed)
	root.add_child(_board)
	_board.setup(_r)

func _process(_d: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	var k := UiTheme.res_k()
	print("  window height %d -> sizes x%.2f of 1080p" % [root.size.y, k])
	var line: Label = null
	for c in _feed._box.get_children():
		if c is Label:
			line = c
	_ok(line != null and float(_fs(line)) / k >= 27.5, "a Chronicle line is %.0f px at 1080p" % (float(_fs(line)) / k))
	var roll: Array = _board._list.get_children().filter(func(c): return c is Label and not c.is_queued_for_deletion())
	_ok(roll.size() >= 1 and float(_fs(roll[0])) / k >= 25.5, "a Guild Roll line is %.0f px at 1080p" % (float(_fs(roll[0])) / k))
	_ok(UiTheme.px(28) == int(round(28.0 * k)), "px() is 1080p pixels times the window")
	var before := _fs(line)
	_ok(is_equal_approx(UiTheme.cycle(), 1.25) and is_equal_approx(UiTheme.cycle(), 1.5) and is_equal_approx(UiTheme.cycle(), 1.0), "F11 cycles 100 -> 125 -> 150 -> 100%")
	UiTheme.set_scale(1.5)
	var line2: Label = null
	for c in _feed._box.get_children():
		if c is Label and not c.is_queued_for_deletion():
			line2 = c
	_ok(line2 != null and _fs(line2) > before, "the Chronicle restyled bigger at 150%% (%d -> %d)" % [before, _fs(line2)])
	UiTheme.set_scale(1.0)
	print("L15_TEST OK" if _fail == 0 else "L15_TEST FAIL %d" % _fail)
	return true
