extends SceneTree
## L16: one theme. Every panel is the house parchment; titles carry the teal rule.
## Prints L16_TEST OK. (The look: tools/_l16_shot.gd.)
var _fail := 0
var _f := 0
var _feed := FeedHUD.new()
var _board := LeaderboardPanel.new()
var _bar := BossBar.new()

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _parch(c: Control) -> bool:
	var sb := c.get_theme_stylebox("panel") as StyleBoxFlat
	return sb != null and sb.bg_color.is_equal_approx(UiTheme.parchment().bg_color)

func _has_teal(n: Node) -> bool:
	for c in n.find_children("*", "ColorRect", true, false):
		if (c as ColorRect).color.is_equal_approx(UiTheme.TEAL) or Color((c as ColorRect).color, 1.0).is_equal_approx(UiTheme.TEAL):
			return true
	return false

func _initialize() -> void:
	var r := Roster.new()
	root.add_child(r)
	r.fresh("a", "Ash", "knight", "human")
	_feed.source = ["A line."]
	root.add_child(_feed)
	root.add_child(_board)
	_board.setup(r)
	root.add_child(_bar)
	_bar.setup(null)

func _process(_d: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	_ok(_parch(_feed._panel) and _has_teal(_feed._panel), "the Chronicle: parchment, a teal-ruled title")
	_ok(_parch(_board._panel) and _has_teal(_board._panel), "the Guild Roll: parchment, a teal-ruled title")
	_ok(_parch(_bar._plate), "the boss bar: on a parchment plate")
	var t := UiTheme.title("X")
	_ok(_has_teal(t), "UiTheme.title carries the teal diamond and rule")
	t.free()
	var src := FileAccess.get_file_as_string("res://scripts/rts_camera.gd") + FileAccess.get_file_as_string("res://scripts/party_frames.gd")
	_ok(src.contains("UiTheme.parchment()") and src.contains("UiTheme.chip()") and src.contains("UiTheme.bar("), "the unit frame, chips, chat and party frames build from the theme")
	print("L16_TEST OK" if _fail == 0 else "L16_TEST FAIL %d" % _fail)
	return true
