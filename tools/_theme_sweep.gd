extends SceneTree
## U85 theme-at-scale sweep (WINDOWED, --script). For UiTheme scale 100/125/150: every watched panel's visible
## Controls must lie inside the viewport, and top-level panels must not overlap each other. NO VERDICT if < 4 panels
## were found. Arg "break_shift" nudges one panel off-screen to prove the check goes red.
var _t: Node3D
var _f := 0
var _step := 0
var _wait := 0
var _bad := 0
var _tag := "run"
var _out := ""
var _panels := 0
var _feed := 0   # U94: FeedHUD's Chronicle (a ChronicleScroll Control, not a PanelContainer) counted by name so the floor stops being the whole verdict
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/u85/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
var _phase := 0   # 0 = set scale, 1 = checking after settle
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var eye := RtsCamera.new(); _t.add_child(eye); eye.setup(_t)
	if _f < 90: return false
	if _wait > 0:
		_wait -= 1; return false
	var sc := [1.0, 1.25, 1.5]
	if _step >= 3:
		print("U85 panels=", _panels, " feed_chronicle=", _feed, " bad=", _bad)
		if _feed < 3:
			print("THEME_SWEEP NO VERDICT - FeedHUD Chronicle not seen at all three scales (", _feed, ")"); quit(2); return true
		if _panels < 12:
			print("THEME_SWEEP NO VERDICT - too few panel checks"); quit(2); return true
		print("THEME_SWEEP ", "OK" if _bad == 0 else "FAIL"); quit(1 if _bad > 0 else 0); return true
	if _phase == 0:
		UiTheme.set_scale(sc[_step]); _phase = 1; _wait = 8; return false
	_check(int(sc[_step] * 100.0))
	root.get_texture().get_image().save_png(_out + "u85_%s_%d.png" % [_tag, int(sc[_step] * 100.0)])
	_step += 1; _phase = 0; _wait = 2
	return false
func _check(pct: int) -> void:
	var vp := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	var tops: Array = []
	for l in UiTheme._watch:
		if not is_instance_valid(l): continue
		var rects: Array = []
		_walk(l, rects)
		for r in rects:
			_panels += 1
			# U86: shift every 4th panel rect (watch order/type independent - `l is FeedHUD` and `_watch[0]` both matched nothing: only 4 panels/scale exist, 12 total)
			if _tag == "break_shift" and _panels % 4 == 1: r = Rect2(r.position + Vector2(5000, 0), r.size)
			if not vp.grow(1.0).encloses(r):
				_bad += 1; print("  OFFSCREEN ", pct, "% ", l.name, " ", r, " vp ", vp)
		if rects.size() > 0: tops.append([l.name, rects[0]])
	for i in tops.size():
		for j in range(i + 1, tops.size()):
			var a: Rect2 = tops[i][1]; var b: Rect2 = tops[j][1]
			if a.intersection(b).get_area() > 4.0:
				print("  OVERLAP ", pct, "% ", tops[i][0], " ", a, " x ", tops[j][0], " ", b)
func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and (c as Control).is_visible_in_tree() and (c as Control).size.x > 8.0 and (c as Control).size.y > 8.0:
			if c is PanelContainer or c is Panel or c is HudDock.ChronicleScroll:
				if c is HudDock.ChronicleScroll: _feed += 1
				out.append((c as Control).get_global_rect())
		_walk(c, out)
