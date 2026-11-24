extends SceneTree
## U69 RED PROOF of the in-pane 20% named-element check: oversize BossCard injected into a visible pane. MUST print FAIL.
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
var _n := 0  # U154: elements audited
var _control := false  # U156: `-- control` skips the injection; the SAME gate must then print OK (proves the FAIL is the injection, not the HUD)
var _inflated := 0  # U156: count of the named-element-inflated FAIL lines
const SC := [1.0, 1.5]
const LINES := ["A trade caravan is sighted on the west road.", "Viewer1001 swings a sword at a raider - hit! 7 damage.",
	"Viewer1002 gathers wood.", "The granary is down to 12 days of food - hunger looms.", "Viewer1004 hauls a sack of grain."]
func _initialize() -> void:
	_control = "control" in OS.get_cmdline_user_args()
	_out = ProjectSettings.globalize_path("res://renders/cycles/u69/")
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
		var _inj := 0
		for cl2 in root.find_children("*", "CanvasLayer", true, false):
			for k2 in (cl2 as Node).get_children():
				if k2 is Control and str(k2.name).begins_with("Pane_") and (k2 as Control).is_visible_in_tree() and _inj == 0 and not _control:
					var bc := Panel.new()
					bc.name = "BossCard"
					bc.size = Vector2(1500, 800)
					(k2 as Node).add_child(bc)
					bc.global_position = (k2 as Control).global_position
					_inj += 1
		print("  injected oversize BossCard into ", _inj, " visible pane(s)")
		_audit(int(sc * 100.0), full)
		root.get_texture().get_image().save_png(_out + "l40_%s_%d.png" % ["full" if full else "grid", int(sc * 100.0)])
		_step += 1
		_fed = 0
		if _step >= SC.size() * 2:
			if _n == 0: print("U69_REDPROOF NO VERDICT - 0 elements audited"); _bad += 1
			print("U69_REDPROOF ", "OK" if _bad == 0 else "FAIL", " elements=", _n, " arm=", "CONTROL(no injection, must be OK)" if _control else "RED(injected, must FAIL)", " inflated_fails=", _inflated)
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
						if pr.size.x * pr.size.y >= 0.20 * scr.x * scr.y and (str(pc.name).contains("Chronicle") or str(pc.name).contains("BossCard") or str(pc.name).contains("Feed")):
							# U69: the 20% in-pane skip is for backdrops; a NAMED HUD element grown past it is the fault
							print("FAIL named HUD element inflated past the in-pane skip @", tag, ": ", k.name, "/", pc.name, " ", pr); _bad += 1; _inflated += 1
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
	_n += items.size()
	print("  [", tag, "] ", items.size(), " elements")
	for it in items:
		print("     ", it[0], " ", it[1])
	for i in items.size():
		for j in range(i + 1, items.size()):
			if (items[i][1] as Rect2).intersects(items[j][1]):
				print("FAIL overlap @", tag, ": ", items[i][0], " x ", items[j][0]); _bad += 1
