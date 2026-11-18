extends SceneTree
## U68 RED PROOF of the U67 fix: identical to _l40_test.gd except that the Chronicle is inflated past 35% before the audit. MUST print FAIL.
## L40 test (WINDOWED 1080p, --script). Every HUD element that is up at once - chat box, Chronicle,
## party frames, boss card, unit frame, lane plates, clock - must share ZERO pixels with any other.
## Chat open + Chronicle running + the subs lane up (the alert's in-game face), at UI scale
## 100/150 in the grid AND full screen. Pane/background boxes (>=35% of the screen) are skipped.
var _t: Node3D
var _eye: RtsCamera
var _hud: FeedHUD
var _f := 0
var _t0 := -1.0
var _out := ""
var _step := 0
var _fed := 0
var _bad := 0
const SC := [1.0, 1.5]
const LINES := ["A trade caravan is sighted on the west road.", "Viewer1001 swings a sword at a raider - hit! 7 damage.",
	"Viewer1002 gathers wood.", "The granary is down to 12 days of food - hunger looms.", "Viewer1004 hauls a sack of grain."]
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/u68/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for c in _t.get_children():
			if c is FeedHUD:
				_hud = c
	if _f < 60 or _hud == null:
		return false
	if _t0 < 0.0:
		_t0 = Time.get_ticks_msec() / 1000.0
	var now := Time.get_ticks_msec() / 1000.0 - _t0
	var base := float(_step) * 5.0
	if now < base:
		return false
	var t := now - base
	var sc: float = SC[_step / 2]
	var full := (_step % 2) == 1
	if t < 0.1 and _fed == 0:
		UiTheme.scale = sc
		_hud.restyle()
		var sp := Spotlight.of(_t)
		if sp != null:
			sp.suspend(full)
		_eye._chat.visible = true
		_eye._chat.text = "!hero what is my hero doing right now"
	if t < 2.5:
		var want := int(t / 2.5 * 18.0)
		while _fed < want:
			_hud.source.append(LINES[_fed % LINES.size()] + " (" + str(_fed) + ")")
			_fed += 1
	if t >= 4.0:
		for cl in root.find_children("*", "CanvasLayer", true, false):
			for k in (cl as Node).get_children():
				if k is PanelContainer and str(k.name).contains("Chronicle"):
					(k as Control).custom_minimum_size = Vector2(1700, 900)
					(k as Control).size = Vector2(1700, 900)
		_audit(int(sc * 100.0), full)
		root.get_texture().get_image().save_png(_out + "l40_%s_%d.png" % ["full" if full else "grid", int(sc * 100.0)])
		_step += 1
		_fed = 0
		if _step >= SC.size() * 2:
			print("U68_REDPROOF ", "OK" if _bad == 0 else "FAIL")
			return true
	return false
func _audit(pct: int, full: bool) -> void:
	var tag := "%d%% %s" % [pct, "full" if full else "grid"]
	var scr := Vector2(root.size)
	var items: Array = []
	for cl in root.find_children("*", "CanvasLayer", true, false):
		for k in (cl as Node).get_children():
			if not (k is Control and (k as Control).is_visible_in_tree()):
				continue
			if str(k.name).begins_with("Pane_"):
				# a pane box is the container its own plate / boss card / frames live in:
				# audit what is drawn ON it, never the box against the Chronicle at the cross
				for pc in (k as Node).get_children():
					if pc is Control and (pc as Control).is_visible_in_tree():
						var pr := (pc as Control).get_global_rect()
						if pr.size.x >= 4.0 and pr.size.y >= 4.0 and pr.size.x * pr.size.y < 0.20 * scr.x * scr.y:
							items.append([str(k.name) + "/" + str(pc.name) + ":" + pc.get_class(), pr])
				continue
			var r := (k as Control).get_global_rect()
			if r.size.x * r.size.y >= 0.35 * scr.x * scr.y and (str(k.name).contains("Chronicle") or str(k.name).contains("BossCard") or str(k.name).contains("Feed")):
				# U67: the 35% skip is for backdrops; a NAMED HUD element that has grown past it is the fault, not a backdrop
				print("FAIL named HUD element inflated past the backdrop skip @", tag, ": ", k.name, " ", r); _bad += 1
			if r.size.x < 4.0 or r.size.y < 4.0 or r.size.x * r.size.y >= 0.35 * scr.x * scr.y:
				continue
			items.append([str(k.name) + ":" + k.get_class(), r])
	print("  [", tag, "] ", items.size(), " elements")
	for it in items:
		print("     ", it[0], " ", it[1])
	for i in items.size():
		for j in range(i + 1, items.size()):
			if (items[i][1] as Rect2).intersects(items[j][1]):
				print("FAIL overlap @", tag, ": ", items[i][0], " x ", items[j][0]); _bad += 1
