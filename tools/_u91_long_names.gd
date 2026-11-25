extends SceneTree
## U91 (L74): the Chronicle under load, WINDOWED 1920x1080 --script. At UiTheme scale 100/125/150 a mixed flood
## (routine / normal / town / crit lines, every key distinct) is raised at once. Per frame: shown <= _cap(), pending
## <= QUEUE_MAX, every label inside the viewport and inside the feed panel. At the end: no P_TOWN/P_CRIT line was
## dropped (stats.dropped_protected == 0), the crit lines were all ADMITTED, and the panel rect was COUNTED
## (the U85 sweep never saw the feed: its panel is hidden while empty). Arg "break" lowers the viewport check
## by shrinking the allowed rect to prove the check goes red. NO VERDICT if no label was ever measured.
var _t: Node3D
var _f := 0
var _step := 0
var _phase := 0
var _wait := 0
var _tag := "run"
var _fails := 0
var _labels := 0
var _panels := 0
var _frames_in := 0
var _out := ""
var _foreign := {}
const MINE := ["hud_dock.gd","spotlight.gd","auto_director.gd","dice.gd","feed_hud.gd","leaderboard_panel.gd","ui_theme.gd"]
const W1 := ["moss","flint","ember","thistle","wren","cinder","barley","sorrel","tallow","hazel","pitch","bracken","kestrel","lichen","mortar","nettle","oakum","plover","quill","russet"]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _tag = a[0]
	_out = ProjectSettings.globalize_path("res://renders/cycles/u91/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _hud() -> FeedHUD:
	for c in _t.get_children():
		if c is FeedHUD: return c
	return null
const LONG := ["Bartholomew-Wigglesworth-of-Thistledown","Ælfwynn_the_Unreasonably_Long_Named","Maximilianus_Quartermain_IV","xX_DragonSlayer_Of_The_Nine_Realms_Xx","Goodwife_Perpetua_Hawthorne-Underbough"]
func _flood(h: FeedHUD, pct: int) -> void:
	for w in LONG:
		for i in 3:
			h.source.append("%s picks up a very heavy oaken log number %d from the far lumber lane" % [w, i])
		h.source.append("%s has fallen to the raiders at the northern gate, mourned by the whole market" % w)
	for w in W1.slice(0, 12):
		h.source.append("Goodwife %s chops a %s bough" % [w, w])
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		var eye := RtsCamera.new(); _t.add_child(eye); eye.setup(_t)
	if _f < 90: return false
	if _wait > 0:
		_wait -= 1; return false
	if root.get_visible_rect().size.x < 1919 or root.get_visible_rect().size.y < 1079:
		print("U91 NO VERDICT - capture %s is smaller than 1920x1080; run --windowed --resolution 1920x1080" % str(root.get_visible_rect().size)); quit(2); return true
	var sc := [1.0, 1.25, 1.5]
	var h := _hud()
	if h == null:
		print("U91 NO FEED HUD - NO VERDICT"); quit(2); return true
	if _step >= 3:
		print("U91 labels=", _labels, " panels=", _panels, " fails=", _fails, " stats=", h.stats)
		var crit := 0
		for l in h.feed_log:
			if String(l).contains("ADMIT pri=3"): crit += 1
		print("U91 crit admitted=", crit)
		if int(h.stats["dropped_protected"]) > 0:
			_fails += 1; print("  FAIL protected line dropped: ", h.stats["dropped_protected"])
		if crit < 4:
			_fails += 1; print("  FAIL crit lines admitted ", crit, " < 4")
		if _labels < 10 or _panels < 3:
			print("LONGNAME NO VERDICT - nothing measured"); quit(2); return true
		for k in _foreign: print("LONGNAME FOREIGN (not HUD-owned) off-screen: ", k, " ", _foreign[k])
		print("LONGNAME ", "OK" if _fails == 0 else "FAIL"); quit(1 if _fails > 0 else 0); return true
	var pct := int(sc[_step] * 100.0)
	if _phase == 0:
		UiTheme.set_scale(sc[_step]); _phase = 1; _wait = 8; _frames_in = 0; return false
	if _phase == 1:
		_flood(h, pct); _phase = 2; return false
	_frames_in += 1
	_measure(h, pct)
	if _frames_in == 150:
		root.get_texture().get_image().save_png(_out + "u91_%s_%d.png" % [_tag, pct])
	if _frames_in >= 420:    # ~7 s: long enough for ~8 admissions at PACE_S
		_step += 1; _phase = 0; _wait = 2
	return false
func _measure(h: FeedHUD, pct: int) -> void:
	var vp := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	if _tag == "break": vp = Rect2(Vector2.ZERO, Vector2(300, 200))
	var up := 0   # what is DRAWN, not what _shown remembers (a scale step trims the drawing; _shown keeps the dwell clock)
	for lb in h._box.get_children():
		if lb is Label and not (lb as Label).is_queued_for_deletion(): up += 1
	if up > h._cap():
		_fails += 1; print("  FAIL ", pct, "% drawn ", up, " > cap ", h._cap())
	if h._pending.size() > FeedHUD.QUEUE_MAX:
		_fails += 1; print("  FAIL ", pct, "% pending ", h._pending.size())
	if h._panel != null and h._panel.is_visible_in_tree() and h._panel.modulate.a > 0.5:
		var pr := h._panel.get_global_rect()
		_panels += 1
		if not vp.grow(1.0).encloses(pr):
			_fails += 1; print("  FAIL ", pct, "% panel off-screen ", pr)
		for lb in h._box.get_children():
			if lb is Label and not (lb as Label).is_queued_for_deletion() and (lb as Label).size.y > 4.0:
				_labels += 1
				var r := (lb as Label).get_global_rect()
				if not vp.grow(1.0).encloses(r):
					_fails += 1; print("  FAIL ", pct, "% label off-screen ", r, " '", (lb as Label).text.left(30), "'")
	var vis := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	if _tag == "break": vis = Rect2(Vector2.ZERO, Vector2(300, 200))
	for cl in root.find_children("*", "CanvasLayer", true, false):
		for lb in (cl as Node).find_children("*", "Label", true, false):
			var L := lb as Label
			if not L.is_visible_in_tree() or L.size.y < 4.0 or L.modulate.a < 0.5 or L.text == "": continue
			_labels += 1
			if not vis.grow(1.0).encloses(L.get_global_rect()):
				var own: Variant = cl.get_parent().get_script() if cl.get_parent() != null else null
				var op: String = (own as Script).resource_path.get_file() if own != null else "?"
				if not (op in MINE):
					_foreign[op + ":" + L.text.left(6)] = L.get_global_rect(); continue
				_fails += 1; print("  FAIL ", pct, "% HUD label off-screen ", L.get_global_rect(), " '", L.text.left(30), "' in ", L.get_path())
